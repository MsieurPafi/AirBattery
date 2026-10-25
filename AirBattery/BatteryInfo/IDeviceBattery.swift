//
//  AirBatteryModel.swift
//  AirBattery
//
//  Created by apple on 2024/2/6.
//
import SwiftUI
import Foundation

class IDeviceBattery {
    static var shared: IDeviceBattery = IDeviceBattery()
    
    var scanTimer: Timer?
    @AppStorage("readPencil") var readPencil = false
    @AppStorage("readIDevice") var readIDevice = true
    @AppStorage("updateInterval") var updateInterval = 1
    /// One scan at a time: a slow tool (iPhone leaving Wi-Fi range) used to let a new scan
    /// thread start every 15 s on top of the previous ones.
    private let stateLock = NSLock()
    private var scanning = false
    /// Last read attempt by device ID, for devices that are not (or no longer) in the list:
    /// blocked ones, or ones whose read fails, were retried every 15 s.
    private var lastAttempt: [String: Double] = [:]
    private var pencilReads: Set<String> = []

    func startScan() {
        // Own timer, independent of any view. The scan used to be driven by a SwiftUI view's
        // 5 s dockTimer: two idevice_id launches every 5 s, and only while that view was
        // alive (upstream #91). Battery reads stay throttled to the refresh interval in
        // getIDeviceBattery(); 15 s is how long a newly plugged device can take to appear.
        scanTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            self?.scanDevices()
        }
        Log.idevice.notice("Start scanning iPhone, iPad and Watch")
        scanDevices()
    }
    
    @objc func scanDevices() {
        stateLock.lock()
        if scanning || !readIDevice { stateLock.unlock(); return }
        scanning = true
        stateLock.unlock()
        Thread.detachNewThread {
            self.getIDeviceBattery()
            self.stateLock.lock()
            self.scanning = false
            self.stateLock.unlock()
        }
    }

    /// Whether an unknown device may be read again (at most once per refresh interval).
    private func mayRetry(_ id: String) -> Bool {
        let now = Date().timeIntervalSince1970
        stateLock.lock(); defer { stateLock.unlock() }
        if let last = lastAttempt[id], now - last < Double(60 * updateInterval) { return false }
        lastAttempt[id] = now
        return true
    }
    
    func getPencil(d: Device, type: String = "") {
        if d.deviceType == "iPad" && readPencil {
            // Same refresh interval as the other devices, and one read per iPad at a time:
            // it ran at every 15 s scan, with an idevicesyslog lasting up to 11 × interval s.
            let pencilID = "Pencil_" + d.deviceID
            if let pencil = AirBatteryModel.getByID(pencilID), Date().timeIntervalSince1970 - pencil.lastUpdate < Double(60 * updateInterval) { return }
            stateLock.lock()
            if pencilReads.contains(d.deviceID) { stateLock.unlock(); return }
            pencilReads.insert(d.deviceID)
            stateLock.unlock()
            Thread.detachNewThread {
                defer { self.stateLock.lock(); self.pencilReads.remove(d.deviceID); self.stateLock.unlock() }
                if let result = process(path: "/bin/bash", arguments: ["\(Bundle.main.resourcePath!)/logReader.sh", "\(Bundle.main.resourcePath!)/libimobiledevice/bin/idevicesyslog", type, d.deviceID], timeout: 11 * self.updateInterval) {
                    if let json = try? JSONSerialization.jsonObject(with: Data(result.utf8), options: []) as? [String: Any] {
                        if let level = json["level"] as? Int, let model = json["model"] as? String, let vendor = json["vendor"] as? String {
                            let status = (json["status"] as? Int) ?? 0
                            Log.idevice.debug("Pencil of \(d.deviceName): \(result)")
                            AirBatteryModel.updateDevice(Device(deviceID: "Pencil_"+d.deviceID, deviceType: vendor == "Apple" ? "ApplePencil" : "Pencil", deviceName: vendor == "Apple" ? "Apple Pencil" : "Pencil", deviceModel: model, batteryLevel: level, isCharging: status, parentName: d.deviceName, lastUpdate: Date().timeIntervalSince1970))
                        }
                    }
                }
            }
        }
    }
    
    func getIDeviceBattery() {
        if let result = process(path: "\(Bundle.main.resourcePath!)/libimobiledevice/bin/idevice_id", arguments: ["-n"]) {
            for id in result.components(separatedBy: .newlines) {
                if let d = AirBatteryModel.getByID(id) {
                    if (Double(Date().timeIntervalSince1970) - d.lastUpdate) > Double(60 * updateInterval) { writeBatteryInfo(id, "-n") }
                    getPencil(d: d, type: "-n")
                } else if mayRetry(id + " network") {
                    writeBatteryInfo(id, "-n")
                }
            }
        }
        if let result = process(path: "\(Bundle.main.resourcePath!)/libimobiledevice/bin/idevice_id", arguments: ["-l"]) {
            for id in result.components(separatedBy: .newlines) {
                if let d = AirBatteryModel.getByID(id) {
                    if (Double(Date().timeIntervalSince1970) - d.lastUpdate) > Double(60 * updateInterval) { writeBatteryInfo(id, "") }
                    getPencil(d: d)
                } else if mayRetry(id + " usb") {
                    writeBatteryInfo(id, "")
                }
            }
        }
    }
    
    /// Reads "BatteryCurrentCapacity" and "BatteryIsCharging" from ideviceinfo or comptest
    /// output. Returns nil instead of crashing when a field is missing or malformed: these
    /// lines come from external tools whose format may change.
    static func parseBattery(_ lines: [String]) -> (level: Int, charging: Bool)? {
        return BatteryParsing.ideviceBattery(lines)
    }

    func writeBatteryInfo(_ id: String, _ connectType: String) {
        //print("ℹ️ Getting Battery Info for \(id)")
        let lastUpdate = Date().timeIntervalSince1970
        if connectType == "" { _ = process(path: "\(Bundle.main.resourcePath!)/libimobiledevice/bin/wificonnection", arguments: ["-u", id, "true"]) }
        if let deviceInfo = process(path: "\(Bundle.main.resourcePath!)/libimobiledevice/bin/ideviceinfo", arguments: [connectType, "-u", id]){
            let i = deviceInfo.components(separatedBy: .newlines)
            if let deviceName = i.filter({ $0.contains("DeviceName") }).first?.components(separatedBy: ": ").last,
               let model = i.filter({ $0.contains("ProductType") }).first?.components(separatedBy: ": ").last,
               let type = i.filter({ $0.contains("DeviceClass") }).first?.components(separatedBy: ": ").last {
                if let batteryInfo = process(path: "\(Bundle.main.resourcePath!)/libimobiledevice/bin/ideviceinfo", arguments: [connectType, "-u", id, "-q", "com.apple.mobile.battery"]) {
                    if let battery = IDeviceBattery.parseBattery(batteryInfo.components(separatedBy: .newlines)) {
                        AirBatteryModel.updateDevice(Device(deviceID: id, deviceType: type, deviceName: deviceName, deviceModel: model, batteryLevel: battery.level, isCharging: battery.charging ? 1 : 0, lastUpdate: lastUpdate))
                        // comptest occasionally hangs or crashes (upstream #198): don't let it
                        // block this background thread forever.
                        if let watchInfo = process(path: "\(Bundle.main.resourcePath!)/libimobiledevice/bin/comptest", arguments: [id], timeout: 15) {
                            let w = watchInfo.components(separatedBy: .newlines)
                            if let watchID = w.filter({ $0.contains("Checking watch") }).first?.components(separatedBy: " ").last,
                               let watchName = w.filter({ $0.contains("DeviceName") }).first?.components(separatedBy: ": ").last,
                               let watchModel = w.filter({ $0.contains("ProductType") }).first?.components(separatedBy: ": ").last,
                               let watchBattery = IDeviceBattery.parseBattery(w) {
                                AirBatteryModel.updateDevice(Device(deviceID: watchID, deviceType: "Watch", deviceName: watchName, deviceModel: watchModel, batteryLevel: watchBattery.level, isCharging: watchBattery.charging ? 1 : 0, parentName: deviceName, lastUpdate: lastUpdate))
                            } else {
                                Log.idevice.error("Could not parse Watch battery info for \(deviceName)")
                            }
                        }
                    } else {
                        Log.idevice.error("Could not parse battery info for \(deviceName)")
                    }
                }
            }
        }
    }
}
