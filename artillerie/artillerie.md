# 🎯 JEU D'ARTILLERIE 6502 POUR APPLE II

Ce document décrit en détail le fonctionnement du jeu **Artillerie**, ses règles, sa physique balistique, son architecture technique en assembleur 6502, ainsi que l'historique complet de ses versions.

---

## 📖 1. Présentation du Jeu

Le jeu d'artillerie est l'un des grands classiques de l'histoire du jeu vidéo sur micro-ordinateurs (*Artillery* sur Apple II dès 1980, *Smithereens!* sur Philips G7000, *Scorched Earth* sur PC, puis plus tard *Gorillas* et *Worms*).

Dans cette adaptation écrite en pur assembleur 6502 pour **Apple II / Apple II+ / Apple IIe / Apple IIgs** :
- Deux chars de combat blindés se font face sur un relief montagneux accidenté généré de façon procédurale.
- Le joueur ajuste son **angle de tir** (en degrés) et sa **puissance de propulsion** (vitesse initiale).
- Le projectile suit une parabole balistique réaliste sous l'influence de la **gravité terrestre** et de la **force dynamique du vent**.
- Chaque obus percutant le sol pulvérise la roche et creuse un **cratère dynamique**.
- Le premier joueur qui détruit le char adverse marque la manche. Une partie se dispute en **5 manches gagnantes**.

---

## 🎮 2. Modes de Jeu & Options

Au lancement, le jeu propose deux écrans de configuration :

### 1. Mode de Combat :
- **1 - CONTRE L'ORDINATEUR (PVE)** : Vous affrontez l'ordinateur. Celui-ci est doté d'une intelligence artificielle balistique qui ajuste son angle et sa force après chaque tir manqué en observant si l'obus est tombé trop court ou trop long.
- **2 - DEUX JOUEURS (PVP)** : Deux joueurs humains s'affrontent au tour par tour sur le même clavier.

### 2. Choix du Relief :
- **1 - PLAINE** : Dénivelé faible avec collines douces, idéal pour les tirs tendus.
- **2 - COLLINE** : Relief vallonné classique avec dénivelé moyen.
- **3 - MONTAGNE** : Crêtes escarpées et vallées profondes imposant des tirs en cloche à angle élevé.

---

## 🕹️ 3. Commandes du Jeu

Le jeu prend en charge les claviers complets (avec flèches) ainsi que les claviers historiques sans touches fléchées de l'**Apple II et Apple II+** :

| Action | Clavier Standard | Clavier Apple II+ |
| :--- | :--- | :--- |
| **Augmenter l'angle** | `Flèche Droite` | `K` |
| **Diminuer l'angle** | `Flèche Gauche` | `J` |
| **Augmenter la puissance** | `Flèche Haut` | `A` |
| **Diminuer la puissance** | `Flèche Bas` | `Z` |
| **Faire Feu** | `Barre d'Espace` ou `Entrée` | `Barre d'Espace` ou `Entrée` |

---

## 📐 4. Moteur Balistique & Graphique

### Calculs Balistiques en 24-bits
Pour garantir une précision sub-pixélique sans saccade :
- Les coordonnées ($X, Y$) et les vecteurs vitesse ($V_x, V_y$) sont calculés en **virgule fixe 24-bits** (1 octet entier, 2 octets fractionnaires).
- La trajectoire est découpée en 4 sous-pas temporels par trame pour éviter que le projectile ne saute à travers une crête montagneuse étroite.
- Le vent applique une accélération latérale continue sur le projectile tout au long de sa course.

### Double Buffering des Trajectoires
Chaque joueur possède son propre tampon mémoire de trajectoire (`P1_BUF1` et `P2_BUF1`). Lors du nouveau tour du joueur 1, sa trajectoire précédente est effacée en noir sans toucher à la trajectoire tracée par le joueur 2, permettant de conserver les repères visuels de tir.

### Cratères Géologiques Réalistes
Lorsqu'un obus heurte la montagne, la routine `DigCrater` lit une table de demi-profil parabolique (`CRATER_TAB`) et applique une déformation verticale sur les colonnes rocheuses du tableau `TERRAIN_Y[280]`. Le terrain est définitivement entaillé pour les tirs suivants.

---

## 📜 5. Historique des Versions (Changelog)

### Version 1.0 (Version Initiale)
- Première version en assembleur 6502 pur.
- Affichage HGR 280x160 en mode mixte (graphisme haut + 4 lignes de texte au bas).
- Génération d'un relief à harmoniques de Fourier.
- Tirs balistiques basiques.
- Explosion rudimentaire en croix de 4 lignes filaires.
- Bips sonores élémentaires sur le haut-parleur `$C030`.

### Version 2.0 (Double Buffering & Balistique 24-bits)
- Refonte de la physique en virgule fixe 24-bits avec vent dynamique continu.
- Tampons d'effacement de trajectoire séparés (`P1_BUF1` et `P2_BUF1`).
- Ajout du ciel étoilé décoratif (`DrawStars`).
- Gestion de deux modes de jeu : Solo contre Ordinateur (IA balistique adaptative) et Duel 2 joueurs.
- Sélection du type de relief au démarrage (Plaine, Colline, Montagne).
- Support des touches alternatives pour claviers Apple II+ (`A`/`Z` et `J`/`K`).

### Version 2.1 (Corrections Critiques & Robustesse)
- **Correction du blocage infini (`OutOfBounds`)** : lorsqu'un obus sortait de l'écran, le CPU entrait dans une boucle infinie sans pouvoir ajuster son tir. Corrigé avec sortie propre et ajustement des bornes de puissance.
- **Séparation des scores** : scission du compteur commun `SHOT_COUNT` en deux variables indépendantes (`P1_SHOT_COUNT` et `P2_SHOT_COUNT`) pour un calcul de score équitable.
- **Fiabilisation du générateur aléatoire LFSR** : ajout d'une graine de secours si `RANDOM_SEED` tombait à zéro (évitant le gel des calculs trigonométriques).
- **Conservation du ciel étoilé** : sauvegarde de la graine `STAR_SEED` pour redessiner fidèlement les étoiles après l'effacement de la trajectoire.
- **Détection de l'auto-destruction** : gestion des tirs verticaux retombant sur le tireur avec message `AUTO-DESTRUCTION !`.

### Version 2.2 (Révolution Graphique & Acoustique Haute Fidélité)
- **Explosion Propre & Sans Artefact** :
  - Élimination intégrale des pixels orphelins, des fragments parasites et des traits filaires sujets aux artefacts de couleur NTSC.
  - Séquence cinématique en 6 étapes à base de disques pleins géométriques parfaits (`DrawFilledFireball`) :
    1. **Flash d'allumage blanc pur** ($R=6$).
    2. **Expansion thermique géante** : sphère orange ($R=12$) avec cœur incandescent blanc ($R=6$).
    3. **Méga déflagration plasma** : sphère maximale ($R=18$) à stries alternées bicolores blanc/orange créant une vibration optique éclatante.
    4. **Onde de choc en anneau** : effacement du cœur en noir ($R=8$) au milieu de la boule orange ($R=18$), créant un anneau de feu parfait.
    5. **Oblitération & Creusement** : effacement complet de la boule de feu en noir (zéro pixel résiduel) et creusement du cratère sombre dans la roche.
    6. **Volute de fumée** : bouffée de fumée violette pleine s'élevant au-dessus du cratère puis s'effaçant proprement pour laisser un champ de bataille immaculé.
- **Synthèse Acoustique à Balayage Fréquentiel Descendant (Pitch Sweep)** :
  - Remplacement du bruit blanc statique (qui produisait un simple sifflement) par un **balayage de fréquence descendant couplé à une modulation chaotique Galois LFSR**.
  - Son d'explosion lourd, physique et résonant qui balaye du haut vers les infrabasses (durée totale continue > 2 secondes), faisant vibrer le haut-parleur physique `$C030`.
  - Nouveau son de canon au départ (`PlayFireSound`) : claquement sec de culasse suivi du grondement lourd de la chambre de tir (~280 ms).
  - Nouveau son d'impact de terre pour les tirs manqués (`PlayExplosionSound`) à pitch descendant.
- **Affichage de Version** :
  - Ajout du label `VERSION 2.2` en bas à gauche de l'écran titre et de l'écran de choix du relief, en regard du copyright `(C) BACO 2026`.

### Version 2.3 (Équilibrage Compétitif & Physique du Vent Dynamique)
- **Alternance de l'Initiative par Manche** :
  - Fin du monopole du tir d'ouverture par J1 : le premier tireur alterne désormais à chaque manche (Manches 1, 3, 5 = J1 commence ; Manches 2, 4 = J2 / CPU commence).
- **Équité des Réglages en Duel (PvP)** :
  - En mode 2 Joueurs, les réglages d'angle et de force de J2 ne sont plus réinitialisés aléatoirement par le RNG au début de chaque manche. J2 conserve désormais ses réglages mémorisés de façon symétrique à J1.
- **Vent Dynamique au Tour par Tour (Rafales Réalistes)** :
  - La routine `UpdateWindTurn` applique une fluctuation continue du vent ($\pm 2$) après chaque tir. Les joueurs doivent réadapter leur tir en temps réel en observant l'indicateur de vent mis à jour sur le HUD.
- **Rehaussement Tactique du Relief "Plaine"** :
  - Amplitudes sinusoïdales augmentées (`AMP1=12`, `AMP2=9`, `AMP3=7`, `AMP4=5`).
  - Ajout de la routine `AddCentralMound` créant une butte centrale fluide ($X \in [105, 161]$) entre les deux belligérants pour bannir les tirs directs horizontaux et forcer des tirs en cloche.
- **Dispersion Accrue des Chars** :
  - Élargissement des plages de spawn : J1 dans $[20, 79]$ et J2 dans $[185, 259]$, offrant une variation de distance de 106 à 239 pixels.

