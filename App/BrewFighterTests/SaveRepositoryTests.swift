import BrewCore
import Foundation
import Testing

@testable import BrewFighter

struct SaveRepositoryTests {
    private func makeRepository() throws -> SaveRepository {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("SaveRepositoryTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return SaveRepository(directory: dir)
    }

    private func sampleState(day: Int) -> GameState {
        GameState(day: day, nextBatchNumber: 1, beers: [])
    }

    @Test func writeThenLoadReturnsThePrimaryState() throws {
        let repo = try makeRepository()
        let state = sampleState(day: 15)
        try repo.write(SaveCodec.encode(state))
        #expect(repo.load() == .loaded(state, source: .primary))
    }

    @Test func missingFileLoadsFresh() throws {
        let repo = try makeRepository()
        #expect(repo.load() == .fresh)
    }
}
