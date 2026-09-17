# 1000 Bornes pour Apple II (Assembleur 6502)

Adaptation intégrale et fidèle en assembleur 6502 du jeu **1000 Bornes** pour Thomson MO5, conçu à l'origine en 1985 par **J.Y. Boucrot** et édité par **Free Game Blot** en collaboration avec **Dujardin International**.

---

## 1. Origine et Extraction

Le programme original a été récupéré à partir d'une image de cassette MO5 (`.k7`) au format DCMO6.
* **Format K7** : Enregistrement de blocs LEP/DCMO6 avec protection Thomson MO5 (`SAVE "...", P`, type `0xFE`).
* **Décodage & Détokenisation** :
  * Extraction du flux binaire complet de 15 900 octets.
  * Détokenisation complète de la table de tokens Microsoft BASIC 1.0 (6809) du MO5 grâce au script [detok.py](file:///d:/Documents/Antigravity/Apple2/1000bornes/source/detok.py).
  * Génération du listing BASIC intégral déprotégé : [mbornes_listing.bas](file:///d:/Documents/Antigravity/Apple2/1000bornes/source/mbornes_listing.bas).

---

## 2. Règles du Jeu et Fidélité

Cette version 6502 pour Apple II reprend **l'intégralité des règles officielles et les algorithmes du programme MO5** :

### Le Sabot de 106 Cartes
1. **Bornes / Distances (46 cartes)** :
   * `25 KM` (10 cartes)
   * `50 KM` (10 cartes)
   * `75 KM` (10 cartes)
   * `100 KM` (12 cartes)
   * `200 KM` (4 cartes) — *Règle officielle : maximum 2 cartes de 200 km jouables par manche et par joueur.*
2. **Attaques (18 cartes)** :
   * `PANNE D'ESSENCE` (3 cartes)
   * `ACCIDENT` (3 cartes)
   * `CREVAISON` (3 cartes)
   * `LIMITATION DE VITESSE (50 KM/H)` (4 cartes)
   * `FEU ROUGE` (5 cartes)
3. **Parades / Remèdes (38 cartes)** :
   * `ESSENCE` (6 cartes)
   * `REPARATIONS` (6 cartes)
   * `ROUE DE SECOURS` (6 cartes)
   * `FIN DE LIMITE` (6 cartes)
   * `FEU VERT` (14 cartes) — *Nécessaire pour démarrer et rouler.*
4. **Bottes / Immunités (4 cartes)** :
   * `CITERNE D'ESSENCE` (1 carte) : protège et guérit de la Panne d'essence.
   * `AS DU VOLANT` (1 carte) : protège et guérit de l'Accident.
   * `INCREVABLE` (1 carte) : protège et guérit de la Crevaison.
   * `VEHICULE PRIORITAIRE` (1 carte) : protège et guérit du Feu Rouge et de la Limitation de vitesse, et dispense d'avoir à poser un Feu Vert pour rouler.

### Déroulement de la Partie
* Chaque joueur reçoit **6 cartes**.
* Au début de son tour, le joueur pioche une **7ᵉ carte** dans le sabot.
* Il doit alors **[J]ouer** une carte légale ou en **[D]éfausser** une sur la pile de défausse.
* **Coup-Fourré** :
  * Si l'adversaire pose une attaque et que le joueur détient la botte correspondante, il peut immédiatement déclarer un **COUP-FOURRE** (touche `C` ou confirmation `O`).
  * L'attaque est annulée, la botte est posée, **300 points de bonus** sont accordés, une carte de remplacement est piochée et le joueur prend la main !
* **Objectif d'une manche** : Atteindre exactement **700 km**.
* **Objectif du match** : Cumuler des points de manche jusqu'à atteindre ou dépasser **5000 points**.

### Calcul Officiel des Scores par Manche
* **Distance parcourue** : 1 point par kilomètre (jusqu'à 700).
* **Bottes posées** : 100 points par botte.
* **Bonus 4 Bottes** : +300 points supplémentaires si les 4 bottes ont été posées.
* **Coups-fourrés** : 300 points par coup-fourré.
* **Manche gagnée** (700 km atteints) : +400 points.
* **Bonus "Pas d'étape 200"** : +300 points si la manche a été remportée sans aucune carte de 200 km.
* **Bonus "Sans talon" (Couronnement)** : +300 points si la manche a été remportée alors que le sabot est épuisé.
* **Bonus "Capot"** : +500 points si l'adversaire a terminé la manche à 0 km.

---

## 3. Contrôles sur Apple II

* `1` à `7` : Sélectionner une carte dans votre main.
* `J`, `ESPACE` ou `ENTREE` : **Jouer** la carte sélectionnée.
* `D` : **Défausser** la carte sélectionnée.
* `C` ou `O` : Déclencher un **Coup-Fourré** lorsque l'alerte apparaît.
* `A` : **Abandonner** la manche (confirmation `O`/`N`).

---

## 4. Architecture et Compilation

* **Langage** : Assembleur 6502 pur (compatible `64tass`).
* **Adresse d'implantation** : `$6000` (24576).
* **Affichage** : Mode graphique Haute Résolution HGR plein écran (280x192 pixels, Page 1 `$2000-$3FFF`).
  * Extraction et conversion exacte des 117 caractères graphiques `DEFGR$` du Thomson MO5.
  * Rendu haute fidélité des 20 cartes originales (28x40 pixels chacune) : feux, bornes avec chiffres, citernes, bolides, voitures de police, etc.
  * Moteur typographique HGR 7x8 pixels pour l'affichage des textes, scores et tableaux sans jamais basculer en mode texte.
  * Écran de titre avec logos et cascade animée des cartes avec effets sonores.
  * Feuille de résultats complète tracée en HGR à chaque fin de manche.
* **Sons** : Rendu sonore complet via le haut-parleur Apple II (`$C030`) (bips de pose, son de défausse, alerte d'action illégale, fanfare de coup-fourré et mélodie de victoire).

### Commandes de Compilation
Pour compiler et injecter uniquement 1000 Bornes :
```cmd
cd 1000bornes
build.bat
```

Pour recompiler l'intégralité des jeux assembleur et régénérer le disque amorçable unifié :
```cmd
python make_ai_asm.py
```
Le jeu est alors accessible directement depuis le menu de démarrage sous l'option `B. 1000 BORNES (MO5 1985)`.
