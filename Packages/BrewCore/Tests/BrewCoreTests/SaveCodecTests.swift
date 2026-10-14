import Foundation
import Testing

@testable import BrewCore

@Suite struct SaveCodecTests {
    let content: ContentCatalog

    init() throws {
        content = try ContentCatalog.loadBundled()
    }

    /// Brews each recipe in turn through the reducer, with fixed IDs so the result is reproducible.
    private func state(brewing recipes: [Recipe]) -> GameState {
        var rng = SeededRNG(seed: 1)
        var state = GameState.new
        for (index, recipe) in recipes.enumerated() {
            let id = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, UInt8(index >> 8), UInt8(index & 0xFF)))
            (state, _) = Reducer.apply(.brew(recipe: recipe, beerID: id), to: state, content: content, rng: &rng)
        }
        return state
    }

    /// The most extreme legal recipe: eight maximal bittering additions, imperial strength,
    /// 15% roasted barley and 20% crystal.
    private func extremeRecipe() -> Recipe {
        var bill = RecipeGrid.require(
            RecipeRules.addingFermentable("grain.g01", to: GrainBill(), content: content), "base")
        bill = RecipeGrid.stepUp("grain.g05", to: 15, in: bill, content: content)
        bill = RecipeGrid.stepUp("grain.g04", to: 20, in: bill, content: content)

        var hops: [HopAddition] = []
        for hop in content.hops.prefix(RecipeRules.maxHopAdditions) {
            hops = RecipeGrid.require(
                RecipeRules.addingHop(hop.id, slot: .bittering, to: hops, content: content), "hop \(hop.id)")
            let index = hops.count - 1
            while hops[index].quarterOunces < RecipeRules.hopQuarterOunceRange.upperBound {
                hops = RecipeGrid.require(RecipeRules.steppingHop(at: index, by: 1, in: hops), "step \(hop.id)")
            }
        }
        var recipe = Recipe(grainBill: bill, strength: .imperial, hops: hops, yeastID: "yeast.y01")
        recipe.fermentDuration = .extended
        return recipe
    }

    // MARK: Engine output always validates

    @Test func theMostExtremeLegalRecipeBrewsAndValidates() throws {
        let recipe = extremeRecipe()
        #expect(RecipeRules.validate(recipe, content: content).isEmpty)
        #expect(recipe.hops.count == RecipeRules.maxHopAdditions)
        let brewed = state(brewing: [recipe])
        #expect(brewed.beers.count == 1)
        try SaveValidator.validate(brewed, content: content)
        #expect(try SaveCodec.decode(SaveCodec.encode(brewed), content: content) == brewed)
    }

    @Test func seededRandomRecipesAllValidate() throws {
        let recipes = RecipeGrid.sample(seed: 99, count: 120, content: content)
        let brewed = state(brewing: recipes)
        #expect(brewed.beers.count == recipes.count)
        try SaveValidator.validate(brewed, content: content)
    }

    // MARK: Determinism

    @Test func encodingTheSameStateTwiceYieldsIdenticalBytes() throws {
        let brewed = state(brewing: [content.housePaleAle, extremeRecipe()])
        #expect(try SaveCodec.encode(brewed) == SaveCodec.encode(brewed))
    }
}
