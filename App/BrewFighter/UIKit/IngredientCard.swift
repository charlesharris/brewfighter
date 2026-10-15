import SwiftUI

/// A chunky ingredient card (D-03): tap the face to pick it, qualitative trait tags instead of
/// numbers (D-05). Selection is shown by fill, a checkmark and the selected trait, never color alone.
/// The accessory sits below the face, outside the button, so its controls keep their own hit frames.
struct IngredientCard<Accessory: View>: View {
    let nameKey: String
    let traitKeys: [String]
    let identifier: String
    var isSelected = false
    var isEnabled = true
    var disabledReason: LocalizedStringKey?
    /// Optional one-line description under the name, and an optional bold tag beside the traits.
    var blurbKey: String?
    var badge: Text?
    let action: () -> Void
    private let accessory: Accessory

    init(
        nameKey: String, traitKeys: [String], identifier: String,
        isSelected: Bool = false, isEnabled: Bool = true, disabledReason: LocalizedStringKey? = nil,
        blurbKey: String? = nil, badge: Text? = nil,
        action: @escaping () -> Void, @ViewBuilder accessory: () -> Accessory
    ) {
        self.nameKey = nameKey
        self.blurbKey = blurbKey
        self.badge = badge
        self.traitKeys = traitKeys
        self.identifier = identifier
        self.isSelected = isSelected
        self.isEnabled = isEnabled
        self.disabledReason = disabledReason
        self.action = action
        self.accessory = accessory()
    }

    var body: some View {
        VStack(spacing: 8) {
            Button(action: action) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top, spacing: 4) {
                        Text(LocalizedStringKey(nameKey))
                            .font(.headline)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Palette.success)
                        }
                    }
                    if let blurbKey {
                        Text(LocalizedStringKey(blurbKey))
                            .font(.caption)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if !traitKeys.isEmpty || badge != nil {
                        ChipFlow(spacing: 4) {
                            ForEach(Array(traitKeys.prefix(3).enumerated()), id: \.offset) { _, key in
                                Text(LocalizedStringKey(key))
                                    .font(.caption2.bold())
                                    .lineLimit(1)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(Palette.cellarBrown.opacity(0.12)))
                            }
                            if let badge {
                                badge
                                    .font(.caption2.bold())
                                    .lineLimit(1)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(Palette.amber.opacity(0.6)))
                            }
                        }
                    }
                    if !isEnabled, let disabledReason {
                        Text(disabledReason)
                            .font(.caption)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .foregroundStyle(Palette.ink)
                .padding(10)
                .frame(maxWidth: .infinity, minHeight: 88, alignment: .topLeading)
            }
            .buttonStyle(CardButtonStyle(isSelected: isSelected))
            .disabled(!isEnabled)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityIdentifier(identifier)

            accessory
        }
    }
}

extension IngredientCard where Accessory == EmptyView {
    init(
        nameKey: String, traitKeys: [String], identifier: String,
        isSelected: Bool = false, isEnabled: Bool = true, disabledReason: LocalizedStringKey? = nil,
        blurbKey: String? = nil, badge: Text? = nil,
        action: @escaping () -> Void
    ) {
        self.init(
            nameKey: nameKey, traitKeys: traitKeys, identifier: identifier, isSelected: isSelected,
            isEnabled: isEnabled, disabledReason: disabledReason, blurbKey: blurbKey, badge: badge,
            action: action, accessory: { EmptyView() })
    }
}

private struct CardButtonStyle: ButtonStyle {
    let isSelected: Bool
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        configuration.label
            .background(shape.fill(isSelected ? Palette.amber.opacity(0.35) : Color.white))
            .overlay(
                shape.strokeBorder(
                    isSelected ? Palette.amberDeep : Palette.cellarBrown.opacity(0.3),
                    lineWidth: isSelected ? 3 : 2))
            .shadow(
                color: .black.opacity(isEnabled ? 0.18 : 0), radius: configuration.isPressed ? 0 : 3,
                y: configuration.isPressed ? 0 : 3)
            .opacity(isEnabled ? 1 : 0.5)
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed && isEnabled ? 0.97 : 1)
            .animation(.snappy, value: configuration.isPressed)
    }
}

/// Left-to-right wrapping row of small tags.
private struct ChipFlow: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(width: proposal.width, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(width: bounds.width, subviews: subviews)
        for (subview, origin) in zip(subviews, result.origins) {
            subview.place(at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y), proposal: .unspecified)
        }
    }

    private func arrange(width: CGFloat?, subviews: Subviews) -> (size: CGSize, origins: [CGPoint]) {
        let limit = width ?? .infinity
        var origins: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var usedWidth: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(ProposedViewSize(width: limit.isFinite ? limit : nil, height: nil))
            if x > 0, x + size.width > limit {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            usedWidth = max(usedWidth, x - spacing)
        }
        return (CGSize(width: usedWidth, height: y + rowHeight), origins)
    }
}
