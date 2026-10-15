import BrewCore
import SwiftUI

/// Number formatting for tenths-scale values (attributes, ledger deltas). Numbers are locale-formatted
/// but never catalog strings.
enum Tenths {
    /// 25 -> "2.5"
    static func text(_ tenths: Int) -> String {
        (Double(tenths) / 10).formatted(.number.precision(.fractionLength(1)))
    }

    /// 25 -> "+2.5", -10 -> "\u{2212}1.0" (true minus sign)
    static func signed(_ tenths: Int) -> String {
        let magnitude = text(abs(tenths))
        return tenths < 0 ? "\u{2212}\(magnitude)" : "+\(magnitude)"
    }
}

/// The 16 attributes as four family groups of bars with the exact number at each bar's end (D-11).
/// Attributes below 0.5 are collapsed behind a per-family "Show N more" button.
struct AttributeFamilyBars: View {
    /// Below this many tenths an attribute is considered absent and tucked away.
    static let nearZeroTenths = 5

    let beer: Beer
    let onSelect: (AttributeID) -> Void
    @State private var expanded: Set<AttributeFamily> = []

    var body: some View {
        VStack(spacing: 12) {
            ForEach(AttributeFamily.allCases, id: \.self) { family in
                familyPanel(family)
            }
        }
    }

    private func familyPanel(_ family: AttributeFamily) -> some View {
        let isExpanded = expanded.contains(family)
        let hidden = family.attributes.filter { beer.result.attributes[$0] < Self.nearZeroTenths }
        let shown = isExpanded ? family.attributes : family.attributes.filter { !hidden.contains($0) }
        let hiddenCount = hidden.count
        return Panel(LocalizedStringKey(family.nameKey), systemImage: Self.glyph(family)) {
            VStack(spacing: 6) {
                ForEach(shown, id: \.self) { attribute in
                    row(attribute)
                }
                if !isExpanded && hiddenCount > 0 {
                    Button("detail.showMore \(hiddenCount)") {
                        withAnimation(.snappy) { _ = expanded.insert(family) }
                    }
                    .buttonStyle(GameButtonStyle(.secondary, size: .compact))
                    .accessibilityIdentifier("detail.showMore.\(family.rawValue)")
                }
            }
        }
        .accessibilityRegion("detail.family.\(family.rawValue)")
    }

    private func row(_ attribute: AttributeID) -> some View {
        let value = beer.result.attributes[attribute]
        let name = Text(LocalizedStringKey(attribute.nameKey))
        let number = Tenths.text(value)
        return Button {
            onSelect(attribute)
        } label: {
            HStack(spacing: 10) {
                name
                    .font(.subheadline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(width: 104, alignment: .leading)
                bar(value)
                Text(verbatim: number)
                    .font(.subheadline.monospacedDigit().bold())
                    .frame(width: 40, alignment: .trailing)
            }
            .foregroundStyle(Palette.ink)
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("detail.attribute.a11y \(name) \(number)"))
        .accessibilityIdentifier("detail.attribute.\(attribute.rawValue)")
    }

    private func bar(_ value: Int) -> some View {
        let fraction = Double(min(max(value, 0), AttributeScale.max)) / Double(AttributeScale.max)
        return GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Palette.cellarBrown.opacity(0.12))
                Capsule()
                    .fill(Palette.amber)
                    .overlay(Capsule().strokeBorder(Palette.amberDeep, lineWidth: 1.5))
                    .frame(width: max(proxy.size.width * fraction, value > 0 ? 8 : 0))
            }
        }
        .frame(height: 14)
        .accessibilityHidden(true)
    }

    /// SF Symbols as a system affordance; the family name always accompanies the glyph.
    private static func glyph(_ family: AttributeFamily) -> String {
        switch family {
        case .malt: "leaf"
        case .hop: "circle.hexagongrid"
        case .yeast: "bubbles.and.sparkles"
        case .mouthfeel: "drop"
        }
    }
}
