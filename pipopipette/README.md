# 🟩 Pipopipette (*Dots and Boxes*) pour Apple II

Jeu complet de **Pipopipette** (la Pipopipette / *Dots and Boxes*) développé en **Assembleur 6502 pur** pour Apple II, Apple II+ et Apple IIe.

---

## 📁 Contenu du dossier

| Fichier | Description |
| :--- | :--- |
| [`pipopipette.asm`](file:///pipopipette.asm) | Code source complet en assembleur 6502 |
| [`fonttable.asm`](file:///fonttable.asm) | Table de caractères 8×8 (police bitmap HGR, chiffres, spinner et symboles) |
| [`pipopipette.bin`](file:///pipopipette.bin) | Fichier binaire assemblé (adresse d'implantation : `$6000`) |
| [`build.bat`](file:///build.bat) | Script automatisé de compilation et d'injection dans l'image disquette |

---

## 🕹️ Caractéristiques du Jeu

- **Écran de titre & sélection de grille interactive** :
  - Sélection par **Joystick (Haut / Bas + Bouton 0/1)** ou **Clavier (Flèches, 1-3, 5-7, Entrée)**
  - `1` ou `5` : Grille **5×5** (25 boîtes, 36 points)
  - `2` ou `6` : Grille **6×6** (36 boîtes, 49 points)
  - `3` ou `7` : Grille **7×7** (49 boîtes, 64 points)
- **Rendu Haute Résolution (HGR 280×192)** avec double tamponnage (*double buffering / page-flipping*).
- **Intelligence Artificielle à 3 Niveaux** (sélectionnables avec les touches `1`, `2`, `3`) :
  - **Niveau 1 (Bon)** : Joue les coups immédiats et évite les erreurs flagrantes.
  - **Niveau 2 (Excellent)** : Évalue la qualité de chaque coup sûr et minimise les sacrifices.
  - **Niveau 3 (Imbattable - MCTS)** : Moteur de simulation Monte Carlo (*MCTS rollouts*) évaluant les fins de partie, avec spinner animé et compteur de progression en pourcentage réel (**0% à 100%**) en moins de 22 secondes.
- **Cinématique d'adieu (*Farewell Animation*)** avec volet, iris zoom, fanfare sonore Sol Majeur et retour propre au BASIC (`JMP $E003`).

---

## ⌨️ Commandes

| Touche | Action |
| :--- | :--- |
| **Flèches** | Déplacer le curseur |
| **Espace** | Basculer l'orientation du trait (Horizontal / Vertical) |
| **Entrée** | Valider et poser le trait |
| **1, 2, 3** | Changer le niveau de l'ordinateur en direct |
| **R** | Recommencer la partie (reset propre sans boucle clavier) |

---

## 🔨 Compilation & Injection

Pour compiler et injecter le jeu dans la disquette maître :
```cmd
build.bat
```
Ou manuellement avec `64tass` et `bas2dsk.py` :
```cmd
64tass -b pipopipette.asm -o pipopipette.bin
python ..\bas2dsk.py pipopipette.bin ..\AI-ASM.DSK "PIPOPIPETTE" 6000
```
Dans l'émulateur Apple II :
```text
BRUN PIPOPIPETTE
```
