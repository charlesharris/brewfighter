import SwiftUI

/// A rounded, padded container with a title. Every wizard stage is built from these.
struct Panel<Content: View>: View {
    private let title: LocalizedStringKey
    private let systemImage: String?
    private let content: Content

    /// `systemImage` is an optional SF Symbol shown beside the title. It is decoration: the title
    /// carries the meaning, so the glyph is hidden from VoiceOver.
    init(_ title: LocalizedStringKey, systemImage: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .accessibilityHidden(true)
                }
                Text(title)
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
            }
            content
        }
        .foregroundStyle(Palette.ink)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Palette.cellarBrown.opacity(0.15), lineWidth: 2))
    }
}

extension View {
    /// Names a screen region for UI tests without stamping the identifier onto every child.
    func accessibilityRegion(_ identifier: String) -> some View {
        accessibilityElement(children: .contain)
            .accessibilityIdentifier(identifier)
    }
}
