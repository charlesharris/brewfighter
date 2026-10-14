import BrewCore
import Foundation
import Observation

enum PersistenceFailure: Equatable, Sendable {
    case recoveredFromBackup
    case writeFailed
    case unrecoverable
}

/// A validated, not-yet-applied import. Holds the decoded state so the confirmation can show
/// what is about to replace the cellar; nothing on disk or in the store has changed yet.
struct ImportPreview: Equatable {
    let beerCount: Int
    let day: Int
    let state: GameState

    init(state: GameState) {
        self.beerCount = state.beers.count
        self.day = state.day
        self.state = state
    }
}

/// Single source of truth. The only writer of the save file (single-writer rule).
@MainActor @Observable
final class GameStore {
    private(set) var state: GameState
    let content: ContentCatalog
    private(set) var lastEvents: [GameEvent] = []
    var screen: Screen = .cellar
    private(set) var persistenceError: PersistenceFailure?

    private let repository: SaveRepository
    private var lastExportDirectory: URL?
    private var rng = SeededRNG(seed: 0x42_52_45_57)

    init(repository: SaveRepository, content: ContentCatalog) {
        self.repository = repository
        self.content = content
        switch repository.load(content: content) {
        case let .loaded(loaded, source):
            state = loaded
            if source == .backup { persistenceError = .recoveredFromBackup }
        case .fresh:
            state = .new
        case .unrecoverable:
            // Never overwritten until the player brews.
            state = .new
            persistenceError = .unrecoverable
        }
    }

    static func live() -> GameStore {
        let repository: SaveRepository
        do {
            repository = try SaveRepository.live()
        } catch {
            fatalError("Cannot open the save directory: \(error)")
        }
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-UITestResetSave") {
            try? repository.removeAllSaves()
        }
        #endif
        let content: ContentCatalog
        do {
            content = try ContentCatalog.loadBundled()
        } catch {
            fatalError("Bundled content failed to load: \(error)")
        }
        return GameStore(repository: repository, content: content)
    }

    /// Commits the brew and persists it before returning, so any reveal is purely presentational.
    @discardableResult
    func brew(_ recipe: Recipe) -> Beer? {
        let beerID = UUID()
        let (next, events) = Reducer.apply(
            .brew(recipe: recipe, beerID: beerID), to: state, content: content, rng: &rng)
        lastEvents = events
        guard next != state else { return nil }
        state = next
        do {
            let data = try SaveCodec.encode(next)
            try repository.write(data)
            persistenceError = nil
        } catch {
            persistenceError = .writeFailed
        }
        return next.beers.first { $0.id == beerID }
    }

    // MARK: Save transfer (PLAT-03)

    static let exportFileName = "BrewFighter-Save.json"

    /// Writes the current save to a fresh temporary folder under the clean file name the share
    /// sheet will show. The previous export folder is removed first.
    func exportSaveFile() throws -> URL {
        let data = try SaveCodec.encode(state)
        let fm = FileManager.default
        if let previous = lastExportDirectory { try? fm.removeItem(at: previous) }
        let directory = fm.temporaryDirectory.appendingPathComponent("Export-\(UUID().uuidString)", isDirectory: true)
        try fm.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(Self.exportFileName)
        try data.write(to: url, options: [.atomic])
        lastExportDirectory = directory
        return url
    }

    /// Reads and validates a picked file. Only the picked URL is read, never a path found inside
    /// the file, and at most `maxSaveBytes + 1` bytes are ever pulled into memory (T-1-13, T-1-15).
    /// State and disk are untouched whether this succeeds or throws.
    func prepareImport(from url: URL) throws -> ImportPreview {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        let handle: FileHandle
        do {
            handle = try FileHandle(forReadingFrom: url)
        } catch {
            throw SaveError.unreadable
        }
        defer { try? handle.close() }

        let limit = SaveCodec.maxSaveBytes + 1
        var data = Data()
        do {
            while data.count < limit, let chunk = try handle.read(upToCount: limit - data.count), !chunk.isEmpty {
                data.append(chunk)
            }
        } catch {
            throw SaveError.unreadable
        }
        guard data.count <= SaveCodec.maxSaveBytes else { throw SaveError.tooLarge }

        return ImportPreview(state: try SaveCodec.decode(data, content: content))
    }

    /// Replaces the cellar with a previewed import. The current cellar goes to save.pre-import.json
    /// first and the replacement aborts if that write fails; the new save is written before the
    /// in-memory state changes, so any failure leaves both untouched (T-1-14).
    func confirmImport(_ preview: ImportPreview) throws {
        try repository.writePreImportBackup(SaveCodec.encode(state))
        try repository.write(SaveCodec.encode(preview.state))
        state = preview.state
        lastEvents = []
        persistenceError = nil
    }
}
