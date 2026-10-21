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
| **À faire :** soucis d'UI signalés par Côme (détails à recueillir avec lui) | Côme, 2026-10-21 | Pense-bête, pas encore décrit |
| Remplacer `print()` par `os.Logger` (sous-système `io.github.msieurpafi.AirBattery`) | Claude, 2026-10-21 | Logs visibles dans `log stream`, filtrables, et non perdus dans un tampon stdout |
