import BrewCore
import SwiftUI
import UniformTypeIdentifiers

/// Export the cellar through the share sheet and import it back through the file picker (PLAT-03).
/// The share sheet, file picker and alerts are the only system chrome. An import never replaces
/// anything until the player confirms a preview; every failure leaves the cellar untouched.
struct SaveTransferSheet: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var exportURL: URL?
    @State private var showImporter = false
    @State private var pendingImport: ImportPreview?
    @State private var failure: TransferFailure?

    private enum TransferFailure: Equatable {
        case notASave
        case newer
        case tooLarge
        case writeFailed

        init(_ error: any Error) {
            switch error as? SaveError {
            case .newerThanApp: self = .newer
            case .tooLarge: self = .tooLarge
            case .unreadable, .invalid: self = .notASave
            case nil: self = .writeFailed
            }
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("saveTransfer.title")
                .font(.title2.bold())
                .accessibilityIdentifier("saveTransfer.title")
            Text("saveTransfer.body")
                .font(.body)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let exportURL {
                ShareLink(item: exportURL) {
                    Text("saveTransfer.shareButton")
                }
                .buttonStyle(GameButtonStyle(.primary))
                .accessibilityIdentifier("saveTransfer.share")
            } else {
                Button("saveTransfer.exportButton") {
                    export()
                }
                .buttonStyle(GameButtonStyle(.primary))
                .accessibilityIdentifier("saveTransfer.export")
            }

            Button("saveTransfer.importButton") {
                showImporter = true
            }
            .buttonStyle(GameButtonStyle(.secondary))
            .accessibilityIdentifier("saveTransfer.import")
        }
        .foregroundStyle(Palette.ink)
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json], allowsMultipleSelection: false) {
            handlePicked($0)
        }
        .alert(
            Text("saveTransfer.confirm.title"),
            isPresented: Binding(get: { pendingImport != nil }, set: { if !$0 { pendingImport = nil } }),
            presenting: pendingImport
        ) { preview in
            Button("saveTransfer.confirm.replace", role: .destructive) {
                replace(with: preview)
            }
            Button("saveTransfer.confirm.cancel", role: .cancel) {}
        } message: { preview in
            Text("saveTransfer.confirm.message \(preview.beerCount) \(preview.day)")
        }
        .alert(
            Text("saveTransfer.error.title"),
            isPresented: Binding(get: { failure != nil }, set: { if !$0 { failure = nil } }),
            presenting: failure
        ) { _ in
            Button("saveTransfer.error.ok", role: .cancel) {}
        } message: { failure in
            switch failure {
            case .notASave: Text("saveTransfer.error.notASave")
            case .newer: Text("saveTransfer.error.newer")
            case .tooLarge: Text("saveTransfer.error.tooLarge")
            case .writeFailed: Text("saveTransfer.error.writeFailed")
            }
        }
    }

    private func export() {
        do {
            exportURL = try store.exportSaveFile()
        } catch {
            failure = .writeFailed
        }
    }

    private func handlePicked(_ result: Result<[URL], any Error>) {
        switch result {
        case let .success(urls):
            guard let url = urls.first else { return }
            do {
                pendingImport = try store.prepareImport(from: url)
            } catch {
                failure = TransferFailure(error)
            }
        case .failure:
            failure = .notASave
        }
    }

    private func replace(with preview: ImportPreview) {
        do {
            try store.confirmImport(preview)
            exportURL = nil
            dismiss()
        } catch {
            failure = .writeFailed
        }
    }
}
