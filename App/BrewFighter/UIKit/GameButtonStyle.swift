import SwiftUI

/// Chunky tactile button: 44pt floor, 56pt default height, press scale and collapsing shadow.
/// A disabled button dims and loses its shadow, so a refused action explains itself visually.
struct GameButtonStyle: ButtonStyle {
    enum Role {
        case primary
        case secondary
    }

    enum Size {
        /// 56pt tall, generous side padding: the main action buttons.
        case regular
        /// 44pt tall, tight padding: secondary actions packed into cards.
        case compact
        /// 56x56pt: icon-only buttons such as the stepper pair.
        case square
    }

    var role: Role = .primary
    var size: Size = .regular
    @Environment(\.isEnabled) private var isEnabled

    init(_ role: Role = .primary, size: Size = .regular) {
        self.role = role
        self.size = size
    }

    func makeBody(configuration: Configuration) -> some View {
        let fill = role == .primary ? Palette.amber : Palette.foamCream
        let edge = role == .primary ? Palette.amberDeep : Palette.cellarBrown.opacity(0.4)
        let pressed = configuration.isPressed && isEnabled
        configuration.label
            .font(.headline)
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, horizontalPadding)
            .frame(minWidth: minWidth, minHeight: minHeight)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(fill))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(edge, lineWidth: 3))
            .shadow(
                color: .black.opacity(isEnabled ? 0.3 : 0),
                radius: pressed || !isEnabled ? 0 : 4, y: pressed || !isEnabled ? 0 : 4)
            .opacity(isEnabled ? 1 : 0.4)
            .contentShape(Rectangle())
            .scaleEffect(pressed ? 0.96 : 1)
            .animation(.snappy, value: configuration.isPressed)
    }

    private var horizontalPadding: CGFloat {
        switch size {
        case .regular: 20
        case .compact: 10
        case .square: 0
        }
    }

    private var minWidth: CGFloat { size == .square ? 56 : 44 }

    private var minHeight: CGFloat {
        switch size {
        case .regular, .square: 56
        case .compact: 44
        }
    }
}
