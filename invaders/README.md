# 👾 Space Invaders (1978 Arcade Replica) pour Apple II

Port fidèle et authentique du légendaire **Space Invaders** de Taito (1978), programmé en **Assembleur 6502 pur** pour Apple II, Apple II+ et Apple IIe.

---

## 📁 Contenu du dossier

| Fichier | Description |
| :--- | :--- |
| [`invaders.asm`](file:///invaders.asm) | Code source principal du moteur de jeu (implantation `$6000`) |
| [`invaders_data.asm`](file:///invaders_data.asm) | Motifs graphiques des aliens, soucoupes, bunkers et tables pré-décalées |
| [`invaders.bin`](file:///invaders.bin) | Binaire assemblé prêt pour l'Apple II |
| [`build.bat`](file:///build.bat) | Script de compilation et d'injection automatique dans `AI-ASM.DSK` |

---

## 🕹️ Caractéristiques

- **Mode Haute Résolution (HGR 280×192)** avec page-flipping fluide.
- **Rendu fidèle à l'arcade** :
  - 5 rangées d'aliens (calmars, crabes, poulpes) avec pas de marche accéléré au fur et à mesure des éliminations.
  - 4 bunkers de protection destructibles avec érosion géologique réaliste des impacts.
  - Soucoupe volante mystère (*Mystery Saucer*) rapportant des points bonus.
  - Animation cinématique d'attraction (*Attract Mode*) et table des scores.

---

## ⌨️ Commandes

| Touche | Action |
| :--- | :--- |
| **Flèche Gauche / `A`** | Déplacer le canon vers la gauche |
| **Flèche Droite / `D`** | Déplacer le canon vers la droite |
| **Barre d'espace** | Tirer un missile |
| **ESC** | Quitter vers le prompt Applesoft BASIC |

---

## 🔨 Compilation & Lancement

```cmd
build.bat
```
Dans l'émulateur avec [`AI-ASM.DSK`](file:///../AI-ASM.DSK) :
```basic
BRUN INVADERS
```
