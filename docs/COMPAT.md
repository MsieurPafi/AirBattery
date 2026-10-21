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
| iPhone / iPad (libimobiledevice) | `IDeviceBattery.swift` | ❔ binaires embarqués exécutables (`idevice_id --version`), aucun appareil testé |
| Apple Watch (`comptest`) | `IDeviceBattery.swift` | ❔ |
| Apple Pencil | `IDeviceBattery.swift` | ❔ |
| Nearcast | `Multipeer.swift` | ❔ |
| Widget | `widget/` | ⚠️ enregistré par PlugInKit avec la signature gratuite, affichage non testé |
| CLI `abt` | `abt/` | ❔ |

## Build

### 2026-10-21 — Xcode 27.1 (27A9275), SDK macOS 27, `main` @ `134e02f`

Commande de référence :

```
xcodebuild -project AirBattery.xcodeproj -scheme AirBattery -configuration Debug \
  -derivedDataPath build/DerivedData build
```

**Erreurs, dans l'ordre où elles apparaissent :**

| # | Erreur | Cible | Traitement |
| --- | --- | --- | --- |
| 1 | `No signing certificate "Mac Development" found: No "Mac Development" signing certificate matching team ID "L4T783637F" with a private key was found.` | les 4 | attendu (équipe de l'auteur) ; équipe remplacée par `PCH7VR8GPS` (`4737267`), certificat encore absent (W-002) |
| 2 | `The macOS deployment target 'MACOSX_DEPLOYMENT_TARGET' is set to 11.0, but the range of supported deployment target versions is 12.0 to 27.0.x.` | les 4 | cible passée à 12.0 dans le projet (D-007, `138b433`) |
| 3 | `AirBatteryApp.swift:522:21: error: cannot find 'SMAppService' in scope` (et `:524`, `:532` pour `SMLoginItemSetEnabled`) | AirBattery | corrigé : `import ServiceManagement` manquant (`774c380`) |

Avec `CODE_SIGNING_ALLOWED=NO MACOSX_DEPLOYMENT_TARGET=12.0` et le correctif n° 3 : **BUILD SUCCEEDED** (schémas `AirBattery` et `abt`).

**Warnings significatifs :**
- `Supports/Supports.swift:426:68` : `'kIOMasterPortDefault' was deprecated in macOS 12.0: renamed to 'kIOMainPortDefault'`.
- `widget/BatteryWidget.swift:123`, `widget/BatteryWidget2.swift:353`, `widget/BatteryWidget3.swift:16` : `switch must be exhaustive` (probablement un nouveau cas de `WidgetFamily` dans le SDK 27, à vérifier).
- `appintentsmetadataprocessor` : `Metadata extraction skipped, no AppIntents.framework dependency found` (sans conséquence a priori).

Logs complets : `build/logs/` (non versionnés).

### 2026-10-21 — Build signé (équipe personnelle gratuite)

`xcodebuild -project AirBattery.xcodeproj -scheme AirBattery -configuration Debug -derivedDataPath build/DerivedData build` → **BUILD SUCCEEDED**, sans `-allowProvisioningUpdates` ni profil embarqué.

| Bundle | Identifier | Équipe | Entitlements (Debug) |
| --- | --- | --- | --- |
| `AirBattery.app` | `io.github.msieurpafi.AirBattery` | `PCH7VR8GPS` | `get-task-allow` |
| `AirBatteryWidgetExtension.appex` | `io.github.msieurpafi.AirBattery.widget` | `PCH7VR8GPS` | `app-sandbox`, `get-task-allow` |
| `AirBatteryHelper.app` | `io.github.msieurpafi.AirBatteryHelper` | `PCH7VR8GPS` | `app-sandbox`, `files.user-selected.read-only`, `get-task-allow` |
| `Sparkle.framework`, `Resources/abt` | — | `PCH7VR8GPS` | — |
| `Resources/libimobiledevice/{bin,lib}/*` | — | aucune (ad hoc, `linker-signed`, binaires de l'auteur) | — |

- Hardened runtime actif partout ; `codesign --verify --deep --strict` OK.
- `spctl -a -vv` → `rejected` (signature de développement, non notarisée) : attendu, sans effet sur un build local qui n'a pas d'attribut de quarantaine.
- `pluginkit -m -v -A -i io.github.msieurpafi.AirBattery.widget` : extension enregistrée depuis `build/DerivedData/…`, et le container `~/Library/Containers/io.github.msieurpafi.AirBattery.widget` a été créé. **L'enregistrement du widget fonctionne avec une signature gratuite** ; reste à vérifier qu'il s'affiche et lit les données.
- `libimobiledevice/bin/idevice_id --version` → `idevice_id 1.3.0-210-g73b6fd1` : les binaires embarqués s'exécutent sur macOS 27.0.1.
