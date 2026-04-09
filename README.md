# Expérimentations Rétro : Apple II+ et Apple IIe

Bienvenue dans ce dépôt consacré à la création de jeux et d'expérimentations en **Assembleur 6502** et **Applesoft BASIC** pour les ordinateurs mythiques **Apple II+ et Apple IIe**.

Ces projets ont été développés avec une approche moderne, combinant des outils actuels et l'intelligence artificielle pour redonner vie à ces machines d'époque. 

## 🛠️ Comment ces projets ont-ils été fabriqués ?

Le développement de ces jeux et l'écriture de ces utilitaires ont été réalisés essentiellement grâce à :
*   **VS Code (Visual Studio Code)** couplé à l'extension **APPLETS** (et divers outils dédiés à l'écosystème Apple II).
*   **Gemini Code Assist** : L'intelligence artificielle a été utilisée comme véritable "copilote" de programmation pour aider à la conception de l'architecture, l'optimisation des routines système (Assembleur/BASIC) et la création des puissants scripts Python de gestion de disquettes.

## 📂 Description des fichiers et des utilitaires

Ce dépôt contient le code source des jeux ainsi que des outils Python sur-mesure indispensables pour compiler, convertir et tester le code de manière fluide.

### 1. Les utilitaires de compilation (Python)

*   **`make_loader.py`**
    *   **Rôle :** Ce script prend un fichier exécutable binaire (comme un jeu en assembleur `.bin`) et génère automatiquement un programme **Applesoft BASIC** (`_loader.bas`). Ce programme contient les données binaires sous forme de multiples lignes `DATA`. Lorsqu'il est exécuté sur l'Apple II, il injecte (via la commande `POKE`) ces octets directement dans la mémoire de la machine (généralement à l'adresse `$6000` / `24576` pour la Haute Résolution HGR) avant de lancer le jeu avec un `CALL`.
    *   **Utilisation :** `python make_loader.py <fichier.bin>`

*   **`bas2dsk.py`**
    *   **Rôle :** Outil incontournable permettant d'injecter directement vos fichiers textes BASIC (`.bas`) ou vos binaires (`.bin`) dans une image de disquette au format DOS 3.3 (`.dsk`). Le script est capable de "tokeniser" le BASIC à la volée (le traduire en bytecodes compréhensibles par la ROM Applesoft) et de modifier l'index (VTOC) de l'image `.dsk` de manière autonome.
    *   **Utilisation (BASIC) :** `python bas2dsk.py mon_jeu.bas MASTER.DSK "MON JEU"`
    *   **Utilisation (Binaire) :** `python bas2dsk.py snake.bin MASTER.DSK "SNAKE" 4000`

### 2. Les fichiers de jeux

*   **Fichiers `.asm` / `.s`** : Code source en assembleur 6502 (moteur rapide du jeu).
*   **Fichiers `.bas`** : Code source en Applesoft BASIC (chargeurs, menus, jeux simples).
*   **Fichiers `.bin`** : Les binaires compilés.

## 🚀 Comment tester et utiliser ces jeux ?

Voici le flux de travail typique (workflow) pour compiler et jouer à l'un de ces projets :

1. **Écriture & Compilation :**
   Rédigez le code dans VS Code et compilez la partie Assembleur pour obtenir un fichier binaire (`.bin`).

2. **Génération du chargeur BASIC (Optionnel) :**
   Si votre binaire a besoin d'être chargé confortablement :
   ```bash
   python make_loader.py mon_jeu.bin
   ```
   *(Génère `mon_jeu_loader.bas`)*

3. **Injection dans une disquette :**
   Prenez une image disquette existante (ex: `MASTER.DSK`) et insérez le jeu dedans. L'utilitaire fera automatiquement une sauvegarde `.bak` au cas où !
   ```bash
   python bas2dsk.py mon_jeu_loader.bas MASTER.DSK "SUPER JEU"
   ```

4. **Émulation :**
   Ouvrez votre image `MASTER.DSK` fraîchement modifiée dans un émulateur Apple II de votre choix (comme **AppleWin** sous Windows, **OpenEmulator** / **Virtual II** sous Mac, ou **LinApple** sous Linux).
   Démarrez la machine, tapez la commande suivante et profitez :
   ```basic
   RUN SUPER JEU
   ```

---

*Bon voyage dans le temps et bonne exploration de la mémoire du 6502 !*