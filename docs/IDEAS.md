# Idées

Pistes **non engagées**. Rien ici ne s'implémente sans le feu vert de Côme.

| Idée | Origine | Notes |
| --- | --- | --- |
| API « provider » externe (exécutables tiers → JSON) | Côme | Débloque les sources exotiques |
| Batterie PS Vita (plugin taiHEN + provider Mac) | Côme | Repo séparé pour le plugin |
| Export MQTT / Home Assistant (auto-discovery) | Côme | Broker MQTT dans son homelab |
| Historique et courbes de décharge (SQLite) | Côme | |
| Manettes via `GameController` | Côme | DualSense, DualShock 4, Switch Pro |
| Signature + notarisation via GitHub Actions | Côme | Le jour où il y aura un compte payant |
| Bascule du mode d'énergie + apps énergivores | upstream PR #211 | Hors périmètre a priori |
| Tri du widget par batterie la plus faible | upstream #188 | |
| ~~Batterie des périphériques BLE HID déjà connectés~~ | Côme (MX Anywhere 3), 2026-10-21 | Fait : branche `fix/ble-hid-battery` |
| ~~Réduire le scan BLE actif~~ | Claude, 2026-10-21 | Fait : branche `perf/ble-scan` (D-011). #207 n'avait rien à voir avec le scan (voir COMPAT note 4) |
| `RetrieveAddressForPeripheral` ×12 toutes les 24 s : `IOBluetoothDevice.pairedDevices()` + `addressString` dans `MagicBattery.scanDevices()` (minuteur `widgetDataTimer`) | Claude, 2026-10-21 | Messages XPC légers ; à n'optimiser que si une mesure le justifie |
| Réactiver ou supprimer `MagicBattery.getAirpods()` (lecture des AirPods via `system_profiler`, plus appelée depuis le commit upstream `5991915`) | Claude, 2026-10-21 | `system_profiler` semble renvoyer des niveaux en cache (mêmes valeurs pour les entrées connectée et non connectée) : à vérifier avant |
| ~~`abt` : lire les données hors du container sandboxé du widget~~ | Claude, 2026-10-21 | Fait : branche `fix/abt-data-access` |
| ~~**À faire :** soucis d'UI signalés par Côme~~ | Côme, 2026-10-21 | Fait : coins, boutons et position du popover (D-012, branche `ui/liquid-glass`) |
| **À faire :** mettre à jour l'identité du projet | Côme, 2026-10-21 | Nom « AirBattery Plus » partout (app, fenêtres, À propos, widget, `abt`, cohérent avec le schéma `airbattery-plus://`) ; README retravaillé ; liens vers les PR, issues et idées du projet initial qu'on a reprises, avec leurs auteurs. Remplace D-002 sur le nom (à consigner dans une nouvelle décision) ; mention du fork, de l'original et de l'AGPL-3.0 obligatoire dans le README. |
| **À faire :** mises à jour depuis le repo GitHub du fork | Côme, 2026-10-21 | Piste : réactiver Sparkle (D-004) avec une clé EdDSA propre au fork et un `appcast.xml` servi depuis le fork (releases GitHub). À vérifier : comportement de Gatekeeper sur une mise à jour non notarisée (D-003). Variante minimale : simple vérification des releases GitHub avec notification, sans installation automatique. |
| **À faire :** pipeline de build via GitHub Actions | Côme, 2026-10-21 | Faisable : les runners macOS sont gratuits pour un repo public, et `xcodebuild` y tourne. Limites : pas de compte payant, donc build non signé ou signé ad hoc (et widget à revérifier dans ce cas), pas de notarisation ; il faut vérifier quelle version d'Xcode les runners proposent. Créer un workflow qui publie demande l'accord de Côme (CLAUDE.md § 9). Se combine avec la ligne précédente (le CI produit les releases et l'appcast). |
| Interface : icônes de la barre d'outils plus grandes (≈ 18 pt, sans cercle), texte des lignes en 13 pt, séparateurs en retrait, liste sans carte | Claude, comparaison avec Parcel/BetterDisplay, 2026-10-21 | Côme préfère laisser tel quel pour l'instant |
| Remplacer `print()` par `os.Logger` (sous-système `io.github.msieurpafi.AirBattery`) | Claude, 2026-10-21 | Logs visibles dans `log stream`, filtrables, et non perdus dans un tampon stdout |
