# 🔴 PANG! (Buster Bros) pour Apple II

Port fidèle et authentique du chef-d'œuvre d'arcade **Pang!** (Mitchell Corporation, 1989) développé en **Assembleur 6502 pur** pour Apple II, Apple II+ et Apple //e.

Intégré directement dans la disquette maître du projet : [`..\AI-ASM.DSK`](file:///../AI-ASM.DSK).

---

## 📁 Contenu du dossier

| Fichier | Description |
| :--- | :--- |
| [`pang.asm`](file:///pang.asm) | Moteur de jeu complet : physique arcade, joueur, tir anti-répétition, collisions parfaites, invulnérabilité au respawn, page-flipping HGR (`$6000`) |
| [`pang_data.asm`](file:///pang_data.asm) | Tables HGR ($2000-$3FFF), masques, police ASCII complète 8×8 et sprites pré-décalés (joueur, bulles, grappin) |
| [`build_pang_assets.py`](file:///build_pang_assets.py) | Générateur Python des sprites avec couleurs HGR Apple II authentiques et tables précalculées |
| [`build.bat`](file:///build.bat) | Script de compilation `64tass` et injection directe du binaire `PANG` dans [`AI-ASM.DSK`](file:///../AI-ASM.DSK) |

---

## 🕹️ Améliorations & Authenticité Arcade

1. **Graphisme de Buster retravaillé à l'identique de l'arcade** :
   - Casquette safari/baseball orange avec visière profilée et mèche de cheveux.
   - Visage expressif avec grands yeux animés et pupilles sombres.
   - Salopette bleue avec bretelles apparentes sur t-shirt orange, jambes et bottes d'explorateur.
   - Animation complète : pose au repos (*stand*), marche alternée (*walk1*, *walk2*), tir vers le haut avec fusil tenu à deux mains (*shoot*), et chute d'impact (*hit*).
   - Couleurs HGR Apple II pures par frangeage NTSC (bits pairs = Bleu, bits impairs = Orange, paires de bits = Blanc éclatant, zéros = contours noirs nets).

2. **Résolution des bugs de tir et de scission des bulles** :
   - **Détection de collision AABB complète** : la pointe du grappin (large de 7 pixels) et le câble vertical détectent les bulles sur l'ensemble de leur largeur et sur toute la hauteur jusqu'au sol (`FLOOR_Y = 174`), éliminant tout tir traversant sans effet, même au ras du sol.
   - **Débouncer & Cooldown de tir (*Single-Shot Trigger*)** : suppression du tir automatique répété en rafale. Il est impératif de relâcher le bouton avant de tirer à nouveau, et un temps de recharge évite que les deux bulles filles n'éclatent instantanément à l'apparition.

3. **Invulnérabilité temporaire après réapparition (*Respawn Protection*)** :
   - Lorsque Buster perd une vie, il réapparaît au centre avec **~2,5 secondes d'invulnérabilité** (`player_invinc_timer = 90`).
   - Clignotement visuel rétro (8 Hz) pour signaler la protection au joueur.
   - Décompte immédiat du compteur `LIVES:` mis à jour à l'écran.

4. **Double-Buffering HGR 280×192 & Dirty Rectangles** :
   - Alternance Page 1 (`$2000`) et Page 2 (`$4000`) à 35 FPS avec effacement symétrique sans traînée ni clignotement.
   - Bordures colorées (murs bleus, sol orange) et HUD parfaitement net (`SCORE:`, `STAGE 01`, `LIVES:`).

---

## 🎮 Commandes de jeu (Clavier & Manette)

| Périphérique | Touche / Axe | Action |
| :--- | :--- | :--- |
| **Clavier** | **Flèche Gauche / `A`** | Déplacer Buster vers la gauche |
| **Clavier** | **Flèche Droite / `D`** | Déplacer Buster vers la droite |
| **Clavier** | **Espace / Entrée** | Tirer le grappin |
| **Clavier** | **ESC** | Quitter vers le prompt Applesoft DOS 3.3 |
| **Manette** | **Joystick 0 (Gauche / Droite)** | Déplacer Buster |
| **Manette** | **Bouton 0 / Bouton 1** | Tirer le grappin |

---

## 🔨 Lancement & Test sous AppleWin

1. **Démarrer la disquette maître :**
   ```cmd
   D:\Emulateurs\AppleWin\Applewin.exe -d1 "c:\Users\baco\Documents\Apple2\AI-ASM.DSK"
   ```
2. **Dans le menu Applesoft `HELLO` :**
   - Appuyez sur la touche **`P`** pour lancer directement `PANG! ARCADE (1989 HGR)`.
