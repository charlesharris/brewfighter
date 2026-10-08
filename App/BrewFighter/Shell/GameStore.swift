import BrewCore
import Foundation
import Observation

enum PersistenceFailure: Equatable, Sendable {
    case recoveredFromBackup
    case writeFailed
    case unrecoverable
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
    private var rng = SeededRNG(seed: 0x42_52_45_57)

    init(repository: SaveRepository, content: ContentCatalog) {
        self.repository = repository
        self.content = content
        switch repository.load() {
        case let .loaded(loaded, source: _):
            state = loaded
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
}
