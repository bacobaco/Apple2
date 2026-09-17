# 🎯 Duel d'Artillerie 6502 (*Artillery Combat*) pour Apple II

Jeu de combat tactique balistique développé en **Assembleur 6502 pur** pour Apple II, Apple II+ et Apple IIe.

Documentation technique détaillée : [`artillerie.md`](file:///artillerie.md).

---

## 📁 Contenu du dossier

| Fichier | Description |
| :--- | :--- |
| [`artillerie.asm`](file:///artillerie.asm) | Code source complet du jeu (implantation `$4000`) |
| [`artillerie.md`](file:///artillerie.md) | Spécifications mathématiques et physiques complètes |
| [`artillerie.bin`](file:///artillerie.bin) | Binaire assemblé |
| [`build.bat`](file:///build.bat) | Script de compilation et d'injection automatique dans `AI-ASM.DSK` |

---

## 🕹️ Caractéristiques

- **Mode Haute Résolution Mixte (HGR 280×160 + 4 lignes de texte)**.
- **Physique balistique 24-bits** :
  - Simulation sub-pixélique des trajectoires paraboliques avec gravité et vent dynamique.
  - Relief procédural généré par séries de Fourier (Plaine, Collines, Montagnes).
  - Déformation géologique en temps réel (cratères d'impact).
- **Cinématique d'explosion en 6 étapes** : Flash, expansion thermique, déflagration plasma, onde de choc annulaire et dissipation.
- **Synthèse acoustique** : Pitch sweep fréquentiel descendant sur `$C030`.
- **Modes de jeu** : 1 Joueur contre l'Ordinateur (IA adaptative) ou 2 Joueurs humains.

---

## ⌨️ Commandes

| Touche | Action |
| :--- | :--- |
| **`A` / `Z`** | Augmenter / Diminuer la puissance du tir |
| **`J` / `K`** | Ajuster l'angle de tir |
| **Barre d'espace** | Déclencher le tir |
| **ESC** | Quitter vers le prompt Applesoft BASIC |

---

## 🔨 Compilation & Lancement

```cmd
build.bat
```
Dans l'émulateur avec [`AI-ASM.DSK`](file:///../AI-ASM.DSK) :
```basic
BRUN ARTILLERIE
```
