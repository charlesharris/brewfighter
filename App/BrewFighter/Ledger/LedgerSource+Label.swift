import BrewCore
import SwiftUI

extension LedgerSource {
    /// One catalog sentence per source kind. Every label is a single format string with its names
    /// filled in from the catalog, never a concatenation of fragments, so translators can reorder it.
    /// `delta` is only needed for cap rows, whose wording depends on which side of the scale was hit.
    func labelText(in beer: Beer, content: ContentCatalog, delta: Int = 0) -> Text {
        switch kind {
        case .baseline:
            return Text("ledger.source.baseline")
        case .fermentable:
            let name = Self.name(content.ingredientNameKey(refID ?? ""), fallback: refID ?? "")
            let percent = beer.recipe.grainBill.entries.first { $0.fermentableID == refID }?.percent ?? 0
            return Text("ledger.source.fermentable \(name) \(percent)")
        case .strength:
            let name = Self.name(content.strengthBands.first { $0.id == refID }?.nameKey, fallback: refID ?? "")
            return Text("ledger.source.strength \(name)")
        case .mashTemp:
            let name = Self.name(content.mashBands.first { $0.id == refID }?.nameKey, fallback: refID ?? "")
            return Text("ledger.source.mashTemp \(name)")
        case .hop:
            let name = Self.name(content.hopNameKey(refID ?? ""), fallback: refID ?? "")
            let slot = Self.name(
                HopSlot(rawValue: detail ?? "").flatMap { content.slotNameKey($0) }, fallback: detail ?? "")
            return Text("ledger.source.hop \(name) \(slot)")
        case .yeast:
            if detail == "attenuationLimit" {
                return Text("ledger.source.attenuationLimit")
            }
            let name = Self.name(content.yeastNameKey(refID ?? ""), fallback: refID ?? "")
            return Text("ledger.source.yeast \(name)")
        case .fermentTemp:
            let name = Self.name(content.fermentTempBands.first { $0.id == refID }?.nameKey, fallback: refID ?? "")
            return Text("ledger.source.fermentTemp \(name)")
        case .fermentDuration:
            // A yeast-specific duration effect carries the yeast as refID and the duration band as detail.
            if let refID, let yeastKey = content.yeastNameKey(refID) {
                let yeast = Text(LocalizedStringKey(yeastKey))
                let duration = Self.name(
                    content.durationBands.first { $0.id == detail }?.nameKey, fallback: detail ?? "")
                return Text("ledger.source.yeastDuration \(yeast) \(duration)")
            }
            let name = Self.name(content.durationBands.first { $0.id == refID }?.nameKey, fallback: refID ?? "")
            return Text("ledger.source.fermentDuration \(name)")
        case .conditioning:
            switch ConditioningKind(rawValue: detail ?? "") {
            case .dryHop:
                let name = Self.name(content.hopNameKey(refID ?? ""), fallback: refID ?? "")
                return Text("ledger.source.dryHop \(name)")
            case .fruit:
                let name = Self.name(content.fruitNameKey(refID ?? ""), fallback: refID ?? "")
                return Text("ledger.source.fruit \(name)")
            case .lagering:
                return Text("ledger.source.lagering")
            case .bottleConditioning, .none:
                return Text("ledger.source.bottleConditioning")
            }
        case .cap:
            return delta < 0 ? Text("ledger.source.capMax") : Text("ledger.source.capMin")
        }
    }

    private static func name(_ key: String?, fallback: String) -> Text {
        key.map { Text(LocalizedStringKey($0)) } ?? Text(verbatim: fallback)
    }
}

extension ContentCatalog {
    /// Grain-bill ingredients are fermentables, including sugars that the content files list as adjuncts.
    func ingredientNameKey(_ id: String) -> String? {
        fermentableNameKey(id) ?? adjuncts.first { $0.id == id }?.nameKey
    }
}
