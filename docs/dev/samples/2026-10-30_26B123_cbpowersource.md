# CBPowerSource — première mesure (2026-10-30, macOS 27.2 26B123)

Commande : `scripts/measure-cbpowersource.sh` (noms remplacés par la catégorie). Appareils connectés au Mac de Côme ce jour-là : AirPods Pro 3 (`AirPods3,4`), souris Logitech MX Anywhere 3 (BLE). Pas de clavier ni de casque tiers.

```
macOS 27.2 (26B123), 2026-10-30 18:36, window 7d
2923 lines, 2026-10-30 01:12 → 2026-10-30 18:35
2-minute query: 1.15 s, CPU 0.32 s
- Headset 1 | Headset | Bluetooth LE | VID 0x004C (Apple) PID 0x2027 (AirPods3,4) | 1761 lines over 17 h | levels 6…79% (55 distinct), last 37% | components: Left 80%, Right 79%
- Mouse 1 | Mouse | Bluetooth LE | VID 0x046D (?) PID 0xB025 (?) | 956 lines over 11 h | levels -65…-65% (1 distinct), last -65%
- Headset 1 | Headset | Bluetooth | VID 0x004C (Apple) PID 0x2027 (AirPods3,4) | 150 lines over 5 h | levels 47…74% (6 distinct), last 47% | components: Left 51%, Right 51%, Case -47%
- Headset 1 | Headphone | Bluetooth | VID 0x004C (Apple) PID 0x2027 (AirPods3,4) | 56 lines over 4 h | levels 43…74% (9 distinct), last 43% | components: Left 70%
```

Répartition par heure (AirPods, ligne « Headset » en BLE) : 28, 213, 167, 167, 85, 150, 215, 106, 118, 171, 177, 122, 2, –, 40, 14, 30, 106, 94 (00 h → 18 h). Souris : 11 à 372 lignes par heure de 00 h à 11 h, puis plus rien.

Exemple de ligne (identifiants remplacés) :

```
Power source updated CBPowerSource Nm 'MX Anywhere 3', SID …, AcCa Mouse, AcID <UUID>, PID 0xB025 (?), VID 0x046D (?), VIDSrc USB, Type 'Accessory Source', TPT Bluetooth LE, CF 0x1 < Attributes >, IF 0x2 < IOKit >, Present yes, MaxC 100%, Battery -65%
```

**Constats :**
- **Conservation courte :** `--last 7d` ne renvoie que ~17 h (premières lignes vers 01 h). Une mesure sur plusieurs jours demande de relancer le script chaque jour (ou un collecteur, non mis en place : configuration persistante, à demander).
- **Coût :** une requête sur 2 min prend ~1 s et ~0,3 s de CPU, du même ordre que la lecture actuelle des appareils tiers (0,23 s de CPU sur 10 min).
- **Volume élevé et répétitif :** jusqu'à ~370 lignes par heure pour un appareil, la plupart avec le même niveau (la souris : 956 lignes, toujours -65 %).
- **Un même appareil apparaît sous plusieurs entrées :** les AirPods en « Headset » sur Bluetooth LE, en « Headset » et en « Headphone » sur Bluetooth classique. Il faudrait les regrouper par `AcID` ou par nom.
- **Signe des niveaux :** `Battery -65%` (souris, sur batterie), `Case -47%` ; la nuit, les AirPods remontent de 6 à 79 % sans signe (dans le boîtier, en charge). Hypothèse : `-` = en décharge. **Non vérifié.**
- Les noms sont en clair dans ces lignes (alors que `Device found` affiche `Nm <private>`).
- Rien de neuf pour l'instant par rapport aux sources actuelles : les deux appareils sont déjà lus par l'app. L'intérêt serait pour des appareils que l'app rate (casques et enceintes tiers, manettes) : à mesurer avec ces appareils.
