import SwiftUI

struct BandDialOption: Identifiable {
    let id: String
    let title: Text
    let detail: Text?
}

/// A banded dial (D-04): equal-width chunky segments with a flavor-text name and the real number
/// small underneath. Replaces the system segmented picker. Each segment is a button with the
/// identifier `<dialID>.<optionID>`; the selected one is filled and carries a dot, not color alone.
struct BandDial: View {
    let dialID: String
    let options: [BandDialOption]
    let selectedID: String
    let onSelect: (String) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            ForEach(options) { option in
                let isSelected = option.id == selectedID
                Button {
                    onSelect(option.id)
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: isSelected ? "circle.inset.filled" : "circle")
                            .font(.caption)
                        option.title
                            .font(.subheadline.bold())
                            .lineLimit(2)
                            .minimumScaleFactor(0.6)
                            .multilineTextAlignment(.center)
                        if let detail = option.detail {
                            detail
                                .font(.caption2)
                                .lineLimit(2)
                                .minimumScaleFactor(0.7)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .foregroundStyle(Palette.ink)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(SegmentButtonStyle(isSelected: isSelected))
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .accessibilityIdentifier("\(dialID).\(option.id)")
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(minHeight: 64)
    }
}

private struct SegmentButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        configuration.label
            .frame(minHeight: 64)
            .background(shape.fill(isSelected ? Palette.amber : Palette.foamCream))
            .overlay(shape.strokeBorder(isSelected ? Palette.amberDeep : Palette.cellarBrown.opacity(0.4), lineWidth: 3))
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.snappy, value: configuration.isPressed)
    }
}
