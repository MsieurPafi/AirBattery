# Getting started

[Guide](README.md) · [Français](../fr/getting-started.md)

## Requirements

- macOS 12 or later. Tested on macOS 27 (Apple Silicon).
- AirBattery Plus can be installed next to the official AirBattery: they don't share settings, widgets or command line tool.

## Install

1. Download the DMG from the [releases page](https://github.com/MsieurPafi/AirBattery-Plus/releases). Each release lists the file's SHA-256 checksum.
2. Open the DMG and drag **AirBattery Plus** to Applications.
3. The app is not notarized by Apple: on first launch, macOS blocks it. Open **System Settings › Privacy & Security**, scroll down and click **Open Anyway** next to AirBattery Plus.

## Update

AirBattery Plus finds new versions itself. On its second launch, it asks whether to check for updates automatically; you can change this later in **Settings › General › Update**, or check now with **Check for Updates…** at the bottom of the settings. Updates come from this repository's releases on GitHub, and are installed only if they carry the project's signature. Then macOS asks again for local network access (step 3 below).

Versions up to 1.10.0 can't update themselves. To update by hand:

1. Quit AirBattery Plus (menu bar icon › ⓧ).
2. Install the new version as above, replacing the old one. Your settings are kept.
3. macOS asks again whether AirBattery Plus may find devices on the local network: allow it. The permission is tied to the exact app version.

macOS may keep showing the old app icon for a while after an update: it caches icons, and refreshes them on its own or after you log out.

## First launch

AirBattery Plus asks for a few permissions. Why each one is needed is explained in [Permissions and privacy](permissions-privacy.md).

- **Bluetooth**: to read AirPods, Beats and Bluetooth accessories.
- **Local network**: for iPhone, iPad and Apple Watch over Wi-Fi, and for Nearcast.
- **Notifications**: for battery alerts.

By default the app shows in the menu bar. Click its icon to see your devices. To show it in the Dock too, or only there, see **Settings › General › Show AirBattery Plus**.

Most devices show up on their own. An iPhone, iPad or Apple Watch needs one extra step: see [Supported devices](devices.md#iphone-ipad-and-apple-watch).

## Language

AirBattery Plus is in English and French (and in Chinese, with an older translation). It follows the languages set in **System Settings › General › Language & Region**, and falls back to English. To use another language for this app only, add it under **Applications** in the same pane.
