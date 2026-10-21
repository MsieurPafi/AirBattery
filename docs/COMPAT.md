# Compatibilité

Matrice version de macOS × source de données × état. Chaque case renvoie à une preuve (entrée de `JOURNAL.md`, échantillon dans `samples/`).

Légende : ✅ vérifié sur appareil réel · ⚠️ partiel / dégradé · ❌ cassé · ❔ non testé

## Environnements de test

| Machine | macOS (build) | Xcode | Notes |
| --- | --- | --- | --- |
| MacBook Pro M1 Pro (Côme) | 27.0.1 (26A434) | 27.1 (27A9275) | Swift 6.4, arm64 |

## Matrice

| Source | Fichier | macOS 27.0.1 |
| --- | --- | --- |
| Batterie interne | `InternalBattery.swift` | ❔ |
| Magic / BT via IOKit + `system_profiler` | `MagicBattery.swift` | ❔ |
| BT tiers via logs `bluetoothd` | `BTDBattery.swift` | ❔ |
| AirPods / Beats (BLE) | `BLEBattery.swift` | ❔ |
| BLE générique GATT 180F | `BLEBattery.swift` | ❔ |
| iPhone / iPad (libimobiledevice) | `IDeviceBattery.swift` | ❔ |
| Apple Watch (`comptest`) | `IDeviceBattery.swift` | ❔ |
| Apple Pencil | `IDeviceBattery.swift` | ❔ |
| Nearcast | `Multipeer.swift` | ❔ |
| Widget | `widget/` | ❔ |
| CLI `abt` | `abt/` | ❔ |

## Build

_(à remplir au premier build : erreurs, warnings significatifs, dépréciations d'API)_
