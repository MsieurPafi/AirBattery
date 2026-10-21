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

## D-002 — Nouveau bundle ID `io.github.msieurpafi`, nom « AirBattery » conservé   (2026-10-21, statut : acceptée)
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
