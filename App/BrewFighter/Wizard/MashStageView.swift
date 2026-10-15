import BrewCore
import SwiftUI

/// Mash: the grain bill in percent (D-14), batch strength and mash temperature on banded dials (D-04).
/// Cards show trait tags, never numbers (D-05). Every edit goes through the draft, so controls that
/// would break the bill are disabled by asking the rules first.
struct MashStageView: View {
    @Environment(GameStore.self) private var store
    let draft: RecipeDraft

    private let columns = [
        GridItem(.flexible(), spacing: 10, alignment: .top),
        GridItem(.flexible(), spacing: 10, alignment: .top),
    ]

    var body: some View {
        VStack(spacing: 12) {
            grainBillPanel
            strengthPanel
            mashTempPanel
            StageSummaryPanel(stage: .mash, draft: draft)
        }
        .accessibilityRegion("mash")
    }

    // MARK: Grain bill

    private var grainBillPanel: some View {
        let total = draft.recipe.grainBill.entries.reduce(0) { $0 + $1.percent }
        return Panel("mash.grainBill.title") {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(store.content.fermentables, id: \.id) { info in
                    card(for: info)
                }
            }
            Text("mash.total \(total)")
                .font(.subheadline.bold())
                .accessibilityIdentifier("mash.total")
        }
    }

    private func card(for info: FermentableInfo) -> some View {
        let id = info.id
        let percent = draft.percent(of: id)
        let isSelected = percent != nil
        let billIsEmpty = draft.recipe.grainBill.entries.isEmpty
        let reason = billIsEmpty ? LocalizedStringKey("mash.needBase") : LocalizedStringKey("mash.noRoom")
        return IngredientCard(
            nameKey: info.nameKey,
            traitKeys: info.traitKeys,
            identifier: "mash.card.\(id)",
            isSelected: isSelected,
            isEnabled: isSelected || draft.canAddFermentable(id),
            disabledReason: reason,
            action: { draft.addFermentable(id) }
        ) {
            if let percent {
                selectedControls(for: info, percent: percent)
            }
        }
    }

    @ViewBuilder
    private func selectedControls(for info: FermentableInfo, percent: Int) -> some View {
        let id = info.id
        let step = RecipeRules.percentStep
        if draft.isBase(id) {
            HStack(spacing: 6) {
                Text("mash.baseBadge")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Palette.amber))
                Text("mash.percent \(percent)")
                    .font(.headline)
                    .accessibilityIdentifier("mash.percent.\(id)")
                Spacer(minLength: 0)
                removeButton(id)
            }
        } else {
            StepperButton(
                subject: Text(LocalizedStringKey(info.nameKey)),
                value: Text("mash.percent \(percent)"),
                identifier: "mash.step.\(id)",
                valueIdentifier: "mash.percent.\(id)",
                canDecrease: draft.canStepFermentable(id, by: -step),
                canIncrease: draft.canStepFermentable(id, by: step),
                onDecrease: { draft.stepFermentable(id, by: -step) },
                onIncrease: { draft.stepFermentable(id, by: step) })
            HStack(spacing: 6) {
                if info.isBaseCapable {
                    Button("mash.makeBase") { draft.makeBase(id) }
                        .buttonStyle(GameButtonStyle(.secondary, size: .compact))
                        .disabled(!draft.canMakeBase(id))
                        .accessibilityIdentifier("mash.makeBase.\(id)")
                }
                Spacer(minLength: 0)
                removeButton(id)
            }
        }
    }

    private func removeButton(_ id: String) -> some View {
        Button {
            draft.removeFermentable(id)
        } label: {
            Label("mash.remove", systemImage: "xmark")
                .labelStyle(.iconOnly)
        }
        .buttonStyle(GameButtonStyle(.secondary, size: .compact))
        .accessibilityIdentifier("mash.remove.\(id)")
    }

    // MARK: Dials

    private var strengthPanel: some View {
        let bands = store.content.strengthBands
        let selected = bands.first { $0.id == draft.recipe.strength.rawValue }
        return Panel("mash.strength.title") {
            BandDial(
                dialID: "mash.strength",
                options: bands.map { band in
                    let og = band.ogPoints.map { (Double($0) / 1000).formatted(.number.precision(.fractionLength(3))) }
                    return BandDialOption(
                        id: band.id,
                        title: Text(LocalizedStringKey(band.nameKey)),
                        detail: og.map { Text("mash.og \($0)") })
                },
                selectedID: draft.recipe.strength.rawValue
            ) { id in
                if let band = StrengthBand(rawValue: id) { draft.setStrength(band) }
            }
            if let selected {
                Text(LocalizedStringKey(selected.blurbKey))
                    .font(.footnote)
            }
        }
    }

    private var mashTempPanel: some View {
        let bands = store.content.mashBands
        let selected = bands.first { $0.id == draft.recipe.mashTemp.rawValue }
        return Panel("mash.temp.title") {
            BandDial(
                dialID: "mash.temp",
                options: bands.map { band in
                    BandDialOption(
                        id: band.id,
                        title: Text(LocalizedStringKey(band.nameKey)),
                        detail: band.tempF.map { Text("band.tempF \($0)") })
                },
                selectedID: draft.recipe.mashTemp.rawValue
            ) { id in
                if let band = MashTempBand(rawValue: id) { draft.setMashTemp(band) }
            }
            if let selected {
                Text(LocalizedStringKey(selected.blurbKey))
                    .font(.footnote)
            }
        }
    }
}
