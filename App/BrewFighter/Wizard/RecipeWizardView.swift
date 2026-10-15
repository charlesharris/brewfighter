import BrewCore
import SwiftUI

/// The brewing stages, in order (D-01). The player may move back freely and jump to any stage (D-02).
enum WizardStage: Int, CaseIterable, Identifiable {
    case mash, boil, ferment, condition, review

    var id: Int { rawValue }

    /// Stable suffix for accessibility identifiers.
    var slug: String {
        switch self {
        case .mash: "mash"
        case .boil: "boil"
        case .ferment: "ferment"
        case .condition: "condition"
        case .review: "review"
        }
    }

    var chipTitle: LocalizedStringKey {
        switch self {
        case .mash: LocalizedStringKey("wizard.stage.mash")
        case .boil: LocalizedStringKey("wizard.stage.boil")
        case .ferment: LocalizedStringKey("wizard.stage.ferment")
        case .condition: LocalizedStringKey("wizard.stage.condition")
        case .review: LocalizedStringKey("wizard.stage.review")
        }
    }

    var previous: WizardStage? { WizardStage(rawValue: rawValue - 1) }
    var next: WizardStage? { WizardStage(rawValue: rawValue + 1) }
}

/// One screen with a stage state machine, not pushed navigation: custom chrome, and Back, Next and
/// BREW sit in the bottom safe-area bar where a thumb rests (PLAT-01).
struct RecipeWizardView: View {
    @Environment(GameStore.self) private var store
    @State private var draft: RecipeDraft
    @State private var stage: WizardStage = .mash

    init(content: ContentCatalog) {
        _draft = State(initialValue: RecipeDraft(content: content))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            progress
            ScrollView {
                stageBody
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
            }
            .id(stage)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.foamCream.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) { bottomBar }
        .accessibilityRegion("wizard")
    }

    private var header: some View {
        HStack {
            Button("wizard.close") { store.closeWizard() }
                .buttonStyle(GameButtonStyle(.secondary, size: .compact))
                .accessibilityIdentifier("wizard.close")
            Spacer()
            Button("wizard.clear") { draft.clear() }
                .buttonStyle(GameButtonStyle(.secondary, size: .compact))
                .accessibilityIdentifier("wizard.clear")
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    /// Five tappable chips. The current one is filled and carries a check, so it is not color-only.
    private var progress: some View {
        HStack(spacing: 4) {
            ForEach(WizardStage.allCases) { item in
                let isCurrent = item == stage
                Button {
                    stage = item
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: isCurrent ? "checkmark.circle.fill" : "circle")
                        Text(item.chipTitle)
                            .font(.caption.bold())
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                            .multilineTextAlignment(.center)
                    }
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(isCurrent ? Palette.amber : Palette.foamCream))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(isCurrent ? Palette.amberDeep : Palette.cellarBrown.opacity(0.3), lineWidth: 2))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isCurrent ? .isSelected : [])
                .accessibilityIdentifier("wizard.stage.\(item.slug)")
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private var stageBody: some View {
        switch stage {
        case .review:
            ReviewStageView(draft: draft, stage: $stage)
        case .mash:
            MashStageView(draft: draft)
        case .boil:
            BoilStageView(draft: draft)
        case .ferment, .condition:
            StageSummaryPanel(stage: stage, draft: draft)
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            if let previous = stage.previous {
                Button("wizard.back") { stage = previous }
                    .buttonStyle(GameButtonStyle(.secondary))
                    .accessibilityIdentifier("wizard.back")
            }
            if let next = stage.next {
                Button("wizard.next") { stage = next }
                    .buttonStyle(GameButtonStyle(.primary))
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("wizard.next")
            } else {
                ReviewBrewButton(draft: draft)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Palette.foamCream.opacity(0.95))
    }
}
