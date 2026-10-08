import Foundation
import Testing

@testable import BrewCore

private let g01 = "grain.g01"  // base-capable, max 100
private let g04 = "grain.g04"  // specialty, max 20

/// Extra fermentables so random edit sequences can hit base promotion and per-grain caps.
private func extraFermentables() throws -> [FermentableInfo] {
    let json = """
        [
          { "id": "grain.t02", "nameKey": "content.grain.t02.name", "traitKeys": [], "kind": "base",
            "isBaseCapable": true, "maxPercent": 100, "lovibondTenths": 30, "effects": {} },
          { "id": "grain.t03", "nameKey": "content.grain.t03.name", "traitKeys": [], "kind": "base",
            "isBaseCapable": true, "maxPercent": 60, "lovibondTenths": 40, "effects": {} },
          { "id": "grain.t05", "nameKey": "content.grain.t05.name", "traitKeys": [], "kind": "specialty",
            "isBaseCapable": false, "maxPercent": 10, "lovibondTenths": 500, "effects": {} },
          { "id": "grain.t06", "nameKey": "content.grain.t06.name", "traitKeys": [], "kind": "specialty",
            "isBaseCapable": false, "maxPercent": 15, "lovibondTenths": 700, "effects": {} }
        ]
        """
    return try JSONDecoder().decode([FermentableInfo].self, from: Data(json.utf8))
}

private func percents(_ bill: GrainBill) -> [String: Int] {
    Dictionary(uniqueKeysWithValues: bill.entries.map { ($0.fermentableID, $0.percent) })
}

/// Independent statement of the bill invariants (does not call RecipeRules.validate).
private func violation(_ bill: GrainBill, _ catalog: ContentCatalog) -> String? {
    if bill.entries.isEmpty { return bill.baseID == nil ? nil : "empty bill still names a base" }
    guard let baseID = bill.baseID, let base = bill.entries.first(where: { $0.fermentableID == baseID }) else {
        return "base is not an entry: \(bill)"
    }
    if bill.entries.map(\.percent).reduce(0, +) != 100 { return "percents do not sum to 100: \(bill)" }
    if Set(bill.entries.map(\.fermentableID)).count != bill.entries.count { return "duplicate IDs: \(bill)" }
    if base.percent < RecipeRules.minimumBasePercent { return "base below minimum: \(bill)" }
    guard let baseInfo = catalog.fermentable(baseID), baseInfo.isBaseCapable else { return "base not base-capable: \(bill)" }
    if base.percent > baseInfo.maxPercent { return "base above its max: \(bill)" }
    for entry in bill.entries where entry.fermentableID != baseID {
        guard let info = catalog.fermentable(entry.fermentableID) else { return "unknown fermentable: \(bill)" }
        if entry.percent % RecipeRules.percentStep != 0 || !(5...info.maxPercent).contains(entry.percent) {
            return "specialty out of range \(entry): \(bill)"
        }
    }
    return nil
}

@Suite struct RecipeRulesTests {
    let content: ContentCatalog

    init() throws {
        content = try ContentCatalog.loadBundled()
    }

    private func recipe(bill: GrainBill, yeast: String? = "yeast.y01") -> Recipe {
        Recipe(grainBill: bill, yeastID: yeast)
    }

    // MARK: validate

    @Test func validateEmptyRecipeReportsNoGrainAndNoYeast() {
        let issues = RecipeRules.validate(Recipe(), content: content)
        #expect(issues.contains(.noGrain))
        #expect(issues.contains(.noYeast))
    }

    @Test func validateHousePaleAleIsClean() {
        #expect(RecipeRules.validate(content.housePaleAle, content: content).isEmpty)
    }

    @Test func validateReportsGrainBillProblems() {
        func issues(_ bill: GrainBill) -> [RecipeIssue] { RecipeRules.validate(recipe(bill: bill), content: content) }

        #expect(issues(GrainBill(baseID: g01, entries: [GrainEntry(fermentableID: g01, percent: 95), GrainEntry(fermentableID: g04, percent: 10)]))
            .contains(.billNotHundred))
        #expect(issues(GrainBill(baseID: g04, entries: [GrainEntry(fermentableID: g04, percent: 20), GrainEntry(fermentableID: g01, percent: 80)]))
            .contains(.baseNotBaseCapable))
        #expect(issues(GrainBill(baseID: g01, entries: [GrainEntry(fermentableID: g01, percent: 5), GrainEntry(fermentableID: g04, percent: 20)]))
            .contains(.baseBelowMinimum))
        #expect(issues(GrainBill(baseID: g01, entries: [GrainEntry(fermentableID: g01, percent: 75), GrainEntry(fermentableID: g04, percent: 25)]))
            .contains(.grainOutOfRange(g04)))
        #expect(issues(GrainBill(baseID: g01, entries: [GrainEntry(fermentableID: g01, percent: 50), GrainEntry(fermentableID: g01, percent: 50)]))
            .contains(.duplicateFermentable(g01)))
        #expect(issues(GrainBill(baseID: g01, entries: [GrainEntry(fermentableID: g01, percent: 90), GrainEntry(fermentableID: "grain.zzz", percent: 10)]))
            .contains(.unknownIngredient("grain.zzz")))
        #expect(issues(GrainBill(baseID: g01, entries: [GrainEntry(fermentableID: g01, percent: 100)]))
            .isEmpty)
    }

    @Test func validateReportsYeastHopAndConditioningProblems() {
        let bill = content.housePaleAle.grainBill
        func issues(_ edit: (inout Recipe) -> Void) -> [RecipeIssue] {
            var r = content.housePaleAle
            edit(&r)
            return RecipeRules.validate(r, content: content)
        }

        #expect(issues { $0.yeastID = "yeast.zzz" }.contains(.unknownIngredient("yeast.zzz")))
        #expect(issues { $0.grainBill = bill; $0.hops = (0..<9).map { HopAddition(hopID: "hop.h\($0)", slot: .aroma, quarterOunces: 4) } }
            .contains(.tooManyHopAdditions))
        #expect(issues { $0.hops = [HopAddition(hopID: "hop.h1", slot: .aroma, quarterOunces: 17)] }
            .contains(.hopAmountOutOfRange(17)))
        #expect(issues { $0.hops = [HopAddition(hopID: "hop.h1", slot: .aroma, quarterOunces: 0)] }
            .contains(.hopAmountOutOfRange(0)))
        #expect(issues { $0.hops = [HopAddition(hopID: "hop.h1", slot: .aroma, quarterOunces: 4), HopAddition(hopID: "hop.h1", slot: .aroma, quarterOunces: 4)] }
            .contains(.duplicateHopSlot("hop.h1:aroma")))
        // Until hop content exists (plan 01-03) every hop ID is unknown.
        #expect(issues { $0.hops = [HopAddition(hopID: "hop.h1", slot: .aroma, quarterOunces: 4)] }
            .contains(.unknownIngredient("hop.h1")))

        #expect(issues { $0.conditioning = [ConditioningStep(kind: .lagering), ConditioningStep(kind: .bottleConditioning)] }
            .contains(.conditioningConflict))
        #expect(issues { $0.conditioning = [ConditioningStep(kind: .lagering), ConditioningStep(kind: .lagering)] }
            .contains(.duplicateConditioning(.lagering)))
        #expect(issues { $0.conditioning = [ConditioningStep(kind: .fruit, ingredientID: nil, amount: 2)] }
            .contains(.conditioningMissingIngredient(.fruit)))
        #expect(issues { $0.conditioning = [ConditioningStep(kind: .fruit, ingredientID: "fruit.f1", amount: 5)] }
            .contains(.conditioningAmountOutOfRange(.fruit)))
        #expect(issues { $0.conditioning = [ConditioningStep(kind: .fruit, ingredientID: "fruit.f1", amount: nil)] }
            .contains(.conditioningAmountOutOfRange(.fruit)))
        #expect(issues { $0.conditioning = [ConditioningStep(kind: .lagering)] }.isEmpty)
    }

    // MARK: Grain bill edits

    @Test func addingABaseCapableGrainToAnEmptyBillMakesItTheBaseAtHundred() {
        let bill = RecipeRules.addingFermentable(g01, to: GrainBill(), content: content)
        #expect(bill == GrainBill(baseID: g01, entries: [GrainEntry(fermentableID: g01, percent: 100)]))
    }

    @Test func addingANonBaseCapableGrainToAnEmptyBillIsRefused() {
        #expect(RecipeRules.addingFermentable(g04, to: GrainBill(), content: content) == nil)
        #expect(RecipeRules.addingFermentable("grain.zzz", to: GrainBill(), content: content) == nil)
    }

    @Test func addingASpecialtyTakesFiveFromTheBase() throws {
        let start = try #require(RecipeRules.addingFermentable(g01, to: GrainBill(), content: content))
        let bill = try #require(RecipeRules.addingFermentable(g04, to: start, content: content))
        #expect(bill == GrainBill(baseID: g01, entries: [GrainEntry(fermentableID: g01, percent: 95), GrainEntry(fermentableID: g04, percent: 5)]))
        #expect(RecipeRules.addingFermentable(g04, to: bill, content: content) == nil, "already present")
    }

    @Test func steppingASpecialtyUpStopsAtItsMaxPercent() throws {
        var bill = try #require(RecipeRules.addingFermentable(g01, to: GrainBill(), content: content))
        bill = try #require(RecipeRules.addingFermentable(g04, to: bill, content: content))  // g04 at 5
        for expected in [10, 15, 20] {
            bill = try #require(RecipeRules.steppingFermentable(g04, by: 5, in: bill, content: content))
            #expect(percents(bill)[g04] == expected)
            #expect(percents(bill)[g01] == 100 - expected)
        }
        #expect(RecipeRules.steppingFermentable(g04, by: 5, in: bill, content: content) == nil, "g04 max is 20")
    }

    @Test func steppingASpecialtyToZeroRemovesItAndReturnsThePercentToTheBase() throws {
        var bill = try #require(RecipeRules.addingFermentable(g01, to: GrainBill(), content: content))
        bill = try #require(RecipeRules.addingFermentable(g04, to: bill, content: content))
        let stepped = try #require(RecipeRules.steppingFermentable(g04, by: -5, in: bill, content: content))
        #expect(stepped == GrainBill(baseID: g01, entries: [GrainEntry(fermentableID: g01, percent: 100)]))
    }

    @Test func steppingRefusesBadDeltasTheBaseAndUnknownGrains() throws {
        let bill = content.housePaleAle.grainBill
        #expect(RecipeRules.steppingFermentable(g04, by: 10, in: bill, content: content) == nil, "delta must be one step")
        #expect(RecipeRules.steppingFermentable(g04, by: 0, in: bill, content: content) == nil)
        #expect(RecipeRules.steppingFermentable(g01, by: 5, in: bill, content: content) == nil, "base absorbs, never steps")
        #expect(RecipeRules.steppingFermentable("grain.zzz", by: 5, in: bill, content: content) == nil)
    }

    @Test func aStepThatWouldDropTheBaseBelowTenIsRefused() throws {
        let catalog = content.appendingFermentables(try extraFermentables())
        // base 10, t06 at 15, g04 at 20, t05 at 10 ... build a bill with base exactly 10.
        let bill = GrainBill(baseID: g01, entries: [
            GrainEntry(fermentableID: g01, percent: 10),
            GrainEntry(fermentableID: g04, percent: 20),
            GrainEntry(fermentableID: "grain.t06", percent: 15),
            GrainEntry(fermentableID: "grain.t05", percent: 10),
            GrainEntry(fermentableID: "grain.t02", percent: 45),
        ])
        #expect(violation(bill, catalog) == nil)
        #expect(RecipeRules.steppingFermentable("grain.t02", by: 5, in: bill, content: catalog) == nil)
        #expect(RecipeRules.addingFermentable("grain.t03", to: bill, content: catalog) == nil, "base would drop to 5")
    }

    @Test func removingASpecialtyReturnsItsPercentToTheBase() throws {
        let bill = try #require(RecipeRules.removingFermentable(g04, from: content.housePaleAle.grainBill, content: content))
        #expect(bill == GrainBill(baseID: g01, entries: [GrainEntry(fermentableID: g01, percent: 100)]))
        #expect(RecipeRules.removingFermentable("grain.zzz", from: bill, content: content) == nil)
    }

    @Test func removingTheOnlyEntryYieldsAnEmptyBill() throws {
        let bill = GrainBill(baseID: g01, entries: [GrainEntry(fermentableID: g01, percent: 100)])
        #expect(RecipeRules.removingFermentable(g01, from: bill, content: content) == GrainBill())
    }

    @Test func removingTheBasePromotesTheFirstRemainingBaseCapableEntry() throws {
        let catalog = content.appendingFermentables(try extraFermentables())
        let bill = GrainBill(baseID: g01, entries: [
            GrainEntry(fermentableID: g01, percent: 70),
            GrainEntry(fermentableID: g04, percent: 10),
            GrainEntry(fermentableID: "grain.t02", percent: 20),
        ])
        let promoted = try #require(RecipeRules.removingFermentable(g01, from: bill, content: catalog))
        #expect(promoted.baseID == "grain.t02")
        #expect(percents(promoted) == [g04: 10, "grain.t02": 90])
        #expect(violation(promoted, catalog) == nil)
    }

    @Test func removingTheBaseIsRefusedWhenNothingElseCanBeBase() {
        // g04 is a specialty and not base-capable, so a bill cannot survive losing g01.
        #expect(RecipeRules.removingFermentable(g01, from: content.housePaleAle.grainBill, content: content) == nil)
    }

    @Test func settingTheBaseSwapsRolesAndKeepsTheOldBaseAsARegularEntry() throws {
        let catalog = content.appendingFermentables(try extraFermentables())
        let bill = GrainBill(baseID: g01, entries: [
            GrainEntry(fermentableID: g01, percent: 40),
            GrainEntry(fermentableID: "grain.t02", percent: 60),
        ])
        let swapped = try #require(RecipeRules.settingBase("grain.t02", in: bill, content: catalog))
        #expect(swapped.baseID == "grain.t02")
        #expect(percents(swapped) == [g01: 40, "grain.t02": 60])
        #expect(violation(swapped, catalog) == nil)
        #expect(RecipeRules.settingBase("grain.t02", in: swapped, content: catalog) == swapped, "already the base")
        #expect(RecipeRules.settingBase(g04, in: content.housePaleAle.grainBill, content: content) == nil, "not base-capable")
        #expect(RecipeRules.settingBase("grain.zzz", in: bill, content: catalog) == nil, "not in the bill")
    }

    @Test func settingTheBaseIsRefusedWhenTheNewBaseWouldSitBelowTheMinimum() throws {
        let catalog = content.appendingFermentables(try extraFermentables())
        // The roles swap but percents do not move, so a 5% grain cannot become the base.
        let bill = GrainBill(baseID: g01, entries: [
            GrainEntry(fermentableID: g01, percent: 95),
            GrainEntry(fermentableID: "grain.t02", percent: 5),
        ])
        #expect(RecipeRules.settingBase("grain.t02", in: bill, content: catalog) == nil)
        // A base-capable grain sitting exactly at its own cap (60) can be promoted.
        let capped = GrainBill(baseID: g01, entries: [
            GrainEntry(fermentableID: g01, percent: 30),
            GrainEntry(fermentableID: "grain.t03", percent: 60),
            GrainEntry(fermentableID: g04, percent: 10),
        ])
        #expect(RecipeRules.settingBase("grain.t03", in: capped, content: catalog)?.baseID == "grain.t03")
    }

    @Test func randomGrainBillEditSequencesNeverBreakTheInvariants() throws {
        let catalog = content.appendingFermentables(try extraFermentables())
        let ids = catalog.fermentables.map(\.id)
        var rng = SeededRNG(seed: 42)
        var applied = 0
        var refused = 0

        for _ in 0..<1_000 {
            var bill = GrainBill()
            for _ in 0..<30 {
                let id = ids[Int.random(in: 0..<ids.count, using: &rng)]
                let result: GrainBill?
                switch Int.random(in: 0..<4, using: &rng) {
                case 0: result = RecipeRules.addingFermentable(id, to: bill, content: catalog)
                case 1:
                    let delta = Bool.random(using: &rng) ? RecipeRules.percentStep : -RecipeRules.percentStep
                    result = RecipeRules.steppingFermentable(id, by: delta, in: bill, content: catalog)
                case 2: result = RecipeRules.removingFermentable(id, from: bill, content: catalog)
                default: result = RecipeRules.settingBase(id, in: bill, content: catalog)
                }
                if let result {
                    bill = result
                    applied += 1
                } else {
                    refused += 1
                }
                if let problem = violation(bill, catalog) {
                    Issue.record("invariant violated: \(problem)")
                    return
                }
                // The engine's own validator agrees with the independent statement.
                if !bill.entries.isEmpty {
                    let issues = RecipeRules.validate(Recipe(grainBill: bill, yeastID: "yeast.y01"), content: catalog)
                    #expect(issues.isEmpty, "\(issues) for \(bill)")
                }
            }
        }
        #expect(applied > 5_000, "sequences should actually edit the bill (applied \(applied), refused \(refused))")
        #expect(refused > 1_000, "sequences should also hit refusals (applied \(applied), refused \(refused))")
    }

    // MARK: Hops

    @Test func addingTheSameHopAndSlotTwiceMergesIntoOneAdditionOfEight() throws {
        var hops = try #require(RecipeRules.addingHop("hop.h1", slot: .aroma, to: [], content: content))
        #expect(hops == [HopAddition(hopID: "hop.h1", slot: .aroma, quarterOunces: 4)])
        hops = try #require(RecipeRules.addingHop("hop.h1", slot: .aroma, to: hops, content: content))
        #expect(hops == [HopAddition(hopID: "hop.h1", slot: .aroma, quarterOunces: 8)])
        // A different slot is a separate addition.
        hops = try #require(RecipeRules.addingHop("hop.h1", slot: .bittering, to: hops, content: content))
        #expect(hops.count == 2)
    }

    @Test func mergedHopAmountsCapAtSixteenAndThenRefuse() throws {
        var hops = [HopAddition(hopID: "hop.h1", slot: .flavor, quarterOunces: 14)]
        hops = try #require(RecipeRules.addingHop("hop.h1", slot: .flavor, to: hops, content: content))
        #expect(hops[0].quarterOunces == 16)
        #expect(RecipeRules.addingHop("hop.h1", slot: .flavor, to: hops, content: content) == nil)
    }

    @Test func aNinthDistinctHopAdditionIsRefused() throws {
        var hops: [HopAddition] = []
        for i in 0..<RecipeRules.maxHopAdditions {
            hops = try #require(RecipeRules.addingHop("hop.h\(i)", slot: .aroma, to: hops, content: content))
        }
        #expect(hops.count == 8)
        #expect(RecipeRules.addingHop("hop.h8", slot: .aroma, to: hops, content: content) == nil)
        // Merging into an existing addition is still allowed at the limit.
        #expect(RecipeRules.addingHop("hop.h0", slot: .aroma, to: hops, content: content) != nil)
    }

    @Test func steppingAHopStaysWithinOneToSixteenAndZeroRemoves() throws {
        let hops = [HopAddition(hopID: "hop.h1", slot: .aroma, quarterOunces: 1), HopAddition(hopID: "hop.h2", slot: .flavor, quarterOunces: 16)]
        #expect(RecipeRules.steppingHop(at: 1, by: 1, in: hops) == nil, "above 16")
        let up = try #require(RecipeRules.steppingHop(at: 0, by: 1, in: hops))
        #expect(up[0].quarterOunces == 2)
        let removed = try #require(RecipeRules.steppingHop(at: 0, by: -1, in: hops))
        #expect(removed == [HopAddition(hopID: "hop.h2", slot: .flavor, quarterOunces: 16)])
        #expect(RecipeRules.steppingHop(at: 5, by: 1, in: hops) == nil, "bad index")
        #expect(RecipeRules.steppingHop(at: 0, by: 2, in: hops) == nil, "delta must be one step")
    }

    // MARK: Conditioning

    @Test func lageringAndBottleConditioningExcludeEachOther() throws {
        let lagering = try #require(RecipeRules.togglingConditioning(.lagering, defaultIngredientID: nil, in: []))
        #expect(lagering == [ConditioningStep(kind: .lagering)])
        #expect(RecipeRules.togglingConditioning(.bottleConditioning, defaultIngredientID: nil, in: lagering) == nil)

        let bottle = try #require(RecipeRules.togglingConditioning(.bottleConditioning, defaultIngredientID: nil, in: []))
        #expect(RecipeRules.togglingConditioning(.lagering, defaultIngredientID: nil, in: bottle) == nil)

        // Turning one off lifts the exclusion.
        let off = try #require(RecipeRules.togglingConditioning(.lagering, defaultIngredientID: nil, in: lagering))
        #expect(off.isEmpty)
        #expect(RecipeRules.togglingConditioning(.bottleConditioning, defaultIngredientID: nil, in: off) != nil)
    }

    @Test func dryHopAndFruitNeedAnIngredientAndStartAtTheLowerAmountBound() throws {
        #expect(RecipeRules.togglingConditioning(.dryHop, defaultIngredientID: nil, in: []) == nil)
        #expect(RecipeRules.togglingConditioning(.fruit, defaultIngredientID: nil, in: []) == nil)
        let dry = try #require(RecipeRules.togglingConditioning(.dryHop, defaultIngredientID: "hop.h1", in: []))
        #expect(dry == [ConditioningStep(kind: .dryHop, ingredientID: "hop.h1", amount: 1)])
        let both = try #require(RecipeRules.togglingConditioning(.fruit, defaultIngredientID: "fruit.f1", in: dry))
        #expect(both.map(\.kind) == [.dryHop, .fruit], "steps keep the order they were turned on")
    }

    @Test func conditioningAmountsAndIngredientsStayInRange() throws {
        let steps = [
            ConditioningStep(kind: .dryHop, ingredientID: "hop.h1", amount: 1),
            ConditioningStep(kind: .fruit, ingredientID: "fruit.f1", amount: 1),
            ConditioningStep(kind: .lagering),
        ]
        #expect(RecipeRules.settingConditioningAmount(.dryHop, amount: 16, in: steps)?[0].amount == 16)
        #expect(RecipeRules.settingConditioningAmount(.dryHop, amount: 17, in: steps) == nil)
        #expect(RecipeRules.settingConditioningAmount(.dryHop, amount: 0, in: steps) == nil)
        #expect(RecipeRules.settingConditioningAmount(.fruit, amount: 4, in: steps)?[1].amount == 4)
        #expect(RecipeRules.settingConditioningAmount(.fruit, amount: 5, in: steps) == nil)
        #expect(RecipeRules.settingConditioningAmount(.lagering, amount: 1, in: steps) == nil, "no amount")
        #expect(RecipeRules.settingConditioningAmount(.bottleConditioning, amount: 1, in: steps) == nil, "not turned on")

        #expect(RecipeRules.settingConditioningIngredient(.dryHop, id: "hop.h2", in: steps)?[0].ingredientID == "hop.h2")
        #expect(RecipeRules.settingConditioningIngredient(.lagering, id: "x", in: steps) == nil)
        #expect(RecipeRules.settingConditioningIngredient(.bottleConditioning, id: "x", in: steps) == nil)

        #expect(RecipeRules.conditioningAmountRange(.dryHop) == 1...16)
        #expect(RecipeRules.conditioningAmountRange(.fruit) == 1...4)
        #expect(RecipeRules.conditioningAmountRange(.lagering) == nil)
        #expect(RecipeRules.conditioningAmountRange(.bottleConditioning) == nil)
    }

    // MARK: Day cost (D-10)

    @Test func dayCostOfTheHousePaleAleIsFourteen() {
        #expect(RecipeRules.dayCost(content.housePaleAle, content: content) == 14)
    }

    @Test func dayCostSumsFermentationAndEveryConditioningStep() {
        var recipe = content.housePaleAle
        recipe.fermentDuration = .extended
        recipe.conditioning = [
            ConditioningStep(kind: .lagering),
            ConditioningStep(kind: .dryHop, ingredientID: "hop.h1", amount: 4),
        ]
        #expect(RecipeRules.dayCost(recipe, content: content) == 21 + 28 + 3)

        recipe.fermentDuration = .quick
        recipe.conditioning = [ConditioningStep(kind: .bottleConditioning), ConditioningStep(kind: .fruit, ingredientID: "fruit.f1", amount: 1)]
        #expect(RecipeRules.dayCost(recipe, content: content) == 7 + 14 + 7)
    }

    @Test func reducerAdvancesTheDayByTheFullDayCost() throws {
        var recipe = content.housePaleAle
        recipe.conditioning = [ConditioningStep(kind: .lagering)]
        var rng = SeededRNG(seed: 3)
        let id = UUID(uuidString: "00000000-0000-0000-0000-0000000000AA")!
        let (state, events) = Reducer.apply(.brew(recipe: recipe, beerID: id), to: .new, content: content, rng: &rng)
        #expect(state.day == 1 + 14 + 28)
        #expect(events.first == .dayAdvanced(from: 1, to: 43))
        #expect(state.beers.first?.brewDay == 1)
    }

    // MARK: Brewer safety (T-1-01)

    @Test func brewerRefusesOutOfRangeAmountsBeforeAnyArithmetic() {
        var rng = SeededRNG(seed: 1)
        var recipe = content.housePaleAle
        recipe.grainBill.entries[0].percent = 1_000
        let (state, events) = Reducer.apply(.brew(recipe: recipe, beerID: UUID()), to: .new, content: content, rng: &rng)
        #expect(state == .new)
        guard case let .brewRejected(issues)? = events.first else {
            Issue.record("expected brewRejected, got \(events)")
            return
        }
        #expect(issues.contains(.grainOutOfRange(g01)))
        #expect(issues.contains(.billNotHundred))
    }
}
