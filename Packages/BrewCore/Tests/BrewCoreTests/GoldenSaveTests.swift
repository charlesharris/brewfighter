import Foundation
import Testing

@testable import BrewCore

/// FNV-1a 64-bit. Hand-rolled so the test needs no CryptoKit and runs on Linux too.
private func fnv1a64(_ data: Data) -> UInt64 {
    var hash: UInt64 = 0xcbf2_9ce4_8422_2325
    for byte in data {
        hash ^= UInt64(byte)
        hash = hash &* 0x0000_0100_0000_01b3
    }
    return hash
}

/// The recorded checksum of `Fixtures/save_v1.json`. The fixture is frozen: schema version 1 is a
/// published contract once a TestFlight build ships. Any change to the on-disk shape needs a
/// SaveMigrator step and a NEW fixture (`save_v2.json`); this file and this constant stay as they are.
private let goldenChecksum: UInt64 = 0x1505d50a292b09fc

private func fixtureURL() -> URL? {
    Bundle.module.url(forResource: "save_v1", withExtension: "json", subdirectory: "Fixtures")
}

@Suite struct GoldenSaveTests {
    let content: ContentCatalog

    init() throws {
        content = try ContentCatalog.loadBundled()
    }

    private func fixtureData() throws -> Data {
        try Data(contentsOf: #require(fixtureURL()))
    }

    // MARK: Generator (run once, then commit the output)

    /// `BREWCORE_WRITE_GOLDEN=1 swift test --filter writeGoldenFixture` rewrites the fixture.
    /// Without the variable this test is skipped, so a normal run can never modify it.
    @Test(.enabled(if: ProcessInfo.processInfo.environment["BREWCORE_WRITE_GOLDEN"] == "1"))
    func writeGoldenFixture() throws {
        let ids = (1...3).map { UUID(uuidString: "00000000-0000-0000-0000-00000000000\($0)")! }
        let recipes = [housePaleAle(), stout(), fruitedWildAle()]
        var rng = SeededRNG(seed: 1)
        var state = GameState.new
        for (id, recipe) in zip(ids, recipes) {
            (state, _) = Reducer.apply(.brew(recipe: recipe, beerID: id), to: state, content: content, rng: &rng)
        }
        #expect(state.beers.count == 3)

        let envelope = SaveEnvelope(
            schemaVersion: SaveCodec.currentSchemaVersion,
            contentVersion: state.beers.map(\.contentVersion).max() ?? 1,
            payload: state)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        let data = try encoder.encode(envelope)

        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .appendingPathComponent("Fixtures/save_v1.json")
        try data.write(to: url, options: [.atomic])
        print("GOLDEN checksum: 0x\(String(fnv1a64(data), radix: 16))")
    }

    private func housePaleAle() -> Recipe { content.housePaleAle }

    /// Flavor and whirlpool hops, roasted barley, bottle conditioning.
    private func stout() -> Recipe {
        var bill = RecipeGrid.require(
            RecipeRules.addingFermentable("grain.g01", to: GrainBill(), content: content), "stout base")
        bill = RecipeGrid.stepUp("grain.g05", to: 10, in: bill, content: content)
        bill = RecipeGrid.stepUp("grain.g04", to: 5, in: bill, content: content)
        var hops: [HopAddition] = []
        for (id, slot) in [("hop.h07", HopSlot.bittering), ("hop.h05", .flavor), ("hop.h01", .whirlpool)] {
            hops = RecipeGrid.require(RecipeRules.addingHop(id, slot: slot, to: hops, content: content), "hop \(id)")
        }
        let conditioning = RecipeGrid.require(
            RecipeRules.togglingConditioning(.bottleConditioning, defaultIngredientID: nil, in: []), "bottle")
        return Recipe(grainBill: bill, hops: hops, yeastID: "yeast.y02", conditioning: conditioning)
    }

    /// Wild yeast, flaked oats and candi sugar in the grain bill, raspberry fruit and lagering.
    private func fruitedWildAle() -> Recipe {
        var bill = RecipeGrid.require(
            RecipeRules.addingFermentable("grain.g02", to: GrainBill(), content: content), "wild base")
        bill = RecipeGrid.stepUp("adjunct.a01", to: 10, in: bill, content: content)
        bill = RecipeGrid.stepUp("adjunct.a02", to: 10, in: bill, content: content)
        let hops = RecipeGrid.require(
            RecipeRules.addingHop("hop.h05", slot: .bittering, to: [], content: content), "wild hop")
        var steps = RecipeGrid.require(
            RecipeRules.togglingConditioning(.fruit, defaultIngredientID: "adjunct.a03", in: []), "fruit")
        steps = RecipeGrid.require(RecipeRules.settingConditioningAmount(.fruit, amount: 2, in: steps), "fruit amount")
        steps = RecipeGrid.require(
            RecipeRules.togglingConditioning(.lagering, defaultIngredientID: nil, in: steps), "lagering")
        return Recipe(
            grainBill: bill, hops: hops, yeastID: "yeast.y05", fermentDuration: .extended, conditioning: steps)
    }

    // MARK: Frozen v1 fixture

    @Test func theFixtureMatchesItsRecordedChecksum() throws {
        let checksum = fnv1a64(try fixtureData())
        #expect(checksum == goldenChecksum, "fixture checksum is 0x\(String(checksum, radix: 16))")
    }

    @Test func theFixtureDecodesAndValidatesWithThreeBeers() throws {
        let state = try SaveCodec.decode(fixtureData(), content: content)
        #expect(state.beers.map(\.batchNumber) == [1, 2, 3])
        #expect(state.nextBatchNumber == 4)
    }

    @Test func reEncodingTheDecodedFixtureReproducesTheSameJSONTree() throws {
        let data = try fixtureData()
        let state = try SaveCodec.decode(data, content: content)
        let original = try #require(try JSONSerialization.jsonObject(with: data) as? NSDictionary)
        let reencoded = try #require(
            try JSONSerialization.jsonObject(with: SaveCodec.encode(state)) as? NSDictionary)
        #expect(original == reencoded)
    }

    @Test func migratingTheFixtureIsANoOp() throws {
        let data = try fixtureData()
        #expect(try SaveMigrator.migrate(data, from: 1) == data)
    }

    @Test func fixtureBeersReBrewToIdenticalResultsUnderTheCurrentContent() throws {
        let state = try SaveCodec.decode(fixtureData(), content: content)
        for beer in state.beers where beer.contentVersion == content.contentVersion {
            #expect(try Brewer.brew(beer.recipe, content: content) == beer.result, "batch \(beer.batchNumber)")
        }
    }

    @Test func theFixtureExercisesTheWholeRecipeSurface() throws {
        let state = try SaveCodec.decode(fixtureData(), content: content)
        let recipes = state.beers.map(\.recipe)
        #expect(Set(recipes.flatMap(\.hops).map(\.slot)) == Set(HopSlot.allCases))
        #expect(Set(recipes.flatMap(\.conditioning).map(\.kind)) == Set(ConditioningKind.allCases))
        let fermentables = recipes.flatMap(\.grainBill.entries).map(\.fermentableID)
        #expect(fermentables.contains { content.fermentable($0)?.kind == .adjunct })
        let fruits = recipes.flatMap(\.conditioning).filter { $0.kind == .fruit }.compactMap(\.ingredientID)
        #expect(fruits.contains { content.containsFruit($0) })
    }
}
