# Upstream

Ce qu'on a repris, ou pas, de l'upstream `lihaoyun6/AirBattery`, et pourquoi.

Base du fork : `main` @ `134e02f` (2025-11-02), soit le tag `1.6.3` + 11 commits jamais publiés (#161, #162, #163, #177).

Les têtes de PR de l'archive locale sont disponibles dans `archive/pr/<N>` (`git fetch archive`). Les PR plus récentes que l'archive (≥ 204) se récupèrent avec `git fetch upstream pull/<N>/head:upstream-pr-<N>`.

## PR

| PR | Sujet | Statut | Pourquoi |
| --- | --- | --- | --- |
| #161 | Lancement au login (`SMAppService`) | dans la base | non publié, à valider en usage |
| #162 | `ProcessInfo.beginActivity` | dans la base | non publié, à valider (#203, #153/#160) |
| #163 | CPU du parsing de logs | dans la base | non publié, à valider |
| #177 | Correctif popup (#176) | dans la base | |
| #216 | Concurrence / crash au réveil | **repris**, fusionné dans `main` le 2026-10-21, en observation | D-008. `a8614c4` → `7b06120`, `befadc9` → `d4af77a` (cherry-pick `-x`, auteur conservé ; conflit sur `AirBatteryModel.key` résolu en gardant `AppIdentifiers.widget`). `0ca1233` (import) non repris : déjà fait dans `774c380`. Libellé de la file renommé (`59a054d`). |
| #214 | Plus de connexion BT auto aux iOS | **repris** (D-009) | cherry-pick `-x` de `3f2a6eb` « only connect iOS devices authorized by the user », `781f750` et `ceaede7` (UI de la fenêtre), `c9f9505` « fix retry state, show failure reason » → `7ca2817`, `0737d17`, `5710d86`, `709c794`. `aa85210` (import) sauté : déjà dans `774c380`. Testé par Côme le 2026-10-21. |
| #210 | Wi-Fi privée iOS (`syncmac`) | à évaluer | recompiler le binaire, ne pas l'intégrer tel quel |
| #211 | Mode d'énergie | hors périmètre | cf. IDEAS.md |
| #200 | Liquid Glass | à évaluer | |
| #191 | Souris Roccat | à évaluer | |
| #170 | Traduction française | à évaluer | |
| #164 | CLI `supported` | à évaluer | |
| #202 | « Update Supports.swift » | à évaluer | |

## Issues upstream traitées

| Issue | Statut | Notes |
| --- | --- | --- |
| #207 | **corrigée** (`perf/ble-scan`, `0b75d57`) | Le rapporteur soupçonnait « un port Mach mal libéré par une minuterie à 1 Hz » : c'est juste, mais ce n'est pas lié au Bluetooth. `IOServiceClose()` sur un service jamais ouvert, dans la lecture de la batterie du Mac. |
| #178 | piste (D-011) | Scan BLE actif divisé par deux ; gain non vérifiable chez Côme (pas de saccades). |

## « 1.6.4 Community Patch » (issue #208)

Binaire non audité : ne pas l'exécuter.

**Sources trouvées le 2026-10-21 :** `https://github.com/callieskye/Air-Battery` (« My personal fork of AirBattery », AGPL-3.0, release « V1.6.5 » du 2026-08-24). Ajouté en remote `callie` (fetch seul, push `DISABLED`). Historique : un « Initial import » (`7e9932b`) + 5 commits de README/CHANGELOG, **sans historique commun** avec l'upstream : pas de cherry-pick, portage manuel avec `Co-authored-by: callieskye`. Bundle ID `com.callieskye.AirBattery`, Sparkle retiré.

Le `CHANGELOG.md` du dépôt sert de liste de bugs diagnostiqués (chaque ligne cite une issue). Correctifs à évaluer en priorité : doublons d'appareils (#127), découpe AirPods sans vérification du fabricant (#106), niveaux bornés 0–100 % (#76), clé `NSBluetoothAlwaysUsageDescription` manquante (#80), regex des logs pour appareils sans PID (#137), minuterie indépendante pour iPhone/iPad (#91), `return` au lieu de `continue` dans les alertes (#78), nombre de cycles sur certains Apple Silicon (#152), non-reconnexion aux appareils BLE sans batterie (#132).

Pour la concurrence, voir D-008 : son code ne corrige pas la capture de `device` dans `deviceIsConnected`.
