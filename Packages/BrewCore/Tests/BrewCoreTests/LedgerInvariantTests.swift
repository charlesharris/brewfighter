import Foundation
import Testing

@testable import BrewCore

private func baseRecipe(
    hops: [HopAddition] = [], conditioning: [ConditioningStep] = [], yeast: String = "yeast.y01"
) -> Recipe {
    Recipe(
        grainBill: GrainBill(baseID: "grain.g01", entries: [GrainEntry(fermentableID: "grain.g01", percent: 100)]),
        hops: hops, yeastID: yeast, conditioning: conditioning)
}

@Suite struct LedgerInvariantTests {
    let content: ContentCatalog

    init() throws {
        content = try ContentCatalog.loadBundled()
    }

    private func conditioningRows(_ result: BrewResult, _ attribute: AttributeID) -> [LedgerRow] {
        result.ledger.filter { $0.attribute == attribute && $0.source.kind == .conditioning }
    }

    // MARK: Conditioning contributions (D-16)

    @Test func dryHopAddsAromaRowsFromTheChosenHopAndNoIBU() throws {
        let plain = try Brewer.brew(baseRecipe(), content: content)
        let dry = try Brewer.brew(
            baseRecipe(conditioning: [ConditioningStep(kind: .dryHop, ingredientID: "hop.h01", amount: 4)]),
            content: content)
        let rows = conditioningRows(dry, .hopAroma)
        #expect(rows.count == 1)
        #expect(rows.first?.delta == divRound(25 * 130 * 4, 400))
        #expect(rows.first?.delta == 33)
        #expect(rows.first?.source == LedgerSource(kind: .conditioning, refID: "hop.h01", detail: "dryHop"))
        #expect(dry.stats.ibuTenths == plain.stats.ibuTenths, "dry hop adds 0 IBU")
        #expect(conditioningRows(dry, .bitterness).isEmpty)
    }

    @Test func fruitAddsPerPoundRowsFromTheFruitAdjunct() throws {
        let result = try Brewer.brew(
            baseRecipe(conditioning: [ConditioningStep(kind: .fruit, ingredientID: "adjunct.a03", amount: 2)]),
            content: content)
        let source = LedgerSource(kind: .conditioning, refID: "adjunct.a03", detail: "fruit")
        func delta(_ attribute: AttributeID) -> Int? {
            result.ledger.first { $0.attribute == attribute && $0.source == source }?.delta
        }
        #expect(delta(.fruit) == 50)
        #expect(delta(.sour) == 20)
        #expect(delta(.sweetness) == 10)
    }

    @Test func lageringAndBottleConditioningHaveFixedEffects() throws {
        let lagered = try Brewer.brew(baseRecipe(conditioning: [ConditioningStep(kind: .lagering)]), content: content)
        let source = LedgerSource(kind: .conditioning, refID: nil, detail: "lagering")
        func lager(_ attribute: AttributeID) -> Int? {
            lagered.ledger.first { $0.attribute == attribute && $0.source == source }?.delta
        }
        #expect(lager(.fruit) == -10)
        #expect(lager(.dryness) == 10)
        #expect(lager(.carbonation) == 5)
        #expect(lager(.sweetness) == -5)

        let bottled = try Brewer.brew(
            baseRecipe(conditioning: [ConditioningStep(kind: .bottleConditioning)]), content: content)
        let bottleSource = LedgerSource(kind: .conditioning, refID: nil, detail: "bottleConditioning")
        func bottle(_ attribute: AttributeID) -> Int? {
            bottled.ledger.first { $0.attribute == attribute && $0.source == bottleSource }?.delta
        }
        #expect(bottle(.carbonation) == 20)
        #expect(bottle(.dryness) == 5)
    }

    @Test func houseDryHopBrewAdvancesTheDayToEighteen() {
        var rng = SeededRNG(seed: 1)
        let beerID = UUID(uuidString: "00000000-0000-0000-0000-0000000000AA")!
        let (state, _) = Reducer.apply(
            .brew(recipe: content.housePaleAle, beerID: beerID), to: .new, content: content, rng: &rng)
        #expect(content.housePaleAle.conditioning.map(\.kind) == [.dryHop])
        #expect(state.day == 18, "14 fermentation days + 3 dry hop days from day 1")
    }

    // MARK: Hops in two slots

    @Test func sameHopInTwoSlotsGivesTwoRowsDistinguishedBySlot() throws {
        let result = try Brewer.brew(
            baseRecipe(hops: [
                HopAddition(hopID: "hop.h01", slot: .bittering, quarterOunces: 4),
                HopAddition(hopID: "hop.h01", slot: .aroma, quarterOunces: 4),
            ]),
            content: content)
        let rows = result.ledger.filter { $0.attribute == .hopAroma && $0.source.kind == .hop }
        #expect(rows.map(\.source.detail) == ["bittering", "aroma"])
        #expect(rows.map(\.delta) == [3, 25])
    }

    // MARK: House pale ale profile (design doc)

    @Test func housePaleAleMeetsTheDesignProfile() throws {
        let result = try Brewer.brew(content.housePaleAle, content: content)
        let a = result.attributes
        #expect((30...50).contains(a[.bitterness]), "bitterness \(a[.bitterness])")
        #expect((50...70).contains(a[.hopAroma]), "hopAroma \(a[.hopAroma])")
        #expect((40...60).contains(a[.citrus]), "citrus \(a[.citrus])")
        #expect((20...40).contains(a[.tropical]), "tropical \(a[.tropical])")
        #expect((15...35).contains(a[.body]), "body \(a[.body])")
        #expect((45...60).contains(a[.carbonation]), "carbonation \(a[.carbonation])")
        #expect(a[.roast] <= 5, "roast \(a[.roast])")
        let capped = Set(result.ledger.filter { $0.source.kind == .cap }.map(\.attribute))
        #expect(capped.count <= 2, "capped: \(capped)")
        #expect(result.styleID == "american_pale_ale")
    }

    // MARK: Ledger invariants over the recipe grid

    private func recipes(_ which: String) -> [Recipe] {
        which == "structured"
            ? RecipeGrid.structured(content: content)
            : RecipeGrid.sample(seed: 42, count: 500, content: content)
    }

    @Test func gridSizesAndDeterminism() {
        #expect(RecipeGrid.structured(content: content).count == 600)
        #expect(RecipeGrid.sample(seed: 42, count: 500, content: content).count == 500)
        #expect(RecipeGrid.sample(seed: 42, count: 50, content: content) == RecipeGrid.sample(seed: 42, count: 50, content: content))
        #expect(RecipeGrid.sample(seed: 42, count: 50, content: content) != RecipeGrid.sample(seed: 43, count: 50, content: content))
        #expect(RecipeGrid.structured(content: content).allSatisfy { RecipeRules.validate($0, content: content).isEmpty })
    }

    @Test(arguments: ["structured", "sample"])
    func rowsSumToValuesAndStayInRange(which: String) throws {
        for (index, recipe) in recipes(which).enumerated() {
            let result = try Brewer.brew(recipe, content: content)
            #expect(AttributeID.allCases.count == 16)
            for attribute in AttributeID.allCases {
                let sum = result.rows(for: attribute).reduce(0) { $0 + $1.delta }
                #expect(sum == result.attributes[attribute], "\(which)#\(index) \(attribute)")
                #expect((0...AttributeScale.max).contains(result.attributes[attribute]), "\(which)#\(index) \(attribute)")
            }
            #expect(!result.ledger.contains { $0.delta == 0 }, "\(which)#\(index) has a zero-delta row")
        }
    }

    @Test(arguments: ["structured", "sample"])
    func capRowsAreUniqueAndLastPerAttribute(which: String) throws {
        for (index, recipe) in recipes(which).enumerated() {
            let result = try Brewer.brew(recipe, content: content)
            for attribute in AttributeID.allCases {
                let rows = result.rows(for: attribute)
                let caps = rows.filter { $0.source.kind == .cap }
                #expect(caps.count <= 1, "\(which)#\(index) \(attribute)")
                if let cap = caps.first { #expect(rows.last == cap, "\(which)#\(index) \(attribute)") }
            }
        }
    }

    @Test(arguments: ["structured", "sample"])
    func brewingTwiceGivesEqualResults(which: String) throws {
        for (index, recipe) in recipes(which).enumerated() {
            #expect(try Brewer.brew(recipe, content: content) == Brewer.brew(recipe, content: content), "\(which)#\(index)")
        }
    }

    @Test(arguments: ["structured", "sample"])
    func reorderingHopsAndNonBaseGrainsLeavesTheBeerUnchanged(which: String) throws {
        for (index, recipe) in recipes(which).enumerated() {
            var shuffled = recipe
            shuffled.hops = recipe.hops.reversed()
            let base = recipe.grainBill.entries.filter { $0.fermentableID == recipe.grainBill.baseID }
            let others = recipe.grainBill.entries.filter { $0.fermentableID != recipe.grainBill.baseID }
            shuffled.grainBill.entries = base + others.reversed()

            let a = try Brewer.brew(recipe, content: content)
            let b = try Brewer.brew(shuffled, content: content)
            #expect(a.attributes == b.attributes, "\(which)#\(index)")
            #expect(a.stats == b.stats, "\(which)#\(index)")
            #expect(a.styleID == b.styleID, "\(which)#\(index)")
        }
    }
}
