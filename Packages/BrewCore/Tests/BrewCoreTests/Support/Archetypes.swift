import Foundation

@testable import BrewCore

/// One representative recipe per style, built only through `RecipeRules` operations so each is valid
/// by construction. Style IDs are the keys; the recipes are tuned so each one classifies to its key.
enum Archetypes {
    /// The six styles whose glasses must look visibly different (ART-01).
    static let glassSet = ["american_pale_ale", "stout", "pilsner", "hazy_ipa", "saison", "wheat_beer"]

    /// Every non-fallback style, in styles.json order.
    static let allStyles = [
        "west_coast_ipa", "hazy_ipa", "american_pale_ale", "stout", "porter", "brown_ale", "english_bitter",
        "saison", "wild_ale", "wheat_beer", "pilsner", "helles_lager", "blonde_ale",
    ]

    static func recipe(for styleID: String, content: ContentCatalog) -> Recipe {
        switch styleID {
        case "west_coast_ipa":
            return build(
                base: "grain.g01", others: [("adjunct.a02", 10)], strength: .strong, mashTemp: .low,
                hops: [
                    ("hop.h03", .bittering, 6), ("hop.h03", .aroma, 4), ("hop.h01", .whirlpool, 6),
                ],
                yeast: "yeast.y01", conditioning: [(.dryHop, "hop.h03", 8)], content: content)
        case "porter":
            return build(
                base: "grain.g01", others: [("grain.g05", 5), ("grain.g04", 5)],
                hops: [("hop.h05", .bittering, 6)], yeast: "yeast.y02", content: content)
        case "brown_ale":
            return build(
                base: "grain.g01", others: [("grain.g04", 10)],
                hops: [("hop.h05", .bittering, 4)], yeast: "yeast.y02", content: content)
        case "english_bitter":
            return build(
                base: "grain.g01", others: [("grain.g04", 5)], strength: .session,
                hops: [("hop.h05", .bittering, 8), ("hop.h05", .flavor, 4)], yeast: "yeast.y02", content: content)
        case "wild_ale":
            return build(
                base: "grain.g02", hops: [("hop.h05", .bittering, 2)], yeast: "yeast.y05",
                fermentDuration: .extended, content: content)
        case "helles_lager":
            return build(
                base: "grain.g01", hops: [("hop.h02", .bittering, 8)], yeast: "yeast.y03",
                conditioning: [(.lagering, nil, nil)], content: content)
        case "blonde_ale":
            return build(
                base: "grain.g01", hops: [("hop.h06", .bittering, 4)], yeast: "yeast.y01", fermentTemp: .warm,
                content: content)
        case "american_pale_ale":
            return content.housePaleAle
        case "stout":
            return build(
                base: "grain.g01", others: [("grain.g05", 10), ("grain.g04", 5)],
                hops: [("hop.h07", .bittering, 2)], yeast: "yeast.y02", content: content)
        case "pilsner":
            return build(
                base: "grain.g02", hops: [("hop.h02", .bittering, 8), ("hop.h02", .aroma, 4)],
                yeast: "yeast.y03", fermentTemp: .cold,
                conditioning: [(.lagering, nil, nil)], content: content)
        case "hazy_ipa":
            return build(
                base: "grain.g01", others: [("adjunct.a01", 20), ("grain.g03", 10)],
                strength: .strong,
                hops: [("hop.h04", .aroma, 8), ("hop.h01", .whirlpool, 8)],
                yeast: "yeast.y02", conditioning: [(.dryHop, "hop.h04", 8)], content: content)
        case "saison":
            return build(
                base: "grain.g02", others: [("grain.g03", 15), ("grain.g04", 5)],
                hops: [("hop.h05", .bittering, 6), ("hop.h05", .aroma, 4)],
                yeast: "yeast.y04", fermentTemp: .warm,
                conditioning: [(.bottleConditioning, nil, nil)], content: content)
        case "wheat_beer":
            return build(
                base: "grain.g03", others: [("grain.g01", 40), ("adjunct.a01", 10)],
                hops: [("hop.h06", .bittering, 2)], yeast: "yeast.y01",
                conditioning: [(.bottleConditioning, nil, nil)], content: content)
        default:
            fatalError("No archetype recipe for style '\(styleID)'")
        }
    }

    // MARK: Builder

    private static func build(
        base: String,
        others: [(id: String, percent: Int)] = [],
        strength: StrengthBand = .standard,
        mashTemp: MashTempBand = .medium,
        hops: [(id: String, slot: HopSlot, quarterOunces: Int)] = [],
        yeast: String,
        fermentTemp: FermentTempBand = .balanced,
        fermentDuration: FermentDurationBand = .standard,
        conditioning: [(kind: ConditioningKind, ingredient: String?, amount: Int?)] = [],
        content: ContentCatalog
    ) -> Recipe {
        var recipe = Recipe(yeastID: yeast)
        recipe.strength = strength
        recipe.mashTemp = mashTemp
        recipe.fermentTemp = fermentTemp
        recipe.fermentDuration = fermentDuration

        var bill = RecipeGrid.require(
            RecipeRules.addingFermentable(base, to: GrainBill(), content: content), "base \(base)")
        for other in others {
            bill = RecipeGrid.stepUp(other.id, to: other.percent, in: bill, content: content)
        }
        recipe.grainBill = bill

        var additions: [HopAddition] = []
        for hop in hops {
            additions = RecipeGrid.require(
                RecipeRules.addingHop(hop.id, slot: hop.slot, to: additions, content: content), "hop \(hop.id)")
            let index = additions.count - 1
            while additions[index].quarterOunces != hop.quarterOunces {
                let delta = additions[index].quarterOunces < hop.quarterOunces ? 1 : -1
                additions = RecipeGrid.require(RecipeRules.steppingHop(at: index, by: delta, in: additions), "step hop")
            }
        }
        recipe.hops = additions

        var steps: [ConditioningStep] = []
        for step in conditioning {
            steps = RecipeGrid.require(
                RecipeRules.togglingConditioning(step.kind, defaultIngredientID: step.ingredient, in: steps),
                "conditioning \(step.kind)")
            if let amount = step.amount {
                steps = RecipeGrid.require(
                    RecipeRules.settingConditioningAmount(step.kind, amount: amount, in: steps), "amount \(step.kind)")
            }
        }
        recipe.conditioning = steps

        let issues = RecipeRules.validate(recipe, content: content)
        precondition(issues.isEmpty, "Archetype built an invalid recipe: \(issues)")
        return recipe
    }
}
