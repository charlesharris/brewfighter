import Foundation

// The frozen migration chain for saves.
//
// RULE: a schema change bumps `SaveCodec.currentSchemaVersion`, adds exactly ONE step to `steps`
// (keyed by the version it migrates FROM, producing the next version's bytes), and adds a new
// frozen `Tests/BrewCoreTests/Fixtures/save_vN.json` golden fixture while every older fixture
// keeps decoding. `GoldenSaveTests` is what turns a forgotten migration into a failing test.
//
// Version 1 is current, so the chain is empty and `migrate` is the identity for v1 saves.

package enum SaveMigrator {
    /// `steps[n]` upgrades version-n bytes to version n+1 bytes.
    private static let steps: [Int: @Sendable (Data) throws -> Data] = [:]

    /// Brings `data` (declared schema `version`) up to `SaveCodec.currentSchemaVersion`.
    /// Versions below 1 are invalid; versions above the current one belong to a newer app.
    package static func migrate(_ data: Data, from version: Int) throws -> Data {
        guard version >= 1 else { throw SaveError.invalid("schemaVersion") }
        guard version <= SaveCodec.currentSchemaVersion else { throw SaveError.newerThanApp(version) }

        var migrated = data
        for from in version..<SaveCodec.currentSchemaVersion {
            guard let step = steps[from] else { throw SaveError.invalid("schemaVersion") }
            migrated = try step(migrated)
        }
        return migrated
    }
}
