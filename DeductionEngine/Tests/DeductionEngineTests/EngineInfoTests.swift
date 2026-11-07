//
//  EngineInfoTests.swift
//  DeductionEngineTests
//

import Testing
@testable import DeductionEngine

// Swift Testing: plain functions marked @Test, with #expect instead of
// XCTAssert. No XCTestCase subclass needed.
struct EngineInfoTests {
    @Test func versionIsSet() {
        #expect(!EngineInfo.version.isEmpty)
    }
}
