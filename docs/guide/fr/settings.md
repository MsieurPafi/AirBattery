# Réglages

[Guide](README.md) · [English](../en/settings.md)

Ouvrez les réglages avec ⚙︎ en haut de la liste des appareils. Les valeurs par défaut sont entre crochets.

## General

- **Launch at Login** [désactivé] : ouvrir l'app à l'ouverture de session.
- **Show AirBattery Plus** : Dock, Menu Bar, Both ou None [Menu Bar]. Voir [Utiliser l'app](using-the-app.md#affichage).
- **Command Line Tool** : installe ou supprime `abtp` ([Ligne de commande](command-line.md)).

## Menu Bar & Dock

Barre des menus :

- **Dynamic Battery Icon** [activé] : l'icône de la barre des menus affiche la batterie de ce Mac.
- **Colorful Battery Icon**, **Battery Icon Style** (macOS ou iOS), **Show Percentage** (masqué, dans l'icône ou à côté).
- **Remove Offline Device** [après 20 min] : les appareils qui ne se manifestent plus quittent la liste.
- **Sort Devices** [Default] : par nom, batterie la plus faible ou la plus élevée d'abord. S'applique aussi à l'icône du Dock et aux widgets.
- **Hide percentage when above** [90 %] : à côté des icônes de batterie, le pourcentage est masqué au-dessus de ce niveau.

Dock :

- **Appearance** : automatique, clair ou sombre.
- **Built-in Battery Style** : affiche la batterie de ce Mac dans l'icône du Dock sous forme d'icône ou de pourcentage, ou la masque.
- **Carousel Mode** [activé] : l'icône du Dock fait défiler tous vos appareils.

## Nearbility

Les sources de lecture des batteries (détails dans [Appareils pris en charge](devices.md)) :

- **Discover iOS devices via Network** [activé] : iPhone, iPad, Apple Watch en USB ou en Wi-Fi.
- **Discover iOS devices via Bluetooth** [désactivé], avec **Authorized iOS Bluetooth Devices › Manage**.
- **Discover BT and BLE devices** [activé], **Discover more BT devices** [activé], **Discover more BLE devices** [désactivé, bêta].
- **Apple Pencil from your iPad** [désactivé, bêta].
- **Refresh Interval (min)** [1] : fréquence de lecture des batteries. Relancez l'app pour appliquer un changement.
- **Earbud Merging Threshold** [5] : en dessous de cet écart, les écouteurs gauche et droit s'affichent comme un seul appareil.

## Nearcast

Activation de Nearcast et Group ID : voir [Nearcast](nearcast.md). **Peer Info** affiche l'identifiant de ce Mac dans le groupe.

## Widget

- **Reverse Device List** : inverse l'ordre de la liste.
- **Refresh Interval** : identique à Nearbility [par défaut], ou laissé à macOS.
- **Single Device Widget** (macOS 12 et 13 seulement).
- **Reload All Widgets** : si un widget semble figé.

## Blocklist

Les appareils de cette liste sont masqués. Avec **Allowlist Mode**, la liste fonctionne à l'inverse : seuls les appareils listés sont affichés.
