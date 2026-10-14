import BrewCore
import SwiftUI

/// Choices only: no attribute values and no predicted style before brewing (D-05). The live
/// preview is BREW-03 in Phase 3.
struct ReviewStageView: View {
    let draft: RecipeDraft
    @Binding var stage: WizardStage

    var body: some View {
        VStack(spacing: 12) {
            ForEach([WizardStage.mash, .boil, .ferment, .condition]) { item in
                Button {
                    stage = item
                } label: {
                    StageSummaryPanel(stage: item, draft: draft)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("review.panel.\(item.slug)")
            }
        }
    }
}

/// The BREW button. It lives in the wizard's bottom bar on the Review stage and is disabled while
/// the recipe has issues (D-07).
struct ReviewBrewButton: View {
    @Environment(GameStore.self) private var store
    let draft: RecipeDraft

    var body: some View {
        Button("review.brewButton") {
            if store.brew(draft.recipe) != nil {
                store.closeWizard()
            }
        }
        .buttonStyle(GameButtonStyle(.primary))
        .disabled(!draft.issues.isEmpty)
        .accessibilityIdentifier("review.brew")
    }
}

/// One stage's choices as catalog-backed text lines inside a Panel.
struct StageSummaryPanel: View {
    @Environment(GameStore.self) private var store
    let stage: WizardStage
    let draft: RecipeDraft

    var body: some View {
        Panel(title) {
            VStack(alignment: .leading, spacing: 4) {
                lines
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var title: LocalizedStringKey {
        switch stage {
        case .mash: LocalizedStringKey("review.panel.mash")
        case .boil: LocalizedStringKey("review.panel.boil")
        case .ferment: LocalizedStringKey("review.panel.ferment")
        case .condition: LocalizedStringKey("review.panel.condition")
        case .review: LocalizedStringKey("wizard.stage.review")
        }
    }

    @ViewBuilder
    private var lines: some View {
        let recipe = draft.recipe
        let content = store.content
        switch stage {
        case .mash:
            ForEach(recipe.grainBill.entries, id: \.fermentableID) { entry in
                let name = Text(LocalizedStringKey(content.fermentableNameKey(entry.fermentableID) ?? entry.fermentableID))
                let percent = entry.percent
                Text("review.grainLine \(name) \(percent)")
            }
            let strength = Text(LocalizedStringKey(content.strengthNameKey(recipe.strength) ?? ""))
            Text("review.strengthLine \(strength)")
            let mash = Text(LocalizedStringKey(content.mashNameKey(recipe.mashTemp) ?? ""))
            Text("review.mashTempLine \(mash)")
        case .boil:
            if recipe.hops.isEmpty {
                Text("review.noHops")
            }
            ForEach(Array(recipe.hops.enumerated()), id: \.offset) { _, hop in
                let name = Text(LocalizedStringKey(content.hopNameKey(hop.hopID) ?? hop.hopID))
                let slot = Text(LocalizedStringKey(content.slotNameKey(hop.slot) ?? ""))
                let ounces = Ounces.text(quarterOunces: hop.quarterOunces)
                Text("review.hopLine \(name) \(slot) \(ounces)")
            }
        case .ferment:
            if let yeastID = recipe.yeastID {
                Text(LocalizedStringKey(content.yeastNameKey(yeastID) ?? yeastID))
            } else {
                Text("review.noYeast")
            }
            let temp = Text(LocalizedStringKey(content.fermentTempNameKey(recipe.fermentTemp) ?? ""))
            Text("review.fermentTempLine \(temp)")
            let duration = Text(LocalizedStringKey(content.fermentDurationNameKey(recipe.fermentDuration) ?? ""))
            Text("review.fermentDurationLine \(duration)")
        case .condition:
            if recipe.conditioning.isEmpty {
                Text("review.noConditioning")
            }
            ForEach(recipe.conditioning, id: \.kind) { step in
                Text(LocalizedStringKey(content.conditioningNameKey(step.kind) ?? ""))
            }
        case .review:
            EmptyView()
        }
    }
}
