//
//  AirBatteryApp.swift
//  AirBattery
//
//  Created by apple on 2023/9/4.
//
import AppKit
import SwiftUI
import WidgetKit
import UserNotifications
import IOBluetooth
import Sparkle
import ServiceManagement
import IOKit.ps

let fd = FileManager.default
let ud = UserDefaults.standard
var updaterController: SPUStandardUpdaterController!
var statusBarItem: NSStatusItem!
var pinnedItems = [NSStatusItem]()
/// Icon name currently shown by each pinned item, keyed by device name.
var pinnedIcons = [String: String]()
var netcastService: MultipeerService = MultipeerService(serviceType: "airbattery-nc")
let ncFolder = fd.urls(for: .libraryDirectory, in: .userDomainMask).first!.appendingPathComponent("Containers/\(AirBatteryModel.key)/Data/Documents/NearcastData")
let systemUUID = getMacDeviceUUID()
var dockWindow = AutoHideWindow()
var menuPopover = NSPopover()
let bleBattery = BLEBattery()
let btdBattery = BTDBattery()
var updateDelay = 1
var keepAliveActivity: NSObjectProtocol? = nil
// Serial queue: after wake many Bluetooth devices reconnect at once; handling them in
// parallel ran several system_profiler scans and data updates concurrently.
let btConnectQueue = DispatchQueue(label: "\(AppIdentifiers.app).btconnect", qos: .background)

@main
struct AirBatteryApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // If you want to start the updater manually, pass false to startingUpdater and call .startUpdater() later
        // This is where you can also pass an updater delegate if you need one
        updaterController = SPUStandardUpdaterController(startingUpdater: updatesEnabled, updaterDelegate: nil, userDriverDelegate: nil)
        registerNotificationCategory()
    }
    
    var body: some Scene {
        Settings {
            SettingsView()
                .background(
                    WindowAccessor(
                        onWindowOpen: { w in
                            if let w = w {
                                //w.level = .floating
                                w.titlebarSeparatorStyle = .none
                                guard let nsSplitView = findNSSplitVIew(view: w.contentView),
                                      let controller = nsSplitView.delegate as? NSSplitViewController else { return }
                                controller.splitViewItems.first?.canCollapse = false
                                controller.splitViewItems.first?.minimumThickness = 175
                                controller.splitViewItems.first?.maximumThickness = 175
                                w.orderFront(nil)
                            }
                        })
                )
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, UNUserNotificationCenterDelegate {
    //static let shared = AppDelegate()
    @AppStorage("showOn") var showOn = "sbar"
    @AppStorage("machineType") var machineType = "mac"
    @AppStorage("deviceName") var deviceName = "Mac"
    @AppStorage("ncGroupID") var ncGroupID = ""
    @AppStorage("nearCast") var nearCast = false
    @AppStorage("launchAtLogin") var launchAtLogin = false
    @AppStorage("intBattOnStatusBar") var intBattOnStatusBar = true
    @AppStorage("batteryPercent") var batteryPercent = "outside"
    @AppStorage("alertSound") var alertSound = true
    @AppStorage("readBTHID") var readBTHID = true
    @AppStorage("hideLevel") var hideLevel = 90
    @AppStorage("disappearTime") var disappearTime = 20
    @AppStorage("whitelistMode") var whitelistMode = false
    @AppStorage("iosBatteryStyle") var iosBatteryStyle = false
    @AppStorage("updateInterval") var updateInterval = 1
    @AppStorage("carouselMode") var carouselMode = true
    
    //加载旧版设置项
    @AppStorage("alertLevel") var alertLevel = 10
    @AppStorage("fullyLevel") var fullyLevel = 100
    
    //var statusMenu: NSMenu = NSMenu()
    var menu: NSMenu = NSMenu()
    var startTime = Date()
    let nc = NSWorkspace.shared.notificationCenter
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        if response.actionIdentifier == "DELAY_30_MIN" {
            let deviceName = response.notification.request.content.userInfo["customInfo"] as? String ?? ""
            lowPowerNoteDelay[deviceName] = Date().timeIntervalSince1970 + 1800
        }
        completionHandler()
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // 用户点击 Dock 图标时会调用这个方法
        if showOn == "sbar" || showOn == "none" {
            openSettingPanel()
            return false
        }
        if dockWindow.isVisible {
            dockWindow.orderOut(nil)
        } else {
            var allDevices = AirBatteryModel.getAll()
            let ibStatus = InternalBattery.status
            if ibStatus.hasBattery { allDevices.insert(ib2ab(ibStatus), at: 0) }
            allDevices = AirBatteryModel.sortForDisplay(allDevices)
            let contentViewSwiftUI = popover(fromDock: true, allDevice: allDevices)
            let contentView = NSHostingView(rootView: contentViewSwiftUI)
            let hiddenRow = AirBatteryModel.getBlackList().count > 0 ? 1 : 0
            let allNearcast = getFiles(withExtension: "json", in: ncFolder)
            var ncCount = 0
            var ncDeviceCount = 0
            for jsonUrl in allNearcast {
                let count = AirBatteryModel.ncGetAll(url: jsonUrl).count
                if count != 0 {
                    ncCount += 7
                    ncDeviceCount += count
                }
            }
            var menuHeight = CGFloat((max(max(allDevices.count,1)+ncDeviceCount,1)+hiddenRow)*37+30+ncCount)
            // Liquid Glass layout: measure the view (the formula above doesn't know its margins)
            if ListMetrics.liquidGlass { menuHeight = contentView.fittingSize.height }
            let mouse = NSEvent.mouseLocation
            var menuX = mouse.x
            var menuY = mouse.y
            if let screen = NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.frame, false) }) {
                let visibleFrame = screen.visibleFrame
                var dockOrientation = "bottom"
                if let defaults = UserDefaults(suiteName: "com.apple.dock"), let orientation = defaults.string(forKey: "orientation") { dockOrientation = orientation }
                switch dockOrientation {
                case "bottom":
                    // Dock 位于屏幕底部
                    //menuX = menuX + 186 > visibleFrame.maxX ? visibleFrame.maxX - 362 : menuX - 176
                    if menuX + 186 > visibleFrame.maxX {
                        menuX = visibleFrame.maxX - 362
                    } else if menuX - 166 < visibleFrame.minX {
                        menuX = visibleFrame.minX + 10
                    } else {
                        menuX = menuX - 176
                    }
                    menuY = max(menuY, visibleFrame.origin.y) + 20
                case "right":
                    // Dock 位于屏幕右侧
                    menuX = menuX + 352 > visibleFrame.maxX ? visibleFrame.maxX - 372 : menuX + 10
                    menuY = max(menuY - menuHeight/2, visibleFrame.origin.y)
                case "left":
                    // Dock 位于屏幕左侧
                    menuX = menuX + 352 > visibleFrame.maxX ? visibleFrame.maxX - 372 : menuX
                    menuX = menuX < visibleFrame.origin.x ? visibleFrame.origin.x + 20 : menuX + 10
                    menuY = max(menuY - menuHeight/2, visibleFrame.origin.y)
                default:
                    Log.app.error("Failed to get Dock orientation")
                }
            }
            contentView.frame = NSRect(x: menuX, y: menuY, width: 352, height: menuHeight)
            dockWindow = AutoHideWindow(contentRect: contentView.frame, styleMask: [.fullSizeContentView], backing: .buffered, defer: false)
            dockWindow.title = "AirBattery Plus Dock Window"
            dockWindow.level = .popUpMenu
            dockWindow.isOpaque = false
            dockWindow.backgroundColor = NSColor.clear
            if #available(macOS 26.0, *) {
                // Same glass and corner radius as the menu bar popover, so the lists inside
                // stay concentric with the window (D-020)
                let glass = NSGlassEffectView(frame: NSRect(origin: .zero, size: contentView.frame.size))
                glass.cornerRadius = ListMetrics.popoverCornerRadius
                // The window keeps the size measured above: left to the hosting view, it could
                // be resized after showing and grow down past the bottom of the screen
                contentView.sizingOptions = []
                contentView.frame.origin = .zero
                glass.contentView = contentView
                dockWindow.contentView = glass
                dockWindow.hasShadow = true
                var frame = dockWindow.frame
                if let visible = (dockWindow.screen ?? NSScreen.main)?.visibleFrame {
                    frame.origin.y = min(max(frame.origin.y, visible.minY), visible.maxY - frame.height)
                }
                Log.app.debug("Dock window frame \(NSStringFromRect(frame), privacy: .public)")
                dockWindow.setFrame(frame, display: false)
            } else {
                dockWindow.contentView = contentView
                dockWindow.contentView?.wantsLayer = true
                dockWindow.contentView?.layer?.cornerRadius = 7
                dockWindow.contentView?.layer?.masksToBounds = true
            }
            dockWindow.makeKeyAndOrderFront(nil)
        }
        return true
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        // AppIdentifiers.prefix must match the APP_ID_PREFIX build setting,
        // otherwise the widget container path and the helper checks break silently.
        assert(Bundle.main.bundleIdentifier == AppIdentifiers.app,
               "AppIdentifiers.prefix is out of sync with APP_ID_PREFIX")
        // default defaults (used if not set)
        ud.register(
            defaults: [
                "showOn": "sbar",
                "machineType": "mac",
                "deviceName": "Mac",
                "launchAtLogin": false,
                "intBattOnStatusBar": true,
                "deviceOnWidget": "",
                "updateInterval": 1,
                "widgetInterval": 0,
                "hideLevel": 90,
                "nearCast": false,
                "readBTHID": true,
                "whitelistMode": false,
                "neverRemindMe": [String]()
            ]
        )
        
        updateDelay = updateInterval
        machineType = getMacDeviceType()
        deviceName = getMacDeviceName()
        InternalBattery.status = getPowerState()
        
        if showOn == "dock" || showOn == "both" { NSApp.setActivationPolicy(.regular) }
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds, .withTimeZone]
        menu.addItem(withTitle:"Settings...".local, action: #selector(openSetting), keyEquivalent: "")
        menu.addItem(withTitle:"About AirBattery Plus".local, action: #selector(openAbout), keyEquivalent: "")
        
        //处理旧版偏好设置
        if let alertList = (ud.object(forKey: "alertList") ?? []) as? [String] {
            let alerts: [btAlert] = alertList.map({
                btAlert(name: $0, full: fullyLevel == 100 ? 99 : fullyLevel, fullOn: true, fullSound: alertSound, low: alertLevel, lowOn: true, lowSound: alertSound)
            })
            ud.set([], forKey: "alertList")
            ud.set(object: alerts, forKey: "alertList")
        }
        
        if !fd.fileExists(atPath: ncFolder.path) {
            do {
                try fd.createDirectory(at: ncFolder, withIntermediateDirectories: true, attributes: nil)
                Log.nearcast.notice("Nearcast folder created at \(ncFolder.path)")
            } catch {
                Log.nearcast.error("Failed to create the Nearcast folder: \(String(describing: error), privacy: .public)")
            }
        } else {
            let oldFiles = getFiles(withExtension: "json", in: ncFolder)
            for url in oldFiles { try? fd.removeItem(at: url) }
        }
        
        startTime = Date()
        nc.addObserver(self, selector: #selector(onDisplayWake), name: NSWorkspace.screensDidWakeNotification, object: nil)
        IOBluetoothDevice.register(forConnectNotifications: self, selector: #selector(deviceIsConnected(notification:fromDevice:)))
        NSAppleEventManager.shared().setEventHandler(self, andSelector: #selector(handleURLEvent(_:replyEvent:)), forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
        //if let window = NSApplication.shared.windows.first { window.close() }
        launchAtLogin = LoginItem.isEnabled
        Log.app.notice("Launch at login: \(self.launchAtLogin, privacy: .public)")
        Log.app.notice("Icon mode: \(self.showOn, privacy: .public)")
        if nearCast && isGroupIDValid(id: ncGroupID) { netcastService.resume() }
        if let result = process(path: "/usr/sbin/system_profiler", arguments: ["SPBluetoothDataType", "-json"]) { SPBluetoothDataModel.shared.data = result }
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error { Log.app.error("Notification authorization denied: \(error.localizedDescription, privacy: .public)") }
        }
        UNUserNotificationCenter.current().delegate = self
        
        bleBattery.startScan()
        btdBattery.startScan()
        MagicBattery.shared.startScan()
        IDeviceBattery.shared.startScan()
        Scheduler.shared.start()
        PowerSourceMonitor.shared.start()
        #if DEBUG
        DemoDevices.start()
        #endif
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            AirBatteryModel.writeData(force: true)
            _ = AirBatteryModel.singleDeviceName()
            WidgetCenter.shared.reloadAllTimelines()
        }
        
        //menu.delegate = self
        //statusMenu.delegate = self
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        // A stable name lets macOS and menu bar managers (Ice, Bartender…) remember the
        // item's position across launches (upstream #182).
        statusBarItem.autosaveName = "AirBatteryMainStatusItem"
        //statusBarItem.menu = statusMenu
        if let button = statusBarItem.button {
            button.target = self
            let ib = getPowerState()
            let iconView = NSHostingView(rootView: mainBatteryView())
            if ib.hasBattery && intBattOnStatusBar {
                iconView.frame = NSRect(x: 0, y: 0, width: 42, height: 21.5)
            } else {
                iconView.frame = NSRect(x: 0, y: 0, width: 36, height: 21.5)
            }
            button.image = NSImage()
            button.addSubview(iconView)
            button.frame = iconView.frame
            button.action = #selector(togglePopover(_ :))
        }
        statusBarItem.isVisible = !(showOn == "dock" || showOn == "none")
        NSApp.dockTile.contentView = NSHostingView(rootView: MultiBatteryView())
        NSApp.dockTile.display()
        if nearCast {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                netcastService.refreshAll()
            }
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let opts: ProcessInfo.ActivityOptions = [.automaticTerminationDisabled, .suddenTerminationDisabled]
        keepAliveActivity = ProcessInfo.processInfo.beginActivity(options: opts, reason: "AirBattery menu bar monitoring")

        if showOn == "dock" || showOn == "both" {
            let tipID = "ab.docktile-power.note"
            let never = (ud.stringArray(forKey: "neverRemindMe") ?? [])
            if !never.contains(tipID) {
                let alert = createAlert(title: "AirBattery Plus Tips".local, message: "Displaying AirBattery Plus on the Dock will consume more power, it is better to use Menu Bar mode or Widgets.".local, button1: "Don't remind me again", button2: "OK")
                if alert.runModal() == .alertFirstButtonReturn { ud.setValue(never + [tipID], forKey: "neverRemindMe") }
            }
        }
        
        if readBTHID {
            let tipID = "ab.third-party-device.note"
            let never = (ud.stringArray(forKey: "neverRemindMe") ?? [])
            if !never.contains(tipID) {
                let alert = createAlert(title: "AirBattery Plus Tips".local, message: "If some of your devices shows battery level in the Bluetooth menu, but AirBattery Plus doesn't find it. Try disconnecting and reconnecting it, and wait a few minutes.".local, button1: "Don't remind me again", button2: "OK")
                if alert.runModal() == .alertFirstButtonReturn { ud.setValue(never + [tipID], forKey: "neverRemindMe") }
            }
            // Bootstrap Enhanced HID scan incrementally with a short initial window
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                LogReader.shared.run(.bootstrap)
            }
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        if let act = keepAliveActivity { ProcessInfo.processInfo.endActivity(act) }

        _ = process(path: "/usr/bin/killall", arguments: ["idevicesyslog"])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                    willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }
    
    @objc func onDisplayWake() {
        if readBTHID {
            DispatchQueue.global().asyncAfter(deadline: .now() + 10) {
                LogReader.shared.run(.wake)
            }
        }
    }
    
    /// Last time a connection was handled, by Bluetooth address (main thread only).
    private var lastConnectHandled: [String: Date] = [:]

    @objc func deviceIsConnected(notification: IOBluetoothUserNotification, fromDevice device: IOBluetoothDevice) {
        if readBTHID {
            let now = Date()
            if now.timeIntervalSince(startTime) >= 10 {
                if let name = device.name, let macAdd = device.addressString {
                    if AirBatteryModel.checkIfBlocked(name: name) { return }
                    // A device reconnecting in a loop must not start a full read each time
                    // (system_profiler, logs): at most one per device and per minute.
                    if let last = lastConnectHandled[macAdd], now.timeIntervalSince(last) < 60 { return }
                    lastConnectHandled[macAdd] = now
                    //if let prefix = getFirstNCharacters(of: macAdd, count: 8) {
                        Log.bluetooth.notice("\(name) (\(macAdd)) connected")
                        // Read everything from the IOBluetoothDevice here on the main thread.
                        // Capturing the device in the background closure crashed with
                        // "pointer being freed was not allocated" when the closure released it
                        // (e.g. devices reconnecting after wake from sleep).
                        let isAppleDevice = device.isAppleDevice
                        btConnectQueue.async {
                            usleep(2500000)
                            //if !appleMacPrefix.contains(prefix) {
                            if !isAppleDevice {
                                SPBluetoothDataModel.shared.refreshData { _ in
                                    LogReader.shared.run(.connect)
                                    MagicBattery.shared.getIOBTBattery()
                                    MagicBattery.shared.getOtherBTBattery()
                                }
                            } else {
                                if let device = AirBatteryModel.getByName(name) {
                                    if ["Trackpad", "Keyboard", "MMouse", "Mouse"].contains(device.deviceType) {
                                        SPBluetoothDataModel.shared.refreshData { _ in MagicBattery.shared.scanDevices() }
                                    }
                                } else {
                                    SPBluetoothDataModel.shared.refreshData { _ in MagicBattery.shared.scanDevices() }
                                }
                            }
                        }
                    //}
                }
            }
        }
    }
    
    
    @objc func togglePopover(_ sender: Any?) {
        if let button = statusBarItem.button, !menuPopover.isShown {
            var allDevices = AirBatteryModel.getAll()
            let ibStatus = InternalBattery.status
            if ibStatus.hasBattery { allDevices.insert(ib2ab(ibStatus), at: 0) }
            allDevices = AirBatteryModel.sortForDisplay(allDevices)
            let contentView = NSHostingController(rootView: popover(fromDock: false, allDevice: allDevices))
            menuPopover.setValue(true, forKeyPath: "shouldHideAnchor")
            menuPopover.contentViewController = contentView
            menuPopover.behavior = .transient
            var bound = button.bounds
            if #available(macOS 26.0, *) {
                // The hidden anchor still takes room: without this the popover sat ~9.5 pt
                // below the menu bar, versus ~2.5-3 pt for other Liquid Glass menu bar apps
                // (measured on a notched MacBook Pro). Not yet checked on a 24 pt menu bar.
                bound.origin.y -= 7
            } else if getMenuBarHeight() == 24.0 { bound.origin.y -= 6 }
            menuPopover.show(relativeTo: bound, of: button, preferredEdge: .minY)
            //menuPopover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            menuPopover.contentViewController?.view.window?.makeKeyAndOrderFront(nil)
        }
    }
    
    @objc func handleURLEvent(_ event: NSAppleEventDescriptor, replyEvent: NSAppleEventDescriptor) {
        if let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
           let url = URL(string: urlString) {
            if url.scheme == AppIdentifiers.urlScheme {
                switch url.host {
                case "writedata" :
                    Log.app.debug("URL command: write data")
                    AirBatteryModel.writeData(force: true)
                case "reloadwidgets", "reloadwingets" :  // the misspelled form was the original one
                    Log.app.debug("URL command: reload widgets")
                    AirBatteryModel.writeData(force: true)
                    WidgetCenter.shared.reloadAllTimelines()
                default: Log.app.error("Unknown URL command: \(url.host ?? "", privacy: .public)")
                }
            }
        }
    }
     
    @objc func openAbout() {
        openAboutPanel()
    }
    
    @objc func openSetting() {
        openSettingPanel()
    }
    
    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        dockWindow.orderOut(nil)
        return menu
    }
}

class NNSWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }
}

class AutoHideWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }
    
    override func resignKey() {
        super.resignKey()
        self.orderOut(nil)
    }
}

extension NSImage {
    func resized(to maxSize: NSSize) -> NSImage {
        let aspectWidth = maxSize.width / self.size.width
        let aspectHeight = maxSize.height / self.size.height
        let aspectRatio = min(aspectWidth, aspectHeight)
        
        let newSize = NSSize(width: self.size.width * aspectRatio, height: self.size.height * aspectRatio)
        
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        self.draw(in: NSRect(origin: .zero, size: newSize),
                  from: NSRect(origin: .zero, size: self.size),
                  operation: .sourceOver,
                  fraction: 1.0)
        newImage.unlockFocus()
        
        return newImage
    }
}

public extension UserDefaults {
    func set<T: Codable>(object: T, forKey: String) {
        if let jsonData = try? JSONEncoder().encode(object) {
            set(jsonData, forKey: forKey)
        }
    }
    
    func get<T: Codable>(objectType: T.Type, forKey: String) -> T? {
        guard let result = value(forKey: forKey) as? Data else {
            return nil
        }

        return try? JSONDecoder().decode(objectType, from: result)
    }
}

func refreshPinnedBar(unpin: String? = nil) {
    var pinnedList = (ud.stringArray(forKey: "pinnedList") ?? [])
    if pinnedList.isEmpty { return }
    if let unpin = unpin { pinnedList.removeAll(where: { DeviceIdentity.sameName($0, unpin) }) }
    var allDevices = AirBatteryModel.getAll()
    let ncFiles = getFiles(withExtension: "json", in: ncFolder)
    for ncFile in ncFiles { allDevices += AirBatteryModel.ncGetAll(url: ncFile) }
    let pinnedDevices = allDevices.filter({ pinnedList.containsDeviceName($0.deviceName) })
    let deviceNames = pinnedDevices.map({ $0.deviceName })
    for device in pinnedDevices {
        if let index = pinnedItems.firstIndex(where: { $0.button?.toolTip == device.deviceName }) {
            if let button = pinnedItems[index].button {
                // The icon was only set when the item was created: a device first seen with the
                // generic Bluetooth icon kept it forever, while the popover showed the right one.
                setPinnedIcon(button, device: device)
                button.title = "\(device.batteryLevel)\(device.isCharging != 0  ? "⚡︎" : "%")"
            }
        } else {
            let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            statusItem.autosaveName = "AirBatteryPinned.\(device.deviceName)"
            if let button = statusItem.button {
                setPinnedIcon(button, device: device)
                button.title = "\(device.batteryLevel)\(device.isCharging != 0  ? "⚡︎" : "%")"
                button.toolTip = device.deviceName
            }
            pinnedItems.append(statusItem)
        }
    }
    let expItems = pinnedItems.filter({ !pinnedList.containsDeviceName($0.button?.toolTip ?? "") || !deviceNames.contains($0.button?.toolTip ?? "") })
    let expNames = expItems.map({ $0.button?.toolTip ?? "" })
    DispatchQueue.main.async { for e in expItems { NSStatusBar.system.removeStatusItem(e) } }
    pinnedItems.removeAll{ expNames.contains($0.button?.toolTip ?? "") }
    for name in expNames { pinnedIcons.removeValue(forKey: name) }
}

func setPinnedIcon(_ button: NSStatusBarButton, device: Device) {
    let icon = getDeviceIcon(device)
    guard pinnedIcons[device.deviceName] != icon, let image = NSImage(named: icon) else { return }
    let resized = image.resized(to: NSSize(width: 17, height: 17))
    resized.isTemplate = true
    button.image = resized
    pinnedIcons[device.deviceName] = icon
}

/// Launch at login through the bundled helper (Contents/Library/LoginItems), the same
/// registration as before, so existing users keep a single login item.
enum LoginItem {
    /// macOS 13+: the state macOS reports. macOS 12 has no API for it: the helper only runs
    /// when the app was launched at login, which is the best available hint.
    static var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.loginItem(identifier: AppIdentifiers.helper).status == .enabled
        }
        return NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == AppIdentifiers.helper }
    }

    @discardableResult
    static func set(_ enabled: Bool) -> Bool {
        if #available(macOS 13.0, *) {
            let service = SMAppService.loginItem(identifier: AppIdentifiers.helper)
            do {
                if enabled { try service.register() } else { try service.unregister() }
                return true
            } catch {
                Log.app.error("Login item \(enabled ? "register" : "unregister", privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
                return false
            }
        }
        let ok = SMLoginItemSetEnabled(AppIdentifiers.helper as CFString, enabled)
        if !ok { Log.app.error("SMLoginItemSetEnabled failed for \(AppIdentifiers.helper, privacy: .public)") }
        return ok
    }
}

/// Periodic background work. It used to hang off the Dock icon's SwiftUI view (installed even
/// in menu bar mode), and ran system_profiler on the main thread every 24 s.
/// Intervals follow the Nearbility refresh interval read at launch, as before.
final class Scheduler {
    static let shared = Scheduler()
    private var timers: [Timer] = []
    private let dataQueue = DispatchQueue(label: "\(AppIdentifiers.app).data", qos: .utility)

    func start() {
        let interval = TimeInterval(60 * max(updateInterval, 1))
        every(300) { batteryAlert() }
        every(interval) {
            if widgetInterval != -1 && AirBatteryModel.takeWidgetReloadNeeded() { WidgetCenter.shared.reloadAllTimelines() }
        }
        // system_profiler and the accessories (Magic and other Bluetooth): once per interval,
        // at most 5 min apart so they never look offline ("Remove Offline Device" starts at
        // 20 min, and the interval goes up to 99 min). Their levels move by 1% in hours, and a
        // newly connected device is read right away (deviceIsConnected). It ran every
        // 0.4 × interval, i.e. every 24 s by default.
        every(min(interval, 300)) { self.refreshAccessories() }
        // Widgets' data, written only when something shown changed (24 s by default), so it is
        // fresh before each widget reload.
        every(interval * 0.4) { self.dataQueue.async { AirBatteryModel.writeData() } }
        every(interval + Double(Int(arc4random_uniform(19)) - 9)) { self.broadcastNearcast() }
    }

    private func every(_ seconds: TimeInterval, _ work: @escaping () -> Void) {
        let timer = Timer(timeInterval: seconds, repeats: true) { _ in work() }
        timer.tolerance = seconds / 10
        RunLoop.main.add(timer, forMode: .common)
        timers.append(timer)
    }

    private func refreshAccessories() {
        // Serial queue: a slow system_profiler (after wake) can't pile up runs
        dataQueue.async {
            SPBluetoothDataModel.shared.refreshData(completion: { _ in
                MagicBattery.shared.scanDevices()
                AirBatteryModel.writeData()
            }, error: {
                AirBatteryModel.writeData()
            })
        }
    }

    private func broadcastNearcast() {
        let ncGroupID = ud.string(forKey: "ncGroupID") ?? ""
        guard ud.bool(forKey: "nearCast"), isGroupIDValid(id: ncGroupID) else { return }
        var allDevices = AirBatteryModel.getAll()
        allDevices.insert(ib2ab(InternalBattery.status), at: 0)
        do {
            let jsonData = try JSONEncoder().encode(allDevices)
            guard let jsonString = String(data: jsonData, encoding: .utf8) else { return }
            guard let data = encryptString(jsonString, password: ncGroupID) else { return }
            let sender = systemUUID ?? (ud.string(forKey: "deviceName") ?? "Mac")
            let message = NCMessage(id: String(ncGroupID.prefix(15)), sender: sender, command: "", content: data)
            netcastService.sendMessage(message)
        } catch {
            Log.data.error("Write JSON error: \(String(describing: error), privacy: .public)")
        }
    }
}

extension Notification.Name {
    /// Posted on the main thread after InternalBattery.status was read again.
    static let internalBatteryChanged = Notification.Name("\(AppIdentifiers.app).internalBatteryChanged")
}

/// Reads the Mac's battery when macOS reports a change, instead of every second
/// (AUDIT-2026-10-25, performance): power source changes (level, time left, charger),
/// Low Power Mode, and wake from sleep. A slow timer is kept as a safety net.
final class PowerSourceMonitor {
    static let shared = PowerSourceMonitor()
    private var source: CFRunLoopSource?
    private var timer: Timer?

    func start() {
        guard source == nil else { return }
        let context = Unmanaged.passUnretained(self).toOpaque()
        if let source = IOPSNotificationCreateRunLoopSource({ context in
            guard let context else { return }
            Log.app.debug("Power source changed")
            Unmanaged<PowerSourceMonitor>.fromOpaque(context).takeUnretainedValue().refresh()
        }, context)?.takeRetainedValue() {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
            self.source = source
        } else {
            Log.app.error("No power source notifications: falling back to the timer")
        }
        NotificationCenter.default.addObserver(forName: .NSProcessInfoPowerStateDidChange, object: nil, queue: .main) { [weak self] _ in self?.refresh() }
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in self?.refresh() }
        let timer = Timer(timeInterval: 60, repeats: true) { [weak self] _ in self?.refresh() }
        timer.tolerance = 10
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        refresh()
    }

    /// Main thread only (run loop source, observers and timer are all on it).
    func refresh() {
        InternalBattery.status = getPowerState()
        NotificationCenter.default.post(name: .internalBatteryChanged, object: nil)
    }
}

