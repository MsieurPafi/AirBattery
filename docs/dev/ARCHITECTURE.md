# Architecture

Carte du code, à enrichir au fil des sessions. Point de départ : relevé du 19/10/2026 sur `134e02f` (voir aussi `CLAUDE.md` §4, qui garde ce relevé initial). **Mise à jour pour 1.10.0** (2026-10-25, `e4e973a`).

## Targets

| Target | Dossier | Rôle | Sandbox |
| --- | --- | --- | --- |
| AirBattery | `AirBattery/` | App principale (SwiftUI + AppKit) | non |
| widget | `widget/` | Extension WidgetKit (3 tailles) | oui |
| AirBatteryHelper | `AirBatteryHelper/` | Lancement au login : inscrit par `LoginItem` (`AirBatteryApp.swift`), via `SMAppService.loginItem` sur macOS 13+ et `SMLoginItemSetEnabled` sur macOS 12 | |
| abt | `abt/` | CLI, produit `abtp` (D-017) | |

Réglages : `MACOSX_DEPLOYMENT_TARGET = 12.0` (D-007), `SWIFT_VERSION = 5.0`, hardened runtime. Dépendances SPM : Sparkle 2.6.2 (D-026), MultipeerKit 0.4.0, swift-argument-parser 1.5.0.

Dossier `Shared/` (groupe synchronisé, compilé dans les 4 targets) :
- `AppIdentifiers.swift` (D-006) ;
- `Log.swift` (`os.Logger`, D-019) ;
- `Core/` : logique pure, en Foundation seule, testée par `swift test` grâce au `Package.swift` de la racine (D-025). Contenu : `DeviceIdentity`, `BatteryParsing`.

Ressources traduites : String Catalogs `AirBattery/Localizable.xcstrings` (app et widget) et `InfoPlist.xcstrings` (D-022) ; `*.lproj/Credits.rtf`.

## Sources de données (`AirBattery/BatteryInfo/`)

| Fichier | Lit | Mécanisme |
| --- | --- | --- |
| `InternalBattery.swift` | Batterie du Mac | IOKit `AppleSmartBattery` + `IOKit.ps` |
| `MagicBattery.swift` | Magic + autres BT | IOKit + `system_profiler SPBluetoothDataType -json` |
| `BTDBattery.swift` | BT tiers | logs `bluetoothd` via `log show` (`Supports/logReader.sh`, réparé en 1.10.0, COMPAT note 13) ; lecture incrémentale par `LogReader` (`Supports.swift`), fenêtre de 10 min au plus |
| `BLEBattery.swift` | AirPods/Beats, BLE GATT | CoreBluetooth (manufacturer data `0x004C`, service `180F`) |
| `IDeviceBattery.swift` | iPhone/iPad/Watch/Pencil | binaires libimobiledevice embarqués |

Nearcast v2 (D-029, `docs/dev/NEARCAST-V2.md`) : protocole dans `Shared/Core/NearcastProtocol.swift` (code de groupe `nc2-` + 26 caractères, HKDF à sel fixe, étiquette de groupe HMAC, message scellé entier en AES-GCM, rejeu refusé, jeton d'invitation ; tests dans `Tests/AirBatteryCoreTests/NearcastProtocolTests.swift`) ; transport dans `Supports/Multipeer.swift` (MultipeerKit, type de service `airbattery-n2` déclaré dans `NSBonjourServices`, chiffrement obligatoire, invitations filtrées par le jeton). Envoi des données si elles changent (ou toutes les 5 min, minuterie de diffusion du `Scheduler`), demande d'envoi à chaque pair qui se connecte. Un Group ID v1 désactive Nearcast au lancement, avec une notification.

## Ordonnancement

- **Minuteries d'interface** (`Supports.swift`) : `mainTimer` (1 s, batterie du Mac et icône de la barre des menus) et `dockTimer` (5 s, Dock et épingles), avec tolérance.
- **`Scheduler`** (`AirBatteryApp.swift`, démarré au lancement) : alertes (300 s), rechargement des widgets (intervalle de Proximité), `system_profiler` + accessoires Magic et Bluetooth (une fois par intervalle, 5 min au plus, file série hors du fil principal), données des widgets (0,4 × intervalle, écrites seulement si un champ affiché change), diffusion Nearcast. Intervalles lus au lancement.
- **`PowerSourceMonitor`** (`AirBatteryApp.swift`) : relit la batterie du Mac (`InternalBattery.status`) sur notification de macOS (`IOPSNotificationCreateRunLoopSource`, mode bas régime, sortie de veille), plus une lecture de secours toutes les 60 s, puis poste `.internalBatteryChanged`. L'icône de la barre des menus (`mainBatteryView`) se met à jour sur cette notification et quand un réglage d'affichage change, plus chaque seconde.
- **Sources** : chacune a sa minuterie. BLE (intervalle), BTD (59 × intervalle s), iPhone/iPad/Watch : `UsbmuxdListener` (`IDeviceBattery.swift`, D-028) écoute `/var/run/usbmuxd` (requête « Listen », protocole dans `Shared/Core/Usbmuxd.swift`) ; lecture dès qu'un appareil apparaît (USB ou Wi-Fi), puis une fois par intervalle tant qu'il reste attaché (minuterie de 15 s qui parcourt la liste, sans lancer d'outil) ; une lecture à la fois par appareil. Sans réponse d'`usbmuxd` : retour à l'ancien scan (`idevice_id -n`/`-l` toutes les 15 s), nouvelle tentative toutes les 30 s.
- **`process()`** (`Supports.swift`) : outils externes avec délai (20 s par défaut) ; à l'expiration, arrêt de l'arbre de processus (`terminateTree`) ; sortie d'erreur ignorée.

## Identité des appareils

`AirBatteryModel.updateDevice` retrouve un appareil par identifiant d'abord (adresses normalisées), puis par nom, sauf deux UDID différents (`DeviceIdentity.matchIndex`, D-025). Les listes (alertes, épingles, masqués, blocage/autorisation) restent par nom, comparé via `DeviceIdentity.sameName` (suffixe du boîtier des AirPods dans toutes les langues).

## Flux de données

1. Chaque source appelle `AirBatteryModel.updateDevice(_:)`.
2. `AirBatteryModel.writeData()` écrit `~/Library/Containers/<bundle-id-widget>/Data/Documents/data.json`, mais seulement si un champ affiché a changé, ou toutes les 5 min (`writeData(force: true)` pour les actions de l'utilisateur, le lancement, les URL et AppleScript).
3. Le widget relit ce fichier quand l'app demande un rechargement : seulement après une écriture.
4. Pour les outils locaux, l'app écrit une copie dans `~/Library/Application Support/<bundle-id-app>/` (`data.json`, et `nearcast.json` avec les appareils Nearcast déjà filtrés comme dans l'app), seulement sur demande (`writeData(force: true)`). Raison : depuis macOS 14, un processus lancé depuis un terminal ne peut plus lire le container sandboxé d'une autre app. `abtp` ouvre `<schéma>://writedata`, attend 500 ms, puis lit cette copie.
5. Données Nearcast reçues : `…/Documents/NearcastData/*.json` (container du widget).

## Identifiants codés en dur

Depuis `4737267` (D-006), plus aucun identifiant n'est codé en dur dans le code Swift :

- bundle IDs : réglage de build `APP_ID_PREFIX` (niveau projet) → `$(APP_ID_PREFIX).AirBattery`, `.AirBattery.widget`, `.AirBatteryHelper` ;
- côté Swift : `Shared/AppIdentifiers.swift` (dossier synchronisé, compilé dans les 4 targets) ;
- schéma d'URL `airbattery-plus` : `AirBattery/Info.plist` + `AppIdentifiers.urlScheme`. Commandes : `writedata` (utilisée par `abtp`) et `reloadwidgets` (l'ancienne forme `reloadwingets` reste acceptée).

Les crédits (`*.lproj/Credits.rtf`) et `wificonnection.c` mentionnent toujours lihaoyun6 : c'est voulu (AGPL, auteur d'origine).

## Mises à jour (Sparkle)

Réactivées par D-026 (désactivées de la 1.7.0 à la 1.10.0, D-004) :
- `Info.plist` : `SUFeedURL` = `https://raw.githubusercontent.com/MsieurPafi/AirBattery-Plus/main/appcast.xml`, `SUPublicEDKey` = clé du fork. Pas de `SUEnableAutomaticChecks` : Sparkle demande l'autorisation au deuxième lancement.
- `Supports/Sparkle.swift` : `updatesEnabled` (désormais `true`) démarre l'updater (`AirBatteryApp.swift`) et affiche « Mise à jour » et « Rechercher des mises à jour… » dans les réglages généraux.
- `appcast.xml` à la racine, mis à jour par `scripts/update-appcast.sh <dmg>` (`generate_appcast` de Sparkle, clé lue dans le trousseau, notes tirées de `CHANGELOG.md`). Procédure : `CONTRIBUTING.md` § Releases.

## Outils de développement

- Mode démo (builds Debug, `-demoDevices YES`, D-023) pour les captures d'écran.
- Intégration continue (D-027) : `.github/workflows/ci.yml` (image `xcode-27`), contrôles rapides dans `scripts/ci-checks.sh`, `swift test`, builds Debug et Release non signés. Ne publie rien.
- Essais d'une copie de test : désenregistrer ensuite son widget (`pluginkit -r`, `lsregister -u`). Pour tester `abtp` ou les URL, l'enregistrer temporairement comme gestionnaire du schéma (JOURNAL 2026-10-25 suite 21).

