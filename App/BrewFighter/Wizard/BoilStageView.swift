import BrewCore
import SwiftUI

/// Boil: pick a named hop slot (D-15), tap hop cards to add them to it, and adjust each addition in
/// quarter-ounce steps. Hops are optional, so an empty schedule is fine (D-07). Cards show trait
/// tags, never numbers (D-05).
struct BoilStageView: View {
    @Environment(GameStore.self) private var store
    let draft: RecipeDraft
    @State private var selectedSlot: HopSlot = .aroma

    private let columns = [
        GridItem(.flexible(), spacing: 10, alignment: .top),
        GridItem(.flexible(), spacing: 10, alignment: .top),
    ]

    var body: some View {
        VStack(spacing: 12) {
            slotPanel
            hopsPanel
            additionsPanel
            StageSummaryPanel(stage: .boil, draft: draft)
        }
        .accessibilityRegion("boil")
    }

    // MARK: Slot

    private var slotPanel: some View {
        Panel("boil.slot.title") {
            BandDial(
                dialID: "boil.slot",
                options: store.content.hopSlots.map { info in
                    BandDialOption(
                        id: info.slot.rawValue,
                        title: Text(LocalizedStringKey(info.nameKey)),
                        detail: Text(LocalizedStringKey(info.detailKey)))
                },
                selectedID: selectedSlot.rawValue
            ) { id in
                if let slot = HopSlot(rawValue: id) { selectedSlot = slot }
            }
        }
    }

    // MARK: Hop cards

    private var hopsPanel: some View {
        Panel("boil.hops.title") {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(store.content.hops, id: \.id) { info in
                    card(for: info)
                }
            }
        }
    }

    private func card(for info: HopInfo) -> some View {
        let id = info.id
        let slot = selectedSlot
        let existing = draft.recipe.hops.first { $0.hopID == id && $0.slot == slot }
        let canAdd = draft.canAddHop(id, slot: slot)
        let reason: LocalizedStringKey =
            existing == nil ? LocalizedStringKey("boil.maxAdditions") : LocalizedStringKey("boil.maxAmount")
        return IngredientCard(
            nameKey: info.nameKey,
            traitKeys: info.traitKeys,
            identifier: "boil.card.\(id)",
            isSelected: existing != nil,
            isEnabled: canAdd,
            disabledReason: reason,
            action: { draft.addHop(id, slot: slot) })
    }

    // MARK: Schedule

    private var additionsPanel: some View {
        let hops = draft.recipe.hops
        return Panel("boil.additions.title") {
            if hops.isEmpty {
                Text("boil.empty")
                    .font(.subheadline)
                    .accessibilityIdentifier("boil.empty")
            }
            ForEach(Array(hops.enumerated()), id: \.offset) { index, hop in
                additionRow(index: index, hop: hop)
            }
        }
    }

    private func additionRow(index: Int, hop: HopAddition) -> some View {
        let content = store.content
        let hopName = Text(LocalizedStringKey(content.hopNameKey(hop.hopID) ?? hop.hopID))
        let slotName = Text(LocalizedStringKey(content.slotNameKey(hop.slot) ?? ""))
        let ounces = Ounces.text(quarterOunces: hop.quarterOunces)
        return VStack(alignment: .leading, spacing: 6) {
            Text("boil.additionLine \(hopName) \(slotName)")
                .font(.subheadline.bold())
                .accessibilityIdentifier("boil.additionLine.\(index)")
            StepperButton(
                subject: hopName,
                value: Text("boil.ounces \(ounces)"),
                identifier: "boil.step.\(index)",
                valueIdentifier: "boil.ounces.\(index)",
                canDecrease: draft.canStepHop(at: index, by: -1),
                canIncrease: draft.canStepHop(at: index, by: 1),
                onDecrease: { draft.stepHop(at: index, by: -1) },
                onIncrease: { draft.stepHop(at: index, by: 1) })
        }
        .accessibilityRegion("boil.addition.\(index)")
    }
}
