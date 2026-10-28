# Nearcast

[Guide](README.md) · [Français](../fr/nearcast.md)

Nearcast shares battery levels between your Macs on the same local network. Each Mac shows the batteries of the others, and of their devices, in a section of its own list. Battery alerts are also forwarded to the other Macs.

Every Mac in a group needs AirBattery Plus with Nearcast v2 (version 1.14 or later). It can't talk to the original AirBattery, nor to the AirBattery Mobile iOS app.

## Set it up

1. On the first Mac, open **Settings › Nearcast** and click **Create a Group**. Nearcast turns on, and the group code is shown (it starts with `nc2-`).
2. Send the code to your other Macs with the share button (AirDrop, Messages…) or the copy button.
3. On each other Mac, open **Settings › Nearcast**, click **Join a Group**, then **Paste** (a copied code is filled in automatically), and **Join**.

Once in a group, **Settings › Nearcast** shows the code (click the eye to see it all), the **Connected Macs**, and a switch to pause Nearcast. **Leave Group** turns Nearcast off on this Mac and forgets the code.

## Coming from an earlier version

Nearcast switched to a new, more secure protocol. Group IDs from before (`nc-` followed by 20 characters) no longer work: after the update, Nearcast is turned off and a notification says so. Create a new group on one Mac and join it from the others.

## Good to know

- Everything sent over Nearcast is encrypted and authenticated with keys derived from the group code, and only Macs that know it are let in. Don't share it with anyone outside your own Macs.
- Nearcast only works between Macs on the same network.
- Every Mac needs local network access (see [Permissions and privacy](permissions-privacy.md)). If the macOS firewall is on, it asks the first time another Mac connects whether AirBattery Plus may accept incoming connections: click **Allow**.
- Don't put too many Macs in one group: each one talks to all the others.
