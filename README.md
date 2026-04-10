# Expérimentations Rétro : Apple II+ et Apple IIe

Bienvenue dans ce dépôt consacré à la création de jeux et d'expérimentations en **Assembleur 6502** et **Applesoft BASIC** pour les ordinateurs mythiques **Apple II+ et Apple IIe**.

Ces projets ont été développés avec une approche moderne, combinant des outils actuels et l'intelligence artificielle pour redonner vie à ces machines d'époque avec des moteurs de jeu performants et des IA avancées.

---

## 🎮 Les Jeux Développés

### 1. Pipopipette (Dots and Boxes) - *Le Fleuron*
*   **Description** : Le jeu classique des petits carrés, porté intégralement en Haute Résolution (HGR).
*   **Conception** : Développé en pur assembleur 6502. Utilise une gestion dynamique de la grille (5x5 boxes) et un moteur graphique gérant page-flipping et sprites de caractères personnalisés.
*   **Intelligence Artificielle (Monaco Ver. 2)** : Intègre un algorithme de type **Monte Carlo Tree Search (MCTS)** simplifié. L'ordinateur simule des centaines de fins de parties possibles en utilisant des heuristiques humaines pour choisir le coup optimal.
*   **Commandes** : 
    *   **Clavier** : Flèches pour se déplacer, `Espace` pour pivoter le trait, `Entrée` pour poser.
    *   **Joystick** : Support complet des manettes analogiques Apple II.
    *   **Niveaux** : Touches `1`, `2`, `3` pour changer la difficulté (du mode aléatoire au mode Monaco "Expert").

### 2. Snake HGR
*   **Description** : Une version fluide et colorée du célèbre jeu de serpent.
*   **Conception** : Utilise le mode graphique HGR pour un rendu net. Le moteur gère la détection de collision, la génération aléatoire de pommes et une vitesse progressive.
*   **Commandes** : Flèches directionnelles ou touches IJKM.

### 3. Apple Pong
*   **Description** : La base du jeu vidéo, revisitée pour le Apple II.
*   **Conception** : Un duel classique (Humain vs IA ou Humain vs Humain). Le code met l'accent sur les calculs de trajectoire de balle et les interruptions de rafraîchissement pour éviter les clignotements.
*   **Commandes** : Manettes de jeu (Paddles) ou touches clavier.

---

## 🛠️ Outils & Workflow

Le développement a été réalisé grâce à :
*   **VS Code** + **64tass** (Assembleur 6502).
*   **Gemini Code Assist** : Utilisé comme copilote pour optimiser les calculs mathématiques (divisions, randomisation) et l'architecture de l'IA Monaco.

### Les Utilitaires Python (Inclus)
*   **`bas2dsk.py`** : Permet d'injecter des binaires `.bin` ou des fichiers textes `.bas` directement dans une image de disquette `.dsk`. Gère la tokenisation BASIC et le catalogue DOS 3.3.
*   **`dsk2bas.py`** : Opération inverse pour extraire et décoder des programmes BASIC depuis une disquette.
*   **`make_loader.py`** : Génère un chargeur BASIC Applesoft pour injecter et lancer automatiquement des binaires en mémoire.

---

## 🚀 Comment Jouer ?

1. **Compilation** : Compilez votre fichier `.asm` avec `64tass` pour obtenir un `.bin`.
2. **Injection** : Utilisez `bas2dsk.py` pour mettre le binaire sur une disquette :
   ```bash
   python bas2dsk.py pipopipette.bin MASTER.DSK "PIPOPIPETTE" 6000
   ```
3. **Lancement** : Dans votre émulateur (AppleWin, etc.), lancez la disquette et tapez :
   ```basic
   BRUN PIPOPIPETTE
   ```

---

*Bon voyage dans le temps et bonne exploration de la mémoire du 6502 !* ✨