import BrewCore
import SwiftUI

/// Condition: the four conditioning options (D-16) as tap-to-toggle cards, in catalog order. Dry hop
/// and fruit reveal an ingredient chooser and an amount stepper; lagering and bottle conditioning
/// exclude each other, and the blocked card says why. The total day cost sits at the top so the
/// player sees what lagering costs before committing (D-10). Conditioning is optional (D-07).
struct ConditionStageView: View {
    @Environment(GameStore.self) private var store
    let draft: RecipeDraft

    var body: some View {
        VStack(spacing: 12) {
            dayCostLine
            optionsPanel
            StageSummaryPanel(stage: .condition, draft: draft)
        }
        .accessibilityRegion("condition")
    }

    private var dayCostLine: some View {
        Text("condition.dayCost \(draft.dayCost)")
            .font(.headline)
            .foregroundStyle(Palette.ink)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Palette.amber.opacity(0.45)))
            .contentTransition(.numericText())
            .animation(.snappy, value: draft.dayCost)
            .accessibilityIdentifier("condition.dayCost")
    }

    private var optionsPanel: some View {
        Panel("condition.menu.title") {
            if draft.recipe.conditioning.isEmpty {
                Text("condition.none")
                    .font(.subheadline)
                    .accessibilityIdentifier("condition.none")
            }
            VStack(spacing: 10) {
                ForEach(store.content.conditioning, id: \.kind) { info in
                    card(for: info)
                }
            }
        }
    }

    private func card(for info: ConditioningInfo) -> some View {
        let kind = info.kind
        let step = draft.conditioningStep(kind)
        return IngredientCard(
            nameKey: info.nameKey,
            traitKeys: [],
            identifier: "condition.card.\(kind.rawValue)",
            isSelected: step != nil,
            isEnabled: step != nil || draft.canToggleConditioning(kind),
            disabledReason: LocalizedStringKey("condition.exclusive"),
            blurbKey: info.blurbKey,
            badge: Text("condition.days \(info.days)"),
            action: { draft.toggleConditioning(kind) }
        ) {
            if let step {
                switch kind {
                case .dryHop: dryHopControls(step)
                case .fruit: fruitControls(step)
                case .lagering, .bottleConditioning: EmptyView()
                }
            }
        }
    }

    // MARK: Dry hop

    private func dryHopControls(_ step: ConditioningStep) -> some View {
        let amount = step.amount ?? 1
        let hopName = Text(LocalizedStringKey(store.content.hopNameKey(step.ingredientID ?? "") ?? ""))
        let ounces = Ounces.text(quarterOunces: amount)
        return VStack(alignment: .leading, spacing: 8) {
            Text("condition.dryHop.choose")
                .font(.subheadline.bold())
            choiceGrid(store.content.hops.map { ($0.id, $0.nameKey) }, selectedID: step.ingredientID) { id in
                "condition.dryHop.hop.\(id)"
            } onSelect: { id in
                draft.setConditioningIngredient(.dryHop, id: id)
            }
            StepperButton(
                subject: hopName,
                value: Text("boil.ounces \(ounces)"),
                identifier: "condition.dryHop.amount",
                valueIdentifier: "condition.dryHop.amountValue",
                canDecrease: draft.canSetConditioningAmount(.dryHop, amount: amount - 1),
                canIncrease: draft.canSetConditioningAmount(.dryHop, amount: amount + 1),
                onDecrease: { draft.setConditioningAmount(.dryHop, amount: amount - 1) },
                onIncrease: { draft.setConditioningAmount(.dryHop, amount: amount + 1) })
        }
    }

    // MARK: Fruit

    private func fruitControls(_ step: ConditioningStep) -> some View {
        let amount = step.amount ?? 1
        let fruitName = Text(LocalizedStringKey(store.content.fruitNameKey(step.ingredientID ?? "") ?? ""))
        return VStack(alignment: .leading, spacing: 8) {
            Text("condition.fruit.choose")
                .font(.subheadline.bold())
            choiceGrid(store.content.fruits.map { ($0.id, $0.nameKey) }, selectedID: step.ingredientID) { id in
                "condition.fruit.\(id)"
            } onSelect: { id in
                draft.setConditioningIngredient(.fruit, id: id)
            }
            StepperButton(
                subject: fruitName,
                value: Text("condition.pounds \(amount)"),
                identifier: "condition.fruit.amount",
                valueIdentifier: "condition.fruit.amountValue",
                canDecrease: draft.canSetConditioningAmount(.fruit, amount: amount - 1),
                canIncrease: draft.canSetConditioningAmount(.fruit, amount: amount + 1),
                onDecrease: { draft.setConditioningAmount(.fruit, amount: amount - 1) },
                onIncrease: { draft.setConditioningAmount(.fruit, amount: amount + 1) })
        }
    }

    /// Two columns of choice buttons. Not lazy: the handful of choices stay in the accessibility tree
    /// even when scrolled out of view, so UI tests and VoiceOver can always find them.
    private func choiceGrid(
        _ choices: [(id: String, nameKey: String)], selectedID: String?,
        identifier: @escaping (String) -> String, onSelect: @escaping (String) -> Void
    ) -> some View {
        let rows = stride(from: 0, to: choices.count, by: 2).map { Array(choices[$0..<min($0 + 2, choices.count)]) }
        return Grid(horizontalSpacing: 8, verticalSpacing: 8) {
            ForEach(rows.indices, id: \.self) { index in
                GridRow {
                    ForEach(rows[index], id: \.id) { choice in
                        choiceButton(
                            nameKey: choice.nameKey, isSelected: choice.id == selectedID,
                            identifier: identifier(choice.id)
                        ) { onSelect(choice.id) }
                    }
                }
            }
        }
    }

    /// A chunky name button; the chosen one is filled and carries a checkmark, not color alone.
    private func choiceButton(
        nameKey: String, isSelected: Bool, identifier: String, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if isSelected { Image(systemName: "checkmark") }
                Text(LocalizedStringKey(nameKey))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .multilineTextAlignment(.center)
            }
            .font(.subheadline.bold())
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(GameButtonStyle(isSelected ? .primary : .secondary, size: .compact))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(identifier)
    }
}
