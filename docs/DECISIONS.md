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

## D-007 — `MACOSX_DEPLOYMENT_TARGET` : passer de 11.0 à 12.0   (2026-10-21, statut : proposée)
**Contexte :** Xcode 27.1 refuse de compiler : `The macOS deployment target 'MACOSX_DEPLOYMENT_TARGET' is set to 11.0, but the range of supported deployment target versions is 12.0 to 27.0.x.` (erreur, pas warning, sur les quatre targets).
**Options envisagées :** A. 12.0, le minimum accepté (changement minimal) / B. 13.0, ce qui permettrait de supprimer le chemin `SMLoginItemSetEnabled` au profit de `SMAppService` seul / C. plus haut (14, 15…) pour profiter d'API récentes.
**Décision proposée :** A pour l'instant. Une montée plus haute se décidera quand une API en aura vraiment besoin.
**Pourquoi :** c'est la plus petite marche qui débloque le build ; le fork est perso, mais rien ne justifie encore d'exclure des versions.
**Conséquences :** en attendant la validation, le projet garde 11.0 et les builds passent `MACOSX_DEPLOYMENT_TARGET=12.0` en ligne de commande (voir W-001).
**Validée par Côme :** non, en attente
