import BrewCore
import Foundation

/// How a validation issue is shown on Review (D-07): a catalog message and the stage whose controls
/// fix it. The engine already prevents the composite issues while editing, so those map to a
/// generic per-area message; every case is mapped so the switches stay exhaustive.
extension RecipeIssue {
    var messageKey: String {
        switch self {
        case .noGrain: "issue.noGrain"
        case .noYeast: "issue.noYeast"
        case .billNotHundred, .baseNotBaseCapable, .baseBelowMinimum, .grainOutOfRange, .duplicateFermentable:
            "issue.grainBill"
        case .hopAmountOutOfRange, .duplicateHopSlot, .tooManyHopAdditions:
            "issue.hops"
        case .conditioningConflict, .duplicateConditioning, .conditioningMissingIngredient,
            .conditioningAmountOutOfRange:
            "issue.conditioning"
        case .unknownIngredient: "issue.unknownIngredient"
        }
    }

    /// The stage that owns the fix.
    var stage: WizardStage {
        switch self {
        case .noGrain, .billNotHundred, .baseNotBaseCapable, .baseBelowMinimum, .grainOutOfRange,
            .duplicateFermentable, .unknownIngredient:
            .mash
        case .noYeast: .ferment
        case .hopAmountOutOfRange, .duplicateHopSlot, .tooManyHopAdditions: .boil
        case .conditioningConflict, .duplicateConditioning, .conditioningMissingIngredient,
            .conditioningAmountOutOfRange:
            .condition
        }
    }

    /// Stable suffix for accessibility identifiers: the message key without its `issue.` prefix.
    var slug: String {
        String(messageKey.dropFirst("issue.".count))
    }
}

extension Array where Element == RecipeIssue {
    /// One entry per distinct message, in first-seen order: several grain-bill problems read as one line.
    var distinctByMessage: [RecipeIssue] {
        var seen = Set<String>()
        return filter { seen.insert($0.messageKey).inserted }
    }
}
