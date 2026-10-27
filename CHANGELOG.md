# Changelog

Changes in this fork compared with the official [AirBattery](https://github.com/lihaoyun6/AirBattery) releases.

## Unreleased

### Fixes

- **iPhones, iPads and Apple Watches are read as soon as they show up**, over USB or Wi-Fi: the app now listens to macOS's device service (`usbmuxd`) instead of checking every 15 s. An idle iPhone turns on its Wi-Fi only a few seconds at a time, and the 15 s check often missed it. Then, as before, they're read once per refresh interval while they stay. Measured over 6 minutes: the iPhone and Watch were read 5 times instead of about 1 or 2.

### Performance

- No more `idevice_id` launches every 15 s (about 480 per hour): measured over 6 minutes, 32 → 0. If the device service can't be reached, the app goes back to checking every 15 s.

## 1.12.0 — 2026-10-26 (pre-release)

### Performance

- **The Mac's battery is read when it changes** (level, time left, charger, Low Power Mode, wake from sleep) instead of every second. The menu bar icon follows a charger plugged in or out right away. Measured over 3 minutes: idle wakeups went from about 30 per minute to 0 or 1.
- **Bluetooth accessories (Magic keyboards, mice and trackpads, and others) are read once per refresh interval** (every minute by default, at most every 5 minutes) instead of every 24 s: their level moves by 1% in hours, and a newly connected accessory is still read right away. Measured over 6 minutes: `system_profiler` ran 10 times instead of 17.

### Changes

- Each read of an iPhone, iPad or Apple Watch is written to the system log, with its connection (USB or Wi-Fi), to see how often an idle iPhone is really read over Wi-Fi. See them in Console, or with `log show --predicate 'subsystem == "io.github.msieurpafi.AirBattery" AND category == "idevice"'`.

### Note

- After the update, macOS asks again for local network access: allow it.

## 1.11.1 — 2026-10-25 (pre-release)

### Changes

- No change to the app: this version checks that updates found and installed by the app itself work, from 1.11.0.

### Note

- After the update, macOS asks again for local network access: allow it.

## 1.11.0 — 2026-10-25 (pre-release)

### Changes

- **In-app updates**: AirBattery Plus finds and installs new versions itself, from this repository's releases (Sparkle, turned off since 1.7.0). On its second launch it asks whether to check automatically; **Settings › General › Update** and **Check for Updates…** are back. Updates are installed only if they carry the project's signature (its own key, not the original app's). The only internet access is this check, to GitHub: see [Permissions & privacy](https://github.com/MsieurPafi/AirBattery-Plus/blob/main/docs/guide/en/permissions-privacy.md).
- Versions up to 1.10.0 can't update themselves: install this version by hand.

### Note

- After the update, macOS asks again for local network access: allow it.

## 1.10.0 — 2026-10-25 (pre-release)

Fixes from a full audit of the app (performance, security, code quality).

### Fixes

- **Fewer crash risks**: a Mac battery reporting a zero capacity, an empty Bluetooth report from `system_profiler`, unexpected values in the battery registry or in hand-edited settings, an AppleScript call without a device name, a malformed Nearcast group ID. Bluetooth devices are now read on the main thread only, and the Mac's battery status is protected against concurrent access (same kind of crash as upstream [#215](https://github.com/lihaoyun6/AirBattery/issues/215)).
- **Battery alerts, pins and hidden devices keep working when the app's language changes**: the AirPods case was saved as "(Case)" in English and is now shown as "(boîtier)" in French, so lists saved before 1.9.0 no longer matched it.
- **Two iPhones (or iPads, Watches) with the same name are shown as two devices** instead of overwriting each other. A device that reports the same ID under a new name stays one device, and the two forms of Bluetooth addresses (`aa-bb-…`, `AA:BB:…`) are recognized as one.
- **"Discover more BT devices" works again for devices reported in the Bluetooth logs** (third-party headphones and speakers): since upstream PR [#163](https://github.com/lihaoyun6/AirBattery/pull/163), the log reader passed malformed options and dates to `log show`, which rejected them, so it read nothing. It now reads at most the last 10 minutes of logs and escapes device names.
- **"Remove Offline Device › Never"** now works (it did nothing).
- **Launch at login** shows its real state, also when the app was opened by hand, and uses the current macOS API on macOS 13 and later. The existing login item is kept.
- When you save a battery alert while notifications are turned off for the app, it now says so and offers to open the notification settings.
- One Bluetooth device with an unreadable level no longer hides the devices after it.
- `abtp`: the minutes since the last update were negative in `--json`; `--csv` now quotes device names and gives levels as numbers.

### Performance

- **Less Bluetooth traffic**: the app no longer reconnects every minute to Bluetooth LE mice and keyboards that macOS keeps connected (such as a Logitech MX): it just reads their level again. With "Discover iOS devices via Bluetooth", an iPhone also read over USB or Wi-Fi is no longer re-read over Bluetooth every minute, nor over USB/Wi-Fi every 15 s. A device reconnecting in a loop starts at most one full read per minute.
- **Less background work**: the widgets' data is only rewritten, and the widgets reloaded, when something they show changes (or every 5 minutes); `system_profiler` no longer runs on the main thread; the Mac's battery is read once per second instead of twice; timers let macOS group their wakeups. Measured over 6 minutes: about a third fewer `system_profiler` runs and 70% fewer widget reloads.
- **External tools can no longer hang**: every tool gets a timeout (20 s by default), a timed-out script is stopped with its children, and error output can no longer block a tool. iPhone/iPad scans no longer overlap, devices that can't be read are retried once per refresh interval instead of every 15 s, and the Apple Pencil is read once per interval.
- IOKit references were leaked at each scan of Magic accessories; the Bluetooth and HID scans were started by their timers with an invalid argument.

### Changes

- The URL command `airbattery-plus://reloadwidgets` is accepted with this spelling (the original misspelled `reloadwingets` still works).
- About 660 lines of unused code removed (old features left commented out, unused helpers and views).
- Unit tests for the device matching and parsing logic (`swift test`).

### Security

- **Nearcast**: data from another Mac can no longer be written outside the Nearcast folder, files are written atomically, a peer can no longer make this Mac connect a Bluetooth device, and unknown commands are no longer echoed back (that echo could be used to forge notifications). A stronger Nearcast protocol is planned ([#41](https://github.com/MsieurPafi/AirBattery-Plus/issues/41)).

### Note

- After the update, macOS asks again for local network access: allow it.

## 1.9.0 — 2026-10-25 (pre-release)

### New

- **French translation** of the app, from upstream [#170](https://github.com/lihaoyun6/AirBattery/pull/170) by leo1425, reviewed and completed. The app follows the language set in macOS, and can be set per app in System Settings › General › Language & Region.

### Changes

- **Liquid Glass Dock window** on macOS 26 and later: the window opened from the Dock icon now matches the menu bar popover (glass, rounded corners, lists that follow them).
- The device list in the menu bar popover now keeps the same margin at the bottom as on the sides, so its corners follow the popover's.
- **User guide** in `docs/guide/` (supported devices, settings, Nearcast, `abtp`, permissions, troubleshooting) and a shorter README, both in English and French, with new screenshots.
- **Diagnostic messages now go to the macOS unified log** (subsystem `io.github.msieurpafi.AirBattery`), so they can be read in Console or with `log show` even when the app was opened from Finder. Device names and addresses stay private. The Nearcast group ID is no longer printed.

## 1.8.0 — 2026-10-25 (pre-release)

### Changes

- **The app is called AirBattery Plus everywhere**: Bluetooth and local network permission prompts, settings, tips and the About panel, which now links to this fork and credits the original AirBattery by lihaoyun6.
- **The command line tool is now `abtp`** (was `airbattery`, the same name as the official app's tool). If you had installed it, install it again from Settings › Command Line Tool: the old `airbattery` link is removed when it belongs to AirBattery Plus, never when it belongs to the official app.
- **New app icon**: green to turquoise with a "+", so AirBattery Plus is easy to tell apart from the official app. On macOS 26 and later it is a Liquid Glass icon, with light, dark and tinted variants (upstream [#187](https://github.com/lihaoyun6/AirBattery/issues/187)).
- README rewritten for the fork, with credits to the original project and to the contributors whose work was ported.

### Note

- macOS may keep showing the old icon in Finder or the Dock for a while after the update: it caches app icons. It refreshes on its own, or after logging out.

## 1.7.4 — 2026-10-25 (pre-release)

### New

- **iPhone Duo icon** (model `iPhone19,4`), drawn after the one iOS shows on the phone itself. It used the generic iPhone icon.

### Note

- **New iPhone and no Apple Watch?** The Watch battery is read through the iPhone over USB or Wi-Fi, not Bluetooth. Plug the new iPhone into the Mac once, tap "Trust", and in Finder enable "Show this iPhone when on Wi-Fi".

## 1.7.3 — 2026-10-22 (pre-release)

### Fixes

- **Apple Watch reader (`comptest`) no longer crashes** (upstream [#198](https://github.com/lihaoyun6/AirBattery/issues/198)). It used an uninitialized connection whenever the iPhone was unreachable at that moment; the crashes happened several times a day.

### Changes

- **iPhone, iPad and Watch tools rebuilt** from current releases: libimobiledevice 1.4.0, libplist 2.8.0, libusbmuxd 2.1.1, libimobiledevice-glue 1.3.3 and OpenSSL 3.5.9 (LTS), instead of 2024 builds. They now run on macOS 12 like the app (the old ones required macOS 14). `scripts/build-libimobiledevice.sh` rebuilds them from pinned sources; license texts are in `libimobiledevice/licenses/`.

### Note

- After each update, macOS asks again whether AirBattery Plus may find devices on the local network: the permission is tied to the exact app binary. Allow it to keep Nearcast and iPhone/iPad over Wi-Fi working.

## 1.7.2 — 2026-10-21 (pre-release)

### New

- **Sort Devices** (Settings › Menu Bar & Dock): by name, lowest battery first or highest battery first, in the menu, the Dock icon and the widgets (upstream [#56](https://github.com/lihaoyun6/AirBattery/issues/56), [#188](https://github.com/lihaoyun6/AirBattery/issues/188)). An AirPods case stays with its earbuds, an iPhone with its Watch, an iPad with its Pencil. "Default" keeps the previous order.

### Changes

- The app now shows as **AirBattery Plus**, including in the widget gallery, where the fork and the official app used to appear as two identical "AirBattery" entries. Bundle IDs and settings are unchanged.

## 1.7.1 — 2026-10-21 (pre-release)

Fixes ported from callieskye's 1.6.5 community build ([callieskye/Air-Battery](https://github.com/callieskye/Air-Battery)), each one checked on macOS 27 first. Several of her changes didn't apply here and were left out; the details are in `docs/dev/UPSTREAM.md`.

### Fixes

- **No more crashes on unexpected tool output**: iPhone, iPad and Watch battery info, Bluetooth log lines and IOKit properties are now parsed safely instead of with forced unwraps.
- **`comptest` (Apple Watch battery) can no longer hang the app**: it is stopped after 15 s. It still crashes now and then inside the bundled libimobiledevice (upstream [#198](https://github.com/lihaoyun6/AirBattery/issues/198)), but without affecting AirBattery.
- **AirPods levels above 100%** (for example 125%) are clamped (upstream [#76](https://github.com/lihaoyun6/AirBattery/issues/76)).
- **Battery alerts**: one device waiting out its notification delay no longer silences the alerts of all the others (upstream [#78](https://github.com/lihaoyun6/AirBattery/issues/78)).
- **Mac battery percentage** now comes from the same source as the macOS menu bar. It could differ when a charge limit is set.
- **"Discover more BLE devices"**: connections are released after reading the battery, and devices without one are no longer retried every cycle. This kept some Macs awake (upstream [#132](https://github.com/lihaoyun6/AirBattery/issues/132)) and is a suspected cause of audio stutter (upstream [#178](https://github.com/lihaoyun6/AirBattery/issues/178)).
- **AirPods reported as "iPhone"** on macOS 26 now get their model name (upstream [#172](https://github.com/lihaoyun6/AirBattery/issues/172)).
- **Icons**: AirPods 4 with ANC (upstream [#166](https://github.com/lihaoyun6/AirBattery/issues/166)), AirPods Max (upstream [#204](https://github.com/lihaoyun6/AirBattery/issues/204), [#205](https://github.com/lihaoyun6/AirBattery/issues/205)) and MacBook Neo (upstream [#195](https://github.com/lihaoyun6/AirBattery/issues/195)).
- **Pinned menu bar items** now update their icon and keep their position across launches (upstream [#182](https://github.com/lihaoyun6/AirBattery/issues/182)).
- **Nearcast list**: the hover highlight clears when the cursor leaves (upstream [#159](https://github.com/lihaoyun6/AirBattery/issues/159)).

### Changes

- iPhone, iPad and Watch are scanned on their own 15 s timer, instead of launching two `idevice_id` processes every 5 s.

## 1.7.0 — 2026-10-21 (pre-release)

First release of the fork, based on the official 1.6.3 plus the upstream commits that were merged after it but never released.

### Fork identity

- Own bundle IDs (`io.github.msieurpafi.AirBattery`, `.widget`, `AirBatteryHelper`) and URL scheme (`airbattery-plus://`). The fork never shares settings, widget data or login items with the official app, and both can be installed side by side. The app file is named `AirBattery Plus.app` so that it doesn't overwrite the official `AirBattery.app` in Applications; inside, the app is still called AirBattery for now.
- Automatic updates (Sparkle) are disabled: the official update feed could otherwise replace the fork with the official app.
- Minimum macOS version raised from 11.0 to 12.0, the lowest that Xcode 27 can target.

### Fixes

- **Crash after waking from sleep** in the Bluetooth connection handler ("pointer being freed was not allocated", upstream [#215](https://github.com/lihaoyun6/AirBattery/issues/215), [#206](https://github.com/lihaoyun6/AirBattery/issues/206)). From upstream PR [#216](https://github.com/lihaoyun6/AirBattery/pull/216) by its author, cherry-picked.
- **Mach port `EXC_GUARD` errors twice per second** in the kernel log while the app runs (upstream [#207](https://github.com/lihaoyun6/AirBattery/issues/207)). The internal battery reader closed an IOKit service it never opened.
- **BLE peripherals already connected to the Mac** (for example a Logitech MX Anywhere 3) now show their battery. They no longer advertise, so the BLE scan never saw them.
- **`abt` command line tool** works again: since macOS 14 it was denied access to the widget's container. The app now also writes its data to `~/Library/Application Support/io.github.msieurpafi.AirBattery/`.
- Missing `ServiceManagement` import that broke the build with recent Xcode versions.

### Changes

- **No more automatic Bluetooth connections to nearby iPhones and iPads** (upstream [#89](https://github.com/lihaoyun6/AirBattery/issues/89), [#158](https://github.com/lihaoyun6/AirBattery/issues/158), [#169](https://github.com/lihaoyun6/AirBattery/issues/169)). With "Discover iOS devices via Bluetooth", you now pick your own devices once in Settings › Nearbility › Manage. From upstream PR [#214](https://github.com/lihaoyun6/AirBattery/pull/214) by Moyuin-aka, cherry-picked.
- **Lighter Bluetooth scanning**: one active BLE scan per refresh interval instead of every 29 s (about 9% of the time instead of 18%), and no scan at all when no feature needs it. A suspected contributor to Bluetooth audio stutter (upstream [#178](https://github.com/lihaoyun6/AirBattery/issues/178)).
- **Liquid Glass layout on macOS 26 and later**: device lists and toolbar buttons follow the popover's rounded corners, and the popover sits right under the menu bar.

### Also included (merged upstream after 1.6.3, never released)

- More reliable launch at login (upstream PR [#161](https://github.com/lihaoyun6/AirBattery/pull/161)).
- The app no longer gets terminated automatically by macOS (upstream PR [#162](https://github.com/lihaoyun6/AirBattery/pull/162)).
- Lower CPU use when reading Bluetooth logs (upstream PR [#163](https://github.com/lihaoyun6/AirBattery/pull/163)).
- Popup display fix (upstream PR [#177](https://github.com/lihaoyun6/AirBattery/pull/177)).

### Known limitations

- Not notarized, and signed with a development certificate: on first launch, allow the app in System Settings › Privacy & Security.
- Tested on a single Mac (MacBook Pro M1 Pro, macOS 27.0.1).
