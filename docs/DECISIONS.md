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
**Conséquences :** le schéma ne préjuge pas du nom de l'app (D-002 garde « AirBattery ») ; s'il change un jour, seuls `Info.plist` et `abt` sont concernés. Pour les mesures fines (BLE, logs, crashs), ne faire tourner qu'une seule des deux apps à la fois.
**Validée par Côme :** oui (2026-10-21, nom provisoire proposé par Côme)
