import BrewCore
import SwiftUI

/// Paints a `GlassSpec` (D-19, ART-01): a glass silhouette per shape, the liquid in the SRM color, a haze
/// overlay, a settled foam head with a scalloped top, and rising bubbles. Everything drawn comes from the
/// spec; nothing here decides what a beer looks like.
///
/// `.hero` runs a stateless bubble emitter inside one `TimelineView` (positions are a pure function of
/// time); `.thumbnail` draws a single still frame and has no timeline, so a grid never runs N timelines.
/// `fillFraction` is animatable, which lets the brew reveal pour the glass full.
struct GlassView: View, Animatable {
    enum Mode {
        case hero
        case thumbnail
    }

    private let spec: GlassSpec
    private let styleNameKey: String
    private let mode: Mode
    // Read by the nonisolated Animatable requirement; only SwiftUI writes it, during animation.
    private nonisolated(unsafe) var fillFraction: Double
    private let colors: GlassColors
    private let bubbles: [Bubble]

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @State private var appeared = false

    init(spec: GlassSpec, styleNameKey: String, mode: Mode = .hero, fillFraction: Double = 1) {
        self.spec = spec
        self.styleNameKey = styleNameKey
        self.mode = mode
        self.fillFraction = fillFraction
        self.colors = GlassColors(spec)
        // Thumbnails are small and still, so a dozen bubbles read as carbonation without the cost.
        self.bubbles = Bubble.make(seed: spec.seed, count: min(spec.bubbleCount, mode == .hero ? 60 : 12))
    }

    nonisolated var animatableData: Double {
        get { fillFraction }
        set { fillFraction = newValue }
    }

    var body: some View {
        let shapeKey = "glass.shape.\(spec.shape.rawValue)"
        let style = Text(LocalizedStringKey(styleNameKey))
        let shape = Text(LocalizedStringKey(shapeKey))
        Group {
            switch mode {
            case .hero:
                // Reduce Motion pauses the timeline: the bubbles hold still at a fixed phase.
                TimelineView(.animation(paused: accessibilityReduceMotion)) { timeline in
                    canvas(time: accessibilityReduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate)
                }
            case .thumbnail:
                canvas(time: 0)
            }
        }
        .opacity(accessibilityReduceMotion && !appeared ? 0 : 1)
        .onAppear {
            if accessibilityReduceMotion {
                withAnimation(.easeIn(duration: 0.3)) { appeared = true }
            } else {
                appeared = true
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("glass.a11y \(style) \(shape)"))
    }

    private func canvas(time: Double) -> some View {
        Canvas { context, size in
            draw(into: &context, size: size, time: time)
        }
    }

    // MARK: Drawing

    private func draw(into context: inout GraphicsContext, size: CGSize, time: Double) {
        let geometry = GlassGeometry(shape: spec.shape, size: size)
        let fill = min(max(fillFraction, 0), 1)
        let outline = geometry.bowlPath()
        let lineWidth: CGFloat = mode == .hero ? 3 : 2

        // The glass itself: a faint body and the stem and foot of stemmed shapes.
        context.fill(outline, with: .color(.white.opacity(0.35)))
        if let stem = geometry.stemPath() {
            context.fill(stem, with: .color(.white.opacity(0.45)))
            context.stroke(stem, with: .color(colors.edge), style: StrokeStyle(lineWidth: lineWidth, lineJoin: .round))
        }

        if fill > 0.001 {
            let levelTop = geometry.bowlBottom - geometry.bowlHeight * 0.96 * fill
            let headHeight = geometry.bowlHeight * CGFloat(spec.headHeightPercent) / 100 * fill
            let liquidTop = levelTop + headHeight

            context.drawLayer { layer in
                layer.clip(to: outline)

                // Liquid body.
                let liquidRect = CGRect(
                    x: geometry.rect.minX, y: levelTop, width: geometry.rect.width,
                    height: geometry.bowlBottom - levelTop + 1)
                layer.fill(
                    Path(liquidRect),
                    with: .linearGradient(
                        Gradient(colors: [colors.liquidTop, colors.liquidBottom]),
                        startPoint: CGPoint(x: 0, y: levelTop), endPoint: CGPoint(x: 0, y: geometry.bowlBottom)))

                // Haze: a milky veil over the liquid, up to half opacity.
                if spec.hazePercent > 0 {
                    layer.fill(
                        Path(CGRect(x: liquidRect.minX, y: liquidTop, width: liquidRect.width, height: liquidRect.maxY - liquidTop)),
                        with: .color(colors.haze.opacity(Double(spec.hazePercent) / 100 * 0.5 * colors.hazeVisibility)))
                }

                // Rising bubbles (carbonation), a pure function of time.
                drawBubbles(into: &layer, geometry: geometry, liquidTop: liquidTop, time: time)

                // Foam head with a scalloped top.
                layer.fill(
                    headPath(geometry: geometry, levelTop: levelTop, height: headHeight), with: .color(colors.head))
                layer.stroke(
                    headPath(geometry: geometry, levelTop: levelTop, height: headHeight),
                    with: .color(colors.headShade), lineWidth: 1)
            }
        }

        // Highlight along the left wall, then the outline on top.
        context.stroke(
            geometry.highlightPath(), with: .color(.white.opacity(0.55)),
            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        context.stroke(outline, with: .color(colors.edge), style: StrokeStyle(lineWidth: lineWidth, lineJoin: .round))
    }

    private func headPath(geometry: GlassGeometry, levelTop: CGFloat, height: CGFloat) -> Path {
        let scallops = 7
        let left = geometry.rect.minX
        let right = geometry.rect.maxX
        let width = (right - left) / CGFloat(scallops)
        let bump = max(geometry.bowlHeight * 0.03, 2)
        var path = Path()
        path.move(to: CGPoint(x: left, y: levelTop))
        for index in 0..<scallops {
            let x = left + CGFloat(index) * width
            path.addQuadCurve(
                to: CGPoint(x: x + width, y: levelTop),
                control: CGPoint(x: x + width / 2, y: levelTop - bump * 2))
        }
        path.addLine(to: CGPoint(x: right, y: levelTop + height))
        path.addLine(to: CGPoint(x: left, y: levelTop + height))
        path.closeSubpath()
        return path
    }

    private func drawBubbles(
        into layer: inout GraphicsContext, geometry: GlassGeometry, liquidTop: CGFloat, time: Double
    ) {
        let floor = geometry.bowlBottom - 4
        guard floor - liquidTop > 6 else { return }
        // Carbonation sets the speed: permille is 400...1000, so a rise takes roughly 3 to 7 seconds.
        let rate = Double(spec.bubbleSpeedPermille) / 1000 * 0.35
        for bubble in bubbles {
            let progress = fract(bubble.phase + time * rate * bubble.rate)
            let y = floor - CGFloat(progress) * (floor - liquidTop)
            let t = (y - geometry.bowlTop) / geometry.bowlHeight
            let reach = geometry.halfWidth(at: t) * 0.72
            let x = geometry.centerX + (bubble.u * 2 - 1) * reach
            let opacity = 0.7 * (1 - progress * progress * progress)
            let rect = CGRect(x: x - bubble.radius, y: y - bubble.radius, width: bubble.radius * 2, height: bubble.radius * 2)
            layer.fill(Path(ellipseIn: rect), with: .color(.white.opacity(opacity * 0.5)))
            layer.stroke(Path(ellipseIn: rect), with: .color(.white.opacity(opacity)), lineWidth: 0.8)
        }
    }

    private func fract(_ value: Double) -> Double { value - value.rounded(.down) }
}

// MARK: - Resolved colors

/// Colors are resolved once per view value, never inside the draw loop.
private struct GlassColors {
    let liquidTop: Color
    let liquidBottom: Color
    let head: Color
    let headShade: Color
    let haze: Color
    /// Haze reads as a milky veil on pale beer but turns a dark beer muddy gray, so it fades with darkness.
    let hazeVisibility: Double
    let edge = Palette.cellarBrown.opacity(0.6)

    init(_ spec: GlassSpec) {
        func color(_ rgb: RGB, scale: Double = 1) -> Color {
            Color(
                red: min(Double(rgb.r) / 255 * scale, 1), green: min(Double(rgb.g) / 255 * scale, 1),
                blue: min(Double(rgb.b) / 255 * scale, 1))
        }
        liquidTop = color(spec.liquid)
        liquidBottom = color(spec.liquid, scale: 0.8)
        head = color(spec.head)
        headShade = color(spec.head, scale: 0.8)
        haze = Color(red: 1, green: 0.96, blue: 0.86)
        let lightness = (0.299 * Double(spec.liquid.r) + 0.587 * Double(spec.liquid.g) + 0.114 * Double(spec.liquid.b)) / 255
        hazeVisibility = min(max(lightness * 1.6, 0.2), 1)
    }
}

// MARK: - Bubbles

/// One bubble of the stateless emitter. Derived from the spec's seed alone, so a beer's bubbles are
/// the same every time it is drawn.
private struct Bubble {
    let u: CGFloat
    let phase: Double
    let radius: CGFloat
    let rate: Double

    static func make(seed: UInt64, count: Int) -> [Bubble] {
        var state = seed
        func next() -> UInt64 {
            // SplitMix64
            state = state &+ 0x9E37_79B9_7F4A_7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            return z ^ (z >> 31)
        }
        func unit() -> Double { Double(next() >> 11) / Double(1 << 53) }
        return (0..<max(count, 0)).map { _ in
            Bubble(u: CGFloat(unit()), phase: unit(), radius: CGFloat(1 + unit() * 2), rate: 0.7 + unit() * 0.6)
        }
    }
}

// MARK: - Silhouettes

/// Where the glass sits inside the canvas and what its walls look like.
private struct GlassGeometry {
    let shape: GlassShape
    /// The widest extent of the bowl, centered in the canvas.
    let rect: CGRect
    let bowlTop: CGFloat
    let bowlBottom: CGFloat
    let footY: CGFloat
    let centerX: CGFloat
    let halfMax: CGFloat

    var bowlHeight: CGFloat { bowlBottom - bowlTop }

    /// Profile control points: (position down the bowl 0...1, half width as a fraction of the maximum).
    private static func profile(_ shape: GlassShape) -> [(CGFloat, CGFloat)] {
        switch shape {
        case .shaker: [(0, 1.0), (1, 0.76)]
        case .nonic: [(0, 0.96), (0.1, 1.0), (0.2, 0.93), (1, 0.74)]
        case .tulip: [(0, 0.70), (0.1, 0.66), (0.45, 1.0), (0.85, 0.74), (1, 0.26)]
        case .pilsnerFlute: [(0, 1.0), (0.5, 0.72), (1, 0.30)]
        case .weizen: [(0, 1.0), (0.18, 0.84), (0.5, 0.60), (0.8, 0.52), (1, 0.56)]
        case .snifter: [(0, 0.55), (0.12, 0.80), (0.5, 1.0), (0.85, 0.80), (1, 0.30)]
        }
    }

    /// Share of the glass height taken by the bowl; the rest is stem and foot.
    private static func bowlShare(_ shape: GlassShape) -> CGFloat {
        switch shape {
        case .shaker, .nonic, .weizen: 1.0
        case .pilsnerFlute: 0.86
        case .tulip: 0.74
        case .snifter: 0.70
        }
    }

    /// Width over height of the whole glass.
    private static func aspect(_ shape: GlassShape) -> CGFloat {
        switch shape {
        case .shaker, .nonic: 0.66
        case .tulip: 0.62
        case .pilsnerFlute: 0.40
        case .weizen: 0.52
        case .snifter: 0.72
        }
    }

    init(shape: GlassShape, size: CGSize) {
        self.shape = shape
        let margin: CGFloat = 4
        let height = max(size.height - margin * 2, 1)
        let width = min(height * Self.aspect(shape), max(size.width - margin * 2, 1))
        let fittedHeight = min(height, width / Self.aspect(shape))
        let top = (size.height - fittedHeight) / 2
        halfMax = width / 2
        centerX = size.width / 2
        bowlTop = top
        bowlBottom = top + fittedHeight * Self.bowlShare(shape)
        footY = top + fittedHeight
        rect = CGRect(x: size.width / 2 - width / 2, y: top, width: width, height: fittedHeight)
    }

    /// Half width of the bowl at `t` (0 at the rim, 1 at the base), smoothly interpolated.
    func halfWidth(at t: CGFloat) -> CGFloat {
        let points = Self.profile(shape)
        let clamped = min(max(t, 0), 1)
        for index in 1..<points.count where clamped <= points[index].0 {
            let (t0, w0) = points[index - 1]
            let (t1, w1) = points[index]
            let local = (clamped - t0) / max(t1 - t0, 0.0001)
            let eased = local * local * (3 - 2 * local)
            return (w0 + (w1 - w0) * eased) * halfMax
        }
        return (points.last?.1 ?? 1) * halfMax
    }

    func bowlPath() -> Path {
        let steps = 48
        var path = Path()
        for step in 0...steps {
            let t = CGFloat(step) / CGFloat(steps)
            let point = CGPoint(x: centerX - halfWidth(at: t), y: bowlTop + t * bowlHeight)
            if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        for step in stride(from: steps, through: 0, by: -1) {
            let t = CGFloat(step) / CGFloat(steps)
            path.addLine(to: CGPoint(x: centerX + halfWidth(at: t), y: bowlTop + t * bowlHeight))
        }
        path.closeSubpath()
        return path
    }

    /// Stem and foot for stemmed glasses; nil for shapes that stand on their base.
    func stemPath() -> Path? {
        guard footY - bowlBottom > 1 else { return nil }
        let stemHalf = max(halfMax * 0.07, 2)
        let footHalf = halfMax * 0.62
        let footHeight = max((footY - bowlBottom) * 0.22, 3)
        var path = Path()
        path.addRect(CGRect(x: centerX - stemHalf, y: bowlBottom - 1, width: stemHalf * 2, height: footY - bowlBottom - footHeight + 1))
        path.addRoundedRect(
            in: CGRect(x: centerX - footHalf, y: footY - footHeight, width: footHalf * 2, height: footHeight),
            cornerSize: CGSize(width: footHeight / 2, height: footHeight / 2))
        return path
    }

    func highlightPath() -> Path {
        var path = Path()
        let steps = 20
        for step in 0...steps {
            let t = 0.12 + 0.7 * CGFloat(step) / CGFloat(steps)
            let point = CGPoint(x: centerX - halfWidth(at: t) * 0.78, y: bowlTop + t * bowlHeight)
            if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        return path
    }
}
