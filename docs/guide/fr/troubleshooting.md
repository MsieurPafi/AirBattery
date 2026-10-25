# Dépannage

[Guide](README.md) · [English](../en/troubleshooting.md)

**macOS refuse d'ouvrir l'app.**
Elle n'est pas notarisée : autorisez-la une fois dans **Réglages Système › Confidentialité et sécurité › Ouvrir quand même**.

**Mon iPhone, iPad ou Apple Watch n'apparaît pas.**
Branchez une fois l'iPhone ou l'iPad au Mac avec un câble et touchez **Se fier**, puis cochez **Afficher cet iPhone en Wi-Fi** dans le Finder. Laissez-le sur le même réseau que le Mac, et vérifiez qu'AirBattery Plus a accès au réseau local (**Réglages Système › Confidentialité et sécurité › Réseau local**). Détails dans [Appareils pris en charge](devices.md#iphone-ipad-et-apple-watch).

**Mon Apple Watch a disparu quand j'ai changé d'iPhone.**
La Watch est lue par l'intermédiaire de son iPhone. Branchez une fois le nouvel iPhone avec un câble, touchez **Se fier** et cochez **Afficher cet iPhone en Wi-Fi**.

**Mon iPhone n'est pas en Wi-Fi.**
Utilisez **Rechercher les appareils iOS en Bluetooth** et autorisez-le dans **Gérer** (iPhone et iPad cellulaire seulement, sans l'Apple Watch).

**Un accessoire Bluetooth manque.**
Activez **Rechercher plus d'appareils BT**, puis déconnectez et reconnectez l'accessoire. S'il manque toujours, essayez **Rechercher plus d'appareils BLE** (bêta).

**Un appareil qui n'est pas à moi demande un jumelage.**
Il a été trouvé par **Rechercher plus d'appareils BLE**. Refusez, puis masquez cet appareil ou ajoutez-le à la liste de blocage.

**Un ⚠️ s'affiche devant un appareil.**
Il ne s'est pas manifesté depuis plus de dix minutes : il est peut-être éteint, en veille ou hors de portée.

**Un widget indique que l'app n'est pas lancée.**
Ouvrez AirBattery Plus. Si le widget semble encore figé : **Réglages › Widget › Recharger tous les widgets**.

**Après une mise à jour, l'ancienne icône s'affiche encore.**
macOS garde les icônes des apps en cache. Elles se rafraîchissent d'elles-mêmes, ou à la prochaine ouverture de session.

**Autre chose ne va pas.**
Ouvrez une *issue* sur [GitHub](https://github.com/MsieurPafi/AirBattery-Plus/issues) (en anglais ou en français) avec votre version de macOS, la version de l'app et, si possible, ses journaux (voir [Autorisations et confidentialité](permissions-privacy.md#journaux)).
