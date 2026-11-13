//
//  ModelSchema.swift
//  KmKroner
//

import Foundation
import SwiftData

/// Builds the SwiftData container from the current schema and migration plan,
/// for the app, previews and tests.
enum ModelSchema {
    /// Where a container keeps its data.
    enum Storage {
        /// The app's default store on the device.
        case onDisk
        /// A throwaway store for previews and tests.
        case inMemory
        /// A store at a specific file, for tests that reopen it.
        case file(URL)
    }

    static var models: [any PersistentModel.Type] { SchemaV1.models }

    /// Opens (or creates) a store, migrating it to the current schema if an
    /// older app version saved it.
    static func makeContainer(_ storage: Storage = .onDisk) throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV1.self)
        // iCloud stays off until sync is built (FR-26), even if the app gains
        // an iCloud capability; SwiftData would otherwise turn it on by itself.
        let configuration = switch storage {
        case .onDisk:
            ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        case .inMemory:
            ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        case .file(let url):
            ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        }
        return try ModelContainer(
            for: schema,
            migrationPlan: KmKronerMigrationPlan.self,
            configurations: configuration
        )
    }

    /// A throwaway in-memory store for previews and tests.
    static func inMemoryContainer() throws -> ModelContainer {
        try makeContainer(.inMemory)
    }
}
