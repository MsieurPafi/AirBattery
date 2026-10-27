//
//  BatteryParsing.swift
//  Shared by the app, the widget, the login helper and abt; tested with `swift test`.
//

import Foundation

enum BatteryParsing {
    /// Level and charging state from `ideviceinfo -q com.apple.mobile.battery` or `comptest`
    /// output ("BatteryCurrentCapacity: 85", "BatteryIsCharging: true"). Nil if either is
    /// missing or malformed: the tools' output must never crash the app.
    /// `state` is the app's isCharging value: 1 charging, 5 plugged in but not (yet) charging,
    /// 0 neither. An iPhone reports "ExternalConnected: true" as soon as it's plugged in, but
    /// "BatteryIsCharging" only 15 s to over a minute later (measured on an iPhone 17).
    static func ideviceBattery(_ lines: [String]) -> (level: Int, charging: Bool, state: Int)? {
        func value(_ key: String) -> String? {
            return lines.first(where: { $0.contains(key) })?
                .components(separatedBy: ": ").last?
                .trimmingCharacters(in: .whitespaces)
        }
        guard let levelText = value("BatteryCurrentCapacity"), let level = Int(levelText),
              let chargingText = value("BatteryIsCharging"), let charging = Bool(chargingText) else { return nil }
        let pluggedIn = value("ExternalConnected").flatMap { Bool($0) } ?? false
        return (min(100, max(0, level)), charging, charging ? 1 : (pluggedIn ? 5 : 0))
    }
}
