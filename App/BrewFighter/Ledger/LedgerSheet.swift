import BrewCore
import SwiftUI

/// Where one attribute's number comes from (D-17, BREW-04): every signed contribution in the order the
/// engine stored it (brewing-stage order, cap row last), summing to the total shown.
struct LedgerSheet: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let beer: Beer
    let attribute: AttributeID

    var body: some View {
        let name = Text(LocalizedStringKey(attribute.nameKey))
        let rows = beer.result.rows(for: attribute)
        let total = beer.result.attributes[attribute]

        VStack(spacing: 0) {
            Text("ledger.title \(name)")
                .font(.title3.bold())
                .foregroundStyle(Palette.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 8)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("ledger.heading")

            ScrollView {
                VStack(spacing: 8) {
                    if rows.isEmpty {
                        Text("ledger.empty \(name)")
                            .font(.body)
                            .foregroundStyle(Palette.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.white))
                            .accessibilityIdentifier("ledger.empty")
                    } else {
                        // Stored order is the explanation: rows are never re-sorted.
                        ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                            ledgerRow(row, at: index)
                        }
                        Divider()
                        totalRow(total)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }

            Button("ledger.close") { dismiss() }
                .buttonStyle(GameButtonStyle(.primary))
                .accessibilityIdentifier("ledger.close")
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
        .accessibilityRegion("ledger")
    }

    private func ledgerRow(_ row: LedgerRow, at index: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            row.source.labelText(in: beer, content: store.content, delta: row.delta)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(verbatim: Tenths.signed(row.delta))
                .font(.body.monospacedDigit().bold())
        }
        .foregroundStyle(Palette.ink)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(minHeight: 44)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.white))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("ledger.row.\(index)")
    }

    private func totalRow(_ total: Int) -> some View {
        HStack {
            Text("ledger.total")
                .font(.headline)
            Spacer()
            Text(verbatim: Tenths.text(total))
                .font(.headline.monospacedDigit())
        }
        .foregroundStyle(Palette.ink)
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("ledger.total")
    }
}
