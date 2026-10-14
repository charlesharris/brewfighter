import Foundation

/// One range test over one attribute (tenths, inclusive bounds).
package struct StyleCondition: Decodable, Equatable, Sendable {
    package var attribute: AttributeID
    package var min: Int
    package var max: Int
    package var weight: Int
    package var required: Bool

    package func isSatisfied(by attributes: AttributeVector) -> Bool {
        (min...max).contains(attributes[attribute])
    }
}

package struct StyleDefinition: Decodable, Equatable, Sendable {
    package var id: String
    package var nameKey: String
    /// Percent match needed to qualify. Fallbacks omit it.
    package var threshold: Int?
    package var conditions: [StyleCondition]
    /// The glass this style is served in (D-19). Required in styles.json.
    package var glass: GlassShape

    package init(id: String, nameKey: String, threshold: Int?, conditions: [StyleCondition], glass: GlassShape = .shaker) {
        self.id = id
        self.nameKey = nameKey
        self.threshold = threshold
        self.conditions = conditions
        self.glass = glass
    }

    enum CodingKeys: String, CodingKey {
        case id, nameKey, threshold, conditions, glass
    }

    package init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        nameKey = try c.decode(String.self, forKey: .nameKey)
        threshold = try c.decodeIfPresent(Int.self, forKey: .threshold)
        conditions = try c.decode([StyleCondition].self, forKey: .conditions)
        glass = try c.decode(GlassShape.self, forKey: .glass)
    }
}

package struct StyleTable: Decodable, Equatable, Sendable {
    package var styles: [StyleDefinition]
    package var fallbacks: [StyleDefinition]
}

/// Style is computed from the finished attribute vector alone (BREW-06 / D-18):
/// no recipe, stats or ingredient IDs reach the classifier.
package enum StyleClassifier {
    package static func classify(_ attributes: AttributeVector, styles: StyleTable) -> String {
        // A style qualifies when every `required` condition holds and its weighted match
        // percent reaches the threshold. Highest percent wins; ties go to the earlier entry.
        var best: (id: String, percent: Int)?
        for style in styles.styles {
            guard let percent = qualifyingPercent(style, attributes) else { continue }
            if best == nil || percent > best!.percent { best = (style.id, percent) }
        }
        if let best { return best.id }

        // Fallbacks apply only when nothing qualified: first one whose conditions all hold.
        for fallback in styles.fallbacks where fallback.conditions.allSatisfy({ $0.isSatisfied(by: attributes) }) {
            return fallback.id
        }
        // A well-formed table ends with an unconditional experimental_ale (the loader enforces it).
        return "experimental_ale"
    }

    /// The style's match percent when it qualifies, otherwise nil.
    private static func qualifyingPercent(_ style: StyleDefinition, _ attributes: AttributeVector) -> Int? {
        var totalWeight = 0
        var satisfiedWeight = 0
        for condition in style.conditions {
            let satisfied = condition.isSatisfied(by: attributes)
            if condition.required && !satisfied { return nil }
            totalWeight += condition.weight
            if satisfied { satisfiedWeight += condition.weight }
        }
        let percent = totalWeight == 0 ? 100 : satisfiedWeight * 100 / totalWeight
        return percent >= (style.threshold ?? 0) ? percent : nil
    }
}
