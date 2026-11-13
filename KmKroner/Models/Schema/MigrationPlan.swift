//
//  MigrationPlan.swift
//  KmKroner
//

import SwiftData

/// Every schema version in order, and how to move a store from one to the
/// next. SwiftData runs the stages it needs once, when the app opens a store
/// saved by an older version.
enum KmKronerMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]
    }

    /// Empty until SchemaV2: there's nothing to migrate from yet.
    static var stages: [MigrationStage] {
        []
    }
}
