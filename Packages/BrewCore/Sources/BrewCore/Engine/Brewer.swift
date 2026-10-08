import Foundation

package enum BrewError: Error, Equatable {
    case invalidRecipe([RecipeIssue])
}

/// Integer division rounding half away from zero. `d` must be positive.
package func divRound(_ n: Int, _ d: Int) -> Int {
    let (q, r) = n.quotientAndRemainder(dividingBy: d)
    if r.magnitude * 2 >= d.magnitude {
        return n < 0 ? q - 1 : q + 1
    }
    return q
}

/// Deterministic recipe -> beer resolution. No RNG, no dates, no floating point.
/// Ledger rows are emitted in fixed brewing-stage order and never re-sorted;
/// zero-delta rows are never emitted; every attribute value is the sum of its rows.
package enum Brewer {
    package static func brew(_ recipe: Recipe, content: ContentCatalog) throws(BrewError) -> BrewResult {
        // Validation runs before any arithmetic: percents are bounded 0...100 and amounts are in
        // range by the time anything is multiplied (T-1-01 / Pitfall 12).
        let issues = RecipeRules.validate(recipe, content: content)
        if !issues.isEmpty { throw .invalidRecipe(issues) }

        var rows: [LedgerRow] = []

        // 1. Baseline
        emit(content.baselineEffects, source: LedgerSource(kind: .baseline), into: &rows)

        // 2. Grain bill, entry order
        for entry in recipe.grainBill.entries {
            guard let info = content.fermentable(entry.fermentableID) else {
                throw .invalidRecipe([.unknownIngredient(entry.fermentableID)])
            }
            emit(info.effects, source: LedgerSource(kind: .fermentable, refID: entry.fermentableID), into: &rows) {
                divRound($0 * entry.percent, 100)
            }
        }

        // 3. Strength band, 4. mash band
        guard let strength = content.band(for: recipe.strength) else {
            throw .invalidRecipe([.unknownIngredient("band.strength.\(recipe.strength.rawValue)")])
        }
        emit(strength.effects, source: LedgerSource(kind: .strength, refID: strength.id), into: &rows)

        guard let mash = content.band(for: recipe.mashTemp) else {
            throw .invalidRecipe([.unknownIngredient("band.mashTemp.\(recipe.mashTemp.rawValue)")])
        }
        emit(mash.effects, source: LedgerSource(kind: .mashTemp, refID: mash.id), into: &rows)

        // 4b. Hop additions in recipe order: bitterness from Tinseth IBU, aroma-family rows by slot weight.
        var ibuTenths = 0
        for addition in recipe.hops {
            guard let hop = content.hop(addition.hopID), let slot = content.hopSlot(addition.slot) else {
                throw .invalidRecipe([.unknownIngredient(addition.hopID)])
            }
            let utilization = content.tinseth.utilizationPer100k(slot: addition.slot, ogPoints: strength.ogPoints ?? 0)
            // Tinseth mg/L for a fixed 5-gallon batch, in tenths of an IBU. Operands are bounded by
            // validation (alpha <= 1000, quarter-ounces <= 16), so the product stays far below Int.max.
            let additionIBU = divRound(utilization * hop.alphaTenths * addition.quarterOunces * 74_900, 2_000_000_000)
            ibuTenths += additionIBU
            let source = LedgerSource(kind: .hop, refID: addition.hopID, detail: addition.slot.rawValue)
            let bitterness = divRound(additionIBU, 10)
            if bitterness != 0 { rows.append(LedgerRow(attribute: .bitterness, source: source, delta: bitterness)) }
            emit(hop.effects, source: source, into: &rows) {
                divRound($0 * slot.aromaWeightPercent * addition.quarterOunces, 400)
            }
        }

        // 5. Yeast (effects depend on the ferment temperature band)
        guard let yeastID = recipe.yeastID, let yeast = content.yeast(yeastID) else {
            throw .invalidRecipe([.unknownIngredient(recipe.yeastID ?? "")])
        }
        if let effects = yeast.effectsByTempBand[recipe.fermentTemp] {
            emit(
                effects,
                source: LedgerSource(kind: .yeast, refID: yeastID, detail: recipe.fermentTemp.rawValue),
                into: &rows)
        }

        // 6. Ferment temperature band, 7. ferment duration band
        guard let temp = content.band(for: recipe.fermentTemp) else {
            throw .invalidRecipe([.unknownIngredient("band.fermentTemp.\(recipe.fermentTemp.rawValue)")])
        }
        emit(temp.effects, source: LedgerSource(kind: .fermentTemp, refID: temp.id), into: &rows)

        guard let duration = content.band(for: recipe.fermentDuration) else {
            throw .invalidRecipe([.unknownIngredient("band.fermentDuration.\(recipe.fermentDuration.rawValue)")])
        }
        emit(duration.effects, source: LedgerSource(kind: .fermentDuration, refID: duration.id), into: &rows)

        // 7b. Yeast-specific duration effects (only yeasts that define effectsByDuration)
        if let effects = yeast.effectsByDuration[recipe.fermentDuration] {
            emit(
                effects,
                source: LedgerSource(kind: .fermentDuration, refID: yeastID, detail: recipe.fermentDuration.rawValue),
                into: &rows)
        }

        // 8. Conditioning, in step order (D-16). Dry hop adds aroma only (no IBU); fruit scales per pound.
        for step in recipe.conditioning {
            guard let info = content.conditioningInfo(for: step.kind) else { continue }
            let source = LedgerSource(kind: .conditioning, refID: step.ingredientID, detail: step.kind.rawValue)
            switch step.kind {
            case .dryHop:
                guard let hopID = step.ingredientID, let hop = content.hop(hopID), let amount = step.amount else {
                    throw .invalidRecipe([.conditioningMissingIngredient(.dryHop)])
                }
                let weight = info.aromaWeightPercent ?? 100
                emit(hop.effects, source: source, into: &rows) { divRound($0 * weight * amount, 400) }
            case .fruit:
                guard let fruitID = step.ingredientID, let fruit = content.adjunct(fruitID), let amount = step.amount else {
                    throw .invalidRecipe([.conditioningMissingIngredient(.fruit)])
                }
                emit(fruit.effects, source: source, into: &rows) { $0 * amount }
            case .lagering, .bottleConditioning:
                emit(info.effects, source: source, into: &rows)
            }
        }

        // 9. Cap rows last
        let (attributes, ledger) = finalize(rows)

        let stats = BeerStats(
            ogPoints: strength.ogPoints ?? 0, fgPoints: 0, abvTenths: 0, ibuTenths: ibuTenths, srmTenths: 0)

        let styleID = StyleClassifier.classify(attributes, styles: content.styles)
        return BrewResult(attributes: attributes, ledger: ledger, stats: stats, styleID: styleID)
    }

    /// Append one row per non-zero attribute effect, in AttributeID order.
    private static func emit(
        _ effects: EffectMap, source: LedgerSource, into rows: inout [LedgerRow],
        scale: (Int) -> Int = { $0 }
    ) {
        for attribute in AttributeID.allCases {
            let delta = scale(effects[attribute])
            if delta != 0 { rows.append(LedgerRow(attribute: attribute, source: source, delta: delta)) }
        }
    }

    /// Sum rows per attribute; clamp to 0...100 by appending an explicit `cap` row, so
    /// the visible rows always sum to the stored value (D-17 / Pitfall 2).
    package static func finalize(_ rows: [LedgerRow]) -> (AttributeVector, [LedgerRow]) {
        var sums: [AttributeID: Int] = [:]
        for row in rows { sums[row.attribute, default: 0] += row.delta }

        var ledger = rows
        var vector = AttributeVector.zero
        let capSource = LedgerSource(kind: .cap)
        for attribute in AttributeID.allCases {
            let sum = sums[attribute] ?? 0
            if sum > AttributeScale.max {
                ledger.append(LedgerRow(attribute: attribute, source: capSource, delta: AttributeScale.max - sum))
                vector[attribute] = AttributeScale.max
            } else if sum < 0 {
                ledger.append(LedgerRow(attribute: attribute, source: capSource, delta: -sum))
                vector[attribute] = 0
            } else {
                vector[attribute] = sum
            }
        }
        return (vector, ledger)
    }
}
