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
| iPhone / iPad (libimobiledevice) | `IDeviceBattery.swift` | ✅ iPhone 17 en USB (2026-10-21) ; avec libimobiledevice 1.4.0 recompilée (D-016) : Wi-Fi et USB OK (2026-10-22) |
| iPhone / iPad via BLE (liste autorisée, D-009) | `BLEBattery.swift` | ✅ iPhone 17 autorisé via « Manage » › « Pair… » ; Apple Watch refusée avec un message (2026-10-21) |
| Apple Watch (`comptest`) | `IDeviceBattery.swift` | ✅ via l'iPhone (2026-10-21) ; `comptest` recompilé et corrigé (#198) : OK, plus de crash depuis (2026-10-22) |
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
7. **Gestionnaire de barre des menus Thaw** (dérivé d'Ice, utilisé par Côme) : il identifie les icônes par `<bundle ID>:<nom>` (`defaults read com.stonerl.Thaw MenuBarConcealBundleIDMap`). Avant `27f28da`, il avait enregistré `io.github.msieurpafi.AirBattery:Item-0`, `…:Item-1` et **`…:85%`** pour l'icône épinglée de la MX, c'est-à-dire son texte : quand le pourcentage change, l'icône peut être vue comme nouvelle (upstream #182). Après ajout des `autosaveName` et relance, les icônes principale et épinglée sont **restées en place** (vérifié par Côme), mais Thaw n'avait pas encore enregistré les nouveaux noms au bout de 90 s. À revoir quand le pourcentage de la souris changera.
8. **Accès au réseau local redemandé à chaque nouvelle version** : `nehelper` mémorise l'autorisation par UUID d'exécutable (« Caching 1 UUID(s) for io.github.msieurpafi.AirBattery ») ; chaque compilation change l'UUID, donc macOS repose la question au premier usage du réseau local (Nearcast/Bonjour), y compris après une mise à jour. Observé le 2026-10-22 au réveil avec la version de test. Un mécanisme de mise à jour intégré n'y changerait rien. Le texte de la demande dit encore « AirBattery » (`NSLocalNetworkUsageDescription`, tâche identité).
   - **Correction du 2026-10-25 :** « chaque compilation change l'UUID » est faux. L'UUID (`LC_UUID`) ne change que si le code compilé change : la 1.11.1, sans changement de code, a exactement les UUID de la 1.11.0 (`dwarfdump --uuid` : arm64 `8DD7FDE8-4559-3C1C-933E-AB83CF750ACF`, x86_64 `F48D39B7-AB48-3294-AE6C-40BD60192A68`), déjà connus de `nesessionmanager` (« UUID: Found for io.github.msieurpafi.AirBattery »). Résultat : pas de nouvelle demande après la mise à jour 1.11.0 → 1.11.1 par Sparkle (constaté par Côme). Une version qui change le code redemandera, par Sparkle comme à la main. Guide (EN/FR) corrigé : « après la plupart des mises à jour ».
   - **Précision du 2026-10-27 :** la demande n'apparaît qu'au premier usage du réseau local **par l'app elle-même**, c'est-à-dire Nearcast (MultipeerKit, Bonjour). Les iPhone en Wi-Fi passent par `usbmuxd` (service système), pas par l'app. Mise à jour 1.11.1 → 1.12.0 par Sparkle (nouveaux UUID : arm64 `650A8A39-62D8-3CD7-A274-FA926D068FC2`) : pas de demande, Nearcast étant désactivé chez Côme (clé `nearCast` absente, défaut `false`) ; aucune trace de l'app dans `nehelper` / `nesessionmanager` après le lancement (26/10 13:56:56).
9. **Cause de #198 trouvée** : `comptest.c` (gist d'origine) utilisait un `idevice_t` non initialisé quand l'iPhone n'est pas joignable (`idevice_new_with_options` ne le remplit pas en cas d'échec) → SIGSEGV dans `idevice_connect` (binaire 2024, 3 fois le 21/10) ou SIGABRT dans `idevice_free` (binaire recompilé, 12:48 et 12:52 le 22/10). Corrigé dans `5b4cf12`.
10. Bruit sans conséquence : `tccd … kTCCServiceAppleEvents requires entitlement com.apple.security.automation.apple-events but it is missing` au lancement. La même ligne apparaît pour d'autres apps (Thaw, l'updater Sparkle de Thaw), ce n'est pas propre à AirBattery. Seul `CommandLineTool.install()` envoie vraiment un Apple Event (`do shell script … with administrator privileges`), à vérifier le jour où on l'utilise.
11. **Autres messages Bluetooth dans les logs de l'app (relevé du 2026-10-25, 1.7.3, 24 h)** : `IOBluetoothCoreBluetoothCoordinator … connectionStatusHandler (disconnect) callback`, `handlePeerDisconnectionCompleted: <private> not found`, `CBClassicPeer dealloc` et « No name or address » (~225 chacun par 24 h, par salves toutes les ~15 min). **Pas de notre fait** : sur 3 h, `sharingd`, `audioaccessoryd`, `PerfPowerServices` et Vorssaint en consignent exactement autant (92) aux mêmes instants. IOBluetooth signale les connexions des périphériques classiques à tout processus qui utilise le framework. Les « Cannot create IOBluetoothDevice » (897) et « API MISUSE … powered on state » (58) relevés le 2026-10-23 n'apparaissent plus sur 72 h : ils dataient des jours de tests (copies de build, option « Discover more BLE devices »). `reloadAllTimelines()` une fois par minute : voulu (réglage d'intervalle de rafraîchissement du widget).
12. **Apple Watch lue par l'iPhone en libimobiledevice uniquement** : l'iPhone Duo (`iPhone19,4`) de Côme apparaît via la découverte Bluetooth autorisée (D-009), mais ni `idevice_id -l` ni `idevice_id -n` ne le voient (2026-10-25) : le Mac n'a pas encore de *pair record* pour lui. Or `comptest` (Watch) passe par l'iPhone en USB ou Wi-Fi. Après un changement d'iPhone, il faut le brancher une fois en USB, le déclarer fiable, et cocher « Afficher cet iPhone en Wi-Fi » dans le Finder.
13. **`logReader.sh` inopérant depuis `de55b38` (PR upstream #163), corrigé le 2026-10-25** (`fix/logreader`).
    - Première cause : `IFS=$'\n'` en tête du script fusionnait les options (`--style compact` en un seul argument) ; `--level info` n'existe pas pour `log show` (code de sortie 64).
    - Seconde cause : la date `--start` produite par l'app (`yyyy-MM-dd HH:mm:ss ZZZZZ`, donc avec une espace avant le fuseau) était refusée (« Failed conversion … using format '%Y-%m-%d %H:%M:%S%z' »). Formats acceptés : `2026-10-25 17:50:16+0100` ou sans fuseau.
    - Sur le Mac de Côme (macOS 27.0.1), aucune ligne `Battery M` en 2 h de journaux, et aucune paire `statedump: 0x001D Characteristic Value`. Ces lignes viennent d'appareils Bluetooth classiques d'autres marques (casques, enceintes), que Côme n'a pas : le format n'est donc ni confirmé ni infirmé sur macOS 27.
    - Coût mesuré de `log show --info` avec le prédicat : 3,5 s pour 10 min de journaux, 8 s de temps réel (3,5 s de CPU) pour 2 h.
    - Échantillon de test : `docs/dev/samples/logreader-mac-sample.log` (lignes synthétiques au format attendu).
14. **Mise à jour par Sparkle (macOS 27.0.1, 26A434, 2026-10-25)** : 1.11.0 → 1.11.1, déclenchée par Côme avec « Rechercher des mises à jour… », téléchargée, installée et relancée sans mot de passe. Après coup : 1.11.1 (1111) dans `/Applications`, `codesign --verify --deep --strict` OK, **pas d'attribut `com.apple.quarantine`** (seulement `com.apple.macl` et `com.apple.provenance`), donc pas de passage par Gatekeeper au lancement, alors que `spctl -a` rejette l'app (non notarisée, D-003). Widget 1.11.1 enregistré seul, aucun rapport de plantage. Pas de nouvelle demande d'accès au réseau local : voir la correction de la note 8.
15. **Charge de la boîte des AirPods, couvercle fermé : indétectable (macOS 27.0.1, AirPods Pro de Côme, 2026-10-27)** : couvercle fermé, branchée ou non, le Mac ne reçoit ni message « couvercle ouvert » (type 7, 29 octets) ni le message « couvercle fermé » de 25 octets (type 18) que l'app sait lire ; seulement des messages Find My de 6 octets (type 18, sans nom, identifiant tournant, ex. `4c0012020002` à −37 dBm), sans niveau ni indicateur de charge. Dès l'ouverture du couvercle, la boîte annonce sa charge (bit 7 de l'octet du niveau) et l'app l'affiche aussitôt. Même comportement que l'iPhone, qui n'affiche la boîte qu'à l'ouverture. Diagnostic dans JOURNAL 2026-10-27 suite 7 (code non fusionné, diff gardé hors du dépôt).
16. **`NSAlert.runModal()` bloqué dans un `onChange` de SwiftUI (macOS 27.0.1, 2026-10-28)** : « Suppressing invocation of -[NSAlert runModal]. -[NSAlert runModal] cannot run inside a transaction begin/commit pair… » (`com.apple.AppKit:General`), avec la pile `NearcastView … onChange`. L'alerte ne s'affiche pas et le code continue : Nearcast se désactivait sans explication. Trois alertes concernées (Nearcast, astuces Dock et « Discover more BLE devices »), ouvertes désormais dans un `DispatchQueue.main.async`. À surveiller pour toute nouvelle alerte ouverte depuis un `onChange`. Compter les cas : `log show --predicate 'process == "AirBattery Plus" AND eventMessage CONTAINS "Suppressing invocation"'`.

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
