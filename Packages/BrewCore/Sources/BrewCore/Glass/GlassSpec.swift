import Foundation

/// An 8-bit RGB color. Plain Ints keep the glass description free of UI frameworks.
public struct RGB: Codable, Equatable, Sendable {
    public var r: Int
    public var g: Int
    public var b: Int

    public init(r: Int, g: Int, b: Int) {
        self.r = r
        self.g = g
        self.b = b
    }
}

/// The silhouette a style is served in. Raw values are the `glass` field in styles.json.
public enum GlassShape: String, Codable, Sendable, CaseIterable {
    case shaker, nonic, tulip, pilsnerFlute, weizen, snifter
}

/// A pure, Int-only description of how a beer's glass looks (D-19). The app paints it; nothing
/// here knows about SwiftUI.
public struct GlassSpec: Equatable, Sendable {
    public var shape: GlassShape
    public var liquid: RGB
    public var head: RGB
    public var headHeightPercent: Int
    public var bubbleCount: Int
    public var bubbleSpeedPermille: Int
    public var hazePercent: Int
    public var seed: UInt64

    public static func make(for beer: Beer, content: ContentCatalog) -> GlassSpec {
        // RED stub: replaced by the real derivation.
        GlassSpec(
            shape: .tulip, liquid: RGB(r: 0, g: 0, b: 0), head: RGB(r: 0, g: 0, b: 0), headHeightPercent: 6,
            bubbleCount: 4, bubbleSpeedPermille: 400, hazePercent: 0, seed: 0)
    }

    /// How different two glasses look: color distance plus head, bubbles, haze and a shape penalty.
    package func distance(to other: GlassSpec) -> Int {
        abs(liquid.r - other.liquid.r) + abs(liquid.g - other.liquid.g) + abs(liquid.b - other.liquid.b)
            + 2 * abs(headHeightPercent - other.headHeightPercent)
            + 2 * abs(bubbleCount - other.bubbleCount)
            + abs(hazePercent - other.hazePercent)
            + (shape == other.shape ? 0 : 100)
    }
}
