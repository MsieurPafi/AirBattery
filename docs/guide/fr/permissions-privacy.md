# Autorisations et confidentialité

[Guide](README.md) · [English](../en/permissions-privacy.md)

## Ce que l'app demande

| Autorisation | Pourquoi | Sans elle |
| --- | --- | --- |
| Bluetooth | Lire les AirPods, les Beats et les accessoires Bluetooth, et les iPhone autorisés en Bluetooth | Seulement ce Mac, l'iPhone, l'iPad et l'Apple Watch en USB ou en Wi-Fi, et Nearcast |
| Réseau local | iPhone, iPad et Apple Watch en Wi-Fi ; Nearcast | Pas d'appareils en Wi-Fi, pas de Nearcast. macOS redemande après la plupart des mises à jour |
| Connexions entrantes (coupe-feu) | Seulement si le coupe-feu de macOS est activé et que Nearcast sert : permet à vos autres Mac de se connecter à celui-ci. Demandé la première fois qu'un autre Mac se connecte | Nearcast ne fonctionne que lorsque ce Mac est celui qui se connecte |
| Notifications | Alertes de batterie | Pas d'alertes |
| Mot de passe administrateur | Seulement pour installer ou supprimer la commande `abtp`, qui écrit dans `/usr/local/bin` | Pas d'`abtp` |

Comme l'AirBattery d'origine, l'app n'est pas en bac à sable (*sandbox*) : elle lance les outils qui lisent les iPhone, iPad et Apple Watch, et lit les informations Bluetooth de macOS.

## Ce qui reste sur votre Mac

- Les niveaux de batterie et les noms des appareils sont enregistrés uniquement sur votre Mac, pour les widgets et `abtp`.
- AirBattery Plus n'envoie aucune statistique d'usage. Son seul accès à internet est la recherche de mises à jour : elle télécharge la liste des versions depuis GitHub (`appcast.xml` dans ce dépôt), automatiquement si vous l'avez accepté, ou quand vous cliquez sur **Rechercher des mises à jour…**, puis la nouvelle version si vous l'installez. GitHub voit ces requêtes comme n'importe quel téléchargement (votre adresse IP, et la version de l'app dans l'en-tête User-Agent ; aucune information sur le système n'est envoyée). Désactivez **Réglages › Général › Mise à jour › Rechercher automatiquement les mises à jour** pour ne jamais vérifier de vous-même.
- Avec Nearcast, les niveaux sont partagés avec vos autres Mac sur le réseau local, chiffrés avec votre identifiant de groupe.

## Journaux

L'app écrit ses messages de diagnostic dans le journal unifié de macOS, en gardant privés les noms et adresses des appareils. Pour les lire, par exemple pour signaler un bogue :

```bash
/usr/bin/log show --last 1h --predicate 'subsystem == "io.github.msieurpafi.AirBattery"'
```
