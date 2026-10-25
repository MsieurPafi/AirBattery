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
| ~~**À faire :** mettre à jour l'identité du projet~~ | Côme, 2026-10-21 | En cours : D-017 (branche `feat/identity-name`) |
| ~~**À faire :** nouvelle icône de l'app (D-017)~~ Fait : D-018, branche `feat/app-icon` | Côme, 2026-10-25 | Icon Composer (format `.icon`, Liquid Glass, variantes sombre/teintée/transparente ; l'ancienne icône reste pour macOS 12–25, upstream #187). Évolution (éclair avec un « + ») ou changement de couleur, ou révolution : à choisir sur maquettes. |
| **À faire :** app et documentation en français et en anglais (D-017) | Côme, 2026-10-25 | Chinois figé dans son état, avec appel aux PR pour le mettre à jour (Côme ne peut pas le vérifier). Voir aussi la PR upstream #170 (traduction française). |
| **À faire :** mises à jour depuis le repo GitHub du fork | Côme, 2026-10-21 | Piste : réactiver Sparkle (D-004) avec une clé EdDSA propre au fork et un `appcast.xml` servi depuis le fork (releases GitHub). À vérifier : comportement de Gatekeeper sur une mise à jour non notarisée (D-003). Variante minimale : simple vérification des releases GitHub avec notification, sans installation automatique. |
| **À faire :** pipeline de build via GitHub Actions | Côme, 2026-10-21 | Faisable : les runners macOS sont gratuits pour un repo public, et `xcodebuild` y tourne. Limites : pas de compte payant, donc build non signé ou signé ad hoc (et widget à revérifier dans ce cas), pas de notarisation ; il faut vérifier quelle version d'Xcode les runners proposent. Créer un workflow qui publie demande l'accord de Côme (CLAUDE.md § 9). Se combine avec la ligne précédente (le CI produit les releases et l'appcast). |
| Interface : icônes de la barre d'outils plus grandes (≈ 18 pt, sans cercle), texte des lignes en 13 pt, séparateurs en retrait, liste sans carte | Claude, comparaison avec Parcel/BetterDisplay, 2026-10-21 | Côme préfère laisser tel quel pour l'instant |
| Nouvelle source : lignes `bluetoothd` catégorie `CBPowerSource` (« Power source updated … Nm '…', AcCa Mouse, … Battery -85% ») | Claude, 2026-10-21 | Contiennent la batterie de tous les accessoires telle que macOS la voit (MX Anywhere 3, AirPods…), avec nom, catégorie, VID/PID. Dépend du format des logs (fragile), à mesurer côté CPU |
| Afficher la santé et les cycles de la batterie du Mac | Claude, 2026-10-21 | Clés sur Apple Silicon/macOS 27 : `CycleCount` (1er niveau), `BatteryData.DesignCapacity` et `BatteryData.NominalChargeCapacity` (mAh) ; `MaxCapacity` est un % |
| ~~**À faire :** remplacer `print()` par `os.Logger`~~ Fait : D-019, branche `chore/os-logger` — (sous-système `io.github.msieurpafi.AirBattery`) | Claude, 2026-10-21 ; retenu par Côme le 2026-10-25 | Logs visibles dans `log stream`, filtrables, et non perdus dans un tampon stdout |
| Au lancement, un iPhone autorisé en Bluetooth apparaît d'abord avec l'icône Bluetooth générique (appareil BLE nommé « iPhone ») avant d'être reconnu | Claude, captures de Côme, 2026-10-25 | Conséquence de l'indexation par nom (ARCHITECTURE, points faibles) : deux sources écrivent sous le même nom. À traiter avec l'indexation par identifiant |
