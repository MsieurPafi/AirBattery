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

---

## 2026-10-25 — Icône Duo absente, Apple Watch disparue, bruit des logs

**Contexte :** macOS 27.0.1 (26A434), Xcode 27.1, `main` @ `e828441`. Branche `docs/session-2026-10-25`. App installée : 1.7.3, lancée depuis 41 h, RSS 48 Mo.

**Fait :**
- Crashs : aucun nouveau rapport depuis le 2026-10-22 12:52 (avant le correctif de `comptest`).
- Icône de l'iPhone Duo « pas utilisée » (Côme) : normal, l'app installée est la 1.7.3 et son `Assets.car` ne contient pas `iphone.duo` (`assetutil --info` → 0). L'icône arrivera avec la prochaine release.
- Apple Watch absente : l'iPhone Duo n'est vu qu'en Bluetooth (D-009) ; `idevice_id -l` et `-n` ne renvoient rien. Sans *pair record*, `comptest` ne peut pas joindre la Watch par l'iPhone (COMPAT note 12). Test demandé à Côme : branchement USB, « Se fier », « Afficher cet iPhone en Wi-Fi ».
- Bruit des logs (COMPAT note 11) : les messages IOBluetooth/CoreBluetooth restants sont émis aussi, en même nombre, par des processus système ; les « Cannot create IOBluetoothDevice » et « API MISUSE » ont disparu depuis la fin des tests. Rien à corriger dans le code.

**Échecs :** `ls /var/db/lockdown/` → `Operation not permitted` (dossier protégé, pas de vérification directe des *pair records*).
**Testé sur appareil réel :** non (en attente du branchement de l'iPhone Duo par Côme).
**Pistes ouvertes :** préciser dans l'aide de l'app qu'un iPhone doit être fiable en USB pour la Watch (tâche identité / textes d'aide).
**Prochaine étape :** résultat du branchement USB ; release 1.7.4 (icône Duo) quand Côme le souhaite.

**Ajout (2026-10-25, suite) :** Côme a branché l'iPhone Duo en USB, l'a déclaré fiable et a activé l'affichage en Wi-Fi. `idevice_id -l` et `-n` voient maintenant l'iPhone (`00008160-…`), et la **Watch est revenue** dans l'app (`Watch6,7`, 67 %). COMPAT note 12 confirmée.

---

## 2026-10-25 (suite) — Release 1.7.4 (pre-release)

**Contexte :** macOS 27.0.1 (26A434), Xcode 27.1. Branche `release/1.7.4` (empilée sur `docs/session-2026-10-25`, PR #21 fusionnée avec l'accord de Côme : `85fa916`).

**Fait :**
- `os.Logger` passé dans « À faire » de `IDEAS.md` (demande de Côme).
- `4a90be5` : version 1.7.4 (174), changelog (icône iPhone Duo ; note « nouvel iPhone, pas de Watch » → COMPAT note 12).
- Build Release propre (`build/DerivedData-release`) : 1.7.4 (174), `CFBundleName` « AirBattery Plus », pas de `SUFeedURL`, `codesign --verify --deep --strict` OK, `iphone.duo` présent dans `Assets.car`, `ideviceinfo 1.4.0`.
- DMG depuis un dossier temporaire du scratchpad, `hdiutil verify` OK ; copies de build désenregistrées (`pluginkit -r`, `lsregister -u`) et `build/DerivedData-release` supprimé avant l'installation : un seul widget enregistré.
- Test de Côme : 1.7.4 installée, icône du Duo affichée. Widget 1.7.4 enregistré depuis `/Applications`.
- Tag `v1.7.4` sur `4a90be5`. Pre-release publiée : https://github.com/MsieurPafi/AirBattery/releases/tag/v1.7.4. SHA-256 `931d3f24c128e4c3f25aa3b5a3a34f781b89dfc8ca37e5cdc41cd5238e3fafd7`, identique après retéléchargement.

**Échecs :** — (avertissement : `hdiutil create -volname -format …` est déprécié sous macOS 27, « Please use 'diskutil image create from/blank …' » ; DMG valide, à reprendre pour le CI.)
**Testé sur appareil réel :** oui, par Côme.
**Pistes ouvertes :** identité du projet — liste de questions soumise à Côme (public ou non, « Plus » partout ou non, icône, nom de `abt`, copyright et crédits, traductions, liens upstream) ; rien d'écrit avant d'en avoir discuté (demande de Côme).
**Prochaine étape :** discussion sur l'identité.

---

## 2026-10-25 (suite 2) — Identité « AirBattery Plus » : nom, textes, `abtp`, README

**Contexte :** macOS 27.0.1 (26A434), Xcode 27.1, `main` @ `3a23eb3`. Branche `feat/identity-name`.

**Fait :**
- Réponses de Côme aux 7 questions → **D-017** (projet public sans promotion ; « Plus » partout ; `abtp` ; copyright et crédits ; liens vers l'original regroupés ; icône et traductions en sujets à part, ajoutés dans IDEAS « À faire »). D-002 marquée « nom remplacé par D-014, D-015 puis D-017 ».
- Constat : la commande installée n'était pas `abt` mais **`airbattery`** (lien `/usr/local/bin/airbattery`, même nom que l'app officielle) ; `abt` n'était que le nom du fichier dans l'app.
- `bfcd1b0` : « AirBattery Plus » dans les demandes d'autorisation (Bluetooth, réseau local), réglages, astuces, À propos (lien vers le fork + « Based on AirBattery by lihaoyun6 ») ; copyright `© 2024 lihaoyun6, © 2026 Côme Bouquet.` (sans « All rights reserved », contradictoire avec l'AGPL). Traductions chinoises : clés mises à jour, seul le nom remplacé dans le texte ; `plutil -lint` OK ; aucune clé contenant « AirBattery » orpheline sauf « Quit AirBattery Plus » (déjà inutilisée).
- `e31d3db` : outil en ligne de commande renommé **`abtp`** (`PRODUCT_NAME = abtp`, lien `/usr/local/bin/abtp`, `commandName` et résumé dans `--help`). L'ancien lien `airbattery` est supprimé à l'installation ou la désinstallation **seulement** s'il pointe vers `…/AirBattery Plus.app/Contents/Resources/abt`. Vérifié : `abtp --help` et `abtp` (liste des appareils) depuis la copie de build. Installation/désinstallation **non testées** (mot de passe administrateur).
- `534bcae` : README réécrit (en-tête, installation du fork seulement, `abtp`, Q&R à jour dont la Watch avec un nouvel iPhone et « Manage », crédits : lihaoyun6 et son lien de dons, #216 @R0cketBean, #214 @Moyuin-aka, #161–163 @barkleesanders, #177 @leo1425, callieskye, bibliothèques ; licence) ; bandeau en anglais sur `README_zh.md` ; 28 liens « upstream #N » dans le changelog ; entrée « Unreleased ».
- Build Debug OK ; copie de build désenregistrée (seul le widget 1.7.4 de `/Applications` reste).

**Échecs :** —
**Testé sur appareil réel :** non (à faire par Côme : À propos, demandes d'autorisation, installation de `abtp`).
**Pistes ouvertes :** l'alignement des colonnes de `abtp` est faux avec des noms accentués ou des emojis (préexistant) ; mention éventuelle de Claude Code dans les crédits du README (au choix de Côme, comme la ligne ChatGPT de l'original).
**Prochaine étape :** relecture et test par Côme, puis fusion ; ensuite l'icône.

**Ajout (2026-10-25, suite 2) :** test de Côme sur la copie de build : fenêtre À propos, installation de `abtp` depuis les réglages, `abtp`, `abtp --help`, désinstallation et textes des réglages jugés corrects. Ensuite : aucun lien `abtp` ni `airbattery` dans `/usr/local/bin`, copie de build désenregistrée, 1.7.4 de `/Applications` relancée (seul widget enregistré).

---

## 2026-10-25 (suite 3) — Nouvelle icône (B2, Icon Composer)

**Contexte :** macOS 27.0.1 (26A434), Xcode 27.1, `main` @ `9d7de6e` (PR #23 fusionnée avec l'accord de Côme). Branche `feat/app-icon`.

**Fait :**
- 6 maquettes plates (A1, A2, B1, B2, C1, C2) + l'icône actuelle, rendues avec CoreSVG (`NSImage`) ; Côme choisit **B2**. Premier rendu : contour visible de l'éclair (remplissage et trait semi-transparents qui se superposent) → éclair dessiné à travers un masque.
- B2 affinée : éclair agrandi, « + » aligné en haut à droite ; contrôle à 16, 32, 64, 128, 256 px sur fond clair et sombre (« + » invisible à 16 px, lisible dès 32 px).
- Format Icon Composer reconstitué sans l'interface : modèle de fichier d'Xcode (`Icon Composer Icon.xctemplate/…/icon.json`), clés confirmées dans `IconComposerFoundation`/`IconRendering` (`groups`, `layers`, `image-name`, `glass`, `linear-gradient`, `orientation`, `shadow`, `translucency`…), type de fichier `folder.iconcomposer.icon` (`StandardFileTypes.xcspec`).
- `AirBattery/AppIcon.icon` (fond en dégradé, calques `bolt.svg` et `plus.svg` en verre) ajouté aux ressources de l'app. `actool` produit `IconImageStack` clair, sombre et teinté + `AppIcon.icns`, sans avertissement malgré l'`AppIcon.appiconset` du même nom. Rendu système vérifié avec `NSWorkspace.icon(forFile:)` (Liquid Glass correct).
- PNG de `AppIcon.appiconset` remplacés par la version plate de B2 (macOS 12–25, en-tête du README). Scripts `scripts/icon/make-icon-artwork.py` et `export-pngs.swift`. D-018. Copie de build désenregistrée.

**Échecs :** `iconutil -c iconset` sur l'`AppIcon.icns` généré ne contient que 16 à 128@2x (256 px max) : sans conséquence, le rendu système passe par `Assets.car`.
**Testé sur appareil réel :** rendu système sur macOS 27.0.1 seulement ; macOS 12–25 non testé.
**Pistes ouvertes :** vérifier l'icône dans le Dock et le Finder après installation d'une release (cache d'icônes de LaunchServices).
**Prochaine étape :** avis de Côme, fusion, puis release 1.8.0 (identité + icône).

---

## 2026-10-25 (suite 4) — Release 1.8.0 (pre-release)

**Contexte :** macOS 27.0.1 (26A434), Xcode 27.1. PR #24 (icône) fusionnée avec l'accord de Côme (`main` @ `a2bbcb5`). Branche `release/1.8.0`.

**Fait :**
- `5fa7a79` : version 1.8.0 (180) ; changelog (identité D-017, `abtp`, icône D-018, README ; note sur le cache d'icônes de macOS).
- Build Release propre : 1.8.0 (180), `CFBundleName` « AirBattery Plus », pas de `SUFeedURL`, nouveau copyright et textes d'autorisation, `CFBundleIconName = AppIcon`, 3 `IconImageStack` (clair, sombre, teinté) + `AppIcon.icns`, `abtp` embarqué, `codesign --verify --deep --strict` OK.
- DMG depuis un dossier temporaire du scratchpad, `hdiutil verify` OK ; copies de build (Release, DMG, Debug) désenregistrées et `build/DerivedData-release` supprimé avant l'installation.
- Test de Côme : 1.8.0 installée, nouvelle icône, tout fonctionne. Widget 1.8.0 enregistré depuis `/Applications`.
- Tag `v1.8.0` sur `5fa7a79`. Pre-release publiée : https://github.com/MsieurPafi/AirBattery/releases/tag/v1.8.0. SHA-256 `da0e4167ce3996e55e07fe35096c713dc0a3510246029e5759b5ece145daca2c`, identique après retéléchargement.

**Échecs :** —
**Testé sur appareil réel :** oui, par Côme.
**Prochaine étape :** au choix de Côme : app et doc FR/EN, mises à jour GitHub / CI, `os.Logger`, fenêtre Dock et alertes en Liquid Glass.

---

## 2026-10-25 (suite 5) — Journalisation unifiée (`os.Logger`)

**Contexte :** macOS 27.0.1 (26A434), Xcode 27.1, `main` @ `44c77c9`. Branche `chore/os-logger`.

**Fait :**
- Inventaire : 51 `print` et 3 `NSLog` dans l'app ; 4 `print` dans `abtp` (sortie de la commande, conservés) ; rien dans le widget et le helper.
- `Shared/Log.swift` (8 catégories) et migration de tous les appels (D-019). Le Group ID Nearcast n'est plus journalisé. Nouvel avertissement `process` quand un outil dépasse son délai (nom de l'outil ou du script, jamais ses arguments).
- Échec de compilation à la première tentative : `reference to property 'launchAtLogin' in closure requires explicit use of 'self'` (l'interpolation de `Logger` est une fermeture) → `self.` ajouté. Avertissements de compilation inchangés (6, `kIOMasterPortDefault`, préexistants).
- Test (~1 min, copie de build à la place de la 1.8.0, puis 1.8.0 relancée et widget réenregistré) : `log stream --level debug --predicate 'subsystem == "io.github.msieurpafi.AirBattery"'` montre `Launch at login: true`, `Icon mode: sbar`, le démarrage des scans `ble`, `bluetooth`, `magic`, `idevice`, et une erreur `Notification authorization denied: Notifications are not allowed for this application` (copie de build, chemin différent de l'app installée).

**Échecs :** `open -g "airbattery-plus://writedata"` pendant le test n'a rien journalisé : l'URL a sans doute été confiée à l'app de `/Applications` (gestionnaire du schéma enregistré) plutôt qu'à la copie de build. Non approfondi.
**Testé sur appareil réel :** oui, par Claude (journalisation sur le Mac de Côme).
**Pistes ouvertes :** vérifier dans la prochaine release que l'app installée n'a pas la même erreur d'autorisation des notifications.
**Prochaine étape :** PR, fusion par Côme.

---

## 2026-10-25 (suite 6) — Fenêtre du Dock en Liquid Glass

**Contexte :** macOS 27.0.1 (26A434), Xcode 27.1, `main` @ `9971a5b`. Branche `ui/liquid-glass-dock-alerts`.

**Fait :**
- Alertes : `NSAlert` standard (`createAlert` + `runModal`), déjà en Liquid Glass avec le SDK 27 : vérifié sur capture de Côme (astuce « Displaying AirBattery Plus on the Dock… »). Rien à changer.
- Fenêtre du Dock (`applicationShouldHandleReopen`) : `NSGlassEffectView` (18 pt), ombre, géométrie du popover (`ListMetrics.dockHeaderTopSpacing` = marge du popover + 2,5 pt). D-020.
- 1er essai : hauteur mesurée par `fittingSize` avant affichage → 72 pt (liste vide jusqu'au `onAppear`) ; la fenêtre grandissait ensuite vers le bas et était coupée par le bas de l'écran (capture de Côme, écran externe).
- 2e essai : `sizingOptions = []` + mesure dans la fenêtre → 0 pt (journal : `estimated height 72.000000, fitted 0.000000, frame {{1951, 76}, {353, 0}}`) : fenêtre réduite à un trait.
- 3e essai (retenu) : formule de hauteur existante + marges Liquid Glass, `sizingOptions = []`, fenêtre bornée à l'écran visible. Journal : `Dock window frame {{1938, 76}, {353, 237}}`. Validé par Côme sur les écrans interne et externe.
- Observation : la fenêtre À propos et l'alerte de la copie de build montraient l'**ancienne icône verte**, alors que le Finder, `NSRunningApplication.icon` et le catalogue compilé ont la nouvelle. Hypothèse : cache d'icônes de macOS pour cette copie. À confirmer sur l'app installée.

**Échecs :** voir les essais 1 et 2 ci-dessus.
**Testé sur appareil réel :** oui, par Côme.
**Pistes ouvertes :** icône de l'À propos (ci-dessus).
**Prochaine étape :** PR, fusion par Côme.

**Ajout (2026-10-25, suite 6) :**
- Icône de l'À propos : l'app installée (1.8.0) montre bien la **nouvelle** icône (Côme) → l'ancienne icône verte de la copie de build venait du cache d'icônes de macOS pour ce chemin.
- Côme signale des coins du bas non concentriques dans le **popover de la barre des menus** (1.8.0). Mesure au pixel sur sa capture : 5 pt sur les côtés, **3 pt** en bas entre le bord et la liste. Dans la fenêtre du Dock : ~11 pt en bas (formule de hauteur trop généreuse).
- Correctifs : `popover` reçoit sa liste dès l'initialisation (`State(initialValue:)`), ce qui permet de mesurer la fenêtre du Dock avec `fittingSize` ; marge du bas 9 pt pour le popover (le popover système en masque ~2), 6 puis 8 pt pour la fenêtre du Dock (3 pt mesurés avec 6). Mesures finales : popover 5/5 pt, fenêtre du Dock 6/5 pt (côté/bas). Validé par Côme. D-020 mise à jour.
- Au lancement de la copie de test, l'iPhone apparaissait avec l'icône Bluetooth (appareil BLE générique nommé « iPhone ») avant d'être reconnu : noté dans IDEAS (indexation par nom).
- Copie de build désenregistrée, 1.8.0 relancée (seul widget enregistré).

---

## 2026-10-25 (suite 7) — Documentation, étape 1 : structure

**Contexte :** macOS 27.0.1 (26A434), Xcode 27.1, `main` @ `5e8600c`. Branche `docs/restructure`.

**Fait :**
- État des lieux et recommandations présentés à Côme ; tout validé → D-021.
- Documentation de travail déplacée dans `docs/dev/` (`git mv`, historique conservé) ; références mises à jour dans `CLAUDE.md`, `Sparkle.swift`, `InternalBattery.swift`, `CHANGELOG.md`. Les anciennes entrées de ce journal gardent les chemins `docs/…` d'origine.
- Guide utilisateur anglais `docs/guide/en/` (8 pages : démarrage, appareils, utilisation, Nearcast, `abtp`, réglages, autorisations et confidentialité, dépannage), rédigé d'après le code : valeurs par défaut des `@AppStorage`, textes des réglages, comportement des widgets et de `abtp`. Corrections faites en relisant le code : le menu « Transmit to… » est commenté (retiré du guide) ; le widget mono-appareil se règle par « Edit Widget » à partir de macOS 14 (le réglage n'existe que sous macOS 12–13) ; statut `=` de `abtp` quand la charge est en pause ; aucune requête internet dans le code (vérifié).
- `README.md` raccourci en vitrine ; `CONTRIBUTING.md` (signaler un bogue, compiler, pièges du widget et de l'accès réseau local, organisation du projet, PR, traductions, licence).
- Liens relatifs vérifiés par script : aucun lien cassé. Les liens vers la version française seront ajoutés à l'étape 2.

**Échecs :** —
**Testé sur appareil réel :** sans objet (documentation).
**Prochaine étape :** relecture par Côme, puis étape 2 (traduction française).

---

## 2026-10-25 (suite 8) — Documentation, étape 2 : traduction française

**Contexte :** macOS 27.0.1 (26A434), Xcode 27.1, `main` @ `c86a341` (PR #28 fusionnée avec l'accord de Côme). Branche `docs/french`.

**Fait :**
- `README.fr.md` et `docs/guide/fr/` (9 pages, mêmes noms de fichiers que l'anglais pour que les paires soient évidentes). Liens de langue dans les deux sens sur chaque page ; lien « Français » dans l'en-tête du `README.md` ; `CONTRIBUTING.md` mis à jour (règle des deux langues).
- Termes système en français tels que macOS et iOS les affichent (« Réglages Système › Confidentialité et sécurité », « Ouvrir quand même », « Se fier », « Afficher cet iPhone en Wi-Fi », « Partage de connexion », « Modifier le widget »). Les réglages de l'app restent nommés en anglais, comme elle les affiche aujourd'hui : à passer en français à l'étape 3 avec la traduction de l'app.
- Typographie française par script : espace insécable avant « : ; ! ? » et avant « % », hors blocs et extraits de code (84 lignes).
- Petite correction de l'anglais : mention « in English or French » pour les issues.
- Vérification par script : aucun lien relatif ni ancre cassés (ancres générées à la manière de GitHub), mêmes pages en anglais et en français.

**Échecs :** —
**Testé sur appareil réel :** sans objet.
**Prochaine étape :** relecture par Côme (français), puis étape 3 : app en français à partir de la PR upstream #170 + String Catalog.

---

## 2026-10-25 (suite 9) — Documentation, étape 3 : l'app en français, String Catalogs

**Contexte :** macOS 27.0.1 (26A434), Xcode 27.1, `main` @ `a1ae6cb` (PR #29 fusionnée avec l'accord de Côme). Branche `feat/french-localization`.

**Fait :**
- Inventaire : `Localizable.strings` partagé par l'app et le widget (zh-Hans, zh-Hant : 177 phrases), `InfoPlist.strings` (2), `Credits.rtf` ; `LOCALIZATION_PREFERS_STRING_CATALOGS` et `SWIFT_EMIT_LOC_STRINGS` déjà actifs. PR #170 (leo1425) : 149 phrases sur d'anciennes clés.
- « il y a X min » en une seule chaîne de format (`"%d mins ago"`, correctif de #170). Faute de frappe `"Cancle"` corrigée en `"Cancel"` (menu de débogage).
- Catalogues créés par script (`.strings` convertis avec `plutil`, clés de #170 renommées), puis `xcrun xcstringstool sync` avec les `.stringsdata` de l'app et du widget : +37 phrases extraites du code. 17 phrases absentes du code retirées, 12 marquées « ne pas traduire ». Contrôle des spécificateurs de format (`%@`, `%d`, `%lld`) : identiques dans toutes les langues.
- Traduction française complète (186 phrases) et relue ; `InfoPlist.xcstrings` (demandes Bluetooth et réseau local en français) ; `fr.lproj/Credits.rtf`. D-022.
- Projet : `fr` dans `knownRegions`, références des catalogues à la place des groupes de variantes `.strings`. Build OK : `fr.lproj` dans l'app et le widget (186 phrases, `InfoPlist.strings`, `Credits.rtf`) ; chinois toujours compilé (160 phrases).
- Test de Côme sur la copie de build (macOS en `fr-FR`) : « parfait ». Copie de build désenregistrée, 1.8.0 relancée.
- Guide français : noms des réglages remplacés par leurs noms français (d'après le catalogue), liens et ancres revérifiés.
- Questions de Côme : comment l'app choisit sa langue (préférences de langue de macOS, puis anglais ; réglage par app possible) ; la fréquence du widget dépend-elle de celle de Proximité (notée dans IDEAS, non creusée à sa demande).

**Échecs :**
- Crédits français : premier rendu sans la phrase d'accroche ni « Dérivé d' » : la police était déclarée avec `\fcharset134` (chinois), qui écrase la code page 1252 → `\fcharset0`.
- `grep -rnF … --include='*.swift'` comptait aussi les `.strings` (`grep` est un alias d'`ugrep`, qui ignore `--include` ici) : vérification refaite en Python.

**Testé sur appareil réel :** oui, par Côme (app en français).
**Prochaine étape :** PR ; puis étape 4 (captures d'écran) et une release.

---

## 2026-10-25 (suite 10) — Documentation, étape 4 : captures d'écran

**Contexte :** macOS 27.0.1 (26A434), Xcode 27.1, `main` @ `7b6804c` (PR #30 fusionnée avec l'accord de Côme). Branche `docs/screenshots`.

**Fait :**
- Impossible de capturer l'écran moi-même (pas d'autorisation d'enregistrement de l'écran) : captures faites par Côme.
- Mode démo Debug (`-demoDevices YES`, D-023) : huit appareils neutres, vrais appareils masqués, Mac nommé « MacBook Pro ».
- 1er essai : les widgets montraient les vrais appareils (instantané gardé : la demande de rechargement venait de la copie de test) → widgets retirés et rajoutés. 2e essai : la ligne « iPhone » était le vrai iPhone Duo de Côme (indexation par nom) et les captures étaient en 1x (écran externe) → appareils de démo renommés (« iPhone 16 Pro », « iPad Pro »), captures refaites en 2x (mode HiDPI de BetterDisplay). Popover clair gris opaque (131/255) en capture « fenêtre », même sur fond blanc : le verre est rendu sans arrière-plan → capture par zone sur fond clair, découpe au masque arrondi (rayon 36 px en 2x, bord détecté au pixel).
- `img/preview.png` et `img/preview_dark.png` recomposés (grand widget, popover, widgets moyen et petit, marges transparentes rognées), vérifiés sur fond blanc et sur le fond sombre de GitHub. Procédure dans `CONTRIBUTING.md`.
- Observation non creusée (IDEAS) : « connected » journalisé environ une fois par minute dans la catégorie `bluetooth` pendant les tests.
- Copie de test désenregistrée, 1.8.0 relancée avec les vrais appareils.

**Échecs :** voir les trois essais ci-dessus.
**Testé sur appareil réel :** oui (captures de Côme).
**Prochaine étape :** PR, puis release 1.9.0.

---

## 2026-10-25 (suite 11) — Release 1.9.0 (pre-release)

**Contexte :** macOS 27.0.1 (26A434), Xcode 27.1. PR #31 fusionnée avec l'accord de Côme (`main` @ `6b244dd`). Branche `release/1.9.0`.

**Fait :**
- `9001dda` : version 1.9.0 (190), changelog (app en français, fenêtre du Dock en Liquid Glass, marges du popover, guide utilisateur EN/FR et captures, journalisation unifiée).
- Build Release propre : 1.9.0 (190), `codesign --verify --deep --strict` OK, pas de `SUFeedURL`, `fr.lproj` dans l'app (186 phrases) et le widget, **aucune trace du mode démo** dans le binaire (`strings | grep demoDevices` → 0), `ideviceinfo 1.4.0`, `abtp`.
- DMG depuis un dossier temporaire du scratchpad, `hdiutil verify` OK ; copies de build (Release, DMG, Debug) désenregistrées et `build/DerivedData-release` supprimé.
- Tag `v1.9.0` sur `9001dda`. Pre-release publiée : https://github.com/MsieurPafi/AirBattery/releases/tag/v1.9.0. SHA-256 `fa020348fed7dcc069cb65659303207188673d9b520a7287ebe9b8188a728176`, identique après retéléchargement.

**Échecs :**
- Côme a répondu « 1.9.0 installée, l'app est en français » mais `/Applications` contenait encore la 1.8.0 (Info.plist de 14:34, pas de `fr.lproj`, processus lancé par moi à 16:44 après les captures) ; le français vu venait sans doute de la copie de test. **La release était déjà publiée** : je l'ai publiée sur la foi de ce message sans vérifier l'app installée au préalable. Signalé à Côme, fusion de la PR de release suspendue. Côme a ensuite réellement installé la 1.9.0 : À propos affiche 1.9.0 (190) en français (capture), vérifié côté système (Info.plist 1.9.0, `fr.lproj` présent, widget 1.9.0 enregistré depuis `/Applications`).
- Leçon pour la procédure de release : **vérifier la version de `/Applications` (PlistBuddy, pas `defaults read`, qui peut renvoyer une valeur en cache) avant de publier**, même quand Côme confirme son test.

**Testé sur appareil réel :** oui, par Côme (après la correction ci-dessus).
**Prochaine étape :** au choix de Côme : mises à jour depuis GitHub / CI ; indexation des appareils par identifiant ; observation « connected » chaque minute (IDEAS).

---

## 2026-10-25 (suite 12) — Fréquence du widget ; deux tâches ajoutées

**Contexte :** macOS 27.0.1 (26A434), Xcode 27.1, `main` @ `6d02f11`, 1.9.0 installée. Branche `docs/session-2026-10-25-b`.

**Fait :**
- Crashs : aucun nouveau rapport (derniers : `comptest` le 2026-10-22 à 12:52, avant le correctif).
- Question de Côme : la fréquence du widget dépend-elle de la « Fréquence d'actualisation » de Proximité ? **Oui.**
  - App : `widgetViewTimer` (`Supports.swift`) toutes les `60 × updateInterval` s appelle `WidgetCenter.shared.reloadAllTimelines()`, sauf si le réglage du widget vaut « Défini par macOS » (`widgetInterval == -1`). `widgetDataTimer` (toutes les `24 × updateInterval` s) relance `system_profiler`, relit les accessoires Magic et réécrit `data.json`.
  - `updateInterval` est lu **une fois au lancement** (constantes globales) : un changement demande de relancer l'app, comme l'indique déjà le réglage.
  - Les minuteries sont rattachées à la vue de l'icône du Dock (`MultiBatteryView`), installée même en mode « barre des menus » : elles tournent quel que soit l'affichage choisi.
  - Widget : une seule entrée, politique `.atEnd` ; il ne se rafraîchit pas de lui-même à intervalle fixe.
  - Vérification : journaux de `chronod`, `record reload` pour `widget.battery.part3` à hh:mm:18 chaque minute (16:56 → 17:01).
  - Guide (EN et FR, page Réglages) complété en conséquence.
- `IDEAS.md` : question marquée résolue ; ajout de deux tâches demandées par Côme : renommer le dépôt GitHub (liste de ce qu'il faudra mettre à jour) et une grande analyse de l'app (performances, sécurité, qualité, journaux), avec les pistes déjà connues.

**Échecs :** —
**Testé sur appareil réel :** lecture des journaux système sur le Mac de Côme.
**Prochaine étape :** au choix de Côme : analyse de l'app, renommage du dépôt, mises à jour GitHub / CI, indexation par identifiant.

---

## 2026-10-25 (suite 13) — Dépôt renommé `AirBattery-Plus`

**Contexte :** macOS 27.0.1 (26A434), `main` @ `c4d3701`. Branche `chore/repo-rename`.

**Fait :**
- Récapitulatif des tâches fait avec Côme ; ordre proposé : renommage, analyse de l'app, indexation par identifiant (avec tests unitaires), mises à jour et CI. Côme commence par le renommage.
- `gh repo rename AirBattery-Plus --repo MsieurPafi/AirBattery --yes` → `MsieurPafi/AirBattery-Plus`, toujours fork de `lihaoyun6/AirBattery`. D-024.
- Remote `origin` de `src/` → `https://github.com/MsieurPafi/AirBattery-Plus.git` (`git fetch` OK).
- Liens mis à jour : `Credits.rtf` (Base, fr, zh-Hans, zh-Hant), guide EN et FR (prise en main, dépannage), `CONTRIBUTING.md`, `CLAUDE.md`. Les README utilisent des liens relatifs (rien à changer).
- Vérification : nouvelles adresses en 200, anciennes en 301 vers les nouvelles (dépôt et page de la release v1.9.0).

**Échecs :** —
**Testé sur appareil réel :** sans objet (les crédits de l'app installée garderont l'ancien lien, redirigé, jusqu'à la prochaine version).
**Prochaine étape :** analyse de l'app.

---

## 2026-10-25 (suite 14) — Analyse de l'app (performances, sécurité, qualité, journaux)

**Contexte :** macOS 27.0.1 (26A434), Xcode 27.1, `main` @ `ea88184` (PR #34 fusionnée avec l'accord de Côme), 1.9.0 installée. Branche `docs/audit-2026-10-25`.

**Fait :**
- Trois relectures du code en parallèle, par des agents en lecture seule : sécurité, performances et énergie, qualité et bogues.
- Mesures sur la 1.9.0 : 0,46 % de CPU, 28 Mo, ~13 réveils/s, 0 `EXC_GUARD`, pas de zombie, ~150 lignes de journal en 20 min.
- Constats principaux revérifiés par moi dans le code ou les journaux :
  - **reconnexion de la souris MX chaque minute** : journaux de `bluetoothd` alignés sur les « connected » de l'app à hh:mm:20 ;
  - **`logReader.sh` inopérant depuis `de55b38`** : `IFS=$'\n'` empêche le découpage des options, et `log show --level` sort en code 64 ;
  - notifications refusées pour la 1.9.0 ;
  - noms traduits (« (boîtier) ») utilisés comme identifiants ; « Apple Pencil » et « Pencil » absents du catalogue ;
  - fuite IOKit dans `MagicBattery` ; division par zéro dans `InternalBattery.charge` ;
  - « Jamais » inopérant ; connexion au démarrage par API dépréciée ;
  - la lecture BLE remplace le `deviceID` de l'iPhone ;
  - Nearcast : nom de fichier tiré de `sender`, clé de 8 caractères.
- Divergence entre les relectures sur la cause des « connected » : la piste iPhone est réfutée par les journaux, c'est la souris.
- Rapport priorisé avec un plan de 7 PR : `docs/dev/AUDIT-2026-10-25.md`. `IDEAS.md` mis à jour (analyse faite, « connected » expliqué, tri du widget déjà fait en 1.7.2).

**Échecs :** —
**Testé sur appareil réel :** mesures et journaux sur le Mac de Côme ; aucune correction appliquée.
**Pistes ouvertes :** vérifier les notifications dans Réglages Système (Côme) ; choisir l'ordre des corrections.
**Prochaine étape :** PR 1 du plan (correctifs rapides) si Côme valide.

---

## 2026-10-25 (suite 15) — Analyse, PR 1 : correctifs rapides

**Contexte :** macOS 27.0.1 (26A434), Xcode 27.1, `main` @ `4cc6f76` (PR #35 fusionnée, plan validé par Côme : « dans l'ordre que tu as suggéré »). Branche `fix/audit-quick-wins`. Côme a réactivé les notifications d'AirBattery Plus dans Réglages Système (elles étaient désactivées).

**Fait (renvois à `AUDIT-2026-10-25.md`) :**
- Plantages (1.5) :
  - `charge` refuse une capacité nulle ; `as!` → `as?` sur `Temperature` et `ManufactureDate`.
  - `SPBluetoothDataTypeRaw[0]` → `.first` (7 endroits + `SPHardwareDataType`) ; entrées de `device_connected` en `guard … as? … else { continue }`.
  - Réglages lus par `ud.stringArray`, et `as? Int ?? 20` pour `disappearTime`.
  - AppleScript sans paramètre → -1.
  - `generateSymmetricKey` renvoie un optionnel pour un Group ID invalide ; Nearcast ne reprend au lancement que si l'identifiant est valide.
- « Jamais » : étiquette `Int(UInt32.max)` (type de la sélection).
- `getOtherBTBattery` : `continue` au lieu de `return`.
- `IOObjectRelease` de chaque objet de l'itérateur (4 boucles de `MagicBattery`).
- Minuteries BLE et BTD : fermetures au lieu de `target/selector` (le `Timer` était passé comme `longScan`).
- `abtp` : signe de l'âge des données, CSV RFC 4180 (noms entre guillemets, niveaux numériques).
- « Apple Pencil » et « Pencil » ne passent plus par `.local` (noms = identifiants, 1.4).
- Connexion au démarrage : type `LoginItem` (`SMAppService.loginItem(identifier: helper)` sur macOS 13+, `SMLoginItemSetEnabled` sur macOS 12) ; même helper qu'avant, pour ne pas créer une deuxième inscription. `ensureLoginItem` (`SMAppService.mainApp`, PR #161) et `registerDefaults`, inutilisés, sont supprimés. État lu au lancement : `true` chez Côme, donc l'inscription existante est bien reconnue.
- Notifications refusées : boîte de dialogue à l'enregistrement d'une alerte, avec bouton vers Réglages Système › Notifications ; 3 phrases ajoutées au catalogue (EN, FR).
- Nearcast, mesures d'attente :
  - nom de fichier = `sender` seulement s'il est sûr (`^[A-Za-z0-9-]{1,64}$`), sinon SHA-256 ; écriture atomique ;
  - plus de `BTTool.connect` à distance (type 254) ;
  - plus de réponse aux commandes inconnues (l'oracle) ; commande journalisée en privé, tronquée à 32 caractères ;
  - « Unknown Command » et « doesn't support command » retirés du catalogue.
- Build Debug OK, sans nouvel avertissement. Les avertissements « switch must be exhaustive » des widgets existaient déjà.
- Essai de 80 s sur le Mac de Côme (copie de test, puis 1.9.0 relancée et widget réenregistré) : appareils lus normalement, `abtp --csv` et `--json` corrects.

**Échecs :** premier build → `'@discardableResult' attribute cannot be applied to this declaration` (attribut de l'ancienne fonction resté au-dessus du nouveau type), corrigé.
**Testé sur appareil réel :** en partie. Non testés : bascule de « Ouvrir à la connexion » (à faire avec le DMG, sinon l'inscription pointerait vers la copie de test) ; boîte de dialogue des notifications (il faudrait les désactiver).
**Prochaine étape :** PR 2 (Bluetooth : reconnexion de la MX, anti-rebond, IOBluetooth sur le fil principal, verrou de `InternalBattery.status`).

---

## 2026-10-25 (suite 16) — Analyse, PR 2 : Bluetooth

**Contexte :** macOS 27.0.1 (26A434), Xcode 27.1, `main` @ `0c3e575` (PR #36 fusionnée avec l'accord de Côme). Branche `fix/bluetooth-reconnects`.

**Fait :**
- **Souris MX** (AUDIT 1.1) : `didConnect` découvrait tous les services, et le premier service non batterie retirait le périphérique de `peripherals`, ce qui fermait la connexion de l'app. Désormais, pour les périphériques que macOS garde connectés (`systemConnectedPeripherals`, rempli par `readConnectedPeripherals`), seul `180F` est découvert et la référence est gardée : aux cycles suivants, simple `readValue`.
- **Premier essai insuffisant** : `bluetoothd` montrait encore une connexion de l'app par minute. Les sessions dans le journal de `bluetoothd` (`… from session "io.github.msieurpafi.AirBattery-central-…"`) ont montré que la MX n'était plus reconnectée (`CharacteristicReadValue`), mais que l'**iPhone autorisé en Bluetooth** l'était (`ideviceOverBLE` = 1 chez Côme).
  - La piste iPhone de la relecture qualité était donc juste pour cette partie. Mon premier verdict (« la souris seule ») était incomplet ; voir l'entrée de la suite 14 et AUDIT 1.1.
- **iPhone** (AUDIT 1.6) :
  - la lecture BLE ne remplace plus le `deviceID` (UDID) d'un iPhone ou iPad déjà connu ;
  - si l'appareil est connu sous un autre identifiant, donc tenu à jour par USB/Wi-Fi, la connexion BLE n'a lieu que si cette source est muette depuis 3 intervalles.
- **Anti-rebond** dans `deviceIsConnected` : au plus un traitement par adresse et par minute.
- **IOBluetooth sur le fil principal** (AUDIT 1.5) : `MagicBattery.getIOBTBattery` et `BTDBattery.getConnected` passent par `onMainThread` (nouveau, `Supports.swift`) et n'en sortent que des valeurs simples. Pas de risque d'interblocage relevé : `LogReader` libère son verrou avant de travailler, et aucun appel n'a lieu sous le verrou du modèle.
- `InternalBattery.status` protégé par un `NSLock`.
- **Mesure sur le Mac de Côme** (copie de test, 4 min, puis 1.9.0 relancée et widget réenregistré) :
  - aucun « connected » (1 par minute avant) ;
  - connexions BLE de l'app seulement au lancement, puis 8 lectures de valeur ;
  - iPhone et Watch gardent leur UDID et sont relus environ une fois par minute ;
  - 0 erreur.

**Échecs :** premier correctif insuffisant (voir ci-dessus).
**Testé sur appareil réel :** oui (mesures sur le Mac de Côme).
**Prochaine étape :** PR 3 (`logReader.sh`).

---

## 2026-10-25 (suite 17) — Analyse, PR 3 : `logReader.sh`

**Contexte :** macOS 27.0.1 (26A434), Xcode 27.1, `main` @ `5aeee19` (PR #37 fusionnée avec l'accord de Côme). Branche `fix/logreader`.

**Fait :**
- Journaux réels : 2 h → 3 303 lignes, 0 `Battery M`, 0 paire `0x001D Characteristic Value`. Le format n'est pas vérifiable chez Côme (pas d'appareil Bluetooth classique d'une autre marque), donc on garde le chemin. COMPAT note 13.
- `logReader.sh`, mode « mac » :
  - options de `log show` dans un tableau, `--info` au lieu de `--level info` ;
  - lignes lues par `while IFS= read -r`, sans découpage ni expansion de motifs ;
  - noms et types échappés pour le JSON (AUDIT, sécurité L1) ;
  - `system_profiler` lancé seulement s'il y a des lignes à apparier ;
  - variable `LOGREADER_SAMPLE` pour les tests.
- `logReader.sh`, mode Pencil : chemin d'`idevicesyslog` mis entre guillemets. Il contient « AirBattery Plus.app » et ne tenait que grâce à l'ancien `IFS` global.
- `LogReader` (Swift) : la date de départ est passée en 4e argument au lieu de `setenv("START_TS")` (course sur l'environnement, AUDIT 1.5) ; fenêtre bornée à 10 min.
- **Second bogue trouvé en testant** : `log show --start` refusait le format de date de l'app, avec une espace avant le fuseau → format `yyyy-MM-dd HH:mm:ssZ`. Une valeur enregistrée dans l'ancien format ne se relit plus, et le cycle suivant utilise une fenêtre.
- Tests :
  - échantillon (`docs/dev/samples/logreader-mac-sample.log`) : JSON valide, appareil Apple exclu, guillemets échappés, `*` non développé ;
  - journaux réels : 10 min → code 0, 3,5 s ; avec date de départ → code 0 ;
  - Pencil avec un faux `idevicesyslog` dans un dossier à espace, en USB et en Wi-Fi : JSON correct ;
  - copie de test 1 min sur le Mac de Côme : aucune erreur, `logReaderLastTS` réécrit au nouveau format (`2026-10-25 17:56:06+0100`), puis 1.9.0 relancée et widget réenregistré.

**Échecs :** voir le second bogue ci-dessus.
**Testé sur appareil réel :** script et app sur le Mac de Côme ; pas d'appareil concerné pour vérifier une lecture de batterie réelle.
**Prochaine étape :** PR 4 (ordonnanceur et `process()`).

---

## 2026-10-25 (suite 18) — Analyse, PR 4 : ordonnanceur et `process()`

**Contexte :** macOS 27.0.1 (26A434), Xcode 27.1, `main` @ `5e59153` (PR #38 fusionnée avec l'accord de Côme). Branche `perf/scheduler-process`.

**Fait :**
- **`process()`** :
  - délai par défaut de 20 s (8 `system_profiler`, `idevice_id`, `ideviceinfo`, `wificonnection`, `killall` n'en avaient pas) ;
  - sortie d'erreur vers `FileHandle.nullDevice` (le tube jamais lu pouvait bloquer l'outil) ;
  - à l'expiration, `terminateTree` arrête les descendants d'abord (via `pgrep -P`), puis SIGKILL 400 ms plus tard ; `kill()` direct au lieu de lancer `/bin/kill`.
  - Testé à part : `bash -c 'x=$(sleep 300…)'` avec 1 s de délai rend la main en 1 s, sans `sleep` restant.
- **iPhone/iPad** :
  - un seul scan à la fois (`scanning` sous verrou) ;
  - appareils inconnus (bloqués ou lecture en échec) relus au plus une fois par intervalle, séparément pour l'USB et le réseau ;
  - Pencil relu une fois par intervalle, une lecture par iPad à la fois.
- **`Scheduler`** (`AirBatteryApp.swift`) :
  - alertes (300 s), rechargement des widgets (intervalle), `system_profiler` + accessoires Magic + données des widgets (0,4 × intervalle, file série hors du fil principal), diffusion Nearcast ;
  - minuteries avec 10 % de tolérance, retirées de `MultiBatteryView` ;
  - tolérance aussi sur `mainTimer` (0,1 s) et `dockTimer` (0,5 s).
  - Premier build en échec : `Supports.swift` est aussi compilé dans le widget (`cannot find 'NCMessage' in scope`…). Classe déplacée dans `AirBatteryApp.swift` (cible app seule).
- **`writeData`** : écrit seulement si un champ affiché change (signature sans les horodatages) ou toutes les 5 min. Le rechargement des widgets n'a lieu que s'il y a eu écriture. `force: true` pour les actions de l'utilisateur, le lancement, les URL et AppleScript ; l'export pour `abtp` n'a lieu qu'en mode `force`.
- Batterie du Mac lue une fois par seconde au lieu de deux. Onglet Widget : type de Mac lu dans `machineType` au lieu de relancer `system_profiler`.
- **Mesure sur 6 min** (1.9.0 sur les 6 min précédentes, puis copie de test) :
  - `system_profiler` : 26 → 17, compté par les PID distincts « from system_profiler » dans les journaux de `bluetoothd` ;
  - enregistrements de rechargement des widgets (`chronod`) : 52 → 16 ;
  - CPU de la copie de test : 0,98 s en 345 s (0,28 %) ;
  - aucune erreur ; `abtp --csv` complet.
  - Les réveils mesurés avec `top` ne sont pas comparables d'un échantillon à l'autre : non retenus.
- 1.9.0 relancée et widget réenregistré.

**Échecs :** voir le premier build ci-dessus.
**Testé sur appareil réel :** oui (mesures sur le Mac de Côme).
**Pistes ouvertes :** le reste des `system_profiler` (~2,5 par minute) vient de la relecture des accessoires Magic toutes les 24 s ; une lecture par intervalle suffirait sans doute. Batterie du Mac sur notification (`IOPSNotificationCreateRunLoopSource`) plutôt qu'à la seconde : non fait.
**Prochaine étape :** PR 5 (indexation par identifiant + tests).

---

## 2026-10-25 (suite 19) — Analyse, PR 5 : identité des appareils et tests unitaires

**Contexte :** macOS 27.0.1 (26A434), Xcode 27.1 (Swift 6.4), `main` @ `09a90e8` (PR #39 fusionnée avec l'accord de Côme). Branche `feat/device-identity`.

**Fait :**
- Carte des identifiants par source (voir D-025). L'indexation par identifiant seul aurait risqué des doublons d'AirPods (identifiant d'annonce changeant) et la migration de toutes les listes de l'utilisateur, qui sont par nom : **portée réduite**, et le plan de l'analyse est ajusté.
- `Shared/Core/DeviceIdentity.swift` :
  - `canonicalName` (suffixe du boîtier dans les 4 langues) ;
  - `normalizedID` (adresses `aa-bb` / `AA:BB`) ;
  - `isUDID` ;
  - `matchIndex` (même identifiant d'abord, sinon même nom sauf deux UDID différents) ;
  - `[String].containsDeviceName`.
- Appliqué à `updateDevice`, `hideDevice`/`unhideDevice`, `getBlackList`, `getAll`, `getByName`, `checkIfBlocked`, aux alertes (`BatteryAlertView`, popover), aux épingles (`refeshPinnedBar`, popover), aux retraits des listes (11 tests d'appartenance et 4 retraits remplacés dans `ContentView`) et à AppleScript.
- `Shared/Core/BatteryParsing.swift` : lecture d'`ideviceinfo` déplacée depuis `IDeviceBattery.parseBattery`, qui délègue.
- Paquet Swift à la racine (`Package.swift`, `Tests/AirBatteryCoreTests`) : `swift test` → 12 tests, 0 échec. `.swiftpm/` ignoré (`.build/` l'était déjà).
- Build Debug OK. Nouvelle note « Metadata extraction skipped » du traitement AppIntents pour le helper : il est recompilé parce qu'il inclut `Shared`. Information, sans effet.
- Copie de test 2 min sur le Mac de Côme : mêmes 5 appareils, sans doublon, aucune erreur. Listes de Côme : aucune épingle ni appareil masqué ; alertes sur MX et Air75, non concernées. 1.9.0 relancée et widget réenregistré.

**Échecs :** —
**Testé sur appareil réel :** liste d'appareils seulement (pas d'AirPods sortis du boîtier pendant le test ; cas couvert par les tests unitaires).
**Prochaine étape :** PR 6 (Nearcast v2) : décision à prendre avec Côme sur la compatibilité avec le client iOS ; PR 7 (nettoyage) ; puis une release.

---

## 2026-10-25 (suite 20) — Nearcast v2 mis de côté, issues activées

**Contexte :** `main` @ `602ec5c` (PR #40 fusionnée avec l'accord de Côme). Branche `docs/nearcast-v2-todo`.

**Fait :**
- Nearcast v2 (PR 6 du plan) reporté : il rompt la compatibilité avec la v1 (client iOS, Mac non mis à jour), Côme n'utilise pas Nearcast, et les mesures d'attente de la PR #36 couvrent le plus grave. Côme juge le sujet important : à garder.
- Les issues étaient **désactivées** sur le dépôt (réglage par défaut d'un fork), alors que le guide et `CONTRIBUTING.md` pointent vers la page Issues. Activées avec l'accord de Côme (`gh repo edit --enable-issues`).
- Issue [#41](https://github.com/MsieurPafi/AirBattery-Plus/issues/41) « Nearcast v2: a secure protocol » (étiquette `enhancement`), texte versionné dans `docs/dev/issues/nearcast-v2.md`. Ligne « À faire » dans `IDEAS.md`.

**Échecs :** —
**Prochaine étape :** PR 7 (nettoyage), puis une release.

---

## 2026-10-25 (suite 21) — Analyse, PR 7 : nettoyage

**Contexte :** macOS 27.0.1 (26A434), Xcode 27.1, `main` @ `622b94a` (PR #42 fusionnée). Branche `chore/cleanup`.

**Fait :**
- Inventaire par script : déclarations jamais référencées hors commentaires, faux positifs écartés (points d'entrée, classes AppleScript nommées dans le `.sdef`, méthodes de délégués).
- Supprimé :
  - fichiers `BTTool.swift` et `InfoButton.swift` (et leurs entrées du projet) ;
  - `appleMacPrefix` (~900 entrées sur une ligne), `dayAndWeek`, `roundedCorners`, `getFirstNCharacters`, `getMonoNum`, `pasteFromClipboard` ;
  - le `findParentKey` global (doublon de celui de `MagicBattery`, que l'inventaire ratait à cause de sa récursion) ;
  - `MagicBattery.getAirpods` et `getDeviceTypeWithPID`, `BLEBattery.getPaired`, `transDevice`, `unhideDevice` ;
  - `SDivider`, `SItem`, `SSlider`, `HoverButton` ;
  - les blocs commentés `test_data`, `.contextMenu` (73 lignes), `menuWillOpen`, « trans » de Nearcast, `hidpp` ;
  - 9 phrases du catalogue utilisées seulement par ce code (« Transmit to… », etc.).
- Gardé : le grand commentaire en tête de `BLEBattery.swift`, qui documente les octets des AirPods.
- Lecture du rapport `system_profiler` regroupée : `SPBluetoothDataModel.connectedDevices`, utilisé par `getLevel`, `getType`, `getDeviceType`, `getOtherBTBattery`.
- Noms corrigés : `refesh*` → `refresh*`, `isGroudIDValid` → `isGroupIDValid` (22 occurrences). Commande d'URL `reloadwidgets` acceptée en plus de `reloadwingets`, gardée pour les scripts existants.
- Bilan : 13 fichiers, +52 / −712 lignes, plus 2 fichiers supprimés. Build Debug sans nouvel avertissement, `swift test` 12/12.
- **Essai** : un premier essai de 2 min était faussé, parce que `open airbattery-plus://…` et `abtp` ont réveillé la 1.9.0 installée, qui est le gestionnaire du schéma d'URL ; deux instances tournaient. Second essai, la copie de test enregistrée temporairement comme gestionnaire (`lsregister -u` de `/Applications`, `-f` de la copie) : 5 appareils, `reloadwidgets` accepté, aucune erreur. Ensuite, copie désenregistrée, `/Applications` réenregistrée et relancée, widget réenregistré.

**Échecs :**
- Premier passage du script de suppression : `getPaired` coupée à une ligne (crochet `[String]` de la signature pris pour le bloc). Fichier restauré et suppression refaite par accolades.
- Premier essai faussé par le gestionnaire d'URL (voir ci-dessus). À retenir pour les essais d'`abtp` ou des URL : enregistrer la copie de test comme gestionnaire.

**Testé sur appareil réel :** oui (copie de test sur le Mac de Côme).
**Prochaine étape :** release 1.10.0 (PR 1 à 5 et 7 depuis 1.9.0).

---

## 2026-10-25 (suite 22) — Release 1.10.0 (pre-release)

**Contexte :** macOS 27.0.1 (26A434), Xcode 27.1. PR #43 fusionnée avec l'accord de Côme (`main` @ `767e1a6`). Branche `release/1.10.0`.

**Fait :**
- `45190bb` : version 1.10.0 (`CURRENT_PROJECT_VERSION` 1100, qui reste supérieur à 190). Changelog réorganisé en Corrections, Performances, Changements et Sécurité : les entrées s'étaient accumulées PR après PR sous un seul titre.
- Build Release propre : 1.10.0 (1100), pas de `SUFeedURL`, `codesign --verify --deep --strict` OK, `fr.lproj` présent, aucune trace du mode démo, nouveau `logReader.sh`, `BTTool`/`InfoButton` absents, `ideviceinfo 1.4.0`, `abtp --help` OK.
- DMG depuis un dossier temporaire du scratchpad, `hdiutil verify` OK ; copies de build (Release, DMG, Debug) désenregistrées et `build/DerivedData-release` supprimé avant l'installation.
- Test de Côme : 1.10.0 installée, « tout fonctionne », y compris la checklist : appareils, « Ouvrir à la connexion » (une seule entrée dans Réglages Système), widget.
- **Vérification avant publication** (procédure depuis la suite 11) : PlistBuddy sur `/Applications` → 1.10.0 (1100), `fr.lproj` présent, processus lancé à 18:41, widget 1.10.0 enregistré, aucun nouveau rapport de plantage.
- Tag `v1.10.0` sur `45190bb`. Pre-release publiée : https://github.com/MsieurPafi/AirBattery-Plus/releases/tag/v1.10.0. SHA-256 `1b3e22e6145a097883572a81a65a5ce7f1d665ff3f7356cbc88faf2fe85bd77f`, identique après retéléchargement.

**Échecs :** —
**Testé sur appareil réel :** oui, par Côme.
**Prochaine étape :** au choix de Côme : mises à jour depuis GitHub / CI ; Nearcast v2 (#41).

## 2026-10-25 (suite 23) — Mises à jour par Sparkle (D-026)

**Contexte :** macOS 27.0.1 (26A434), Xcode 27.1, commit de départ `9c249c0` (PR #45 fusionnée avec l'accord de Côme), branche `feat/sparkle-updates`
**Objectif :** réactiver Sparkle avec une clé et un appcast propres au fork (option B choisie par Côme).

**Fait :**
- Clé EdDSA générée sur le Mac de Côme, avec son accord : `build/DerivedData/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_keys --account io.github.msieurpafi.AirBattery`. Clé publique `uUnzqQIUgDEL6VMjBtNE8PfnsYDMrS8Tx/Kr6w8R7H8=` (relue avec `generate_keys -p --account …`). Clé privée dans le trousseau de session : sauvegarde à faire par Côme (D-026).
- `Info.plist` : `SUFeedURL` (raw `main`), `SUPublicEDKey` ; `SUEnableAutomaticChecks = NO` retiré. `Sparkle.swift` : `updatesEnabled = true`.
- `appcast.xml` de l'auteur (v1.6.3) remplacé par un flux vide du fork.
- `scripts/update-appcast.sh <dmg>` : lit la version dans l'app du DMG, convertit la section du `CHANGELOG.md` en HTML, lance `generate_appcast` dans un dossier temporaire avec l'appcast actuel, vérifie que la nouvelle entrée est signée, puis recopie `appcast.xml`.
- Essais du script (appcast remis à vide ensuite) : DMG de la 1.10.0 téléchargé de la release → entrée **non signée**, sans erreur (l'app n'a pas de `SUPublicEDKey`) : vérification ajoutée au script. DMG d'un build Debug de la branche → entrée signée. Deuxième version (copie modifiée en 1.10.1 / 1101, re-signée ad hoc, section de test temporaire dans le CHANGELOG) → les deux entrées présentes, chacune avec son adresse de release.
- Agent utilisateur de Sparkle relu dans le binaire (`%@%@/%@ Sparkle/%@`) : nom et version de l'app, pas de version de macOS ; écrit tel quel dans la page de confidentialité.
- Docs : guide EN/FR (prise en main § Mise à jour, réglages, confidentialité), `CHANGELOG.md` (*Unreleased*), `CONTRIBUTING.md` § Releases, `ARCHITECTURE.md`, `IDEAS.md`, D-026, D-004 marquée remplacée.

**Échecs :**
- Copie modifiée sans re-signature → `generate_appcast` : « Skipped AirBattery-Plus-1.10.1.dmg … The app failed Apple Code Signing checks … Code=-67030 ». Attendu : il vérifie la signature de code. Re-signée ad hoc pour l'essai.
- `hdiutil attach/detach` : avertissements de dépréciation sous macOS 27 (comme `hdiutil create`, suite 13) ; sans effet.
- Build Debug lancé directement depuis le shell (`…/Contents/MacOS/AirBattery Plus`) → arrêt immédiat, rapport `~/Library/Logs/DiagnosticReports/AirBattery Plus-2026-10-25-185757.ips` : « This app has crashed because it attempted to access privacy-sensitive data without a usage description … NSBluetoothAlwaysUsageDescription ». La clé est bien dans l'`Info.plist` du build : lancée depuis un shell, l'app a ce shell pour processus responsable aux yeux de TCC. **Ce rapport n'est pas un crash de l'app** (ne pas le compter au prochain relevé). Relancé avec `open -n` : démarre, Sparkle sans erreur ; arrêté, copie désenregistrée (`pluginkit -r`, `lsregister -u`), widget de `/Applications` réenregistré.

**Décisions :** D-026 (remplace D-004)
**Testé sur appareil réel :** non. Il faut une première version avec Sparkle installée à la main, puis la suivante livrée par Sparkle (Gatekeeper à observer).
**Prochaine étape :** PR ; puis release de la première version avec Sparkle, installée à la main par Côme, et une seconde pour essayer la mise à jour.

## 2026-10-25 (suite 24) — Release 1.11.0 (pre-release), première version avec Sparkle

**Contexte :** macOS 27.0.1 (26A434), Xcode 27.1. Clé privée sauvegardée par Côme (fichier d'export supprimé, vérifié : absent du Bureau). PR #46 fusionnée avec son accord (`main` @ `669f194`). Branche `release/1.11.0`. Numéro choisi avec Côme : 1.11.0 (nouvelle fonction) plutôt que 1.10.1.

**Fait :**
- `c75e4b7` : version 1.11.0 (`CURRENT_PROJECT_VERSION` 1110). *Unreleased* → `## 1.11.0`, avec la note sur l'accès au réseau local.
- Build Release propre (`clean build`, `build/DerivedData-release`). DMG `AirBattery-Plus-1.11.0.dmg` depuis un dossier du scratchpad (app + raccourci Applications), `hdiutil verify` OK. SHA-256 `b4b1f2bd18c76a3ed79bc3f9c046636d5e4b52ff0517b03ca3a9a41139398c5f`.
- App du DMG : 1.11.0 (1110), widget 1.11.0, `SUFeedURL` et `SUPublicEDKey` du fork, pas de `SUEnableAutomaticChecks`, `codesign --verify --deep --strict` OK, équipe `PCH7VR8GPS`, 5 `.lproj`, Sparkle.framework, outils libimobiledevice présents, aucune trace de `demoDevices`.
- `scripts/update-appcast.sh` sur ce DMG : entrée 1.11.0 signée, ajoutée à `appcast.xml` sur la branche. Signature identique à celle de `sign_update --account io.github.msieurpafi.AirBattery` (ed25519 est déterministe). **Le DMG publié doit être exactement ce fichier**, sinon la signature ne correspond plus.
- Copies de build désenregistrées (`pluginkit -r`, `lsregister -u`), `build/DerivedData-release` supprimé ; un seul widget enregistré, celui de `/Applications` (1.10.0).

**Ordre de publication :** tag et pre-release avec ce DMG d'abord, fusion de la PR (qui porte `appcast.xml`) ensuite.
**Échecs :** —
**Testé sur appareil réel :** en attente de Côme (installation à la main de la 1.11.0).
**Prochaine étape :** test de Côme, publication, fusion ; puis une 1.11.1 pour essayer une mise à jour livrée par Sparkle (Gatekeeper).

## 2026-10-25 (suite 25) — 1.11.0 publiée

**Contexte :** suite 24. Test de Côme : 1.11.0 installée à la main, « tout fonctionne ». Il a accepté les vérifications automatiques à la question du deuxième lancement.

**Fait :**
- **Vérification avant publication** : PlistBuddy sur `/Applications` → 1.11.0 (1110), `SUPublicEDKey` du fork ; processus lancé à 19:08 ; widget 1.11.0 enregistré (un seul) ; aucun nouveau rapport de plantage (le seul récent, 18:57, est le lancement depuis le shell de la suite 23). Préférences Sparkle : `SUEnableAutomaticChecks = 1`, `SUAutomaticallyUpdate = 1` (téléchargement et installation automatiques aussi activés), `SUSendProfileInfo = 0`, `SULastCheckTime` 18:08:54 UTC : la première vérification a eu lieu, sur le flux vide.
- Première tentative de publication refusée par le mode automatique (« Create Public Surface ») : la réponse de Côme n'autorisait pas explicitement la publication. Rien n'avait été créé (pas de tag) ; accord explicite demandé, puis obtenu.
- Tag annoté `v1.11.0` sur `c75e4b7`, poussé. Pre-release publiée : https://github.com/MsieurPafi/AirBattery-Plus/releases/tag/v1.11.0 (DMG + `.sha256`). DMG retéléchargé : même SHA-256 ; adresse du flux → HTTP 200.
- PR #47 fusionnée (`main` @ `ebef8b6`). `appcast.xml` servi par `raw.githubusercontent.com` : entrée 1.11.0 (1110) avec l'adresse de la release.

**Testé sur appareil réel :** oui, par Côme (installation à la main, réglages, question du deuxième lancement).
**Pour le test de la 1.11.1 :** avec `SUAutomaticallyUpdate = 1`, Sparkle télécharge la mise à jour en arrière-plan et l'installe **à la fermeture de l'app**, sans fenêtre. Pour la voir passer, utiliser « Rechercher des mises à jour… », ou observer la version après avoir quitté puis relancé l'app. Sparkle vérifie toutes les 24 h par défaut.
**Prochaine étape :** une 1.11.1 pour valider une mise à jour livrée par Sparkle (Gatekeeper, accès au réseau local, widget) ; ou CI / Nearcast v2, au choix de Côme.

## 2026-10-25 (suite 26) — 1.11.1 préparée pour tester une mise à jour par Sparkle

**Contexte :** PR #48 fusionnée avec l'accord de Côme (`main` @ `edcc55f`). Branche `release/1.11.1`. 1.11.0 installée chez Côme, vérification et installation automatiques activées.

**Fait :**
- `7f08ac5` : version 1.11.1 (`CURRENT_PROJECT_VERSION` 1111). Aucun changement de l'app : version de test de la mise à jour, dit tel quel dans le CHANGELOG.
- Build Release propre, DMG `AirBattery-Plus-1.11.1.dmg` (`hdiutil verify` OK), SHA-256 `5179f7e821421b017e8b02858fd03aa9953dc93c880d3e3cc1b098e0d01acd03`. App : 1.11.1 (1111), widget 1111, clé du fork, `codesign --verify --deep --strict` OK, équipe `PCH7VR8GPS`, pas de mode démo.
- **Exigence de signature** : Sparkle refuse une mise à jour dont la signature de code ne satisfait pas l'exigence désignée de l'app installée. Celle de la 1.11.0 : `identifier "io.github.msieurpafi.AirBattery" and anchor apple generic and certificate leaf[subject.CN] = "Apple Development: … (D8K49NUSH7)" and certificate 1[…6.2.1] exists`. Vérifiée sur la 1.11.1 avec `codesign -v -R=…` : satisfaite. Elle dépend du nom du certificat de développement : si un jour Xcode signe avec un autre certificat (autre nom), les mises à jour seront refusées par la version installée (la clé EdDSA seule ne suffit pas quand les deux apps sont signées). À revérifier à chaque release.
- `appcast.xml` : 1.11.1 ajoutée (signature identique à `sign_update`), 1.11.0 conservée.
- Copies de build désenregistrées, `build/DerivedData-release` supprimé, widget de `/Applications` seul enregistré.

**Testé sur appareil réel :** pas encore : le test passe par la publication (le flux est lu sur `main`).
**Prochaine étape :** accord de Côme pour publier la 1.11.1 et fusionner l'appcast, puis son test (checklist dans le résumé de la PR).
