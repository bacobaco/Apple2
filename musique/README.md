# 🎼 Fugues de J.S. Bach en 2 Voix Polyphoniques sur Apple II

> **Synthèse acoustique polyphonique à deux voix pures sur le haut-parleur 1-bit (`$C030`) de l'Apple II, utilisant le moteur officiel *Electric Duet* de Paul Lutus (1981).**

---

## 🏛️ 1. Le Défi Matériel : Polyphonie sur Haut-Parleur 1-Bit

L'Apple II (conçu par Steve Wozniak en 1977) ne possède **aucun processeur sonore**, aucun générateur de son programmable (comme le PSG AY-3-8910 ou le SID 6581) et aucun convertisseur numérique-analogique (DAC).

La seule interface acoustique est une bascule logique 1-bit connectée à l'adresse mémoire **`$C030`** :
* Tout accès en lecture ou écriture (`LDA $C030`, `BIT $C030`) **inverse l'état physique de la bascule** du haut-parleur.
* Chaque basculement déplace le cône d'avant en arrière, produisant une impulsion acoustique discrète (un "click").

---

## ⚠️ 2. Pourquoi la Naïve "Synthèse DDS" Produisait du Bruit

Lors d'une première tentative, on pourrait être tenté de faire tourner deux accumulateurs de phase 16-bits (synthèse DDS) et d'inverser `$C030` à chaque fois que la Voix 1 ou la Voix 2 déborde :

```assembly
    ; --- TENTATIVE NAÏVE : SOURCE DE BRUIT PUR ---
    CLC
    LDA ACC1_L : ADC FREQ1_L : STA ACC1_L
    LDA ACC1_H : ADC FREQ1_H : STA ACC1_H
    BCC +
    BIT SPEAKER         ; Toggle flip-flop si débordement Voix 1
+
    CLC
    LDA ACC2_L : ADC FREQ2_L : STA ACC2_L
    LDA ACC2_H : ADC FREQ2_H : STA ACC2_H
    BCC +
    BIT SPEAKER         ; Toggle flip-flop si débordement Voix 2
+
```

### Le Piège Mathématique : Le Ou Exclusif (XOR) et la Modulation en Anneau
Sur une bascule 1-bit (flip-flop T) :
* Inverser la bascule à chaque front de la Voix 1 et à chaque front de la Voix 2 applique mathématiquement l'opération logique **OU Exclusif (XOR)** :
  $$S(t) = S_1(t) \oplus S_2(t)$$
* Or, en traitement du signal, le XOR logique de deux ondes carrées bipolaires $\pm 1$ correspond exactement à leur **multiplication temporelle (modulation en anneau / Ring Modulation)** :
  $$S_1(t) \times S_2(t) = \cos(\omega_1 t) \times \cos(\omega_2 t) = \frac{1}{2} [\cos((\omega_1 + \omega_2)t) + \cos((\omega_1 - \omega_2)t)]$$
* **Conséquence catastrophique :**
  Les fréquences fondamentales $f_1$ et $f_2$ **disparaissent complètement du spectre sonore** ! À leur place apparaissent des dizaines de bandes latérales parasites et inharmoniques :
  $$|f_1 - f_2|, \quad f_1 + f_2, \quad 3f_1 \pm f_2, \quad 5f_1 \pm 3f_2\dots$$
  Dès que la deuxième voix (le Soprano) entre dans la fugue, toute musicalité est détruite et remplacée par un **bourdonnement métallique agressif et strident** (du pur bruit d'intermodulation).

---

## 💡 3. La Solution de Paul Lutus : *Electric Duet* (1981)

En 1981, **Paul Lutus** ([arachnoid.com/electric_duet](https://arachnoid.com/electric_duet/index.html)) a publié *Electric Duet*, le chef-d'œuvre absolu de la synthèse 2 voix sur Apple II.

Paul Lutus ne fait **jamais de XOR** sur la bascule. Il utilise le **Multiplexage Temporel (Time-Domain Multiplexing - TDM)** associé à la **Modulation de Largeur d'Impulsion (PWM)**.

### Le Principe du Découpage à 12,94 kHz
1. La boucle 6502 tourne à temps **rigoureusement constant : exactement 79 cycles d'horloge**.
   $$F_{carrier} = \frac{1\,020\,484\text{ Hz}}{79} \approx 12\,937\text{ Hz}$$
   Cette fréquence ultrasonore se situe tout en haut du spectre audible (ou au-delà de la réponse du haut-parleur).

2. À l'intérieur de cette fenêtre de 79 cycles, le moteur détermine l'état de chaque voix (0 ou 1) :
   * **Voix 1 = 0 et Voix 2 = 0** : Le haut-parleur reste à 0 pendant les 79 cycles (Duty cycle = 0%, tension moyenne = **0,0 V**).
   * **Voix 1 = 1 et Voix 2 = 1** : Le haut-parleur reste à 1 pendant les 79 cycles (Duty cycle = 100%, tension moyenne = **1,0 V**).
   * **Une seule voix active** (1, 0) ou (0, 1) : Le haut-parleur est commuté à la moitié de la boucle (Duty cycle = 50% à 12,9 kHz, tension moyenne = **0,5 V**).

```
                      BOUCLE DE 79 CYCLES (12,94 kHz)
  ───────────────────────────────────────────────────────────────────
  État (0, 0) :   [           HP = BAS (0.0 V)                      ]
  État (1, 0) :   [    HP = HAUT (40c)    ][    HP = BAS (39c)      ] -> Moyenne = 0.5 V
  État (0, 1) :   [    HP = HAUT (40c)    ][    HP = BAS (39c)      ] -> Moyenne = 0.5 V
  État (1, 1) :   [           HP = HAUT (1.0 V)                     ]
  ───────────────────────────────────────────────────────────────────
```

### Le Filtrage Mécanique du Cône : Une Sommation Linéaire Pure
La membrane physique du haut-parleur de l'Apple II possède une masse et une inertie mécanique qui l'empêchent de vibrer à 12,94 kHz. Elle se comporte comme un **filtre analogique passe-bas acoustique d'ordre 2**.

Le déplacement réel de la membrane $x(t)$ correspond donc à la valeur moyenne lissée du signal PWM :
$$x(t) \propto \frac{V_1(t) + V_2(t)}{2}$$

**C'est une SOMMATION LINÉAIRE PARFAITE.**
Puisque l'opération est linéaire :
* Aucun produit de battement ($f_1 \pm f_2$) n'est créé.
* La Voix 1 sonne avec sa fondamentale pure.
* La Voix 2 sonne avec sa fondamentale pure.
* On entend un duo cristallin et harmonieux à deux voix réelles !

---

## 🎵 4. Table des Périodes Musicales

Dans le moteur de Lutus, la période d'une note est le nombre de boucles de 79 cycles constituant une demi-période d'onde carrée.
La formule de conversion est :
$$P = \mathrm{round}\left( \frac{12\,600}{f} \right)$$

Exemples de correspondances :
| Note | Fréquence | Période $P$ | Période hexadécimale |
| :---: | :---: | :---: | :---: |
| **Do 3 (C3)** | 130,8 Hz | 96 | `$60` |
| **Fa 3 (F3)** | 174,6 Hz | 72 | `$48` |
| **Sol 3 (G3)** | 196,0 Hz | 64 | `$40` |
| **Do 4 (C4)** | 261,6 Hz | 48 | `$30` |
| **Ré 4 (D4)** | 293,7 Hz | 43 | `$2B` |
| **Mi♭ 4 (Eb4)**| 311,1 Hz | 40 | `$28` |
| **Fa 4 (F4)** | 349,2 Hz | 36 | `$24` |
| **Sol 4 (G4)** | 392,0 Hz | 32 | `$20` |
| **La 4 (A4)** | 440,0 Hz | 29 | `$1D` |
| **Si♭ 4 (Bb4)**| 466,2 Hz | 27 | `$1B` |
| **Si 4 (B4)** | 493,9 Hz | 26 | `$1A` |
| **Do 5 (C5)** | 523,3 Hz | 24 | `$18` |

Format d'un événement musical (3 octets) :
1. `DURÉE` : Décompte en unités de ~20,2 ms ($256 \times 79\text{ cycles}$).
2. `PÉRIODE_V1` : Période de la voix 1 ($0 = \text{silence}$).
3. `PÉRIODE_V2` : Période de la voix 2 ($0 = \text{silence}$).
4. Fin de partition : `.byte $00, $00, $00`.

---

## 🎹 5. Les Œuvres Embarquées

Le programme `bach.asm` embarque désormais un véritable juke-box contrapuntique à deux voix réelles comprenant 5 chefs-d'œuvre :

### 1. J.S. Bach — Fuga II en Do mineur (BWV 847) — Intégrale (31 mesures, ~1.47 min)
Issue du Livre 1 du *Clavecin bien tempéré* (1722) :
* **397 événements musicaux** à 2 voix pures découpés tranche par tranche.
* **L'intégralité absolue des 31 mesures** de la fugue (au lieu de s'arrêter à la mesure 9) :
  1. *Exposition* : Entrée solennelle du Sujet à l'Alto (mesures 1-2), Réponse du Soprano à la quinte avec contre-sujet 1 (mesures 3-5), entrée de la Basse avec contre-sujet 2 (mesures 7-8).
  2. *Épisodes et divertissements contrapuntiques* : Marches d'harmonie en doubles croches (mesures 9-14), modulation en Mi♭ majeur (mesures 11-14).
  3. *Développement central* : Réexpositions en Sol mineur et Do mineur (mesures 15-26), alternance virtuose des motifs thématiques.
  4. *Coda et Pédale finale* : Pédale de tonique, strette et résolution solennelle sur l'accord final picard (mesures 27-31).

### 2. T. Albinoni / R. Giazotto — Adagio en Sol mineur (~1.27 min)
Le célèbre Adagio baroque en Sol mineur pour cordes et orgue, transcrit avec une rigueur rythmique et mélodique absolue :
* **80 événements musicaux** à 52 BPM (~1 minute 16 secondes de musique, 22 mesures complètes en 3/4).
* **Tonalité originale** : Sol mineur (Gm, Eb, Cm, D7).
* **Richesse rythmique & contrepoint fidèle note pour note** :
  1. *Rythme baroque authentique au violon solo* : Respect scrupuleux des croches pointées suivies de doubles croches (180 ticks / 60 ticks), des triolets de croches (80 ticks) et de la grande envolée lyrique expressive au sommet dramatique en Ré5.
  2. *Basso continuo & pizzicato pulsé* : Marche noble de basse alternant scrupuleusement l'octave basse/haute/basse sur chaque temps de la mesure (Sol2 -> Sol3 -> Sol2, etc.), avec la pédale de dominante en Ré sur l'envolée du violon.
  3. *Cadence solennelle* : Résolution complète sur le Sol mineur final (Do5 -> Si♭4 -> La4 -> Sol4) parfaitement synchronisée entre les deux voix.

### 3. The Beatles — Hey Jude (Paul McCartney, 1968)
Le chef-d'œuvre universellement célébré des Beatles (single Apple Records) :
* **132 événements musicaux** à ~95 BPM (~60 secondes de musique).
* **Tonalité originale** : Fa majeur (F, C, C7, Bb).
* **Déroulement complet centré sur le chant** :
  1. **Couplet complet** : L'introduction vocale (*« Hey Jude, don't make it bad... »*) suivie de la seconde partie (*« Remember to let her into your heart... then you begin to make it better! »*).
  2. **Grande Coda ritournelle vocale en 6 rotations complètes** : Le célèbre hymne universel (*« Naaaa, na, na, na-na-na-na, na-na-na-na, Hey Jude! »*) répété 6 fois en harmonie vocale pure à deux voix (Lead vocal $F_4 \rightarrow A_4 \rightarrow C_5 \rightarrow G_5/F_5 \rightarrow E\flat_5/D_5 \rightarrow C_5$ + Chœur $C_4 \rightarrow F_4 \rightarrow A_4 \rightarrow E\flat_5/D_5 \rightarrow C_5/B\flat_4 \rightarrow A_4$), sans aucune basse lourde qui perturbe le spectre acoustique 1-bit.

### 4. The Beatles — Let It Be (Paul McCartney, 1970)
L'hymne gospel-rock inoubliable des Beatles :
* **89 événements musicaux** à ~72 BPM (~35 secondes de musique).
* **Tonalité originale** : Do majeur (C, G, Am, F).
* **100% centré sur le chant pur (sans intro, duo vocal en tierces)** :
  1. **Couplet 1** : Attaque directe sur le chant fidèle note pour note à Paul McCartney (*« When I find myself in times of trouble, Mother Mary comes to me, speaking words of wisdom, let it be... »*).
  2. **Couplet 2** : (*« And in my hour of darkness, she is standing right in front of me, speaking words of wisdom, let it be... »*).
  3. **Refrain universel** : (*« Let it be, let it be, let it be, yeah let it be, whisper words of wisdom, let it be... »*).
  4. **Cadence finale** : Résolution chorale Beatles en Fa - Mim - Rém - Do.

### 5. The Beatles — I Want You (She's So Heavy) (John Lennon, 1969)
Le riff proto-heavy metal / blues-rock mythique d'*Abbey Road* :
* **109 événements musicaux** en 6/8 (~45 secondes de musique).
* **Tonalité originale** : Ré mineur (Dm, Dm/E, Dm/F, E7♭9, B♭7, A7aug).
* **Structure en 4 temps forts** :
  1. **Arpèges gothiques d'ouverture** en 6/8.
  2. **Couplet Blues lent** (*« I want you, I want you so bad... It's driving me mad! »*) avec les réponses de guitare électrique.
  3. **Transition vocale passionnée** (*« She's so... HEAVY! »*).
  4. **Climax Outro** : Les arpèges massifs avec basse lourde jusqu'à la coupure nette brutale.

---

## 🚀 6. Utilisation & Compilation

### Compilation avec 64tass
```bash
64tass --cbm-prg -o bach.bin bach.asm
```

### Installation sur la disquette DOS 3.3
Le script racine reconstruit la disquette `AI-ASM.DSK` :
```bash
python make_ai_asm.py
```

### Exécution sur Apple II / Émulateur (AppleWin, MAME, Virtual ][)
1. Insérer `AI-ASM.DSK` dans le lecteur 1.
2. Démarrer l'ordinateur (le menu DOS 3.3 s'affiche).
3. Taper :
   ```basic
   BRUN BACH
   ```
4. Menu interactif :
   * Touche **`1`** : J.S. Bach — *Fugue II en Do mineur* (BWV 847) - Complète (31 mesures)
   * Touche **`2`** : T. Albinoni — *Adagio en Sol mineur* (~1.27 min)
   * Touche **`3`** : The Beatles — *Hey Jude* (1968)
   * Touche **`4`** : The Beatles — *Let It Be* (1970)
   * Touche **`5`** : The Beatles — *I Want You (She's So Heavy)* (1969)
   * Touche **`Q`** : Quitter proprement vers DOS 3.3.
   * Pendant la lecture : **n'importe quelle touche** interrompt instantanément la musique et revient au menu principal sans plantage.
