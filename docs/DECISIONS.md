# Décisions

Journal des décisions du fork (ADR léger). On ajoute, on n'efface pas : une décision remplacée est marquée « remplacée par D-xxx ».

---

## D-001 — Fork perso d'abord, public ensuite   (2026-10-21, statut : acceptée)
**Contexte :** l'upstream (lihaoyun6/AirBattery) est abandonné depuis novembre 2025 ; Côme utilise l'app au quotidien.
**Options envisagées :** A. fork public maintenu pour la communauté / B. fork perso, repo public sans engagement.
**Décision :** B. Le repo `MsieurPafi/AirBattery` est public, mais sans obligation de releases, de support ni de triage.
**Pourquoi :** garder la maîtrise du rythme ; l'ouverture à la communauté reste possible plus tard.
**Conséquences :** pas de canal de distribution (Homebrew, releases) pour l'instant (cf. upstream #212, #213).
**Validée par Côme :** oui (brief initial)

## D-002 — Nouveau bundle ID `io.github.msieurpafi`, nom « AirBattery » conservé   (2026-10-21, statut : acceptée ; nom remplacé par D-014, D-015 puis D-017)
**Contexte :** le fork ne doit jamais partager réglages, containers ou mises à jour avec l'app officielle (`com.lihaoyun6.*`).
**Options envisagées :** A. `io.github.msieurpafi` (profil GitHub) / B. `me.bouquetco` (domaine de Côme).
**Décision :** A. Identifiants : `io.github.msieurpafi.AirBattery`, `io.github.msieurpafi.AirBattery.widget`, `io.github.msieurpafi.AirBatteryHelper`. Nom affiché inchangé.
**Pourquoi :** cohérent avec le repo GitHub, convention usuelle pour un projet open source.
**Conséquences :** les réglages et le container du widget repartent de zéro (pas de migration depuis l'app officielle). Si le compte GitHub est renommé, l'ID reste valable (un bundle ID n'a pas à résoudre).
**Validée par Côme :** oui (2026-10-21)

## D-003 — Pas de compte Apple Developer payant, builds locaux   (2026-10-21, statut : acceptée)
**Contexte :** la signature de l'auteur (certificat gratuit) a expiré ; Gatekeeper rejette les builds officiels (upstream #174).
**Décision :** signature avec l'Apple ID gratuit de Côme, ou ad hoc. Pas de notarisation pour l'instant, mais rien ne doit l'empêcher plus tard.
**Conséquences :** à vérifier empiriquement : enregistrement du widget WidgetKit avec une signature gratuite ou ad hoc.
**Validée par Côme :** oui (brief initial)

## D-004 — Sparkle désactivé   (2026-10-21, statut : acceptée)
**Contexte :** `Info.plist` pointe vers l'appcast et la clé EdDSA de l'auteur : une éventuelle 1.6.4 officielle remplacerait le fork, avec une signature valide.
**Décision :** retirer le flux de mises à jour, désactiver les vérifications automatiques et masquer le bouton dans l'UI. `appcast.xml` reste dans le repo mais n'est plus utilisé.
**Conséquences :** pas de mise à jour automatique. Réactivation future avec une clé EdDSA propre au fork.
**Validée par Côme :** oui (brief initial)

## D-005 — Schéma d'URL `airbattery-plus://`   (2026-10-21, statut : acceptée)
**Contexte :** le CLI `abt` ouvre `airbattery://writedata`. Si l'app officielle et le fork sont installés tous les deux, le schéma est ambigu.
**Options envisagées :** A. garder `airbattery://` et désinstaller l'officielle / B. schéma propre au fork.
**Décision :** B, `airbattery-plus://`.
**Pourquoi :** permet de garder l'app officielle installée pour comparer les comportements pendant le développement.
**Conséquences :** le schéma ne préjuge pas du nom de l'app (D-002 garde « AirBattery ») ; s'il change un jour, voir D-006 pour les endroits à modifier. Pour les mesures fines (BLE, logs, crashs), ne faire tourner qu'une seule des deux apps à la fois.
**Validée par Côme :** oui (2026-10-21, nom provisoire proposé par Côme)

## D-006 — Identifiants centralisés : `APP_ID_PREFIX` + `Shared/AppIdentifiers.swift`   (2026-10-21, statut : acceptée)
**Contexte :** l'ID de l'app, du widget et du helper était codé en dur à dix endroits (widget ×4, helper, `AirBatteryApp.swift` ×2, `SettingsView.swift`, `AirBatteryModel.swift`, `abt/main.swift`), plus le schéma d'URL à cinq endroits. Un oubli lors d'un renommage casse le widget en silence (container introuvable, ou « ouvre l'app » en permanence).
**Options envisagées :** A. remplacer les chaînes une par une / B. clé `Info.plist` lue au runtime (impossible proprement pour `abt`, outil en ligne de commande sans `Info.plist`) / C. réglage de build unique + une constante Swift partagée.
**Décision :** C. Réglage `APP_ID_PREFIX` au niveau projet, dont dérivent les trois `PRODUCT_BUNDLE_IDENTIFIER`. Côté Swift, un dossier synchronisé `Shared/` compilé dans les quatre targets, avec `enum AppIdentifiers` (`app`, `widget`, `helper`, `urlScheme`, `url(_:)`). `CFBundleURLName` vaut `$(PRODUCT_BUNDLE_IDENTIFIER)`.
**Pourquoi :** fonctionne pour les quatre targets, `abt` compris. Il reste deux endroits à garder synchrones (le réglage de build et `AppIdentifiers.prefix`), mais une `assert` au lancement de l'app (Debug) détecte tout écart.
**Conséquences :** pour renommer : `APP_ID_PREFIX` dans le projet, `AppIdentifiers.prefix`, et le schéma dans `Info.plist` + `AppIdentifiers.urlScheme`.
**Validée par Côme :** pas nécessaire (demandé par le brief, §3 étape 5)

## D-007 — `MACOSX_DEPLOYMENT_TARGET` : passer de 11.0 à 12.0   (2026-10-21, statut : acceptée)
**Contexte :** Xcode 27.1 refuse de compiler : `The macOS deployment target 'MACOSX_DEPLOYMENT_TARGET' is set to 11.0, but the range of supported deployment target versions is 12.0 to 27.0.x.` (erreur, pas warning, sur les quatre targets).
**Options envisagées :** A. 12.0, le minimum accepté (changement minimal) / B. 13.0, ce qui permettrait de supprimer le chemin `SMLoginItemSetEnabled` au profit de `SMAppService` seul / C. plus haut (14, 15…) pour profiter d'API récentes.
**Décision :** A pour l'instant. Une montée plus haute se décidera quand une API en aura vraiment besoin.
**Pourquoi :** c'est la plus petite marche qui débloque le build ; le fork est perso, mais rien ne justifie encore d'exclure des versions.
**Conséquences :** l'app, le widget, le helper et `abt` exigent macOS 12 (Monterey) ou plus. Appliqué dans `138b433` ; W-001 retiré. Pour revenir en arrière : impossible avec Xcode ≥ 27, sauf à garder un Xcode plus ancien.
**Validée par Côme :** oui (2026-10-21)

## D-008 — Concurrence : la PR upstream #216 comme implémentation de référence   (2026-10-21, statut : acceptée)
**Contexte :** le faux verrou `AirBatteryModel.lock` (un `Bool`) et la capture d'un `IOBluetoothDevice` dans une closure en arrière-plan provoquent les crashs de `deviceIsConnected` (upstream #215, #206). Sur le Mac de Côme, l'app officielle 1.6.3 a planté 4 fois du 14 au 19/10/2026 exactement à cet endroit (`samples/2026-10-21_26A434_official-1.6.3-crashes.md`). Trois candidats : PR #216, PR #214, la « 1.6.4/1.6.5 Community Patch » de callieskye (sources trouvées : `github.com/callieskye/Air-Battery`, AGPL-3.0).
**Options envisagées :**
- A. PR #216 (3 commits, ~60 lignes) : `isAppleDevice` lu sur le fil principal (la closure ne capture plus l'`IOBluetoothDevice`), `NSLock` sur `AirBatteryModel.Devices` et `SPBluetoothDataModel.data`, file série pour les connexions.
- B. Code de callieskye : `NSLock` équivalents, file série, mais la closure de `deviceIsConnected` **capture toujours `device`**, donc le crash de nos rapports n'est pas traité. Import en un seul commit sans historique commun, mêlé à une vingtaine de features : rien n'est cherry-pickable.
- C. PR #214 : ne touche pas à la concurrence (le brief le supposait) ; son seul recouvrement avec #216 est l'import `ServiceManagement`, déjà dans `main` (`774c380`).
**Décision :** A, intégrée par `git cherry-pick -x` (auteur conservé). Le code de callieskye sert de **catalogue de correctifs diagnostiqués**, à porter un par un avec crédit. #214 sera rebasée sur ce résultat.
**Pourquoi :** c'est le seul candidat qui traite la pile exacte de nos crashs ; diff minimal et lisible ; historique propre.
**Conséquences :** les connexions BT sont traitées en série (2,5 s + un `system_profiler` par appareil) : après un réveil avec beaucoup d'appareils, les mises à jour arrivent plus lentement (effet signalé par l'auteur de #216). Les accès en lecture-modification-écriture via `Devices[i].x = …` restent non atomiques (perte de mise à jour possible, plus de corruption mémoire), mais seul `AirBatteryModel` y accède et il passe par `_devices` sous verrou.
**Validée par Côme :** oui (feu vert pour démarrer la Phase 1 par la PR #216, 2026-10-21)

## D-009 — Découverte Bluetooth des iPhone/iPad : liste d'appareils autorisés (PR upstream #214)   (2026-10-21, statut : acceptée)
**Contexte :** avec l'option « Discover iOS devices via Bluetooth », l'app se connectait d'elle-même à tout appareil Apple dont l'annonce BLE ressemblait à un iPhone/iPad, y compris ceux des voisins : popups d'appairage à répétition (upstream #89, #158, #169).
**Options envisagées :** A. garder le comportement d'origine, avec les listes noire/blanche par nom (inefficaces d'après #169) / B. PR #214 : découverte ≠ connexion ; l'utilisateur autorise explicitement chaque appareil (« Manage » › « Pair… »), autorisation indexée par identifiant CoreBluetooth, délai de 30 s, pause d'une heure après un échec / C. retirer l'option.
**Décision :** B.
**Pourquoi :** supprime la nuisance pour l'entourage sans retirer la fonction ; l'option reste désactivée par défaut ; diff isolé dans `BLEBattery.swift` et `SettingsView.swift`.
**Conséquences :** changement de comportement : un iPhone/iPad n'est lu en Bluetooth qu'après autorisation manuelle (stockée dans `authorizedIOSBLEDevices`, UUID → nom). Les Apple Watch sont refusées avec un message explicite (elles passent par l'iPhone). Pas de traduction française des nouveaux textes (à faire avec la PR #170). Messages de commit d'origine en chinois, conservés tels quels pour garder l'auteur (`Moyuin-aka`).
**Validée par Côme :** oui (testé le 2026-10-21 : appairage de son iPhone OK, Watch refusée avec le message « seuls les iPhone et iPad sont supportés »)

## D-010 — Flux Git : une branche par sujet, PR sur le fork, fusion par Côme   (2026-10-21, statut : acceptée)
**Contexte :** jusqu'ici, les branches de travail étaient fusionnées localement dans `main`, puis `main` était poussé avec l'accord de Côme.
**Options envisagées :** A. push direct sur `main` avec accord par session / B. branches de sujet poussées librement + PR sur le fork, fusionnées par Côme.
**Décision :** B. Claude pousse librement les branches de sujet sur `origin` et ouvre les PR sur `MsieurPafi/AirBattery` (jamais sur l'upstream). Côme relit et fusionne, ou autorise explicitement Claude à le faire. Pas de push direct sur `main` sans son accord.
**Pourquoi :** Côme garde la main sur ce qui entre dans `main`, et chaque sujet a une page de relecture sur GitHub.
**Conséquences :** `gh pr create` doit toujours passer `--repo MsieurPafi/AirBattery --base main`. Cette décision n'a pas d'effet rétroactif sur les commits déjà poussés le 2026-10-21 (Phase 0, PR #216, PR #214).
**Validée par Côme :** oui (2026-10-21)

## D-011 — Scan BLE actif : une fois par intervalle de rafraîchissement   (2026-10-21, statut : acceptée)
**Contexte :** le scan BLE actif tournait 5 s toutes les 29 s (environ 18 % du temps, intervalle par défaut d'1 min). Il alimente les AirPods/Beats (annonces de proximité), les iPhone/iPad autorisés en BLE (D-009) et le BLE générique. Suspect principal des saccades audio Bluetooth (upstream #178), que Côme ne constate pas lui-même.
**Options envisagées :** A. garder le rythme actuel / B. un scan par intervalle de rafraîchissement (5 s par minute, environ 9 %) / C. raccourcir chaque scan.
**Décision :** B, avec un seuil de relecture des appareils à « intervalle − 10 s », pour qu'un appareil lu à un scan soit relu au suivant.
**Pourquoi :** divise par deux le temps de radio en scan actif sans retirer de fonction.
**Conséquences :** les AirPods dépendent **uniquement** de ce scan (le lecteur `system_profiler` de `MagicBattery.getAirpods()` n'est plus appelé depuis le commit upstream `5991915`, 2024). À l'ouverture du boîtier, ils apparaissent en 45 à 60 s au lieu de 30 s au plus. Le gain sur #178 n'est pas vérifiable chez Côme. Pour revenir en arrière : `startScan()` dans `BLEBattery.swift`.
**Validée par Côme :** oui (2026-10-21, après test : AirPods visibles en 45–60 s boîtier ouvert, stables en utilisation)

## D-012 — Interface Liquid Glass : popover système + géométrie concentrique   (2026-10-21, statut : acceptée)
**Contexte :** sur macOS 26/27, le popover de la barre des menus avait des coins de ~18 pt, mais la liste intérieure gardait un cadre gris à coins de 4 pt, les boutons de la barre d'outils empiétaient sur l'arrondi, et le popover était ~7 pt plus bas que dans les autres apps Liquid Glass (BetterDisplay, Parcel). Côme pensait que le verre manquait.
**Options envisagées :** A. reprendre la PR upstream #200 / B. remplacer le `NSPopover` par une fenêtre maison avec `glassEffect` / C. garder le `NSPopover` système (qui fournit déjà le verre) et corriger la géométrie du contenu.
**Décision :** C. Tout se règle dans `ListMetrics` (`ContentView.swift`) : rayon du popover 18 pt (mesuré), liste en retrait de 5 pt avec un rayon de 13 pt, boutons centrés sur l'arc du coin, popover remonté de 7 pt. Le rendu d'avant macOS 26 est conservé.
**Pourquoi :** vérifié sur capture au-dessus d'un fond coloré, le `NSPopover` compilé avec le SDK 27 est **déjà** en Liquid Glass ; il ne manquait que la géométrie. B aurait obligé à réimplémenter la fermeture au clic extérieur, le positionnement, etc. A est écartée (voir UPSTREAM.md).
**Conséquences :** les valeurs sont mesurées sur l'écran à encoche de Côme : un changement de rayon du popover dans une future version de macOS demandera de les réajuster. Le décalage de 7 pt n'est pas vérifié sur une barre des menus de 24 pt (écran externe).
**Validée par Côme :** oui (2026-10-21, captures avant/après ; il choisit de ne pas reprendre les autres écarts avec Parcel/BetterDisplay pour l'instant)

## D-013 — Première release : 1.7.0, DMG, pre-release, fichier « AirBattery Plus.app »   (2026-10-21, statut : acceptée)
**Contexte :** Côme veut une première release avec le travail de la Phase 0 et du début de Phase 1, avant d'attaquer les correctifs de callieskye.
**Options envisagées :** version 1.7.0 / 2.0.0 / 0.1.0 ; ZIP / DMG ; pre-release / release normale ; nom de fichier `AirBattery Plus.app` / `AirBattery.app`.
**Décision :** **1.7.0** (build 170), en **DMG**, publiée en **pre-release** ; l'app s'y appelle **`AirBattery Plus.app`** (seul le nom du fichier ; le nom affiché reste « AirBattery » jusqu'à la tâche d'identité).
**Pourquoi :** 1.7.0 suit la 1.6.3 officielle sans entrer en collision avec les « 1.6.4/1.6.5 » communautaires de callieskye. Pre-release car le build n'est pas notarisé, il est signé avec un certificat de développement et n'a été testé que sur un Mac. Le nom de fichier distinct évite qu'un glisser-déposer dans Applications **remplace** l'app officielle, qui porte le même nom.
**Conséquences :** le tag `v1.7.0` pointe sur `9925e69`. Le DMG a été compilé depuis `900e8f5` (seule la doc diffère). Les notes de version écrivent les numéros upstream en police de code (`` `#215` ``) pour ne pas créer de lien automatique, ni vers des issues inexistantes du fork ni vers le dépôt de l'auteur. Le README porte désormais l'encart « fork modifié, AGPL-3.0 » exigé pour distribuer un binaire.
**Validée par Côme :** oui (2026-10-21 : choix via questionnaire, puis test du DMG installé dans Applications)

## D-014 — Nom affiché « AirBattery Plus » (remplace en partie D-002)   (2026-10-21, statut : acceptée)
**Contexte :** l'app officielle et le fork s'appelaient tous deux « AirBattery ». La galerie des widgets montrait donc deux entrées identiques, et Côme a ajouté celui de l'officielle en croyant tester le fork (clic → `airbattery://`, donc l'app officielle). Le fichier était déjà nommé `AirBattery Plus.app` (D-013).
**Options envisagées :** A. garder « AirBattery » et désinstaller l'officielle / B. nom affiché « AirBattery Plus » tout de suite, reste de l'identité (README, crédits, textes d'aide) plus tard / C. toute la tâche « identité » maintenant.
**Décision :** B. `INFOPLIST_KEY_CFBundleDisplayName = "AirBattery Plus"` pour la cible app, et le nom dans ce qui identifie l'app : fenêtre « À propos » (passée en option, car `CFBundleName` suit `PRODUCT_NAME` et reste « AirBattery » ; une clé `CFBundleName` dans `Info.plist` est écrasée par la valeur générée, vérifié), titre de la fenêtre de Réglages, ligne de version, entrée « About » du menu du Dock, description des widgets et message « … is not running ».
**Pourquoi :** distinguer les deux apps partout où l'utilisateur choisit (galerie, À propos), sans toucher aux identifiants techniques ni casser les traductions chinoises des textes d'aide.
**Conséquences :** remplace D-002 sur le nom affiché ; D-002 reste valable pour les bundle IDs. Inchangés : `CFBundleName`/exécutable « AirBattery » (le titre du menu de l'app quand une fenêtre est au premier plan peut encore l'afficher), textes d'aide et astuces. Les clés de traduction modifiées perdent leur traduction chinoise (« AirBattery Plus Settings », messages des widgets). À compléter par la tâche « identité » (IDEAS.md).
**Validée par Côme :** oui (2026-10-21)

## D-015 — Nom du produit « AirBattery Plus » (complète D-014)   (2026-10-21, statut : acceptée)
**Contexte :** avec seulement `CFBundleDisplayName` (D-014), la galerie des widgets affichait toujours « AirBattery » pour le fork (capture de Côme sur la 1.7.2), alors que LaunchServices le nommait bien « AirBattery Plus ». La galerie se sert de `CFBundleName`, généré par Xcode depuis `PRODUCT_NAME`. Testé sans effet : une clé `CFBundleName` dans `Info.plist` (écrasée), le réglage `INFOPLIST_KEY_CFBundleName` (ignoré).
**Options envisagées :** A. script post-build qui réécrit `CFBundleName` (fragile, avant la signature) / B. `PRODUCT_NAME = "AirBattery Plus"` pour la cible app, en fixant `PRODUCT_MODULE_NAME = AirBattery`.
**Décision :** B.
**Pourquoi :** c'est la voie standard, et le nom de module fixé préserve le dictionnaire AppleScript (`AirBattery.listAll`…) et les noms de classes Swift (`_TtC10AirBattery…`, vérifiés dans le binaire).
**Conséquences :** le produit s'appelle `AirBattery Plus.app`, l'exécutable `AirBattery Plus`, et le processus s'appelle « AirBattery Plus » dans `ps`, `log` et le Moniteur d'activité. Les commandes de test doivent utiliser `/usr/bin/log … process == "AirBattery Plus"` et le chemin `build/DerivedData/Build/Products/Debug/AirBattery Plus.app`. Inchangés : bundle IDs, widget, helper (il ouvre l'app par chemin), `abt`, réglages.
**Validée par Côme :** oui (demande « AirBattery Plus » dans la galerie, 2026-10-21)

## D-016 — libimobiledevice recompilée depuis les versions publiées   (2026-10-22, statut : acceptée)
**Contexte :** les binaires embarqués dataient de 2024 (`1.3.0-210-g73b6fd1`, libplist 2.0.4, OpenSSL 3.2.1 de Homebrew) et exigeaient **macOS 14** alors que l'app vise 12.0. `comptest` plantait plusieurs fois par jour (upstream #198).
**Options envisagées :** A. HEAD de développement (demande autoconf/automake/libtool via Homebrew) / B. dernières versions publiées, tarballs épinglés par SHA-256.
**Décision :** B, choisie par Côme : OpenSSL 3.5.9 (LTS), libplist 2.8.0, libimobiledevice-glue 1.3.3, libusbmuxd 2.1.1, libtatsu 1.0.5 (nouvelle dépendance de 1.4.0, utilisée seulement à la compilation), libimobiledevice 1.4.0. Universel arm64 + x86_64, macOS 12.0 minimum. Script `scripts/build-libimobiledevice.sh` (clang, make, perl, pkg-config ; rien installé sur le système). `comptest.c` versionné dans `scripts/libimobiledevice/` (gist de nikias + les deux ajouts du binaire de 2024 + correctif de #198).
**Pourquoi :** reproductible, auditable, cohérent avec la cible de l'app, sans outillage supplémentaire.
**Conséquences :** ~13 Mo de binaires embarqués (libcrypto ~10 Mo) ; licences dans `AirBattery/libimobiledevice/licenses/`, versions dans `VERSIONS.txt`. OpenSSL n'est pas reproductible au bit près d'une compilation à l'autre. Mettre à jour = changer les lignes `SOURCES` du script et relancer. Retour arrière : revert du commit `3cb0e62`.
**Validée par Côme :** oui (2026-10-21)

## D-017 — Identité « AirBattery Plus »   (2026-10-25, statut : acceptée)
**Contexte :** D-014 et D-015 ont renommé l'app (nom affiché, produit), mais plusieurs textes visibles disent encore « AirBattery » (demandes d'autorisation, réglages, alertes, copyright), la commande installée s'appelle `airbattery` comme celle de l'app officielle, et le README renvoie vers la page et le Homebrew de l'officielle. Questions posées à Côme le 2026-10-25 (JOURNAL), réponses le même jour.
**Options envisagées :** « Plus » seulement là où il sert à distinguer les deux apps / « Plus » partout. Pour la commande : garder `airbattery` / `abt` / `abtp`. Pour les liens vers l'original : les garder en tête du README / les regrouper dans une section de crédits.
**Décision :**
1. **Projet public** : le repo s'adresse à qui en a besoin, sans promotion. Complète D-001.
2. **« AirBattery Plus » dans tous les textes visibles** : app, demandes d'autorisation (Bluetooth, réseau local), réglages, alertes, À propos, widget, README. **Identifiants techniques inchangés** : bundle IDs (D-002), module Swift `AirBattery` (D-015), clés de réglages, `autosaveName` des icônes de barre des menus, nom de la file série, chemins de données.
3. **Commande `abtp`** : fichier `abtp` dans l'app, lien `/usr/local/bin/abtp`, nom affiché par `--help`. Un ancien lien `/usr/local/bin/airbattery` n'est supprimé que s'il pointe vers `AirBattery Plus.app` (celui de l'app officielle n'est jamais touché).
4. **Copyright** `© 2024 lihaoyun6, © 2026 Côme Bouquet`. Crédits dans le README (original, auteurs des PR reprises, callieskye) et mention de l'original dans À propos.
5. **Liens vers l'original** : la page d'accueil et le Homebrew de l'officielle quittent l'en-tête et l'installation du README ; l'original est cité en tête (« fork maintenu de AirBattery par lihaoyun6 ») et dans les crédits. `README_zh.md` est gardé tel quel, avec un bandeau en anglais (page de l'original, peut-être périmée, PR bienvenues). Les « upstream #N » du changelog deviennent des liens.
6. **Hors de cette décision**, sujets à part (IDEAS, « À faire ») : l'icône de l'app (Icon Composer, évolution ou révolution, à choisir sur maquettes) ; l'app et la doc en français et en anglais, le chinois figé avec appel aux PR.
**Pourquoi :** un nom unique évite toute confusion avec l'app officielle installée à côté ; garder les identifiants techniques évite de faire perdre leurs réglages et la position de leurs icônes aux utilisateurs actuels.
**Conséquences :** les traductions chinoises sont indexées par la phrase anglaise : quand une phrase change, sa clé chinoise est mise à jour et le nom propre remplacé dans la traduction, sans autre retouche. Les scripts ou raccourcis de quelqu'un qui tapait `airbattery` pour le fork doivent passer à `abtp`.
**Validée par Côme :** oui (2026-10-25)

## D-018 — Icône de l'app : maquette B2, au format Icon Composer   (2026-10-25, statut : acceptée)
**Contexte :** l'icône du fork était celle de l'app officielle (carré vert, éclair blanc), en simples PNG : impossible de distinguer les deux apps dans le Dock, et pas d'icône Liquid Glass sur macOS 26+ (upstream #187). D-017 en a fait un sujet à part.
**Options envisagées :** six maquettes soumises à Côme le 2026-10-25 : A (même icône + « + »), B1 (bleu), B2 (vert → turquoise + « + »), C1 (anneaux, un par appareil), C2 (batterie dont la borne est un « + »).
**Décision :** **B2**, choisie par Côme. Fond en dégradé vertical `#8DEFB2` → `#13A6A0`, éclair et « + » blancs. Fichier Icon Composer `AirBattery/AppIcon.icon` (écrit à la main : `icon.json` + calques SVG, sans passer par l'interface d'Icon Composer), ajouté aux ressources de l'app ; `actool` (Xcode 27.1) en tire les variantes claire, sombre et teintée et un `AppIcon.icns`. Les PNG de `AppIcon.appiconset` sont remplacés par la version plate (macOS 12–25, en-tête du README). Les SVG viennent de `scripts/icon/make-icon-artwork.py`, les PNG de `scripts/icon/export-pngs.swift`.
**Pourquoi :** on reconnaît la famille AirBattery, mais la couleur et le « + » distinguent le fork d'un coup d'œil, même à 32 px (à 16 px le « + » disparaît, la couleur suffit). Icon Composer est le format attendu par macOS 26+.
**Conséquences :** une seule géométrie à modifier dans le script. Le rendu Liquid Glass n'a été vérifié que via `NSWorkspace.icon(forFile:)` sur macOS 27.0.1 ; l'affichage sur macOS 12–25 n'est pas testé (pas de machine). Retour arrière : revert du commit.
**Validée par Côme :** oui (choix de B2, 2026-10-25)

## D-019 — Journalisation unifiée (`os.Logger`)   (2026-10-25, statut : acceptée)
**Contexte :** l'app écrivait ses messages avec `print()` (51 appels) et `NSLog()` (3). `print()` va sur la sortie standard, perdue quand l'app est lancée depuis le Finder : aucun de ces messages n'était lisible pour diagnostiquer un problème chez Côme. Le `print` de démarrage de Nearcast affichait en clair le Group ID, secret dont est dérivée la clé de chiffrement.
**Options envisagées :** A. `NSLog` partout / B. `os.Logger`, une catégorie par domaine.
**Décision :** B. `Shared/Log.swift` : sous-système `io.github.msieurpafi.AirBattery`, catégories `app`, `data`, `ble`, `bluetooth`, `idevice`, `magic`, `nearcast`, `process`. Niveaux : `notice` pour le cycle de vie (conservé sur disque), `error` pour les échecs, `debug` pour les messages fréquents (réception Nearcast, commandes d'URL). Noms d'appareils, adresses et chemins restent privés (masqués par défaut) ; seuls les réglages, noms d'outils et messages d'erreur sont publics. Le Group ID Nearcast n'est plus journalisé. Nouveau : un avertissement quand un outil externe dépasse son délai (`comptest`, `logReader.sh`…), sans ses arguments (identifiants d'appareils). Les `print` de `abtp` restent : c'est la sortie de la commande.
**Pourquoi :** messages visibles par `log show` après coup, filtrables par catégorie, sans coût notable.
**Conséquences :** lecture : `/usr/bin/log show --last 1h --predicate 'subsystem == "io.github.msieurpafi.AirBattery"'` (ajouter `--debug` à `log stream` pour le niveau debug). Les noms d'appareils apparaissent comme `<private>` hors Xcode.
**Validée par Côme :** oui (demande du 2026-10-25)

## D-020 — Fenêtre du Dock en Liquid Glass ; alertes laissées au système   (2026-10-25, statut : acceptée)
**Contexte :** sur macOS 26/27, la fenêtre ouverte par un clic sur l'icône du Dock gardait l'ancien rendu (fond `NSVisualEffectView` `.menu`, coins de 7 pt, barre d'outils collée au bord), alors que le popover de la barre des menus est en Liquid Glass (D-012). Les alertes sont des `NSAlert` standard.
**Options envisagées :** A. `glassEffect` en SwiftUI sur le contenu / B. `NSGlassEffectView` comme vue de contenu de la fenêtre / C. remplacer la fenêtre par un `NSPopover` ancré au Dock (pas d'ancre possible).
**Décision :** B, à partir de macOS 26 : `NSGlassEffectView` de rayon `ListMetrics.popoverCornerRadius` (18 pt), ombre de fenêtre, et la même géométrie que le popover (marges du haut et du bas, retrait de la barre d'outils, listes concentriques ; marge du haut + 2,5 pt, que le popover système ajoute de lui-même). La hauteur reste celle de la formule existante, plus ces marges ; `sizingOptions = []` empêche SwiftUI de redimensionner la fenêtre, et la fenêtre est gardée dans la partie visible de l'écran. Avant macOS 26 : rendu inchangé. Alertes : rien à faire, `NSAlert` est déjà en Liquid Glass avec le SDK 27 (capture de Côme).
**Pourquoi :** B garde la fenêtre existante (positionnement selon le Dock, fermeture au clic extérieur) et reproduit exactement le popover. Deux essais ratés montrent qu'il ne faut pas laisser SwiftUI mesurer : la liste n'est remplie qu'au `onAppear`, d'où une fenêtre de 72 pt qui grandissait ensuite vers le bas, hors de l'écran (1er essai), puis de 0 pt avec `sizingOptions = []` (2e essai).
**Conséquences :** la formule de hauteur (`37 pt` par ligne, `+30`, `+7` par groupe Nearcast) reste la référence : un changement de mise en page de la liste doit la mettre à jour.
**Validée par Côme :** oui (capture du 2026-10-25, écrans interne et externe)
