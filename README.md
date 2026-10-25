# 
<p align="center">
<img src="./AirBattery/Assets.xcassets/AppIcon.appiconset/icon_128x128@2x.png" width="200" height="200" />
<h1 align="center">AirBattery Plus</h1>
<h3 align="center">The battery of all your devices, in your Mac's menu bar, Dock and widgets.<br><a href="./README.fr.md">[Français]</a> <a href="./README_zh.md">[中文版本 (original app)]</a></h3>
</p>

> [!NOTE]
> **AirBattery Plus is a maintained fork of [AirBattery](https://github.com/lihaoyun6/AirBattery) by [lihaoyun6](https://github.com/lihaoyun6).** The original has had no release since June 2025. This fork fixes crashes, keeps it working on macOS 26 and 27, and brings in fixes from the community. It runs next to the official app without sharing its settings.

<p align="center">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="./img/preview_dark.png">
  <source media="(prefers-color-scheme: light)" srcset="./img/preview.png">
  <img alt="AirBattery Plus screenshots" src="./img/preview.png" width="840"/>
</picture>
</p>

## Features

- **This Mac**, **iPhone, iPad and Apple Watch** (over USB, Wi-Fi or Bluetooth), **Apple Pencil**, **AirPods and Beats**, **Magic Keyboard, Mouse and Trackpad** and many other **Bluetooth accessories**.
- In the **menu bar**, the **Dock** or **widgets**, sorted the way you like, with pinned devices in the menu bar.
- **Battery alerts** when a device runs low or finishes charging.
- **Nearcast**: the batteries of your other Macs and their devices, encrypted on your local network.
- **`abtp`** command line tool, with JSON and CSV output.
- Liquid Glass design on macOS 26 and later. Nothing is sent over the internet.

## Install

macOS 12 or later. Download the DMG from the [releases page](../../releases), open it and drag **AirBattery Plus** to Applications. The app is not notarized: on first launch, allow it in **System Settings › Privacy & Security**. Step by step: [Getting started](docs/guide/en/getting-started.md).

## Documentation

- [User guide](docs/guide/en/README.md): supported devices, settings, Nearcast, `abtp`, troubleshooting.
- [Changelog](CHANGELOG.md).
- [Contributing](CONTRIBUTING.md): build the app, translate it, report a bug.

## Credits
**[AirBattery](https://github.com/lihaoyun6/AirBattery)** by [@lihaoyun6](https://github.com/lihaoyun6) is the original app this fork is built on ([landing page](https://lihaoyun6.github.io/airbattery/)). Its author accepts donations:

<img src="./img/donate.png" width="250"/>

Contributions ported from the original project and its community:
- [#216](https://github.com/lihaoyun6/AirBattery/pull/216) by [@R0cketBean](https://github.com/R0cketBean): crash fix after waking from sleep.
- [#214](https://github.com/lihaoyun6/AirBattery/pull/214) by [@Moyuin-aka](https://github.com/Moyuin-aka): Bluetooth connections only to the iPhones and iPads you authorize.
- [#161](https://github.com/lihaoyun6/AirBattery/pull/161), [#162](https://github.com/lihaoyun6/AirBattery/pull/162), [#163](https://github.com/lihaoyun6/AirBattery/pull/163) by [@barkleesanders](https://github.com/barkleesanders) and [#177](https://github.com/lihaoyun6/AirBattery/pull/177) by [@leo1425](https://github.com/leo1425), merged upstream after 1.6.3 but never released.
- [@callieskye](https://github.com/callieskye) ([Air-Battery](https://github.com/callieskye/Air-Battery), 1.6.5 community build): many fixes, ported one by one (details in [docs/dev/UPSTREAM.md](./docs/dev/UPSTREAM.md)).

Libraries and tools:
- [libimobiledevice](https://github.com/libimobiledevice/libimobiledevice) @libimobiledevice: the iPhone / iPad / Watch tools are built from libimobiledevice 1.4.0 and its companion libraries by [`scripts/build-libimobiledevice.sh`](./scripts/build-libimobiledevice.sh). Their licenses are in `AirBattery/libimobiledevice/licenses/`.
- [comptest](https://gist.github.com/nikias/ebc6e975dc908f3741af0f789c5b1088) @nikias: the Apple Watch reader is built from this source, with a crash fix ([`scripts/libimobiledevice/comptest.c`](./scripts/libimobiledevice/comptest.c)).
- [MultipeerKit](https://github.com/insidegui/MultipeerKit) @insidegui: symmetric multi-end communication within the LAN (Nearcast).
- [swift-argument-parser](https://github.com/apple/swift-argument-parser) @apple: the `abtp` command line tool.

The original project notes that some of its code was generated or refactored by [ChatGPT](https://chat.openai.com).

## License
[AGPL-3.0](./LICENSE), like the original. If you redistribute AirBattery Plus or a modified version, its source code must be available under the same license.
