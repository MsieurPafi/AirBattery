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
3. Le widget relit ce fichier.
4. L'app principale écrit aussi une copie pour les outils locaux dans `~/Library/Application Support/<bundle-id-app>/` : `data.json` (mêmes données) et `nearcast.json` (appareils Nearcast déjà filtrés comme dans l'app). Raison : depuis macOS 14, un processus lancé depuis un terminal ne peut plus lire le container sandboxé d'une autre app. `abt` ouvre `<schéma>://writedata`, attend 500 ms, puis lit cette copie.
5. Données Nearcast reçues : `…/Documents/NearcastData/*.json` (container du widget).

## Identifiants codés en dur

Depuis `4737267` (D-006), plus aucun identifiant n'est codé en dur dans le code Swift :

- bundle IDs : réglage de build `APP_ID_PREFIX` (niveau projet) → `$(APP_ID_PREFIX).AirBattery`, `.AirBattery.widget`, `.AirBatteryHelper` ;
- côté Swift : `Shared/AppIdentifiers.swift` (dossier synchronisé, compilé dans les 4 targets) ;
- schéma d'URL `airbattery-plus` : `AirBattery/Info.plist` + `AppIdentifiers.urlScheme`. Utilisé par `abt` (`writedata`) et les widgets (`reloadwingets`, sic).

Les crédits (`*.lproj/Credits.rtf`) et `wificonnection.c` mentionnent toujours lihaoyun6 : c'est voulu (AGPL, auteur d'origine).

## Mises à jour (Sparkle)

Désactivées (D-004, `994dca4`) : flag `updatesEnabled = false` dans `Supports/Sparkle.swift`. L'updater n'est jamais démarré, l'UI est masquée, `Info.plist` n'a plus de `SUFeedURL` ni de `SUPublicEDKey`.
