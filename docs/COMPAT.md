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
| Batterie interne | `InternalBattery.swift` | ✅ (2026-10-21) |
| Magic / BT via IOKit + `system_profiler` | `MagicBattery.swift` | ❔ aucun appareil Magic testé |
| Périphériques BLE déjà connectés (GATT `180F`) | `BLEBattery.swift` (`readConnectedPeripherals`) | ✅ Logitech MX Anywhere 3 : même niveau que Réglages › Bluetooth (2026-10-21, `fix/ble-hid-battery`) |
| BT tiers via logs `bluetoothd` | `BTDBattery.swift` | ❔ |
| AirPods / Beats (BLE) | `BLEBattery.swift` | ✅ AirPods Pro, écouteurs + boîtier (2026-10-21). Avec le scan d'une fois par minute (D-011) : visibles en 45–60 s à l'ouverture du boîtier, stables en utilisation, invisibles boîtier fermé (comme avant) |
| BLE générique GATT 180F | `BLEBattery.swift` | ❔ |
| iPhone / iPad (libimobiledevice) | `IDeviceBattery.swift` | ✅ iPhone 17 en USB (2026-10-21) |
| iPhone / iPad via BLE (liste autorisée, D-009) | `BLEBattery.swift` | ✅ iPhone 17 autorisé via « Manage » › « Pair… » ; Apple Watch refusée avec un message (2026-10-21) |
| Apple Watch (`comptest`) | `IDeviceBattery.swift` | ✅ via l'iPhone (2026-10-21) |
| Apple Pencil | `IDeviceBattery.swift` | ❔ |
| Nearcast | `Multipeer.swift` | ❔ |
| Widget | `widget/` | ✅ affichage OK avec signature gratuite (2026-10-21) ; faute SwiftUI bénigne, note 3 |
| CLI `abt` | `abt/` | ✅ depuis un shell, tableau / `--csv` / `--json` / `--nearcast` (2026-10-21, `fix/abt-data-access`) ; note 2 |

### Notes du premier lancement (2026-10-21, macOS 27.0.1, build Debug signé `PCH7VR8GPS`)

Testé par Côme sur son Mac. Réglages par défaut. Autorisations accordées au premier lancement : **Bluetooth** et **appareils du réseau local** (la seconde vient de Nearcast / MultipeerKit). La fenêtre des Réglages s'ouvre (upstream #175 non reproduit), et la section « Update » est bien masquée (D-004).

1. **Logitech MX Anywhere 3** (BLE direct, `0x046D:0xB025`, `HID BLE`) : macOS affiche sa batterie dans Réglages › Bluetooth, mais `system_profiler SPBluetoothDataType -json` ne donne **aucun champ batterie** pour elle (seuls `device_minorType`, `device_vendorID`, `device_productID`, `device_services`), et `ioreg` n'a pas de `BatteryPercent`. La découverte BLE générique (`readBLEDevice`) ne voit que les appareils qui *annoncent* (`scanForPeripherals`) ; une souris déjà connectée n'annonce plus. Piste : `CBCentralManager.retrieveConnectedPeripherals(withServices: [180F])` puis lecture de `2A19`. **Résolu le 2026-10-21** (branche `fix/ble-hid-battery`) : la souris apparaît, avec le même pourcentage que Réglages › Bluetooth. Sans rapport avec upstream #209 (souris MX via récepteur USB Logi Bolt).
2. **`abt` et la protection des containers** : `abt` lancé depuis le shell de Claude Code → `Read JSON error … Code=257 … Operation not permitted` sur `~/Library/Containers/io.github.msieurpafi.AirBattery.widget/Data/Documents/data.json`, et `ls` sur ce dossier est refusé aussi. Pourtant, une lecture du même fichier, juste après le lancement, avait réussi (16:47). Hypothèse : la protection des données d'apps (macOS 14+) s'applique au processus responsable (le terminal) une fois le container « adopté » par le widget. À tester depuis Terminal.app : macOS devrait demander l'autorisation d'accéder aux données d'autres apps. Le CLI doit sans doute lire ailleurs (container de l'app principale, non sandboxée) ou passer par l'app. **Résolu le 2026-10-21** (`fix/abt-data-access`) : l'app exporte une copie dans `~/Library/Application Support/io.github.msieurpafi.AirBattery/` (`data.json`, `nearcast.json`), que `abt` lit.
3. **Widget, faute SwiftUI** : `ForEach<ArraySlice<Device>, …>: the ID Device(… deviceType: "blank", deviceName: "" …) occurs multiple times within the collection`. Les cases vides de remplissage ont toutes le même identifiant (`Device` hashé sur l'ensemble de ses champs). Sans effet visible pour l'instant. À corriger avec l'indexation par ID (Phase 1).
4. **`EXC_GUARD` (upstream #207) reproduit sur macOS 27.0.1 puis corrigé** (`perf/ble-scan`, `0b75d57`) : `kernel … ERROR: [AirBattery:PID] EXC_GUARD AST: type=0x1 flavor=0x200 …`, par paires, une fois par seconde (1 193 lignes en 10 min, ~240 en 2 min). Cause : `InternalFinder.close()` appelait `IOServiceClose()` sur un `io_service_t` jamais ouvert, à chaque lecture de la batterie du Mac (2 par seconde, via `mainTimer`). Reproduit isolément (`swiftc`, 3 appels → 3 `EXC_GUARD` identiques ; sans `IOServiceClose` → 0). Après correctif : 0 en 2 min et en 5 min.
5. **`comptest` plante dans libimobiledevice** (upstream #198, reproduit 2026-10-21 19:56) : `EXC_BAD_ACCESS SIGSEGV` dans `idevice_connect` ← `service_client_new` ← … ← `companion_proxy_client_start_service` ← `comptest main`, avec la `libimobiledevice-1.0.6.dylib` embarquée (2024). L'app n'est pas affectée (processus séparé, délai de 15 s depuis `6ea85bb`) et la Watch est relue au cycle suivant. Argument pour la recompilation en Phase 2.
6. **Registre `AppleSmartBattery` sur Apple Silicon (M1 Pro, macOS 27.0.1)** : `CurrentCapacity`/`MaxCapacity` = pourcentages (100/100), `CycleCount` = 301 et `DesignCycleCount9C` = 1000 au premier niveau ; `DesignCapacity` (6 075 mAh) et `NominalChargeCapacity` (5 424 mAh) seulement dans `BatteryData` ; pas d'`AppleRawMaxCapacity`. Rapport système : « Capacité maximale 91 % ». `IOPowerSources` : Current 100 / Max 100.
7. Bruit sans conséquence : `tccd … kTCCServiceAppleEvents requires entitlement com.apple.security.automation.apple-events but it is missing` au lancement. La même ligne apparaît pour d'autres apps (Thaw, l'updater Sparkle de Thaw), ce n'est pas propre à AirBattery. Seul `CommandLineTool.install()` envoie vraiment un Apple Event (`do shell script … with administrator privileges`), à vérifier le jour où on l'utilise.

### App officielle 1.6.3 sur macOS 27.0.1 : crashs

4 crashs entre le 14 et le 19 octobre, tous dans `closure #1 in AppDelegate.deviceIsConnected(notification:fromDevice:)` (1 SIGABRT « pointer being freed was not allocated », 3 SIGSEGV). Détail : `samples/2026-10-21_26A434_official-1.6.3-crashes.md`. Correspond à upstream #215 / #206, correctif candidat PR #216.

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
