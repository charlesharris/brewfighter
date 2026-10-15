import BrewCore
import SwiftUI

/// The stages of the brew reveal (D-09).
enum RevealPhase: Int, Comparable {
    case vignette, dayRoll, fill, stamp, done

    static func < (lhs: RevealPhase, rhs: RevealPhase) -> Bool { lhs.rawValue < rhs.rawValue }

    var next: RevealPhase? { RevealPhase(rawValue: rawValue + 1) }
}

/// A staged, skippable 3 to 5 second reveal: brewing vignette, the day counter rolling forward, the glass
/// filling, the style stamping in (D-09). It is purely presentational. The beer was committed and saved
/// before this screen was shown, so nothing here can lose or repeat a brew, and no real-time waiting
/// ever gates the game (BREW-07). Phases advance only when the previous animation completes.
struct BrewRevealView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let beerID: UUID

    @State private var phase: RevealPhase = .vignette
    @State private var started = false
    @State private var vignetteProgress = 0.0
    @State private var shownDay = 0
    @State private var dayProgress = 0.0
    @State private var fill = 0.0
    @State private var stampProgress = 0.0

    var body: some View {
        if let beer = store.state.beers.first(where: { $0.id == beerID }) {
            reveal(beer)
        } else {
            Color.clear.onAppear { store.backToCellar() }
        }
    }

    // MARK: Events

    /// The day span this brew covered, from the events the brew emitted.
    private func daySpan(for beer: Beer) -> (from: Int, to: Int) {
        for case let .dayAdvanced(from, to) in store.lastEvents { return (from, to) }
        return (beer.brewDay, store.state.day)
    }

    private func styleID(for beer: Beer) -> String {
        for case let .styleAssigned(id, style) in store.lastEvents where id == beer.id { return style }
        return beer.result.styleID
    }

    // MARK: Layout

    private func reveal(_ beer: Beer) -> some View {
        let span = daySpan(for: beer)
        let styleKey = store.content.styleNameKey(styleID(for: beer)) ?? "style.experimental_ale.name"
        let styleName = Text(LocalizedStringKey(styleKey))
        let batchNumber = beer.batchNumber
        let spec = GlassSpec.make(for: beer, content: store.content)
        let day = phase == .vignette && !started ? span.from : shownDay
        return VStack(spacing: 20) {
            Spacer(minLength: 12)

            Text("reveal.day \(day)")
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundStyle(Palette.ink)
                .contentTransition(.numericText())
                .scaleEffect(reduceMotion ? 1 : 0.8 + 0.2 * dayProgress)
                .opacity(phase >= .dayRoll ? 1 : 0)
                .accessibilityIdentifier("reveal.day")

            ZStack {
                KettleView(progress: vignetteProgress)
                    .opacity(phase == .vignette ? 1 : 0)
                    .accessibilityHidden(true)
                GlassView(spec: spec, styleNameKey: styleKey, mode: .hero, fillFraction: fill)
                    .opacity(phase >= .fill ? 1 : 0)
                    .accessibilityIdentifier("reveal.glass")
            }
            .frame(height: 280)
            .frame(maxWidth: .infinity)

            VStack(spacing: 6) {
                Text("reveal.style \(styleName)")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)
                    .scaleEffect(reduceMotion ? 1 : 1 + 0.8 * (1 - stampProgress))
                    .rotationEffect(.degrees(reduceMotion ? 0 : -3 - 7 * (1 - stampProgress)))
                    .accessibilityIdentifier("reveal.style")
                Text("cellar.batchLabel \(batchNumber) \(styleName)")
                    .font(.subheadline)
                    .accessibilityIdentifier("reveal.batch")
            }
            .foregroundStyle(Palette.ink)
            .opacity(phase >= .stamp ? stampOpacity : 0)
            .padding(.horizontal, 16)

            Text("reveal.brewing")
                .font(.title2.bold())
                .foregroundStyle(Palette.ink)
                .opacity(phase == .vignette ? 1 : 0)
                .accessibilityIdentifier("reveal.brewing")

            Spacer(minLength: 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.foamCream.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) { bottomBar(span: span, beer: beer) }
        .accessibilityRegion("reveal")
        .onAppear { begin(span: span) }
    }

    /// Under Reduce Motion the stamp is a plain fade; otherwise it fades in quickly while it lands.
    private var stampOpacity: Double { reduceMotion ? stampProgress : min(stampProgress * 4, 1) }

    @ViewBuilder
    private func bottomBar(span: (from: Int, to: Int), beer: Beer) -> some View {
        VStack(spacing: 10) {
            if phase == .done {
                Button("reveal.details") { store.showDetail(beer.id) }
                    .buttonStyle(GameButtonStyle(.primary))
                    .accessibilityIdentifier("reveal.details")
                Button("reveal.toCellar") { store.backToCellar() }
                    .buttonStyle(GameButtonStyle(.secondary))
                    .accessibilityIdentifier("reveal.toCellar")
            } else {
                Button("reveal.skip") { skip(to: span.to) }
                    .buttonStyle(GameButtonStyle(.secondary))
                    .accessibilityIdentifier("reveal.skip")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: Sequencing

    private func begin(span: (from: Int, to: Int)) {
        guard !started else { return }
        started = true
        shownDay = reduceMotion ? span.to : span.from
        enter(.vignette, span: span)
    }

    /// Starts one phase. Its animation's completion starts the next, so there is no clock to wait on.
    private func enter(_ next: RevealPhase, span: (from: Int, to: Int)) {
        let duration = { (normal: Double) in reduceMotion ? 0.25 : normal }
        switch next {
        case .vignette:
            advance(from: .vignette, span: span, animation: .easeInOut(duration: duration(0.8))) {
                vignetteProgress = 1
            }
        case .dayRoll:
            advance(from: .dayRoll, span: span, animation: .easeOut(duration: duration(1.0))) {
                shownDay = span.to
                dayProgress = 1
            }
        case .fill:
            advance(from: .fill, span: span, animation: .easeInOut(duration: duration(1.0))) {
                fill = 1
            }
        case .stamp:
            let animation: Animation = reduceMotion ? .easeOut(duration: 0.25) : .spring(duration: 0.6, bounce: 0.35)
            advance(from: .stamp, span: span, animation: animation) {
                stampProgress = 1
            }
        case .done:
            withAnimation(.easeInOut(duration: 0.2)) { phase = .done }
        }
    }

    private func advance(
        from current: RevealPhase, span: (from: Int, to: Int), animation: Animation, changes: @escaping () -> Void
    ) {
        // The phase flips inside the same animation, so its cross-fade rides the phase's own timing and
        // never overrides the fill or day roll with a shorter implicit animation.
        withAnimation(animation, completionCriteria: .logicallyComplete) {
            phase = current
            changes()
        } completion: {
            // A skip may already have finished the reveal; a stale completion must not replay anything.
            guard phase == current, let next = current.next else { return }
            enter(next, span: span)
        }
    }

    /// Jumps straight to the final state with no animation.
    private func skip(to day: Int) {
        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            vignetteProgress = 1
            shownDay = day
            dayProgress = 1
            fill = 1
            stampProgress = 1
            phase = .done
        }
    }
}

/// A procedural brew kettle with steam puffs, drawn in one Canvas. Steam position is a function of
/// `progress` alone, so the animation is driven by the reveal's phase animation, not a clock.
private struct KettleView: View, Animatable {
    private nonisolated(unsafe) var progress: Double

    init(progress: Double) { self.progress = progress }

    nonisolated var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height * 0.62)
            let width = min(size.width * 0.5, 190)
            let height = width * 0.72
            let body = CGRect(x: center.x - width / 2, y: center.y - height / 2, width: width, height: height)
            let edge = Palette.cellarBrown

            // Handles, then the pot, rim and lid.
            for side in [-1.0, 1.0] {
                let handle = CGRect(x: center.x + side * (width / 2) - 9, y: body.minY + height * 0.2, width: 18, height: 26)
                context.stroke(Path(roundedRect: handle, cornerRadius: 9), with: .color(edge), lineWidth: 5)
            }
            let pot = Path(roundedRect: body, cornerRadius: 18)
            context.fill(pot, with: .linearGradient(
                Gradient(colors: [Palette.amber, Palette.amberDeep]),
                startPoint: CGPoint(x: body.minX, y: body.minY), endPoint: CGPoint(x: body.maxX, y: body.maxY)))
            context.stroke(pot, with: .color(edge), lineWidth: 4)
            let lid = CGRect(x: body.minX - 6, y: body.minY - 10, width: width + 12, height: 16)
            context.fill(Path(roundedRect: lid, cornerRadius: 8), with: .color(Palette.amberDeep))
            context.stroke(Path(roundedRect: lid, cornerRadius: 8), with: .color(edge), lineWidth: 4)

            // Steam puffs rise and fade; five of them, staggered, looping twice over the phase.
            for index in 0..<5 {
                let local = progress * 2 + Double(index) * 0.2
                let t = local - local.rounded(.down)
                let x = center.x + (CGFloat(index) - 2) * width * 0.16 + CGFloat(sin(local * 3 + Double(index))) * 6
                let y = lid.minY - 6 - CGFloat(t) * height * 1.1
                let radius = 8 + CGFloat(t) * 12
                let opacity = sin(t * .pi) * 0.7
                context.fill(
                    Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)),
                    with: .color(.white.opacity(opacity)))
                context.stroke(
                    Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)),
                    with: .color(edge.opacity(opacity * 0.4)), lineWidth: 1.5)
            }
        }
    }
}
