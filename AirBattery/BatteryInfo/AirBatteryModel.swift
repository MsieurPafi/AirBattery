//
//  AirBatteryModel.swift
//  AirBattery
//
//  Created by apple on 2024/2/9.
//

import Foundation

struct btdDevice: Codable, Equatable {
    let time: Date
    let vid: String
    let pid: String
    let type: String
    let mac: String
    let name: String
    let level: Int
}

struct Device: Hashable, Codable {
    var hasBattery: Bool = true
    var deviceID: String
    var deviceType: String
    var deviceName: String
    var deviceModel: String?
    var batteryLevel: Int
    var isCharging: Int
    var isCharged: Bool = false
    var isPaused: Bool = false
    var acPowered: Bool = false
    var isHidden: Bool = false
    var lowPower: Bool = false
    var parentName: String = ""
    var lastUpdate: Double
    var realUpdate: Double = 0.0
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(hasBattery)
        hasher.combine(deviceID)
        hasher.combine(deviceType)
        hasher.combine(deviceName)
        hasher.combine(deviceModel)
        hasher.combine(batteryLevel)
        hasher.combine(isCharging)
        hasher.combine(isCharged)
        hasher.combine(isPaused)
        hasher.combine(acPowered)
        hasher.combine(isHidden)
        hasher.combine(lowPower)
        hasher.combine(lastUpdate)
        hasher.combine(realUpdate)
        hasher.combine(parentName)
    }
}

class AirBatteryModel {
    // Devices is updated from several threads (Bluetooth callbacks, background scans),
    // so every access goes through a real lock. Unsynchronized access corrupted memory.
    private static let devicesLock = NSLock()
    private static var _devices: [Device] = []
    static var Devices: [Device] {
        get { devicesLock.lock(); defer { devicesLock.unlock() }; return _devices }
        set { devicesLock.lock(); defer { devicesLock.unlock() }; _devices = newValue }
    }
    static let machineType = ud.string(forKey: "machineType") ?? "Mac"
    static let key = AppIdentifiers.widget

    static func updateDevice(_ device: Device) {
        //let blockedItems = (ud.object(forKey: "blockedDevices") as? [String]) ?? [String]()
        //if blockedItems.contains(device.deviceName) { return }
        devicesLock.lock(); defer { devicesLock.unlock() }
        //self.Devices.removeAll(where: {blockedItems.contains($0.deviceName)})
        // Same ID first, then same name (DeviceIdentity, D-025)
        if let index = DeviceIdentity.matchIndex(id: device.deviceID, name: device.deviceName, in: _devices.map { ($0.deviceID, $0.deviceName) }) {
            _devices[index] = device
        } else {
            _devices.append(device)
        }
    }

    static func hideDevice(_ name: String) {
        devicesLock.lock(); defer { devicesLock.unlock() }
        for index in _devices.indices {
            if DeviceIdentity.sameName(_devices[index].deviceName, name) {
                _devices[index].isHidden = true
            }
        }
    }

    static func unhideDevice(_ name: String) {
        devicesLock.lock(); defer { devicesLock.unlock() }
        for index in _devices.indices {
            if DeviceIdentity.sameName(_devices[index].deviceName, name) {
                _devices[index].isHidden = false
            }
        }
    }
    
    static func getBlackList() -> [Device] {
        let blackList = (ud.stringArray(forKey: "blackList") ?? [])
        let devices = getAll(noFilter: true)
        return devices.filter({ blackList.containsDeviceName($0.deviceName) })
    }
    
    static func getAll(reverse: Bool = false, noFilter: Bool = false) -> [Device] {
        let thisMac = ud.string(forKey: "deviceName")
        let disappearTime = (ud.object(forKey: "disappearTime") as? Int ?? 20)
        let blackList = (ud.stringArray(forKey: "blackList") ?? [])
        let now = Double(Date().timeIntervalSince1970)
        var list = (reverse ? Array(Devices.reversed()) : Devices).filter { (now - $0.lastUpdate < Double(disappearTime * 60)) }
        if !noFilter { list = list.filter { !blackList.containsDeviceName($0.deviceName) && !$0.isHidden } }
        var newList: [Device] = list.filter({ $0.parentName == thisMac })
        for d in list {
            if d.parentName == "" && d.parentName != thisMac {
                newList.append(d)
                for sd in list.filter({ $0.parentName == d.deviceName }) {
                    newList.append(sd)
                }
            }
        }
        for dd in list.filter({ !newList.contains($0) }) { newList.append(dd) }
        return newList.filter({ !checkIfBlocked(name: $0.deviceName) })
    }
    
    /// Order of the device list in the menu, the Dock and the widget (setting "sortDevices").
    /// "default" keeps the discovery order. "name", "levelAsc" and "levelDesc" sort groups as a
    /// whole: an AirPods case with its earbuds, an iPhone with its Watch, an iPad with its
    /// Pencil. A group's level is its lowest one; devices without a battery go last.
    /// The Mac's own battery is sorted like any other device.
    static func sortForDisplay(_ list: [Device], reversed: Bool = false) -> [Device] {
        let order = ud.string(forKey: "sortDevices") ?? "default"
        if order == "default" { return list }
        let thisMac = ud.string(forKey: "deviceName")
        let names = Set(list.map { $0.deviceName })
        // Peripherals reported by this Mac carry its name as parent: sort them on their own.
        func isChild(_ d: Device) -> Bool {
            return d.parentName != "" && d.parentName != thisMac && names.contains(d.parentName)
        }
        var groups: [[Device]] = []
        for d in list where !isChild(d) {
            groups.append([d] + list.filter { isChild($0) && $0.parentName == d.deviceName })
        }
        func lowestLevel(_ group: [Device]) -> Int? {
            return group.filter { $0.hasBattery }.map { $0.batteryLevel }.min()
        }
        func byName(_ a: [Device], _ b: [Device]) -> Bool {
            return a[0].deviceName.localizedStandardCompare(b[0].deviceName) == .orderedAscending
        }
        groups.sort { a, b in
            if order == "name" { return byName(a, b) }
            guard let levelA = lowestLevel(a) else { return false }
            guard let levelB = lowestLevel(b) else { return true }
            if levelA != levelB { return order == "levelAsc" ? levelA < levelB : levelA > levelB }
            return byName(a, b)
        }
        if reversed { groups.reverse() }
        return groups.flatMap { $0 }
    }

    static func getByName(_ name: String) -> Device? {
        for d in getAll(noFilter: true) { if DeviceIdentity.sameName(d.deviceName, name) { return d } }
        return nil
    }
    
    static func getByID(_ id: String) -> Device? {
        for d in getAll(noFilter: true) { if d.deviceID == id { return d } }
        return nil
    }
    
    static func singleDeviceName() -> String {
        var url: URL
        let bundleIdentifier = Bundle.main.bundleIdentifier
        if bundleIdentifier == key {
            url = fd.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("singleDeviceName")
            let devicename = try? String(contentsOf: url, encoding: .utf8)
            return devicename ?? ""
        } else {
            url = fd.urls(for: .libraryDirectory, in: .userDomainMask).first!.appendingPathComponent("Containers/\(key)/Data/Documents/singleDeviceName")
            try? ud.string(forKey: "deviceOnWidget")?.write(to: url, atomically: true, encoding: .utf8)
        }
        return ""
    }
    
    static func getJsonURL() -> URL {
        var url: URL
        let bundleIdentifier = Bundle.main.bundleIdentifier
        if bundleIdentifier == key {
            url = fd.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("data.json")
        } else {
            url = fd.urls(for: .libraryDirectory, in: .userDomainMask).first!.appendingPathComponent("Containers/\(key)/Data/Documents/data.json")
        }
        return url
    }
    
    private static let writeLock = NSLock()
    private static var lastSignature = ""
    private static var lastWrite = 0.0
    private static var widgetReloadNeeded = true

    /// Writes the widgets' data. Periodic calls only write when something the widgets show has
    /// changed, or every 5 minutes so the "⚠︎" offline marker stays right: the file was
    /// replaced every 24 s and the widgets reloaded every minute even when nothing changed.
    /// `force` (user action, `abtp`, AppleScript, launch) always writes, and exports for `abtp`.
    static func writeData(force: Bool = false) {
        //let showMac = ud.object(forKey: "showMacOnWidget") as? Bool ?? true
        let revList = ud.object(forKey: "revListOnWidget") as? Bool ?? false
        
        let sorted = (ud.string(forKey: "sortDevices") ?? "default") != "default"
        var devices = getAll(reverse: revList && !sorted)
        let ibStatus = InternalBattery.status
        if ibStatus.hasBattery { devices.insert(ib2ab(ibStatus), at: 0) }
        devices = sortForDisplay(devices, reversed: revList)

        let signature = devices.map { "\($0.deviceID)|\($0.deviceName)|\($0.deviceType)|\($0.deviceModel ?? "")|\($0.batteryLevel)|\($0.isCharging)|\($0.isCharged)|\($0.isPaused)|\($0.acPowered)|\($0.lowPower)|\($0.parentName)" }.joined(separator: "\n")
        let now = Date().timeIntervalSince1970
        writeLock.lock()
        let due = force || signature != lastSignature || now - lastWrite >= 300
        if due {
            lastSignature = signature
            lastWrite = now
            widgetReloadNeeded = true
        }
        writeLock.unlock()
        guard due else { return }

        do {
            let jsonData = try JSONEncoder().encode(devices)
            try jsonData.write(to: getJsonURL(), options: .atomic)
        } catch {
            Log.data.error("Write JSON error: \(String(describing: error), privacy: .public)")
        }
        if force && Bundle.main.bundleIdentifier == AppIdentifiers.app { exportForTools(devices) }
    }

    /// Whether the widgets' data changed since the last call (then they need a reload).
    static func takeWidgetReloadNeeded() -> Bool {
        writeLock.lock(); defer { writeLock.unlock() }
        let needed = widgetReloadNeeded
        widgetReloadNeeded = false
        return needed
    }

    /// Folder read by abt and other local tools. Since macOS 14, a process launched
    /// from a terminal may not read another app's sandbox container, so the widget's
    /// Documents folder is off limits for abt. Application Support is not protected.
    static func exportFolder() -> URL {
        return fd.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent(AppIdentifiers.app)
    }

    /// Writes data.json (local devices) and nearcast.json (Nearcast devices, already
    /// filtered like in the app) to `exportFolder()`.
    static func exportForTools(_ devices: [Device]) {
        let folder = exportFolder()
        do {
            try fd.createDirectory(at: folder, withIntermediateDirectories: true)
            try JSONEncoder().encode(devices).write(to: folder.appendingPathComponent("data.json"), options: .atomic)
            var nearcastDevices: [Device] = []
            for url in getFiles(withExtension: "json", in: ncFolder) { nearcastDevices += ncGetAll(url: url) }
            try JSONEncoder().encode(nearcastDevices).write(to: folder.appendingPathComponent("nearcast.json"), options: .atomic)
        } catch {
            Log.data.error("Export JSON error: \(String(describing: error), privacy: .public)")
        }
    }
    
    static func readData(url: URL = getJsonURL()) -> [Device]{
        do {
            let jsonData = try Data(contentsOf: url)
            let list = try JSONDecoder().decode([Device].self, from: jsonData)
            return list
        } catch {
            Log.data.error("Read JSON error: \(String(describing: error), privacy: .public)")
        }
        return []
    }
    
    static func ncGetAll(url: URL, fromWidget: Bool = false) -> [Device] {
        let disappearTime = (ud.object(forKey: "disappearTime") as? Int ?? 20)
        let devices = readData(url: url)
        let now = Double(Date().timeIntervalSince1970)
        var localDevices = getAll().map({ $0.deviceName })
        if fromWidget { localDevices = readData().map({ $0.deviceName }) }
        var list = devices.filter{(now - $0.lastUpdate < Double(disappearTime * 60))}.filter({!localDevices.contains($0.deviceName)})
        if let first = devices.first { if !list.contains(first) && list.count != 0 { list.insert(first, at: 0) }}
        if let first = list.first { if list.count == 1 && !first.hasBattery { return [] }}
        return list
    }
    
    static func checkIfBlocked(name: String) -> Bool {
        #if DEBUG
        if DemoDevices.enabled { return !DemoDevices.names.contains(name) }
        #endif
        let whitelistMode = ud.bool(forKey: "whitelistMode")
        let blockedItems = (ud.object(forKey: "blockedDevices") as? [String]) ?? [String]()
        if (blockedItems.containsDeviceName(name) && !whitelistMode) || (!blockedItems.containsDeviceName(name) && whitelistMode) {
            return true
        }
        return false
    }
}

#if DEBUG
/// Neutral devices for documentation screenshots, in Debug builds only (D-023).
/// Launch with `-demoDevices YES`: real devices are hidden, the Mac shows as "MacBook Pro",
/// and these devices are refreshed every minute so they never look offline. Their names must
/// differ from the real devices': the app indexes devices by name, so a real "iPhone" would
/// overwrite a demo "iPhone".
enum DemoDevices {
    static var enabled: Bool { UserDefaults.standard.bool(forKey: "demoDevices") }
    static let macName = "MacBook Pro"

    private static func devices() -> [Device] {
        let now = Date().timeIntervalSince1970
        let airPods = "AirPods Pro"
        return [
            Device(deviceID: "demo-iphone", deviceType: "iPhone", deviceName: "iPhone 16 Pro", deviceModel: "iPhone17,1", batteryLevel: 82, isCharging: 0, lastUpdate: now),
            Device(deviceID: "demo-watch", deviceType: "Watch", deviceName: "Apple Watch", deviceModel: "Watch7,1", batteryLevel: 64, isCharging: 0, parentName: "iPhone 16 Pro", lastUpdate: now),
            Device(deviceID: "demo-ipad", deviceType: "iPad", deviceName: "iPad Pro", deviceModel: "iPad16,3", batteryLevel: 57, isCharging: 1, lastUpdate: now),
            Device(deviceID: "demo-pencil", deviceType: "ApplePencil", deviceName: "Apple Pencil", deviceModel: "333", batteryLevel: 91, isCharging: 0, parentName: "iPad Pro", lastUpdate: now),
            Device(deviceID: "demo-airpods", deviceType: "ap_case", deviceName: airPods + " (Case)".local, deviceModel: "Airpods Pro 2", batteryLevel: 73, isCharging: 0, lastUpdate: now),
            Device(deviceID: "demo-airpods_All", deviceType: "ap_pod_all", deviceName: airPods + " 🄻🅁", deviceModel: "Airpods Pro 2", batteryLevel: 48, isCharging: 0, parentName: airPods + " (Case)".local, lastUpdate: now),
            Device(deviceID: "demo-keyboard", deviceType: "Keyboard", deviceName: "Magic Keyboard", batteryLevel: 36, isCharging: 0, lastUpdate: now),
            Device(deviceID: "demo-mouse", deviceType: "MMouse", deviceName: "Magic Mouse", batteryLevel: 18, isCharging: 0, lastUpdate: now),
        ]
    }

    static var names: [String] { devices().map { $0.deviceName } + [macName] }

    private static var timer: Timer?

    static func start() {
        guard enabled else { return }
        let refresh = { devices().forEach { AirBatteryModel.updateDevice($0) } }
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in refresh() }
        Log.app.notice("Demo devices enabled")
    }
}
#endif

