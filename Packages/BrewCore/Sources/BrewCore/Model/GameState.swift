import Foundation

public struct GameState: Codable, Equatable, Sendable {
    public var day: Int
    public var nextBatchNumber: Int
    public var beers: [Beer]

    public init(day: Int, nextBatchNumber: Int, beers: [Beer]) {
        self.day = day
        self.nextBatchNumber = nextBatchNumber
        self.beers = beers
    }

    /// A fresh game: day 1, batch #1 next, an empty cellar.
    public static let new = GameState(day: 1, nextBatchNumber: 1, beers: [])

    enum CodingKeys: String, CodingKey {
        case day, nextBatchNumber, beers
    }
}

public enum Action: Equatable, Sendable {
    /// `beerID` is injected from outside so the engine stays deterministic.
    case brew(recipe: Recipe, beerID: UUID)
}

/// Facts about what just happened, replayed by the UI as animation.
public enum GameEvent: Equatable, Sendable {
    case dayAdvanced(from: Int, to: Int)
    case beerBrewed(beerID: UUID, batchNumber: Int)
    case styleAssigned(beerID: UUID, styleID: String)
    case brewRejected([RecipeIssue])
}
