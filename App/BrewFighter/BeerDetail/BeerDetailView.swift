import BrewCore
import SwiftUI

/// What the player tapped in the attribute list; wrapping the attribute keeps the engine enum free of
/// a retroactive Identifiable conformance.
struct LedgerTarget: Identifiable {
    let attribute: AttributeID
    var id: String { attribute.rawValue }
}

/// One beer, inspectable (D-11, D-12, D-17): grouped attribute bars, and a ledger behind every number.
struct BeerDetailView: View {
    @Environment(GameStore.self) private var store
    let beerID: UUID
    @State private var ledgerTarget: LedgerTarget?

    var body: some View {
        if let beer = store.state.beers.first(where: { $0.id == beerID }) {
            content(beer)
        } else {
            // A beer that is not in the save cannot be shown; go back instead of showing an empty screen.
            Color.clear.onAppear { store.backToCellar() }
        }
    }

    private func content(_ beer: Beer) -> some View {
        let nameKey = store.content.styleNameKey(beer.result.styleID) ?? "style.experimental_ale.name"
        let styleName = Text(LocalizedStringKey(nameKey))
        let batchNumber = beer.batchNumber
        let brewDay = beer.brewDay
        return VStack(spacing: 0) {
            HStack {
                Button("detail.back") { store.backToCellar() }
                    .buttonStyle(GameButtonStyle(.secondary, size: .compact))
                    .accessibilityIdentifier("detail.back")
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            ScrollView {
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("cellar.batchLabel \(batchNumber) \(styleName)")
                            .font(.title2.bold())
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityIdentifier("detail.title")
                        Text("cellar.brewDayLabel \(brewDay)")
                            .font(.subheadline)
                            .accessibilityIdentifier("detail.brewDay")
                    }
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    AttributeFamilyBars(beer: beer) { attribute in
                        ledgerTarget = LedgerTarget(attribute: attribute)
                    }
                }
                .padding(16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.foamCream.ignoresSafeArea())
        .sheet(item: $ledgerTarget) { target in
            LedgerSheet(beer: beer, attribute: target.attribute)
                .presentationBackground(Palette.foamCream)
                .presentationDetents([.medium, .large])
        }
        .accessibilityRegion("detail")
    }
}
