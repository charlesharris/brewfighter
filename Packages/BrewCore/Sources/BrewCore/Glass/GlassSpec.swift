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

    /// Derives the glass from the finished beer alone: attributes and stats, the style's glass field
    /// and the batch number. All math is Int; carbonation, body, roast, tropical and fruit are
    /// attribute tenths.
    public static func make(for beer: Beer, content: ContentCatalog) -> GlassSpec {
        let attributes = beer.result.attributes
        let stats = beer.result.stats
        let carbonation = attributes[.carbonation]
        let body = attributes[.body]
        let roast = attributes[.roast]
        let tropical = attributes[.tropical]
        let fruit = attributes[.fruit]

        // Cream foam turns tan as roast rises, fully tan at 8.0.
        let roastWeight = min(roast, 80)
        func tint(_ cream: Int, _ tan: Int) -> Int { cream + divRound((tan - cream) * roastWeight, 80) }
        let head = RGB(r: tint(255, 196), g: tint(248, 160), b: tint(230, 112))

        let shape: GlassShape =
            stats.abvTenths >= snifterAbvTenths ? .snifter : content.glassShape(forStyle: beer.result.styleID)

        return GlassSpec(
            shape: shape,
            liquid: content.srmColors.rgb(srmTenths: stats.srmTenths),
            head: head,
            headHeightPercent: min(max(8 + carbonation / 4 + body / 8, 6), 35),
            bubbleCount: min(max(carbonation * 6 / 10, 4), 60),
            bubbleSpeedPermille: 400 + carbonation * 6,
            hazePercent: min(max(max(0, body - 25) * 2 + max(0, tropical - 30) + max(0, fruit - 30), 0), 80),
            seed: splitMix64(UInt64(max(beer.batchNumber, 0))))
    }

    /// 8.0% ABV and up is served in a snifter, whatever the style says.
    package static let snifterAbvTenths = 80

    /// One SplitMix64 step, so neighbouring batch numbers give unrelated seeds.
    private static func splitMix64(_ x: UInt64) -> UInt64 {
        var z = x &+ 0x9E37_79B9_7F4A_7C15
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
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
