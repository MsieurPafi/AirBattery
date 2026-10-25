# Permissions and privacy

[Guide](README.md)

## What the app asks for

| Permission | Why | Without it |
| --- | --- | --- |
| Bluetooth | Reads AirPods, Beats and Bluetooth accessories, and iPhones you authorize over Bluetooth | Only this Mac, iPhone/iPad/Watch over USB or Wi-Fi, and Nearcast |
| Local network | iPhone, iPad and Apple Watch over Wi-Fi; Nearcast | No Wi-Fi devices, no Nearcast. macOS asks again after each update |
| Notifications | Battery alerts | No alerts |
| Administrator password | Only to install or remove the `abtp` command, which writes in `/usr/local/bin` | No `abtp` |

The app is not sandboxed, like the original AirBattery: it runs the tools that read iPhones, iPads and Watches, and reads Bluetooth information from macOS.

## What stays on your Mac

- Battery levels and device names are stored on your Mac only, for the widgets and `abtp`.
- AirBattery Plus sends nothing over the internet: no analytics, no automatic updates.
- With Nearcast, levels are shared with your other Macs on the local network, encrypted with your Group ID.

## Logs

The app writes diagnostic messages to the macOS unified log, with device names and addresses kept private. To read them, for example to report a bug:

```bash
/usr/bin/log show --last 1h --predicate 'subsystem == "io.github.msieurpafi.AirBattery"'
```
