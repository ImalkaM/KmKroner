//
//  SchemaV1.swift
//  KmKroner
//

import SwiftData

/// The data layout shipped in version 1.0. Frozen once released: a change
/// to any model means a new `SchemaV2` plus a stage in `KmKronerMigrationPlan`.
///
/// CloudKit rules (iCloud sync, FR-26) every schema version must follow:
/// - every stored property is optional or has a default value
/// - every relationship is optional
/// - no `@Attribute(.unique)` or `#Unique`; the stores enforce uniqueness
/// `SchemaTests` checks these, so breaking one fails the tests.
enum SchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [HomeAddress.self, Workplace.self, Trip.self]
    }
}

// The rest of the app uses the current version's models by these names.
// A new schema version only has to repoint them.
typealias HomeAddress = SchemaV1.HomeAddress
typealias Workplace = SchemaV1.Workplace
typealias Trip = SchemaV1.Trip
