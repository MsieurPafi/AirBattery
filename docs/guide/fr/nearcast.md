# Nearcast

[Guide](README.md) · [English](../en/nearcast.md)

Nearcast partage les niveaux de batterie entre vos Mac sur un même réseau local. Chaque Mac affiche la batterie des autres, et celle de leurs appareils, dans une section de sa propre liste. Les alertes de batterie sont aussi transmises aux autres Mac.

Chaque Mac du groupe doit avoir AirBattery Plus avec Nearcast v2 (version 1.14 ou plus récente). Nearcast ne communique ni avec l'AirBattery d'origine, ni avec l'app iOS AirBattery Mobile.

## Mise en place

1. Sur le premier Mac, ouvrez **Réglages › Nearcast** et cliquez sur **+** à côté du champ **Identifiant de groupe** pour créer un identifiant.
2. Copiez-le avec le bouton de copie, puis saisissez-le ou collez-le dans le champ **Identifiant de groupe** sur chacun de vos autres Mac.
3. Activez **Activer Nearcast** sur chaque Mac.

Un identifiant de groupe ressemble à `nc2-` suivi de 26 lettres et chiffres. Majuscules, espaces et tirets n'ont pas d'importance à la saisie. L'identifiant de groupe ne peut être modifié que lorsque Nearcast est désactivé. ↻ en crée un nouveau : il faut alors le saisir de nouveau sur vos autres Mac.

## Depuis une version précédente

Nearcast passe à un nouveau protocole, plus sûr. Les identifiants de groupe d'avant (`nc-` suivi de 20 caractères) ne fonctionnent plus : après la mise à jour, Nearcast est désactivé et une notification le signale. Créez un nouvel identifiant et saisissez-le sur tous vos Mac.

## Bon à savoir

- Tout ce qui passe par Nearcast est chiffré et authentifié avec des clés tirées de l'identifiant de groupe, et seuls les Mac qui le connaissent sont admis. Ne le communiquez à personne en dehors de vos propres Mac.
- Nearcast ne fonctionne qu'entre Mac d'un même réseau.
- Chaque Mac a besoin de l'accès au réseau local (voir [Autorisations et confidentialité](permissions-privacy.md)).
- Ne mettez pas trop de Mac dans un même groupe : chacun échange avec tous les autres.
