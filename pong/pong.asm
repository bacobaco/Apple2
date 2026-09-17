* = $6000               ; Le jeu charge en $6000 (24576) pour une sécurité absolue

.cpu "6502"

    jmp Start           ; SAUT VITAL : Enjamber les données pour aller au code !

; ===================================================================
; PONG - APPLE II+ (ACCES MEMOIRE DIRECT HGR1)
; 100% Sans Bug ROM - Code natif
; ===================================================================

; --- Soft Switches Matériels ---
TXTCLR   = $C050        ; Active les Graphismes
MIXCLR   = $C052        ; Plein écran (Désactive les 4 lignes de texte)
TXTPAGE1 = $C054        ; Affiche la Page 1 ($2000-$3FFF)
TXTPAGE2 = $C055        ; Affiche la Page 2 ($4000-$5FFF)
HIRES    = $C057        ; Mode Haute Résolution
PDL       = $FB1E       ; Lit le paddle/joystick (numéro dans X, retour dans Y)
SPEAKER   = $C030       ; Soft Switch: Clique le haut-parleur (son)
BTN0      = $C061       ; Soft Switch: Bouton 0 du joystick (Bit 7 = 1 si pressé)
BTN1      = $C062       ; Soft Switch: Bouton 1 du joystick
KEYBD     = $C000       ; Clavier: Dernière touche pressée
KBDSTRB   = $C010       ; Clavier: Réinitialise le strobe

; --- Pointeur en Page Zéro ---
PTR      = $06          ; Pointeur utilisé pour écrire à l'écran

; ===================================================================
; TABLES DE LOOKUP HGR1 (Calcul direct des adresses vidéo par 64tass)
; ===================================================================
HGR_LO:
.for y = 0, y < 192, y += 1
    .byte <($2000 + (y & 7) * 1024 + ((y / 8) & 7) * 128 + (y / 64) * 40)
.next

HGR_HI:
.for y = 0, y < 192, y += 1
    .byte >($2000 + (y & 7) * 1024 + ((y / 8) & 7) * 128 + (y / 64) * 40)
.next

; ===================================================================
; VARIABLES LOCALES (Protégées dans le bloc de code $4000)
; ===================================================================
BALL_X:   .byte 19      ; Colonne de la balle (0-39)
BALL_Y:   .byte 96      ; Ligne de la balle (0-191)
BALL_X_OFF:.byte 0      ; Décalage au pixel près de la balle (0-6)
BALL_V_PX:.byte 2       ; Vitesse de la balle en pixels par frame
BALL_DX:  .byte 1       ; Direction X
BALL_DY:  .byte 1       ; Direction Y
PAD1_Y:   .byte 80      ; Raquette IA (Gauche)
PAD2_Y:   .byte 80      ; Raquette Joueur (Droite)
OLD_B_X:  .byte 19, 19  ; Historique Page 1 et Page 2
OLD_B_Y:  .byte 96, 96
OLD_P1:   .byte 80, 80
OLD_P2:   .byte 80, 80
SCORE_P1: .byte 0
SCORE_P2: .byte 0
SCORE_COLOR_P1:.byte $7F; Couleur du score 1
SCORE_COLOR_P2:.byte $7F; Couleur du score 2
BLINK_TARGET: .byte 0   ; Cible du clignotement (1 ou 2)
FRAME:    .byte 0
COLOR:    .byte 0
TEMP_X:   .byte 0
TEMP_Y:   .byte 0
TEMP_H:   .byte 0
TEMP_W:   .byte 0
TEMP_C:   .byte 0
BASE_X:   .byte 0
BASE_Y:   .byte 0
DIGIT_MSK:.byte 0
PAGE_IDX: .byte 0       ; 0 = Dessine sur Page 1, 1 = Dessine sur Page 2
PAGE_OFF: .byte 0       ; Offset Haut (0x00 ou 0x20)
SPEED:    .byte 0       ; Vitesse (Délai) du jeu
SCROLL_POS:.byte 0      ; Position du texte défilant
SCROLL_TICK:.byte 0     ; Vitesse du défilement
GAME_ACTIVE:.byte 0     ; 0 = Attente, 1 = En Jeu
SCORE_FLAG: .byte 0     ; 0 = Jeu, 1 = P1 Marque, 2 = P2 Marque
PIXEL_SHIFT:.byte 0     ; Décalage fluide au pixel (0-6)
TEXT_BUF: .byte 0,0,0,0,0,0,0,0,0,0
          .byte 0,0,0,0,0,0,0,0,0,0
          .byte 0,0,0,0,0,0,0,0,0,0
          .byte 0,0,0,0,0,0,0,0,0,0
          .byte 0,0     ; Marge supplémentaire pour le décalage fluide

; ===================================================================
; DEBUT DU JEU
; ===================================================================
Start:
    sta TXTCLR
    sta MIXCLR
    sta TXTPAGE1
    sta HIRES

    ; --- Pre-calculer la police "Grasse" en RAM une seule fois ---
    ldx #0
BoldLoop:
    lda FontData,x
    sta TEMP_W
    and #$7F
    asl
    ora TEMP_W
    and #$7F
    ora #$80
    sta FontData,x
    inx
    cpx #208            ; 26 caractères * 8 octets (Ajout de S et T)
    bne BoldLoop

    jsr ClearBothScreens

    lda #0
    sta SCORE_P1
    sta SCORE_P2
    sta SCROLL_POS
    sta SCROLL_TICK
    sta PIXEL_SHIFT
    sta BALL_X_OFF
    sta BLINK_TARGET    ; Sécurité : on s'assure de ne pas cibler de clignotement
    sta PAGE_IDX        ; Sécurité : on initialise le flip de page à 0

    ; --- Dessin statique initial sur les deux pages ---
    lda #$00
    sta PAGE_OFF        ; FIX : Force la Page 1 (ClearBothScreens l'avait laissé à $20 !)
    lda #$7F
    sta COLOR
    sta SCORE_COLOR_P1  ; Sécurité : Force les couleurs en blanc au démarrage
    sta SCORE_COLOR_P2
    jsr DrawBorders
    jsr DrawScores
    lda #$20
    sta PAGE_OFF
    lda #$7F
    sta COLOR
    jsr DrawBorders
    jsr DrawScores
    lda #$00
    sta PAGE_OFF

    lda #80
    sta PAD1_Y
    sta PAD2_Y
    sta OLD_P1
    sta OLD_P1+1
    sta OLD_P2
    sta OLD_P2+1

    lda #19
    sta OLD_B_X
    sta OLD_B_X+1
    lda #96
    sta OLD_B_Y
    sta OLD_B_Y+1

    jsr ResetRoundSub
    jmp WaitGameOver

ResetRoundSub:
    ; --- Effacer proprement l'ancienne balle des deux pages ---
    lda #$00
    sta COLOR
    lda #6
    sta TEMP_H
    
    lda #$00
    sta PAGE_OFF
    lda OLD_B_X
    ldy OLD_B_Y
    ldx #2          ; Efface 2 colonnes pour nettoyer les débordements de pixels
    jsr DrawRect
    
    lda #$20
    sta PAGE_OFF
    lda #6
    sta TEMP_H
    lda OLD_B_X+1
    ldy OLD_B_Y+1
    ldx #2          ; Efface 2 colonnes
    jsr DrawRect

    lda BALL_DX
    eor #$FE            ; Inversion propre du sens de la balle
    sta BALL_DX
    
    cmp #1              ; Si la balle va vers la droite (1)
    beq ServeRight
    lda #19             ; Part à gauche -> Colonne 19 (à gauche du filet)
    jmp StoreServeX
ServeRight:
    lda #20             ; Part à droite -> Colonne 20 (à droite du filet)
StoreServeX:
    sta BALL_X
    sta OLD_B_X
    sta OLD_B_X+1
    
    lda #0
    sta BALL_X_OFF
    
    lda #96
    sta BALL_Y
    sta OLD_B_Y
    sta OLD_B_Y+1

    lda #0              ; AUCUN DELAI ! On tourne à vitesse processeur MAX !
    sta SPEED
    
    lda #4              ; Vitesse initiale plus rapide : 4 px/frame (dynamique direct !)
    sta BALL_V_PX
    
    lda #0
    sta SCORE_FLAG
    sta BLINK_TARGET    ; Réinitialise la cible de clignotement
    rts

WaitGameOver:
    lda #0
    sta GAME_ACTIVE

WaitStart:
    jsr DoFrame         ; Fait tourner l'animation (Attract Mode)
    lda BTN0
    bmi StartNewGame    ; Bouton 0 pressé ?
    lda BTN1
    bmi StartNewGame    ; Bouton 1 pressé ?
    lda KEYBD
    bpl WaitStart       ; Touche clavier pressée ? (Bit 7 = 1)
    sta KBDSTRB         ; Réinitialise le buffer du clavier

StartNewGame:
    ; --- Effacer "PRESS START" des deux pages proprement ---
    lda #$00
    sta COLOR

        lda #16
    sta TEMP_H
    lda #$00
    sta PAGE_OFF
        lda #9              ; Centre X pour x2 (40 - 22)/2 = 9
        ldy #60             ; Y = 60 (Vers le haut de l'écran)
        ldx #22             ; Largeur = 22 colonnes (11 caractères * 2)
    jsr DrawRect

        lda #16
    sta TEMP_H
    lda #$20
    sta PAGE_OFF
        lda #9              ; X = 9
        ldy #60             ; Y = 60
        ldx #22             ; Largeur = 22 colonnes
    jsr DrawRect
    lda #$00
    sta PAGE_OFF

    lda SCORE_P1
    ora SCORE_P2
    beq StartGameActive ; Si 0-0, on lance direct sans redessiner
    lda #0
    sta SCORE_P1
    sta SCORE_P2
    lda #$00
    sta PAGE_OFF
    jsr DrawScores
    lda #$20
    sta PAGE_OFF
    jsr DrawScores
StartGameActive:
    lda #1              ; Lance la partie !
    sta GAME_ACTIVE

; ===================================================================
; BOUCLE PRINCIPALE (Double Buffering)
; ===================================================================
GameLoop:
    jsr DoFrame
    lda SCORE_FLAG
    beq GameLoop        ; Si 0, la partie continue normalement

    ; --- Gestion sécurisée du Score ---
    cmp #1
    beq P1Scored
    
    lda #2
    sta BLINK_TARGET
    jsr DoBlink
    inc SCORE_P2
    jsr DoBlink
    jmp CheckWinCondition

P1Scored:
    lda #1
    sta BLINK_TARGET
    jsr DoBlink
    inc SCORE_P1
    jsr DoBlink

CheckWinCondition:
    lda SCORE_P1
    cmp #10
    bcs CheckDiff
    lda SCORE_P2
    cmp #10
    bcc NextRound
CheckDiff:
    sec
    lda SCORE_P1
    sbc SCORE_P2
    bcs PosDiff
    lda SCORE_P2
    sec
    sbc SCORE_P1
PosDiff:
    cmp #2
    bcc NextRound       ; Différence < 2, on continue l'échange !
    jsr ResetRoundSub
    jmp WaitGameOver

NextRound:
    jsr ResetRoundSub
    lda #1
    sta GAME_ACTIVE
    jmp GameLoop

DoFrame:
    ; --- Vérifier si la touche ESC est pressée pour quitter ---
    lda KEYBD
    cmp #$9B            ; Code pour la touche ESC ($1B | $80)
    bne SkipQuit
    jmp QuitGame
SkipQuit:
    ; ---------------------------------------------------------

    inc FRAME

    ; --- 0. BASCULER SUR LA PAGE CACHEE ---
    lda PAGE_IDX
    eor #1
    sta PAGE_IDX
    beq SetPage1
    lda #$20
    sta PAGE_OFF
    jmp PageSet
SetPage1:
    lda #$00
    sta PAGE_OFF
PageSet:

    ; --- 1. EFFACER L'HISTORIQUE DE LA PAGE CACHEE ---
    lda #$00
    sta COLOR
    lda #6
    sta TEMP_H
    ldx PAGE_IDX
    lda OLD_B_X,x
    ldy OLD_B_Y,x
    ldx #2          ; Nettoie l'ancien sprite (2 colonnes de large)
    jsr DrawRect
    
    lda #28
    sta TEMP_H
    ldx PAGE_IDX
    lda #2
    ldy OLD_P1,x
    ldx #1
    jsr DrawRect
    
    lda #28
    sta TEMP_H
    ldx PAGE_IDX
    lda #37
    ldy OLD_P2,x
    ldx #1
    jsr DrawRect

    ; --- 2. DEPLACER LES RAQUETTES ---
    ; Joueur (Joystick en mode Relatif - Reste en place si lâché)
    ldx #1            ; PDL(1) = Lecture de l'axe Y du Joystick
    jsr PDL
    tya
    
    cmp #112            ; Seuil Haut Zone Morte
    bcc JoyUp
    cmp #144            ; Seuil Bas Zone Morte
    bcs JoyDown
    jmp Pad2Done        ; Zone morte : la raquette ne bouge absolument pas !

JoyUp:
    sta TEMP_C
    lda #112
    sec
    sbc TEMP_C          ; Calcule la vitesse (112 - A)
    lsr
    lsr
    lsr                 ; Divise par 8 pour la proportionnalité
    clc
    adc #2              ; Vitesse minimum de 2
    sta TEMP_H
    lda PAD2_Y
    sec
    sbc TEMP_H
    bcc FixPad2         ; Sécurité anti-underflow (si Y passe sous 0)
    cmp #4
    bcs StorePad2
FixPad2:
    lda #4              ; Bloque strictement sous la bordure haute
StorePad2:
    sta PAD2_Y
    jmp Pad2Done

JoyDown:
    sec
    sbc #144            ; Calcule la vitesse (A - 144)
    lsr
    lsr
    lsr                 ; Divise par 8
    clc
    adc #2              ; Vitesse minimum de 2
    clc
    adc PAD2_Y
    cmp #153            ; Limite basse (Au-dessus de la nouvelle bordure)
    bcc +
    lda #152
+   sta PAD2_Y
Pad2Done:

    ; Intelligence Artificielle Imbattable (Vitesse x2 et Angles Max)
    lda BALL_DY
    bmi AITargetBottom  ; Si balle monte (DY négatif), vise avec le bas de la raquette
AITargetTop:
    lda PAD1_Y
    sec
    sbc #2              ; Cible = Extrême bord haut de la raquette
    jmp AICmp
AITargetBottom:
    lda PAD1_Y
    clc
    adc #27             ; Cible = Extrême bord bas de la raquette
AICmp:
    sta TEMP_W          ; Sauvegarde la cible dynamique
    cmp BALL_Y
    beq AIDone
    bcs AIUp
AIDown:
    lda BALL_Y
    sec
    sbc TEMP_W          ; Distance à la cible
    cmp #4
    bcc AIDown1
AIDown2:
    lda PAD1_Y
    clc
    adc #4              ; Vitesse Max : 4 pixels par frame (Ralentie)
    jmp StoreAIDown
AIDown1:
    lda PAD1_Y
    clc
    adc #2
StoreAIDown:
    cmp #153            ; Limite basse
    bcc +
    lda #152
+   sta PAD1_Y
    jmp AIDone

AIUp:
    lda TEMP_W
    sec
    sbc BALL_Y          ; Distance à la cible
    cmp #4
    bcc AIUp1
AIUp2:
    lda PAD1_Y
    sec
    sbc #4              ; Vitesse Max : 4 px/frame
    jmp StoreAIUp
AIUp1:
    lda PAD1_Y
    sec
    sbc #2
StoreAIUp:
    bcc FixPad1         ; Sécurité anti-underflow
    cmp #4              ; Limite haute
    bcs StorePad1
FixPad1:
    lda #4              ; Bloque à 4 sous la bordure
StorePad1:
    sta PAD1_Y
AIDone:

    lda GAME_ACTIVE
    beq SkipBall        ; Ne bouge la balle que si la partie a commencé

    ; --- 3. DEPLACER LA BALLE ---
    jsr MoveBall

SkipBall:
    ; --- 5. DESSINER LES NOUVELLES POSITIONS ---
    lda #$7F
    sta COLOR
    jsr DrawBorders
    jsr DrawPressStart  ; S'exécute AVANT le filet pour ne pas abîmer le décor !
    jsr DrawNet
    
    lda BALL_Y          ; Répare les scores uniquement si la balle passe dessus
    cmp #48
    bcc RepairScores
    ldx PAGE_IDX
    lda OLD_B_Y,x
    cmp #48
    bcs SkipScores
RepairScores:
    jsr RepairScoreDigits
SkipScores:

    jsr DrawScrollText
    jsr DrawAll

    ; --- 4. SAUVEGARDER LE NOUVEL HISTORIQUE ---
    lda SCORE_FLAG
    bne SkipHistory     ; Interdit de sauvegarder la balle si elle est sortie !
    ldx PAGE_IDX
    lda BALL_X
    sta OLD_B_X,x
    lda BALL_Y
    sta OLD_B_Y,x
SkipHistory:
    ldx PAGE_IDX
    lda PAD1_Y
    sta OLD_P1,x
    lda PAD2_Y
    sta OLD_P2,x

    ; --- 6. FLIP (AFFICHER LA PAGE CACHEE) ---
    lda PAGE_IDX
    beq ShowPage1
    sta TXTPAGE2
    jmp FlipDone
ShowPage1:
    sta TXTPAGE1
FlipDone:

    ; --- 7. TIMING ---
    jsr Delay
    rts

; ===================================================================
; LOGIQUE DE LA BALLE ET DES COLLISIONS
; ===================================================================
MoveBall:

    lda BALL_DX
    cmp #1
    beq MoveRightPx

MoveLeftPx:
    ldy BALL_V_PX       ; Boucle infaillible pixel par pixel pour grande vitesse
MoveLeftLoop:
    dec BALL_X_OFF
    bpl MoveLeftNext
    lda #6
    sta BALL_X_OFF
    dec BALL_X
MoveLeftNext:
    dey
    bne MoveLeftLoop
    jmp MoveY

MoveRightPx:
    ldy BALL_V_PX
MoveRightLoop:
    inc BALL_X_OFF
    lda BALL_X_OFF
    cmp #7
    bcc MoveRightNext
    lda #0
    sta BALL_X_OFF
    inc BALL_X
MoveRightNext:
    dey
    bne MoveRightLoop

MoveY:

    lda BALL_Y
    clc
    adc BALL_DY
    sta BALL_Y

    ; Rebond Haut/Bas
    lda BALL_Y
    cmp #200
    bcs HitTop          ; Sécurité : Y négatif (wrap-around 8 bits)
    cmp #4
    bcc HitTop
    cmp #174            ; Nouvelle bordure basse à 180 (180 - 6px)
    bcs HitBottom
    jmp CheckPads
    
HitTop:
    lda #0              ; Inversion de DY (DY = -DY)
    sec
    sbc BALL_DY
    sta BALL_DY
    lda #4              ; Repousse sous la bordure
    sta BALL_Y
    jsr BeepWall
    jmp CheckPads
    
HitBottom:
    
    lda #0              ; Inversion de DY (DY = -DY)
    sec
    sbc BALL_DY
    sta BALL_DY
    lda #173
    sta BALL_Y
    jsr BeepWall
    jmp CheckPads

CheckPads:
    ; Rebond Raquette Gauche (IA)
    lda BALL_DX
    cmp #$FF            ; Ne teste la raquette gauche QUE si la balle va à gauche
    bne CheckRightPad
    
    lda BALL_X
    cmp #128            ; Sécurité anti-wrap (Balle très rapide passée en négatif)
    bcs DoLeftCheck
    cmp #4              ; Zone élargie (0 à 3) pour contrer l'effet tunnel
    bcs CheckRightPad
    
DoLeftCheck:
    lda BALL_Y
    clc
    adc #5              ; Pied de la balle carrée (6px)
    cmp PAD1_Y
    bcc CheckRightPad   ; Passe au-dessus
    
    lda PAD1_Y
    clc
    adc #28             ; Pied de la raquette
    cmp BALL_Y
    bcc CheckRightPad   ; Passe en dessous
    
    ; Calcul dynamique de l'angle
    lda BALL_Y
    clc
    adc #3              ; Centre de la balle carrée
    sec
    sbc PAD1_Y          ; Index d'impact de 0 à 30
    bcs +
    lda #0
+   cmp #30
    bcc +
    lda #30
+   tax
    lda BounceAngles,x
    sta BALL_DY
    
    lda BALL_V_PX
    cmp #16              ; Vitesse max plafonnée à 8 px/frame pour préserver la fluidité
    bcs SpeedCap1
    inc BALL_V_PX       ; Accélération !
SpeedCap1:
    
    lda #1
    sta BALL_DX
    lda #3
    sta BALL_X
    lda #0              ; Repousse proprement au pixel 0
    sta BALL_X_OFF
    jsr BeepPad
    rts

CheckRightPad:
    ; Rebond Raquette Droite (Joueur)
    lda BALL_DX
    cmp #1              ; Ne teste la raquette droite QUE si la balle va à droite
    bne CheckScore
    
    lda BALL_X
    cmp #128            ; Si wrap négatif (balle à gauche), on ignore la raquette droite !
    bcs CheckScore
    cmp #35             ; Zone élargie (35 à 38) pour contrer l'effet tunnel
    bcc CheckScore
    
    lda BALL_Y
    clc
    adc #5              ; Pied de la balle carrée (6px)
    cmp PAD2_Y
    bcc CheckScore      ; Passe au-dessus
    
    lda PAD2_Y
    clc
    adc #28             ; Pied de la raquette
    cmp BALL_Y
    bcc CheckScore      ; Passe en dessous
    
    ; Calcul dynamique de l'angle
    lda BALL_Y
    clc
    adc #3
    sec
    sbc PAD2_Y          ; Index d'impact de 0 à 30
    bcs +
    lda #0
+   cmp #30
    bcc +
    lda #30
+   tax
    lda BounceAngles,x
    sta BALL_DY
    
    lda BALL_V_PX
    cmp #16             ; Synchronisation de la vitesse max extrême (16 px/frame) !
    bcs SpeedCap2
    inc BALL_V_PX       ; Accélération !
SpeedCap2:
    
    lda #$FF
    sta BALL_DX
    lda #36             ; Répulsion PARFAITEMENT collée à la raquette
    sta BALL_X
    lda #0              ; Au pixel près
    sta BALL_X_OFF
    jsr BeepPad
    rts

CheckScore:
    ; Sortie d'écran
    lda BALL_X
    cmp #128            ; Valeur négative (wrap)
    bcc CheckRightOut
    
    lda #2
    sta SCORE_FLAG      ; Lève le drapeau pour Joueur 2
    rts
CheckRightOut:
    cmp #39
    bcc MoveBallDone
    
    lda #1
    sta SCORE_FLAG      ; Lève le drapeau pour Joueur 1
    rts
MoveBallDone:
    rts

; ===================================================================
; ROUTINES GRAPHIQUES DIRECTES (HGR1 MEMORY)
; ===================================================================
DrawAll:
    lda #28
    sta TEMP_H
    lda #2
    ldy PAD1_Y
    ldx #1
    jsr DrawRect
    lda #28
    sta TEMP_H
    lda #37
    ldy PAD2_Y
    ldx #1
    jsr DrawRect

    lda SCORE_FLAG
    bne SkipDrawBallRect ; Interdit de dessiner la balle si elle est sortie !
    
    jsr DrawBall
SkipDrawBallRect:
    rts

DrawPressStart:
    lda GAME_ACTIVE
    beq ContinueDrawPS1
    jmp PressStartDone
ContinueDrawPS1:

    ; 1. Effacer la zone texte (Rectangle noir)
    lda #$00
    sta COLOR
    lda #16
    sta TEMP_H
    lda #9          ; Centre X pour x2
    ldy #60         ; Vers le haut de l'écran
    ldx #22         ; Largeur (11 caractères * 2 = 22)
    jsr DrawRect
    
    ; 2. Logique de clignotement (Blink)
    lda FRAME
    and #$10        ; Clignote toutes les 16 frames (2 fois plus rapide !)
    beq ContinueDrawPS2
    jmp PressStartDone
ContinueDrawPS2:
    
    ; 3. Dessiner "PRESS START" en taille x2 (Horizontal et Vertical)
    lda #0
    sta TEMP_Y
PStartRowLoop:
    lda #0
    sta TEMP_X      ; Index du caractère
PStartColLoop:
    ldx #0
    ldx TEMP_X
    lda TitleString,x
    asl
    asl
    asl
    clc
    adc TEMP_Y
    tay
    lda FontData,y  ; Récupère le pixel de la police
    and #$7F        ; Retire le bit de couleur
    
    ; --- Expansion Automatique (1 bit devient 2 bits, 1 Octet devient 2 Octets) ---
    sta DIGIT_MSK
    lda #0
    sta TEMP_W      ; TEMP_W = Octet Gauche
    sta TEMP_C      ; TEMP_C = Octet Droit
    
    lsr DIGIT_MSK
    bcc PSkip0
    lda #$03
    sta TEMP_W
PSkip0:
    lsr DIGIT_MSK
    bcc PSkip1
    lda TEMP_W
    ora #$0C
    sta TEMP_W
PSkip1:
    lsr DIGIT_MSK
    bcc PSkip2
    lda TEMP_W
    ora #$30
    sta TEMP_W
PSkip2:
    lsr DIGIT_MSK
    bcc PSkip3
    lda TEMP_W
    ora #$40
    sta TEMP_W
    lda #$01
    sta TEMP_C
PSkip3:
    lsr DIGIT_MSK
    bcc PSkip4
    lda TEMP_C
    ora #$06
    sta TEMP_C
PSkip4:
    lsr DIGIT_MSK
    bcc PSkip5
    lda TEMP_C
    ora #$18
    sta TEMP_C
PSkip5:
    lsr DIGIT_MSK
    bcc PSkip6
    lda TEMP_C
    ora #$60
    sta TEMP_C
PSkip6:
    lda TEMP_W
    ora #$80
    sta TEMP_W
    lda TEMP_C
    ora #$80
    sta TEMP_C
    ; -------------------------------------------------------------------------
    
    lda TEMP_X
    asl
    clc
    adc #9
    sta BASE_X      ; Position X de base (9 + Char * 2)
    
    ; --- Dessine Ligne 1 ---
    lda TEMP_Y
    asl
    clc
    adc #60
    tay
    lda HGR_LO,y
    sta PTR
    lda HGR_HI,y
    clc
    adc PAGE_OFF
    sta PTR+1
    
    ldy BASE_X
    lda TEMP_W
    sta (PTR),y
    iny
    lda TEMP_C
    sta (PTR),y
    
    ; --- Dessine Ligne 2 (Zoom Vertical) ---
    lda TEMP_Y
    asl
    clc
    adc #61
    tay
    lda HGR_LO,y
    sta PTR
    lda HGR_HI,y
    clc
    adc PAGE_OFF
    sta PTR+1
    
    ldy BASE_X
    lda TEMP_W
    sta (PTR),y
    iny
    lda TEMP_C
    sta (PTR),y
    
    inc TEMP_X
    lda TEMP_X
    cmp #11         ; Longueur de "PRESS START"
    beq PStartRowNext
    jmp PStartColLoop
    
PStartRowNext:
    inc TEMP_Y
    lda TEMP_Y
    cmp #8
    beq PressStartDone
    jmp PStartRowLoop
    
PressStartDone:
    rts

; Nouvelle routine de rendu au pixel près pour la balle
DrawBall:
    lda #6
    sta TEMP_H
    ldx BALL_X_OFF
    lda BallMaskLeft,x
    sta TEMP_W
    lda BallMaskRight,x
    sta TEMP_C
    
    lda BALL_X
    sta TEMP_X
    lda BALL_Y
    sta TEMP_Y
    
DrawBallLoop:
    ldy TEMP_Y
    lda HGR_LO,y
    sta PTR
    lda HGR_HI,y
    clc
    adc PAGE_OFF
    sta PTR+1
    
    ldy TEMP_X
    lda (PTR),y
    ora TEMP_W      ; Fusionne l'octet gauche de la balle avec le décor
    sta (PTR),y
    
    iny
    lda (PTR),y
    ora TEMP_C      ; Fusionne l'octet droit de la balle (le débordement) avec le décor
    sta (PTR),y
    
    inc TEMP_Y
    dec TEMP_H
    bne DrawBallLoop
    rts

; Super-Routine universelle pour tracer des rectangles HGR
DrawRect:
    sta TEMP_X
    sty TEMP_Y
    stx TEMP_W
DrawRectLoop:
    ldy TEMP_Y
    lda HGR_LO,y
    sta PTR
    lda HGR_HI,y
    clc
    adc PAGE_OFF        ; Redirige vers Page 1 ou Page 2
    sta PTR+1

    ldy TEMP_X          ; Y = Position directe de la colonne à l'écran
    ldx TEMP_W          ; X = Compteur de la largeur restante
    lda COLOR           ; A = Couleur (chargée une seule fois !)
DrawRectHori:
    sta (PTR),y
    iny
    dex
    bne DrawRectHori
    inc TEMP_Y
    dec TEMP_H
    bne DrawRectLoop
    rts

; ===================================================================
; DESSIN DE L'ARENE (Style Hanimex 7771)
; ===================================================================
DrawBorders:
    ; Bordure Haute (Epaisse)
    lda #4
    sta TEMP_H
    lda #0
    ldy #0
    ldx #40
    jsr DrawRect

    ; Bordure Basse (Epaisse)
    lda #4
    sta TEMP_H
    lda #0
    ldy #180            ; Remontée pour laisser la place au texte en bas !
    ldx #40
    jsr DrawRect
    rts

DrawNet:
    ; Filet central pointillé parfaitement au centre (Pixel 139 et 140)
    lda #5
    sta BASE_Y
NetLoop:
    lda #6
    sta TEMP_H
    lda #$40            ; Pixel le plus à droite de l'octet 19 (bit 6)
    sta COLOR
    lda #19             ; Demi-filet gauche (fin octet 19)
    ldy BASE_Y
    ldx #1
    jsr DrawRect
    
    lda #6
    sta TEMP_H
    lda #$01            ; Pixel le plus à gauche de l'octet 20 (bit 0)
    sta COLOR
    lda #20             ; Demi-filet droit (début octet 20)
    ldy BASE_Y
    ldx #1
    jsr DrawRect
    lda BASE_Y
    clc
    adc #12             ; Espace vide entre les carrés
    sta BASE_Y
    cmp #180            ; Arrête le filet avant de toucher la bordure du bas
    bcc NetLoop
    
    lda #$7F            ; Restaure la couleur blanche pleine pour le reste du jeu
    sta COLOR
    rts

; --- DESSINER LES SCORES (En Chiffres) ---
DrawScores:
    lda BLINK_TARGET
    cmp #2
    beq DrawScoreP2Only

DrawScoreP1Only:
    ; --- EFFACER L'ANCIEN SCORE P1 ---
    lda #$00
    sta COLOR
    lda #31
    sta TEMP_H
    lda #5              ; Effaceur Joueur 1
    ldy #15
    ldx #9
    jsr DrawRect

    ; --- DESSINER LE NOUVEAU SCORE P1 ---
    lda SCORE_COLOR_P1
    sta COLOR
    lda SCORE_P1
    ldx #8              ; Centre du score Joueur 1
    jsr DrawTwoDigits

    lda BLINK_TARGET
    bne DrawScoresDone  ; Si on cible P1, on s'arrête ici pour ne pas toucher P2 !

DrawScoreP2Only:
    ; --- EFFACER L'ANCIEN SCORE P2 ---
    lda #$00
    sta COLOR
    lda #31
    sta TEMP_H
    lda #24             ; Effaceur Joueur 2
    ldy #15
    ldx #9
    jsr DrawRect

    ; --- DESSINER LE NOUVEAU SCORE P2 ---
    lda SCORE_COLOR_P2
    sta COLOR
    lda SCORE_P2
    ldx #27             ; Centre du score Joueur 2
    jsr DrawTwoDigits

DrawScoresDone:
    rts
    
RepairScoreDigits:
    ; Redessine juste les chiffres sans le gros carré noir (évite le clignotement)
    lda SCORE_COLOR_P1
    sta COLOR
    lda SCORE_P1
    ldx #8              ; Centre du score Joueur 1
    jsr DrawTwoDigits

    lda SCORE_COLOR_P2
    sta COLOR
    lda SCORE_P2
    ldx #27             ; Centre du score Joueur 2
    jmp DrawTwoDigits   ; Optimisation tail call

DrawTwoDigits:
    ldy #0
Div10:
    cmp #10
    bcc Div10Done
    sec
    sbc #10
    iny
    jmp Div10
Div10Done:
    pha                 ; Sauvegarder les unités
    stx BASE_X          ; Toujours sauvegarder le point de départ
    tya                 ; A = Dizaines
    beq IsSingleDigit   ; Centrage parfait si un seul chiffre

    ; --- Mode 2 Chiffres ---
    pha
    lda BASE_X
    sec
    sbc #2              ; Décale les dizaines à gauche
    sta BASE_X
    pla
    ldy #15
    sty BASE_Y
    jsr DrawDigit       ; Dessiner les dizaines
    
    lda BASE_X
    clc
    adc #4              ; Décale les unités à droite
    sta BASE_X

IsSingleDigit:
    pla                 ; Récupère les unités (A = le chiffre)
    ldy #15
    sty BASE_Y
    jsr DrawDigit       ; Dessiner les unités
    rts

; Dessine un chiffre géant épais (3 colonnes x 31 lignes)
DrawDigit:
    tax
    lda DigitMasks,x
    sta DIGIT_MSK

    ; Segment 0: Haut
    lsr DIGIT_MSK
    bcc DigSkip0
    lda #3
    sta TEMP_H
    lda BASE_X
    ldy BASE_Y
    ldx #3
    jsr DrawRect
DigSkip0:
    ; Segment 1: Haut-Gauche
    lsr DIGIT_MSK
    bcc DigSkip1
    lda #15               ; Rallongé pour combler l'absence de barre horizontale
    sta TEMP_H
    lda BASE_X
    ldy BASE_Y
    ldx #1
    jsr DrawRect
DigSkip1:
    ; Segment 2: Haut-Droit
    lsr DIGIT_MSK
    bcc DigSkip2
    lda #15               ; Rallongé pour combler l'absence de barre horizontale
    sta TEMP_H
    lda BASE_X
    clc
    adc #2
    ldy BASE_Y
    ldx #1
    jsr DrawRect
DigSkip2:
    ; Segment 3: Milieu
    lsr DIGIT_MSK
    bcc DigSkip3
    lda #3
    sta TEMP_H
    lda BASE_Y
    clc
    adc #14
    tay
    lda BASE_X
    ldx #3
    jsr DrawRect
DigSkip3:
    ; Segment 4: Bas-Gauche
    lsr DIGIT_MSK
    bcc DigSkip4
    lda #17               ; Rallongé vers le bas pour s'aligner avec le 0
    sta TEMP_H
    lda BASE_Y
    clc
    adc #14
    tay
    lda BASE_X
    ldx #1
    jsr DrawRect
DigSkip4:
    ; Segment 5: Bas-Droit
    lsr DIGIT_MSK
    bcc DigSkip5
    lda #17               ; Rallongé vers le bas pour s'aligner avec le 0
    sta TEMP_H
    lda BASE_Y
    clc
    adc #14
    tay
    lda BASE_X
    clc
    adc #2
    ldx #1
    jsr DrawRect
DigSkip5:
    ; Segment 6: Bas
    lsr DIGIT_MSK
    bcc DigSkip6
    lda #3
    sta TEMP_H
    lda BASE_Y
    clc
    adc #28
    tay
    lda BASE_X
    ldx #3
    jsr DrawRect
DigSkip6:
    rts

DigitMasks:
    .byte $77 ; 0
    .byte $24 ; 1
    .byte $5D ; 2
    .byte $6D ; 3
    .byte $2E ; 4
    .byte $6B ; 5
    .byte $7B ; 6
    .byte $25 ; 7
    .byte $7F ; 8
    .byte $6F ; 9
    
BounceAngles:
    ; Table des 31 angles avec des rebonds hyper extrêmes sur les bords
    .byte $FA, $FB                        ; Hyper Extrême Haut (-6, -5)
    .byte $FC, $FD, $FD                   ; Extrême Haut (-4, -3, -3)
    .byte $FE, $FE, $FE, $FE              ; Haut fort (-2)
    .byte $FF, $FF, $FF, $FF, $FF         ; Haut normal (-1)
    .byte $00, $00, $00                   ; Centre (0)
    .byte $01, $01, $01, $01, $01         ; Bas normal (+1)
    .byte $02, $02, $02, $02              ; Bas fort (+2)
    .byte $03, $03, $04                   ; Extrême Bas (+3, +3, +4)
    .byte $05, $06                        ; Hyper Extrême Bas (+5, +6)

DrawScrollText:
    inc SCROLL_TICK
    lda SCROLL_TICK
    cmp #1              ; Vitesse: 1 update par frame
    bne SkipScroll
    lda #0
    sta SCROLL_TICK
    
    inc PIXEL_SHIFT
    lda PIXEL_SHIFT
    cmp #7              ; 7 pixels de décalage max (largeur d'un caractère Apple II)
    bne SkipScroll
    lda #0
    sta PIXEL_SHIFT
    
    inc SCROLL_POS
    lda SCROLL_POS
    cmp #54             ; Longueur de la phrase (54 caractères)
    bne SkipScroll
    lda #0
    sta SCROLL_POS
SkipScroll:

    ; Pré-calculer les 41 caractères en cache pour cette image (40 + marge de scroll)
    ldx #0
PrecalcScroll:
    txa
    clc
    adc SCROLL_POS
    cmp #54             ; Longueur de la phrase
    bcc PrecalcOk
    sec
    sbc #54
PrecalcOk:
    tay
    lda ScrollString,y
    asl
    asl
    asl
    sta TEXT_BUF,x      ; Sauvegarde l'offset du caractère
    inx
    cpx #41
    bne PrecalcScroll

    lda #0
    sta TEMP_Y
ScrollRowLoop:
    ldy TEMP_Y
    tya
    clc
    adc #185            ; Y = 185 (Laisse 1 pixel de marge avec le terrain !)
    tay
    lda HGR_LO,y
    sta PTR
    lda HGR_HI,y
    clc
    adc PAGE_OFF
    sta PTR+1
    
    ldx #0
ScrollColLoop:
    stx TEMP_X
    
    ; --- Lit le Caractère de Gauche ---
    lda TEXT_BUF,x
    clc
    adc TEMP_Y
    tay
    lda FontData,y
    sta TEMP_W
    
    ; --- Lit le Caractère de Droite ---
    inx
    lda TEXT_BUF,x
    clc
    adc TEMP_Y
    tay
    lda FontData,y
    sta TEMP_C
    
    dex                 ; Restaure la colonne en cours
    
    lda PIXEL_SHIFT
    beq ScrollShiftDone
    
    ; --- Décale le caractère de gauche vers la droite ---
    tay                 ; Y = nombre de décalages
    lda TEMP_W
    and #$7F
SrlLoop:
    lsr
    dey
    bne SrlLoop
    sta TEMP_W
    
    ; --- Décale le caractère de droite vers la gauche ---
    lda #7
    sec
    sbc PIXEL_SHIFT
    tay                 ; Y = 7 - décalages
    lda TEMP_C
    and #$7F
SllLoop:
    asl
    dey
    bne SllLoop
    
    ora TEMP_W          ; Combine les pixels des deux caractères
    ora #$80            ; Restaure le bit de palette 
    sta TEMP_W
    
ScrollShiftDone:
    ldy TEMP_X
    lda TEMP_W
    sta (PTR),y
    
    inx
    cpx #40             ; La boucle dessine exactement 40 colonnes visibles
    bne ScrollColLoop
    
    inc TEMP_Y
    lda TEMP_Y
    cmp #7              ; On ne dessine que 7 lignes de la police pour ne pas déborder à Y=192
    bcc ScrollRowLoop
    rts

FontData:
    .byte $80,$80,$80,$80,$80,$80,$80,$80 ; 0: Espace
    .byte $82,$81,$81,$81,$81,$81,$82,$80 ; 1: (
    .byte $81,$82,$82,$82,$82,$82,$81,$80 ; 2: )
    .byte $8E,$91,$81,$81,$81,$91,$8E,$80 ; 3: C
    .byte $8F,$91,$91,$8F,$91,$91,$8F,$80 ; 4: B
    .byte $8E,$91,$91,$9F,$91,$91,$91,$80 ; 5: A
    .byte $8E,$91,$91,$91,$91,$91,$8E,$80 ; 6: O
    .byte $80,$80,$80,$8E,$80,$80,$80,$80 ; 7: -
    .byte $8F,$91,$91,$8F,$81,$81,$81,$80 ; 8: P
    .byte $91,$91,$93,$95,$99,$91,$91,$80 ; 9: N
    .byte $8E,$91,$81,$9D,$91,$91,$8E,$80 ; 10: G
    .byte $8F,$91,$91,$8F,$89,$91,$91,$80 ; 11: R
    .byte $9F,$81,$81,$8F,$81,$81,$9F,$80 ; 12: E
    .byte $91,$9B,$95,$91,$91,$91,$91,$80 ; 13: M
    .byte $8E,$84,$84,$84,$84,$84,$8E,$80 ; 14: I
    .byte $9F,$90,$8C,$90,$91,$91,$8E,$80 ; 15: 3
    .byte $80,$80,$80,$80,$80,$84,$80,$80 ; 16: .
    .byte $84,$86,$84,$84,$84,$84,$8E,$80 ; 17: 1
    .byte $91,$91,$91,$91,$8A,$84,$80,$80 ; 18: V
    .byte $81,$81,$81,$81,$81,$81,$9F,$80 ; 19: L
    .byte $8E,$91,$90,$88,$84,$82,$9F,$80 ; 20: 2
    .byte $8E,$91,$99,$95,$93,$91,$8E,$80 ; 21: 0
    .byte $8E,$81,$8F,$91,$91,$91,$8E,$80 ; 22: 6
    .byte $91,$91,$8A,$84,$84,$84,$84,$80 ; 23: Y (Nouveau caractère)
    .byte $8E,$81,$81,$8E,$90,$90,$8E,$80 ; 24: S (Corrigé pour le mode Bold)
    .byte $9F,$84,$84,$84,$84,$84,$84,$80 ; 25: T (Nouveau caractère)

ScrollString:
    ; "(C) BACO - PONG PAR GEMINI 3.1 PRO - AVRIL 2026"
    .byte 1,3,2,0,4,5,3,6,0,7,0,8,6,9,10,0,8,5,11,0,10,12,13,14,9,14,0,15,16,17,0,8,11,6,0,7,0,5,18,11,14,19,0,20,21,20,22,0,0,0,0,0,0,0
    
TitleString:
    .byte 8, 11, 12, 24, 24, 0, 24, 25, 5, 11, 25 ; "PRESS START"

ClearBothScreens:
    lda #$00
    sta PAGE_OFF
    jsr ClearScreen
    lda #$20
    sta PAGE_OFF
    jsr ClearScreen
    rts

ClearScreen:
    lda PAGE_OFF
    clc
    adc #$20            ; Page 1 ($20) ou Page 2 ($40) correctement calculé
    sta PTR+1
    lda #$00
    sta PTR
    tay
ClearLoop:              ; On efface une page de 8 Ko
    lda #$00
ClearInner:
    sta (PTR),y
    iny
    bne ClearInner
    inc PTR+1
    lda PTR+1
    and #$1F            ; Détecte la fin des $20 pages (8192 octets)
    bne ClearLoop
    rts

; ===================================================================
; SONS ET TIMINGS
; ===================================================================
BeepWall:
    ldy #15          ; Moins d'oscillations
BWall1:
    lda SPEAKER
    ldx #80          ; Délai plus long = Son plus grave (Pong)
BWall2:
    dex
    bne BWall2
    dey
    bne BWall1
    rts

BeepPad:
    ldy #30          ; Plus d'oscillations
BPad1:
    lda SPEAKER
    ldx #30          ; Délai très court = Son très aigu (Ping)
BPad2:
    dex
    bne BPad2
    dey
    bne BPad1
    rts

DoBlink:
    lda PAGE_OFF
    pha             ; Sauvegarder la page actuelle
    
    lda #10
    sta TEMP_W      ; Fréquence de base du 1er balayage (très aigu)
    
    lda #4          ; 4 ondulations (2 clignotements avant, 2 après !)
    pha             ; Sauvegarder le compteur sur la pile du processeur
PacLoop:
    lda BLINK_TARGET
    cmp #1
    bne BlinkP2
    lda SCORE_COLOR_P1
    eor #$7F
    sta SCORE_COLOR_P1  ; Inverse la couleur du Joueur 1
    jmp DrawBlink
BlinkP2:
    lda SCORE_COLOR_P2
    eor #$7F
    sta SCORE_COLOR_P2  ; Inverse la couleur du Joueur 2
DrawBlink:
    
    lda #$00
    sta PAGE_OFF
    jsr DrawScores  ; Dessine l'état clignotant sur Page 1
    lda #$20
    sta PAGE_OFF
    jsr DrawScores  ; Dessine l'état clignotant sur Page 2
    
    lda TEMP_W
    sta TEMP_C
    clc
    adc #60
    sta TEMP_X      ; Limite dynamique du balayage (Base + 60)
PacSweep:
    ldy #12         ; Vitesse du balayage (légèrement accélérée)
PacS1:
    lda SPEAKER     ; Clique le haut-parleur
    ldx TEMP_C
PacS2:
    dex
    bne PacS2
    dey
    bne PacS1
    lda TEMP_C
    clc
    adc #2          ; Glissando vers le bas
    sta TEMP_C
    cmp TEMP_X      ; Atteint la limite qui se décale à chaque fois ?
    bcc PacSweep
    
    lda TEMP_W
    clc
    adc #15         ; À la boucle suivante, la sirène partira plus grave !
    sta TEMP_W
    
    pla             ; Récupère le compteur de la pile
    sec
    sbc #1
    beq PacEnd      ; Si 0, on a fini !
    pha             ; Remet le compteur sur la pile
    jmp PacLoop
PacEnd:
    ; --- Le fameux double "Wa-Wa" final de Pac-Man ---
    ; Plop 1 (Très rapide)
    lda #90         ; Départ grave
    sta TEMP_C
Wa1:
    ldy #8          ; Maintien extrêmement court
Wa1Loop:
    lda SPEAKER
    ldx TEMP_C
Wa1Wait:
    dex
    bne Wa1Wait
    dey
    bne Wa1Loop
    lda TEMP_C
    sec
    sbc #4          ; Monte en flèche très rapidement (-4 d'un coup)
    sta TEMP_C
    cmp #30
    bcs Wa1

    ; Silence court
    ldy #120
Sil1:
    ldx #200
SilWait1:
    dex
    bne SilWait1
    dey
    bne Sil1
    
    ; Plop 2 (Légèrement plus grave pour l'effet de chute)
    lda #100        ; Départ encore plus grave
    sta TEMP_C
Wa2:
    ldy #8          ; Très rapide
Wa2Loop:
    lda SPEAKER
    ldx TEMP_C
Wa2Wait:
    dex
    bne Wa2Wait
    dey
    bne Wa2Loop
    lda TEMP_C
    sec
    sbc #4          ; Monte en flèche
    sta TEMP_C
    cmp #40
    bcs Wa2
    ; -------------------------------------------------

    lda #$7F
    ldx BLINK_TARGET
    cpx #1
    bne RestoreP2
    sta SCORE_COLOR_P1  ; Restaurer Blanc Joueur 1
    jmp EndBlink
RestoreP2:
    sta SCORE_COLOR_P2  ; Restaurer Blanc Joueur 2
EndBlink:
    ; --- Redessine les scores en blanc à la fin du clignotement ---
    lda #$00
    sta PAGE_OFF
    jsr DrawScores
    lda #$20
    sta PAGE_OFF
    jsr DrawScores
    ; -------------------------------------------------------------
    pla
    sta PAGE_OFF    ; Restaurer la page vidéo d'origine
    rts

QuitGame:
    sta KBDSTRB         ; Réinitialise le strobe du clavier pour éviter une boucle

    ; --- Restaurer le mode texte standard ---
    sta $C051           ; Active le mode texte (contre $C050 pour graphiques)
    sta $C053           ; Désactive le mode plein écran (contre $C052)
    jsr $FCA8           ; Routine ROM pour effacer l'écran (HOME)

    ; --- Retour propre au BASIC de DOS 3.3 ---
    jmp $3D0            ; Effectue un "Warm Start" de DOS 3.3


Delay:
    lda SPEED
    beq DelayDone       ; Si 0 = pas de délai, vitesse absolue !
    ldy SPEED           ; Utilise la vitesse dynamique
Delay1:
    ldx #$FF
Delay2:
    dex
    bne Delay2
    dey
    bne Delay1
DelayDone:
    rts

; --- Tables de décalage des pixels de la Balle (Sprites) ---
BallMaskLeft:
    .byte $7F, $7E, $7C, $78, $70, $60, $40
BallMaskRight:
    .byte $00, $01, $03, $07, $0F, $1F, $3F