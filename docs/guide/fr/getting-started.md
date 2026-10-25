# Prise en main

[Guide](README.md) · [English](../en/getting-started.md)

## Configuration requise

- macOS 12 ou plus récent. Testé sur macOS 27 (Apple Silicon).
- AirBattery Plus peut être installée à côté de l'AirBattery officielle : elles ne partagent ni réglages, ni widgets, ni outil en ligne de commande.

## Installation

1. Téléchargez le DMG sur la [page des versions](https://github.com/MsieurPafi/AirBattery/releases). Chaque version indique l'empreinte SHA-256 du fichier.
2. Ouvrez le DMG et glissez **AirBattery Plus** dans Applications.
3. L'app n'est pas notarisée par Apple : au premier lancement, macOS la bloque. Ouvrez **Réglages Système › Confidentialité et sécurité**, faites défiler et cliquez sur **Ouvrir quand même** en face d'AirBattery Plus.

## Mise à jour

Il n'y a pas encore de mise à jour automatique : suivez les versions du dépôt sur GitHub pour être prévenu des nouveautés.

1. Quittez AirBattery Plus (icône de la barre des menus › ⓧ).
2. Installez la nouvelle version comme ci-dessus, en remplaçant l'ancienne. Vos réglages sont conservés.
3. macOS redemande si AirBattery Plus peut rechercher des appareils sur le réseau local : autorisez-la. L'autorisation est liée à la version exacte de l'app.

Après une mise à jour, macOS peut continuer d'afficher l'ancienne icône de l'app quelque temps : il garde les icônes en cache et les rafraîchit de lui-même, ou à la prochaine ouverture de session.

## Premier lancement

AirBattery Plus demande quelques autorisations. Leur raison d'être est expliquée dans [Autorisations et confidentialité](permissions-privacy.md).

- **Bluetooth** : pour lire les AirPods, les Beats et les accessoires Bluetooth.
- **Réseau local** : pour l'iPhone, l'iPad et l'Apple Watch en Wi-Fi, et pour Nearcast.
- **Notifications** : pour les alertes de batterie.

Par défaut, l'app s'affiche dans la barre des menus. Cliquez sur son icône pour voir vos appareils. Pour l'afficher aussi dans le Dock, ou seulement là, voir **Settings › General › Show AirBattery Plus**.

La plupart des appareils apparaissent d'eux-mêmes. Un iPhone, un iPad ou une Apple Watch demandent une étape de plus : voir [Appareils pris en charge](devices.md#iphone-ipad-et-apple-watch).
