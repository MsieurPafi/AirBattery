# Nearcast

[Guide](README.md) · [English](../en/nearcast.md)

Nearcast partage les niveaux de batterie entre vos Mac sur un même réseau local. Chaque Mac affiche la batterie des autres, et celle de leurs appareils, dans une section de sa propre liste. Les alertes de batterie sont aussi transmises aux autres Mac.

Chaque Mac du groupe doit avoir AirBattery Plus avec Nearcast v2 (version 1.14 ou plus récente). Nearcast ne communique ni avec l'AirBattery d'origine, ni avec l'app iOS AirBattery Mobile.

## Mise en place

1. Sur le premier Mac, ouvrez **Réglages › Nearcast** et cliquez sur **Créer un groupe**. Nearcast s'active et le code du groupe s'affiche (il commence par `nc2-`).
2. Envoyez ce code à vos autres Mac avec le bouton de partage (AirDrop, Messages…) ou le bouton de copie.
3. Sur chaque autre Mac, ouvrez **Réglages › Nearcast**, cliquez sur **Rejoindre un groupe**, puis sur **Coller** (un code copié est rempli automatiquement), et sur **Rejoindre**.

Une fois dans un groupe, **Réglages › Nearcast** affiche le code (cliquez sur l'œil pour le voir en entier), les **Mac connectés** et un interrupteur pour mettre Nearcast en pause. **Quitter le groupe** désactive Nearcast sur ce Mac et oublie le code.

## Depuis une version précédente

Nearcast passe à un nouveau protocole, plus sûr. Les identifiants de groupe d'avant (`nc-` suivi de 20 caractères) ne fonctionnent plus : après la mise à jour, Nearcast est désactivé et une notification le signale. Créez un nouveau groupe sur un Mac, puis rejoignez-le depuis les autres.

## Bon à savoir

- Tout ce qui passe par Nearcast est chiffré et authentifié avec des clés tirées du code du groupe, et seuls les Mac qui le connaissent sont admis. Ne le communiquez à personne en dehors de vos propres Mac.
- Nearcast ne fonctionne qu'entre Mac d'un même réseau.
- Chaque Mac a besoin de l'accès au réseau local (voir [Autorisations et confidentialité](permissions-privacy.md)).
- Ne mettez pas trop de Mac dans un même groupe : chacun échange avec tous les autres.
