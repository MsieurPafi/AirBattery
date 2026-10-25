# Autorisations et confidentialité

[Guide](README.md) · [English](../en/permissions-privacy.md)

## Ce que l'app demande

| Autorisation | Pourquoi | Sans elle |
| --- | --- | --- |
| Bluetooth | Lire les AirPods, les Beats et les accessoires Bluetooth, et les iPhone autorisés en Bluetooth | Seulement ce Mac, l'iPhone, l'iPad et l'Apple Watch en USB ou en Wi-Fi, et Nearcast |
| Réseau local | iPhone, iPad et Apple Watch en Wi-Fi ; Nearcast | Pas d'appareils en Wi-Fi, pas de Nearcast. macOS redemande après chaque mise à jour |
| Notifications | Alertes de batterie | Pas d'alertes |
| Mot de passe administrateur | Seulement pour installer ou supprimer la commande `abtp`, qui écrit dans `/usr/local/bin` | Pas d'`abtp` |

Comme l'AirBattery d'origine, l'app n'est pas en bac à sable (*sandbox*) : elle lance les outils qui lisent les iPhone, iPad et Apple Watch, et lit les informations Bluetooth de macOS.

## Ce qui reste sur votre Mac

- Les niveaux de batterie et les noms des appareils sont enregistrés uniquement sur votre Mac, pour les widgets et `abtp`.
- AirBattery Plus n'envoie rien sur internet : ni statistiques d'usage, ni mise à jour automatique.
- Avec Nearcast, les niveaux sont partagés avec vos autres Mac sur le réseau local, chiffrés avec votre Group ID.

## Journaux

L'app écrit ses messages de diagnostic dans le journal unifié de macOS, en gardant privés les noms et adresses des appareils. Pour les lire, par exemple pour signaler un bogue :

```bash
/usr/bin/log show --last 1h --predicate 'subsystem == "io.github.msieurpafi.AirBattery"'
```
