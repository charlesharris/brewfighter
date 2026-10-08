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
}

package struct StyleTable: Decodable, Equatable, Sendable {
    package var styles: [StyleDefinition]
    package var fallbacks: [StyleDefinition]
}

/// Style is computed from the finished attribute vector alone (BREW-06 / D-18):
/// no recipe, stats or ingredient IDs reach the classifier.
package enum StyleClassifier {
    package static func classify(_ attributes: AttributeVector, styles: StyleTable) -> String {
        // RED stub: real scoring lands in the GREEN commit.
        "experimental_ale"
    }
}
