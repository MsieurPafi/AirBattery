# Contournements

Chaque contournement en place dans le code : pourquoi, où, comment le retirer un jour.

## W-001 — Cible de déploiement forcée en ligne de commande   (retiré le 2026-10-21, `138b433`)
**Pourquoi :** Xcode 27.1 n'accepte plus `MACOSX_DEPLOYMENT_TARGET = 11.0` (minimum 12.0). Le changer dans le projet demande l'accord de Côme (D-007, proposée).
**Où :** pas dans le code ; dans la commande de build : `xcodebuild … MACOSX_DEPLOYMENT_TARGET=12.0 build`.
**Comment le retirer :** dès que D-007 est acceptée, changer la valeur dans le projet (8 occurrences dans `project.pbxproj`) et retirer l'option.
**Retiré :** D-007 acceptée, cible passée à 12.0 dans le projet. Correction : il y avait 10 occurrences (2 au niveau projet + 8 dans les targets), pas 8.

## W-002 — Builds sans signature   (retiré le 2026-10-21)
**Pourquoi :** l'équipe personnelle de Côme (`PCH7VR8GPS`) est configurée, mais le trousseau ne contient encore aucun certificat « Apple Development » (`security find-identity -v -p codesigning` → `0 valid identities found`).
**Où :** dans la commande de build : `CODE_SIGNING_ALLOWED=NO`.
**Comment le retirer :** créer le certificat (Xcode › Réglages › Comptes › Gérer les certificats, ou un build avec `-allowProvisioningUpdates`), puis builder sans l'option.
**Retiré :** Côme a créé le certificat « Apple Development » dans Xcode ; le build signé passe sans `-allowProvisioningUpdates` (aucun profil nécessaire).

<!-- Modèle :
## W-001 — <titre>
**Pourquoi :** …
**Où :** `fichier.swift:ligne`
**Comment le retirer :** …
-->
