//
//  AppIdentifiers.swift
//  Shared by the app, the widget, the login helper and abt.
//
//  Single source of truth for the fork's identifiers in Swift code.
//  The bundle IDs themselves come from the APP_ID_PREFIX build setting
//  (project level, AirBattery.xcodeproj): keep `prefix` below in sync with it.
//  The app checks this at launch in Debug builds.
//

import Foundation

enum AppIdentifiers {
    static let prefix = "io.github.msieurpafi"

    static let app = "\(prefix).AirBattery"
    static let widget = "\(prefix).AirBattery.widget"
    static let helper = "\(prefix).AirBatteryHelper"

    // Also declared in AirBattery/Info.plist (CFBundleURLSchemes).
    static let urlScheme = "airbattery-plus"

    static func url(_ host: String) -> URL? {
        URL(string: "\(urlScheme)://\(host)")
    }
}
