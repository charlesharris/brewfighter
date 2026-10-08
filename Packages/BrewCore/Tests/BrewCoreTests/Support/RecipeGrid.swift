import Foundation

@testable import BrewCore

/// Deterministic recipe enumerators shared by the ledger, style and save tests.
/// Every recipe is built only through `RecipeRules` operations, so each one is valid by construction.
enum RecipeGrid {
    private struct HopSpec {
        let hopID: String
        let slot: HopSlot
        let quarterOunces: Int
    }

    private static let hopProfiles: [[HopSpec]] = [
        [],
        [HopSpec(hopID: "hop.h07", slot: .bittering, quarterOunces: 4)],
        [
            HopSpec(hopID: "hop.h06", slot: .bittering, quarterOunces: 4),
            HopSpec(hopID: "hop.h01", slot: .aroma, quarterOunces: 4),
        ],
        [
            HopSpec(hopID: "hop.h07", slot: .bittering, quarterOunces: 2),
            HopSpec(hopID: "hop.h04", slot: .aroma, quarterOunces: 8),
            HopSpec(hopID: "hop.h01", slot: .whirlpool, quarterOunces: 8),
        ],
    ]

    /// base option: (base ID, optional second base-capable grain and its percent)
    private static let baseOptions: [(base: String, partner: (id: String, percent: Int)?)] = [
        ("grain.g01", nil),
        ("grain.g02", nil),
        ("grain.g03", ("grain.g01", 50)),
    ]

    private static let specialtyOptions: [(id: String, percent: Int)?] = [
        nil,
        ("grain.g04", 10),
        ("grain.g05", 10),
        ("adjunct.a01", 15),
        ("adjunct.a02", 10),
    ]

    private static let yeastIDs = ["yeast.y01", "yeast.y02", "yeast.y03", "yeast.y04", "yeast.y05"]

    // MARK: Structured grid

    /// 3 bases x 5 specialties x 5 yeasts x 4 hop profiles x 2 strengths = 600 recipes.
    /// Mash medium, ferment balanced, duration standard, no conditioning.
    static func structured(content: ContentCatalog) -> [Recipe] {
        var recipes: [Recipe] = []
        for base in baseOptions {
            for specialty in specialtyOptions {
                for yeast in yeastIDs {
                    for profile in hopProfiles {
                        for strength in [StrengthBand.standard, .strong] {
                            var recipe = Recipe(yeastID: yeast)
                            recipe.strength = strength
                            recipe.grainBill = bill(base: base.base, partner: base.partner, specialty: specialty, content: content)
                            recipe.hops = hops(profile, content: content)
                            recipes.append(recipe)
                        }
                    }
                }
            }
        }
        return recipes
    }

    private static func bill(
        base: String, partner: (id: String, percent: Int)?, specialty: (id: String, percent: Int)?,
        content: ContentCatalog
    ) -> GrainBill {
        var bill = require(RecipeRules.addingFermentable(base, to: GrainBill(), content: content), "base \(base)")
        if let partner {
            bill = stepUp(partner.id, to: partner.percent, in: bill, content: content)
        }
        if let specialty {
            bill = stepUp(specialty.id, to: specialty.percent, in: bill, content: content)
        }
        return bill
    }

    /// Adds `id` (entering at 5) and steps it up in 5-point increments until it reaches `percent`.
    private static func stepUp(_ id: String, to percent: Int, in bill: GrainBill, content: ContentCatalog) -> GrainBill {
        var bill = require(RecipeRules.addingFermentable(id, to: bill, content: content), "add \(id)")
        var current = RecipeRules.percentStep
        while current < percent {
            bill = require(
                RecipeRules.steppingFermentable(id, by: RecipeRules.percentStep, in: bill, content: content),
                "step \(id) to \(current + RecipeRules.percentStep)")
            current += RecipeRules.percentStep
        }
        return bill
    }

    private static func hops(_ profile: [HopSpec], content: ContentCatalog) -> [HopAddition] {
        var out: [HopAddition] = []
        for spec in profile {
            out = require(RecipeRules.addingHop(spec.hopID, slot: spec.slot, to: out, content: content), "hop \(spec.hopID)")
            let index = out.count - 1
            while out[index].quarterOunces != spec.quarterOunces {
                let delta = out[index].quarterOunces < spec.quarterOunces ? 1 : -1
                out = require(RecipeRules.steppingHop(at: index, by: delta, in: out), "step hop \(spec.hopID)")
            }
        }
        return out
    }

    // MARK: Seeded random grid

    /// `count` random valid recipes: random bands, 0-8 hops, 0-3 conditioning steps respecting exclusivity.
    static func sample(seed: UInt64, count: Int, content: ContentCatalog) -> [Recipe] {
        var rng = SeededRNG(seed: seed)
        return (0..<count).map { _ in randomRecipe(&rng, content: content) }
    }

    private static func pick<T>(_ items: [T], _ rng: inout SeededRNG) -> T {
        items[Int.random(in: 0..<items.count, using: &rng)]
    }

    private static func randomRecipe(_ rng: inout SeededRNG, content: ContentCatalog) -> Recipe {
        var recipe = Recipe()
        recipe.strength = pick(StrengthBand.allCases, &rng)
        recipe.mashTemp = pick(MashTempBand.allCases, &rng)
        recipe.fermentTemp = pick(FermentTempBand.allCases, &rng)
        recipe.fermentDuration = pick(FermentDurationBand.allCases, &rng)
        recipe.yeastID = pick(content.yeasts, &rng).id

        // Grain bill: a base-capable grain, then 0-4 random edits through the rules.
        let bases = content.fermentables.filter(\.isBaseCapable)
        var bill = require(
            RecipeRules.addingFermentable(pick(bases, &rng).id, to: GrainBill(), content: content), "random base")
        for _ in 0..<Int.random(in: 0...4, using: &rng) {
            let candidate = pick(content.fermentables, &rng).id
            if let next = RecipeRules.addingFermentable(candidate, to: bill, content: content) { bill = next }
            for _ in 0..<Int.random(in: 0...3, using: &rng) {
                let id = pick(bill.entries, &rng).fermentableID
                let delta = Bool.random(using: &rng) ? RecipeRules.percentStep : -RecipeRules.percentStep
                if let next = RecipeRules.steppingFermentable(id, by: delta, in: bill, content: content) { bill = next }
            }
        }
        recipe.grainBill = bill

        // Hops: 0-8 additions with random slots and amounts.
        var hops: [HopAddition] = []
        for _ in 0..<Int.random(in: 0...8, using: &rng) {
            let hop = pick(content.hops, &rng).id
            let slot = pick(HopSlot.allCases, &rng)
            if let next = RecipeRules.addingHop(hop, slot: slot, to: hops, content: content) { hops = next }
            if let index = hops.firstIndex(where: { $0.hopID == hop && $0.slot == slot }) {
                for _ in 0..<Int.random(in: 0...6, using: &rng) {
                    let delta = Bool.random(using: &rng) ? 1 : -1
                    if let next = RecipeRules.steppingHop(at: index, by: delta, in: hops), next.count == hops.count {
                        hops = next
                    }
                }
            }
        }
        recipe.hops = hops

        // Conditioning: 0-3 distinct kinds, exclusivity enforced by the rules.
        var steps: [ConditioningStep] = []
        for _ in 0..<Int.random(in: 0...3, using: &rng) {
            let kind = pick(ConditioningKind.allCases, &rng)
            let defaultIngredient: String? =
                switch kind {
                case .dryHop: pick(content.hops, &rng).id
                case .fruit: pick(content.fruits, &rng).id
                default: nil
                }
            guard let toggled = RecipeRules.togglingConditioning(kind, defaultIngredientID: defaultIngredient, in: steps),
                toggled.count > steps.count
            else { continue }
            steps = toggled
            if let range = RecipeRules.conditioningAmountRange(kind) {
                let amount = Int.random(in: range, using: &rng)
                steps = RecipeRules.settingConditioningAmount(kind, amount: amount, in: steps) ?? steps
            }
        }
        recipe.conditioning = steps

        let issues = RecipeRules.validate(recipe, content: content)
        precondition(issues.isEmpty, "RecipeGrid built an invalid recipe: \(issues)")
        return recipe
    }

    private static func require<T>(_ value: T?, _ what: @autoclosure () -> String) -> T {
        guard let value else { fatalError("RecipeGrid could not build \(what())") }
        return value
    }
}
