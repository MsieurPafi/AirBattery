//
//  Log.swift
//  Shared by the app, the widget, the login helper and abt.
//
//  Unified logging under the app's subsystem, one category per area.
//  Read it with:
//    /usr/bin/log stream --predicate 'subsystem == "io.github.msieurpafi.AirBattery"'
//    /usr/bin/log show --last 1h --predicate 'subsystem == "io.github.msieurpafi.AirBattery"'
//  Levels: notice for lifecycle events (kept on disk), error for failures,
//  debug for chatty messages (only visible while streaming with --debug).
//  Device names, addresses and paths stay private (redacted) unless marked public.
//

import os

enum Log {
    static let app = Logger(subsystem: AppIdentifiers.app, category: "app")
    static let data = Logger(subsystem: AppIdentifiers.app, category: "data")
    static let ble = Logger(subsystem: AppIdentifiers.app, category: "ble")
    static let bluetooth = Logger(subsystem: AppIdentifiers.app, category: "bluetooth")
    static let idevice = Logger(subsystem: AppIdentifiers.app, category: "idevice")
    static let magic = Logger(subsystem: AppIdentifiers.app, category: "magic")
    static let nearcast = Logger(subsystem: AppIdentifiers.app, category: "nearcast")
    static let process = Logger(subsystem: AppIdentifiers.app, category: "process")
}
