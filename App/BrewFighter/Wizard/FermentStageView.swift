import BrewCore
import SwiftUI

/// Ferment: one yeast card (D-03), a fermentation temperature band and a duration band (D-04).
/// Temperature shows the selected yeast's real degrees F small under the flavor name, because each
/// yeast has its own range. Duration shows its days, which the brew advances the day counter by (D-10).
struct FermentStageView: View {
    @Environment(GameStore.self) private var store
    let draft: RecipeDraft

    private let columns = [
        GridItem(.flexible(), spacing: 10, alignment: .top),
        GridItem(.flexible(), spacing: 10, alignment: .top),
    ]

    var body: some View {
        VStack(spacing: 12) {
            yeastPanel
            tempPanel
            durationPanel
            StageSummaryPanel(stage: .ferment, draft: draft)
        }
        .accessibilityRegion("ferment")
    }

    // MARK: Yeast

    private var yeastPanel: some View {
        Panel("ferment.yeast.title") {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(store.content.yeasts, id: \.id) { info in
                    IngredientCard(
                        nameKey: info.nameKey,
                        traitKeys: info.traitKeys,
                        identifier: "ferment.card.\(info.id)",
                        isSelected: draft.recipe.yeastID == info.id,
                        action: { draft.setYeast(info.id) })
                }
            }
        }
    }

    // MARK: Dials

    private var tempPanel: some View {
        let bands = store.content.fermentTempBands
        let yeast = store.content.yeasts.first { $0.id == draft.recipe.yeastID }
        let selected = bands.first { $0.id == draft.recipe.fermentTemp.rawValue }
        return Panel("ferment.temp.title") {
            BandDial(
                dialID: "ferment.temp",
                options: bands.map { band in
                    let degrees = FermentTempBand(rawValue: band.id).flatMap { yeast?.tempF[$0] }
                    return BandDialOption(
                        id: band.id,
                        title: Text(LocalizedStringKey(band.nameKey)),
                        detail: degrees.map { Text("band.tempF \($0)") } ?? Text("ferment.pickYeastFirst"))
                },
                selectedID: draft.recipe.fermentTemp.rawValue
            ) { id in
                if let band = FermentTempBand(rawValue: id) { draft.setFermentTemp(band) }
            }
            if let selected {
                Text(LocalizedStringKey(selected.blurbKey))
                    .font(.footnote)
            }
        }
    }

    private var durationPanel: some View {
        let bands = store.content.durationBands
        let selected = bands.first { $0.id == draft.recipe.fermentDuration.rawValue }
        return Panel("ferment.duration.title") {
            BandDial(
                dialID: "ferment.duration",
                options: bands.map { band in
                    BandDialOption(
                        id: band.id,
                        title: Text(LocalizedStringKey(band.nameKey)),
                        detail: band.days.map { Text("ferment.days \($0)") })
                },
                selectedID: draft.recipe.fermentDuration.rawValue
            ) { id in
                if let band = FermentDurationBand(rawValue: id) { draft.setFermentDuration(band) }
            }
            if let selected {
                Text(LocalizedStringKey(selected.blurbKey))
                    .font(.footnote)
            }
        }
    }
}
