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
| #216 | Concurrence / crash au réveil | à évaluer | prioritaire |
| #214 | Plus de connexion BT auto aux iOS | à évaluer | change le comportement, valider avec Côme |
| #210 | Wi-Fi privée iOS (`syncmac`) | à évaluer | recompiler le binaire, ne pas l'intégrer tel quel |
| #211 | Mode d'énergie | hors périmètre | cf. IDEAS.md |
| #200 | Liquid Glass | à évaluer | |
| #191 | Souris Roccat | à évaluer | |
| #170 | Traduction française | à évaluer | |
| #164 | CLI `supported` | à évaluer | |
| #202 | « Update Supports.swift » | à évaluer | |

## « 1.6.4 Community Patch » (issue #208)

Binaire non audité : ne pas l'exécuter. Sources publiques : non trouvées à ce jour.
