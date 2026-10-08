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
        // D-07 validation floor. (Task 3 moves this into RecipeRules.validate.)
        var issues: [RecipeIssue] = []
        if recipe.grainBill.baseID == nil || recipe.grainBill.entries.isEmpty { issues.append(.noGrain) }
        if recipe.yeastID == nil { issues.append(.noYeast) }
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

        // 8. Cap rows last
        let (attributes, ledger) = finalize(rows)

        let stats = BeerStats(
            ogPoints: strength.ogPoints ?? 0, fgPoints: 0, abvTenths: 0, ibuTenths: 0, srmTenths: 0)

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
