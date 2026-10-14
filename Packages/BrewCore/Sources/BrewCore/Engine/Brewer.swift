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

        // Strength, mash, temperature, duration and yeast are resolved up front: the attenuation chain
        // (D-20) must be known before the first ABV ledger row is emitted.
        guard let strength = content.band(for: recipe.strength) else {
            throw .invalidRecipe([.unknownIngredient("band.strength.\(recipe.strength.rawValue)")])
        }
        guard let mash = content.band(for: recipe.mashTemp) else {
            throw .invalidRecipe([.unknownIngredient("band.mashTemp.\(recipe.mashTemp.rawValue)")])
        }
        guard let temp = content.band(for: recipe.fermentTemp) else {
            throw .invalidRecipe([.unknownIngredient("band.fermentTemp.\(recipe.fermentTemp.rawValue)")])
        }
        guard let duration = content.band(for: recipe.fermentDuration) else {
            throw .invalidRecipe([.unknownIngredient("band.fermentDuration.\(recipe.fermentDuration.rawValue)")])
        }
        guard let yeastID = recipe.yeastID, let yeast = content.yeast(yeastID) else {
            throw .invalidRecipe([.unknownIngredient(recipe.yeastID ?? "")])
        }
        let og = strength.ogPoints ?? 0
        var chain = AttenuationChain(og: og)

        // 1. Baseline
        emit(content.baselineEffects, source: LedgerSource(kind: .baseline), into: &rows)

        // 2. Grain bill, entry order
        for entry in recipe.grainBill.entries {
            guard let info = content.fermentable(entry.fermentableID) else {
                throw .invalidRecipe([.unknownIngredient(entry.fermentableID)])
            }
            let fermentableSource = LedgerSource(kind: .fermentable, refID: entry.fermentableID)
            emit(info.effects, source: fermentableSource, into: &rows) {
                divRound($0 * entry.percent, 100)
            }
            // Grain-bill sugars (adjuncts with an attenuation bonus) raise attenuation in entry order.
            let sugar = (content.adjunct(entry.fermentableID)?.attenuationPermillePerPercent ?? 0) * entry.percent
            appendABV(chain.advance(by: sugar), source: fermentableSource, into: &rows)
        }

        // 3. Strength band, 4. mash band. The strength row carries the ABV of the reference attenuation.
        emit(strength.effects, source: LedgerSource(kind: .strength, refID: strength.id), into: &rows)
        appendABV(chain.baseABV, source: LedgerSource(kind: .strength, refID: strength.id), into: &rows)

        let mashSource = LedgerSource(kind: .mashTemp, refID: mash.id)
        emit(mash.effects, source: mashSource, into: &rows)
        let mashABV = chain.advance(by: mash.attenuationDeltaPermille ?? 0)
        appendABV(mashABV, source: mashSource, into: &rows)

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
        if let effects = yeast.effectsByTempBand[recipe.fermentTemp] {
            emit(
                effects,
                source: LedgerSource(kind: .yeast, refID: yeastID, detail: recipe.fermentTemp.rawValue),
                into: &rows)
        }
        // The yeast's attenuation (relative to the 750 reference) and, when the whole chain left the
        // 550...950 range, the clamp correction. Both are yeast-attributed; the clamp is its own row.
        let tempSource = LedgerSource(kind: .fermentTemp, refID: temp.id)
        let durationSource = LedgerSource(kind: .fermentDuration, refID: duration.id)
        let yeastABV = chain.advance(by: yeast.attenuationPermille - AttenuationChain.reference)
        let tempABV = chain.advance(by: temp.attenuationDeltaPermille ?? 0)
        let durationABV = chain.advance(by: duration.attenuationDeltaPermille ?? 0)
        let clampABV = chain.clampToLimits()
        appendABV(yeastABV, source: LedgerSource(kind: .yeast, refID: yeastID, detail: "attenuation"), into: &rows)
        appendABV(clampABV, source: LedgerSource(kind: .yeast, refID: yeastID, detail: "attenuationLimit"), into: &rows)

        // 6. Ferment temperature band, 7. ferment duration band
        emit(temp.effects, source: tempSource, into: &rows)
        appendABV(tempABV, source: tempSource, into: &rows)

        emit(duration.effects, source: durationSource, into: &rows)
        appendABV(durationABV, source: durationSource, into: &rows)

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

        // SRM: Morey over batch-strength grain weight (fixed 5-gallon batch).
        var colorUnits = 0
        for entry in recipe.grainBill.entries {
            guard let info = content.fermentable(entry.fermentableID) else {
                throw .invalidRecipe([.unknownIngredient(entry.fermentableID)])
            }
            let lbsTenths = divRound((strength.grainLbsTenths ?? 0) * entry.percent, 100)
            colorUnits += info.lovibondTenths * lbsTenths
        }
        let mcuTenths = divRound(colorUnits, 50)

        let stats = BeerStats(
            ogPoints: og, fgPoints: chain.fgPoints, abvTenths: chain.abvTenths, ibuTenths: ibuTenths,
            srmTenths: content.morey.srmTenths(mcuTenths: mcuTenths))

        let styleID = StyleClassifier.classify(attributes, styles: content.styles)
        return BrewResult(attributes: attributes, ledger: ledger, stats: stats, styleID: styleID)
    }

    /// Append the ABV ledger row for one attenuation step (zero deltas are never emitted).
    private static func appendABV(_ delta: Int, source: LedgerSource, into rows: inout [LedgerRow]) {
        if delta != 0 { rows.append(LedgerRow(attribute: .abv, source: source, delta: delta)) }
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

/// The running attenuation (permille) behind FG and ABV (D-20). Each `advance` returns the ABV
/// (tenths of a percent) that step adds, so the ABV attribute's rows telescope to exactly the ABV stat.
private struct AttenuationChain {
    /// Reference attenuation attributed to the strength band.
    static let reference = 750
    static let limits = 550...950

    let og: Int
    private(set) var attenuation = AttenuationChain.reference

    init(og: Int) { self.og = og }

    /// Final gravity in points at attenuation `a` (permille).
    private func fg(_ a: Int) -> Int { og - divRound((og - 1000) * a, 1000) }

    /// ABV in tenths of a percent at attenuation `a`: (OG - FG) x 131.25.
    private func abv(_ a: Int) -> Int { divRound((og - fg(a)) * 13125, 10000) }

    var baseABV: Int { abv(AttenuationChain.reference) }
    var fgPoints: Int { fg(attenuation) }
    var abvTenths: Int { abv(attenuation) }

    /// Move attenuation by `delta` and return the resulting change in ABV tenths.
    mutating func advance(by delta: Int) -> Int {
        let before = abv(attenuation)
        attenuation += delta
        return abv(attenuation) - before
    }

    /// Clamp into the legal range as its own step and return the ABV change (0 when already inside).
    mutating func clampToLimits() -> Int {
        let clamped = min(max(attenuation, AttenuationChain.limits.lowerBound), AttenuationChain.limits.upperBound)
        return advance(by: clamped - attenuation)
    }
}
