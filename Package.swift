// swift-tools-version:5.9
// Unit tests for the app's pure logic (D-025): `swift test` from this folder.
// The sources in Shared/Core are also compiled into every target of AirBattery.xcodeproj.
import PackageDescription

let package = Package(
    name: "AirBatteryCore",
    platforms: [.macOS(.v12)],
    targets: [
        .target(name: "AirBatteryCore", path: "Shared/Core"),
        .testTarget(name: "AirBatteryCoreTests", dependencies: ["AirBatteryCore"], path: "Tests/AirBatteryCoreTests"),
    ]
)
