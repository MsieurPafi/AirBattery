# Appareils pris en charge

[Guide](README.md) · [English](../en/devices.md)

AirBattery Plus lit les batteries par plusieurs moyens, que l'on active ou désactive chacun dans **Settings › Nearbility**.

## Ce Mac

La batterie d'un MacBook, telle qu'elle apparaît dans la barre des menus de macOS. Toujours active.

## iPhone, iPad et Apple Watch

Lus avec le protocole qu'utilise le Finder pour synchroniser un iPhone, en USB ou en Wi-Fi (**Discover iOS devices via Network**).

1. Branchez une fois l'iPhone ou l'iPad au Mac avec un câble, déverrouillez-le et touchez **Se fier**.
2. Dans le Finder, sélectionnez l'appareil, cochez **Afficher cet iPhone en Wi-Fi**, puis cliquez sur **Appliquer**.
3. Laissez l'appareil sur le même réseau que le Mac : il apparaît alors sans câble.

L'**Apple Watch** est lue par l'intermédiaire de son iPhone : elle apparaît dès que son iPhone est autorisé, sans autre étape. Après un changement d'iPhone, refaites les étapes 1 et 2 avec le nouveau, sinon la Watch disparaît.

### iPhone et iPad en Bluetooth

Pour un iPhone ou un iPad cellulaire qui n'est pas sur le réseau du Mac (**Discover iOS devices via Bluetooth**) :

1. Activez l'option, puis cliquez sur **Authorized iOS Bluetooth Devices › Manage**.
2. Ouvrez **Partage de connexion** sur l'iPhone et approchez-le du Mac.
3. Sélectionnez votre appareil dans la liste des appareils Apple à proximité et autorisez-le. iOS peut afficher une fois une demande de jumelage.

AirBattery Plus ne se connecte qu'aux appareils autorisés à cet endroit. Un iPhone trouvé en Bluetooth ne donne pas accès à son Apple Watch.

### Apple Pencil

**Apple Pencil from your iPad** lit la batterie de l'Apple Pencil par l'intermédiaire de l'iPad. C'est une fonction en bêta : trouver le Pencil peut prendre 10 minutes ou plus la première fois, et l'iPad peut se décharger plus vite.

## AirPods et Beats

Lus à partir des messages Bluetooth qu'ils émettent quand on ouvre le boîtier ou qu'on utilise les écouteurs : boîtier, écouteur gauche et droit. Quand les deux écouteurs sont à moins de 5 % d'écart, ils s'affichent comme un seul appareil (**Earbud Merging Threshold**, Settings › Nearbility).

## Magic Keyboard, Mouse, Trackpad et autres accessoires Bluetooth

**Discover BT and BLE devices** lit les accessoires dont macOS connaît la batterie : les accessoires Magic d'Apple, et beaucoup de claviers, souris et casques.

Si l'un des vôtres manque :

- **Discover more BT devices** lit davantage d'appareils Bluetooth d'autres marques. Leur batterie se met à jour quand ils se reconnectent au Mac ou quand le Mac sort de veille.
- **Discover more BLE devices** essaie de lire la batterie de n'importe quel appareil Bluetooth basse consommation à proximité (par exemple une souris Logitech MX). C'est une fonction en bêta. Si un appareil qui n'est pas à vous demande un jumelage, masquez-le (voir [Utiliser l'app](using-the-app.md#masquer-un-appareil)).

## Autres Mac

Avec [Nearcast](nearcast.md), la batterie de vos autres Mac, et celle de leurs propres appareils, apparaît aussi.

## Actualisation

Les batteries sont relues à chaque **Refresh Interval** (1 minute par défaut, Settings › Nearbility). Un appareil qui ne s'est pas manifesté depuis plus de dix minutes est marqué d'un ⚠️ devant son nom : il est peut-être éteint ou hors de portée.
