# Settings

[Guide](README.md) · [Français](../fr/settings.md)

Open the settings with ⚙︎ at the top of the device list. Default values are in brackets.

## General

- **Launch at Login** [off].
- **Show AirBattery Plus**: Dock, Menu Bar, Both or None [Menu Bar]. See [Using the app](using-the-app.md#where-it-shows).
- **Command Line Tool**: installs or removes `abtp` ([Command line](command-line.md)).

## Menu Bar & Dock

Menu bar:

- **Dynamic Battery Icon** [on]: the menu bar icon shows this Mac's battery.
- **Colorful Battery Icon**, **Battery Icon Style** (macOS or iOS), **Show Percentage** (hidden, inside or outside the icon).
- **Remove Offline Device** [after 20 min]: devices that stop reporting leave the list.
- **Sort Devices** [Default]: by name, lowest or highest battery first. Also applies to the Dock icon and the widgets.
- **Hide percentage when above** [90%]: next to the battery icons, the percentage is hidden above this level.

Dock:

- **Appearance**: automatic, light or dark.
- **Built-in Battery Style**: shows this Mac's battery in the Dock icon as an icon or a percentage, or hides it.
- **Carousel Mode** [on]: the Dock icon cycles through all your devices.

## Nearbility

Where batteries are read from (details in [Supported devices](devices.md)):

- **Discover iOS devices via Network** [on]: iPhone, iPad, Apple Watch over USB or Wi-Fi.
- **Discover iOS devices via Bluetooth** [off], with **Authorized iOS Bluetooth Devices › Manage**.
- **Discover BT and BLE devices** [on], **Discover more BT devices** [on], **Discover more BLE devices** [off, beta].
- **Apple Pencil from your iPad** [off, beta].
- **Refresh Interval (min)** [1]: how often batteries are read. Relaunch the app to apply a change.
- **Earbud Merging Threshold** [5]: below this difference, left and right earbuds show as one device.

## Nearcast

Enable Nearcast and its Group ID: see [Nearcast](nearcast.md). **Peer Info** shows this Mac's ID in the group.

## Widget

- **Reverse Device List**.
- **Refresh Interval**: same as Nearbility [default], or left to macOS. With *Same as Nearbility*, the app asks macOS to reload the widgets at each Nearbility **Refresh Interval** (every minute by default). There is no separate interval for the widgets.
- **Single Device Widget** (macOS 12 and 13 only).
- **Reload All Widgets**: if a widget looks stuck.

## Blocklist

Devices listed here are hidden. With **Allowlist Mode**, the list works the other way round: only the devices listed are shown.
