import Foundation

/// The engine owns every recipe edit rule, so the wizard can only produce valid,
/// bounded recipes. Every operation is a pure function returning a new value, or
/// nil when the edit is refused (so the UI can disable controls by asking first).
public enum RecipeRules {
    public static let percentStep = 5
    public static let minimumBasePercent = 10
    public static let maxHopAdditions = 8
    public static let hopQuarterOunceRange = 1...16
    public static let defaultHopQuarterOunces = 4

    public static func conditioningAmountRange(_ kind: ConditioningKind) -> ClosedRange<Int>? {
        switch kind {
        case .dryHop: return 1...16
        case .fruit: return 1...4
        case .lagering, .bottleConditioning: return nil
        }
    }

    // RED stubs: the real rules land in the GREEN commit.

    public static func validate(_ recipe: Recipe, content: ContentCatalog) -> [RecipeIssue] { [] }

    public static func addingFermentable(_ id: String, to bill: GrainBill, content: ContentCatalog) -> GrainBill? { nil }

    public static func steppingFermentable(
        _ id: String, by delta: Int, in bill: GrainBill, content: ContentCatalog
    ) -> GrainBill? { nil }

    public static func removingFermentable(_ id: String, from bill: GrainBill, content: ContentCatalog) -> GrainBill? { nil }

    public static func settingBase(_ id: String, in bill: GrainBill, content: ContentCatalog) -> GrainBill? { nil }

    public static func addingHop(
        _ hopID: String, slot: HopSlot, to hops: [HopAddition], content: ContentCatalog
    ) -> [HopAddition]? { nil }

    public static func steppingHop(at index: Int, by delta: Int, in hops: [HopAddition]) -> [HopAddition]? { nil }

    public static func togglingConditioning(
        _ kind: ConditioningKind, defaultIngredientID: String?, in steps: [ConditioningStep]
    ) -> [ConditioningStep]? { nil }

    public static func settingConditioningAmount(
        _ kind: ConditioningKind, amount: Int, in steps: [ConditioningStep]
    ) -> [ConditioningStep]? { nil }

    public static func settingConditioningIngredient(
        _ kind: ConditioningKind, id: String, in steps: [ConditioningStep]
    ) -> [ConditioningStep]? { nil }

    public static func dayCost(_ recipe: Recipe, content: ContentCatalog) -> Int { 0 }
}
