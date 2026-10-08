import SwiftUI

/// Chunky tactile button: 44pt floor, 56pt default height, press scale and collapsing shadow.
struct GameButtonStyle: ButtonStyle {
    enum Role {
        case primary
        case secondary
    }

    var role: Role = .primary

    init(_ role: Role = .primary) {
        self.role = role
    }

    func makeBody(configuration: Configuration) -> some View {
        let fill = role == .primary ? Palette.amber : Palette.foamCream
        let edge = role == .primary ? Palette.amberDeep : Palette.cellarBrown.opacity(0.4)
        configuration.label
            .font(.headline)
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, 20)
            .frame(minWidth: 44, minHeight: 56)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(fill))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(edge, lineWidth: 3))
            .shadow(color: .black.opacity(0.3), radius: configuration.isPressed ? 0 : 4, y: configuration.isPressed ? 0 : 4)
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.snappy, value: configuration.isPressed)
    }
}
