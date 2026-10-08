import Foundation

// The recipe carries no style field of any kind (BREW-06): style is computed
// from the finished attribute vector and can never be a recipe input.

public enum StrengthBand: String, Codable, CaseIterable, Sendable, Hashable {
    case session, standard, strong, imperial
}

public enum MashTempBand: String, Codable, CaseIterable, Sendable, Hashable {
    case low, medium, high
}

public enum FermentTempBand: String, Codable, CaseIterable, Sendable, Hashable {
    case cold, balanced, warm
}

public enum FermentDurationBand: String, Codable, CaseIterable, Sendable, Hashable {
    case quick, standard, extended
}

public enum HopSlot: String, Codable, CaseIterable, Sendable, Hashable {
    case bittering, flavor, aroma, whirlpool
}

public enum ConditioningKind: String, Codable, CaseIterable, Sendable, Hashable {
    case dryHop, fruit, lagering, bottleConditioning
}

public struct GrainEntry: Codable, Equatable, Sendable, Hashable {
    public var fermentableID: String
    public var percent: Int

    public init(fermentableID: String, percent: Int) {
        self.fermentableID = fermentableID
        self.percent = percent
    }

    enum CodingKeys: String, CodingKey {
        case fermentableID, percent
    }
}

public struct GrainBill: Codable, Equatable, Sendable, Hashable {
    /// The explicit base malt (never "the largest entry"): see D-14 / Pitfall 7.
    public var baseID: String?
    public var entries: [GrainEntry]

    public init(baseID: String? = nil, entries: [GrainEntry] = []) {
        self.baseID = baseID
        self.entries = entries
    }

    enum CodingKeys: String, CodingKey {
        case baseID, entries
    }
}

public struct HopAddition: Codable, Equatable, Sendable, Hashable {
    public var hopID: String
    public var slot: HopSlot
    public var quarterOunces: Int

    public init(hopID: String, slot: HopSlot, quarterOunces: Int) {
        self.hopID = hopID
        self.slot = slot
        self.quarterOunces = quarterOunces
    }

    enum CodingKeys: String, CodingKey {
        case hopID, slot, quarterOunces
    }
}

public struct ConditioningStep: Codable, Equatable, Sendable, Hashable {
    public var kind: ConditioningKind
    public var ingredientID: String?
    public var amount: Int?

    public init(kind: ConditioningKind, ingredientID: String? = nil, amount: Int? = nil) {
        self.kind = kind
        self.ingredientID = ingredientID
        self.amount = amount
    }

    enum CodingKeys: String, CodingKey {
        case kind, ingredientID, amount
    }
}

public struct Recipe: Codable, Equatable, Sendable, Hashable {
    public var grainBill: GrainBill
    public var strength: StrengthBand
    public var mashTemp: MashTempBand
    public var hops: [HopAddition]
    public var yeastID: String?
    public var fermentTemp: FermentTempBand
    public var fermentDuration: FermentDurationBand
    public var conditioning: [ConditioningStep]

    public init(
        grainBill: GrainBill = GrainBill(),
        strength: StrengthBand = .standard,
        mashTemp: MashTempBand = .medium,
        hops: [HopAddition] = [],
        yeastID: String? = nil,
        fermentTemp: FermentTempBand = .balanced,
        fermentDuration: FermentDurationBand = .standard,
        conditioning: [ConditioningStep] = []
    ) {
        self.grainBill = grainBill
        self.strength = strength
        self.mashTemp = mashTemp
        self.hops = hops
        self.yeastID = yeastID
        self.fermentTemp = fermentTemp
        self.fermentDuration = fermentDuration
        self.conditioning = conditioning
    }

    enum CodingKeys: String, CodingKey {
        case grainBill, strength, mashTemp, hops, yeastID, fermentTemp, fermentDuration, conditioning
    }
}

/// Reasons a recipe cannot be brewed or an edit is refused (D-07 and the edit rules).
public enum RecipeIssue: Equatable, Sendable, Hashable {
    case noGrain
    case noYeast
    case billNotHundred
    case unknownIngredient(String)
    case baseNotBaseCapable
    case baseBelowMinimum
    case grainOutOfRange(String)
    case duplicateFermentable(String)
    case hopAmountOutOfRange(Int)
    case duplicateHopSlot(String)
    case tooManyHopAdditions
    case conditioningConflict
    case duplicateConditioning(ConditioningKind)
    case conditioningMissingIngredient(ConditioningKind)
    case conditioningAmountOutOfRange(ConditioningKind)
}
