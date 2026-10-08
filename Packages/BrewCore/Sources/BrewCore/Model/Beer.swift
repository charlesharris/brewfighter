import Foundation

public enum SourceKind: String, Codable, CaseIterable, Sendable, Hashable {
    case baseline, fermentable, strength, mashTemp, hop, yeast, fermentTemp, fermentDuration, conditioning, cap
}

/// Where a ledger row came from. Persisted as ids only; labels are composed in the
/// UI from catalog keys (never store English in a save).
public struct LedgerSource: Codable, Equatable, Sendable, Hashable {
    public var kind: SourceKind
    public var refID: String?
    public var detail: String?

    public init(kind: SourceKind, refID: String? = nil, detail: String? = nil) {
        self.kind = kind
        self.refID = refID
        self.detail = detail
    }

    enum CodingKeys: String, CodingKey {
        case kind, refID, detail
    }
}

/// One signed contribution to one attribute, in tenths.
public struct LedgerRow: Codable, Equatable, Sendable, Hashable {
    public var attribute: AttributeID
    public var source: LedgerSource
    public var delta: Int

    public init(attribute: AttributeID, source: LedgerSource, delta: Int) {
        self.attribute = attribute
        self.source = source
        self.delta = delta
    }

    enum CodingKeys: String, CodingKey {
        case attribute, source, delta
    }
}

/// Real-world brewing numbers (D-20). OG/FG are gravity points (1050 = 1.050);
/// ABV, IBU and SRM are Int tenths.
public struct BeerStats: Codable, Equatable, Sendable, Hashable {
    public var ogPoints: Int
    public var fgPoints: Int
    public var abvTenths: Int
    public var ibuTenths: Int
    public var srmTenths: Int

    public init(ogPoints: Int, fgPoints: Int, abvTenths: Int, ibuTenths: Int, srmTenths: Int) {
        self.ogPoints = ogPoints
        self.fgPoints = fgPoints
        self.abvTenths = abvTenths
        self.ibuTenths = ibuTenths
        self.srmTenths = srmTenths
    }

    enum CodingKeys: String, CodingKey {
        case ogPoints, fgPoints, abvTenths, ibuTenths, srmTenths
    }
}

public struct BrewResult: Codable, Equatable, Sendable {
    public var attributes: AttributeVector
    public var ledger: [LedgerRow]
    public var stats: BeerStats
    public var styleID: String

    public init(attributes: AttributeVector, ledger: [LedgerRow], stats: BeerStats, styleID: String) {
        self.attributes = attributes
        self.ledger = ledger
        self.stats = stats
        self.styleID = styleID
    }

    /// Ledger rows for one attribute, in stored (brewing-stage) order.
    public func rows(for attribute: AttributeID) -> [LedgerRow] {
        ledger.filter { $0.attribute == attribute }
    }

    enum CodingKeys: String, CodingKey {
        case attributes, ledger, stats, styleID
    }
}

public struct Beer: Codable, Equatable, Sendable, Identifiable {
    public var id: UUID
    public var batchNumber: Int
    public var brewDay: Int
    public var recipe: Recipe
    public var result: BrewResult
    public var contentVersion: Int

    public init(id: UUID, batchNumber: Int, brewDay: Int, recipe: Recipe, result: BrewResult, contentVersion: Int) {
        self.id = id
        self.batchNumber = batchNumber
        self.brewDay = brewDay
        self.recipe = recipe
        self.result = result
        self.contentVersion = contentVersion
    }

    enum CodingKeys: String, CodingKey {
        case id, batchNumber, brewDay, recipe, result, contentVersion
    }
}
