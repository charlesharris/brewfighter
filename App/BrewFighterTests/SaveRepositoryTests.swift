import BrewCore
import Foundation
import Testing

@testable import BrewFighter

struct SaveRepositoryTests {
    private let content: ContentCatalog

    init() throws {
        content = try ContentCatalog.loadBundled()
    }

    private func makeRepository() throws -> SaveRepository {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("SaveRepositoryTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return SaveRepository(directory: dir)
    }

    private func sampleState(day: Int) -> GameState {
        GameState(day: day, nextBatchNumber: 1, beers: [])
    }

    private func primaryURL(_ repo: SaveRepository) -> URL {
        repo.directory.appendingPathComponent("save.json")
    }

    private func backupURL(_ repo: SaveRepository) -> URL {
        repo.directory.appendingPathComponent("save.backup.json")
    }

    private let garbage = Data("{ this is not a save".utf8)

    @Test func writeThenLoadReturnsThePrimaryState() throws {
        let repo = try makeRepository()
        let state = sampleState(day: 15)
        try repo.write(SaveCodec.encode(state))
        #expect(repo.load(content: content) == .loaded(state, source: .primary))
    }

    @Test func missingFileLoadsFresh() throws {
        let repo = try makeRepository()
        #expect(repo.load(content: content) == .fresh)
    }

    @Test func secondWriteMovesTheFirstIntoTheBackup() throws {
        let repo = try makeRepository()
        let a = sampleState(day: 8)
        let b = sampleState(day: 22)
        try repo.write(SaveCodec.encode(a))
        try repo.write(SaveCodec.encode(b))
        #expect(try SaveCodec.decode(Data(contentsOf: primaryURL(repo)), content: content) == b)
        #expect(try SaveCodec.decode(Data(contentsOf: backupURL(repo)), content: content) == a)
    }

    @Test func firstWriteEverCreatesNoBackup() throws {
        let repo = try makeRepository()
        try repo.write(SaveCodec.encode(sampleState(day: 8)))
        #expect(FileManager.default.fileExists(atPath: primaryURL(repo).path))
        #expect(!FileManager.default.fileExists(atPath: backupURL(repo).path))
    }

    @Test func corruptPrimaryFallsBackToTheBackup() throws {
        let repo = try makeRepository()
        let a = sampleState(day: 8)
        try repo.write(SaveCodec.encode(a))
        try repo.write(SaveCodec.encode(sampleState(day: 22)))
        try garbage.write(to: primaryURL(repo))
        #expect(repo.load(content: content) == .loaded(a, source: .backup))
    }

    @Test func missingPrimaryWithBackupLoadsTheBackup() throws {
        let repo = try makeRepository()
        let a = sampleState(day: 8)
        try repo.write(SaveCodec.encode(a))
        try repo.write(SaveCodec.encode(sampleState(day: 22)))
        try FileManager.default.removeItem(at: primaryURL(repo))
        #expect(repo.load(content: content) == .loaded(a, source: .backup))
    }

    @Test func bothCorruptIsUnrecoverableAndLeavesBothFilesUntouched() throws {
        let repo = try makeRepository()
        let other = Data("also not a save".utf8)
        try garbage.write(to: primaryURL(repo))
        try other.write(to: backupURL(repo))
        #expect(repo.load(content: content) == .unrecoverable(primary: .unreadable, backup: .unreadable))
        #expect(try Data(contentsOf: primaryURL(repo)) == garbage)
        #expect(try Data(contentsOf: backupURL(repo)) == other)
    }

    @Test func newerSchemaIsReportedForThatFileAndNeverOverwrittenByLoad() throws {
        let repo = try makeRepository()
        let encoded = try SaveCodec.encode(sampleState(day: 8))
        let text = try #require(String(data: encoded, encoding: .utf8))
        #expect(text.contains("\"schemaVersion\":1"))
        let newer = Data(text.replacingOccurrences(of: "\"schemaVersion\":1", with: "\"schemaVersion\":2").utf8)
        try newer.write(to: primaryURL(repo))
        #expect(repo.load(content: content) == .unrecoverable(primary: .newerThanApp(2), backup: nil))
        #expect(try Data(contentsOf: primaryURL(repo)) == newer)
        #expect(!FileManager.default.fileExists(atPath: backupURL(repo).path))
    }

    @Test func removeAllSavesDeletesBothFiles() throws {
        let repo = try makeRepository()
        try repo.write(SaveCodec.encode(sampleState(day: 8)))
        try repo.write(SaveCodec.encode(sampleState(day: 22)))
        try repo.removeAllSaves()
        #expect(repo.load(content: content) == .fresh)
        #expect(!FileManager.default.fileExists(atPath: backupURL(repo).path))
    }

    @Test func preImportBackupIsWrittenAndRemovedWithTheOtherSaves() throws {
        let repo = try makeRepository()
        let a = sampleState(day: 8)
        try repo.writePreImportBackup(SaveCodec.encode(a))
        let preImport = repo.directory.appendingPathComponent("save.pre-import.json")
        #expect(try SaveCodec.decode(Data(contentsOf: preImport), content: content) == a)
        // A pre-import backup alone is never loaded as the live save.
        #expect(repo.load(content: content) == .fresh)
        try repo.removeAllSaves()
        #expect(!FileManager.default.fileExists(atPath: preImport.path))
    }

    @Test func aStructurallyValidButOutOfRangeSaveIsRejectedAsInvalid() throws {
        let repo = try makeRepository()
        let text = try #require(String(data: SaveCodec.encode(sampleState(day: 8)), encoding: .utf8))
        let hostile = Data(text.replacingOccurrences(of: "\"day\":8", with: "\"day\":0").utf8)
        try hostile.write(to: primaryURL(repo))
        #expect(repo.load(content: content) == .unrecoverable(primary: .invalid("day"), backup: nil))
    }
}
