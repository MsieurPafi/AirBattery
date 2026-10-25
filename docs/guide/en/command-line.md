# Command line: `abtp`

[Guide](README.md) · [Français](../fr/command-line.md)

`abtp` prints the batteries AirBattery Plus knows about in a terminal, for scripts or a status bar tool. The app must be running.

## Install

**Settings › General › Command Line Tool › Install**, then enter your administrator password: it creates the link `/usr/local/bin/abtp`. **Uninstall** removes it.

Versions up to 1.7.4 installed the tool as `airbattery`, the same name as the official app's tool. Installing `abtp` removes that old link when it belongs to AirBattery Plus, never when it belongs to the official app.

## Use

```bash
abtp              # table of devices, level and status
abtp --json       # JSON, for scripts
abtp --csv        # CSV
abtp --nearcast   # include the devices of your other Macs (Nearcast)
abtp --help
```

In the table, the status column shows `+` while a device is charging or plugged in, `=` when charging is paused, and `-` on battery.
