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
| Batterie des périphériques BLE HID déjà connectés (`retrieveConnectedPeripherals` + `180F`/`2A19`) | Côme (MX Anywhere 3), 2026-10-21 | Plutôt un correctif qu'une feature ; voir COMPAT note 1 |
| `abt` : lire les données hors du container sandboxé du widget | Claude, 2026-10-21 | Voir COMPAT note 2 |
