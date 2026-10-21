# Changelog

Changes in this fork compared with the official [AirBattery](https://github.com/lihaoyun6/AirBattery) releases.

## 1.7.0 — 2026-10-21 (pre-release)

First release of the fork, based on the official 1.6.3 plus the upstream commits that were merged after it but never released.

### Fork identity

- Own bundle IDs (`io.github.msieurpafi.AirBattery`, `.widget`, `AirBatteryHelper`) and URL scheme (`airbattery-plus://`). The fork never shares settings, widget data or login items with the official app, and both can be installed side by side. The app file is named `AirBattery Plus.app` so that it doesn't overwrite the official `AirBattery.app` in Applications; inside, the app is still called AirBattery for now.
- Automatic updates (Sparkle) are disabled: the official update feed could otherwise replace the fork with the official app.
- Minimum macOS version raised from 11.0 to 12.0, the lowest that Xcode 27 can target.

### Fixes

- **Crash after waking from sleep** in the Bluetooth connection handler ("pointer being freed was not allocated", upstream #215, #206). From upstream PR #216 by its author, cherry-picked.
- **Mach port `EXC_GUARD` errors twice per second** in the kernel log while the app runs (upstream #207). The internal battery reader closed an IOKit service it never opened.
- **BLE peripherals already connected to the Mac** (for example a Logitech MX Anywhere 3) now show their battery. They no longer advertise, so the BLE scan never saw them.
- **`abt` command line tool** works again: since macOS 14 it was denied access to the widget's container. The app now also writes its data to `~/Library/Application Support/io.github.msieurpafi.AirBattery/`.
- Missing `ServiceManagement` import that broke the build with recent Xcode versions.

### Changes

- **No more automatic Bluetooth connections to nearby iPhones and iPads** (upstream #89, #158, #169). With "Discover iOS devices via Bluetooth", you now pick your own devices once in Settings › Nearbility › Manage. From upstream PR #214 by Moyuin-aka, cherry-picked.
- **Lighter Bluetooth scanning**: one active BLE scan per refresh interval instead of every 29 s (about 9% of the time instead of 18%), and no scan at all when no feature needs it. A suspected contributor to Bluetooth audio stutter (upstream #178).
- **Liquid Glass layout on macOS 26 and later**: device lists and toolbar buttons follow the popover's rounded corners, and the popover sits right under the menu bar.

### Also included (merged upstream after 1.6.3, never released)

- More reliable launch at login (upstream PR #161).
- The app no longer gets terminated automatically by macOS (upstream PR #162).
- Lower CPU use when reading Bluetooth logs (upstream PR #163).
- Popup display fix (upstream PR #177).

### Known limitations

- Not notarized, and signed with a development certificate: on first launch, allow the app in System Settings › Privacy & Security.
- Tested on a single Mac (MacBook Pro M1 Pro, macOS 27.0.1).
