# Ligne de commande : `abtp`

[Guide](README.md) · [English](../en/command-line.md)

`abtp` affiche dans un terminal les batteries que connaît AirBattery Plus, pour des scripts ou un outil de barre d'état. L'app doit être ouverte.

## Installation

**Réglages › Général › Outil en ligne de commande › Installer**, puis saisissez votre mot de passe administrateur : cela crée le lien `/usr/local/bin/abtp`. **Désinstaller** le supprime.

Jusqu'à la version 1.7.4, l'outil s'installait sous le nom `airbattery`, le même que celui de l'app officielle. L'installation d'`abtp` supprime cet ancien lien s'il appartient à AirBattery Plus, jamais s'il appartient à l'app officielle.

## Utilisation

```bash
abtp              # tableau des appareils, niveau et état
abtp --json       # JSON, pour les scripts
abtp --csv        # CSV
abtp --nearcast   # inclut les appareils de vos autres Mac (Nearcast)
abtp --help
```

Dans le tableau, la colonne d'état affiche `+` quand un appareil se charge ou est branché, `=` quand la charge est en pause, et `-` sur batterie.
