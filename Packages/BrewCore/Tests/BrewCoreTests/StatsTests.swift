import Foundation
import Testing

@testable import BrewCore

private func grains(base: String = "grain.g01", _ entries: [(String, Int)]) -> GrainBill {
    GrainBill(baseID: base, entries: entries.map { GrainEntry(fermentableID: $0.0, percent: $0.1) })
}

@Suite struct StatsTests {
    let content: ContentCatalog

    init() throws {
        content = try ContentCatalog.loadBundled()
    }

    private func brew(_ recipe: Recipe) throws -> BrewResult {
        let issues = RecipeRules.validate(recipe, content: content)
        #expect(issues.isEmpty, "test recipe must be valid: \(issues)")
        return try Brewer.brew(recipe, content: content)
    }

    // MARK: House pale ale

    @Test func housePaleAleStatsAreInTheExpectedRanges() throws {
        let stats = try Brewer.brew(content.housePaleAle, content: content).stats
        #expect(stats.ogPoints == 1050)
        #expect((1008...1014).contains(stats.fgPoints), "fg \(stats.fgPoints)")
        #expect((48...56).contains(stats.abvTenths), "abv \(stats.abvTenths)")
        #expect((70...130).contains(stats.srmTenths), "srm \(stats.srmTenths)")
        #expect(stats.ibuTenths > 0)
    }

    // MARK: ABV

    @Test func imperialFarmhouseIsStrongerThanTheSameRecipeAtSessionStrength() throws {
        var recipe = Recipe(
            grainBill: grains(base: "grain.g02", [("grain.g02", 85), ("grain.g03", 15)]),
            hops: [HopAddition(hopID: "hop.h05", slot: .bittering, quarterOunces: 4)],
            yeastID: "yeast.y04", fermentTemp: .warm)
        recipe.strength = .imperial
        let imperial = try brew(recipe)
        recipe.strength = .session
        let session = try brew(recipe)
        #expect(imperial.stats.abvTenths > session.stats.abvTenths, "\(imperial.stats.abvTenths) vs \(session.stats.abvTenths)")
        #expect(imperial.stats.ogPoints == 1085)
        #expect(session.stats.ogPoints == 1036)
    }

    @Test func abvRowsTelescopeToTheAbvStatOverBothGrids() throws {
        for (which, recipes) in [
            ("structured", RecipeGrid.structured(content: content)),
            ("sample", RecipeGrid.sample(seed: 42, count: 500, content: content)),
        ] {
            for (index, recipe) in recipes.enumerated() {
                let result = try Brewer.brew(recipe, content: content)
                let rowSum = result.rows(for: .abv).reduce(0) { $0 + $1.delta }
                let expected = min(result.stats.abvTenths, AttributeScale.max)
                #expect(rowSum == expected, "\(which)#\(index) rows \(rowSum) vs abv \(result.stats.abvTenths)")
                #expect(result.attributes[.abv] == expected, "\(which)#\(index)")
                if result.stats.abvTenths > AttributeScale.max {
                    #expect(result.rows(for: .abv).last?.source.kind == .cap, "\(which)#\(index) missing cap row")
                }
            }
        }
    }

    @Test func abvAttributeMatchesAbvPercentOneToOne() throws {
        let result = try Brewer.brew(content.housePaleAle, content: content)
        #expect(result.attributes[.abv] == result.stats.abvTenths)
        #expect(result.stats.abvTenths == divRound((result.stats.ogPoints - result.stats.fgPoints) * 13125, 10000))
    }

    @Test func attenuationIsClampedAndTheClampIsItsOwnYeastRow() throws {
        // 750 + 40 (low mash) + 150 (y05) + 10 (warm) + 15 (extended) = 965 > 950. Imperial strength
        // (OG 1085) is big enough for the 15 permille clamp to change the rounded ABV.
        var recipe = Recipe(
            grainBill: grains([("grain.g01", 100)]), strength: .imperial, mashTemp: .low, yeastID: "yeast.y05",
            fermentTemp: .warm, fermentDuration: .extended)
        let clamped = try brew(recipe)
        let limit = LedgerSource(kind: .yeast, refID: "yeast.y05", detail: "attenuationLimit")
        let limitRows = clamped.ledger.filter { $0.attribute == .abv && $0.source == limit }
        #expect(limitRows.count == 1)
        #expect((limitRows.first?.delta ?? 0) < 0)
        #expect(clamped.stats.fgPoints == 1085 - divRound(85 * 950, 1000))

        recipe.mashTemp = .medium
        recipe.fermentDuration = .standard
        let inside = try brew(recipe)
        #expect(!inside.ledger.contains { $0.attribute == .abv && $0.source == limit })
    }

    @Test func abvRowsAreInGlobalStageOrder() throws {
        let recipe = Recipe(
            grainBill: grains([("grain.g01", 90), ("adjunct.a02", 10)]), mashTemp: .low, yeastID: "yeast.y04",
            fermentTemp: .warm, fermentDuration: .extended)
        let kinds = try brew(recipe).rows(for: .abv).map(\.source.kind)
        let stageOrder: [SourceKind] = [
            .fermentable, .strength, .mashTemp, .yeast, .fermentTemp, .fermentDuration, .cap,
        ]
        let indices = kinds.map { stageOrder.firstIndex(of: $0)! }
        #expect(indices == indices.sorted(), "\(kinds)")
        #expect(kinds.first == .fermentable)
    }

    @Test func candiSugarRaisesAbvAndLowersFinalGravity() throws {
        let plain = try brew(Recipe(grainBill: grains([("grain.g01", 100)]), yeastID: "yeast.y01"))
        let candi = try brew(
            Recipe(grainBill: grains([("grain.g01", 90), ("adjunct.a02", 10)]), yeastID: "yeast.y01"))
        #expect(candi.stats.abvTenths > plain.stats.abvTenths)
        #expect(candi.stats.fgPoints < plain.stats.fgPoints)
        #expect(candi.stats.ogPoints == plain.stats.ogPoints)
    }

    // MARK: SRM

    @Test func moreyTableMatchesTheKnownAnchor() {
        #expect((95...100).contains(content.morey.srmTenths(mcuTenths: 156)))
        #expect(content.morey.srmTenths(mcuTenths: 0) == 0)
    }

    @Test func moreyTableClampsOutOfRangeIndices() {
        let top = content.morey.srmTenths(mcuTenths: content.morey.mcuTenthsMax)
        #expect(content.morey.srmTenths(mcuTenths: Int.max / 2) == top)
        #expect(content.morey.srmTenths(mcuTenths: -50) == 0)
    }

    @Test func roastedBarleyStoutIsDark() throws {
        let stout = try brew(
            Recipe(
                grainBill: grains([("grain.g01", 85), ("grain.g05", 10), ("grain.g04", 5)]),
                hops: [HopAddition(hopID: "hop.h07", slot: .bittering, quarterOunces: 4)],
                yeastID: "yeast.y02"))
        #expect(stout.stats.srmTenths >= 300, "srm \(stout.stats.srmTenths)")
    }

    @Test func darkestLegalRecipeStaysInsideTheMoreyTable() throws {
        var recipe = Recipe(
            grainBill: grains([("grain.g01", 65), ("grain.g05", 15), ("grain.g04", 20)]), yeastID: "yeast.y01")
        recipe.strength = .imperial
        let result = try brew(recipe)
        #expect(result.stats.srmTenths <= 1000)
        #expect(result.stats.srmTenths >= 300)
    }

    // MARK: Persistence

    @Test func statsSurviveTheSaveRoundTrip() throws {
        let result = try Brewer.brew(content.housePaleAle, content: content)
        let beer = Beer(
            id: UUID(uuidString: "00000000-0000-0000-0000-0000000000B1")!, batchNumber: 1, brewDay: 1,
            recipe: content.housePaleAle, result: result, contentVersion: content.contentVersion)
        let state = GameState(day: 18, nextBatchNumber: 2, beers: [beer])
        let decoded = try SaveCodec.decode(SaveCodec.encode(state))
        #expect(decoded.beers.first?.result.stats == result.stats)
        #expect(decoded == state)
    }
}
