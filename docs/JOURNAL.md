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

---

## 2026-10-21 (suite 12) — Interface Liquid Glass

**Contexte :** macOS 27.0.1 (26A434), branche `ui/liquid-glass` depuis `main` @ `21aa862`.
**Objectif :** soucis d'UI signalés par Côme : « ce n'est pas du Liquid Glass », coins mal arrondis.

**Fait :**
- Lecture du code : le menu est un `NSPopover` système (`togglePopover`, ancre masquée par `shouldHideAnchor`) qui contient la vue SwiftUI `popover`. La liste est entourée d'un cadre gris à coins de 4 pt, les lignes ont des coins de 2,9 pt. Pas d'option de compatibilité de design ; `DTSDKName` = `macosx27.0`.
- PR upstream #200 lue : non reprise (UPSTREAM.md, D-012).
- SDK 27 : `ConcentricRectangle`, `containerShape`, `glassEffect` et `GlassEffectContainer` sont disponibles (macOS 26+). Finalement non utilisés : un rayon mesuré suffit et reste lisible.
- Itérations sur captures de Côme, mesurées en recadrant/agrandissant avec `sips` (Retina ×2) :
  1. rayon du popover ≈ 18 pt ; liste en retrait de 5,5 pt → carte remplie à 13 pt de rayon, lignes à 12 pt (`68c4b83`) ;
  2. capture au-dessus d'un fond coloré : le popover **est** en Liquid Glass (fond flouté visible) ; boutons à 4,5/7,5 pt du bord, donc dans la courbe → recentrés sur l'arc (≈ 18 pt des bords), marge du bas égalisée ;
  3. comparaison avec BetterDisplay et Parcel : écart barre des menus → popover de 9,5 pt chez nous contre 2,5–3 pt chez eux → popover remonté de 7 pt sur macOS 26+ (`8604193`).
- Côme valide le rendu, et préfère ne pas reprendre les autres écarts relevés (icônes, taille du texte, séparateurs, carte), consignés dans `IDEAS.md`.

**Échecs :** —
**Décisions :** D-012.
**Testé sur appareil réel :** oui, par Côme (captures, mode clair et sombre).
**Pistes ouvertes :** fenêtre « Dock » (`fromDock`) et alertes (`BatteryAlertView`) pas revues ; décalage de 7 pt non vérifié sur une barre de 24 pt.
**Prochaine étape :** PR sur le fork, fusion demandée par Côme.

---

## 2026-10-21 (suite 13) — Release 1.7.0 (pre-release)

**Contexte :** macOS 27.0.1 (26A434), Xcode 27.1, branche `release/1.7.0` depuis `main` @ `5c166c4`.
**Objectif :** première release du fork, demandée par Côme.

**Fait :**
- Configuration Release vérifiée : compile, binaire universel (`x86_64 arm64`), signé `PCH7VR8GPS`, hardened runtime, sans `SUFeedURL`.
- Choix de Côme (D-013) : 1.7.0, DMG, pre-release, `AirBattery Plus.app`.
- `d9cb557` : `MARKETING_VERSION` 1.6.3 → 1.7.0, `CURRENT_PROJECT_VERSION` 163 → 170 (app et widget ; le helper garde sa propre version).
- `900e8f5` : encart « fork » dans le README (AGPL, lien vers l'original, macOS 12+, téléchargements depuis le fork) et `CHANGELOG.md` en anglais, avec crédits aux PR upstream #216 (son auteur), #214 (Moyuin-aka), #161, #162, #163, #177. `9925e69` : mention du nom de fichier.
- Build Release propre (`clean build`, `build/DerivedData-release`). DMG avec `hdiutil create -format UDZO` (app + raccourci Applications), vérifié avec `hdiutil verify` et monté pour un `codesign --verify --deep --strict`. SHA-256 `980cea67bdefff8a73a0766134d88b346041b4950d34f90a663219a21007f45e`.
- Premier DMG refait : l'app s'appelait `AirBattery.app` et aurait écrasé l'officielle dans Applications.
- Test de Côme : installation depuis le DMG dans Applications, menu, widget et version 1.7.0 OK.
- Tag annoté `v1.7.0` sur `9925e69`, poussé. Pre-release publiée : https://github.com/MsieurPafi/AirBattery/releases/tag/v1.7.0 (DMG + `.sha256`). DMG retéléchargé avec `gh release download` : même SHA-256.

**Échecs :** —
**Décisions :** D-013.
**Testé sur appareil réel :** oui, par Côme (DMG installé dans Applications). Gatekeeper non testé sur un DMG *téléchargé* (pas de quarantaine sur un fichier créé localement).
**Pistes ouvertes :** la copie de développement (`build/DerivedData`) et l'app installée ont le même bundle ID ; ne lancer que l'une des deux.
**Prochaine étape :** correctifs de la 1.6.5 de callieskye.

---

## 2026-10-21 (suite 14) — Correctifs de callieskye : inventaire et lot 1 (robustesse)

**Contexte :** macOS 27.0.1 (26A434), branche `port/callie-1-robustness` depuis `main` @ `8379500`.
**Objectif :** inventorier la 1.6.5 de callieskye, puis porter les correctifs par lots (validé par Côme).

**Fait :**
- Inventaire complet dans `UPSTREAM.md` (diff `134e02f..callie/main`, 24 fichiers, +2 230/−557). Affirmations vérifiées sur le Mac de Côme : #80 sans objet (clé déjà présente), `grep "\d"` fonctionne sur macOS 27, `MaxCapacity` = 100 dans `AppleSmartBattery` (un pourcentage), `CycleCount` = 301 au premier niveau.
- Lot 1 :
  - `6ea85bb` : `IDeviceBattery.parseBattery()`, plus de `Int(…)!` / `Bool(…)!` / `.first!` ; `comptest` limité à 15 s. Testé isolément (code extrait du fichier) : format documenté → `95% charging=false` ; champ manquant, valeur non numérique, sortie vide → `nil` ; espaces tolérés ; 140 → 100. L'iPhone n'était pas joignable en Wi-Fi à ce moment-là (`idevice_id -n` vide) : pas d'échantillon réel.
  - `f64e3bc` : plus de force-casts dans `BTDBattery` (lignes de `logReader.sh`) ni dans `MagicBattery` (system_profiler, IORegistry) ; garde « fabricant Apple » dans `getAirpods()` (#106).
  - `7dd363b` : niveaux AirPods bornés à 100 (#76).
- Build Debug OK, sans nouveau warning.

**Échecs :** —
**Testé sur appareil réel :** non. Lot sans changement de comportement visible ; testé par analyse statique et tests isolés.
**Prochaine étape :** lot 2 (rafraîchissement).

---

## 2026-10-21 (suite 15) — Lots 2 à 4 de callieskye : rafraîchissement, batterie du Mac, Bluetooth

**Contexte :** macOS 27.0.1 (26A434), branches empilées `port/callie-2-refresh` → `port/callie-3-mac-battery` → `port/callie-4-bluetooth` (sur `port/callie-1-robustness`).

**Vérifications avant de porter (sur le Mac de Côme) :**
- #91 : avec l'app installée (1.7.0), menu fermé, relevés `abt --json` toutes les 75 s : Watch 76 → 82 → 83 %, `update` 0 à −1 min. La vue `MultiBatteryView` (Dock) fait bien tourner ses minuteurs sans icône dans le Dock : #91 **non reproduit**. Par contre, `IDeviceBattery.scanDevices()` y était appelé toutes les 5 s (`dockTimer`), sans limitation propre.
- #78 : `return` au lieu de `continue` confirmé dans `batteryAlert()`.
- Lots 3 et 4 : registre de la batterie, logs `bluetoothd` (12 h) et format `CBPowerSource` relevés (COMPAT.md notes 5 et 6, UPSTREAM.md).

**Fait :**
- Lot 2 : `b7757d0` (minuteur de 15 s pour les appareils iOS), `d069d4e` (#78).
- Lot 3 : `020bf44` (pourcentage via `IOPowerSources`).
- Lot 4 : `2d29f99` (#132/#178), `985e256` (#172).
- Non repris, avec preuves : Bose/#91 partie BT, #137, santé/cycles (#152). Voir UPSTREAM.md.

**Test groupé** (Côme a autorisé l'arrêt de son app installée ; build Debug PID 35965) :
- Rafraîchissement menu fermé (`abt --json` à 19:56:45, 19:57:56, 19:59:07) : iPhone, souris, AirPods à jour ; Watch 89 → 91 % (en charge). Mac 100 %, comme `pmset -g batt`. Aucune erreur ou faute de l'app.
- Comptage des lancements de `idevice_id` par échantillonnage `ps` (4/s) : **non concluant**, les processus sont trop brefs pour être vus. Le passage de 5 s à 15 s repose sur le code.
- `comptest` a planté pendant le test (COMPAT note 5) sans effet sur l'app.
- BLE générique (Côme a coché « Discover more BLE devices ») : journaux `bluetoothd` sur 4 min. 6 périphériques connectés à 20:00:36, **déconnectés à 20:00:44** ; aucun n'est recontacté aux scans de 20:01, 20:02 et 20:03 ; 3 nouveaux à 20:02:37, déconnectés 8 s plus tard. Seul l'iPhone autorisé (#214) se reconnecte chaque minute. Aucune demande d'appairage (seulement des `RetrievePairedPeersWithOptions`). Aucun de ces périphériques n'exposait de batterie.

**Échecs :** comptage des processus par `ps`, non concluant (voir ci-dessus).
**Testé sur appareil réel :** oui (Côme + mesures de Claude).
**Prochaine étape :** PR des lots 2 à 4 ; lot 5 (icônes et interface).

---

## 2026-10-21 (suite 16) — Lots 1-4 fusionnés ; lot 5 de callieskye (icônes et interface)

**Contexte :** macOS 27.0.1 (26A434). PR #9 → #12 fusionnées dans l'ordre par Claude, avec l'accord de Côme (bases de #10 à #12 repointées sur `main` avant fusion) : `main` @ `c2c8869`. Branche `port/callie-5-icons-ui`.

**Fait :**
- `d17f054` : icônes AirPods 4 ANC (#166, « 201B » → « 201b »), AirPods Max (#204/#205, nom contenant « airpods max »), MacBook Neo (#195, type `macbookneo` + `Mac17,5`).
- `6db2a6a` : survol de la liste Nearcast (#159).
- `27f28da` : icône d'un appareil épinglé mise à jour quand elle change (cache `pinnedIcons`, vidé au désépinglage) ; `autosaveName` stable pour l'icône principale et les épinglées (#182).
- Non repris : icône Pro par défaut, Siri Remote (image manquante), texte de survol (UPSTREAM.md).
- Test : Côme épingle la MX Anywhere 3 et la déplace (⌘-glisser) ; après relance, icône principale et épinglée **restées en place**. Découverte : Thaw identifiait l'icône épinglée par son texte « 85% » (COMPAT note 7).

**Échecs :** —
**Testé sur appareil réel :** oui (épinglage, position). Icônes AirPods 4/Max et MacBook Neo non testables (matériel absent).
**État laissé :** build Debug en cours d'exécution à la place de l'app installée (1.7.0) ; option « Discover more BLE devices » encore activée depuis le test du lot 4 (réglage partagé avec l'app installée).
**Prochaine étape :** PR du lot 5 ; choix des fonctions par Côme.

---

## 2026-10-21 (suite 17) — Release 1.7.1 (pre-release)

**Contexte :** macOS 27.0.1 (26A434), Xcode 27.1, branche `release/1.7.1` depuis `main` @ `911c3bd` (lots 1 à 5 de callieskye).

**Fait :**
- `01fa83e` : version 1.7.1 (171), section 1.7.1 du `CHANGELOG.md`.
- Build Release propre ; vérifié : 1.7.1 (171), universel, signé `PCH7VR8GPS`, pas de `SUFeedURL`, `codesign --verify --deep --strict` OK (dans `build/` et dans le DMG monté).
- DMG `AirBattery-Plus-1.7.1.dmg` (même procédure que 1.7.0, D-013), SHA-256 `dd0a614b42dc924dbcf1d48e366c2e3756ef77f86a34d38ef2aaacfc4f51654c`.
- Test de Côme : la 1.7.1 remplace la 1.7.0 dans Applications ; menu, widget et version 1.7.1 OK.
- Tag annoté `v1.7.1` sur `01fa83e`, poussé. Pre-release publiée : https://github.com/MsieurPafi/AirBattery/releases/tag/v1.7.1 (notes reprises du changelog, numéros upstream en police de code). DMG retéléchargé : même SHA-256.

**Échecs :** —
**Décisions :** — (procédure D-013)
**Testé sur appareil réel :** oui, par Côme.
**Note :** la bascule du mode économie d'énergie de callieskye (#117/#129) passe par `pmset -a lowpowermode`, qui exige les droits administrateur ; elle est déconseillée à Côme (refus silencieux sans privilèges).
**Prochaine étape :** première fonction choisie par Côme : tri de la liste par batterie (#56, #188).

---

## 2026-10-21 (suite 18) — Tri des appareils, nom affiché « AirBattery Plus »

**Contexte :** macOS 27.0.1 (26A434). Branches `feat/sort-devices` et `feat/display-name`, toutes deux depuis `main` @ `4349726`.

**Fait :**
- Vérification de début de session : aucun crash d'AirBattery ; **3 crashs de `comptest`** aujourd'hui (19:56, 20:06, 20:37), même pile qu'en COMPAT note 5. C'est plus fréquent que « une fois par jour » (#198), pendant des tests qui relançaient souvent le scan.
- **Tri** (`63fdc33`, choisi par Côme ; réglage dans Réglages › Menu Bar & Dock, appliqué au menu, au Dock et au widget) : `AirBatteryModel.sortForDisplay()`. Testé : les 4 ordres via `abt --csv` (qui lit le fichier écrit par `writeData()`, donc le tri du widget) ; regroupements testés isolément sur le code extrait (Watch avec iPhone, écouteurs avec boîtier, périphériques du Mac triés à part, parent absent, sans batterie en dernier). Côme : « le tri fonctionne bien ». Il a signalé « iPhone avant MacBook » comme un problème de casse : c'est en fait l'ordre alphabétique correct (I < M), et la preuve que le tri ignore la casse (`localizedStandardCompare`).
- Incident de test : `pkill -TERM -f "A\|B"` n'a rien arrêté (`pkill` lit `\|` comme un « | » littéral). La version de test tournait donc depuis 20:33, et son icône était sans doute masquée par Thaw ; en lançant la 1.7.1, Côme a réactivé l'instance déjà ouverte (même bundle ID). Échantillon `sample` : fil principal au repos, pas de blocage.
- **Widget « qui ouvre l'autre app »** : `pluginkit` → seulement deux widgets, `com.lihaoyun6.AirBattery.widget` (officielle) et `io.github.msieurpafi.AirBattery.widget` (1.7.1 dans Applications). Les deux apps ont `CFBundleName` = « AirBattery », sans nom d'affichage, et la galerie montre deux « AirBattery » identiques. Ce n'était pas une erreur de Côme.
- **Nom affiché** (`1352a0f`, D-014).

**Échecs :** ajout de `CFBundleName` dans `AirBattery/Info.plist` → sans effet (valeur générée depuis `PRODUCT_NAME` prioritaire), retiré.
**Testé sur appareil réel :** tri oui (Côme) ; nom affiché à vérifier dans la galerie une fois installé dans Applications (la galerie suit la copie enregistrée par PlugInKit, ici `/Applications/AirBattery Plus.app`).
**Prochaine étape :** fusion des deux PR, puis 1.7.2 (DMG testé par Côme avant publication).

---

## 2026-10-21 (suite 19) — Release 1.7.2 : tri des appareils et nom « AirBattery Plus »

**Contexte :** macOS 27.0.1 (26A434), Xcode 27.1. PR #15 (tri) et #16 (nom affiché) fusionnées par Claude avec l'accord de Côme (`main` @ `96f35b9`). Branche `release/1.7.2`.

**Fait :**
- `9ad27ee` : version 1.7.2 (172) et changelog.
- Premier DMG : la galerie montrait toujours deux « AirBattery ». LaunchServices nommait pourtant le fork « AirBattery Plus » (nom d'affichage et nom de fichier). Diagnostic : la galerie lit `CFBundleName`. Essais sans effet : clé `CFBundleName` dans `Info.plist` (écrasée par la valeur générée), réglage `INFOPLIST_KEY_CFBundleName` (ignoré).
- `58d70e4` (D-015) : `PRODUCT_NAME = "AirBattery Plus"` pour la cible app, `PRODUCT_MODULE_NAME = AirBattery`. Vérifié dans le binaire : classes AppleScript `_TtC10AirBattery7listAll`… inchangées.
- Deuxième DMG : le widget du fork **disparaît** de la galerie. Cause : PlugInKit avait choisi l'extension de la copie de **compilation** (`build/DerivedData-release/…/AirBattery Plus.app`, enregistrée au build) ; NotificationCenter journalise alors « Remove widgets belonging to extension … from storage ». Correctif : `pluginkit -r` + `lsregister -u` sur les copies de `build/`, `pluginkit -a` + `lsregister -f` sur `/Applications/AirBattery Plus.app`, suppression de `build/DerivedData-release` et de `build/dist/stage`. Le widget revient, avec la description « … from AirBattery Plus ».
- Barre latérale encore sur « AirBattery » : nom gardé en mémoire par NotificationCenter (lancé à 14:47). `killall NotificationCenter` avec l'accord de Côme → relancé automatiquement → « **AirBattery Plus** » affiché (confirmé par Côme).
- Tag `v1.7.2` sur `80b4142` (le DMG vient de `58d70e4` ; seule la doc diffère). Pre-release publiée : https://github.com/MsieurPafi/AirBattery/releases/tag/v1.7.2. SHA-256 `bbdc35ce41687a19265e5d1ff4d118ac0e38f285c7cd99b41bd01ac61b56d91d`, identique après retéléchargement. Les notes conseillent de se déconnecter si la galerie garde l'ancien nom.

**Échecs :** voir ci-dessus (deux tentatives sur `CFBundleName`, puis l'extension choisie dans la copie de build).
**À retenir :** une copie compilée dans `build/` (Debug ou Release) est enregistrée par LaunchServices et PlugInKit, et peut **prendre la place** de l'app installée pour le widget. Après un build Release, la désenregistrer ou supprimer le dossier ; ne pas laisser traîner de `build/dist/stage`.
**Testé sur appareil réel :** oui, par Côme (galerie, widget, tri).
**Prochaine étape :** autres fonctions de callieskye au choix de Côme ; reste de la tâche identité ; mises à jour GitHub / CI.

---

## 2026-10-21/22 (suite 20) — libimobiledevice recompilée ; cause de #198

**Contexte :** macOS 27.0.1 (26A434), Xcode 27.1. Branche `compat/libimobiledevice-rebuild` depuis `main` @ `a38f75a`.

**Fait :**
- `bd6e331` : fonctions restantes de callieskye marquées « non retenues » (décision de Côme).
- État des lieux : outils présents (clang, make, perl, pkg-config, Homebrew ; **pas** d'autoconf/automake). Binaires de 2024 : `1.3.0-210-g73b6fd1`, OpenSSL 3.2.1, `minos 14.0`.
- `comptest` : le gist de nikias ne correspond **pas** au binaire de 2024 (qui affichait l'UDID complet de la montre et lisait `DeviceName`, d'après `strings`). Copie adaptée dans `scripts/libimobiledevice/comptest.c`, origine en en-tête.
- Script `scripts/build-libimobiledevice.sh`. Échecs successifs, chacun corrigé :
  1. `configure: error: Package requirements (libtatsu-1.0 >= 1.0.3) were not met` → libtatsu 1.0.5 ajoutée (signalé à Côme).
  2. `Package requirements (libcurl >= 7.0) were not met` : variables passées en environnement sans effet → passées en arguments de `configure` (libcurl du SDK).
  3. `wificonnection.c:96:33: error: use of undeclared identifier 'PACKAGE_VERSION'` → `-DPACKAGE_VERSION='"1.4.0"'`.
  4. `libcrypto` contenait le chemin du dossier de build (`…/prefix-arm64/ssl/…`) → OpenSSL compilé pour un préfixe neutre `/usr/local/airbattery-openssl` puis installé via `DESTDIR`.
- Résultat (`3cb0e62`) : 5 outils + 6 bibliothèques universels, `minos 12.0`, dépendances en `@executable_path/../lib/`, signés ad hoc, aucun chemin personnel, licences et `VERSIONS.txt` livrés.
- Test : iPhone et Watch relus **en Wi-Fi** avec les nouveaux outils.
- 12:48 et 12:52 : crash du **nouveau** `comptest` (SIGABRT dans `idevice_free`). Lecture du source : `idevice_t device;` non initialisé + résultat de `idevice_new_with_options` ignoré, alors que la fonction ne remplit pas `device` en cas d'échec (vérifié dans `src/idevice.c` de 1.4.0). **Cause de #198.** Corrigé dans `5b4cf12`.
- Côme : demande « autoriser AirBattery Plus à rechercher des appareils sur les réseaux locaux » au réveil → cause : autorisation liée à l'UUID de l'exécutable (`nehelper`), qui change à chaque compilation (COMPAT note 8).
- Test USB (Côme, 13:09) : iPhone relu et passé en « en charge » pendant le branchement ; Watch à jour ; aucun crash de `comptest` depuis 13:06.

**Échecs :** voir les 4 étapes de compilation ci-dessus. L'échantillonnage `ps` (0,1 s) ne capte pas les outils, trop brefs.
**Décisions :** D-016.
**Testé sur appareil réel :** oui, par Côme (iPhone 17 en Wi-Fi et USB, Apple Watch).
**Pistes ouvertes :** surveiller les crashs de `comptest` sur plusieurs jours ; mentionner l'autorisation réseau local dans les notes de version.
**Prochaine étape :** PR, puis release 1.7.3.

---

## 2026-10-22 (suite 21) — Release 1.7.3 (pre-release)

**Contexte :** macOS 27.0.1 (26A434), Xcode 27.1. PR #18 fusionnée avec l'accord de Côme (`main` @ `0c7df16`). Branche `release/1.7.3`.

**Fait :**
- `d62d71b` : version 1.7.3 (173) et changelog (correctif `comptest`/#198, outils recompilés, note sur l'autorisation réseau local redemandée à chaque mise à jour).
- Build Release propre : 1.7.3 (173), `CFBundleName` « AirBattery Plus », pas de `SUFeedURL`, `codesign --verify --deep --strict` OK, `ideviceinfo 1.4.0`, 7 fichiers de licence embarqués.
- DMG construit depuis un dossier temporaire du scratchpad (plus de `build/dist/stage`), puis copies de build désenregistrées (`pluginkit -r`, `lsregister -u`) et `build/DerivedData-release` supprimé **avant** l'installation par Côme : un seul widget du fork enregistré (`/Applications`).
- Test de Côme : 1.7.3 installée, version 1.7.3, iPhone, Watch et widget OK.
- Tag `v1.7.3` sur `d62d71b` (commit compilé). Pre-release publiée : https://github.com/MsieurPafi/AirBattery/releases/tag/v1.7.3. SHA-256 `bdc98bbf1d10b1573f6be4acedafb21c2809666ee35a34ae5c229b3ee033790a`, identique après retéléchargement.
- Crashs : aucun nouveau rapport `comptest` depuis le correctif (derniers : 12:48 et 12:52, avant `5b4cf12`).

**Échecs :** —
**Testé sur appareil réel :** oui, par Côme.
**Prochaine étape :** surveiller `comptest` sur plusieurs jours ; reste de la tâche identité (README, crédits, textes d'aide dont `NSLocalNetworkUsageDescription`) ; mises à jour GitHub / CI.

---

## 2026-10-23 — Relevé des logs, icône de l'iPhone Duo

**Contexte :** macOS 27.0.1 (26A434), Xcode 27.1, `main` @ `b13b907`. Branche `feat/iphone-duo-icon`.

**Fait :**
- Crashs : **aucun rapport** depuis le correctif de `comptest` (`5b4cf12`) ; derniers rapports le 2026-10-22 à 12:48 et 12:52, avant le correctif. 1.7.3 lancée depuis ~21 h, RSS ~89 Mo, 0 `EXC_GUARD`.
- Bruit dans les logs sur 24 h (non investigué) : 897 `Cannot create IOBluetoothDevice`, 149 « No name or address », 145 `handlePeerDisconnectionCompleted`, 58 CoreBluetooth « API MISUSE … can only accept this command while in the powered on state », 25 messages AppKit.
- Nouvel iPhone de Côme : **iPhone Duo**, modèle `iPhone19,4`, vu comme type « iPhone » avec l'icône générique. Pas de symbole Duo dans le catalogue SF Symbols de macOS 27.
- Icône `iphone.duo` dessinée d'après l'icône officielle envoyée par Côme (celle qu'affiche l'iPhone) : format presque carré, petits rayons côté charnière (gauche), grands rayons à droite, caméra en haut à droite, barre en bas. Même style que `iphone.svg` (gabarit, contour 0,85, écran 0,2125). Générée par un petit script (courbes de Bézier, pas d'arcs SVG).
- `getDeviceIcon` : `iPhone19,4` → `iphone.duo`. Build OK, image présente dans `Assets.car`. Copie de build désenregistrée (`pluginkit -r`, `lsregister -u`) ; seul le widget de `/Applications` reste enregistré.

**Échecs :** —
**Testé sur appareil réel :** oui, par Côme (21:40) : la version de test voit l'iPhone Duo (`iPhone19,4`) et affiche la nouvelle icône dans le menu. Ensuite : copie de build désenregistrée, 1.7.3 de `/Applications` relancée.
**Pistes ouvertes :** l'Apple Watch n'apparaît plus depuis l'appairage de l'iPhone Duo (sans doute à re-autoriser en USB avec le nouvel iPhone) ; bruit de logs ci-dessus.
**Prochaine étape :** fusion de la PR #20.
