import Foundation

/// The engine owns every recipe edit rule, so the wizard can only produce valid,
/// bounded recipes. Every operation is a pure function returning a new value, or
/// nil when the edit is refused (so the UI can disable controls by asking first).
///
/// Implements D-07 (validation floor), D-10 (day cost), D-14 (percent grain bill with
/// auto-rebalance), D-15 (named hop slots, same hop+slot merges) and D-16 (conditioning
/// menu rules), plus research gaps 2-4 (quarter-ounce hop steps, multi-select
/// conditioning with summed days, ferment durations 7/14/21).
public enum RecipeRules {
    public static let percentStep = 5
    public static let minimumBasePercent = 10
    public static let maxHopAdditions = 8
    public static let hopQuarterOunceRange = 1...16
    public static let defaultHopQuarterOunces = 4

    /// Dry hop is measured in quarter-ounces, fruit in whole pounds; the other two
    /// conditioning steps carry no amount.
    public static func conditioningAmountRange(_ kind: ConditioningKind) -> ClosedRange<Int>? {
        switch kind {
        case .dryHop: return 1...16
        case .fruit: return 1...4
        case .lagering, .bottleConditioning: return nil
        }
    }

    // MARK: Validation (D-07)

    /// Every issue that applies. Hops and conditioning are optional. Brewer calls this before
    /// any arithmetic, so no unbounded percent or amount can reach a multiplication (T-1-01).
    public static func validate(_ recipe: Recipe, content: ContentCatalog) -> [RecipeIssue] {
        var issues: [RecipeIssue] = []
        func add(_ issue: RecipeIssue) { if !issues.contains(issue) { issues.append(issue) } }

        // Grain bill
        if recipe.grainBill.baseID == nil || recipe.grainBill.entries.isEmpty {
            add(.noGrain)
        } else {
            billIssues(recipe.grainBill, content).forEach(add)
        }

        // Yeast
        if let yeastID = recipe.yeastID {
            if content.yeast(yeastID) == nil { add(.unknownIngredient(yeastID)) }
        } else {
            add(.noYeast)
        }

        // Hops (IDs resolve against the catalog's hop list)
        if recipe.hops.count > maxHopAdditions { add(.tooManyHopAdditions) }
        var seenHops = Set<String>()
        for hop in recipe.hops {
            if !content.containsHop(hop.hopID) { add(.unknownIngredient(hop.hopID)) }
            if !hopQuarterOunceRange.contains(hop.quarterOunces) { add(.hopAmountOutOfRange(hop.quarterOunces)) }
            let key = "\(hop.hopID):\(hop.slot.rawValue)"
            if !seenHops.insert(key).inserted { add(.duplicateHopSlot(key)) }
        }

        // Conditioning
        var seenKinds = Set<ConditioningKind>()
        for step in recipe.conditioning {
            if !seenKinds.insert(step.kind).inserted { add(.duplicateConditioning(step.kind)) }
            guard let range = conditioningAmountRange(step.kind) else { continue }
            if let ingredient = step.ingredientID {
                if step.kind == .dryHop && !content.containsHop(ingredient) { add(.unknownIngredient(ingredient)) }
                if step.kind == .fruit && !content.containsFruit(ingredient) { add(.unknownIngredient(ingredient)) }
            } else {
                add(.conditioningMissingIngredient(step.kind))
            }
            if let amount = step.amount, range.contains(amount) {
                // in range
            } else {
                add(.conditioningAmountOutOfRange(step.kind))
            }
        }
        if seenKinds.contains(.lagering) && seenKinds.contains(.bottleConditioning) { add(.conditioningConflict) }

        return issues
    }

    /// Issues for a non-empty grain bill. The percent sum is taken over values clamped to
    /// 0...100 so a hostile percent cannot overflow the addition.
    private static func billIssues(_ bill: GrainBill, _ content: ContentCatalog) -> [RecipeIssue] {
        guard let baseID = bill.baseID, bill.entries.contains(where: { $0.fermentableID == baseID }) else {
            return [.noGrain]
        }
        var issues: [RecipeIssue] = []
        func add(_ issue: RecipeIssue) { if !issues.contains(issue) { issues.append(issue) } }

        var sum = 0
        var seen = Set<String>()
        for entry in bill.entries {
            let id = entry.fermentableID
            sum += min(max(entry.percent, 0), 100)
            if !seen.insert(id).inserted { add(.duplicateFermentable(id)) }
            guard let info = content.fermentable(id) else {
                add(.unknownIngredient(id))
                continue
            }
            if id == baseID {
                if !info.isBaseCapable { add(.baseNotBaseCapable) }
                if entry.percent < minimumBasePercent { add(.baseBelowMinimum) }
                if !(0...min(info.maxPercent, 100)).contains(entry.percent) { add(.grainOutOfRange(id)) }
            } else if entry.percent % percentStep != 0 || !(percentStep...info.maxPercent).contains(entry.percent) {
                add(.grainOutOfRange(id))
            }
        }
        if sum != 100 { add(.billNotHundred) }
        return issues
    }

    /// An edit is accepted only if the resulting bill satisfies every bill invariant.
    private static func accepted(_ candidate: GrainBill, _ content: ContentCatalog) -> GrainBill? {
        billIssues(candidate, content).isEmpty ? candidate : nil
    }

    // MARK: Grain bill (D-14)

    /// Empty bill: only a base-capable grain, which becomes the base at 100. Otherwise the new
    /// grain enters at 5, taken from the base.
    public static func addingFermentable(_ id: String, to bill: GrainBill, content: ContentCatalog) -> GrainBill? {
        guard let info = content.fermentable(id) else { return nil }
        if bill.entries.isEmpty {
            guard info.isBaseCapable else { return nil }
            return accepted(GrainBill(baseID: id, entries: [GrainEntry(fermentableID: id, percent: 100)]), content)
        }
        guard let baseID = bill.baseID,
            let baseIndex = bill.entries.firstIndex(where: { $0.fermentableID == baseID }),
            !bill.entries.contains(where: { $0.fermentableID == id })
        else { return nil }

        var candidate = bill
        candidate.entries[baseIndex].percent -= percentStep
        candidate.entries.append(GrainEntry(fermentableID: id, percent: percentStep))
        return accepted(candidate, content)
    }

    /// Steps a specialty entry by exactly one step; the base absorbs the difference.
    /// Reaching 0 removes the entry. The base itself never steps.
    public static func steppingFermentable(
        _ id: String, by delta: Int, in bill: GrainBill, content: ContentCatalog
    ) -> GrainBill? {
        guard delta == percentStep || delta == -percentStep,
            let baseID = bill.baseID, id != baseID,
            let baseIndex = bill.entries.firstIndex(where: { $0.fermentableID == baseID }),
            let index = bill.entries.firstIndex(where: { $0.fermentableID == id })
        else { return nil }

        var candidate = bill
        let stepped = candidate.entries[index].percent + delta
        candidate.entries[baseIndex].percent -= delta
        if stepped <= 0 {
            candidate.entries.remove(at: index)
        } else {
            candidate.entries[index].percent = stepped
        }
        return accepted(candidate, content)
    }

    /// A specialty's percent returns to the base. Removing the base promotes the first remaining
    /// base-capable entry (entry order), which absorbs the removed percent. Removing the only
    /// entry yields an empty bill.
    public static func removingFermentable(_ id: String, from bill: GrainBill, content: ContentCatalog) -> GrainBill? {
        guard let index = bill.entries.firstIndex(where: { $0.fermentableID == id }) else { return nil }
        if bill.entries.count == 1 { return GrainBill() }
        guard let baseID = bill.baseID,
            let baseIndex = bill.entries.firstIndex(where: { $0.fermentableID == baseID })
        else { return nil }

        var candidate = bill
        let removed = bill.entries[index].percent
        if id != baseID {
            candidate.entries[baseIndex].percent += removed
        } else {
            guard let promoted = bill.entries.indices.first(where: {
                $0 != index && content.fermentable(bill.entries[$0].fermentableID)?.isBaseCapable == true
            }) else { return nil }
            candidate.entries[promoted].percent += removed
            candidate.baseID = bill.entries[promoted].fermentableID
        }
        candidate.entries.remove(at: index)
        return accepted(candidate, content)
    }

    /// Reassigns the base role to a base-capable entry. Percents do not move: the old base keeps
    /// its share as a regular entry and the new base's share is already 100 minus the others.
    public static func settingBase(_ id: String, in bill: GrainBill, content: ContentCatalog) -> GrainBill? {
        guard let info = content.fermentable(id), info.isBaseCapable,
            bill.entries.contains(where: { $0.fermentableID == id })
        else { return nil }
        var candidate = bill
        candidate.baseID = id
        return accepted(candidate, content)
    }

    // MARK: Hops (D-15)

    /// The same hop in the same slot merges (+4 quarter-ounces, capped at 16; refused once at 16).
    /// A new addition enters at 4 and is refused past 8 additions. `content` is kept in the
    /// signature for catalog checks; `validate` already rejects unknown IDs at brew time.
    public static func addingHop(
        _ hopID: String, slot: HopSlot, to hops: [HopAddition], content: ContentCatalog
    ) -> [HopAddition]? {
        if let index = hops.firstIndex(where: { $0.hopID == hopID && $0.slot == slot }) {
            let current = hops[index].quarterOunces
            guard current < hopQuarterOunceRange.upperBound else { return nil }
            var updated = hops
            updated[index].quarterOunces = min(current + defaultHopQuarterOunces, hopQuarterOunceRange.upperBound)
            return updated
        }
        guard hops.count < maxHopAdditions else { return nil }
        return hops + [HopAddition(hopID: hopID, slot: slot, quarterOunces: defaultHopQuarterOunces)]
    }

    /// One quarter-ounce per step. Reaching 0 removes the addition; above 16 is refused.
    public static func steppingHop(at index: Int, by delta: Int, in hops: [HopAddition]) -> [HopAddition]? {
        guard delta == 1 || delta == -1, hops.indices.contains(index) else { return nil }
        let stepped = hops[index].quarterOunces + delta
        var updated = hops
        if stepped < hopQuarterOunceRange.lowerBound {
            updated.remove(at: index)
        } else if stepped > hopQuarterOunceRange.upperBound {
            return nil
        } else {
            updated[index].quarterOunces = stepped
        }
        return updated
    }

    // MARK: Conditioning (D-16)

    /// One step per kind. Lagering and bottle conditioning exclude each other. Dry hop and fruit
    /// turn on with the default ingredient at the lower amount bound; turning off removes the step.
    public static func togglingConditioning(
        _ kind: ConditioningKind, defaultIngredientID: String?, in steps: [ConditioningStep]
    ) -> [ConditioningStep]? {
        if let index = steps.firstIndex(where: { $0.kind == kind }) {
            var updated = steps
            updated.remove(at: index)
            return updated
        }
        let excluded: ConditioningKind? =
            switch kind {
            case .lagering: .bottleConditioning
            case .bottleConditioning: .lagering
            default: nil
            }
        if let excluded, steps.contains(where: { $0.kind == excluded }) { return nil }

        if let range = conditioningAmountRange(kind) {
            guard let ingredient = defaultIngredientID else { return nil }
            return steps + [ConditioningStep(kind: kind, ingredientID: ingredient, amount: range.lowerBound)]
        }
        return steps + [ConditioningStep(kind: kind)]
    }

    public static func settingConditioningAmount(
        _ kind: ConditioningKind, amount: Int, in steps: [ConditioningStep]
    ) -> [ConditioningStep]? {
        guard let index = steps.firstIndex(where: { $0.kind == kind }),
            let range = conditioningAmountRange(kind), range.contains(amount)
        else { return nil }
        var updated = steps
        updated[index].amount = amount
        return updated
    }

    public static func settingConditioningIngredient(
        _ kind: ConditioningKind, id: String, in steps: [ConditioningStep]
    ) -> [ConditioningStep]? {
        guard let index = steps.firstIndex(where: { $0.kind == kind }),
            conditioningAmountRange(kind) != nil
        else { return nil }
        var updated = steps
        updated[index].ingredientID = id
        return updated
    }

    // MARK: Day cost (D-10)

    /// Fermentation days plus the days of every conditioning step. A real calendar rule, not a timer.
    public static func dayCost(_ recipe: Recipe, content: ContentCatalog) -> Int {
        let fermentation = content.band(for: recipe.fermentDuration)?.days ?? 0
        let conditioning = recipe.conditioning.reduce(0) { $0 + (content.conditioningInfo(for: $1.kind)?.days ?? 0) }
        return fermentation + conditioning
    }
}
