import BrewCore
import SwiftUI

/// The Cellar: root screen of the app (D-08).
struct CellarView: View {
    @Environment(GameStore.self) private var store
    @State private var showSaveTransfer = false

    var body: some View {
        let day = store.state.day
        let beers = store.state.beers.sorted { $0.batchNumber > $1.batchNumber }

        VStack(spacing: 0) {
            header(day: day)
            if let failure = store.persistenceError {
                banner(for: failure)
            }
            if beers.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(beers, id: \.id) { beer in
                            row(for: beer)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.foamCream.ignoresSafeArea())
        .sheet(isPresented: $showSaveTransfer) {
            SaveTransferSheet()
                .presentationBackground(Palette.foamCream)
                .presentationDetents([.medium])
        }
        .safeAreaInset(edge: .bottom) {
            Button("cellar.brewButton") {
                store.openWizard()
            }
            .buttonStyle(GameButtonStyle(.primary))
            .accessibilityIdentifier("cellar.brew")
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private func header(day: Int) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("cellar.title")
                    .font(.title2.bold())
                    .accessibilityIdentifier("cellar.title")
                Spacer()
                Text("cellar.dayCounter \(day)")
                    .font(.headline)
                    .contentTransition(.numericText())
                    .accessibilityIdentifier("cellar.day")
            }
            HStack {
                Spacer()
                Button("cellar.saveTransferButton") {
                    showSaveTransfer = true
                }
                .buttonStyle(GameButtonStyle(.secondary))
                .accessibilityIdentifier("cellar.saveTransfer")
            }
        }
        .foregroundStyle(Palette.ink)
        .padding(16)
    }

    @ViewBuilder
    private func banner(for failure: PersistenceFailure) -> some View {
        Group {
            switch failure {
            case .recoveredFromBackup: Text("cellar.save.recovered")
            case .writeFailed: Text("cellar.save.writeFailed")
            case .unrecoverable: Text("cellar.save.unrecoverable")
            }
        }
        .font(.subheadline)
        .foregroundStyle(Palette.ink)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Palette.amber.opacity(0.35)))
        .padding(.horizontal, 16)
        .accessibilityIdentifier("cellar.saveBanner")
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("cellar.empty.title")
                .font(.title3.bold())
            Text("cellar.empty.body")
                .font(.body)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(Palette.ink)
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("cellar.empty")
    }

    private func row(for beer: Beer) -> some View {
        let batchNumber = beer.batchNumber
        let brewDay = beer.brewDay
        let nameKey = store.content.styleNameKey(beer.result.styleID) ?? "style.experimental_ale.name"
        let styleName = Text(LocalizedStringKey(nameKey))
        return Button {
            store.showDetail(beer.id)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text("cellar.batchLabel \(batchNumber) \(styleName)")
                    .font(.headline)
                Text("cellar.brewDayLabel \(brewDay)")
                    .font(.subheadline)
            }
            .foregroundStyle(Palette.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.white))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("cellar.beer.\(batchNumber)")
    }
}
