# Changelog

Changes in this fork compared with the official [AirBattery](https://github.com/lihaoyun6/AirBattery) releases.

## Unreleased

### Changes

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

Fixes ported from callieskye's 1.6.5 community build ([callieskye/Air-Battery](https://github.com/callieskye/Air-Battery)), each one checked on macOS 27 first. Several of her changes didn't apply here and were left out; the details are in `docs/UPSTREAM.md`.

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
