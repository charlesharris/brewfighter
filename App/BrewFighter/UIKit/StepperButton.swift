import SwiftUI

/// Big minus and plus buttons around a value (D-03), replacing the system stepper. Each button is
/// 56x56pt and can be disabled on its own; a disabled button stays visible, dimmed.
struct StepperButton: View {
    /// What is being changed, for the spoken labels ("Decrease Crystal 60").
    let subject: Text
    let value: Text
    /// Prefix for the two buttons: `<identifier>.decrease` and `<identifier>.increase`.
    let identifier: String
    let valueIdentifier: String
    var canDecrease = true
    var canIncrease = true
    let onDecrease: () -> Void
    let onIncrease: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Button(action: onDecrease) {
                Image(systemName: "minus")
            }
            .buttonStyle(GameButtonStyle(.secondary, size: .square))
            .disabled(!canDecrease)
            .accessibilityLabel(Text("stepper.decrease \(subject)"))
            .accessibilityIdentifier("\(identifier).decrease")

            value
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier(valueIdentifier)

            Button(action: onIncrease) {
                Image(systemName: "plus")
            }
            .buttonStyle(GameButtonStyle(.secondary, size: .square))
            .disabled(!canIncrease)
            .accessibilityLabel(Text("stepper.increase \(subject)"))
            .accessibilityIdentifier("\(identifier).increase")
        }
    }
}
