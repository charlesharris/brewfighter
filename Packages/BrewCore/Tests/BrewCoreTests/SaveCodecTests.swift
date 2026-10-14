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

    // MARK: Migrator

    @Test func migratingACurrentVersionSaveIsANoOp() throws {
        let data = try SaveCodec.encode(state(brewing: [content.housePaleAle]))
        #expect(try SaveMigrator.migrate(data, from: SaveCodec.currentSchemaVersion) == data)
    }

    @Test func migratingFromVersionZeroIsInvalid() {
        #expect(throws: SaveError.invalid("schemaVersion")) { try SaveMigrator.migrate(Data(), from: 0) }
        #expect(throws: SaveError.invalid("schemaVersion")) { try SaveMigrator.migrate(Data(), from: -3) }
    }

    @Test func migratingFromANewerVersionIsRefused() {
        let newer = SaveCodec.currentSchemaVersion + 1
        #expect(throws: SaveError.newerThanApp(newer)) { try SaveMigrator.migrate(Data(), from: newer) }
    }

    // MARK: Validator bounds

    private func twoBeerState() -> GameState {
        var minimal = content.housePaleAle
        minimal.strength = .strong
        return state(brewing: [content.housePaleAle, minimal])
    }

    private func expectInvalid(
        _ state: GameState, prefix: String, sourceLocation: SourceLocation = #_sourceLocation
    ) {
        do {
            try SaveValidator.validate(state, content: content)
            Issue.record("expected .invalid(\(prefix)...)", sourceLocation: sourceLocation)
        } catch let SaveError.invalid(path) {
            #expect(path.hasPrefix(prefix), "got path \(path)", sourceLocation: sourceLocation)
        } catch {
            Issue.record("unexpected error \(error)", sourceLocation: sourceLocation)
        }
    }

    @Test func theUntouchedTwoBeerStateValidates() throws {
        try SaveValidator.validate(twoBeerState(), content: content)
    }

    @Test func dayZeroIsInvalid() {
        var s = twoBeerState(); s.day = 0
        expectInvalid(s, prefix: "day")
    }

    @Test func aDuplicateBeerIDIsInvalid() {
        var s = twoBeerState(); s.beers[1].id = s.beers[0].id
        expectInvalid(s, prefix: "beers[1].id")
    }

    @Test func nonIncreasingBatchNumbersAreInvalid() {
        var s = twoBeerState(); s.beers[1].batchNumber = s.beers[0].batchNumber
        expectInvalid(s, prefix: "beers[1].batchNumber")
    }

    @Test func aWrongNextBatchNumberIsInvalid() {
        var s = twoBeerState(); s.nextBatchNumber += 1
        expectInvalid(s, prefix: "nextBatchNumber")
    }

    @Test func aBrewDayAfterTheCurrentDayIsInvalid() {
        var s = twoBeerState(); s.beers[0].brewDay = s.day + 1
        expectInvalid(s, prefix: "beers[0].brewDay")
    }

    @Test func anUnknownStyleIDIsInvalid() {
        var s = twoBeerState(); s.beers[0].result.styleID = "style_that_does_not_exist"
        expectInvalid(s, prefix: "beers[0].result.styleID")
    }

    @Test func anUnknownFermentableIsInvalid() {
        var s = twoBeerState(); s.beers[0].recipe.grainBill.entries[1].fermentableID = "grain.g99"
        expectInvalid(s, prefix: "beers[0].recipe")
    }

    @Test func aGrainBillSummingToNinetyFiveIsInvalid() {
        var s = twoBeerState(); s.beers[0].recipe.grainBill.entries[0].percent -= 5
        expectInvalid(s, prefix: "beers[0].recipe")
    }

    @Test func anAttributeOverOneHundredIsInvalid() {
        var s = twoBeerState(); s.beers[0].result.attributes[.body] = 101
        expectInvalid(s, prefix: "beers[0].result.attributes.body")
    }

    @Test func aLedgerThatDoesNotSumToTheAttributeIsInvalid() {
        var s = twoBeerState(); s.beers[0].result.ledger[0].delta += 1
        expectInvalid(s, prefix: "beers[0].result.ledger")
    }

    @Test func anOversizedLedgerRowIsInvalidAndDoesNotTrap() {
        var s = twoBeerState(); s.beers[0].result.ledger[0].delta = Int.min
        expectInvalid(s, prefix: "beers[0].result.ledger[0].delta")
    }

    @Test func anOriginalGravityOfThirteenHundredIsInvalid() {
        var s = twoBeerState(); s.beers[0].result.stats.ogPoints = 1300
        expectInvalid(s, prefix: "beers[0].result.stats.ogPoints")
    }

    @Test func moreThanTenThousandBeersIsInvalid() {
        var s = twoBeerState()
        let template = s.beers[0]
        s.beers = (0...SaveValidator.maxBeers).map { index in
            var beer = template
            beer.id = UUID()
            beer.batchNumber = index + 1
            return beer
        }
        s.nextBatchNumber = s.beers.count + 1
        #expect(s.beers.count == 10_001)
        expectInvalid(s, prefix: "beers")
    }
}
