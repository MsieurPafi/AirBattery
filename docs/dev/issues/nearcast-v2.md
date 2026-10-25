# Nearcast v2: a secure protocol

Nearcast shares battery levels between Macs on the same local network, encrypted with a key derived from the group ID. The audit of 1.9.0 (`docs/dev/AUDIT-2026-10-25.md`, priority 2) found that the current protocol isn't secure enough. It only matters when Nearcast is turned on (it's off by default).

## Problems

1. **Weak key**: only 8 characters of the 23-character group ID are secret (~47.6 bits). The first 15 are the salt, and are sent in clear in every message (`id`). The key is derived with a single, fast HKDF, so a captured message can be cracked offline.
2. **No authentication of the envelope**: `sender` and `command` travel in clear and aren't bound to the encrypted content. `sender` was used as a file name (path traversal, fixed by a stopgap in #36).
3. **No replay protection**: a captured message can be replayed later.
4. **Transport**: MultipeerKit accepts every invitation, without transport encryption.
5. **Privacy**: the Mac's hardware UUID is sent in clear as the sender.

Stopgaps already shipped (#36): safe file names, atomic writes, no remote Bluetooth connect, no echo of unknown commands.

## Proposal

- Group secret of at least 128 bits (longer group ID).
- HKDF with a fixed protocol salt and `info`; group tag computed with HMAC instead of a clear prefix.
- `sender`, `command` and a counter or timestamp as AES-GCM additional data (AAD); reject replays.
- MultipeerKit encryption required; reject peers that never sent a valid message.
- A random per-install sender ID, inside the ciphertext.
- A protocol version field.

## Compatibility

v2 can't talk to v1: the official AirBattery-Mobile iOS app and Macs that aren't updated would stop seeing each other. Options to decide:
- clean break, with a note in the release;
- read-only v1 support for a transition period;
- a setting to keep v1, with a warning.
