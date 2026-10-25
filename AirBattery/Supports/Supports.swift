//
//  Support.swift
//  AirBattery
//
//  Created by apple on 2024/2/9.
//
import SwiftUI
import CryptoKit
import SystemConfiguration
import UserNotifications

let widgetInterval = ud.integer(forKey: "widgetInterval")
let updateInterval = ud.integer(forKey: "updateInterval")

// UI timers. A tolerance lets macOS group their wakeups with other work.
let mainTimer = Timer.publish(every: 1, tolerance: 0.1, on: .main, in: .common).autoconnect()
let dockTimer = Timer.publish(every: 5, tolerance: 0.5, on: .main, in: .common).autoconnect()

let macID = getMacModelIdentifier()
let isoFormatter = ISO8601DateFormatter()
var lowPowerNoteDelay = [String: Double]()

// Serialized incremental log reader for Enhanced HID scans
class LogReader {
    static let shared = LogReader()

    @AppStorage("readBTHID") var readBTHID = true
    @AppStorage("logReaderLastTS") var lastTS: String = ""   // e.g. "2025-07-01 12:34:56+0000"

    private var isRunning = false
    private var queued = false
    private let lock = NSLock()
    private let fmt: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        // The format `log show --start` accepts: no space before the time zone. With one, every
        // incremental read failed ("Failed conversion … using format '%Y-%m-%d %H:%M:%S%z'").
        // A value saved in the old format no longer parses, and the next run uses a window.
        f.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
        return f
    }()

    enum Trigger { case bootstrap, wake, connect }

    func run(_ trigger: Trigger) {
        guard readBTHID else { return }
        lock.lock()
        if isRunning { queued = true; lock.unlock(); return }
        isRunning = true
        lock.unlock()

        // The start time is an argument: an environment variable (setenv) was process-wide,
        // raced with other threads launching tools, and leaked into BTDBattery's own runs.
        let args: [String]
        if let start = computeStart(trigger) {
            args = ["\(Bundle.main.resourcePath!)/logReader.sh", "mac", "10m", start]
        } else {
            let win = (trigger == .bootstrap) ? "20m" : (trigger == .wake ? "3m" : "2m")
            args = ["\(Bundle.main.resourcePath!)/logReader.sh", "mac", win]
        }

        let out = process(path: "/bin/bash", arguments: args, timeout: 5)
        parseAndUpdate(output: out)
        advanceLastTS()

        lock.lock()
        isRunning = false
        let again = queued
        queued = false
        lock.unlock()

        if again {
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.8) { self.run(.wake) }
        }
    }

    private func computeStart(_ trigger: Trigger) -> String? {
        if lastTS.isEmpty {
            let t = Date(timeIntervalSinceNow: -20*60)
            return fmt.string(from: t)
        }
        if let prev = fmt.date(from: lastTS) {
            // After a long sleep, the previous run can be hours old: reading all those logs
            // took seconds of CPU and the 5 s timeout cut it short anyway. 10 minutes at most.
            let oldest = Date(timeIntervalSinceNow: -10 * 60)
            return fmt.string(from: max(prev.addingTimeInterval(-2), oldest))
        }
        return nil
    }

    private func advanceLastTS() {
        lastTS = fmt.string(from: Date().addingTimeInterval(-2))
    }

    private func parseAndUpdate(output: String?) {
        guard let output = output, !output.isEmpty else { return }
        let parent = ud.string(forKey: "deviceName") ?? "Mac"
        for line in output.split(separator: "\n") {
            if let json = try? JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any] {
                let mac = json["mac"] as? String ?? ""
                var name = json["name"] as? String ?? ""
                let type = json["type"] as? String ?? "hid"
                let time = json["time"] as? String ?? ""
                let level = json["level"] as? Int ?? 0
                let status = (json["status"] as? String == "+") ? 1 : 0
                if name.isEmpty { name = "\(type) (\(mac))" }
                AirBatteryModel.updateDevice(Device(deviceID: mac, deviceType: type, deviceName: name, batteryLevel: min(100, max(0, level)), isCharging: status, parentName: parent, lastUpdate: Date().timeIntervalSince1970, realUpdate: isoFormatter.date(from: time)?.timeIntervalSince1970 ?? 0.0))
            }
        }
    }
}

extension String {
    var boolValue: Bool { return (self as NSString).boolValue }
    var local: String { return NSLocalizedString(self, comment: "") }
}

extension NSMenuItem {
    func performAction() {
        guard let menu else {
            return
        }
        menu.performActionForItem(at: menu.index(of: self))
    }
}

extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return self.map { String(format: format, $0) }.joined()
    }
    
    func ascii() -> String? {
        var asciiString = ""
        for byte in self {
            asciiString.append(Character(UnicodeScalar(byte)))
        }
        return asciiString.replacingOccurrences(of: "\0", with: "")
    }
}

struct RectCorner: OptionSet {
    
    let rawValue: Int
        
    static let topLeft = RectCorner(rawValue: 1 << 0)
    static let topRight = RectCorner(rawValue: 1 << 1)
    static let bottomRight = RectCorner(rawValue: 1 << 2)
    static let bottomLeft = RectCorner(rawValue: 1 << 3)
    
    static let allCorners: RectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
}


struct RoundedCornersShape: Shape {
    
    var radius: CGFloat = .zero
    var corners: RectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let p1 = CGPoint(x: rect.minX, y: corners.contains(.topLeft) ? rect.minY + radius  : rect.minY )
        let p2 = CGPoint(x: corners.contains(.topLeft) ? rect.minX + radius : rect.minX, y: rect.minY )

        let p3 = CGPoint(x: corners.contains(.topRight) ? rect.maxX - radius : rect.maxX, y: rect.minY )
        let p4 = CGPoint(x: rect.maxX, y: corners.contains(.topRight) ? rect.minY + radius  : rect.minY )

        let p5 = CGPoint(x: rect.maxX, y: corners.contains(.bottomRight) ? rect.maxY - radius : rect.maxY )
        let p6 = CGPoint(x: corners.contains(.bottomRight) ? rect.maxX - radius : rect.maxX, y: rect.maxY )

        let p7 = CGPoint(x: corners.contains(.bottomLeft) ? rect.minX + radius : rect.minX, y: rect.maxY )
        let p8 = CGPoint(x: rect.minX, y: corners.contains(.bottomLeft) ? rect.maxY - radius : rect.maxY )

        
        path.move(to: p1)
        path.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.minY),
                    tangent2End: p2,
                    radius: radius)
        path.addLine(to: p3)
        path.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.minY),
                    tangent2End: p4,
                    radius: radius)
        path.addLine(to: p5)
        path.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.maxY),
                    tangent2End: p6,
                    radius: radius)
        path.addLine(to: p7)
        path.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.maxY),
                    tangent2End: p8,
                    radius: radius)
        path.closeSubpath()

        return path
    }
}

/// Runs a tool and returns its standard output, or nil if it failed or printed nothing.
/// Every call has a timeout (20 s by default): a hung tool used to block its thread forever.
public func process(path: String, arguments: [String], timeout: Int = 20) -> String? {
    let task = Process()
    task.launchPath = path
    task.arguments = arguments
    // A pipe nobody reads blocks the tool once it fills (64 KB): discard error output
    task.standardError = FileHandle.nullDevice

    let outputPipe = Pipe()
    defer { outputPipe.fileHandleForReading.closeFile() }
    task.standardOutput = outputPipe

    if timeout > 0 {
        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(timeout)) {
            guard task.isRunning else { return }
            // Name the tool, or the script run by bash; never the arguments (device IDs)
            let tool = ((path.hasSuffix("/bash") ? arguments.first ?? path : path) as NSString).lastPathComponent
            Log.process.warning("\(tool, privacy: .public) timed out after \(timeout, privacy: .public) s")
            // Stop the children first: `log show` started by a script kept running, and kept
            // the output pipe open, after its bash was killed.
            terminateTree(task.processIdentifier, signal: SIGTERM)
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(400)) {
                if task.isRunning { terminateTree(task.processIdentifier, signal: SIGKILL) }
            }
        }
    }

    do {
        try task.run()
    } catch let error {
        Log.process.error("Could not launch \((path as NSString).lastPathComponent, privacy: .public): \(error.localizedDescription, privacy: .public)")
        return nil
    }

    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(decoding: outputData, as: UTF8.self)

    if output.isEmpty { return nil }

    return output.trimmingCharacters(in: .newlines)
}

/// Sends `signal` to a process and all its descendants, children first.
private func terminateTree(_ pid: pid_t, signal: Int32) {
    let pgrep = Process()
    pgrep.launchPath = "/usr/bin/pgrep"
    pgrep.arguments = ["-P", String(pid)]
    pgrep.standardError = FileHandle.nullDevice
    let pipe = Pipe()
    pgrep.standardOutput = pipe
    if (try? pgrep.run()) != nil {
        let children = String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        pgrep.waitUntilExit()
        for child in children.split(separator: "\n").compactMap({ pid_t($0) }) {
            terminateTree(child, signal: signal)
        }
    }
    kill(pid, signal)
}

func getMenuBarHeight() -> CGFloat {
    let mouseLocation = NSEvent.mouseLocation
    let screen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) })
    if let screen = screen {
        return screen.frame.height - screen.visibleFrame.height - (screen.visibleFrame.origin.y - screen.frame.origin.y) - 1
    }
    return 0.0
}

func createAlert(level: NSAlert.Style = .warning, title: String, message: String, button1: String, button2: String = "") -> NSAlert {
    let alert = NSAlert()
    alert.messageText = title.local
    alert.informativeText = message.local
    alert.addButton(withTitle: button1.local)
    if button2 != "" { alert.addButton(withTitle: button2.local) }
    alert.alertStyle = level
    return alert
}

func registerNotificationCategory() {
    let delayAction = UNNotificationAction(
        identifier: "DELAY_30_MIN",
        title: "Snooze for 30 minutes".local,
        options: []
    )

    let category = UNNotificationCategory(
        identifier: "DELAY_CATEGORY",
        actions: [delayAction],
        intentIdentifiers: [],
        options: []
    )

    UNUserNotificationCenter.current().setNotificationCategories([category])
}

func createNotification(title: String, message: String, alertSound: Bool = true, interval: TimeInterval = 2, delay: Bool = false, info: String = "") {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = message
    content.sound = alertSound ? UNNotificationSound.default : nil
    if delay { content.categoryIdentifier = "DELAY_CATEGORY" }
    content.userInfo = ["customInfo": info]

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            Log.app.error("Notification failed to send: \(error.localizedDescription, privacy: .public)")
        }
    }
}


func randomString(length: Int) -> String {
    let characters = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
    var randomString = ""

    for _ in 0..<length {
        if let randomCharacter = characters.randomElement() {
            randomString.append(randomCharacter)
        }
    }
    return randomString
}

func getPowerState() -> iBattery {
    @AppStorage("machineType") var machineType = "mac"
    if !machineType.lowercased().contains("book") { return iBattery(hasBattery: false, isCharging: false, isCharged: false, acPowered: false, timeLeft: "", batteryLevel: 0) }
    let internalFinder = InternalFinder()
    if let internalBattery = internalFinder.getInternalBattery() {
        if let level = internalBattery.charge {
            var ib = iBattery(hasBattery: true, isCharging: internalBattery.isCharging ?? false, isCharged :internalBattery.isCharged ?? false, acPowered: internalBattery.acPowered ?? false, timeLeft: internalBattery.timeLeft, batteryLevel: Int(level))
            if #available(macOS 12.0, *) { ib.lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled }
            return ib
        }
    }
    return iBattery(hasBattery: false, isCharging: false, isCharged: false, acPowered: false, timeLeft: "", batteryLevel: 0)
}

func getPowerColor(_ device: Device) -> String {
    if device.lowPower { return "my_yellow" }
    
    var colorName = "my_green"
    if device.batteryLevel <= 10 {
        colorName = "my_red"
    } else if device.batteryLevel <= 20 {
        colorName = "my_yellow"
    }
    return colorName
}

func getDarkMode() -> Bool {
    @AppStorage("appearance") var appearance = "auto"
    return (appearance == "auto") ? NSApp.effectiveAppearance == NSAppearance(named: .darkAqua) : appearance.boolValue
}

func ib2ab(_ ib: iBattery) -> Device {
    @AppStorage("machineType") var machineType = "mac"
    @AppStorage("deviceName") var deviceName = "Mac"
    var name = deviceName
    #if DEBUG
    if DemoDevices.enabled { name = DemoDevices.macName }
    #endif
    return Device(hasBattery: ib.hasBattery, deviceID: "@MacInternalBattery", deviceType: machineType, deviceName: name, deviceModel: macID, batteryLevel: ib.batteryLevel, isCharging: ib.isCharging ? 1 : 0, isCharged: ib.isCharged, acPowered: ib.acPowered, lowPower: ib.lowPower, lastUpdate: Double(Date().timeIntervalSince1970))
}

func sliceList(data: [Device], length: Int, count: Int) -> [Device] {
    let totalLength = length * count
    if totalLength <= data.count { return Array(data[totalLength-length..<totalLength]) }
    var list: [Device]
    if totalLength - length > data.count {
        list = []
    } else {
        list = Array(data[totalLength-length..<data.count])
    }
    if list != [] { while list.count < length { list.append(Device(hasBattery: false, deviceID: "", deviceType: "blank", deviceName: "", batteryLevel: 0, isCharging: 0, lastUpdate: 0)) } }
    return list
}

func copyToClipboard(_ text: String) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(text, forType: .string)
}

func isGroupIDValid(id: String) -> Bool {
    let pre = NSPredicate(format: "SELF MATCHES %@", "^[a-zA-Z0-9\\-]+$")
    let pasd = pre.evaluate(with: id)
    return (id.count == 23 && String(id.prefix(3)) == "nc-" && pasd)
}

func getMacDeviceType() -> String {
    guard let result = process(path: "/usr/sbin/system_profiler", arguments: ["SPHardwareDataType", "-json"]) else { return "Mac" }
    if let json = try? JSONSerialization.jsonObject(with: Data(result.utf8), options: []) as? [String: Any],
       let SPHardwareDataTypeRaw = json["SPHardwareDataType"] as? [Any],
       let SPHardwareDataType = SPHardwareDataTypeRaw.first as? [String: Any],
       let model = SPHardwareDataType["machine_name"] as? String{
        return model.lowercased().replacingOccurrences(of: " ", with: "")
    }
    return "mac"
}

func getMacDeviceUUID() -> String? {
    let dev = IOServiceMatching("IOPlatformExpertDevice")
    let platformExpert: io_service_t = IOServiceGetMatchingService(kIOMasterPortDefault, dev)
    if platformExpert != 0 {
        if let serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformUUIDKey as CFString, kCFAllocatorDefault, 0)?.takeUnretainedValue() {
            IOObjectRelease(platformExpert)
            return serialNumberAsCFString as? String
        }
        IOObjectRelease(platformExpert)
    }
    return nil
}

func getMacModelIdentifier() -> String {
    var size = 0
    sysctlbyname("hw.model", nil, &size, nil, 0)
    var model = [CChar](repeating: 0,  count: Int(size))
    sysctlbyname("hw.model", &model, &size, nil, 0)
    if let modelString = String(validatingUTF8: model) {
        return modelString
    } else {
        return "unknow"
    }
}

func getMacDeviceName() -> String {
    @AppStorage("machineType") var machineType = "mac"
    var computerName: CFString?
    if let dynamicStore = SCDynamicStoreCreate(nil, "GetComputerName" as CFString, nil, nil) {
        computerName = SCDynamicStoreCopyComputerName(dynamicStore, nil) as CFString?
    }
    if let name = computerName as String? { return name }
    return machineType
}

/// Nil for a malformed Group ID (it could come from a hand-edited setting).
func generateSymmetricKey(password: String) -> SymmetricKey? {
    guard isGroupIDValid(id: password), let pass = substring(from: password, start: 15, length: 8) else { return nil }
    let salt = String(password.prefix(15))
    let passwordData = Data(pass.utf8)
    let saltData = Data(salt.utf8)
    let derivedKey = HKDF<SHA256>.deriveKey(inputKeyMaterial: SymmetricKey(data: passwordData), salt: saltData, info: Data(), outputByteCount: 32)
    return derivedKey
}

func encryptString(_ string: String, password: String) -> String? {
    guard let key = generateSymmetricKey(password: password) else { return nil }
    let stringData = Data(string.utf8)
    
    do {
        let sealedBox = try AES.GCM.seal(stringData, using: key)
        return sealedBox.combined?.base64EncodedString()
    } catch {
        Log.nearcast.error("Encryption error: \(String(describing: error), privacy: .public)")
        return nil
    }
}

func decryptString(_ string: String, password: String) -> String? {
    guard let key = generateSymmetricKey(password: password) else { return nil }
    
    do {
        guard let data = Data(base64Encoded: string) else { return nil }
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        return String(data: decryptedData, encoding: .utf8)
    } catch {
        Log.nearcast.error("Decryption error: \(String(describing: error), privacy: .public)")
        return nil
    }
}

func substring(from string: String, start: Int, length: Int) -> String? {
    guard start >= 0, length > 0, start + length <= string.count else {
        return nil
    }

    let startIndex = string.index(string.startIndex, offsetBy: start)
    let endIndex = string.index(startIndex, offsetBy: length)
    let substring = string[startIndex..<endIndex]
    return String(substring)
}


func getFiles(withExtension fileExtension: String, in directory: URL) -> [URL] {
    do {
        let filesAndDirectories = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil, options: [])
        let filteredFiles = filesAndDirectories.filter { $0.pathExtension == fileExtension }
        return filteredFiles
    } catch {
        Log.data.error("Failed to list \(directory.path): \(String(describing: error), privacy: .public)")
        return []
    }
}

func getHeadphoneModel(_ model: String) -> String {
    switch model {
    case "2002":
        return "Airpods"
    case "200e":
        return "Airpods Pro"
    case "200a", "201f":
        ///200a: Lightning
        ///201f: USB-C
        return "Airpods Max"
    case "200f":
        return "Airpods 2"
    case "2013":
        return "Airpods 3"
    case "201b", "2019":
        // Model IDs are built with "%02x%02x", i.e. lowercase hex: "201B" never matched and
        // AirPods 4 ANC fell back to the generic icon (upstream #166).
        ///201b: ANC
        ///2019: no ANC
        return "Airpods 4"
    case "2014", "2024":
        ///2014: Lightning Case
        ///2024: USB-C Case
        return "Airpods Pro 2"
    case "2003":
        return "PowerBeats 3"
    case "200d":
        return "PowerBeats 4"
    case "200b":
        return "PowerBeats Pro"
    case "200c":
        return "Beats Solo Pro"
    case "2011":
        return "Beats Studio Buds"
    case "2010":
        return "Beats Flex"
    case "2005":
        return "BeatsX"
    case "2006":
        return "Beats Solo 3"
    case "2009":
        return "Beats Studio 3"
    case "2017":
        return "Beats Studio Pro"
    case "2012":
        return "Beats Fit Pro"
    case "2016":
        return "Beats Studio Buds+"
    default:
        return "Headphones"
    }
}

func getDeviceIcon(_ d: Device) -> String {
    switch d.deviceType {
    case "blank":
        return "blank"
    case "virtual":
        return "square.dashed"
    case "general_bt":
        return "bluetooth.fill"
    case "MobilePhone":
        return "iphone.gen1"
    case "iPhone":
        if d.deviceModel == "iPhone19,4" { return "iphone.duo" }
        if let model = d.deviceModel, let m = model.components(separatedBy: ",").first, let id = m.components(separatedBy: "e").last {
            if (Int(id) ?? 0 < 10) || ["iPhone12,8", "iPhone14,6"].contains(model) { return "iphone.gen1" }
            if (Int(id) ?? 0 < 14) { return "iphone.gen2" }
        }
        return "iphone"
    case "iPad":
        if let model = d.deviceModel, let m = model.components(separatedBy: ",").first, let id = m.components(separatedBy: "d").last {
            if (Int(id) ?? 0 < 13) && !["iPad8"].contains(m) { return "ipad.gen1" }
        }
        return  "ipad"
    case "iPod":
        return "ipodtouch"
    case "Watch":
        return "applewatch"
    case "RealityDevice":
        return "visionpro"
    case "Trackpad":
        return "trackpad.fill"
    case "Keyboard":
        return "keyboard.fill"
    case "MMouse":
        return "magicmouse.fill"
    case "Mouse":
        return "computermouse.fill"
    case "Gamepad":
        return "gamecontroller.fill"
    case "Headphones", "Headset":
        return "headphones"
    case "Speaker":
        return "hifispeaker.fill"
    case "ApplePencil":
        ///Model list: https://theapplewiki.com/wiki/List_of_Apple_Pencils
        if let model = d.deviceModel {
            if model == "222" { return "applepencil.gen1" }
        }
        return "applepencil.gen2"
    case "Pencil":
        return "pencil"
    case "ap_pod_right":
        // AirPods Max models missing from the table below still have "AirPods Max" in their
        // default name: show the over-ear icon instead of an earbud (upstream #204, #205).
        // Matching only "max" would also catch someone named Max or Maxime.
        if d.deviceName.lowercased().contains("airpods max") { return "airpodsmax" }
        if let model = d.deviceModel {
            switch model {
            case "Airpods":
                return "airpod.right"
            case "Airpods Pro":
                return "airpodpro.right"
            case "Airpods Max":
                return "airpodsmax"
            case "Airpods 2":
                return "airpod.right"
            case "Airpods 3":
                return "airpod3.right"
            case "Airpods 4":
                return "airpod4.right"
            case "Airpods Pro 2":
                return "airpodpro.right"
            case "PowerBeats 3":
                return "beats.powerbeats3.right"
            case "PowerBeats 4":
                return "beats.powerbeats4.right"
            case "PowerBeats Pro":
                return "beats.powerbeatspro.right"
            case "Beats Solo Pro":
                return "beats.headphones"
            case "Beats Studio Buds":
                return "beats.studiobud.right"
            case "Beats Flex":
                return "beats.earphones"
            case "BeatsX":
                return "beats.earphones"
            case "Beats Solo 3":
                return "beats.headphones"
            case "Beats Studio 3":
                return "beats.headphones"
            case "Beats Studio Pro":
                return "beats.headphones"
            case "Beats Fit Pro":
                return "beats.fitpro.right"
            case "Beats Studio Buds+":
                return "beats.studiobud.right"
            default:
                return "airpod.right"
            }
        }
        return "airpod.right"
    case "ap_pod_left":
        if d.deviceName.lowercased().contains("airpods max") { return "airpodsmax" }
        if let model = d.deviceModel {
            switch model {
            case "Airpods":
                return "airpod.left"
            case "Airpods Pro":
                return "airpodpro.left"
            case "Airpods Max":
                return "airpodsmax"
            case "Airpods 2":
                return "airpod.left"
            case "Airpods 3":
                return "airpod3.left"
            case "Airpods 4":
                return "airpod4.left"
            case "Airpods Pro 2":
                return "airpodpro.left"
            case "PowerBeats 3":
                return "beats.powerbeats3.left"
            case "PowerBeats 4":
                return "beats.powerbeats4.left"
            case "PowerBeats Pro":
                return "beats.powerbeatspro.left"
            case "Beats Solo Pro":
                return "beats.headphones"
            case "Beats Studio Buds":
                return "beats.studiobud.left"
            case "Beats Flex":
                return "beats.earphones"
            case "BeatsX":
                return "beats.earphones"
            case "Beats Solo 3":
                return "beats.headphones"
            case "Beats Studio 3":
                return "beats.headphones"
            case "Beats Studio Pro":
                return "beats.headphones"
            case "Beats Fit Pro":
                return "beats.fitpro.left"
            case "Beats Studio Buds+":
                return "beats.studiobud.left"
            default:
                return "airpod.left"
            }
        }
        return "airpod.left"
    case "ap_pod_all":
        if d.deviceName.lowercased().contains("airpods max") { return "airpodsmax" }
        if let model = d.deviceModel {
            switch model {
            case "Airpods":
                return "airpods"
            case "Airpods Pro":
                return "airpodspro"
            case "Airpods Max":
                return "airpodsmax"
            case "Airpods 2":
                return "airpods"
            case "Airpods 3":
                return "airpods3"
            case "Airpods 4":
                return "airpods4"
            case "Airpods Pro 2":
                return "airpodspro"
            case "PowerBeats 3":
                return "beats.powerbeats3"
            case "PowerBeats 4":
                return "beats.powerbeats4"
            case "PowerBeats Pro":
                return "beats.powerbeatspro"
            case "Beats Solo Pro":
                return "beats.headphones"
            case "Beats Studio Buds":
                return "beats.studiobud"
            case "Beats Flex":
                return "beats.earphones"
            case "BeatsX":
                return "beats.earphones"
            case "Beats Solo 3":
                return "beats.headphones"
            case "Beats Studio 3":
                return "beats.headphones"
            case "Beats Studio Pro":
                return "beats.headphones"
            case "Beats Fit Pro":
                return "beats.fitpro"
            case "Beats Studio Buds+":
                return "beats.studiobud"
            default:
                return "airpodspro"
            }
        }
        return "airpodspro"
    case "ap_case":
        if d.deviceName.lowercased().contains("airpods max") { return "airpodsmax" }
        if let model = d.deviceModel {
            switch model {
            case "Airpods":
                return "airpods1.case.fill"
            case "Airpods Pro":
                return "airpodspro.case.fill"
            case "Airpods Max":
                return "airpodsmax"
            case "Airpods 2":
                return "airpods.case.fill"
            case "Airpods 3":
                return "airpods3.case.fill"
            case "Airpods 4":
                return "airpods4.case.fill"
            case "Airpods Pro 2":
                return "airpodspro.case.fill"
            case "PowerBeats 3":
                return "beats.powerbeatspro.case.fill"
            case "PowerBeats 4":
                return "beats.powerbeatspro.case.fill"
            case "PowerBeats Pro":
                return "beats.powerbeatspro.case.fill"
            case "Beats Solo Pro":
                return "beats.headphones"
            case "Beats Studio Buds":
                return "beats.studiobuds.case.fill"
            case "Beats Flex":
                return "beats.earphones"
            case "BeatsX":
                return "beats.earphones"
            case "Beats Solo 3":
                return "beats.headphones"
            case "Beats Studio 3":
                return "beats.studiobuds.case.fill"
            case "Beats Studio Pro":
                return "beats.headphones"
            case "Beats Fit Pro":
                return "beats.fitpro.case.fill"
            case "Beats Studio Buds+":
                return "beats.studiobuds.case.fill"
            default:
                return "airpodspro.case.fill"
            }
        }
        return "airpodspro.case.fill"
    case "mac", "applevirtualmachine1":
        return "display"
    case "macbook", "macbookpro", "macbookair", "macbookneo":
        if let icon = macBookList[macID] { return icon }
        return "macbook"
    case "macmini":
        return "macmini.fill"
    case "macstudio":
        return "macstudio.fill"
    case "macpro":
        if let icon = macProList[macID] { return icon }
        return "macpro.gen3.fill"
    case "imac", "imacpro":
        return "desktopcomputer"
    default:
        return "questionmark.circle.fill"
    }
}

let macBookList = ["MacBookPro1,1": "macbook.gen1", "MacBookPro1,2": "macbook.gen1", "MacBookPro2,1": "macbook.gen1", "MacBookPro2,2": "macbook.gen1", "MacBookPro3,1": "macbook.gen1", "MacBookPro4,1": "macbook.gen1", "MacBookPro5,1": "macbook.gen1", "MacBookPro5,2": "macbook.gen1", "MacBookPro5,3": "macbook.gen1", "MacBookPro5,4": "macbook.gen1", "MacBookPro5,5": "macbook.gen1", "MacBookPro6,1": "macbook.gen1", "MacBookPro6,2": "macbook.gen1", "MacBookPro7,1": "macbook.gen1", "MacBookPro8,1": "macbook.gen1", "MacBookPro8,2": "macbook.gen1", "MacBookPro8,3": "macbook.gen1", "MacBookPro9,1": "macbook.gen1", "MacBookPro9,2": "macbook.gen1", "MacBookPro10,1": "macbook.gen1", "MacBookPro10,2": "macbook.gen1", "MacBookPro11,1": "macbook.gen1", "MacBookPro11,2": "macbook.gen1", "MacBookPro11,3": "macbook.gen1", "MacBookPro11,4": "macbook.gen1", "MacBookPro11,5": "macbook.gen1", "MacBookPro12,1": "macbook.gen1", "MacBookPro13,1": "macbook.gen1", "MacBookPro13,2": "macbook.gen1", "MacBookPro13,3": "macbook.gen1", "MacBookPro14,1": "macbook.gen1", "MacBookPro14,2": "macbook.gen1", "MacBookPro14,3": "macbook.gen1", "MacBookPro15,1": "macbook.gen1", "MacBookPro15,2": "macbook.gen1", "MacBookPro15,3": "macbook.gen1", "MacBookPro15,4": "macbook.gen1", "MacBookPro16,1": "macbook.gen1", "MacBookPro16,2": "macbook.gen1", "MacBookPro16,3": "macbook.gen1", "MacBookPro16,4": "macbook.gen1", "MacBookPro17,1": "macbook.gen1", "MacBookPro18,1": "macbook", "MacBookPro18,2": "macbook", "MacBookPro18,3": "macbook", "MacBookPro18,4": "macbook", "Mac14,5": "macbook", "Mac14,6": "macbook", "Mac14,7": "macbook.gen1", "Mac14,9": "macbook", "Mac14,10": "macbook", "Mac15,3": "macbook", "Mac15,6": "macbook", "Mac15,7": "macbook", "Mac15,8": "macbook", "Mac15,9": "macbook", "Mac15,10": "macbook", "Mac15,11": "macbook", "MacBookAir1,1": "macbook.gen1", "MacBookAir2,1": "macbook.gen1", "MacBookAir3,1": "macbook.gen1", "MacBookAir3,2": "macbook.gen1", "MacBookAir4,1": "macbook.gen1", "MacBookAir4,2": "macbook.gen1", "MacBookAir5,1": "macbook.gen1", "MacBookAir5,2": "macbook.gen1", "MacBookAir6,1": "macbook.gen1", "MacBookAir6,2": "macbook.gen1", "MacBookAir7,1": "macbook.gen1", "MacBookAir7,2": "macbook.gen1", "MacBookAir8,1": "macbook.gen1", "MacBookAir8,2": "macbook.gen1", "MacBookAir9,1": "macbook.gen1", "MacBookAir10,1": "macbook.gen1", "Mac14,2": "macbook", "Mac14,15": "macbook", "Mac15,12": "macbook", "Mac15,13": "macbook", "MacBook1,1": "macbook.gen1", "MacBook2,1": "macbook.gen1", "MacBook3,1": "macbook.gen1", "MacBook4,1": "macbook.gen1", "MacBook5,1": "macbook.gen1", "MacBook5,2": "macbook.gen1", "MacBook6,1": "macbook.gen1", "MacBook7,1": "macbook.gen1", "MacBook8,1": "macbook.gen1", "MacBook9,1": "macbook.gen1", "MacBook10,1": "macbook.gen1", "Mac17,5": "macbook"]

let macProList = ["MacPro1,1": "macpro.gen1.fill", "MacPro2,1": "macpro.gen1.fill", "MacPro3,1": "macpro.gen1.fill", "MacPro4,1": "macpro.gen1.fill", "MacPro5,1": "macpro.gen1.fill", "MacPro6,1": "macpro.gen2.fill", "MacPro7,1": "macpro.gen3.fill", "Mac14,8": "macpro.gen3.fill"]

/// Runs `work` on the main thread and returns its result. Never call it while holding a lock
/// the main thread may wait for.
func onMainThread<T>(_ work: () -> T) -> T {
    if Thread.isMainThread { return work() }
    return DispatchQueue.main.sync(execute: work)
}

