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

    enum CodingKeys: String, CodingKey {
        case id, nameKey, traitKeys, tempF, attenuationPermille, effectsByTempBand
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
            effects[band] = rawEffects[band.rawValue] ?? .empty
        }
        for key in rawTemps.keys where FermentTempBand(rawValue: key) == nil {
            throw DecodingError.dataCorruptedError(
                forKey: .tempF, in: c, debugDescription: "yeast \(id) has unknown tempF band '\(key)'")
        }
        for key in rawEffects.keys where FermentTempBand(rawValue: key) == nil {
            throw DecodingError.dataCorruptedError(
                forKey: .effectsByTempBand, in: c, debugDescription: "yeast \(id) has unknown effects band '\(key)'")
        }
        tempF = temps
        effectsByTempBand = effects
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

/// A conditioning menu entry (D-16). Effects are filled by the hop-content plan.
public struct ConditioningInfo: Sendable, Equatable, Decodable {
    public let kind: ConditioningKind
    public let nameKey: String
    public let blurbKey: String
    public let days: Int
    public let amountUnitKey: String?
    package let effects: EffectMap

    enum CodingKeys: String, CodingKey {
        case kind, nameKey, blurbKey, days, amountUnitKey, effects
    }
}

public struct ContentCatalog: Sendable {
    public let contentVersion: Int
    public let fermentables: [FermentableInfo]
    public let yeasts: [YeastInfo]
    public let strengthBands: [BandInfo]
    public let mashBands: [BandInfo]
    public let fermentTempBands: [BandInfo]
    public let durationBands: [BandInfo]
    public let conditioning: [ConditioningInfo]
    /// The first-run starter (D-06).
    public let housePaleAle: Recipe

    package let baselineEffects: EffectMap
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
    }
    private struct GrainsFile: Decodable { let fermentables: [FermentableInfo] }
    private struct YeastsFile: Decodable { let yeasts: [YeastInfo] }
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
        let yeasts = try decode(YeastsFile.self, "yeasts", in: bundle)
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

        var starters: [String: Recipe] = [:]
        for entry in starter.recipes { starters[entry.id] = entry.recipe }
        guard let house = starters["house_pale_ale"] else {
            throw ContentError.invalid("starter_recipes.json is missing house_pale_ale")
        }

        return ContentCatalog(
            contentVersion: manifest.contentVersion,
            fermentables: grains.fermentables,
            yeasts: yeasts.yeasts,
            strengthBands: bands.strength,
            mashBands: bands.mashTemp,
            fermentTempBands: bands.fermentTemp,
            durationBands: bands.fermentDuration,
            conditioning: conditioning,
            housePaleAle: house,
            baselineEffects: bands.baseline.effects,
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
        contentVersion: Int, fermentables: [FermentableInfo], yeasts: [YeastInfo],
        strengthBands: [BandInfo], mashBands: [BandInfo], fermentTempBands: [BandInfo], durationBands: [BandInfo],
        conditioning: [ConditioningInfo],
        housePaleAle: Recipe, baselineEffects: EffectMap, styles: StyleTable, starters: [String: Recipe]
    ) {
        self.contentVersion = contentVersion
        self.fermentables = fermentables
        self.yeasts = yeasts
        self.strengthBands = strengthBands
        self.mashBands = mashBands
        self.fermentTempBands = fermentTempBands
        self.durationBands = durationBands
        self.conditioning = conditioning
        self.housePaleAle = housePaleAle
        self.baselineEffects = baselineEffects
        self.styles = styles
        self.starters = starters
    }

    // MARK: Lookups

    public func starterRecipe(_ id: String) -> Recipe? { starters[id] }

    /// String Catalog key for a style (or fallback) display name.
    public func styleNameKey(_ id: String) -> String? {
        (styles.styles + styles.fallbacks).first { $0.id == id }?.nameKey
    }

    package func fermentable(_ id: String) -> FermentableInfo? { fermentables.first { $0.id == id } }
    package func yeast(_ id: String) -> YeastInfo? { yeasts.first { $0.id == id } }
    package func conditioningInfo(for kind: ConditioningKind) -> ConditioningInfo? {
        conditioning.first { $0.kind == kind }
    }

    /// Hop content arrives in plan 01-03; until then no hop ID resolves.
    package func containsHop(_ id: String) -> Bool { false }

    /// A copy with extra fermentables appended; lets tests exercise richer grain bills.
    package func appendingFermentables(_ extra: [FermentableInfo]) -> ContentCatalog {
        ContentCatalog(
            contentVersion: contentVersion, fermentables: fermentables + extra, yeasts: yeasts,
            strengthBands: strengthBands, mashBands: mashBands, fermentTempBands: fermentTempBands,
            durationBands: durationBands, conditioning: conditioning, housePaleAle: housePaleAle,
            baselineEffects: baselineEffects, styles: styles, starters: starters)
    }

    package func band(for strength: StrengthBand) -> BandInfo? { strengthBands.first { $0.id == strength.rawValue } }
    package func band(for mash: MashTempBand) -> BandInfo? { mashBands.first { $0.id == mash.rawValue } }
    package func band(for temp: FermentTempBand) -> BandInfo? { fermentTempBands.first { $0.id == temp.rawValue } }
    package func band(for duration: FermentDurationBand) -> BandInfo? {
        durationBands.first { $0.id == duration.rawValue }
    }
}
