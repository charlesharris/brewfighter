import Foundation

/// SplitMix64. The engine's only randomness source; brewing never touches it.
public struct SeededRNG: RandomNumberGenerator, Equatable, Sendable {
    private var state: UInt64

    public init(seed: UInt64) {
        state = seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

/// `(GameState, Action) -> (GameState, [GameEvent])`. Events are replayed by the UI
/// as animation; the state change is committed before any reveal plays (BREW-07).
public enum Reducer {
    public static func apply(
        _ action: Action, to state: GameState, content: ContentCatalog, rng: inout SeededRNG
    ) -> (GameState, [GameEvent]) {
        switch action {
        case let .brew(recipe, beerID):
            let result: BrewResult
            do throws(BrewError) {
                result = try Brewer.brew(recipe, content: content)
            } catch {
                switch error {
                case .invalidRecipe(let issues): return (state, [.brewRejected(issues)])
                }
            }

            let beer = Beer(
                id: beerID,
                batchNumber: state.nextBatchNumber,
                brewDay: state.day,
                recipe: recipe,
                result: result,
                contentVersion: content.contentVersion)

            var next = state
            let from = state.day
            // D-10: days advance by the recipe-driven cost. No timers, no wall clock (BREW-07).
            let cost = RecipeRules.dayCost(recipe, content: content)
            next.day = from + cost
            next.beers.append(beer)
            next.nextBatchNumber = state.nextBatchNumber + 1

            return (
                next,
                [
                    .dayAdvanced(from: from, to: next.day),
                    .beerBrewed(beerID: beerID, batchNumber: beer.batchNumber),
                    .styleAssigned(beerID: beerID, styleID: result.styleID),
                ]
            )
        }
    }
}
