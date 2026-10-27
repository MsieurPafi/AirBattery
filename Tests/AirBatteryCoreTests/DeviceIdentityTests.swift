import XCTest
@testable import AirBatteryCore

final class DeviceIdentityTests: XCTestCase {
    func testCaseSuffixMatchesInEveryLanguage() {
        XCTAssertEqual(DeviceIdentity.canonicalName("AirPods Pro (boîtier)"), "AirPods Pro (Case)")
        XCTAssertEqual(DeviceIdentity.canonicalName("AirPods Pro (充电盒)"), "AirPods Pro (Case)")
        XCTAssertEqual(DeviceIdentity.canonicalName("AirPods Pro (充電盒)"), "AirPods Pro (Case)")
        XCTAssertEqual(DeviceIdentity.canonicalName("AirPods Pro (Case)"), "AirPods Pro (Case)")
        XCTAssertTrue(DeviceIdentity.sameName("AirPods Pro de Côme (Case)", "AirPods Pro de Côme (boîtier)"))
        XCTAssertFalse(DeviceIdentity.sameName("AirPods Pro (Case)", "AirPods Pro"))
        // A name merely containing the word is left alone
        XCTAssertEqual(DeviceIdentity.canonicalName("Case (boîtier) speaker"), "Case (boîtier) speaker")
    }

    func testListsMatchAcrossLanguages() {
        let pinned = ["AirPods Pro (Case)", "MX Anywhere 3"]
        XCTAssertTrue(pinned.containsDeviceName("AirPods Pro (boîtier)"))
        XCTAssertTrue(pinned.containsDeviceName("MX Anywhere 3"))
        XCTAssertFalse(pinned.containsDeviceName("MX Master 3"))
    }

    func testBluetoothAddressesAreNormalized() {
        XCTAssertEqual(DeviceIdentity.normalizedID("cb-ba-78-2d-7a-5d"), "CB:BA:78:2D:7A:5D")
        XCTAssertEqual(DeviceIdentity.normalizedID("CB:BA:78:2D:7A:5D"), "CB:BA:78:2D:7A:5D")
        XCTAssertEqual(DeviceIdentity.normalizedID("254BF778-E969-8280-12A7-A11CA9D11204"), "254BF778-E969-8280-12A7-A11CA9D11204")
        XCTAssertEqual(DeviceIdentity.normalizedID("@MacInternalBattery"), "@MacInternalBattery")
    }

    func testUDIDs() {
        XCTAssertTrue(DeviceIdentity.isUDID("00008160-0004683222A00036"))
        XCTAssertTrue(DeviceIdentity.isUDID(String(repeating: "a1", count: 20)))
        XCTAssertFalse(DeviceIdentity.isUDID("254BF778-E969-8280-12A7-A11CA9D11204"))
        XCTAssertFalse(DeviceIdentity.isUDID("CB:BA:78:2D:7A:5D"))
    }

    func testSameIDWinsEvenIfRenamed() {
        let records = [(id: "00008160-0004683222A00036", name: "iPhone")]
        XCTAssertEqual(DeviceIdentity.matchIndex(id: "00008160-0004683222A00036", name: "iPhone de Côme", in: records), 0)
    }

    func testAddressFormatsAreOneDevice() {
        let records = [(id: "cb-ba-78-2d-7a-5d", name: "MX Anywhere 3")]
        XCTAssertEqual(DeviceIdentity.matchIndex(id: "CB:BA:78:2D:7A:5D", name: "MX", in: records), 0)
    }

    func testOneDeviceSeenBySeveralSourcesStaysOneRecord() {
        // iPhone read over USB (UDID), then over Bluetooth (CoreBluetooth UUID)
        let records = [(id: "00008160-0004683222A00036", name: "iPhone")]
        XCTAssertEqual(DeviceIdentity.matchIndex(id: "C0FFEE00-0000-0000-0000-000000000001", name: "iPhone", in: records), 0)
        // AirPods case, whose suffix changed with the language
        let airPods = [(id: "9D7BF48C-5B6C-F788-4E71-D5A37654BDB4", name: "AirPods Pro (Case)")]
        XCTAssertEqual(DeviceIdentity.matchIndex(id: "OTHER", name: "AirPods Pro (boîtier)", in: airPods), 0)
    }

    func testTwoIPhonesWithTheSameNameStayTwoDevices() {
        let records = [(id: "00008160-0004683222A00036", name: "iPhone")]
        XCTAssertNil(DeviceIdentity.matchIndex(id: "00008150-000A1B2C3D4E5F60", name: "iPhone", in: records))
    }

    func testNewDevice() {
        let records = [(id: "@MacInternalBattery", name: "MacBook Pro")]
        XCTAssertNil(DeviceIdentity.matchIndex(id: "254BF778-E969-8280-12A7-A11CA9D11204", name: "MX Anywhere 3", in: records))
        XCTAssertNil(DeviceIdentity.matchIndex(id: "x", name: "y", in: []))
    }
}

final class BatteryParsingTests: XCTestCase {
    func testIdeviceinfoOutput() {
        let output = ["BatteryCurrentCapacity: 85", "BatteryIsCharging: true", "ExternalChargeCapable: true"]
        let result = BatteryParsing.ideviceBattery(output)
        XCTAssertEqual(result?.level, 85)
        XCTAssertEqual(result?.charging, true)
        XCTAssertEqual(result?.state, 1)
    }

    func testPluggedInBeforeCharging() {
        let pluggedIn = ["BatteryCurrentCapacity: 85", "BatteryIsCharging: false", "ExternalConnected: true"]
        XCTAssertEqual(BatteryParsing.ideviceBattery(pluggedIn)?.state, 5)
        let unplugged = ["BatteryCurrentCapacity: 85", "BatteryIsCharging: false", "ExternalConnected: false"]
        XCTAssertEqual(BatteryParsing.ideviceBattery(unplugged)?.state, 0)
        // comptest (Watch) may not report ExternalConnected
        XCTAssertEqual(BatteryParsing.ideviceBattery(["BatteryCurrentCapacity: 50", "BatteryIsCharging: false"])?.state, 0)
    }

    func testLevelIsClamped() {
        XCTAssertEqual(BatteryParsing.ideviceBattery(["BatteryCurrentCapacity: 125", "BatteryIsCharging: false"])?.level, 100)
        XCTAssertEqual(BatteryParsing.ideviceBattery(["BatteryCurrentCapacity: -3", "BatteryIsCharging: false"])?.level, 0)
    }

    func testMalformedOutputGivesNil() {
        XCTAssertNil(BatteryParsing.ideviceBattery([]))
        XCTAssertNil(BatteryParsing.ideviceBattery(["BatteryCurrentCapacity: 85"]))
        XCTAssertNil(BatteryParsing.ideviceBattery(["BatteryCurrentCapacity: lots", "BatteryIsCharging: true"]))
        XCTAssertNil(BatteryParsing.ideviceBattery(["ERROR: Could not connect to lockdownd, error code -17"]))
    }
}
