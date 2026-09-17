# 🐦 Flappy Bird & Happy Bird 6502 pour Apple II

Deux adaptations en **Assembleur 6502 pur** du phénomène Flappy Bird, optimisées pour les capacités graphiques Haute Résolution (HGR) de l'Apple II.

---

## 📁 Contenu du dossier

| Fichier | Description |
| :--- | :--- |
| [`flappy.asm`](file:///flappy.asm) | **Flappy Bird Iconic Arcade** : Défilement parallaxe complet, skyline urbain et physique inertielle (implantation `$0803`) |
| [`happybird.asm`](file:///happybird.asm) | **Happy Bird** : Double buffering fluide (Pages 1 & 2 `$2000` / `$4000`), tuyaux bicolores avec bordures et score dynamique (implantation `$6000`) |
| [`flappy.bin`](file:///flappy.bin) | Binaire assemblé de Flappy Bird |
| [`happybird.bin`](file:///happybird.bin) | Binaire assemblé de Happy Bird |
| [`build.bat`](file:///build.bat) | Script de compilation et d'injection automatique dans `AI-ASM.DSK` |

---

## 🕹️ Caractéristiques

- **Mode Haute Résolution (HGR 280×192)** avec double page vidéo sans scintillement.
- **Moteur inertiel** : Vitesse de chute réaliste et impulsion dynamique à chaque battement d'ailes.
- **Obstacles procéduraux** : Tuyaux bicolores avec rebords (*rims*) et défilement continu.
- **Gestion des records** : Suivi des meilleurs scores en temps réel.

---

## ⌨️ Commandes

| Touche | Action |
| :--- | :--- |
| **Barre d'espace / Bouton manette** | Battre des ailes / Sauter |
| **ESC** | Quitter vers le prompt Applesoft BASIC |

---

## 🔨 Compilation & Lancement

```cmd
build.bat
```
Dans l'émulateur avec [`AI-ASM.DSK`](file:///../AI-ASM.DSK) :
```basic
BRUN FLAPPY
BRUN HAPPYBIRD
```
