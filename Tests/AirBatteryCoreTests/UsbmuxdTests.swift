import XCTest
@testable import AirBatteryCore

final class UsbmuxdTests: XCTestCase {
    /// A message as usbmuxd sends it: header, then an XML plist.
    private func frame(_ message: [String: Any]) -> Data {
        let payload = try! PropertyListSerialization.data(fromPropertyList: message, format: .xml, options: 0)
        var data = Data()
        for value in [UInt32(16 + payload.count), 1, 8, 0] {
            withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
        }
        return data + payload
    }

    private let attachedOverWiFi: [String: Any] = [
        "MessageType": "Attached", "DeviceID": 1280,
        "Properties": ["ConnectionType": "Network", "DeviceID": 1280, "SerialNumber": "00008150-000A1B2C3D4E5F60"],
    ]

    func testListenRequestHeader() {
        let request = Usbmuxd.listenRequest(tag: 7)
        let header = [UInt8](request.prefix(16))
        XCTAssertEqual(Int(header[0]) | Int(header[1]) << 8, request.count)
        XCTAssertEqual(header[4], 1)  // version: plist
        XCTAssertEqual(header[8], 8)  // message type: plist
        XCTAssertEqual(header[12], 7) // tag
        let plist = try? PropertyListSerialization.propertyList(from: request.dropFirst(16), format: nil) as? [String: Any]
        XCTAssertEqual(plist?["MessageType"] as? String, "Listen")
    }

    func testEvents() {
        var buffer = frame(["MessageType": "Result", "Number": 0]) + frame(attachedOverWiFi) + frame(["MessageType": "Detached", "DeviceID": 1280])
        XCTAssertEqual(Usbmuxd.takeEvents(from: &buffer), [
            .result(0),
            .attached(deviceID: 1280, udid: "00008150-000A1B2C3D4E5F60", network: true),
            .detached(deviceID: 1280),
        ])
        XCTAssertTrue(buffer.isEmpty)
    }

    func testUSBAndUnknownMessages() {
        var buffer = frame(["MessageType": "Attached", "DeviceID": 3, "Properties": ["ConnectionType": "USB", "SerialNumber": "abc"]])
            + frame(["MessageType": "Paired", "DeviceID": 3])
        XCTAssertEqual(Usbmuxd.takeEvents(from: &buffer), [.attached(deviceID: 3, udid: "abc", network: false), .other("Paired")])
    }

    func testIncompleteMessageWaitsForTheRest() {
        let full = frame(attachedOverWiFi)
        var buffer = full.prefix(10)
        XCTAssertEqual(Usbmuxd.takeEvents(from: &buffer), [])
        XCTAssertEqual(buffer.count, 10)
        buffer.append(full.dropFirst(10).prefix(30))
        XCTAssertEqual(Usbmuxd.takeEvents(from: &buffer), [])
        buffer.append(full.dropFirst(40))
        XCTAssertEqual(Usbmuxd.takeEvents(from: &buffer), [.attached(deviceID: 1280, udid: "00008150-000A1B2C3D4E5F60", network: true)])
    }

    func testCorruptStream() {
        var tooShort = Data([4, 0, 0, 0] + [UInt8](repeating: 0, count: 12))
        XCTAssertNil(Usbmuxd.takeEvents(from: &tooShort))
        var notAPlist = Data([20, 0, 0, 0, 1, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4])
        XCTAssertNil(Usbmuxd.takeEvents(from: &notAPlist))
    }

    func testAttachedWithoutUDIDIsIgnored() {
        var buffer = frame(["MessageType": "Attached", "DeviceID": 9, "Properties": ["ConnectionType": "USB"]])
        XCTAssertEqual(Usbmuxd.takeEvents(from: &buffer), [.other("Attached")])
    }
}
