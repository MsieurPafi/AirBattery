# Architecture

Carte du code, à enrichir au fil des sessions. Point de départ : relevé du 19/10/2026 sur `134e02f` (voir aussi `CLAUDE.md` §4, à la racine du dossier de travail).

## Targets

| Target | Dossier | Rôle | Sandbox |
| --- | --- | --- | --- |
| AirBattery | `AirBattery/` | App principale (SwiftUI + AppKit) | non |
| widget | `widget/` | Extension WidgetKit (3 tailles) | oui |
| AirBatteryHelper | `AirBatteryHelper/` | Lancement au login | |
| abt | `abt/` | CLI | |

Réglages : `MACOSX_DEPLOYMENT_TARGET = 11.0`, `SWIFT_VERSION = 5.0`, hardened runtime. Dépendances SPM : Sparkle 2.6.2, MultipeerKit 0.4.0, swift-argument-parser 1.5.0.

## Sources de données (`AirBattery/BatteryInfo/`)

| Fichier | Lit | Mécanisme |
| --- | --- | --- |
| `InternalBattery.swift` | Batterie du Mac | IOKit `AppleSmartBattery` + `IOKit.ps` |
| `MagicBattery.swift` | Magic + autres BT | IOKit + `system_profiler SPBluetoothDataType -json` |
| `BTDBattery.swift` | BT tiers | logs `bluetoothd` via `log show` (`Supports/logReader.sh`) |
| `BLEBattery.swift` | AirPods/Beats, BLE GATT | CoreBluetooth (manufacturer data `0x004C`, service `180F`) |
| `IDeviceBattery.swift` | iPhone/iPad/Watch/Pencil | binaires libimobiledevice embarqués |

Nearcast : `Supports/Multipeer.swift` (MultipeerKit, `airbattery-nc`, AES-GCM + HKDF-SHA256 du Group ID).

## Flux de données

1. Chaque source appelle `AirBatteryModel.updateDevice(_:)`.
2. `AirBatteryModel.writeData()` écrit `~/Library/Containers/<bundle-id-widget>/Data/Documents/data.json`.
3. Le widget relit ce fichier ; `abt` ouvre `<schéma>://writedata`, attend 500 ms, relit le fichier.
4. Données Nearcast : `…/Documents/NearcastData/*.json`.

## Identifiants codés en dur

_(à mettre à jour après la centralisation, cf. D-002)_
