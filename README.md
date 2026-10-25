# 
<p align="center">
<img src="./AirBattery/Assets.xcassets/AppIcon.appiconset/icon_128x128@2x.png" width="200" height="200" />
<h1 align="center">AirBattery Plus</h1>
<h3 align="center">Get battery usage of all devices on Mac and show them on the Dock / StatusBar / Widgets!<br><a href="./README_zh.md">[中文版本 (original app)]</a></h3> 
</p>

> [!NOTE]
> **AirBattery Plus is a maintained fork of [AirBattery](https://github.com/lihaoyun6/AirBattery) by [lihaoyun6](https://github.com/lihaoyun6).** The original has had no release since June 2025. This fork fixes crashes, keeps it working on macOS 26 and 27, and brings in fixes from the community. It uses its own bundle ID and URL scheme (`airbattery-plus://`), so it runs next to the official app without sharing its settings. Changes are listed in [CHANGELOG.md](./CHANGELOG.md). Licensed under AGPL-3.0, like the original.

## Screenshots
<p align="center">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="./img/preview_dark.png">
  <source media="(prefers-color-scheme: light)" srcset="./img/preview.png">
  <img alt="AirBattery Plus screenshots" src="./img/preview.png" width="840"/>
</picture>
</p>

## Installation and Usage
### System Requirements:
- macOS 12.0 and later  

### Installation:
1. Download the DMG from the [releases page](../../releases) (each release lists its SHA-256 checksum).
2. Open it and drag **AirBattery Plus** to Applications. To update, quit the app first and replace it: your settings are kept.
3. Builds are not notarized: on first launch, allow the app in **System Settings › Privacy & Security**.
4. After each install or update, macOS asks whether AirBattery Plus may find devices on the local network. Allow it, or Nearcast and iPhone / iPad over Wi-Fi won't work.

There are no automatic updates for now: watch the repository's releases to hear about new versions.

### Usage: 
- After AirBattery Plus is started, it will be displayed on both the Dock and the status bar by default, or only one of them (can be configured).  
- AirBattery Plus will automatically search for all devices supported by the **"Nearbility Engine"** without manual configuration.  
- Click the Dock icon / status bar icon, or add a widget to view the battery usage of your devices.  
- You can also use the **"Nearcast"** feature to check the battery usage of other Macs and their peripherals in the LAN at any time.  
- You can also change the status bar icon to a real-time battery icon in preferences, just like the one that comes with the system.  
- If necessary, you can hide certain devices in the Dock menu or status bar menu, and unhide them at any time.  
- **Command line tool:** install it from Settings (*Command Line Tool › Install*), then run `abtp` in a terminal to list all devices (`abtp --json`, `abtp --csv`, `abtp --nearcast`).  

## Q&A
**1. Why is my iPhone / iPad / Apple Watch not showing up?**
> Please make sure the iPhone / iPad has trusted this Mac ***(connect it to the Mac with a cable at least once and tap "Trust")***. Then just make sure it is on the same LAN as the Mac. In Finder, enabling *"Show this iPhone when on Wi-Fi"* lets AirBattery Plus read it without the cable.  

**2. Does my Apple Watch need to be pre-connected?**
> No, when AirBattery Plus detects a paired iPhone via Wi-Fi or USB, it will automatically read the battery data of the Apple Watch paired with it **(an iPhone discovered via Bluetooth does not give access to the Watch battery!)**. After switching to a new iPhone, connect the new one with a cable once, as in question 1.  

**3. Why do some device names have a ⚠️ symbol?**
> If this symbol appears, it means that the device has not updated its battery information for more than ten minutes, and may be offline or turned off.  

**4. My iPhone is not connected to Wi-Fi, can I get the battery info?**
> Enable **"Discover iOS devices via Bluetooth"** in Settings, then add your iPhone or cellular iPad under **"Authorized iOS Bluetooth Devices › Manage"**. AirBattery Plus only connects to devices you authorize there ***(iPhone or cellular iPad only)***.  

**5. Why does AirBattery Plus need Bluetooth permission?**
> AirBattery Plus needs Bluetooth to capture packets from peripheral devices in order to parse their battery information.  

## Credits
**[AirBattery](https://github.com/lihaoyun6/AirBattery)** by [@lihaoyun6](https://github.com/lihaoyun6) is the original app this fork is built on ([landing page](https://lihaoyun6.github.io/airbattery/)). Its author accepts donations:

<img src="./img/donate.png" width="250"/>

Contributions ported from the original project and its community:
- [#216](https://github.com/lihaoyun6/AirBattery/pull/216) by [@R0cketBean](https://github.com/R0cketBean): crash fix after waking from sleep.
- [#214](https://github.com/lihaoyun6/AirBattery/pull/214) by [@Moyuin-aka](https://github.com/Moyuin-aka): Bluetooth connections only to the iPhones and iPads you authorize.
- [#161](https://github.com/lihaoyun6/AirBattery/pull/161), [#162](https://github.com/lihaoyun6/AirBattery/pull/162), [#163](https://github.com/lihaoyun6/AirBattery/pull/163) by [@barkleesanders](https://github.com/barkleesanders) and [#177](https://github.com/lihaoyun6/AirBattery/pull/177) by [@leo1425](https://github.com/leo1425), merged upstream after 1.6.3 but never released.
- [@callieskye](https://github.com/callieskye) ([Air-Battery](https://github.com/callieskye/Air-Battery), 1.6.5 community build): many fixes, ported one by one (details in [docs/UPSTREAM.md](./docs/UPSTREAM.md)).

Libraries and tools:
- [libimobiledevice](https://github.com/libimobiledevice/libimobiledevice) @libimobiledevice: the iPhone / iPad / Watch tools are built from libimobiledevice 1.4.0 and its companion libraries by [`scripts/build-libimobiledevice.sh`](./scripts/build-libimobiledevice.sh). Their licenses are in `AirBattery/libimobiledevice/licenses/`.
- [comptest](https://gist.github.com/nikias/ebc6e975dc908f3741af0f789c5b1088) @nikias: the Apple Watch reader is built from this source, with a crash fix ([`scripts/libimobiledevice/comptest.c`](./scripts/libimobiledevice/comptest.c)).
- [MultipeerKit](https://github.com/insidegui/MultipeerKit) @insidegui: symmetric multi-end communication within the LAN (Nearcast).
- [swift-argument-parser](https://github.com/apple/swift-argument-parser) @apple: the `abtp` command line tool.

The original project notes that some of its code was generated or refactored by [ChatGPT](https://chat.openai.com).

## License
[AGPL-3.0](./LICENSE), like the original. If you redistribute AirBattery Plus or a modified version, its source code must be available under the same license.
