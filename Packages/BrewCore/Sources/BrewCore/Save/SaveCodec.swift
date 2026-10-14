import Foundation

public enum SaveError: Error, Equatable, Sendable {
    case tooLarge
    case unreadable
    case newerThanApp(Int)
    case invalid(String)
}

/// On-disk shape of a save. `schemaVersion` describes this wrapper plus the payload layout.
struct SaveEnvelope: Codable, Equatable {
    var schemaVersion: Int
    var contentVersion: Int
    var payload: GameState

    enum CodingKeys: String, CodingKey {
        case schemaVersion, contentVersion, payload
    }
}

private struct SaveHeader: Decodable {
    var schemaVersion: Int
}

public enum SaveCodec {
    public static let currentSchemaVersion = 1
    public static let maxSaveBytes = 5_000_000

    /// Deterministic bytes: sorted keys, no pretty printing.
    public static func encode(_ state: GameState) throws -> Data {
        let envelope = SaveEnvelope(
            schemaVersion: currentSchemaVersion,
            contentVersion: state.beers.map(\.contentVersion).max() ?? 1,
            payload: state)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(envelope)
    }

    /// The only decode entry point. Order: size cap, header-only version gate, migrator chain,
    /// full envelope decode, then `SaveValidator` against the catalog (T-1-03, T-1-04, T-1-13).
    /// There is no decode path that skips validation.
    public static func decode(_ data: Data, content: ContentCatalog) throws -> GameState {
        // (a) size cap, before any parsing
        guard data.count <= maxSaveBytes else { throw SaveError.tooLarge }

        // (b) header only
        let header: SaveHeader
        do {
            header = try JSONDecoder().decode(SaveHeader.self, from: data)
        } catch {
            throw SaveError.unreadable
        }

        // (c) version gate, then bring older saves up to the current schema
        if header.schemaVersion > currentSchemaVersion { throw SaveError.newerThanApp(header.schemaVersion) }
        if header.schemaVersion < 1 { throw SaveError.invalid("schemaVersion") }
        let current = try migrateToCurrent(data, from: header.schemaVersion)

        // (d) full envelope
        let state: GameState
        do {
            state = try JSONDecoder().decode(SaveEnvelope.self, from: current).payload
        } catch {
            throw SaveError.unreadable
        }

        // (e) bounds and referential validation
        try SaveValidator.validate(state, content: content)
        return state
    }

    /// Temporary identity step: version 1 is current, so nothing to migrate yet.
    private static func migrateToCurrent(_ data: Data, from version: Int) throws -> Data {
        data
    }
}
