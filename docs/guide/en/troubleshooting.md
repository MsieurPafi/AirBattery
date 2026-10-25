# Troubleshooting

[Guide](README.md) · [Français](../fr/troubleshooting.md)

**macOS won't open the app.**
It isn't notarized: allow it once in **System Settings › Privacy & Security › Open Anyway**.

**My iPhone, iPad or Apple Watch doesn't show up.**
Connect the iPhone or iPad to the Mac with a cable once and tap **Trust**, then enable **Show this iPhone when on Wi-Fi** in Finder. Keep it on the same network as the Mac, and check that AirBattery Plus has local network access (**System Settings › Privacy & Security › Local Network**). Details in [Supported devices](devices.md#iphone-ipad-and-apple-watch).

**My Apple Watch disappeared after I changed iPhone.**
The Watch is read through its iPhone. Connect the new iPhone with a cable once, trust the Mac and enable **Show this iPhone when on Wi-Fi**.

**My iPhone isn't on Wi-Fi.**
Use **Discover iOS devices via Bluetooth** and authorize it in **Manage** (iPhone and cellular iPad only, without the Watch).

**A Bluetooth accessory is missing.**
Turn on **Discover more BT devices**, then disconnect and reconnect the accessory. If it's still missing, try **Discover more BLE devices** (beta).

**A device that isn't mine asks to pair.**
It was found by **Discover more BLE devices**. Decline, then hide that device or add it to the blocklist.

**There's a ⚠️ next to a device.**
It hasn't reported for more than ten minutes: it may be off, asleep or out of range.

**A widget says the app is not running.**
Launch AirBattery Plus. If the widget still looks stuck: **Settings › Widget › Reload All Widgets**.

**After an update, the old icon still shows.**
macOS caches app icons. It refreshes on its own, or after you log out.

**Something else is wrong.**
Open an issue on [GitHub](https://github.com/MsieurPafi/AirBattery-Plus/issues) (in English or French) with your macOS version, the app version and, if you can, the app's logs (see [Permissions and privacy](permissions-privacy.md#logs)).
