// swift-tools-version: 6.0
//
// DeductionEngine: pure Swift kørselsfradrag (commute deduction) maths.
// Deliberately has no SwiftUI/SwiftData/UIKit imports, so it builds and its
// tests run on the Mac with `swift test` in seconds, with no simulator.

import PackageDescription

let package = Package(
    name: "DeductionEngine",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(name: "DeductionEngine", targets: ["DeductionEngine"]),
    ],
    targets: [
        .target(name: "DeductionEngine"),
    ],
    // Match the app: Swift 5 language mode.
    swiftLanguageModes: [.v5]
)
