import Foundation

/// Bounds and referential checks on a decoded `GameState`. Every decoded save, from disk or from
/// an import, passes through here before the app trusts it (T-1-13): nothing downstream multiplies
/// a number that has not been range-checked.
///
/// The bounds sit above what the engine itself can produce (the most extreme legal recipe is about
/// 21,700 IBU tenths and about 900 SRM tenths), so every beer the engine can brew validates.
/// Throws `SaveError.invalid(path)` on the first violation, where the path reads like
/// `beers[2].result.attributes.body`.
package enum SaveValidator {
    package static let dayRange = 1...1_000_000
    package static let maxBeers = 10_000
    package static let maxLedgerDelta = 1000
    package static let ogRange = 1000...1200
    package static let abvTenthsRange = 0...200
    package static let ibuTenthsRange = 0...50_000
    package static let srmTenthsRange = 0...1500
    package static let fgFloor = 990

    package static func validate(_ state: GameState, content: ContentCatalog) throws {
        // The beer count comes first: it bounds every loop below.
        guard state.beers.count <= maxBeers else { throw SaveError.invalid("beers") }
        guard dayRange.contains(state.day) else { throw SaveError.invalid("day") }

        var seenIDs = Set<UUID>()
        var previousBatch = 0
        for (index, beer) in state.beers.enumerated() {
            let path = "beers[\(index)]"
            guard seenIDs.insert(beer.id).inserted else { throw SaveError.invalid("\(path).id") }
            guard beer.batchNumber >= 1, beer.batchNumber > previousBatch else {
                throw SaveError.invalid("\(path).batchNumber")
            }
            previousBatch = beer.batchNumber
            guard (1...state.day).contains(beer.brewDay) else { throw SaveError.invalid("\(path).brewDay") }
            guard beer.contentVersion >= 1 else { throw SaveError.invalid("\(path).contentVersion") }
            guard RecipeRules.validate(beer.recipe, content: content).isEmpty else {
                throw SaveError.invalid("\(path).recipe")
            }
            try validate(beer.result, path: "\(path).result", content: content)
        }

        guard state.nextBatchNumber == previousBatch + 1 else { throw SaveError.invalid("nextBatchNumber") }
    }

    private static func validate(_ result: BrewResult, path: String, content: ContentCatalog) throws {
        guard content.styleNameKey(result.styleID) != nil else { throw SaveError.invalid("\(path).styleID") }

        for attribute in AttributeID.allCases {
            guard (0...AttributeScale.max).contains(result.attributes[attribute]) else {
                throw SaveError.invalid("\(path).attributes.\(attribute.rawValue)")
            }
        }

        // Each row is bounded before any row is added to a sum.
        var sums: [AttributeID: Int] = [:]
        for (rowIndex, row) in result.ledger.enumerated() {
            // A range check, not abs(): abs(Int.min) would trap on a hostile file.
            guard (-maxLedgerDelta...maxLedgerDelta).contains(row.delta) else {
                throw SaveError.invalid("\(path).ledger[\(rowIndex)].delta")
            }
            sums[row.attribute, default: 0] += row.delta
        }
        for attribute in AttributeID.allCases where (sums[attribute] ?? 0) != result.attributes[attribute] {
            throw SaveError.invalid("\(path).ledger.\(attribute.rawValue)")
        }

        let stats = result.stats
        guard ogRange.contains(stats.ogPoints) else { throw SaveError.invalid("\(path).stats.ogPoints") }
        guard (fgFloor...stats.ogPoints).contains(stats.fgPoints) else { throw SaveError.invalid("\(path).stats.fgPoints") }
        guard abvTenthsRange.contains(stats.abvTenths) else { throw SaveError.invalid("\(path).stats.abvTenths") }
        guard ibuTenthsRange.contains(stats.ibuTenths) else { throw SaveError.invalid("\(path).stats.ibuTenths") }
        guard srmTenthsRange.contains(stats.srmTenths) else { throw SaveError.invalid("\(path).stats.srmTenths") }
    }
}
