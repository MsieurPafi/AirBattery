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
| #200 | Liquid Glass | **non repris**, inspiration seulement (D-012) | Mélange l'interface et d'autres sujets (lancement au login via `SMAppService.loginItem`, cible de déploiement, widgets), dont une partie entre en conflit avec `main`. Applique `glassEffect` sur des panneaux par-dessus le verre du popover (verre sur verre) avec des rayons fixes (5/10 pt), sans traiter la concentricité. Ses changements de lancement au login et de widgets restent à évaluer séparément. |
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

### Inventaire et suivi (2026-10-21)

Établi en lisant le diff `134e02f..callie/main` fichier par fichier (ses commentaires citent les issues) et en vérifiant ses affirmations sur le Mac de Côme. Crédit : `Co-authored-by: callieskye <315995303+callieskye@users.noreply.github.com>`.

**Couvert ou sans objet**

| Élément | Statut | Pourquoi |
| --- | --- | --- |
| Verrous `NSLock` (#124, #128, #111) | couvert | PR #216 (D-008), qui traite en plus la capture d'`IOBluetoothDevice` |
| `EXC_GUARD` (#207) | couvert | même cause trouvée, corrigé dans `0b75d57` |
| Popups d'appairage (#169) | remplacé | PR #214 (D-009) ; sa version filtrait par nom d'appareil appairé |
| Identifiant, Sparkle | couvert | D-002, D-004 |
| `NSBluetoothAlwaysUsageDescription` (#80) | **sans objet** | déjà présent via `INFOPLIST_KEY_…` dans le projet ; vérifié dans l'app installée |
| `grep "\d"` cassé sous BSD (commentaire dans `logReader.sh`) | **faux sur macOS 27** | `echo ", Battery M +85%" \| grep -o "\d*"` renvoie `85` |
| Filet anti-doublons dans `getAll()` (#127, #109) | non repris | redondant : `updateDevice` ajoute/remplace sous verrou depuis D-008 |
| macOS 14 minimum, `NavigationSplitView` | non repris | demanderait une décision sur la cible de déploiement (D-007 = 12.0) |

**Correctifs (par lot)**

| # | Élément | Lot | Statut |
| --- | --- | --- | --- |
| 1 | Force-unwraps `ideviceinfo`/`comptest` | 1 | **porté** `6ea85bb` (helper `parseBattery`) |
| 2 | Délai maximal `comptest` (#198) | 1 | **porté** `6ea85bb` (15 s) |
| 3 | Niveaux AirPods bornés à 100 (#76) | 1 | **porté** `7dd363b` |
| 4 | Fabricant Apple avant découpe boîtier/G/D (#106) | 1 | **porté** `f64e3bc` (dans `MagicBattery.getAirpods()`, fonction non appelée) |
| 5 | Force-casts `logReader.sh` / IOKit | 1 | **porté** `f64e3bc` |
| 6 | Minuteur indépendant iPhone/iPad/Watch (#91) | 2 | **porté autrement** `b7757d0` : **non reproduit** sur macOS 27.0.1 (la vue du Dock tourne même sans icône), mais le scan lançait `idevice_id` ×2 **toutes les 5 s** → minuteur propre de 15 s |
| 7 | Alertes de batterie jamais envoyées (#78) | 2 | **porté** `d069d4e` (`return` → `continue`) ; partie « minuteur » non reproduite (même raison que 6) |
| 8 | Appareils BT tiers connectés après le lancement (#91, Bose) | 2 | **non repris** : `deviceIsConnected` relance déjà `LogReader.run(.connect)` à chaque connexion ; sa solution relisait les logs à chaque cycle (coût CPU, #59/#163) |
| 9 | Pas de reconnexion en boucle aux BLE sans batterie (#132), déconnexion après lecture (#178) | 4 | **porté** `2d29f99`, testé (voir JOURNAL) |
| 10 | AirPods nommés « iPhone » sur macOS 26 (#172) | 4 | **porté** `985e256` (non reproductible ici : AirPods correctement nommés) |
| 11 | `logReader.sh` : nom sans PID (#137), catégorie `CBPowerSource`, MAC par le nom | 4 | **non repris** : 0 ligne `Battery M` en 12 h chez Côme ; les lignes `CBPowerSource` ont un autre format (`… Battery -85%`, sans `M` ni `BDA`) que le script ne sait pas lire, donc ajouter la catégorie n'aurait aucun effet (voir IDEAS.md) |
| 12 | Batterie du Mac : % avec limite de charge, santé (unités), cycles imbriqués (#152) | 3 | % : **porté** `020bf44` (`IOPowerSources`), cas « limite de charge » non vérifié ; santé et cycles **non repris** (non affichés ; `AppleRawMaxCapacity` absent sur macOS 27) |
| 13 | Icônes AirPods 4 ANC (#166), AirPods Max (#204/#205), MacBook Neo (#195) | 5 | **porté** `d17f054` ; correspondance « airpods max » au lieu de « max » (évite « Maxime ») ; non repris : icône Pro par défaut (pari), Siri Remote (image `appletvremote.gen1` absente des ressources → plantage) |
| 14 | Survol Nearcast (#159), icône épinglée figée, texte de survol écrasé | 5 | #159 **porté** `6db2a6a` ; icône épinglée **portée** `27f28da` (sans le `!`, avec un cache vidé au désépinglage) ; texte écrasé **non repris** (causé par les 2 boutons qu'elle avait ajoutés ; sa solution supprimait « il y a X min ») |
| 15 | `autosaveName` des icônes de barre des menus (#182) | 5 | **porté** `27f28da` ; effet sur Thaw non démontré (voir COMPAT note 7) |

**Fonctions (au choix de Côme)** — tri de la liste (#56, #188) **réimplémenté** `63fdc33` (PR #15, version 1.7.2). Les autres sont **non retenues** pour l'instant (décision de Côme, 2026-10-22, sur l'avis de Claude) :

| Fonction | Pourquoi non retenue |
| --- | --- |
| Sourdine des alertes par appareil (#135) | l'app a déjà des alertes **par appareil** (seuils « faible » / « chargé » réglables) : il suffit de ne pas en créer |
| Alerte batterie faible avec seuil | doublon global des alertes par appareil existantes |
| Bascule du mode économie d'énergie (#117/#129) | `pmset -a lowpowermode` exige les droits administrateur (échec silencieux sinon) ; hors du sujet « batterie des accessoires » |
| Écouteurs toujours séparés (#116) | quasi couvert par « Earbud Merging Threshold » réglé à 1 |
| Copier l'identifiant (#108) | utile au débogage seulement |
| Fond blanc du widget (#119) | cosmétique, peu cohérent avec les widgets de macOS 26/27 |
| Barre de batterie des épinglés (#100) | cosmétique |
| Astuce Watch/Pencil au premier lancement (#95/#136) | **à reconsidérer si le fork devient public** (aide aux nouveaux utilisateurs) |
| Siri Remote (#85) | non vérifiée par l'autrice ; image `appletvremote.gen1` absente → plantage |

Pour la concurrence, voir D-008 : son code ne corrige pas la capture de `device` dans `deviceIsConnected`.
