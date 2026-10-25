//
//  BatteryParsing.swift
//  Shared by the app, the widget, the login helper and abt; tested with `swift test`.
//

import Foundation

enum BatteryParsing {
    /// Level and charging state from `ideviceinfo -q com.apple.mobile.battery` or `comptest`
    /// output ("BatteryCurrentCapacity: 85", "BatteryIsCharging: true"). Nil if either is
    /// missing or malformed: the tools' output must never crash the app.
    static func ideviceBattery(_ lines: [String]) -> (level: Int, charging: Bool)? {
        func value(_ key: String) -> String? {
            return lines.first(where: { $0.contains(key) })?
                .components(separatedBy: ": ").last?
                .trimmingCharacters(in: .whitespaces)
        }
        guard let levelText = value("BatteryCurrentCapacity"), let level = Int(levelText),
              let chargingText = value("BatteryIsCharging"), let charging = Bool(chargingText) else { return nil }
        return (min(100, max(0, level)), charging)
    }
}
