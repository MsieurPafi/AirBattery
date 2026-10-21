# Journal de bord

Une entrée par session, en ajout seulement. Une entrée fausse n'est jamais effacée : on ajoute une correction datée qui y renvoie.

---

## 2026-10-21 — Phase 0 : environnement, copie de travail, documentation

**Contexte :** macOS 27.0.1 (26A434), arm64 (MacBook Pro M1 Pro). Xcode 27.1 (27A9275) installé dans `/Applications/Xcode.app`. Swift 6.4 (CLT). Git 2.54.0. `gh` connecté au compte `MsieurPafi`. Commit de départ `134e02f`.
**Objectif :** Phase 0, étapes 1 à 3 (et préparer 4 à 6).

**Fait :**
- Étape 1 — relevé de l'environnement (versions ci-dessus).
- Étape 2 — clone de `https://github.com/MsieurPafi/AirBattery` dans `src/`. Remotes :
  - `origin` → le fork (push autorisé sur accord de Côme) ;
  - `upstream` → `lihaoyun6/AirBattery`, push `DISABLED` ;
  - `archive` → `../AirBattery.git`, push `DISABLED`, avec un refspec supplémentaire `+refs/pull/*/head:refs/remotes/archive/pr/*` : les têtes des PR archivées sont dans `archive/pr/<N>`. Seul `git fetch` touche le miroir, en lecture.
  - `origin/main`, `upstream/main` et `archive/main` pointent tous sur `134e02f`.
- Étape 3 — squelette de `docs/`. Décisions D-001 à D-005 consignées (bundle ID `io.github.msieurpafi`, schéma `airbattery-plus://`, validés par Côme le 2026-10-21). `.DS_Store` ajouté au `.gitignore` (`build/` y était déjà).

**Échecs :**
- `xcode-select -p` → `/Library/Developer/CommandLineTools` ; `xcodebuild -version` → `xcode-select: error: tool 'xcodebuild' requires Xcode, but active developer directory '/Library/Developer/CommandLineTools' is a command line tools instance`.
- Avec `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` : `xcodebuild -version` répond `Xcode 27.1`, mais toute autre commande → `You have not agreed to the Xcode license agreements. Please run 'sudo xcodebuild -license' from within a Terminal window to review and agree to the Xcode and Apple SDKs license.` (`-checkFirstLaunchStatus` → code 69).
  **Bloquant pour l'étape 4.** Nécessite `sudo` : à faire par Côme (voir Prochaine étape).

**Contournements :** aucun.
**Décisions :** D-001 à D-005.
**Testé sur appareil réel :** non.
**Pistes ouvertes :** —
**Prochaine étape :** Côme lance dans un terminal `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`, `sudo xcodebuild -license accept`, `sudo xcodebuild -runFirstLaunch`. Ensuite : build de référence de `main` (étape 4).

---

## 2026-10-21 (suite) — Phase 0 : build de référence, identité, Sparkle

**Contexte :** macOS 27.0.1 (26A434), Xcode 27.1 (27A9275), commit de départ `86106af`. Côme a lancé `sudo xcode-select -s …`, `sudo xcodebuild -license accept` et `sudo xcodebuild -runFirstLaunch` : `xcode-select -p` → `/Applications/Xcode.app/Contents/Developer`, `-checkFirstLaunchStatus` → 0. Le bloquant de l'entrée précédente est levé.
**Objectif :** Phase 0, étapes 4 à 6.

**Fait :**
- Étape 4 — build de référence de `main` tel quel. Trois erreurs, détaillées dans `COMPAT.md` § Build : signature (équipe de l'auteur, attendu), cible de déploiement 11.0 refusée par Xcode 27.1 (minimum 12.0), `import ServiceManagement` manquant. Avec `CODE_SIGNING_ALLOWED=NO MACOSX_DEPLOYMENT_TARGET=12.0` et l'import ajouté : **BUILD SUCCEEDED**.
- `774c380` (branche `fix/build-xcode27`) : `fix: add missing ServiceManagement import`.
- Étape 5 — `4737267` (branche `chore/fork-identity`) : bundle IDs `io.github.msieurpafi.*` dérivés d'un réglage `APP_ID_PREFIX`, schéma `airbattery-plus://`, constantes Swift dans `Shared/AppIdentifiers.swift` (D-006), `DEVELOPMENT_TEAM = PCH7VR8GPS` (« Come Bouquet (Personal Team) », gratuite). Vérifié dans le `.app` produit : `CFBundleIdentifier` des trois bundles = `io.github.msieurpafi.AirBattery`, `….AirBattery.widget`, `….AirBatteryHelper` ; `CFBundleURLSchemes` = `[airbattery-plus]`.
- Étape 6 — `994dca4` (branche `chore/disable-sparkle`) : `SUFeedURL` et `SUPublicEDKey` retirés, `SUEnableAutomaticChecks = NO`, updater jamais démarré, UI de mise à jour masquée (flag `updatesEnabled`). Vérifié : le `Info.plist` du `.app` n'a plus de `SUFeedURL`, et le binaire ne contient plus `raw.githubusercontent` ni `lihaoyun6`.
- Les trois branches sont fusionnées en fast-forward dans `main`. **Rien n'est poussé sur `origin`.**

**Échecs :**
- Premier essai sur le schéma d'URL : `plutil -replace CFBundleURLTypes.0.CFBundleURLSchemes.0 -string airbattery-plus` a **inséré** la valeur au lieu de remplacer l'ancienne (le `.app` déclarait `airbattery-plus` **et** `airbattery`). Corrigé avec `plutil -remove …CFBundleURLSchemes.1` avant le commit. À retenir : vérifier le résultat de `plutil -replace` sur un élément de tableau.
- Signature avec l'équipe personnelle non testée : `security find-identity -v -p codesigning` → `0 valid identities found`. Aucun certificat de développement dans le trousseau (W-002).

**Contournements :** W-001 (cible de déploiement en ligne de commande), W-002 (builds sans signature).
**Décisions :** D-006 (acceptée), D-007 (proposée : cible de déploiement 12.0, en attente de Côme).
**Testé sur appareil réel :** non. L'app n'a pas encore été lancée.
**Pistes ouvertes :**
- Un fichier `docs/Collé 21-10-2026 à 16.28.57.textClipping` (contenu : `sudo xcodebuild -license accept`) est apparu, sans doute glissé par erreur depuis le terminal. Non versionné, laissé en place : à supprimer par Côme.
- Warnings `switch must be exhaustive` dans les trois widgets : sûrement un nouveau cas de `WidgetFamily` dans le SDK 27.
- `kIOMasterPortDefault` déprécié (`Supports.swift:426`).
**Prochaine étape :** Côme valide D-007 et crée le certificat de développement ; ensuite, build signé, puis étape 7 (premier lancement, après avoir quitté l'AirBattery officielle), en vérifiant en particulier que le widget s'enregistre avec la signature gratuite.

---

## 2026-10-21 (suite 2) — Cible de déploiement 12.0 (D-007)

**Contexte :** macOS 27.0.1 (26A434), Xcode 27.1 (27A9275), commit de départ `89d8521`.
**Objectif :** appliquer D-007, validée par Côme.

**Fait :**
- `138b433` (branche `build/deployment-target-12`, fusionnée en fast-forward dans `main`) : `MACOSX_DEPLOYMENT_TARGET` passé de 11.0 à 12.0, 10 occurrences dans `project.pbxproj`.
- Build `clean build` sans `MACOSX_DEPLOYMENT_TARGET` en ligne de commande, schémas `AirBattery` et `abt` : OK. `LSMinimumSystemVersion` = 12.0 pour l'app, le widget et le helper ; `vtool -show-build abt` → `minos 12.0`.
- W-001 retiré. Warnings inchangés (cf. `COMPAT.md`).

**Échecs :**
- Correction de l'entrée précédente et de W-001 : j'avais compté 8 occurrences de `MACOSX_DEPLOYMENT_TARGET`, il y en a 10 (2 au niveau projet + 8 dans les targets).
- Un `clean build` du schéma `abt` efface aussi les produits du schéma `AirBattery` (`-derivedDataPath` partagé) : refaire un `build` de l'app avant d'inspecter le `.app`.

**Contournements :** W-002 reste (builds sans signature).
**Décisions :** D-007 acceptée.
**Testé sur appareil réel :** non.
**Prochaine étape :** certificat de développement pour l'équipe `PCH7VR8GPS`, build signé, puis étape 7 (premier lancement).

---

## 2026-10-21 (suite 3) — Build signé avec l'équipe personnelle

**Contexte :** macOS 27.0.1 (26A434), Xcode 27.1 (27A9275), commit de départ `6cb684b`.
**Objectif :** lever W-002 (signature) et préparer l'étape 7.

**Fait :**
- Côme a créé le certificat « Apple Development » dans Xcode (Réglages › Comptes › Gérer les certificats). `security find-identity -v -p codesigning` → 1 identité valide, équipe `PCH7VR8GPS`.
- Build signé sans option particulière : OK, aucun profil de provisionnement requis. Détail des signatures et entitlements dans `COMPAT.md` § « Build signé ». W-002 retiré.
- PlugInKit a enregistré le widget du fork depuis `DerivedData` ; container sandboxé créé (vide).
- Binaires libimobiledevice embarqués : s'exécutent (`1.3.0-210-g73b6fd1`, ad hoc). Aucun appareil iOS branché.
- AirBattery officielle : app principale arrêtée ; seule son extension widget (`com.lihaoyun6.AirBattery.widget`, lancée par WidgetKit) tourne. Elle ne scanne pas le BLE.

**Échecs :**
- `security find-certificate -c "Apple Development"` renvoie d'abord un certificat **expiré** (`notAfter=Jul 12 14:08:21 2025`, même équipe) resté dans le trousseau. Sans effet sur la signature (`find-identity -v` ne liste que le valide), mais Côme peut le supprimer de Trousseaux d'accès s'il veut faire le ménage.

**Contournements :** aucun actif.
**Décisions :** —
**Testé sur appareil réel :** non (app pas encore lancée).
**Prochaine étape :** étape 7, premier lancement avec Côme (checklist donnée en session).

---

## 2026-10-21 (suite 4) — Étape 7 : premier lancement

**Contexte :** macOS 27.0.1 (26A434), build Debug signé (`PCH7VR8GPS`) @ `51cf3a0`. App officielle arrêtée (seule son extension widget tournait). Lancement : `open --stdout … --stderr … build/DerivedData/Build/Products/Debug/AirBattery.app`, logs capturés avec `/usr/bin/log stream` dans `build/logs/run-2026-10-21-1646.log`.
**Objectif :** Phase 0, étape 7 : vérifier source par source avec Côme.

**Fait (testé par Côme, sur ses appareils) :**
- Autorisations Bluetooth et réseau local demandées et accordées.
- Icône dans la barre des menus, batterie interne OK.
- AirPods Pro : écouteurs + boîtier OK.
- Réglages : la fenêtre s'ouvre, section « Update » absente.
- Widget du fork ajouté : affichage OK. Vérifié côté système : c'est bien `…/DerivedData/…/AirBatteryWidgetExtension.appex` (PID 11596) qui le sert. **Un widget WidgetKit fonctionne avec une signature d'Apple ID gratuit.**
- iPhone 17 en USB + Apple Watch associée : OK.
- Après 12 min : 0,4 % CPU, 114 Mo de mémoire résidente, aucun crash.

**Échecs :**
- Souris Logitech MX Anywhere 3 (BLE) absente. Diagnostic dans `COMPAT.md`, note 1.
- `abt` depuis le shell → `Operation not permitted` sur `data.json` (`COMPAT.md`, note 2).
- Côté outillage, deux pièges à retenir : `timeout` n'existe pas sur macOS (exit 127), et **sous zsh, `log` est une commande interne** qui masque `/usr/bin/log` (`log: too many arguments`, et un `log show` qui ne renvoie rien sans erreur). Toujours écrire `/usr/bin/log`.

**Découverte :** 4 crashs de l'app **officielle** 1.6.3 sur ce Mac entre le 14 et le 19/10, tous dans `AppDelegate.deviceIsConnected` (`samples/2026-10-21_26A434_official-1.6.3-crashes.md`). Ça confirme upstream #215/#206 sur macOS 27 et place la PR #216 en tête de la Phase 1.

**Contournements :** aucun.
**Décisions :** —
**Testé sur appareil réel :** oui, par Côme : Mac, AirPods Pro, iPhone 17, Apple Watch, souris MX Anywhere 3, widget.
**Pistes ouvertes :** souris BLE HID (`retrieveConnectedPeripherals`), accès de `abt` aux données, faute SwiftUI des cases vides du widget.
**Prochaine étape :** Phase 0 terminée. Phase 1 : intégrer la PR #216 (concurrence), en tenant compte des recouvrements avec #214 et la 1.6.4 communautaire.

**Ajout (2026-10-21, fin de session) :** avec l'accord de Côme, `main` poussé sur `origin` (`MsieurPafi/AirBattery`) : `134e02f..165f557`, fast-forward. Les branches de travail (`fix/build-xcode27`, `chore/fork-identity`, `chore/disable-sparkle`, `build/deployment-target-12`) restent locales ; elles sont entièrement contenues dans `main`.

---

## 2026-10-21 (suite 5) — Phase 1 : intégration de la PR #216 (concurrence)

**Contexte :** macOS 27.0.1 (26A434), Xcode 27.1, commit de départ `061f05b`, branche `fix/215-concurrency`.
**Objectif :** corriger le crash de `deviceIsConnected` (upstream #215/#206), observé 4 fois sur l'app officielle chez Côme.

**Fait :**
- `git fetch upstream pull/{216,214,210}/head:upstream-pr-N`. Lecture des diffs : #216 = 3 commits ; #214 ne touche pas à la concurrence.
- Sources de la 1.6.4/1.6.5 communautaire trouvées (`callieskye/Air-Battery`), remote `callie` en lecture seule. Comparaison dans D-008 et `UPSTREAM.md`.
- Cherry-pick de #216 (`7b06120`, `d4af77a`), un conflit résolu, libellé de file renommé (`59a054d`). Revue : pas d'interblocage possible (aucun appel externe sous `devicesLock`), la closure ne capture plus d'`IOBluetoothDevice`.
- Build signé OK. Fork relancé avec ce build (PID 13065) ; logs veille/réveil capturés dans `build/logs/run-*-pr216-sleepwake.log`.

**Échecs :** —
**Contournements :** —
**Décisions :** D-008.
**Testé sur appareil réel :** en cours (checklist veille/réveil donnée à Côme).
**Pistes ouvertes :** correctifs de callieskye à porter un par un (liste dans `UPSTREAM.md`).
**Prochaine étape :** si le test de Côme est concluant, fusionner `fix/215-concurrency` dans `main` ; ensuite, PR #214 (popups d'appairage), à valider avec Côme.

---

## 2026-10-21 (suite 6) — PR #216 fusionnée, évaluation de la PR #214

**Contexte :** macOS 27.0.1 (26A434), commit de départ `3aca53b`.

**Fait :**
- Retour de Côme : « l'app a l'air de tenir ». Vérifié de mon côté à 17:36 : fork (PID 13065) en vie depuis 30 min, 0 % CPU, 88 Mo ; au moins une veille capot fermé (`Clamshell Sleep` 17:29:33) et plusieurs réveils dans `build/logs/run-2026-10-21-1705-pr216-sleepwake.log` ; **aucun rapport de crash** (AirBattery, comptest, ideviceinfo, wificonnection) depuis le 21/10. Erreurs du fork limitées au bruit CoreBluetooth (`No name or address`, `handlePeerDisconnectionCompleted: <private> not found`).
- `fix/215-concurrency` fusionnée en fast-forward dans `main`.
- PR #214 : description et diff lus ; essai sur la branche `fix/89-ios-ble-allowlist` (cherry-pick `-x` de `3f2a6eb`, `781f750`, `ceaede7`, `c9f9505` → `814b1fe`, `58d6905`, `7f7eb03`, `8d2ee1c` ; `aa85210`, l'import, est sauté). Aucun conflit ; build OK dans `build/DerivedData-trial` (pour ne pas écraser l'app en cours d'exécution), sans nouveau warning. **Non fusionnée** : en attente de la décision de Côme.
- Réglages du fork (`defaults read io.github.msieurpafi.AirBattery`) : aucune des clés `ideviceOverBLE`, `readBLEDevice`, `readBTDevice`, `readBTHID` n'est définie, donc toutes à leur valeur par défaut. En particulier, la découverte d'iPhone par Bluetooth est **désactivée** : Côme n'est pas exposé aux popups d'appairage (#169/#158) avec le fork tel quel.

**Échecs :**
- La sortie standard de l'app, redirigée vers un fichier par `open --stdout`, reste vide : `print()` est mis en tampon complet quand stdout n'est pas un terminal, et ne se vide qu'à la sortie. On ne peut donc pas prouver que `deviceIsConnected` a tourné après les réveils. Piste : `os.Logger` (consigné dans `IDEAS.md`).

**Décisions :** —
**Testé sur appareil réel :** oui, veille/réveil par Côme (PR #216). Observation à poursuivre quelques jours.
**Prochaine étape :** décision de Côme sur #214.

---

## 2026-10-21 (suite 7) — PR #214 testée et fusionnée

**Contexte :** macOS 27.0.1 (26A434), commit de départ `93dd9d2`.

**Fait :**
- Côme avait activé « Discover iOS devices via Bluetooth » sur le build **sans** #214 (PID 13065, lancé à 17:05), sans trouver le bouton « Manage ». Normal : vérifié avec `ps` (chemin `build/DerivedData`) et `defaults read io.github.msieurpafi.AirBattery ideviceOverBLE` → `1`. Bascule immédiate sur le build d'essai `build/DerivedData-trial` (PID 15963).
- Test de Côme : « Manage » › « Pair… » sur son iPhone : OK, l'iPhone remonte. La Watch apparaît dans « Nearby Apple Devices » ; « Pair… » dessus affiche le message de refus prévu (seuls iPhone/iPad sont supportés).
- `fix/89-ios-ble-allowlist` rebasée sur `main` (seulement des commits de doc entre-temps), puis fast-forward. Rebuild dans `build/DerivedData`, relance (PID 16543) : l'autorisation persiste (`authorizedIOSBLEDevices` = 1 entrée « iPhone »).
- `build/DerivedData-trial` supprimé ; `pluginkit` ne liste plus qu'un seul widget du fork.

**Échecs :** —
**Décisions :** D-009.
**Testé sur appareil réel :** oui, par Côme (iPhone 17, Apple Watch).
**Pistes ouvertes :** traduire les nouveaux textes en français (avec #170).
**Prochaine étape :** PR #210 (Wi-Fi privée d'iOS, `syncmac`) : recompiler `wificonnection` depuis les sources plutôt qu'intégrer le binaire de la PR.

---

## 2026-10-21 (suite 8) — Nouveau flux Git, évaluation de la PR #210

**Contexte :** macOS 27.0.1 (26A434), `main` @ `ecf31cb` (poussé).

**Fait :**
- Côme revient sur l'autorisation de pousser `main` : désormais une branche par gros sujet, poussée librement sur `origin`, avec une PR sur son fork qu'il fusionne lui-même (D-010, règle ajoutée dans `CLAUDE.md` § Git).
- PR #210 (`syncmac` pour `wificonnection`) lue : description, `wificonnection.c`, appel ajouté dans `IDeviceBattery.writeBatteryInfo`.
- **Côme est-il concerné ?** Mesures en lecture seule, iPhone débranché :
  - `idevice_id -l` → rien en USB ; `idevice_id -n` → **1 appareil joignable en Wi-Fi**.
  - `log show --last 2h --predicate 'process == "usbmuxd" AND eventMessage CONTAINS "Ignoring"'` : seulement des `already attached as N-fe80::… Ignoring bonjour add event` (l'appareil est **déjà** rattaché) ; **0** message `Pariable=false`, le symptôme décrit par la PR. Une seule adresse MAC annoncée.
  - Conclusion : sur son réseau domestique, le rattachement Wi-Fi fonctionne. Le cas de la PR se produirait sur un autre réseau Wi-Fi (l'adresse privée « fixe » d'iOS est différente pour chaque réseau), et ne serait corrigé qu'au prochain branchement USB.
- Recompilation de `wificonnection` : le dépôt n'embarque **aucun en-tête** (`AirBattery/libimobiledevice/` = `COPYING`, `bin/`, `lib/`). `otool -L bin/wificonnection` : liée à `libimobiledevice-1.0.6`, `libimobiledevice-glue-1.0.0`, `libusbmuxd-2.0.6`, `libplist-2.0.4`, `libssl.3`, `libcrypto.3` via `@executable_path/../lib/`. Les binaires s'identifient comme `1.3.0-210-g73b6fd1`. Il faut donc récupérer les en-têtes de ces bibliothèques, à des commits compatibles.

**Avis sur #210 (donné à Côme) :** diagnostic solide, code propre et idempotent. Mais il réécrit le *pair record* système (partagé avec Finder/Xcode) sans garder l'adresse d'origine, et il lance un processus de plus à **chaque** sondage USB. À reprendre avec trois améliorations : garder l'ancienne valeur, n'appeler `syncmac` qu'une fois par branchement USB, recompiler depuis les sources (script dans `scripts/`). Priorité moyenne, puisque Côme n'est pas touché chez lui.

**Décisions :** D-010.
**Testé sur appareil réel :** non (mesures passives seulement).
**Prochaine étape :** choix de Côme entre #210 (avec ces améliorations) et la souris MX Anywhere 3 (bug qu'il constate lui-même).

---

## 2026-10-21 (suite 9) — Batterie de la souris Logitech MX Anywhere 3 (BLE)

**Contexte :** macOS 27.0.1 (26A434), branche `fix/ble-hid-battery` depuis `main` @ `ecf31cb`.
**Objectif :** afficher la batterie de la souris de Côme (BLE HID, `0x046D:0xB025`), absente jusqu'ici (COMPAT note 1).

**Fait :**
- `BLEBattery.readConnectedPeripherals()`, appelée à chaque `scan()` : `retrieveConnectedPeripherals(withServices: [180F])`, puis `connect` (première fois) ou `readValue(2A19)` (connexion logique déjà ouverte). Le traitement existant de `2A19` crée l'appareil, avec le type `Mouse` tiré de `system_profiler`.
- Test de Côme : la MX Anywhere 3 apparaît, avec l'icône souris et **le même pourcentage** que Réglages › Bluetooth ; aucun popup ; aucun appareil disparu.
- **Coût mesuré** (fork PID 18254, réglages par défaut, intervalle 1 min), via `log show` sur `bluetoothd`, session `AirBattery-central-18254`, sur 2 min en régime établi :
  - 4 `RetrieveConnectedPeripheralsWithServices` : l'ajout, 1 appel par cycle de 29 s, un simple message XPC ;
  - la souris n'est **pas** reconnectée à chaque fois : seulement une lecture `2A19` (1 octet) par minute au plus. Les 4 `ConnectPeripheral` / `CancelPeripheralConnection` observés sont ceux de l'iPhone autorisé (PR #214), vérifiés dans les journaux `bluetoothd` (`peerType iPhone`) ;
  - processus entier : 2,60 s de CPU en 4 min 11 s, démarrage compris (~1 %).
- Constat au passage : le gros de l'activité Bluetooth vient du scan BLE actif existant (4 scans + 168 `RetrieveAddressForPeripheral` en 2 min). Consigné dans `IDEAS.md` (piste #178/#207).

**Échecs :** —
**Testé sur appareil réel :** oui, par Côme (MX Anywhere 3).
**Prochaine étape :** PR sur le fork, à faire relire par Côme.

---

## 2026-10-21 (suite 10) — `abt` débloqué ; pense-bête UI

**Contexte :** macOS 27.0.1 (26A434), branche `fix/abt-data-access` depuis `main` @ `0dcb797`.

**Fait :**
- Pense-bête dans `IDEAS.md` : « soucis d'UI signalés par Côme », sans détail pour l'instant, à sa demande.
- Cause du blocage d'`abt` (COMPAT note 2) : `abt` lisait `data.json` et `NearcastData/` dans le container sandboxé du widget (`~/Library/Containers/io.github.msieurpafi.AirBattery.widget/…`), protégé contre les processus lancés depuis un terminal depuis macOS 14.
- Correctif : `AirBatteryModel.exportForTools()`, appelée par `writeData()` dans l'app principale seulement. Elle écrit `data.json` et `nearcast.json` dans `~/Library/Application Support/io.github.msieurpafi.AirBattery/`, et `abt` lit là. Les écritures sont devenues atomiques (`.atomic`).
- Vérifié depuis le shell de Claude Code, qui était refusé avant : `abt` → tableau avec 3 appareils (Mac 100 % +, MX Anywhere 3 85 % -, iPhone 95 % -) ; `abt --csv` OK ; `abt --nearcast --json` OK (`nearcast.json` = `[]`, aucun Mac Nearcast).

**Échecs :** —
**Testé sur appareil réel :** sur le Mac de Côme, depuis un shell, par Claude. Pas encore depuis le Terminal de Côme.
**Prochaine étape :** PR sur le fork.

---

## 2026-10-21 (suite 11) — Alléger le scan Bluetooth ; `EXC_GUARD` (#207) corrigé

**Contexte :** macOS 27.0.1 (26A434), branche `perf/ble-scan` depuis `main` @ `58d83d6`.
**Objectif :** réduire l'activité Bluetooth d'AirBattery, en mesurant avant et après.

**Mesures avant** (fork PID 21379, réglages par défaut + iPhone autorisé en BLE), via `log show` sur `bluetoothd` :
- scan actif : 15 s au démarrage, puis **5,25 s toutes les 29 s** (≈ 18 %) ;
- `CBMsgIdRetrieveAddressForPeripheral` : rafales de 12 **toutes les 24 s**, sans lien avec le scan. Elles viennent du minuteur `widgetDataTimer` (`system_profiler` + `MagicBattery.scanDevices()` → `IOBluetoothDevice.pairedDevices()` + `addressString`) ;
- `system_profiler SPBluetoothDataType -json` : 0,07 s réel, ~0,03 s CPU par appel, donc négligeable ;
- **`EXC_GUARD` : 1 193 lignes noyau mentionnant AirBattery en 10 min**, par paires, une fois par seconde (`type=0x1 flavor=0x200`, port Mach, nom invalide). C'est upstream #207, reproduit ici.

**Fait :**
- `0b75d57` : cause de #207 trouvée et confirmée par un binaire de test isolé (voir COMPAT note 4). `InternalFinder.close()` appelait `IOServiceClose()` sur un service jamais ouvert ; l'appel est supprimé. Après : **0** `EXC_GUARD` en 2 min puis en 5 min. Batterie du Mac toujours correcte (`abt` : 100 %, en charge).
- `eaf2b92` : plus de scan si aucune des options AirPods/BT, iOS par BLE et BLE générique n'est active.
- `87b86c6` (D-011) : un scan par intervalle de rafraîchissement. Mesuré : scans à 18:31:07 (15,7 s, démarrage), puis 18:32:07, 18:33:07, 18:34:07, 18:35:07, de 5,0 à 5,25 s chacun, soit **≈ 9 %**. Souris, iPhone et Watch relus à chaque scan (`abt --json` : `update` ≤ 1 min).
- Test de Côme : AirPods invisibles boîtier fermé (déjà le cas avant), **visibles en 45–60 s à l'ouverture**, stables en utilisation.

**Échecs / corrections :**
- **Correction d'une affirmation faite à Côme** : j'avais dit que les AirPods connectés au Mac étaient lus via `system_profiler`, sans le scan. C'est faux : `MagicBattery.getAirpods()` existe mais n'est plus appelé depuis le commit upstream `5991915` (2024). Les AirPods dépendent uniquement du scan BLE. Corrigé auprès de Côme avant sa décision finale.
- Mesure de `system_profiler` : ma première commande redirigeait mal la sortie (`2>&1 >/dev/null`) et a affiché le JSON complet (adresses MAC, numéros de série) dans la session. Rien n'a été écrit dans le dépôt.

**Décisions :** D-011.
**Testé sur appareil réel :** oui, par Côme (AirPods Pro) ; mesures par Claude.
**Prochaine étape :** PR sur le fork.
