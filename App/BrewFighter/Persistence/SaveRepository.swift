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

    func write(_ data: Data) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: primaryURL, options: [.atomic])
    }

    func load() -> SaveLoadOutcome {
        guard let data = try? Data(contentsOf: primaryURL) else { return .fresh }
        do {
            return .loaded(try SaveCodec.decode(data), source: .primary)
        } catch let error as SaveError {
            return .unrecoverable(primary: error, backup: nil)
        } catch {
            return .unrecoverable(primary: .unreadable, backup: nil)
        }
    }

    func removeAllSaves() throws {
        let fm = FileManager.default
        if fm.fileExists(atPath: primaryURL.path) {
            try fm.removeItem(at: primaryURL)
        }
    }
}
