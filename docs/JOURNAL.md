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
