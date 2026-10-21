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
