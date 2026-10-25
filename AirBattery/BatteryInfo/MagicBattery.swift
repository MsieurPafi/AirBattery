//
//  MagicBattery.swift
//  AirBattery
//
//  Created by apple on 2024/2/9.
//
import SwiftUI
import Foundation
import IOBluetooth

class SPBluetoothDataModel {
    static var shared: SPBluetoothDataModel = SPBluetoothDataModel()
    // Written from several background threads at once (e.g. many Bluetooth devices
    // reconnecting after wake). Unsynchronized writes caused
    // "pointer being freed was not allocated" crashes.
    private let lock = NSLock()
    private var _data: String = "{}"
    var data: String {
        get { lock.lock(); defer { lock.unlock() }; return _data }
        set { lock.lock(); defer { lock.unlock() }; _data = newValue }
    }

    /// Connected devices in the last report, as (name, properties). The report was parsed the
    /// same way in several places.
    var connectedDevices: [(name: String, info: [String: Any])] {
        guard let json = try? JSONSerialization.jsonObject(with: Data(data.utf8)) as? [String: Any],
              let report = (json["SPBluetoothDataType"] as? [Any])?.first as? [String: Any],
              let connected = report["device_connected"] as? [Any] else { return [] }
        return connected.compactMap { entry in
            guard let device = entry as? [String: Any], let name = device.keys.first,
                  let info = device[name] as? [String: Any] else { return nil }
            return (name, info)
        }
    }

    func refreshData(completion: (String) -> Void, error: (() -> Void)? = nil) {
        if let result = process(path: "/usr/sbin/system_profiler", arguments: ["SPBluetoothDataType", "-json"]) {
            data = result
            completion(result)
        } else {
            error?()
        }
    }
}

class MagicBattery {
    static var shared: MagicBattery = MagicBattery()
    
    //var scanTimer: Timer?
    @AppStorage("readBTDevice") var readBTDevice = true
    //@AppStorage("readBTHID") var readBTHID = true
    @AppStorage("updateInterval") var updateInterval = 1
    @AppStorage("deviceName") var deviceName = "Mac"
    
    func startScan() {
        //let interval = TimeInterval(59.0 * updateInterval)
        //scanTimer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(scanDevices), userInfo: nil, repeats: true)
        Log.magic.notice("Start scanning Magic devices")
        scanDevices()
    }
    
    @objc func scanDevices() {
        //Thread.detachNewThread {
            if self.readBTDevice {
                self.getIOBTBattery()
                self.getOtherBTBattery()
                self.getMagicBattery()
                self.getOldMagicKeyboard()
                self.getOldMagicTrackpad()
                self.getOldMagicMouse()
            }
        //}
    }
    
    func findParentKey(forValue value: Any, in json: [String: Any]) -> String? {
        for (key, subJson) in json {
            if let subJsonDictionary = subJson as? [String: Any] {
                if subJsonDictionary.values.contains(where: { $0 as? String == value as? String }) {
                    return key
                } else if let parentKey = findParentKey(forValue: value, in: subJsonDictionary) {
                    return parentKey
                }
            } else if let subJsonArray = subJson as? [[String: Any]] {
                for subJsonDictionary in subJsonArray {
                    if subJsonDictionary.values.contains(where: { $0 as? String == value as? String }) {
                        return key
                    } else if let parentKey = findParentKey(forValue: value, in: subJsonDictionary) {
                        return parentKey
                    }
                }
            }
        }
        return nil
    }
    
    func getDeviceName(_ mac: String, _ def: String) -> String {
        //guard let result = process(path: "/usr/sbin/system_profiler", arguments: ["SPBluetoothDataType", "-json"]) else { return def }
        if let json = try? JSONSerialization.jsonObject(with: Data(SPBluetoothDataModel.shared.data.utf8), options: []) as? [String: Any] {
            if let parent = findParentKey(forValue: mac, in: json) {
                return parent
            }
        }
        return def
    }
    
    func getDeviceType(_ mac: String, _ def: String) -> String {
        let device = SPBluetoothDataModel.shared.connectedDevices.first { ($0.info["device_address"] as? String) == mac }
        return device?.info["device_minorType"] as? String ?? def
    }
    
    func readMagicBattery(object: io_object_t) {
        var mac = ""
        var type = "hid"
        var status = 0
        var percent = 0
        var productName = ""
        let lastUpdate = Date().timeIntervalSince1970
        if let productProperty = IORegistryEntryCreateCFProperty(object, "DeviceAddress" as CFString, kCFAllocatorDefault, 0) {
            if let value = productProperty.takeRetainedValue() as? String {
                mac = value.replacingOccurrences(of:"-", with:":").uppercased()
            }
        }
        if let percentProperty = IORegistryEntryCreateCFProperty(object, "BatteryStatusFlags" as CFString, kCFAllocatorDefault, 0) {
            if let value = percentProperty.takeRetainedValue() as? Int {
                status = value == 4 ? 0 : value
            }
        }
        if let percentProperty = IORegistryEntryCreateCFProperty(object, "BatteryPercent" as CFString, kCFAllocatorDefault, 0) {
            percent = (percentProperty.takeRetainedValue() as? Int) ?? percent
        }
        if let productProperty = IORegistryEntryCreateCFProperty(object, "Product" as CFString, kCFAllocatorDefault, 0),
           let value = productProperty.takeRetainedValue() as? String {
            productName = value
            if productName.contains("Trackpad") { type = "Trackpad" }
            if productName.contains("Keyboard") { type = "Keyboard" }
            if productName.contains("Mouse") { type = "MMouse" }
            if type == "hid" {
                type = getDeviceType(mac, type)
                if type.contains("Trackpad") { type = "Trackpad" }
                if type.contains("Keyboard") { type = "Keyboard" }
                if type.contains("Mouse") { type = "MMouse" }
            } else {
                productName = getDeviceName(mac, productName)
            }
        }
        if !productName.contains("Internal"){
            AirBatteryModel.updateDevice(Device(deviceID: mac, deviceType: type, deviceName: productName, batteryLevel: percent, isCharging: status, parentName: deviceName, lastUpdate: lastUpdate))
        }
    }

    func getMagicBattery() {
        var serialPortIterator = io_iterator_t()
        var object : io_object_t
        let masterPort: mach_port_t
        if #available(macOS 12.0, *) {
            masterPort = kIOMainPortDefault // New name in macOS 12 and higher
        } else {
            masterPort = kIOMasterPortDefault // Old name in macOS 11 and lower
        }
        let matchingDict : CFDictionary = IOServiceMatching("AppleDeviceManagementHIDEventService")
        let kernResult = IOServiceGetMatchingServices(masterPort, matchingDict, &serialPortIterator)
        
        if KERN_SUCCESS == kernResult {
            repeat {
                object = IOIteratorNext(serialPortIterator)
                if object != 0 { readMagicBattery(object: object); IOObjectRelease(object) }
            } while object != 0
            IOObjectRelease(object)
        }
        IOObjectRelease(serialPortIterator)
    }
    
    func getOldMagicKeyboard() {
        var serialPortIterator = io_iterator_t()
        var object : io_object_t
        let masterPort: mach_port_t
        if #available(macOS 12.0, *) { masterPort = kIOMainPortDefault } else { masterPort = kIOMasterPortDefault }
        let matchingDict : CFDictionary = IOServiceMatching("AppleBluetoothHIDKeyboard")
        let kernResult = IOServiceGetMatchingServices(masterPort, matchingDict, &serialPortIterator)
        if KERN_SUCCESS == kernResult {
            repeat {
                object = IOIteratorNext(serialPortIterator)
                if object != 0 { readMagicBattery(object: object); IOObjectRelease(object) }
            } while object != 0
            IOObjectRelease(object)
        }
        IOObjectRelease(serialPortIterator)
    }
    
    func getOldMagicTrackpad() {
        var serialPortIterator = io_iterator_t()
        var object : io_object_t
        let masterPort: mach_port_t
        if #available(macOS 12.0, *) { masterPort = kIOMainPortDefault } else { masterPort = kIOMasterPortDefault }
        let matchingDict : CFDictionary = IOServiceMatching("BNBTrackpadDevice")
        let kernResult = IOServiceGetMatchingServices(masterPort, matchingDict, &serialPortIterator)
        if KERN_SUCCESS == kernResult {
            repeat {
                object = IOIteratorNext(serialPortIterator)
                if object != 0 { readMagicBattery(object: object); IOObjectRelease(object) }
            } while object != 0
            IOObjectRelease(object)
        }
        IOObjectRelease(serialPortIterator)
    }
    
    func getOldMagicMouse() {
        var serialPortIterator = io_iterator_t()
        var object : io_object_t
        let masterPort: mach_port_t
        if #available(macOS 12.0, *) { masterPort = kIOMainPortDefault } else { masterPort = kIOMasterPortDefault }
        let matchingDict : CFDictionary = IOServiceMatching("BNBMouseDevice")
        let kernResult = IOServiceGetMatchingServices(masterPort, matchingDict, &serialPortIterator)
        if KERN_SUCCESS == kernResult {
            repeat {
                object = IOIteratorNext(serialPortIterator)
                if object != 0 { readMagicBattery(object: object); IOObjectRelease(object) }
            } while object != 0
            IOObjectRelease(object)
        }
        IOObjectRelease(serialPortIterator)
    }
    
    func getOtherBTBattery() {
        for device in SPBluetoothDataModel.shared.connectedDevices {
            guard let level = device.info["device_batteryLevelMain"] as? String,
                  let id = device.info["device_address"] as? String,
                  let type = device.info["device_minorType"] as? String,
                  (device.info["device_vendorID"] as? String) != "0x004C",
                  let batLevel = Int(level.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "%", with: "")) else { continue }
            AirBatteryModel.updateDevice(Device(deviceID: id, deviceType: type, deviceName: device.name, batteryLevel: batLevel, isCharging: 0, lastUpdate: Date().timeIntervalSince1970))
        }
    }
    
    func getIOBTBattery() {
        // IOBluetoothDevice objects are only read on the main thread (see deviceIsConnected):
        // only plain values leave it (AUDIT-2026-10-25, 1.5).
        let readings: [(name: String, address: String, battery: Int)] = onMainThread {
            guard let devices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else { return [] }
            return devices.compactMap { device in
                guard device.isConnected(), !device.isAppleDevice,
                      let battery = device.getValue(forKey: "batteryPercentSingle") as? Int, battery != 0,
                      let name = device.name, let address = device.addressString else { return nil }
                return (name, address, battery)
            }
        }
        for reading in readings {
            let type = getDeviceType(reading.address.replacingOccurrences(of: "-", with: ":").uppercased(), "")
            AirBatteryModel.updateDevice(Device(deviceID: reading.address, deviceType: type, deviceName: reading.name, batteryLevel: reading.battery, isCharging: 0, lastUpdate: Date().timeIntervalSince1970))
        }
    }
}

extension IOBluetoothDevice {
    func getValue(forKey: String) -> Any? {
        if self.responds(to: Selector((forKey))) {
            return self.value(forKey: forKey)
        }
        return nil
    }
    
    var isAppleDevice: Bool {
        return self.getValue(forKey: "isAppleDevice") as? Bool ?? false
    }
}
