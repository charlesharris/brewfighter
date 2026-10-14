import Foundation

public enum ContentError: Error, Equatable, Sendable {
    case missingResource(String)
    case invalid(String)
}

/// Attribute effects keyed by AttributeID raw value, Int tenths. Decoded from a
/// JSON object (a Swift `[AttributeID: Int]` would decode as an alternating array).
package struct EffectMap: Equatable, Sendable, Decodable {
    package let values: [AttributeID: Int]

    package static let empty = EffectMap(values: [:])

    package init(values: [AttributeID: Int]) {
        self.values = values
    }

    package init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode([String: Int].self)
        var out: [AttributeID: Int] = [:]
        for (key, value) in raw {
            guard let id = AttributeID(rawValue: key) else {
                throw DecodingError.dataCorruptedError(
                    in: container, debugDescription: "Unknown attribute key '\(key)' in effects")
            }
            out[id] = value
        }
        values = out
    }

    package subscript(_ id: AttributeID) -> Int { values[id] ?? 0 }
}

public enum FermentableKind: String, Codable, Sendable, Hashable {
    case base, specialty, adjunct
}

public struct FermentableInfo: Sendable, Equatable, Decodable {
    public let id: String
    public let nameKey: String
    public let traitKeys: [String]
    public let kind: FermentableKind
    public let isBaseCapable: Bool
    public let maxPercent: Int
    package let lovibondTenths: Int
    package let effects: EffectMap

    enum CodingKeys: String, CodingKey {
        case id, nameKey, traitKeys, kind, isBaseCapable, maxPercent, lovibondTenths, effects
    }
}

public struct YeastInfo: Sendable, Equatable, Decodable {
    public let id: String
    public let nameKey: String
    public let traitKeys: [String]
    public let tempF: [FermentTempBand: Int]
    package let attenuationPermille: Int
    package let effectsByTempBand: [FermentTempBand: EffectMap]
    /// Optional per-duration effects (for example wild cultures that keep changing). Empty when absent.
    package let effectsByDuration: [FermentDurationBand: EffectMap]

    enum CodingKeys: String, CodingKey {
        case id, nameKey, traitKeys, tempF, attenuationPermille, effectsByTempBand, effectsByDuration
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        nameKey = try c.decode(String.self, forKey: .nameKey)
        traitKeys = try c.decode([String].self, forKey: .traitKeys)
        attenuationPermille = try c.decode(Int.self, forKey: .attenuationPermille)
        let rawTemps = try c.decode([String: Int].self, forKey: .tempF)
        let rawEffects = try c.decode([String: EffectMap].self, forKey: .effectsByTempBand)
        var temps: [FermentTempBand: Int] = [:]
        var effects: [FermentTempBand: EffectMap] = [:]
        for band in FermentTempBand.allCases {
            guard let t = rawTemps[band.rawValue] else {
                throw DecodingError.keyNotFound(
                    CodingKeys.tempF,
                    .init(codingPath: c.codingPath, debugDescription: "yeast \(id) missing tempF.\(band.rawValue)"))
            }
            temps[band] = t
            guard let bandEffects = rawEffects[band.rawValue] else {
                throw DecodingError.keyNotFound(
                    CodingKeys.effectsByTempBand,
                    .init(codingPath: c.codingPath, debugDescription: "yeast \(id) missing effectsByTempBand.\(band.rawValue)"))
            }
            effects[band] = bandEffects
        }
        for key in rawTemps.keys where FermentTempBand(rawValue: key) == nil {
            throw DecodingError.dataCorruptedError(
                forKey: .tempF, in: c, debugDescription: "yeast \(id) has unknown tempF band '\(key)'")
        }
        for key in rawEffects.keys where FermentTempBand(rawValue: key) == nil {
            throw DecodingError.dataCorruptedError(
                forKey: .effectsByTempBand, in: c, debugDescription: "yeast \(id) has unknown effects band '\(key)'")
        }
        let rawDurations = try c.decodeIfPresent([String: EffectMap].self, forKey: .effectsByDuration) ?? [:]
        var durations: [FermentDurationBand: EffectMap] = [:]
        for (key, value) in rawDurations {
            guard let band = FermentDurationBand(rawValue: key) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .effectsByDuration, in: c, debugDescription: "yeast \(id) has unknown duration band '\(key)'")
            }
            durations[band] = value
        }
        tempF = temps
        effectsByTempBand = effects
        effectsByDuration = durations
    }
}

/// A banded dial option (D-04). Which of the Int fields is present depends on the
/// band group; the catalog loader validates that each group carries what it needs.
public struct BandInfo: Sendable, Equatable, Decodable {
    public let id: String
    public let nameKey: String
    public let blurbKey: String
    public let ogPoints: Int?
    public let grainLbsTenths: Int?
    public let tempF: Int?
    public let days: Int?
    package let attenuationDeltaPermille: Int?
    package let effects: EffectMap

    enum CodingKeys: String, CodingKey {
        case id, nameKey, blurbKey, ogPoints, grainLbsTenths, tempF, days, attenuationDeltaPermille, effects
    }
}

public enum AdjunctUsage: String, Codable, Sendable, Hashable {
    case grainBill, fruit
}

/// An adjunct (D-13): either part of the grain bill (percent) or fruit added in conditioning (pounds).
public struct AdjunctInfo: Sendable, Equatable, Decodable {
    public let id: String
    public let nameKey: String
    public let traitKeys: [String]
    public let usage: AdjunctUsage
    public let maxPercent: Int?
    package let lovibondTenths: Int?
    package let attenuationPermillePerPercent: Int?
    package let effects: EffectMap

    enum CodingKeys: String, CodingKey {
        case id, nameKey, traitKeys, usage, maxPercent, lovibondTenths, attenuationPermillePerPercent, effects
    }
}

/// A hop variety (D-13, D-15). IDs are neutral (`hop.hNN`); the display name is a catalog key.
/// Effects are tenths per 1 oz at 100% aroma weight.
public struct HopInfo: Sendable, Equatable, Decodable {
    public let id: String
    public let nameKey: String
    public let traitKeys: [String]
    package let alphaTenths: Int
    package let effects: EffectMap

    enum CodingKeys: String, CodingKey {
        case id, nameKey, traitKeys, alphaTenths, effects
    }
}

/// A named hop slot (D-15): real minutes live in the detail text, the weight scales aroma.
public struct HopSlotInfo: Sendable, Equatable, Decodable {
    public let slot: HopSlot
    public let nameKey: String
    public let detailKey: String
    package let aromaWeightPercent: Int

    enum CodingKeys: String, CodingKey {
        case slot, nameKey, detailKey, aromaWeightPercent
    }
}

/// Generated Tinseth utilization (Int per 100,000) per slot per OG point. The generator
/// (`scripts/gen-brew-tables.swift`) is the only place floating point happens.
package struct TinsethTable: Sendable, Equatable, Decodable {
    package let ogMin: Int
    package let ogMax: Int
    private let slots: [String: [Int]]

    /// Clamps `ogPoints` into `ogMin...ogMax` before indexing, so no input can index out of range.
    package func utilizationPer100k(slot: HopSlot, ogPoints: Int) -> Int {
        let clamped = min(max(ogPoints, ogMin), ogMax)
        guard let row = slots[slot.rawValue], row.indices.contains(clamped - ogMin) else { return 0 }
        return row[clamped - ogMin]
    }

    fileprivate func validated() throws -> TinsethTable {
        guard ogMin <= ogMax else { throw ContentError.invalid("tinseth.json ogMin exceeds ogMax") }
        for slot in HopSlot.allCases {
            guard let row = slots[slot.rawValue], row.count == ogMax - ogMin + 1, row.allSatisfy({ $0 >= 0 }) else {
                throw ContentError.invalid("tinseth.json slot '\(slot.rawValue)' is missing or the wrong length")
            }
        }
        return self
    }
}

/// Generated Morey MCU -> SRM table (Int tenths to Int tenths). Index `i` is the SRM tenths for
/// `i` tenths of MCU. The generator is the only place floating point happens.
package struct MoreyTable: Sendable, Equatable, Decodable {
    package let mcuTenthsMax: Int
    private let srmTenthsTable: [Int]

    enum CodingKeys: String, CodingKey {
        case mcuTenthsMax
        case srmTenthsTable = "srmTenths"
    }

    /// Clamps the index into `0...mcuTenthsMax`, so no recipe can index out of range (T-1-11).
    package func srmTenths(mcuTenths: Int) -> Int {
        srmTenthsTable[min(max(mcuTenths, 0), mcuTenthsMax)]
    }

    fileprivate func validated() throws -> MoreyTable {
        guard mcuTenthsMax > 0, srmTenthsTable.count == mcuTenthsMax + 1, srmTenthsTable.allSatisfy({ $0 >= 0 }) else {
            throw ContentError.invalid("morey.json srmTenths must have mcuTenthsMax + 1 non-negative entries")
        }
        return self
    }
}

/// SRM color stops (RED stub: replaced by the real table).
package struct SRMColorTable: Sendable, Equatable {
    package static let stub = SRMColorTable()
    package func rgb(srmTenths: Int) -> RGB { RGB(r: 0, g: 0, b: 0) }
}

/// A conditioning menu entry (D-16). Dry hop rows come from the chosen hop scaled by
/// `aromaWeightPercent`; fruit rows come from the fruit adjunct per pound; lagering and
/// bottle conditioning use their fixed `effects`. Effects are filled by the hop-content plan.
public struct ConditioningInfo: Sendable, Equatable, Decodable {
    public let kind: ConditioningKind
    public let nameKey: String
    public let blurbKey: String
    public let days: Int
    public let amountUnitKey: String?
    package let aromaWeightPercent: Int?
    package let effects: EffectMap

    enum CodingKeys: String, CodingKey {
        case kind, nameKey, blurbKey, days, amountUnitKey, aromaWeightPercent, effects
    }
}

public struct ContentCatalog: Sendable {
    public let contentVersion: Int
    /// Grains plus the grain-bill adjuncts (kind `.adjunct`, never base-capable).
    public let fermentables: [FermentableInfo]
    public let adjuncts: [AdjunctInfo]
    public let yeasts: [YeastInfo]
    public let hops: [HopInfo]
    public let hopSlots: [HopSlotInfo]
    public let strengthBands: [BandInfo]
    public let mashBands: [BandInfo]
    public let fermentTempBands: [BandInfo]
    public let durationBands: [BandInfo]
    public let conditioning: [ConditioningInfo]
    /// The first-run starter (D-06).
    public let housePaleAle: Recipe

    package let baselineEffects: EffectMap
    package let tinseth: TinsethTable
    package let morey: MoreyTable
    package let styles: StyleTable
    private let starters: [String: Recipe]

    // MARK: Loading

    private struct ManifestFile: Decodable { let contentVersion: Int }
    private struct BaselineFile: Decodable { let effects: EffectMap }
    private struct BandsFile: Decodable {
        let baseline: BaselineFile
        let strength: [BandInfo]
        let mashTemp: [BandInfo]
        let fermentTemp: [BandInfo]
        let fermentDuration: [BandInfo]
        let hopSlots: [HopSlotInfo]
    }
    private struct GrainsFile: Decodable { let fermentables: [FermentableInfo] }
    private struct AdjunctsFile: Decodable { let adjuncts: [AdjunctInfo] }
    private struct YeastsFile: Decodable { let yeasts: [YeastInfo] }
    private struct HopsFile: Decodable { let hops: [HopInfo] }
    private struct ConditioningFile: Decodable { let conditioning: [ConditioningInfo] }
    private struct StarterEntry: Decodable { let id: String; let recipe: Recipe }
    private struct StarterFile: Decodable { let recipes: [StarterEntry] }

    private static func decode<T: Decodable>(_ type: T.Type, _ name: String, in bundle: Bundle) throws -> T {
        guard let url = bundle.url(forResource: name, withExtension: "json", subdirectory: "Content") else {
            throw ContentError.missingResource(name)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }

    public static func loadBundled() throws -> ContentCatalog {
        let bundle = Bundle.module
        let manifest = try decode(ManifestFile.self, "manifest", in: bundle)
        let bands = try decode(BandsFile.self, "bands", in: bundle)
        let grains = try decode(GrainsFile.self, "grains", in: bundle)
        let adjuncts = try decode(AdjunctsFile.self, "adjuncts", in: bundle).adjuncts
        let yeasts = try decode(YeastsFile.self, "yeasts", in: bundle)
        let hops = try decode(HopsFile.self, "hops", in: bundle).hops
        let tinseth = try decode(TinsethTable.self, "tinseth", in: bundle).validated()
        let morey = try decode(MoreyTable.self, "morey", in: bundle).validated()
        let starter = try decode(StarterFile.self, "starter_recipes", in: bundle)
        let styles = try decode(StyleTable.self, "styles", in: bundle)
        let conditioning = try decode(ConditioningFile.self, "conditioning", in: bundle).conditioning

        for kind in ConditioningKind.allCases where conditioning.filter({ $0.kind == kind }).count != 1 {
            throw ContentError.invalid("conditioning.json must define '\(kind.rawValue)' exactly once")
        }

        guard styles.fallbacks.last?.id == "experimental_ale", styles.fallbacks.last?.conditions.isEmpty == true else {
            throw ContentError.invalid("styles.json must end its fallbacks with an unconditional experimental_ale")
        }

        try validate(bands.strength, ids: StrengthBand.allCases.map(\.rawValue), group: "strength") {
            $0.ogPoints != nil && $0.grainLbsTenths != nil
        }
        try validate(bands.mashTemp, ids: MashTempBand.allCases.map(\.rawValue), group: "mashTemp") {
            $0.tempF != nil && $0.attenuationDeltaPermille != nil
        }
        try validate(bands.fermentTemp, ids: FermentTempBand.allCases.map(\.rawValue), group: "fermentTemp") {
            $0.attenuationDeltaPermille != nil
        }
        try validate(bands.fermentDuration, ids: FermentDurationBand.allCases.map(\.rawValue), group: "fermentDuration") {
            $0.days != nil && $0.attenuationDeltaPermille != nil
        }

        for slot in HopSlot.allCases where bands.hopSlots.filter({ $0.slot == slot }).count != 1 {
            throw ContentError.invalid("bands.json hopSlots must define '\(slot.rawValue)' exactly once")
        }

        var grainBillAdjuncts: [FermentableInfo] = []
        for adjunct in adjuncts {
            switch adjunct.usage {
            case .grainBill:
                guard let maxPercent = adjunct.maxPercent, let lovibond = adjunct.lovibondTenths else {
                    throw ContentError.invalid("adjuncts.json \(adjunct.id) (grainBill) needs maxPercent and lovibondTenths")
                }
                grainBillAdjuncts.append(
                    FermentableInfo(
                        id: adjunct.id, nameKey: adjunct.nameKey, traitKeys: adjunct.traitKeys, kind: .adjunct,
                        isBaseCapable: false, maxPercent: maxPercent, lovibondTenths: lovibond, effects: adjunct.effects))
            case .fruit:
                break
            }
        }

        var starters: [String: Recipe] = [:]
        for entry in starter.recipes { starters[entry.id] = entry.recipe }
        guard let house = starters["house_pale_ale"] else {
            throw ContentError.invalid("starter_recipes.json is missing house_pale_ale")
        }

        return ContentCatalog(
            contentVersion: manifest.contentVersion,
            fermentables: grains.fermentables + grainBillAdjuncts,
            adjuncts: adjuncts,
            yeasts: yeasts.yeasts,
            hops: hops,
            hopSlots: bands.hopSlots,
            strengthBands: bands.strength,
            mashBands: bands.mashTemp,
            fermentTempBands: bands.fermentTemp,
            durationBands: bands.fermentDuration,
            conditioning: conditioning,
            housePaleAle: house,
            baselineEffects: bands.baseline.effects,
            tinseth: tinseth,
            morey: morey,
            styles: styles,
            starters: starters)
    }

    private static func validate(
        _ bands: [BandInfo], ids: [String], group: String, hasRequiredFields: (BandInfo) -> Bool
    ) throws {
        for id in ids {
            guard let band = bands.first(where: { $0.id == id }) else {
                throw ContentError.invalid("bands.json \(group) is missing band '\(id)'")
            }
            guard hasRequiredFields(band) else {
                throw ContentError.invalid("bands.json \(group).\(id) is missing a required field")
            }
        }
    }

    private init(
        contentVersion: Int, fermentables: [FermentableInfo], adjuncts: [AdjunctInfo], yeasts: [YeastInfo],
        hops: [HopInfo], hopSlots: [HopSlotInfo],
        strengthBands: [BandInfo], mashBands: [BandInfo], fermentTempBands: [BandInfo], durationBands: [BandInfo],
        conditioning: [ConditioningInfo],
        housePaleAle: Recipe, baselineEffects: EffectMap, tinseth: TinsethTable, morey: MoreyTable,
        styles: StyleTable, starters: [String: Recipe]
    ) {
        self.contentVersion = contentVersion
        self.fermentables = fermentables
        self.adjuncts = adjuncts
        self.yeasts = yeasts
        self.hops = hops
        self.hopSlots = hopSlots
        self.strengthBands = strengthBands
        self.mashBands = mashBands
        self.fermentTempBands = fermentTempBands
        self.durationBands = durationBands
        self.conditioning = conditioning
        self.housePaleAle = housePaleAle
        self.baselineEffects = baselineEffects
        self.tinseth = tinseth
        self.morey = morey
        self.styles = styles
        self.starters = starters
    }

    // MARK: Lookups

    public func starterRecipe(_ id: String) -> Recipe? { starters[id] }

    /// String Catalog key for a style (or fallback) display name.
    package var srmColors: SRMColorTable { .stub }

    /// The glass shape a style is served in; unknown IDs get the plain shaker (never a crash).
    package func glassShape(forStyle id: String) -> GlassShape {
        (styles.styles + styles.fallbacks).first { $0.id == id }?.glass ?? .shaker
    }

    public func styleNameKey(_ id: String) -> String? {
        (styles.styles + styles.fallbacks).first { $0.id == id }?.nameKey
    }

    package func fermentable(_ id: String) -> FermentableInfo? { fermentables.first { $0.id == id } }
    package func yeast(_ id: String) -> YeastInfo? { yeasts.first { $0.id == id } }
    package func conditioningInfo(for kind: ConditioningKind) -> ConditioningInfo? {
        conditioning.first { $0.kind == kind }
    }

    /// Fruit adjuncts, added in conditioning by the pound.
    public var fruits: [AdjunctInfo] { adjuncts.filter { $0.usage == .fruit } }
    package func adjunct(_ id: String) -> AdjunctInfo? { adjuncts.first { $0.id == id } }
    package func containsFruit(_ id: String) -> Bool { fruits.contains { $0.id == id } }

    package func hop(_ id: String) -> HopInfo? { hops.first { $0.id == id } }
    package func hopSlot(_ slot: HopSlot) -> HopSlotInfo? { hopSlots.first { $0.slot == slot } }
    package func containsHop(_ id: String) -> Bool { hop(id) != nil }

    /// A copy with extra fermentables appended; lets tests exercise richer grain bills.
    package func appendingFermentables(_ extra: [FermentableInfo]) -> ContentCatalog {
        ContentCatalog(
            contentVersion: contentVersion, fermentables: fermentables + extra, adjuncts: adjuncts, yeasts: yeasts,
            hops: hops, hopSlots: hopSlots,
            strengthBands: strengthBands, mashBands: mashBands, fermentTempBands: fermentTempBands,
            durationBands: durationBands, conditioning: conditioning, housePaleAle: housePaleAle,
            baselineEffects: baselineEffects, tinseth: tinseth, morey: morey, styles: styles, starters: starters)
    }

    package func band(for strength: StrengthBand) -> BandInfo? { strengthBands.first { $0.id == strength.rawValue } }
    package func band(for mash: MashTempBand) -> BandInfo? { mashBands.first { $0.id == mash.rawValue } }
    package func band(for temp: FermentTempBand) -> BandInfo? { fermentTempBands.first { $0.id == temp.rawValue } }
    package func band(for duration: FermentDurationBand) -> BandInfo? {
        durationBands.first { $0.id == duration.rawValue }
    }
}
