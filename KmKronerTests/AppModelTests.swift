//
//  AppModelTests.swift
//  KmKronerTests
//

import Testing
@testable import KmKroner

// AppModel is main-actor isolated (the app target's default isolation), but
// test targets don't inherit that default, so the suite opts in explicitly.
@MainActor
struct AppModelTests {
    @Test func startsOnTodayTab() {
        #expect(AppModel().selectedTab == .today)
    }
}
