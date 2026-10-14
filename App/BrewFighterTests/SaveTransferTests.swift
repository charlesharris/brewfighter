import BrewCore
import Foundation
import Testing

@testable import BrewFighter

@MainActor
struct SaveTransferTests {
    private let content: ContentCatalog

    init() throws {
        content = try ContentCatalog.loadBundled()
    }

    // MARK: Helpers

    private func makeRepository() throws -> SaveRepository {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("SaveTransferTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return SaveRepository(directory: dir)
    }

    /// A store whose cellar holds `brews` beers: the house pale ale, then a minimal recipe each time.
    private func makeStore(brews: Int) throws -> (store: GameStore, repository: SaveRepository) {
        let repository = try makeRepository()
        let store = GameStore(repository: repository, content: content)
        for index in 0..<brews {
            if index == 0 {
                store.brew(content.housePaleAle)
            } else {
                var recipe = content.housePaleAle
                recipe.strength = .strong
                store.brew(recipe)
            }
        }
        return (store, repository)
    }

    private func writeTemp(_ data: Data) throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("SaveTransferInput-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("picked.json")
        try data.write(to: url)
        return url
    }

    /// Edits the decoded JSON tree of a save and re-serializes it.
    private func tampered(_ data: Data, _ edit: (inout [[String: Any]]) -> Void) throws -> Data {
        var object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        var payload = try #require(object["payload"] as? [String: Any])
        var beers = try #require(payload["beers"] as? [[String: Any]])
        edit(&beers)
        payload["beers"] = beers
        object["payload"] = payload
        return try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    }

    private func saveBytes(_ repository: SaveRepository) throws -> Data {
        try Data(contentsOf: repository.primaryURL)
    }

    // MARK: Export

    @Test func exportUsesTheCleanFileNameAndDecodesToTheCurrentState() throws {
        let (store, _) = try makeStore(brews: 2)
        let url = try store.exportSaveFile()
        #expect(url.lastPathComponent == "BrewFighter-Save.json")
        let decoded = try SaveCodec.decode(Data(contentsOf: url), content: content)
        #expect(decoded == store.state)
    }

    @Test func eachExportGetsAFreshFolderAndTheOldOneIsRemoved() throws {
        let (store, _) = try makeStore(brews: 1)
        let first = try store.exportSaveFile()
        let second = try store.exportSaveFile()
        #expect(first.deletingLastPathComponent() != second.deletingLastPathComponent())
        #expect(second.lastPathComponent == "BrewFighter-Save.json")
        #expect(!FileManager.default.fileExists(atPath: first.path))
    }

    // MARK: Prepare

    @Test func exportThenPrepareImportGivesAPreviewEqualToTheCurrentState() throws {
        let (store, repository) = try makeStore(brews: 2)
        let before = try saveBytes(repository)
        let preview = try store.prepareImport(from: store.exportSaveFile())
        #expect(preview.state == store.state)
        #expect(preview.beerCount == 2)
        #expect(preview.day == store.state.day)
        // Preparing is read-only.
        #expect(try saveBytes(repository) == before)
    }

    @Test func importingTheSameExportedFileTwiceYieldsEqualStates() throws {
        let (source, _) = try makeStore(brews: 2)
        let file = try source.exportSaveFile()
        let (target, _) = try makeStore(brews: 1)
        try target.confirmImport(target.prepareImport(from: file))
        let afterFirst = target.state
        try target.confirmImport(target.prepareImport(from: file))
        #expect(target.state == afterFirst)
        #expect(target.state == source.state)
    }

    // MARK: Confirm

    @Test func confirmingReplacesTheCellarAndBacksUpThePreviousOne() throws {
        let (source, _) = try makeStore(brews: 2)
        let (target, repository) = try makeStore(brews: 1)
        let previous = target.state
        let preview = try target.prepareImport(from: source.exportSaveFile())

        try target.confirmImport(preview)

        #expect(target.state == source.state)
        let preImport = try Data(contentsOf: repository.preImportURL)
        #expect(try SaveCodec.decode(preImport, content: content) == previous)
        #expect(try SaveCodec.decode(saveBytes(repository), content: content) == source.state)
        #expect(repository.load(content: content) == .loaded(source.state, source: .primary))
    }

    @Test func aFailedPreImportBackupAbortsTheReplacement() throws {
        let (source, _) = try makeStore(brews: 2)
        let (target, repository) = try makeStore(brews: 1)
        let previous = target.state
        let before = try saveBytes(repository)
        let preview = try target.prepareImport(from: source.exportSaveFile())
        // A directory squatting on the backup name makes the atomic write fail.
        try FileManager.default.createDirectory(at: repository.preImportURL, withIntermediateDirectories: false)

        #expect(throws: (any Error).self) { try target.confirmImport(preview) }

        #expect(target.state == previous)
        #expect(try saveBytes(repository) == before)
    }

    @Test func cancellingAfterPreviewLeavesEverythingUntouched() throws {
        let (source, _) = try makeStore(brews: 2)
        let (target, repository) = try makeStore(brews: 1)
        let previous = target.state
        let before = try saveBytes(repository)
        _ = try target.prepareImport(from: source.exportSaveFile())
        #expect(target.state == previous)
        #expect(try saveBytes(repository) == before)
        #expect(!FileManager.default.fileExists(atPath: repository.preImportURL.path))
    }

    // MARK: Rejections leave state and save.json untouched

    private func expectRejection(
        _ data: Data, _ expected: (SaveError) -> Bool, sourceLocation: SourceLocation = #_sourceLocation
    ) throws {
        let (store, repository) = try makeStore(brews: 1)
        let state = store.state
        let before = try saveBytes(repository)
        let url = try writeTemp(data)
        do {
            _ = try store.prepareImport(from: url)
            Issue.record("prepareImport should have thrown", sourceLocation: sourceLocation)
        } catch let error as SaveError {
            #expect(expected(error), "unexpected error \(error)", sourceLocation: sourceLocation)
        }
        #expect(store.state == state, sourceLocation: sourceLocation)
        #expect(try saveBytes(repository) == before, sourceLocation: sourceLocation)
        #expect(!FileManager.default.fileExists(atPath: repository.preImportURL.path), sourceLocation: sourceLocation)
    }

    @Test func garbageBytesAreUnreadable() throws {
        try expectRejection(Data("{ this is not a save".utf8)) { $0 == .unreadable }
    }

    @Test func aMissingFileIsUnreadable() throws {
        let (store, _) = try makeStore(brews: 1)
        let missing = FileManager.default.temporaryDirectory.appendingPathComponent("nope-\(UUID().uuidString).json")
        #expect(throws: SaveError.unreadable) { try store.prepareImport(from: missing) }
    }

    @Test func aNewerSchemaVersionIsReportedAsNewer() throws {
        let (source, _) = try makeStore(brews: 1)
        let text = try #require(String(data: SaveCodec.encode(source.state), encoding: .utf8))
        let newer = Data(text.replacingOccurrences(of: "\"schemaVersion\":1", with: "\"schemaVersion\":2").utf8)
        try expectRejection(newer) { $0 == .newerThanApp(2) }
    }

    @Test func anOversizedFileIsTooLarge() throws {
        try expectRejection(Data(count: SaveCodec.maxSaveBytes + 1)) { $0 == .tooLarge }
    }

    @Test func aFileExactlyAtTheCapIsNotCalledTooLarge() throws {
        // Zeros are not a save, but the size gate must not reject the boundary itself.
        try expectRejection(Data(count: SaveCodec.maxSaveBytes)) { $0 != .tooLarge }
    }

    @Test func anOutOfRangeAttributeIsInvalidWithItsPath() throws {
        let (source, _) = try makeStore(brews: 1)
        let data = try tampered(SaveCodec.encode(source.state)) { beers in
            var result = beers[0]["result"] as! [String: Any]
            var attributes = result["attributes"] as! [String: Any]
            attributes["body"] = 250
            result["attributes"] = attributes
            beers[0]["result"] = result
        }
        try expectRejection(data) {
            if case let .invalid(path) = $0 { return path.contains("attributes") }
            return false
        }
    }

    @Test func aRecipeNamingAnUnknownHopIsInvalid() throws {
        let (source, _) = try makeStore(brews: 1)
        let data = try tampered(SaveCodec.encode(source.state)) { beers in
            var recipe = beers[0]["recipe"] as! [String: Any]
            var hops = recipe["hops"] as! [[String: Any]]
            hops[0]["hopID"] = "hop.h99"
            recipe["hops"] = hops
            beers[0]["recipe"] = recipe
        }
        try expectRejection(data) {
            if case let .invalid(path) = $0 { return path.contains("recipe") }
            return false
        }
    }
}
