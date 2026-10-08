import BrewCore
import Foundation

enum SaveSource: Equatable, Sendable {
    case primary
    case backup
}

enum SaveLoadOutcome: Equatable, Sendable {
    case loaded(GameState, source: SaveSource)
    case fresh
    case unrecoverable(primary: SaveError?, backup: SaveError?)
}

/// App-side file I/O for the save. Written only from the main-actor `GameStore`.
/// Deliberately avoids preferences stores and file-timestamp APIs so the privacy
/// manifest stays empty.
struct SaveRepository: Sendable {
    let directory: URL

    static let primaryName = "save.json"
    static let backupName = "save.backup.json"

    init(directory: URL) {
        self.directory = directory
    }

    static func live() throws -> SaveRepository {
        let support = try FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let directory = support.appendingPathComponent("BrewFighter", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return SaveRepository(directory: directory)
    }

    var primaryURL: URL { directory.appendingPathComponent(Self.primaryName) }
    var backupURL: URL { directory.appendingPathComponent(Self.backupName) }

    /// Atomic write with a one-deep backup. The previous save.json is copied to
    /// save.backup.json first (as plain Data, no item-copy APIs), then save.json is
    /// replaced atomically. An interruption at any point leaves save.json as either the
    /// complete old or the complete new file, and the backup always a complete earlier save.
    func write(_ data: Data) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: directory, withIntermediateDirectories: true)
        if fm.fileExists(atPath: primaryURL.path), let previous = try? Data(contentsOf: primaryURL) {
            // A failed backup never blocks saving the new beer; atomic writes cannot damage the old backup.
            try? previous.write(to: backupURL, options: [.atomic])
        }
        try data.write(to: primaryURL, options: [.atomic])
    }

    /// Primary first, then backup. Never writes or deletes anything.
    func load() -> SaveLoadOutcome {
        let primary = attempt(primaryURL)
        if case let .state(state) = primary { return .loaded(state, source: .primary) }
        let backup = attempt(backupURL)
        if case let .state(state) = backup { return .loaded(state, source: .backup) }
        if case .missing = primary, case .missing = backup { return .fresh }
        return .unrecoverable(primary: primary.error, backup: backup.error)
    }

    func removeAllSaves() throws {
        let fm = FileManager.default
        for url in [primaryURL, backupURL] where fm.fileExists(atPath: url.path) {
            try fm.removeItem(at: url)
        }
    }

    private enum Attempt {
        case state(GameState)
        case missing
        case failed(SaveError)

        var error: SaveError? {
            if case let .failed(error) = self { return error }
            return nil
        }
    }

    private func attempt(_ url: URL) -> Attempt {
        guard FileManager.default.fileExists(atPath: url.path) else { return .missing }
        guard let data = try? Data(contentsOf: url) else { return .failed(.unreadable) }
        do {
            return .state(try SaveCodec.decode(data))
        } catch let error as SaveError {
            return .failed(error)
        } catch {
            return .failed(.unreadable)
        }
    }
}
