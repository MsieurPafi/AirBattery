//
//  DeviceIdentity.swift
//  Shared by the app, the widget, the login helper and abt; tested with `swift test`.
//
//  How two device records are recognized as the same device (D-025).
//

import Foundation

enum DeviceIdentity {
    /// The AirPods case suffix in every language the app has had. Lists (alerts, pins, hidden
    /// and blocked devices) store names: a name saved in one language must still match after
    /// the app's language changes (" (Case)" became " (boîtier)" in French in 1.9.0).
    static let caseSuffixes = [" (Case)", " (boîtier)", " (充电盒)", " (充電盒)"]

    /// The name used to compare devices: the case suffix, in any language, becomes " (Case)".
    static func canonicalName(_ name: String) -> String {
        for suffix in caseSuffixes.dropFirst() where name.hasSuffix(suffix) {
            return String(name.dropLast(suffix.count)) + caseSuffixes[0]
        }
        return name
    }

    static func sameName(_ a: String, _ b: String) -> Bool {
        return a == b || canonicalName(a) == canonicalName(b)
    }

    /// Bluetooth addresses come as "aa-bb-cc-dd-ee-ff" from IOBluetooth and as
    /// "AA:BB:CC:DD:EE:FF" from system_profiler or the logs: one form for comparisons.
    static func normalizedID(_ id: String) -> String {
        if id.range(of: "^[0-9A-Fa-f]{2}([-:][0-9A-Fa-f]{2}){5}$", options: .regularExpression) != nil {
            return id.uppercased().replacingOccurrences(of: "-", with: ":")
        }
        return id
    }

    /// UDID of an iPhone, iPad or Apple Watch ("00008160-0004683222A00036", or 40 hex digits on
    /// older devices). A UDID never changes: two different UDIDs are two devices.
    static func isUDID(_ id: String) -> Bool {
        return id.range(of: "^([0-9A-Fa-f]{8}-[0-9A-Fa-f]{16}|[0-9A-Fa-f]{40})$", options: .regularExpression) != nil
    }

    /// Index of the record an update belongs to, or nil for a new device.
    /// The same ID always wins (a renamed device stays one record). Otherwise the same name, as
    /// before, so one device seen by several sources (Bluetooth and USB, with different IDs)
    /// stays one record; except two different UDIDs, which are two devices that share a name.
    static func matchIndex(id: String, name: String, in records: [(id: String, name: String)]) -> Int? {
        let key = normalizedID(id)
        if !key.isEmpty, let index = records.firstIndex(where: { normalizedID($0.id) == key }) {
            return index
        }
        return records.firstIndex { record in
            sameName(record.name, name) && !(isUDID(record.id) && isUDID(id))
        }
    }
}

extension Array where Element == String {
    /// Whether a list of device names (alerts, pins, hidden or blocked devices) holds this device.
    func containsDeviceName(_ name: String) -> Bool {
        return contains { DeviceIdentity.sameName($0, name) }
    }
}
