# Étude — Nearcast v2

> Étude du 2026-10-27, demandée par Côme (issue [#41](https://github.com/MsieurPafi/AirBattery-Plus/issues/41)). Rien n'est implémenté : ce document sert à décider.
> Sources lues : `AirBattery/Supports/Multipeer.swift` et `Supports.swift` (fork, `main` @ `58c98ef`), `AirBattery-Mobile/AirBattery-Mobile/Multipeer.swift` (client iOS officiel, archive locale, dernier commit `31dad3e`, version 0.1.3), MultipeerKit 0.4.0 (`Sources/MultipeerKit/Public API/MultipeerConfiguration.swift`, `Internal API/MultipeerConnection.swift`), `docs/dev/AUDIT-2026-10-25.md` (priorité 2).

## 1. Ce que fait Nearcast aujourd'hui (v1)

- **Transport :** MultipeerKit (Multipeer Connectivity d'Apple), type de service `airbattery-nc`, configuration `security: .default` = **aucun chiffrement de transport** (`encryptionPreference: .none`) et **toute invitation acceptée** ; `invitation: .automatic` = chaque pair découvert est invité.
- **Message :** JSON `NCMessage { id, sender, command, content }`.
  - `id` = les 15 premiers caractères du Group ID (`nc-` + 12 caractères), **en clair** : sert à filtrer les groupes.
  - `sender` = UUID matériel du Mac (`systemUUID`) ou nom de l'appareil, **en clair**.
  - `command` = `""` (données), `"resend"` (demande d'envoi), `"notify"` (alerte), `"trans"` (inutilisé) ; **en clair**.
  - `content` = AES-GCM (CryptoKit) de la liste des appareils en JSON, ou d'une notification, encodé en base64.
- **Clé :** HKDF-SHA256 avec pour secret les **8 derniers caractères** du Group ID (62⁸ ≈ 2⁴⁷,⁶) et pour sel les 15 premiers, connus de tous (`id`). Une seule dérivation, rapide : un message capté permet de chercher la clé hors ligne (estimation de l'analyse : de l'ordre d'une journée de GPU, *supposé*).
- **Mac :** répond à `resend`, diffuse ses données à chaque intervalle (± 9 s), relaie les alertes de batterie (`notify`), enregistre les données reçues dans `…/NearcastData/<sender>.json`.
- **Client iOS (AirBattery-Mobile 0.1.3) :** même configuration MultipeerKit, même dérivation de clé, mêmes 23 caractères de Group ID. Il **reçoit seulement** les messages de données (`command == ""`) et envoie `resend` à l'ouverture. Distribué hors App Store (AltStore / SideStore), plus maintenu depuis 2024, comme l'app Mac d'origine.

### Correctifs d'attente déjà livrés (1.10.0, PR #36)

Noms de fichiers sûrs (`ncFileName`), écritures atomiques, plus de connexion Bluetooth déclenchée à distance (type 254), plus d'écho des commandes inconnues.

### Ce qui reste faible

| # | Faiblesse | Conséquence concrète |
|---|---|---|
| 1 | Secret de ~47,6 bits, sel public | Quelqu'un sur le même réseau qui capte un message peut retrouver la clé et lire (noms d'appareils, niveaux) ou forger des messages |
| 2 | `sender`, `command` hors du chiffrement | Un message chiffré capté peut être réutilisé avec une autre commande ou un autre expéditeur |
| 3 | Pas de protection contre le rejeu | Un vieux message (données ou alerte) peut être rejoué à volonté |
| 4 | Transport sans chiffrement, invitations acceptées | N'importe quel appareil du réseau entre dans la session |
| 5 | UUID matériel du Mac en clair | Identifiant stable et unique diffusé sur le réseau |
| 6 | `NSBonjourServices` absent de l'`Info.plist` | Depuis macOS 15, la découverte Bonjour pourrait être bloquée par la confidentialité du réseau local : **Nearcast v1 ne marche peut-être plus du tout** sur macOS récent. *Non vérifié* (il faut deux appareils) |

**Mesure du risque :** Nearcast est désactivé par défaut et ne circule que sur le réseau local. Les données sont des niveaux de batterie et des noms d'appareils. Les deux failles graves (écriture de fichiers, connexion Bluetooth à distance) sont déjà fermées. Ce qui reste relève de la confidentialité et de l'intégrité sur un réseau partagé (café, bureau, résidence), pas d'une prise de contrôle du Mac.

## 2. Proposition de protocole v2

Objectif : un protocole simple, entièrement testable en tests unitaires (logique dans `Shared/Core`, comme D-025 et D-028), sans dépendance nouvelle (CryptoKit suffit).

1. **Nouveau code de groupe :** `nc2-` suivi de 26 caractères en base32 (sans caractères ambigus), soit **130 bits** de secret, tirés par `SystemRandomNumberGenerator`. Affiché avec un bouton Copier, éventuellement un QR code plus tard. Les anciens Group ID ne sont pas réutilisables (trop courts).
2. **Clés :** HKDF-SHA256 depuis le secret, sel fixe du protocole (`"AirBattery Plus Nearcast v2"`), deux sorties distinctes par `info` :
   - `"encryption"` → clé AES-GCM 256 bits ;
   - `"group-tag"` → clé HMAC pour une **étiquette de groupe** de 8 octets, qui remplace le préfixe en clair : elle permet d'écarter les messages des autres groupes sans rien révéler du secret.
3. **Message :** `{ "v": 2, "tag": <étiquette>, "box": <AES-GCM combiné> }`, rien d'autre en clair.
   - Dans le chiffré : identifiant d'expéditeur **aléatoire par installation** (plus d'UUID matériel), nom affiché, commande, horodatage, compteur, contenu.
   - Données associées (AAD) de l'AES-GCM : version + étiquette.
4. **Rejeu :** refus si l'horodatage s'écarte de plus de 5 min de l'heure locale, ou si le compteur d'un expéditeur ne dépasse pas le dernier reçu.
5. **Transport :** type de service distinct (`airbattery-n2`), MultipeerKit avec `encryptionPreference: .required`, invitation personnalisée (`.custom`) qui transporte un jeton calculé avec la clé de groupe ; l'invité vérifie ce jeton avant d'accepter. Les appareils hors du groupe n'entrent plus dans la session. (Le chiffrement de transport sans identité ne protège pas contre une interception active : la vraie protection reste celle du message.)
6. **Commandes :** données, demande d'envoi, alerte. Les alertes ne sont affichées que si elles viennent d'un pair authentifié et récent.
7. **Fichiers :** nom = hachage de l'identifiant d'expéditeur (déjà le cas avec `ncFileName` pour les noms douteux).
8. **`Info.plist` :** déclarer `NSBonjourServices` (`_airbattery-n2._tcp`, `_airbattery-n2._udp`, et ceux de v1 si on garde la compatibilité).

**Effort estimé (Claude) :** protocole et tests unitaires, environ une journée de travail ; intégration (réglages, migration du Group ID, documentation EN/FR), une demi-journée ; la compatibilité v1 (section 3) ajoute une demi-journée. **Il faut deux appareils pour tester** : deux Mac, ou un Mac et l'iPhone si on adapte aussi le client iOS. Sans second Mac, seule la partie testable en unitaire serait vérifiée.

## 3. Réponse à la question de Côme : peut-on faire coexister v1 et v2 ?

**Oui, techniquement.** L'app peut faire tourner les deux en parallèle : deux transceivers MultipeerKit sur deux types de service (`airbattery-nc` pour v1, `airbattery-n2` pour v2), chacun avec son code de groupe. Le Mac envoie ses données dans les deux formats et lit les deux. C'est d'ailleurs la seule façon de rester compatible, car les deux ne peuvent pas partager une même session : v2 exige le chiffrement de transport, que les pairs v1 n'acceptent pas.

**Mais la coexistence a un coût, et il faut le dire clairement :**

1. **La sécurité retombe au niveau de v1 tant que v1 est active.** Les mêmes données (niveaux, noms d'appareils) partent aussi en v1, avec la clé de 47 bits : quelqu'un qui casse la clé v1 lit tout ce que v2 protégeait. Côté réception, accepter des messages v1, c'est accepter des données et des alertes forgeables et rejouables.
2. **Deux codes à gérer :** l'ancien Group ID (23 caractères) pour v1, le nouveau pour v2. Plus de réglages, plus de confusion possible.
3. **Plus de code à maintenir et à tester**, pour un usage qui ne concerne qu'un cas.
4. **Qui a vraiment besoin de v1 ?**
   - Les Mac avec l'AirBattery officielle ou une ancienne version du fork : ils peuvent passer à AirBattery Plus, qui se met à jour seul depuis la 1.11.0.
   - **Le client iOS officiel (AirBattery-Mobile)** : il ne sera jamais mis à jour par son auteur. C'est le seul cas où v1 est indispensable, sauf si on adapte aussi le client iOS (ses sources sont dans `AirBattery-Mobile/`, en AGPL : on peut le forker, mais l'installer demande de le compiler et de le réinstaller tous les 7 jours avec un compte gratuit, ou un compte payant).

**Recommandation :**

- **v2 par défaut**, seule active à l'installation.
- **Option « Compatibilité avec les anciennes versions (v1) »**, désactivée par défaut, avec un avertissement (« moins sûr : à n'activer que pour l'app iOS ou un ancien Mac »). Quand elle est activée :
  - le Mac **envoie** ses données en v1 et répond aux demandes d'envoi v1 (ce dont le client iOS a besoin) ;
  - il **affiche** les données reçues de Mac v1, marquées comme telles ;
  - il **n'affiche aucune alerte reçue en v1** (forgeable).
- Garder v1 tant que le client iOS n'a pas d'équivalent v2, puis la retirer dans une version majeure annoncée.

## 4. Décisions à prendre (Côme)

1. **Utilises-tu Nearcast** (plusieurs Mac) **ou l'app iOS AirBattery-Mobile** ? Si ni l'un ni l'autre, v2 n'a pas d'utilisateur pour l'instant : on peut la garder en réserve.
2. **As-tu un second Mac**, ou un Mac d'un proche, pour tester ? Sans ça, seuls les tests unitaires vérifieraient v2.
3. **Coexistence :** option v1 désactivée par défaut (recommandé), v1 toujours active, ou rupture nette.
4. **Client iOS :** le laisser tel quel (compatibilité v1 seulement) ou envisager un fork v2 (projet séparé, Phase 3, contrainte de signature).
5. **Avant tout le reste, vérifier que Nearcast v1 fonctionne encore** sur macOS 27 (point 6 du tableau). Si la découverte est bloquée faute de `NSBonjourServices`, c'est un correctif à part, petit, qui conditionne aussi la compatibilité v1.
