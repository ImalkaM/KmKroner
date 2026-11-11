//
//  ModelSchema.swift
//  KmKroner
//

import SwiftData

/// The SwiftData model types, listed once for the app, previews and tests.
enum ModelSchema {
    static let models: [any PersistentModel.Type] = [
        HomeAddress.self,
        Workplace.self,
        Trip.self,
    ]

    /// A throwaway in-memory store for previews and tests.
    static func inMemoryContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Schema(models),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }
}
