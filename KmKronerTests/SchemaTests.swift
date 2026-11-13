//
//  SchemaTests.swift
//  KmKronerTests
//

import Foundation
import SwiftData
import Testing
@testable import KmKroner

/// Tests for the versioned schema, the migration plan and the CloudKit rules.
@MainActor
struct SchemaTests {
    @Test func migrationPlanStartsAtVersionOne() {
        #expect(SchemaV1.versionIdentifier == Schema.Version(1, 0, 0))
        #expect(KmKronerMigrationPlan.schemas.map { $0.versionIdentifier } == [SchemaV1.versionIdentifier])
        #expect(KmKronerMigrationPlan.stages.isEmpty)
    }

    @Test func containerUsesCurrentSchema() throws {
        let container = try ModelSchema.inMemoryContainer()
        let entities = Set(container.schema.entities.map(\.name))
        #expect(entities == ["HomeAddress", "Workplace", "Trip"])
    }

    /// The CloudKit rules from SchemaV1, checked on every model so a future
    /// field that would break iCloud sync fails here first.
    @Test(arguments: SchemaV1.models.map { Schema.entityName(for: $0) })
    func followsCloudKitRules(_ entityName: String) throws {
        let entity = try #require(Schema(versionedSchema: SchemaV1.self).entitiesByName[entityName])
        for attribute in entity.attributes {
            #expect(attribute.isOptional || attribute.defaultValue != nil,
                    "\(entity.name).\(attribute.name) needs a default value or must be optional")
            #expect(!attribute.isUnique, "\(entity.name).\(attribute.name) can't be unique")
        }
        for relationship in entity.relationships {
            #expect(relationship.isOptional, "\(entity.name).\(relationship.name) must be optional")
        }
        #expect(entity.uniquenessConstraints.isEmpty, "\(entity.name) can't use #Unique")
    }

    /// The path every app update takes: data saved by one launch is still
    /// there when the next launch opens the store through the migration plan.
    @Test func reopeningStoreKeepsData() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appending(path: "KmKroner.store")

        // Keep each container in a variable: a ModelContext doesn't retain its
        // container, and using a context after its container is freed traps.
        do {
            let container = try ModelSchema.makeContainer(.file(url))
            let context = container.mainContext
            let esmark = Workplace(name: "Esmark", roundTripKm: 42.6, bridge: .storebaelt)
            context.insert(esmark)
            context.insert(Trip(day: .now, workplace: esmark))
            try context.save()
        }

        let reopened = try ModelSchema.makeContainer(.file(url))
        let trips = try reopened.mainContext.fetch(FetchDescriptor<Trip>())
        #expect(trips.count == 1)
        #expect(trips.first?.workplace?.name == "Esmark")
        #expect(trips.first?.bridge == .storebaelt)
    }
}
