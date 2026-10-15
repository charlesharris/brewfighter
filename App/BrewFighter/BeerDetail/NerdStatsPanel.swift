import BrewCore
import SwiftUI

/// The real brewing numbers behind a beer (D-20). Neutral reference values only: no ranking, no reward
/// framing, no "strong" or "boozy" copy (App Review 1.4.3).
struct NerdStatsPanel: View {
    let stats: BeerStats

    var body: some View {
        Panel("stats.title") {
            VStack(spacing: 6) {
                let abv = (Double(stats.abvTenths) / 10).formatted(.number.precision(.fractionLength(1)))
                row("stats.abv", label: Text("stats.abv"), value: Text("stats.percentValue \(abv)"))
                row("stats.ibu", label: Text("stats.ibu"), value: Text(verbatim: wholeNumber(tenths: stats.ibuTenths)))
                row("stats.srm", label: Text("stats.srm"), value: Text(verbatim: wholeNumber(tenths: stats.srmTenths)))
                row("stats.og", label: Text("stats.og"), value: Text(verbatim: gravity(stats.ogPoints)))
                row("stats.fg", label: Text("stats.fg"), value: Text(verbatim: gravity(stats.fgPoints)))
            }
        }
    }

    private func row(_ identifier: String, label: Text, value: Text) -> some View {
        HStack {
            label
                .font(.subheadline)
            Spacer()
            value
                .font(.subheadline.monospacedDigit().bold())
        }
        .foregroundStyle(Palette.ink)
        .frame(minHeight: 28)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(identifier)
    }

    /// Tenths rounded to a whole number (half up; the values are never negative).
    private func wholeNumber(tenths: Int) -> String {
        ((tenths + 5) / 10).formatted(.number)
    }

    /// 1050 -> "1.050"
    private func gravity(_ points: Int) -> String {
        (Double(points) / 1000).formatted(.number.precision(.fractionLength(3)))
    }
}
