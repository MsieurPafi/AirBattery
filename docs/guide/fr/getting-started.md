# Prise en main

[Guide](README.md) · [English](../en/getting-started.md)

## Configuration requise

- macOS 12 ou plus récent. Testé sur macOS 27 (Apple Silicon).
- AirBattery Plus peut être installée à côté de l'AirBattery officielle : elles ne partagent ni réglages, ni widgets, ni outil en ligne de commande.

## Installation

1. Téléchargez le DMG sur la [page des versions](https://github.com/MsieurPafi/AirBattery-Plus/releases). Chaque version indique l'empreinte SHA-256 du fichier.
2. Ouvrez le DMG et glissez **AirBattery Plus** dans Applications.
3. L'app n'est pas notarisée par Apple : au premier lancement, macOS la bloque. Ouvrez **Réglages Système › Confidentialité et sécurité**, faites défiler et cliquez sur **Ouvrir quand même** en face d'AirBattery Plus.
4. Pour qu'AirBattery Plus puisse ensuite installer ses mises à jour elle-même, lancez une fois cette commande dans le Terminal, puis relancez l'app :

   ```bash
   xattr -dr com.apple.quarantine "/Applications/AirBattery Plus.app"
   ```

   macOS met en quarantaine les apps téléchargées avec un navigateur, ce qui bloque la mise à jour d'une app non notarisée. **Réglages › Général › Mise à jour** rappelle cette commande, avec un bouton pour la copier, tant qu'elle est nécessaire.

## Mise à jour

AirBattery Plus trouve elle-même les nouvelles versions. À son deuxième lancement, elle demande si elle peut rechercher automatiquement les mises à jour ; vous pouvez changer ce choix plus tard dans **Réglages › Général › Mise à jour**, ou vérifier tout de suite avec **Rechercher des mises à jour…** en bas des réglages. Les mises à jour viennent des versions publiées sur GitHub, et ne sont installées que si elles portent la signature du projet. macOS peut ensuite redemander l'accès au réseau local (étape 3 ci-dessous).

Les versions jusqu'à la 1.10.0 ne se mettent pas à jour seules. Pour mettre à jour à la main :

1. Quittez AirBattery Plus (icône de la barre des menus › ⓧ).
2. Installez la nouvelle version comme ci-dessus, en remplaçant l'ancienne. Vos réglages sont conservés.
3. macOS peut redemander si AirBattery Plus peut rechercher des appareils sur le réseau local : autorisez-la. L'autorisation est liée au code de l'app, donc macOS la redemande après la plupart des mises à jour.

Après une mise à jour, macOS peut continuer d'afficher l'ancienne icône de l'app quelque temps : il garde les icônes en cache et les rafraîchit de lui-même, ou à la prochaine ouverture de session.

## Premier lancement

AirBattery Plus demande quelques autorisations. Leur raison d'être est expliquée dans [Autorisations et confidentialité](permissions-privacy.md).

- **Bluetooth** : pour lire les AirPods, les Beats et les accessoires Bluetooth.
- **Réseau local** : pour l'iPhone, l'iPad et l'Apple Watch en Wi-Fi, et pour Nearcast.
- **Notifications** : pour les alertes de batterie.

Par défaut, l'app s'affiche dans la barre des menus. Cliquez sur son icône pour voir vos appareils. Pour l'afficher aussi dans le Dock, ou seulement là, voir **Réglages › Général › Afficher AirBattery Plus**.

La plupart des appareils apparaissent d'eux-mêmes. Un iPhone, un iPad ou une Apple Watch demandent une étape de plus : voir [Appareils pris en charge](devices.md#iphone-ipad-et-apple-watch).

## Langue

AirBattery Plus est en français et en anglais (et en chinois, avec une traduction plus ancienne). Elle suit les langues choisies dans **Réglages Système › Général › Langue et région**, et à défaut s'affiche en anglais. Pour lui donner une autre langue qu'au reste du système, ajoutez-la dans la section **Applications** du même panneau.
