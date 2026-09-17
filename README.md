# 🍎 Rétro-Engineering & Jeux 6502 pour Apple II+ / Apple IIe

Bienvenue dans ce dépôt dédié au développement de jeux vidéo et d'expérimentations en **Assembleur 6502 pur** et **Applesoft BASIC** pour les micro-ordinateurs légendaires **Apple II, Apple II+ et Apple IIe**.

Ces créations combinent les contraintes matérielles d'époque (1 MHz, 48 Ko / 64 Ko de RAM, mémoire vidéo HGR entrelacée) avec des algorithmes modernes (physique balistique 24-bits, intelligence artificielle Monte Carlo Tree Search, page-flipping graphique et synthèse sonore).

---

## 🎮 Les Jeux Développés

### 1. 👾 Space Invaders 6502 (1978 Arcade Replica)
* **Dossier du projet** : [`invaders/`](file:///invaders/) (Documentation détaillée : [`invaders/README.md`](file:///invaders/README.md))
* **Fichiers sources** : [`invaders.asm`](file:///invaders/invaders.asm), [`invaders_data.asm`](file:///invaders/invaders_data.asm)
* **Mode graphique** : Haute Résolution (HGR 280×192) avec double page et page-flipping.
* **Moteur & Caractéristiques** :
  - 5 rangées d'aliens animés avec accélération progressive des pas de marche.
  - 4 bunkers destructibles avec dégradation réaliste des impacts de tirs.
  - Soucoupe volante mystère (*Mystery Saucer*) rapportant 50 à 300 points bonus.
  - Mode cinématique d'attraction (*Attract Mode*) et table des scores.

---

### 2. 🟩 Pipopipette (*Dots and Boxes*) — Le Fleuron
* **Dossier du projet** : [`pipopipette/`](file:///pipopipette/) (Documentation détaillée : [`pipopipette/README.md`](file:///pipopipette/README.md))
* **Fichiers sources** : [`pipopipette.asm`](file:///pipopipette/pipopipette.asm), [`fonttable.asm`](file:///pipopipette/fonttable.asm)
* **Mode graphique** : Haute Résolution (HGR 280×192) avec double tampon et page-flipping.
* **Moteur & Caractéristiques** :
  - Sélection de grille au lancement : **5×5**, **6×6** ou **7×7**.
  - Tracé de segments horizontaux et verticaux avec gestion des artefacts couleur NTSC.
  - Affichage HUD complet avec score en direct et police de caractères 8×8 personnalisée.
  - **IA Monaco Ver. 2** basée sur un algorithme Monte Carlo Tree Search (MCTS) avec barre de progression.
  - Cinématique d'adieu avec volet théâtral, iris zoom, fanfare Sol Majeur et retour propre au prompt `]` (`JMP $E003`).

---

### 3. 🎯 Duel d'Artillerie 6502 (*Artillery*)
* **Dossier du projet** : [`artillerie/`](file:///artillerie/) (Documentation complète : [`artillerie/artillerie.md`](file:///artillerie/artillerie.md))
* **Fichier source** : [`artillerie.asm`](file:///artillerie/artillerie.asm)
* **Mode graphique** : HGR 280×160 mixte (4 lignes de texte au bas de l'écran).
* **Moteur & Caractéristiques** :
  - **Physique balistique 24-bits** : Calcul sub-pixélique des coordonnées et vitesses avec gravité et vent dynamique.
  - **Relief procédural** généré par harmoniques de Fourier (Plaine, Colline, Montagne).
  - **Cratères géologiques dynamiques** déformant le relief en temps réel.
  - **Explosion cinématique en 6 étapes** et synthèse acoustique sur `$C030`.
* **Modes** : 1 Joueur contre Ordinateur (IA adaptative) ou Duel 2 Joueurs.

---

### 4. 🐦 Flappy Bird & Happy Bird 6502
* **Dossier du projet** : [`flappy/`](file:///flappy/) (Documentation détaillée : [`flappy/README.md`](file:///flappy/README.md))
* **Fichiers sources** : [`flappy.asm`](file:///flappy/flappy.asm), [`happybird.asm`](file:///flappy/happybird.asm)
* **Mode graphique** : HGR 280×192 avec Double Buffering (Pages 1 & 2).
* **Moteur & Caractéristiques** :
  - **Flappy Bird** : Défilement parallaxe complet, skyline urbain, collines et physique inertielle.
  - **Happy Bird** : Rendu bicolore avec rebords de tuyaux (*rims*) et calcul dynamique des scores.

---

### 5. 🐍 Anthologie Snake (4 Déclinaisons Assembleur 6502)
* **Dossier du projet** : [`snake/`](file:///snake/) (Documentation détaillée : [`snake/README.md`](file:///snake/README.md))
* **Fichiers sources** : [`snake-hgr.asm`](file:///snake/snake-hgr.asm), [`snake-gr.asm`](file:///snake/snake-gr.asm), [`snake-txt.asm`](file:///snake/snake-txt.asm), [`snake_kimi.asm`](file:///snake/snake_kimi.asm)
* **Script de compilation** : [`build.bat`](file:///snake/build.bat) & [`build_disk.py`](file:///snake/build_disk.py)
* **Déclinaisons complètes** :
  - **Snake HGR** : Haute Résolution 280×192, vitesse adaptative et formes personnalisées.
  - **Snake GR** : Basse Résolution (40×40 blocs) couleur avec bruitages dynamiques.
  - **Snake Texte** : Mode texte 40×24 avec adieu "SALUT L'ARTISTE!", compatible 100% avec l'Apple II de 1977.
  - **Snake Accélération (KIMI)** : Moteur nerveux avec accélération progressive et score BCD.
  - **Snake 2-Lignes** : Démonstration de compacité extrême en Applesoft BASIC ([`snake_2l.bas`](file:///snake/snake_2l.bas)).

---

### 6. 🏓 Apple Pong
* **Dossier du projet** : [`pong/`](file:///pong/) (Documentation détaillée : [`pong/README.md`](file:///pong/README.md))
* **Fichier source** : [`pong.asm`](file:///pong/pong.asm)
* **Mode graphique** : HGR 280×192 à 60 FPS sans bug ROM.
* **Caractéristiques** : Duel 1 Joueur vs Ordinateur ou 2 Joueurs. Support des paddles analogiques `$C064`/`$C065` et clavier.

---

### 7. 🚗 1000 Bornes 6502 (Adaptation Thomson MO5 1985)
* **Dossier du projet** : [`1000bornes/`](file:///1000bornes/) (Documentation détaillée : [`1000bornes/README.md`](file:///1000bornes/README.md))
* **Fichiers sources** : [`1000bornes.asm`](file:///1000bornes/1000bornes.asm), [`cards_gfx.asm`](file:///1000bornes/cards_gfx.asm)
* **Script de compilation** : [`build.bat`](file:///1000bornes/build.bat)
* **Mode graphique** : HGR 280×192 couleur (reproduction fidèle du tapis vert feutre, volets magenta et orange).
* **Moteur & Caractéristiques** :
  - **Fidélité historique intégrale** au jeu original MO5 de 1985 conçu par J.Y. Boucrot (Free Game Blot / Dujardin).
  - **Moteur de règles complet** : Les 110 cartes du jeu (Bornes 25 à 200, Attaques, Parades, Bottes, Coup-Fourré avec effet sonore et tour supplémentaire).
  - **Graphismes HGR soignés** : Dômes rouges sur toutes les bornes, feux tricolores avec voyants colorés, centrage parfait et lettres de repère.
  - **IA "Thomson" stratégique** : Gestion des priorités de pose de bottes, attaques directes, limitation 50 km/h et défausse intelligente.
  - **Affichage moderne des scores** : Chiffres haute lisibilité 14 scanlines et mention dynamique centrée `[Score] KMS`.

---

### 8. 🔬 Expérimentations & Démonstrateurs
* [`pi.asm`](file:///pi.asm) : Moteur de calcul haute précision des décimales du nombre $\pi$ en 6502 (jusqu'à 4000 décimales).
* [`digits.asm`](file:///digits.asm) : Polices et affichage numérique vectoriel/bitmap HGR.

---

## 🛠️ Boîte à Outils & Workflow Python

Le projet inclut une suite d'utilitaires Python pour faciliter le cycle de développement :

| Script | Rôle & Description |
| :--- | :--- |
| **`make_ai_asm.py`** | Recompile tous les jeux et génère l'image disquette unifiée amorçable [`AI-ASM.DSK`](file:///AI-ASM.DSK). |
| **`bas2dsk.py`** | Injecte des exécutables binaires (`.bin`) ou tokenise des scripts (`.bas`) dans une image DOS 3.3. |
| **`dsk2bas.py`** | Extrait et désassemble les programmes BASIC Applesoft d'une image disque. |
| **`list_cat.py`** | Analyse et affiche instantanément le catalogue DOS 3.3 d'une image disque. |

---

## 🚀 Compilation & Lancement

### 1. Prérequis
* Un assembleur 6502 moderne : **[64tass](https://tass64.sourceforge.net/)** (installé et accessible dans le PATH).
* **Python 3** pour l'injection disquette.
* Un émulateur Apple II : **AppleWin** (Windows), **LinApple** (Linux) ou **Virtual ][** (macOS).

### 2. Compiler un jeu en binaire
```bash
# Exemple avec Pipopipette (implanté en $6000) :
64tass -b pipopipette.asm -o pipopipette.bin

# Exemple avec Artillerie (implanté en $4000) :
64tass -b artillerie.asm -o artillerie.bin

# Exemple avec Flappy Bird (implanté en $0803) :
64tass -b flappy.asm -o flappy.bin
```

### 3. La Disquette Maître Unifiée : `AI-ASM.DSK`
Pour recompiler instantanément l'intégralité des jeux du projet et générer la disquette amorçable :
```bash
python make_ai_asm.py
```
Vérification du catalogue :
```bash
python list_cat.py AI-ASM.DSK
```

### 4. Jouer dans l'émulateur
Insérez l'image [`AI-ASM.DSK`](file:///AI-ASM.DSK) dans le lecteur 1 de votre émulateur :
- Un menu interactif démarre automatiquement au boot (`HELLO`) et vous permet de sélectionner n'importe quel jeu (`1` à `9`, `A`, `S`, `P`).
- Vous pouvez également lancer directement un jeu depuis le prompt Applesoft `]` :
```basic
BRUN INVADERS
BRUN FLAPPY
BRUN HAPPYBIRD
BRUN PONG
BRUN ARTILLERIE
BRUN PIPOPIPETTE
BRUN BORNES
BRUN SNAKE-HGR
BRUN SNAKE-GR
BRUN SNAKE-TXT
BRUN SNAKE-KIMI
BRUN SNAKE
RUN SNAKE_2L
BRUN PI
```

---

*Fait avec passion pour l'architecture 6502 et la formidable machine créée par Steve Wozniak !* 🍏✨