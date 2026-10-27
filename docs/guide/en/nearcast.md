# Nearcast

[Guide](README.md) · [Français](../fr/nearcast.md)

Nearcast shares battery levels between your Macs on the same local network. Each Mac shows the batteries of the others, and of their devices, in a section of its own list. Battery alerts are also forwarded to the other Macs.

Every Mac in a group needs AirBattery Plus with Nearcast v2 (version 1.14 or later). It can't talk to the original AirBattery, nor to the AirBattery Mobile iOS app.

## Set it up

1. On the first Mac, open **Settings › Nearcast** and click **+** next to **Group ID** to create an ID.
2. Copy it with the copy button, and type or paste it into **Group ID** on each of your other Macs.
3. Turn on **Enable Nearcast** on every Mac.

A Group ID looks like `nc2-` followed by 26 letters and digits. Case, spaces and dashes don't matter when you type it. It can only be changed while Nearcast is off. ↻ creates a new one: you then need to enter it again on your other Macs.

## Coming from an earlier version

Nearcast switched to a new, more secure protocol. Group IDs from before (`nc-` followed by 20 characters) no longer work: after the update, Nearcast is turned off and a notification says so. Create a new Group ID and enter it on all your Macs.

## Good to know

- Everything sent over Nearcast is encrypted and authenticated with keys derived from the Group ID, and only Macs that know it are let in. Don't share it with anyone outside your own Macs.
- Nearcast only works between Macs on the same network.
- Every Mac needs local network access (see [Permissions and privacy](permissions-privacy.md)).
- Don't put too many Macs in one group: each one talks to all the others.
