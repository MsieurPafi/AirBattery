# Supported devices

[Guide](README.md) · [Français](../fr/devices.md)

AirBattery Plus reads batteries through several sources. Each one can be turned on or off in **Settings › Nearbility**.

## This Mac

The built-in battery of a MacBook, as shown in the macOS menu bar. Always on.

## iPhone, iPad and Apple Watch

Read with the same protocol Finder uses to sync an iPhone, over USB or Wi-Fi (**Discover iOS devices via Network**).

1. Connect the iPhone or iPad to the Mac with a cable once, unlock it and tap **Trust**.
2. In Finder, select the device and check **Show this iPhone when on Wi-Fi**, then click **Apply**.
3. Keep the device on the same network as the Mac. It then shows up without the cable.

The **Apple Watch** is read through its iPhone: it shows up once its iPhone is trusted, with no extra step. After switching to a new iPhone, repeat steps 1 and 2 with the new one, or the Watch disappears.

### iPhone and iPad over Bluetooth

For an iPhone or cellular iPad that isn't on the Mac's network (**Discover iOS devices via Bluetooth**):

1. Turn the option on, then click **Authorized iOS Bluetooth Devices › Manage**.
2. Open **Personal Hotspot** on the iPhone and bring it close to the Mac.
3. Select your device in the list of nearby Apple devices and authorize it. iOS may show a pairing request once.

AirBattery Plus only connects to devices you authorize there. An iPhone found over Bluetooth doesn't give access to its Apple Watch.

### Apple Pencil

**Apple Pencil from your iPad** reads the Pencil's battery through the iPad. It's a beta feature: finding the Pencil can take 10 minutes or more the first time, and it may drain the iPad's battery faster.

## AirPods and Beats

Read from the Bluetooth messages they send when the case is opened or the earbuds are in use: case, left and right earbuds. When both earbuds are within 5% of each other they are shown as one device (**Earbud Merging Threshold**, Settings › Nearbility).

## Magic Keyboard, Mouse, Trackpad and other Bluetooth accessories

**Discover BT and BLE devices** reads the accessories macOS knows the battery of: Apple's Magic accessories, and many keyboards, mice and headphones.

If one of yours is missing:

- **Discover more BT devices** reads more third-party Bluetooth devices. Their battery updates when they reconnect to the Mac or when the Mac wakes up.
- **Discover more BLE devices** tries to read the battery of any Bluetooth Low Energy device nearby (for example a Logitech MX mouse). It's a beta feature. If a device that isn't yours shows a pairing request, hide it (see [Using the app](using-the-app.md#hide-a-device)).

## Other Macs

With [Nearcast](nearcast.md), the batteries of your other Macs, and of their own devices, show up too.

## Refresh

Batteries are read again every **Refresh Interval** (1 minute by default, Settings › Nearbility). A device that hasn't reported for more than ten minutes gets a ⚠️ next to its name: it may be off or out of range.
