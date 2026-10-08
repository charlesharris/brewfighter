import Foundation
import Testing

@testable import BrewCore

@Suite struct ContentValidationTests {
    let content: ContentCatalog

    init() throws {
        content = try ContentCatalog.loadBundled()
    }

    private var grains: [FermentableInfo] { content.fermentables.filter { $0.id.hasPrefix("grain.") } }

    private var allIDs: [String] {
        content.fermentables.map(\.id).filter { $0.hasPrefix("grain.") }
            + content.hops.map(\.id) + content.yeasts.map(\.id) + content.adjuncts.map(\.id)
    }

    private func recipe(
        entries: [GrainEntry], yeast: String = "yeast.y01", duration: FermentDurationBand = .standard
    ) -> Recipe {
        Recipe(
            grainBill: GrainBill(baseID: entries[0].fermentableID, entries: entries),
            yeastID: yeast, fermentDuration: duration)
    }

    // MARK: Roster (D-13)

    @Test func rosterCountsMatchD13() {
        #expect(grains.count == 5)
        #expect(content.hops.count == 8)
        #expect(content.yeasts.count == 5)
        #expect(content.adjuncts.count == 3)
        // fermentables = 5 grains + the 2 grain-bill adjuncts; fruits = the 1 fruit adjunct
        #expect(content.fermentables.count == 7)
        #expect(content.fruits.map(\.id) == ["adjunct.a03"])
        #expect(content.fermentables.filter { $0.kind == .adjunct }.map(\.id) == ["adjunct.a01", "adjunct.a02"])
    }

    @Test func idsAreNeutralAndUnique() throws {
        let pattern = try Regex(#"^(grain\.g|hop\.h|yeast\.y|adjunct\.a)[0-9]{2}$"#)
        for id in allIDs { #expect(id.wholeMatch(of: pattern) != nil, "\(id)") }
        #expect(Set(allIDs).count == allIDs.count)
        #expect(allIDs.count == 21)
    }

    @Test func namesAndTraitsFollowTheKeyShape() throws {
        let traitPattern = try Regex(#"^trait\.[a-zA-Z]+$"#)
        func check(_ id: String, _ nameKey: String, _ traits: [String]) {
            #expect(nameKey == "content.\(id).name", "\(id)")
            #expect(!traits.isEmpty, "\(id) needs trait tags (D-05)")
            for trait in traits { #expect(trait.wholeMatch(of: traitPattern) != nil, "\(id): \(trait)") }
        }
        for g in grains { check(g.id, g.nameKey, g.traitKeys) }
        for h in content.hops { check(h.id, h.nameKey, h.traitKeys) }
        for y in content.yeasts { check(y.id, y.nameKey, y.traitKeys) }
        for a in content.adjuncts { check(a.id, a.nameKey, a.traitKeys) }
    }

    // MARK: Ranges (T-1-09)

    @Test func percentsAreBoundedAndBaseCapableGrainsExist() {
        for f in content.fermentables {
            #expect((5...100).contains(f.maxPercent), "\(f.id)")
            #expect(f.maxPercent % 5 == 0, "\(f.id)")
        }
        #expect(content.fermentables.filter(\.isBaseCapable).count >= 3)
        #expect(content.fermentables.filter { $0.kind == .adjunct }.allSatisfy { !$0.isBaseCapable })
    }

    @Test func yeastsAreOrderedAndFullyDescribed() {
        for y in content.yeasts {
            let cold = y.tempF[.cold] ?? 0
            let balanced = y.tempF[.balanced] ?? 0
            let warm = y.tempF[.warm] ?? 0
            #expect(cold < balanced && balanced < warm, "\(y.id)")
            #expect((30...100).contains(cold) && (30...100).contains(warm), "\(y.id)")
            #expect((600...950).contains(y.attenuationPermille), "\(y.id)")
            #expect(Set(y.effectsByTempBand.keys) == Set(FermentTempBand.allCases), "\(y.id)")
        }
    }

    @Test func hopAlphaAndEverySourceEffectAreBounded() {
        for h in content.hops { #expect((0...300).contains(h.alphaTenths), "\(h.id)") }
        var maps: [(String, EffectMap)] = []
        maps += content.fermentables.map { ($0.id, $0.effects) }
        maps += content.hops.map { ($0.id, $0.effects) }
        maps += content.adjuncts.map { ($0.id, $0.effects) }
        for y in content.yeasts {
            for (band, map) in y.effectsByTempBand { maps.append(("\(y.id).\(band.rawValue)", map)) }
        }
        maps += content.conditioning.map { ($0.kind.rawValue, $0.effects) }
        maps += (content.strengthBands + content.mashBands + content.fermentTempBands + content.durationBands)
            .map { ($0.id, $0.effects) }
        for (id, map) in maps {
            for attribute in AttributeID.allCases {
                #expect((-1000...1000).contains(map[attribute]), "\(id).\(attribute)")
            }
        }
    }

    @Test func starterRecipesValidate() throws {
        for id in ["house_pale_ale"] {
            let starter = try #require(content.starterRecipe(id), "\(id)")
            #expect(RecipeRules.validate(starter, content: content).isEmpty, "\(id)")
        }
    }

    @Test func everyHopAndConditioningIngredientResolves() {
        let bad = Recipe(
            grainBill: GrainBill(baseID: "grain.g01", entries: [GrainEntry(fermentableID: "grain.g01", percent: 100)]),
            hops: [HopAddition(hopID: "hop.h99", slot: .aroma, quarterOunces: 4)],
            yeastID: "yeast.y01",
            conditioning: [
                ConditioningStep(kind: .fruit, ingredientID: "adjunct.a01", amount: 1),
                ConditioningStep(kind: .dryHop, ingredientID: "hop.h99", amount: 4),
            ])
        let issues = RecipeRules.validate(bad, content: content)
        #expect(issues.contains(.unknownIngredient("hop.h99")))
        #expect(issues.contains(.unknownIngredient("adjunct.a01")), "oats are not a fruit")
    }

    // MARK: Behavior of the new content

    @Test func oatsInTheGrainBillBrewAndOwnTheBodyRow() throws {
        let r = recipe(entries: [
            GrainEntry(fermentableID: "grain.g01", percent: 85), GrainEntry(fermentableID: "adjunct.a01", percent: 15),
        ])
        #expect(RecipeRules.validate(r, content: content).isEmpty)
        let result = try Brewer.brew(r, content: content)
        let body = result.ledger.first { $0.attribute == .body && $0.source.refID == "adjunct.a01" }
        #expect(body?.source.kind == .fermentable)
        #expect(body?.delta == divRound(200 * 15, 100))
    }

    @Test func wildYeastGetsFunkierWithTime() throws {
        let entries = [GrainEntry(fermentableID: "grain.g01", percent: 100)]
        let quick = try Brewer.brew(recipe(entries: entries, yeast: "yeast.y05", duration: .quick), content: content)
        let extended = try Brewer.brew(recipe(entries: entries, yeast: "yeast.y05", duration: .extended), content: content)
        #expect(extended.attributes[.funk] > quick.attributes[.funk])
        #expect(extended.ledger.contains { $0.source.kind == .fermentDuration && $0.source.refID == "yeast.y05" })
    }

    @Test func yeastsWithoutDurationEffectsEmitNoDurationYeastRows() throws {
        let entries = [GrainEntry(fermentableID: "grain.g01", percent: 100)]
        let result = try Brewer.brew(recipe(entries: entries, yeast: "yeast.y01", duration: .extended), content: content)
        #expect(!result.ledger.contains { $0.source.kind == .fermentDuration && $0.source.refID == "yeast.y01" })
    }
}
