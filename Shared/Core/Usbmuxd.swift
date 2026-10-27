//
//  Usbmuxd.swift
//  AirBattery
//
//  usbmuxd's plist protocol, as libusbmuxd speaks it on /var/run/usbmuxd: a 16-byte
//  little-endian header (total length, version 1, message type 8 = plist, tag), then an
//  XML or binary plist. Pure functions, so the framing can be tested without a socket.
//

import Foundation

public enum Usbmuxd {
    public static let socketPath = "/var/run/usbmuxd"

    public enum Event: Equatable {
        /// Answer to a request: 0 is success.
        case result(Int)
        /// A device appeared, over USB or over the network (Wi-Fi).
        case attached(deviceID: Int, udid: String, network: Bool)
        case detached(deviceID: Int)
        /// Any other message (for example "Paired"), by its type.
        case other(String)
    }

    private static let headerSize = 16
    /// Real messages are a few hundred bytes: anything bigger means the stream is out of sync.
    private static let maxMessageSize = 1 << 20

    /// The "Listen" request: usbmuxd then reports every attached device, and each change.
    public static func listenRequest(tag: UInt32 = 1) -> Data {
        let request: [String: Any] = [
            "MessageType": "Listen",
            "ClientVersionString": "AirBattery Plus",
            "ProgName": "AirBattery Plus",
            "kLibUSBMuxVersion": 3,
        ]
        let payload = (try? PropertyListSerialization.data(fromPropertyList: request, format: .xml, options: 0)) ?? Data()
        var message = Data()
        for value in [UInt32(headerSize + payload.count), 1, 8, tag] {
            withUnsafeBytes(of: value.littleEndian) { message.append(contentsOf: $0) }
        }
        message.append(payload)
        return message
    }

    /// Removes the complete messages at the start of `buffer` and returns their events.
    /// An incomplete message stays in the buffer until the rest arrives. Returns nil when the
    /// stream can't be parsed any more (the connection should then be closed).
    public static func takeEvents(from buffer: inout Data) -> [Event]? {
        var events: [Event] = []
        while buffer.count >= headerSize {
            let bytes = [UInt8](buffer.prefix(4))
            let length = Int(bytes[0]) | Int(bytes[1]) << 8 | Int(bytes[2]) << 16 | Int(bytes[3]) << 24
            guard length >= headerSize, length <= maxMessageSize else { return nil }
            guard buffer.count >= length else { break }
            let payload = buffer.subdata(in: buffer.startIndex + headerSize ..< buffer.startIndex + length)
            buffer.removeSubrange(buffer.startIndex ..< buffer.startIndex + length)
            guard let message = (try? PropertyListSerialization.propertyList(from: payload, format: nil)) as? [String: Any] else { return nil }
            events.append(event(from: message))
        }
        return events
    }

    static func event(from message: [String: Any]) -> Event {
        let type = message["MessageType"] as? String ?? ""
        switch type {
        case "Result":
            return .result(message["Number"] as? Int ?? -1)
        case "Attached":
            let properties = message["Properties"] as? [String: Any] ?? [:]
            guard let deviceID = message["DeviceID"] as? Int ?? properties["DeviceID"] as? Int,
                  let udid = properties["SerialNumber"] as? String, !udid.isEmpty else { return .other(type) }
            return .attached(deviceID: deviceID, udid: udid, network: (properties["ConnectionType"] as? String) == "Network")
        case "Detached":
            guard let deviceID = message["DeviceID"] as? Int else { return .other(type) }
            return .detached(deviceID: deviceID)
        default:
            return .other(type)
        }
    }
}
