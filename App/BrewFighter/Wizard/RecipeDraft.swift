import BrewCore
import Foundation
import Observation

/// The recipe being composed. Every edit delegates to `RecipeRules`, which returns nil when it
/// refuses, so the draft can never hold an invalid grain bill or hop schedule (D-07, T-1-17).
/// The `can...` queries ask the same rules without mutating, so the UI disables a control
/// exactly when its action would be refused.
@MainActor @Observable
final class RecipeDraft {
    var recipe: Recipe
    @ObservationIgnored private let content: ContentCatalog

    /// Starts as the house pale ale (D-06).
    init(content: ContentCatalog) {
        self.content = content
        self.recipe = content.housePaleAle
    }

    /// One tap empties everything (D-06): no grain, standard strength, medium mash, no hops, no
    /// yeast, balanced fermentation of standard length, no conditioning.
    func clear() {
        recipe = Recipe()
    }

    /// Every issue that stops this recipe from being brewed (D-07).
    var issues: [RecipeIssue] {
        RecipeRules.validate(recipe, content: content)
    }

    // MARK: Band choices (enumerations cannot be out of range)

    func setStrength(_ band: StrengthBand) { recipe.strength = band }
    func setMashTemp(_ band: MashTempBand) { recipe.mashTemp = band }
    func setFermentTemp(_ band: FermentTempBand) { recipe.fermentTemp = band }
    func setFermentDuration(_ band: FermentDurationBand) { recipe.fermentDuration = band }

    // MARK: Yeast (D-03)

    /// Picks one yeast. An id the catalog does not know is ignored, so the draft never holds a
    /// yeast the engine would reject.
    func setYeast(_ id: String) {
        guard content.yeasts.contains(where: { $0.id == id }) else { return }
        recipe.yeastID = id
    }

    /// Fermentation days plus conditioning days, from the engine (D-10). The brew advances the
    /// day counter by exactly this much and never starts a real-time wait (BREW-07).
    var dayCost: Int {
        RecipeRules.dayCost(recipe, content: content)
    }

    // MARK: Grain bill (D-14)

    func canAddFermentable(_ id: String) -> Bool {
        RecipeRules.addingFermentable(id, to: recipe.grainBill, content: content) != nil
    }

    @discardableResult
    func addFermentable(_ id: String) -> Bool {
        guard let bill = RecipeRules.addingFermentable(id, to: recipe.grainBill, content: content) else { return false }
        recipe.grainBill = bill
        return true
    }

    func canStepFermentable(_ id: String, by delta: Int) -> Bool {
        RecipeRules.steppingFermentable(id, by: delta, in: recipe.grainBill, content: content) != nil
    }

    @discardableResult
    func stepFermentable(_ id: String, by delta: Int) -> Bool {
        guard let bill = RecipeRules.steppingFermentable(id, by: delta, in: recipe.grainBill, content: content)
        else { return false }
        recipe.grainBill = bill
        return true
    }

    @discardableResult
    func removeFermentable(_ id: String) -> Bool {
        guard let bill = RecipeRules.removingFermentable(id, from: recipe.grainBill, content: content) else { return false }
        recipe.grainBill = bill
        return true
    }

    func canMakeBase(_ id: String) -> Bool {
        RecipeRules.settingBase(id, in: recipe.grainBill, content: content) != nil
    }

    @discardableResult
    func makeBase(_ id: String) -> Bool {
        guard let bill = RecipeRules.settingBase(id, in: recipe.grainBill, content: content) else { return false }
        recipe.grainBill = bill
        return true
    }

    func percent(of id: String) -> Int? {
        recipe.grainBill.entries.first { $0.fermentableID == id }?.percent
    }

    func isBase(_ id: String) -> Bool { recipe.grainBill.baseID == id }

    // MARK: Conditioning (D-16)

    /// The ingredient a dry hop or fruit step starts with: the first hop already in the boil
    /// schedule, else the first catalog hop; the first catalog fruit.
    private func defaultConditioningIngredient(_ kind: ConditioningKind) -> String? {
        switch kind {
        case .dryHop: recipe.hops.first?.hopID ?? content.hops.first?.id
        case .fruit: content.fruits.first?.id
        case .lagering, .bottleConditioning: nil
        }
    }

    func conditioningStep(_ kind: ConditioningKind) -> ConditioningStep? {
        recipe.conditioning.first { $0.kind == kind }
    }

    /// False only when the rules refuse: turning on lagering while bottle conditioning is on (or
    /// the reverse). Turning an option off is always allowed.
    func canToggleConditioning(_ kind: ConditioningKind) -> Bool {
        RecipeRules.togglingConditioning(
            kind, defaultIngredientID: defaultConditioningIngredient(kind), in: recipe.conditioning) != nil
    }

    @discardableResult
    func toggleConditioning(_ kind: ConditioningKind) -> Bool {
        guard
            let steps = RecipeRules.togglingConditioning(
                kind, defaultIngredientID: defaultConditioningIngredient(kind), in: recipe.conditioning)
        else { return false }
        recipe.conditioning = steps
        return true
    }

    func canSetConditioningAmount(_ kind: ConditioningKind, amount: Int) -> Bool {
        RecipeRules.settingConditioningAmount(kind, amount: amount, in: recipe.conditioning) != nil
    }

    @discardableResult
    func setConditioningAmount(_ kind: ConditioningKind, amount: Int) -> Bool {
        guard let steps = RecipeRules.settingConditioningAmount(kind, amount: amount, in: recipe.conditioning)
        else { return false }
        recipe.conditioning = steps
        return true
    }

    /// Accepts only a catalog hop for a dry hop and a catalog fruit for fruit, so a step can never
    /// hold an ingredient the engine does not know.
    @discardableResult
    func setConditioningIngredient(_ kind: ConditioningKind, id: String) -> Bool {
        switch kind {
        case .dryHop: guard content.hops.contains(where: { $0.id == id }) else { return false }
        case .fruit: guard content.fruits.contains(where: { $0.id == id }) else { return false }
        case .lagering, .bottleConditioning: return false
        }
        guard let steps = RecipeRules.settingConditioningIngredient(kind, id: id, in: recipe.conditioning)
        else { return false }
        recipe.conditioning = steps
        return true
    }

    // MARK: Hops (D-15)

    func canAddHop(_ id: String, slot: HopSlot) -> Bool {
        RecipeRules.addingHop(id, slot: slot, to: recipe.hops, content: content) != nil
    }

    @discardableResult
    func addHop(_ id: String, slot: HopSlot) -> Bool {
        guard let hops = RecipeRules.addingHop(id, slot: slot, to: recipe.hops, content: content) else { return false }
        recipe.hops = hops
        return true
    }

    func canStepHop(at index: Int, by delta: Int) -> Bool {
        RecipeRules.steppingHop(at: index, by: delta, in: recipe.hops) != nil
    }

    @discardableResult
    func stepHop(at index: Int, by delta: Int) -> Bool {
        guard let hops = RecipeRules.steppingHop(at: index, by: delta, in: recipe.hops) else { return false }
        recipe.hops = hops
        return true
    }
}

// MARK: - Catalog lookups for display

extension ContentCatalog {
    func fermentableNameKey(_ id: String) -> String? { fermentables.first { $0.id == id }?.nameKey }
    func hopNameKey(_ id: String) -> String? { hops.first { $0.id == id }?.nameKey }
    func yeastNameKey(_ id: String) -> String? { yeasts.first { $0.id == id }?.nameKey }
    func slotNameKey(_ slot: HopSlot) -> String? { hopSlots.first { $0.slot == slot }?.nameKey }
    func conditioningNameKey(_ kind: ConditioningKind) -> String? { conditioning.first { $0.kind == kind }?.nameKey }
    func fruitNameKey(_ id: String) -> String? { fruits.first { $0.id == id }?.nameKey }
    func strengthNameKey(_ band: StrengthBand) -> String? { strengthBands.first { $0.id == band.rawValue }?.nameKey }
    func mashNameKey(_ band: MashTempBand) -> String? { mashBands.first { $0.id == band.rawValue }?.nameKey }
    func fermentTempNameKey(_ band: FermentTempBand) -> String? {
        fermentTempBands.first { $0.id == band.rawValue }?.nameKey
    }
    func fermentDurationNameKey(_ band: FermentDurationBand) -> String? {
        durationBands.first { $0.id == band.rawValue }?.nameKey
    }
}

enum Ounces {
    /// Quarter-ounces shown as ounces with two decimals, in the player's number format.
    static func text(quarterOunces: Int) -> String {
        (Double(quarterOunces) / 4).formatted(.number.precision(.fractionLength(2)))
    }
}
