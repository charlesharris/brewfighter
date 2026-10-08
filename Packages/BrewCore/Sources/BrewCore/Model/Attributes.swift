import Foundation

/// The 16 sensory attributes. Order here is the canonical iteration order used
/// everywhere (ledger cap rows, vector encoding checks, UI listing).
public enum AttributeID: String, Codable, CaseIterable, Sendable, Hashable {
    case malt, sweetness, dryness, body, bitterness, hopAroma, citrus, tropical, herbal, spice, roast, fruit, funk, sour, carbonation, abv

    public var family: AttributeFamily {
        switch self {
        case .malt, .sweetness, .roast: return .malt
        case .bitterness, .hopAroma, .citrus, .tropical, .herbal: return .hop
        case .fruit, .spice, .funk, .sour: return .yeast
        case .body, .dryness, .carbonation, .abv: return .mouthfeel
        }
    }

    /// String Catalog key for the attribute's display name.
    public var nameKey: String { "attribute.\(rawValue).name" }
}

/// Cross-phase contract (D-11 / ENC-08): each attribute belongs to exactly one family.
public enum AttributeFamily: String, Codable, CaseIterable, Sendable, Hashable {
    case malt, hop, yeast, mouthfeel

    public var attributes: [AttributeID] {
        switch self {
        case .malt: return [.malt, .sweetness, .roast]
        case .hop: return [.bitterness, .hopAroma, .citrus, .tropical, .herbal]
        case .yeast: return [.fruit, .spice, .funk, .sour]
        case .mouthfeel: return [.body, .dryness, .carbonation, .abv]
        }
    }

    public var nameKey: String { "family.\(rawValue).name" }
}

/// Attribute scale: Int tenths, 0...100 (shown as 0.0 to 10.0).
public enum AttributeScale {
    public static let max = 100
}

/// A value for each of the 16 attributes, in tenths (0...100 after capping).
/// Encodes as a JSON object with exactly the 16 raw-value keys; decoding fails
/// on a missing or unknown key.
public struct AttributeVector: Equatable, Sendable, Codable {
    private var storage: [AttributeID: Int]

    public static let zero = AttributeVector([:])

    /// Missing attributes default to 0.
    public init(_ values: [AttributeID: Int] = [:]) {
        var s: [AttributeID: Int] = [:]
        for id in AttributeID.allCases { s[id] = values[id] ?? 0 }
        storage = s
    }

    public package(set) subscript(_ id: AttributeID) -> Int {
        get { storage[id] ?? 0 }
        set { storage[id] = newValue }
    }

    private struct Key: CodingKey {
        var stringValue: String
        var intValue: Int? { nil }
        init(_ string: String) { stringValue = string }
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        let known = Set(AttributeID.allCases.map(\.rawValue))
        for key in container.allKeys where !known.contains(key.stringValue) {
            throw DecodingError.dataCorruptedError(
                forKey: key, in: container, debugDescription: "Unknown attribute key '\(key.stringValue)'")
        }
        var s: [AttributeID: Int] = [:]
        for id in AttributeID.allCases {
            s[id] = try container.decode(Int.self, forKey: Key(id.rawValue))
        }
        storage = s
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        for id in AttributeID.allCases {
            try container.encode(storage[id] ?? 0, forKey: Key(id.rawValue))
        }
    }
}
