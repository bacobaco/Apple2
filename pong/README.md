# 🏓 Apple Pong pour Apple II

Le grand classique du jeu vidéo d'arcade fidèlement recréé en **Assembleur 6502 pur** pour Apple II, Apple II+ et Apple IIe.

---

## 📁 Contenu du dossier

| Fichier | Description |
| :--- | :--- |
| [`pong.asm`](file:///pong.asm) | Code source complet en assembleur 6502 (implantation `$6000`) |
| [`pong.bin`](file:///pong.bin) | Binaire assemblé prêt pour l'Apple II |
| [`build.bat`](file:///build.bat) | Script de compilation et d'injection automatique dans `AI-ASM.DSK` |

---

## 🕹️ Caractéristiques

- **Rendu Haute Résolution (HGR 280×192)** : Tables de calcul direct d'adresses vidéo intégrées pour une fluidité absolue à 60 FPS sans bug ROM.
- **Physique de rebond avancée** : Angle de renvoi dynamique calculé selon la zone d'impact de la balle sur la raquette.
- **Modes de jeu** : Duel 1 Joueur contre l'Ordinateur ou 2 Joueurs humains.
- **Contrôles analogiques et clavier** : Compatible avec les manettes potentiométriques Apple II (`PDL 0` et `PDL 1`).

---

## ⌨️ Commandes

| Touche / Entrée | Action |
| :--- | :--- |
| **Paddle 0 / Flèches** | Déplacer la raquette du joueur 1 |
| **Paddle 1 / `A` & `Z`** | Déplacer la raquette du joueur 2 |
| **ESC** | Quitter vers le prompt Applesoft BASIC |

---

## 🔨 Compilation & Lancement

```cmd
build.bat
```
Dans l'émulateur avec [`AI-ASM.DSK`](file:///../AI-ASM.DSK) :
```basic
BRUN PONG
```
