# 🐍 Anthologie Snake pour Apple II (4 Déclinaisons 6502)

Collection complète des 4 déclinaisons du jeu **Snake** développées en **Assembleur 6502 pur** pour les micro-ordinateurs **Apple II, Apple II+ et Apple IIe**, accompagnées d'une version de prouesse en 2 lignes d'Applesoft BASIC.

---

## 📁 Contenu du dossier

| Fichier | Type | Adresse | Description |
| :--- | :--- | :--- | :--- |
| [`snake-hgr.asm`](file:///snake-hgr.asm) | ASM 6502 | `$4000` | **Snake HGR** : Version Haute Résolution (280×192, grille 40×20), formes personnalisées et vitesse adaptative. |
| [`snake-gr.asm`](file:///snake-gr.asm) | ASM 6502 | `$4000` | **Snake GR** : Version Basse Résolution couleur (40×40 blocs), mode mixte graphique + texte. |
| [`snake-txt.asm`](file:///snake-txt.asm) | ASM 6502 | `$4000` | **Snake Texte** : Version optimisée 40×24, compatible 100% avec l'Apple II original de 1977. |
| [`snake_kimi.asm`](file:///snake_kimi.asm) | ASM 6502 | `$6000` | **Snake Accélération (KIMI)** : Moteur avec accélération progressive et score BCD en temps réel. |
| [`snake_2l.bas`](file:///snake_2l.bas) | BASIC | — | **Snake 2-Lignes** : Démonstration de compacité extrême en seulement deux lignes d'Applesoft BASIC. |
| [`snake_loader.bas`](file:///snake_loader.bas) | BASIC | — | Chargeur BASIC autonome avec données DATA pour injection mémoire. |
| [`build_disk.py`](file:///build_disk.py) | Python | — | Script de compilation 64tass, formatage et génération de la disquette autonome `SNAKE.dsk`. |
| [`build.bat`](file:///build.bat) | Batch | — | Lanceur automatisé de compilation et d'injection en un clic. |

---

## 🕹️ Les 4 Versions en Détail

### 1. 🟢 Snake HGR (*High Resolution Graphics*)
* **Fichier source** : [`snake-hgr.asm`](file:///snake-hgr.asm)
* **Mode vidéo** : HGR 280×192 (mode mixte avec 4 lignes de texte d'information).
* **Implantation mémoire** : `$4000` (au-dessus de la page HGR1 `$2000-$3FFF`).
* **Points forts** :
  - Grille logique 40×20 avec tracé de formes graphiques dédiées pour la tête, le corps et les différents fruits.
  - Vitesse progressive calculée dynamiquement au fur et à mesure que le serpent grandit.
  - Animation de fin théâtrale et sortie propre vers Applesoft BASIC (`JMP $E003`).

### 2. 🌈 Snake GR (*Low Resolution Graphics*)
* **Fichier source** : [`snake-gr.asm`](file:///snake-gr.asm)
* **Mode vidéo** : GR Basse Résolution 40×40 blocs de couleur avec 4 lignes de texte au bas de l'écran.
* **Implantation mémoire** : `$4000`.
* **Points forts** :
  - Utilise l'entrelacement mémoire du mode Lores Apple II `$0400-$07FF`.
  - Palette rétro 16 couleurs, bruitages sur le haut-parleur `$C030` lors de la prise de fruits.
  - Animation de transition à la sortie.

### 3. 📄 Snake Texte (*40×24 Text Mode*)
* **Fichier source** : [`snake-txt.asm`](file:///snake-txt.asm)
* **Mode vidéo** : Texte pur 40 colonnes × 24 lignes (aucun circuit graphique requis).
* **Implantation mémoire** : `$4000`.
* **Points forts** :
  - Compatible avec n'importe quelle configuration Apple II, dès la carte-mère non-Plus de 1977.
  - Calcul direct des adresses de ligne vidéo par tables entrelacées en page zéro.
  - Animation d'adieu *"SALUT L'ARTISTE!"* avec lettres tombant en cascade du haut de l'écran.

### 4. ⚡ Snake Accélération KIMI
* **Fichier source** : [`snake_kimi.asm`](file:///snake_kimi.asm)
* **Mode vidéo** : Texte 40×24 avec affichage HUD BCD.
* **Implantation mémoire** : `$6000`.
* **Points forts** :
  - Gestion inertielle et accélération par paliers à chaque pomme consommée.
  - Tampon circulaire de corps de serpent avec pointeurs `HEAD_PTR` et `TAIL_PTR`.
  - Touche `ESC` intégrée pour quitter instantanément vers le prompt BASIC.

---

## ⌨️ Commandes de Jeu

| Touche | Action |
| :--- | :--- |
| **Flèches directionnelles** | Diriger le serpent (Apple IIe / IIc / AppleWin) |
| **I, J, K, M** | Haut, Gauche, Bas, Droite (Apple II / II+ historique) |
| **Z, Q, S, D / W, A, S, D** | Commandes alternatives |
| **ESC** | Quitter la partie et retourner au menu Applesoft BASIC |
| **Y / N** | Rejouer ou quitter après un Game Over |

---

## 🔨 Compilation & Lancement

### Compilation automatique (recommandée)
Exécutez simplement depuis ce dossier :
```cmd
build.bat
```
ou via Python :
```cmd
python build_disk.py
```
Le script va :
1. Compiler les 4 fichiers sources avec `64tass` en binaires (`.bin`).
2. Formater et générer la disquette amorçable [`SNAKE.dsk`](file:///../SNAKE.dsk) avec un menu interactif de sélection.
3. Synchroniser automatiquement les binaires dans la disquette d'anthologie [`AI-ASM.DSK`](file:///../AI-ASM.DSK).

### Lancement dans l'émulateur
Insérez [`SNAKE.dsk`](file:///../SNAKE.dsk) dans le lecteur de votre émulateur Apple II :
- Au démarrage, le menu interactif vous propose de choisir parmi les 4 versions (touches `1` à `4`) ou la version 2-lignes (`5`).
- Depuis le prompt Applesoft BASIC `]`, vous pouvez lancer directement :
```basic
BRUN SNAKE-HGR
BRUN SNAKE-GR
BRUN SNAKE-TXT
BRUN SNAKE-KIMI
```
