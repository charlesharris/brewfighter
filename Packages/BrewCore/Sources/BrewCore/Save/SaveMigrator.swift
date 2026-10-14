import Foundation

// RED stub: replaced by the real migration chain in the GREEN step.
package enum SaveMigrator {
    package static func migrate(_ data: Data, from version: Int) throws -> Data {
        throw SaveError.unreadable
    }
}
