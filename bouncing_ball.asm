; =============================================================
; APPLE //e TENNIS BALL PHYSICS DEMO
; Location: $6000 - ROUND BALL & SMART SOUND
; =============================================================

        * = $6000

; --- Softswitches Apple II ---
KBD     = $C000       ; Clavier Data
KBDSTRB = $C010       ; Clavier Strobe (Clear)
TXTCLR  = $C050       ; Mode Graphique
MIXCLR  = $C052       ; Pas de texte en bas (Full Screen)
TXTPAGE1 = $C054      ; Page 1
TXTPAGE2 = $C055      ; Page 2
HIRES   = $C057       ; Mode Haute Résolution
SPEAKER = $C030       ; Click sonore (optionnel)
BUTN0   = $C061       ; Bouton Joystick 0 (Open Apple)

; --- Constantes Physique ---
GRAVITY     = $0020   ; Force de gravité (ajustée pour ~25fps)
THRUST_Y    = $0048   ; Poussée verticale (ajustée pour ~25fps)
THRUST_X    = $0012   ; Poussée horizontale (ajustée pour ~25fps)
BOUNCE_DAMP = 1       ; Amortissement (vitesse divisée par 2)
FLOOR_Y     = 140     ; Sol (bord bas - hauteur balle)
WALL_R      = 32      ; Mur droit (40 colonnes - 8 octets sprite)
PREAD       = $FB1E   ; Routine ROM lecture paddle

; --- Variables (Page Zéro pour vitesse) ---
PTR_L   = $06         ; Pointeur écran Low
PTR_H   = $07         ; Pointeur écran High
SPR_L   = $08         ; Pointeur Sprite Low
SPR_H   = $09         ; Pointeur Sprite High
TEMP    = $0A
TEMP2   = $0B
START_X = $0C         ; Position X (en octets)
PAGE_OFFS = $0D       ; Offset page HGR (0=$2000, $20=$4000)

; --- Variables Programme (après les sprites) ---
VAR_BASE    = $7600   ; Zone de variables (APRÈS les sprites et tables)
POS_Y_INT   = VAR_BASE+0
POS_Y_FRAC  = VAR_BASE+1
VEL_Y_INT   = VAR_BASE+2
VEL_Y_FRAC  = VAR_BASE+3
FRAME_IDX   = VAR_BASE+4
DRAW_PAGE   = VAR_BASE+5  ; 0=page1, 1=page2
DISPLAY_PAGE= VAR_BASE+6  ; 0=page1, 1=page2
POS_X_INT   = VAR_BASE+7  ; Position X (colonne octet 0-32)
POS_X_FRAC  = VAR_BASE+8  ; Position X (fraction)
VEL_X_INT   = VAR_BASE+9  ; Vitesse X (entier signé)
VEL_X_FRAC  = VAR_BASE+10 ; Vitesse X (fraction)
ANIM_ACC    = VAR_BASE+11 ; Accumulateur rotation (fractionnaire)
PREV_Y_0    = VAR_BASE+12 ; Ancienne pos Y page 0 (effacement local)
PREV_X_0    = VAR_BASE+13 ; Ancienne pos X page 0
PREV_Y_1    = VAR_BASE+14 ; Ancienne pos Y page 1
PREV_X_1    = VAR_BASE+15 ; Ancienne pos X page 1
FRIC_CTR    = VAR_BASE+16 ; Compteur friction (rolling)

; =============================================================
; MAIN PROGRAM
; =============================================================
ENTRY_POINT
        JSR INIT_HGR        ; Initialiser graphismes
        JSR GEN_Y_TABLES    ; Générer table des adresses lignes
        JSR INIT_PHYSICS    ; Initialiser variables
        LDA POS_X_INT       ; Position X initiale
        STA START_X         ; Pour le dessin initial
        JSR SET_PAGE_OFFS   ; Préparer page 1
        JSR DRAW_BALL       ; Dessiner la balle initiale
        LDA #1
        STA DRAW_PAGE
        JSR SET_PAGE_OFFS
        JSR DRAW_BALL       ; Préparer la page 2 avec la même image
        LDA #0
        STA DRAW_PAGE
        STA DISPLAY_PAGE
        STA PAGE_OFFS

MAIN_LOOP
        ; 1. Dessiner sur la page arrière (double buffering HGR)
        LDA DISPLAY_PAGE
        EOR #1
        STA DRAW_PAGE
        JSR SET_PAGE_OFFS

        ; 2. Effacer la balle (effacement local rapide)
        JSR ERASE_BALL

        ; 3. Calcul Physique
        JSR UPDATE_PHYSICS

        ; 3b. Copier position X pour dessin
        LDA POS_X_INT
        STA START_X

        ; 4. Animation (Rotation)
        JSR UPDATE_ANIM

        ; 5. Dessiner la balle à la nouvelle position
        JSR DRAW_BALL

        ; 5b. Sauvegarder position pour effacement futur
        JSR SAVE_POS

        ; 6. Basculer l'affichage vers la page dessinée
        JSR FLIP_DISPLAY

        ; 7. Attente (VBL approximatif pour réguler la vitesse)
        JSR WAIT_FRAME

        ; 8. Gestion Clavier (Quitter avec une touche)
        LDA KBD
        BPL MAIN_LOOP       ; Pas de touche -> boucle
        BIT KBDSTRB         ; Clear strobe
        RTS                 ; Retour propre au BASIC ou au lanceur

; =============================================================
; SUBROUTINES
; =============================================================

INIT_HGR
        BIT TXTCLR
        BIT MIXCLR
        BIT HIRES
        BIT TXTPAGE1
        ; Effacer les deux pages HGR (Noir)
        LDA #$00
        LDX #$20        ; Start at $2000
        STX PTR_H
        LDY #$00
        STY PTR_L
CLR_P1_LOOP
        STA (PTR_L),Y
        INY
        BNE CLR_P1_LOOP
        INC PTR_H
        LDX PTR_H
        CPX #$40        ; End at $4000
        BNE CLR_P1_LOOP

        LDX #$40        ; Start at $4000
        STX PTR_H
        LDY #$00
        STY PTR_L
CLR_P2_LOOP
        STA (PTR_L),Y
        INY
        BNE CLR_P2_LOOP
        INC PTR_H
        LDX PTR_H
        CPX #$60        ; End at $6000
        BNE CLR_P2_LOOP
        RTS

INIT_PHYSICS
        LDA #0
        STA POS_Y_INT
        STA POS_Y_FRAC
        STA VEL_Y_INT
        STA VEL_Y_FRAC
        STA FRAME_IDX
        STA VEL_X_INT
        STA VEL_X_FRAC
        STA POS_X_FRAC
        STA ANIM_ACC
        STA FRIC_CTR
        STA PREV_Y_0
        STA PREV_Y_1
        LDA #16             ; Position X initiale (centré)
        STA POS_X_INT
        STA PREV_X_0
        STA PREV_X_1
        LDA #0
        STA DRAW_PAGE
        STA DISPLAY_PAGE
        STA PAGE_OFFS
        RTS

UPDATE_PHYSICS
        ; === GRAVITÉ (Y seulement) ===
        CLC
        LDA VEL_Y_FRAC
        ADC #<GRAVITY
        STA VEL_Y_FRAC
        LDA VEL_Y_INT
        ADC #>GRAVITY
        STA VEL_Y_INT

        ; === JOYSTICK (Bouton = poussée, Paddle = direction X+Y) ===
        LDA BUTN0
        BPL NO_JOYSTICK     ; Bit 7=0 → pas appuyé

        ; Lire Paddle 1 (axe Y) pour direction verticale
        LDX #1
        JSR PREAD           ; Y = 0-255 (0=haut, 255=bas)
        CPY #100
        BCC JOY_UP          ; < 100 → poussée vers le haut
        CPY #156
        BCS JOY_DOWN        ; >= 156 → poussée vers le bas
        JMP JOY_X           ; Zone morte Y → passer à X

JOY_UP
        SEC
        LDA VEL_Y_FRAC
        SBC #<THRUST_Y
        STA VEL_Y_FRAC
        LDA VEL_Y_INT
        SBC #>THRUST_Y
        STA VEL_Y_INT
        JMP JOY_X

JOY_DOWN
        CLC
        LDA VEL_Y_FRAC
        ADC #<THRUST_Y
        STA VEL_Y_FRAC
        LDA VEL_Y_INT
        ADC #>THRUST_Y
        STA VEL_Y_INT

JOY_X
        ; Lire Paddle 0 (axe X) pour direction horizontale
        LDX #0
        JSR PREAD           ; Y = 0-255 (0=gauche, 255=droite)
        CPY #100
        BCC JOY_LEFT        ; < 100 → poussée gauche
        CPY #156
        BCS JOY_RIGHT       ; >= 156 → poussée droite
        JMP NO_JOYSTICK     ; Zone morte centrale

JOY_LEFT
        SEC
        LDA VEL_X_FRAC
        SBC #<THRUST_X
        STA VEL_X_FRAC
        LDA VEL_X_INT
        SBC #>THRUST_X
        STA VEL_X_INT
        JMP NO_JOYSTICK

JOY_RIGHT
        CLC
        LDA VEL_X_FRAC
        ADC #<THRUST_X
        STA VEL_X_FRAC
        LDA VEL_X_INT
        ADC #>THRUST_X
        STA VEL_X_INT

NO_JOYSTICK

        ; === APPLIQUER VITESSE Y : POS_Y += VEL_Y ===
        CLC
        LDA POS_Y_FRAC
        ADC VEL_Y_FRAC
        STA POS_Y_FRAC
        LDA POS_Y_INT
        ADC VEL_Y_INT
        STA POS_Y_INT

        ; === APPLIQUER VITESSE X : POS_X += VEL_X ===
        CLC
        LDA POS_X_FRAC
        ADC VEL_X_FRAC
        STA POS_X_FRAC
        LDA POS_X_INT
        ADC VEL_X_INT
        STA POS_X_INT

        ; === COLLISION PLAFOND (Y underflow → >= $C0) ===
        LDA POS_Y_INT
        CMP #$C0
        BCC Y_TOP_OK
        LDA #0
        STA POS_Y_INT
        STA POS_Y_FRAC
        ; Rebond plafond
        SEC
        LDA #0
        SBC VEL_Y_FRAC
        STA VEL_Y_FRAC
        LDA #0
        SBC VEL_Y_INT
        STA VEL_Y_INT
Y_TOP_OK

        ; === COLLISION SOL (Y >= FLOOR_Y) ===
        LDA POS_Y_INT
        CMP #FLOOR_Y
        BCC Y_FLOOR_OK

        LDA #FLOOR_Y
        STA POS_Y_INT
        LDA #0
        STA POS_Y_FRAC

        ; Son rebond sol
        LDA VEL_Y_INT
        BEQ NO_FLOOR_SND
        JSR PLAY_SOUND
NO_FLOOR_SND
        ; Inverser VEL_Y
        SEC
        LDA #0
        SBC VEL_Y_FRAC
        STA VEL_Y_FRAC
        LDA #0
        SBC VEL_Y_INT
        STA VEL_Y_INT
        ; Amortir >>1 (signé)
        LDA VEL_Y_INT
        BMI DAMP_Y_NEG
        CLC
        ROR VEL_Y_INT
        ROR VEL_Y_FRAC
        JMP CHECK_DEAD_Y
DAMP_Y_NEG
        SEC
        ROR VEL_Y_INT
        ROR VEL_Y_FRAC
CHECK_DEAD_Y
        ; Micro-bounce cutoff: si rebond < 1 pixel, stopper
        LDA VEL_Y_INT
        CMP #$FF
        BNE Y_FLOOR_OK
        LDA #0
        STA VEL_Y_INT
        STA VEL_Y_FRAC
Y_FLOOR_OK

        ; === COLLISION MUR GAUCHE (X underflow → >= $80) ===
        LDA POS_X_INT
        CMP #$80
        BCC X_LEFT_OK

        LDA #0
        STA POS_X_INT
        STA POS_X_FRAC
        LDA VEL_X_INT
        BEQ NO_LW_SND
        JSR PLAY_WALL_SND
NO_LW_SND
        JSR BOUNCE_VEL_X
X_LEFT_OK

        ; === COLLISION MUR DROIT (X > WALL_R) ===
        LDA POS_X_INT
        CMP #WALL_R+1
        BCC PHYS_DONE

        LDA #WALL_R
        STA POS_X_INT
        LDA #0
        STA POS_X_FRAC
        LDA VEL_X_INT
        BEQ NO_RW_SND
        JSR PLAY_WALL_SND
NO_RW_SND
        JSR BOUNCE_VEL_X

PHYS_DONE
        ; === FRICTION AU SOL (rolling, toutes les 3 frames) ===
        LDA POS_Y_INT
        CMP #FLOOR_Y
        BCC NO_FRICTION     ; Pas au sol
        LDA VEL_X_INT
        ORA VEL_X_FRAC
        BEQ NO_FRICTION     ; Deja immobile
        INC FRIC_CTR
        LDA FRIC_CTR
        CMP #3
        BCC NO_FRICTION     ; Pas encore temps
        LDA #0
        STA FRIC_CTR
        ; ASR signe: VEL_X >>= 1
        LDA VEL_X_INT
        BMI FRIC_NEG
        CLC
        ROR VEL_X_INT
        ROR VEL_X_FRAC
        JMP NO_FRICTION
FRIC_NEG
        SEC
        ROR VEL_X_INT
        ROR VEL_X_FRAC
NO_FRICTION
        RTS

; --- Sous-routine : inverser et amortir VEL_X ---
BOUNCE_VEL_X
        SEC
        LDA #0
        SBC VEL_X_FRAC
        STA VEL_X_FRAC
        LDA #0
        SBC VEL_X_INT
        STA VEL_X_INT
        ; Amortir >>1 (signé)
        LDA VEL_X_INT
        BMI DAMP_BX_NEG
        CLC
        ROR VEL_X_INT
        ROR VEL_X_FRAC
        RTS
DAMP_BX_NEG
        SEC
        ROR VEL_X_INT
        ROR VEL_X_FRAC
        RTS

UPDATE_ANIM
        ; Rotation proportionnelle à la vitesse de la balle
        ; speed = |VEL_Y_INT| + |VEL_X_INT| (approximation)
        LDA VEL_Y_INT
        BPL VY_POS
        EOR #$FF
        CLC
        ADC #1
VY_POS  STA TEMP
        LDA VEL_X_INT
        BPL VX_POS
        EOR #$FF
        CLC
        ADC #1
VX_POS  CLC
        ADC TEMP            ; A = |VEL_Y| + |VEL_X|
        ; Si vitesse = 0, pas de rotation (physique realiste)
        BNE SPEED_OK
        RTS                 ; Balle immobile = pas de rotation
SPEED_OK
        ; Multiplier par 32 pour rotation rapide
        ASL
        ASL
        ASL
        ASL
        ASL
        ; Ajouter à l'accumulateur fractionnaire
        CLC
        ADC ANIM_ACC
        STA ANIM_ACC
        BCC NO_ADV_FRAME    ; Pas de carry = on n'avance pas
        INC FRAME_IDX
        LDA FRAME_IDX
        AND #$07            ; Modulo 8 (8 frames)
        STA FRAME_IDX
NO_ADV_FRAME
        RTS

PLAY_SOUND
        LDX #$08            ; Durée du son (réduit pour fluidité)
S_LOOP1 LDA SPEAKER
        LDY #$40            ; Hauteur (Pitch)
S_LOOP2 DEY
        BNE S_LOOP2
        DEX
        BNE S_LOOP1
        RTS

PLAY_WALL_SND
        LDX #$04            ; Durée courte (réduit)
WS_LP1  LDA SPEAKER
        LDY #$20            ; Pitch aigu (mur)
WS_LP2  DEY
        BNE WS_LP2
        DEX
        BNE WS_LP1
        RTS

WAIT_FRAME
        ; Boucle d'attente (calibrée pour ~25 fps)
        LDX #$16            ; Ajusté pour mouvement fluide
WAIT_L1 LDY #$FF
WAIT_L2 DEY
        BNE WAIT_L2
        DEX
        BNE WAIT_L1
        RTS

; --- Nouvelles dimensions du sprite ---
SPR_WIDTH  = 8              ; 8 octets de large (56 pixels)
SPR_HEIGHT = 50             ; 50 lignes de haut
SPRITE_SIZE = SPR_WIDTH * SPR_HEIGHT

; -------------------------------------------------------------
; DRAW_BALL
; Dessine un sprite 8 octets de large x 50 lignes de haut
; Utilise une copie directe, la page est effacee chaque frame
; -------------------------------------------------------------
DRAW_BALL
        ; Calculer l'adresse du sprite source
        LDA #<SPRITE_DATA
        STA SPR_L
        LDA #>SPRITE_DATA
        STA SPR_H
        
        ; Ajouter offset frame
        LDA FRAME_IDX
        BEQ SETUP_DRAW      ; Si frame 0, pas d'offset
        LDX FRAME_IDX
ADD_FRAME_OFFSET
        CLC
        LDA SPR_L
        ADC #<SPRITE_SIZE
        STA SPR_L
        LDA SPR_H
        ADC #>SPRITE_SIZE
        STA SPR_H
        DEX
        BNE ADD_FRAME_OFFSET

SETUP_DRAW
        LDA POS_Y_INT
        STA TEMP            ; Compteur ligne écran (Y courant)
        LDX #0              ; Compteur ligne sprite

DRAW_LINE_LOOP
        ; Récupérer l'adresse écran pour la ligne Y (TEMP)
        LDY TEMP
        LDA TBL_LO,Y        ; Calculer l'adresse de base + START_X
        CLC
        ADC START_X
        STA PTR_L
        LDA TBL_HI,Y        ; Gérer la retenue pour le High Byte
        ADC PAGE_OFFS
        STA PTR_H

        LDY #0              ; Index 0 à SPR_WIDTH-1
BYTE_LOOP
        LDA (SPR_L),Y       ; Lire octet sprite
        BEQ SKIP_BYTE       ; Si 0, on ne dessine rien (transparence)

        STA (PTR_L),Y       ; Ecrire
SKIP_BYTE
        INY
        CPY #SPR_WIDTH
        BNE BYTE_LOOP

        ; Avancer pointeur sprite
        CLC
        LDA SPR_L
        ADC #SPR_WIDTH
        STA SPR_L
        BCC NEXT_LINE
        INC SPR_H
NEXT_LINE

        ; Ligne suivante
        INC TEMP            ; Y ecran ++
        INX                 ; Ligne sprite ++
        CPX #SPR_HEIGHT     ; Hauteur sprite
        BNE DRAW_LINE_LOOP
        RTS

; =============================================================
; LOOKUP TABLES GENERATOR
; Génère les adresses HGR pour les lignes 0-191
; Stocké en $6300 (LO) et $6400 (HI)
; =============================================================
TBL_LO  = $7400
TBL_HI  = $7500

GEN_Y_TABLES
        LDX #0
GEN_LOOP
        TXA
        AND #$07    ; b = Y % 8
        ASL
        ASL
        CLC                  ; CRITICAL: prevent carry leak from prev iteration
        ADC #$20    ; $20 + b*4
        STA TBL_HI,X
        
        TXA
        LSR
        LSR
        LSR
        AND #$07    ; j = (Y/8) % 8
        LSR         ; A = j/2, Carry = j%2 (for $80 test)
        STA TEMP2
        LDA #0
        BCC NO_80
        LDA #$80
NO_80   STA TBL_LO,X
        CLC                  ; CRITICAL: clear carry from b%2
        LDA TBL_HI,X
        ADC TEMP2
        STA TBL_HI,X
        
        TXA
        ASL
        ROL
        ROL
        AND #$03    ; i = Y/64
        TAY
        BEQ NEXT_L
I_L     CLC                  ; CRITICAL: clear carry from i computation
        LDA TBL_LO,X
        ADC #$28
        STA TBL_LO,X
        BCC I_H
        INC TBL_HI,X
I_H     DEY
        BNE I_L
NEXT_L
        INX
        CPX #192
        BEQ GEN_DONE
        JMP GEN_LOOP
GEN_DONE
        RTS

; =============================================================
; DOUBLE BUFFER HELPERS
; =============================================================
SET_PAGE_OFFS
        LDA DRAW_PAGE
        BEQ PAGE1_OFFS
        LDA #$20
        STA PAGE_OFFS
        RTS
PAGE1_OFFS
        LDA #$00
        STA PAGE_OFFS
        RTS

CLEAR_HGR_PAGE
        LDA DRAW_PAGE
        BEQ CLEAR_P1
        LDX #$40
        LDA #$60
        BNE CLEAR_SETUP
CLEAR_P1
        LDX #$20
        LDA #$40
CLEAR_SETUP
        STA TEMP2           ; Fin de page (HI)
        STX PTR_H
        LDY #$00
        STY PTR_L
CLEAR_LOOP
        LDA #$00
        STA (PTR_L),Y
        INY
        BNE CLEAR_LOOP
        INC PTR_H
        LDX PTR_H
        CPX TEMP2
        BNE CLEAR_LOOP
        RTS


FLIP_DISPLAY
        LDA DRAW_PAGE
        STA DISPLAY_PAGE
        BEQ SHOW_P1
        BIT TXTPAGE2
        RTS
SHOW_P1
        BIT TXTPAGE1
        RTS

; --- Effacement local de la balle (remplace clear page entière) ---
ERASE_BALL
        LDA DRAW_PAGE
        BEQ ER_P0
        LDA PREV_Y_1
        STA TEMP
        LDA PREV_X_1
        JMP ER_DO
ER_P0   LDA PREV_Y_0
        STA TEMP
        LDA PREV_X_0
ER_DO   STA START_X
        LDX #0              ; Compteur lignes
ER_LINE LDY TEMP
        LDA TBL_LO,Y
        CLC
        ADC START_X
        STA PTR_L
        LDA TBL_HI,Y
        ADC PAGE_OFFS
        STA PTR_H
        LDY #0
        LDA #$00
ER_BYTE STA (PTR_L),Y
        INY
        CPY #SPR_WIDTH
        BNE ER_BYTE
        INC TEMP
        INX
        CPX #SPR_HEIGHT
        BNE ER_LINE
        RTS

; --- Sauvegarder position pour effacement futur ---
SAVE_POS
        LDA DRAW_PAGE
        BEQ SV_P0
        LDA POS_Y_INT
        STA PREV_Y_1
        LDA POS_X_INT
        STA PREV_X_1
        RTS
SV_P0   LDA POS_Y_INT
        STA PREV_Y_0
        LDA POS_X_INT
        STA PREV_X_0
        RTS

; =============================================================
; SPRITE DATA - Tennis ball with 3D seam rotation
; 8 bytes wide x 50 lines, 8 frames (every 22.5 deg over 180)
; Ball: RX=26, RY=24 (round on 280x192 @ 4:3)
; Solid white body + dark seam line, border always solid (2.5px)
; bit7=0 everywhere - no color shift with position
; =============================================================
SPRITE_DATA
; Frame 0 (rotation 0.0deg)
        .byte $00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$7C,$1F,$00,$00,$00
        .byte $00,$00,$60,$7F,$7F,$03,$00,$00
        .byte $00,$00,$7C,$7F,$7F,$1F,$00,$00
        .byte $00,$00,$7F,$7F,$7F,$7F,$00,$00
        .byte $00,$40,$7F,$7F,$7F,$7F,$01,$00
        .byte $00,$70,$7F,$7F,$7F,$7F,$07,$00
        .byte $00,$78,$7F,$7F,$7F,$3F,$0F,$00
        .byte $00,$7C,$7F,$7F,$7F,$7F,$1E,$00
        .byte $00,$7E,$7F,$7F,$7F,$7F,$3D,$00
        .byte $00,$7F,$7F,$7F,$7F,$7F,$7B,$00
        .byte $00,$7F,$7F,$7F,$7F,$7F,$77,$00
        .byte $40,$7F,$7F,$7F,$7F,$7F,$7F,$01
        .byte $60,$7F,$7F,$7F,$7F,$7F,$7F,$03
        .byte $60,$7F,$7F,$7F,$7F,$7F,$7F,$03
        .byte $70,$7F,$7F,$7F,$7F,$7F,$7F,$07
        .byte $70,$7F,$7F,$7F,$7F,$7F,$7F,$07
        .byte $78,$7F,$7F,$7F,$7F,$7F,$7F,$0F
        .byte $78,$7F,$7F,$7F,$7F,$7F,$7F,$0F
        .byte $78,$7F,$7F,$7F,$7F,$7F,$7F,$0F
        .byte $7C,$7F,$7F,$7F,$7F,$7F,$7F,$1F
        .byte $7C,$7F,$7F,$7F,$7F,$7F,$7F,$1F
        .byte $7C,$7F,$7F,$7F,$7F,$7F,$7F,$1F
        .byte $7C,$7F,$7F,$7F,$7F,$7F,$7F,$1F
        .byte $7C,$7F,$7F,$7F,$7F,$7F,$7F,$1F
        .byte $7C,$7F,$7F,$7F,$7F,$7F,$7F,$1F
        .byte $7C,$7F,$7F,$7F,$7F,$7F,$7F,$1F
        .byte $7C,$7F,$7F,$7F,$7F,$7F,$7F,$1F
        .byte $7C,$7F,$7F,$7F,$7F,$7F,$7F,$1F
        .byte $7C,$7F,$7F,$7F,$7F,$7F,$7F,$1F
        .byte $78,$7F,$7F,$7F,$7F,$7F,$7F,$0F
        .byte $78,$7F,$7F,$7F,$7F,$7F,$7F,$0F
        .byte $78,$7F,$7F,$7F,$7F,$7F,$7F,$0F
        .byte $70,$7F,$7F,$7F,$7F,$7F,$7F,$07
        .byte $70,$7F,$7F,$7F,$7F,$7F,$7F,$07
        .byte $60,$7F,$7F,$7F,$7F,$7F,$7F,$03
        .byte $60,$7F,$7F,$7F,$7F,$7F,$7F,$03
        .byte $40,$7F,$7F,$7F,$7F,$7F,$7F,$01
        .byte $00,$77,$7F,$7F,$7F,$7F,$7F,$00
        .byte $00,$6F,$7F,$7F,$7F,$7F,$7F,$00
        .byte $00,$5E,$7F,$7F,$7F,$7F,$3F,$00
        .byte $00,$3C,$7F,$7F,$7F,$7F,$1F,$00
        .byte $00,$78,$7E,$7F,$7F,$7F,$0F,$00
        .byte $00,$70,$7F,$7F,$7F,$7F,$07,$00
        .byte $00,$40,$7F,$7F,$7F,$7F,$01,$00
        .byte $00,$00,$7F,$7F,$7F,$7F,$00,$00
        .byte $00,$00,$7C,$7F,$7F,$1F,$00,$00
        .byte $00,$00,$60,$7F,$7F,$03,$00,$00
        .byte $00,$00,$00,$7C,$1F,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00
; Frame 1 (rotation 22.5deg)
        .byte $00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$7C,$1F,$00,$00,$00
        .byte $00,$00,$60,$7F,$7F,$03,$00,$00
        .byte $00,$00,$7C,$7F,$78,$1F,$00,$00
        .byte $00,$00,$7F,$7F,$63,$7F,$00,$00
        .byte $00,$40,$7F,$7F,$0F,$7F,$01,$00
        .byte $00,$70,$7F,$7F,$3F,$7C,$07,$00
        .byte $00,$78,$7F,$7F,$7F,$78,$0F,$00
        .byte $00,$7C,$7F,$7F,$7F,$71,$1F,$00
        .byte $00,$7E,$7F,$7F,$7F,$63,$3F,$00
        .byte $00,$7F,$7F,$7F,$7F,$47,$7F,$00
        .byte $00,$7F,$7F,$7F,$7F,$0F,$7E,$00
        .byte $40,$7F,$7F,$7F,$7F,$3F,$7C,$01
        .byte $60,$7F,$7F,$7F,$7F,$7F,$78,$03
        .byte $60,$7F,$7F,$7F,$7F,$7F,$71,$03
        .byte $70,$7F,$7F,$7F,$7F,$7F,$63,$07
        .byte $70,$7F,$7F,$7F,$7F,$7F,$07,$07
        .byte $78,$7F,$7F,$7F,$7F,$7F,$0F,$0E
        .byte $78,$7F,$7F,$7F,$7F,$7F,$3F,$0E
        .byte $78,$7F,$7F,$7F,$7F,$7F,$7F,$0C
        .byte $7C,$7F,$7F,$7F,$7F,$7F,$7F,$1D
        .byte $7C,$7F,$7F,$7F,$7F,$7F,$7F,$1F
        .byte $7C,$7F,$7F,$7F,$7F,$7F,$7F,$1F
        .byte $7C,$7F,$7F,$7F,$7F,$7F,$7F,$1F
        .byte $7C,$7F,$7F,$7F,$7F,$7F,$7F,$1F
        .byte $7C,$7F,$7F,$7F,$7F,$7F,$7F,$1F
        .byte $7C,$7F,$7F,$7F,$7F,$7F,$7F,$1F
        .byte $7C,$7F,$7F,$7F,$7F,$7F,$7F,$1F
        .byte $7C,$7F,$7F,$7F,$7F,$7F,$7F,$1F
        .byte $7C,$7F,$7F,$7F,$7F,$7F,$7F,$1F
        .byte $78,$7F,$7F,$7F,$7F,$7F,$7F,$0F
        .byte $78,$7F,$7F,$7F,$7F,$7F,$7F,$0F
        .byte $78,$7F,$7F,$7F,$7F,$7F,$7F,$0F
        .byte $70,$7F,$7F,$7F,$7F,$7F,$7F,$07
        .byte $70,$7F,$7F,$7F,$7F,$7F,$7F,$07
        .byte $60,$7F,$7F,$7F,$7F,$7F,$7F,$03
        .byte $60,$7F,$7F,$7F,$7F,$7F,$7F,$03
        .byte $40,$7F,$7F,$7F,$7F,$7F,$7F,$01
        .byte $00,$7F,$7F,$7F,$7F,$7F,$7F,$00
        .byte $00,$7F,$7F,$7F,$7F,$7F,$7F,$00
        .byte $00,$7E,$7F,$7F,$7F,$7F,$3F,$00
        .byte $00,$7C,$7F,$7F,$7F,$7F,$1F,$00
        .byte $00,$78,$7F,$7F,$7F,$7F,$0F,$00
        .byte $00,$70,$7F,$7F,$7F,$7F,$07,$00
        .byte $00,$40,$7F,$7F,$7F,$7F,$01,$00
        .byte $00,$00,$7F,$7F,$7F,$7F,$00,$00
        .byte $00,$00,$7C,$7F,$7F,$1F,$00,$00
        .byte $00,$00,$60,$7F,$7F,$03,$00,$00
        .byte $00,$00,$00,$7C,$1F,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00
; Frame 2 (rotation 45.0deg)
        .byte $00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$7C,$1F,$00,$00,$00
        .byte $00,$00,$60,$7F,$7F,$03,$00,$00
        .byte $00,$00,$7C,$7F,$7F,$1F,$00,$00
        .byte $00,$00,$3F,$7E,$7F,$7F,$00,$00
        .byte $00,$40,$0F,$70,$7F,$7F,$01,$00
        .byte $00,$70,$7F,$41,$7F,$7F,$07,$00
        .byte $00,$78,$7F,$0F,$7E,$7F,$0F,$00
        .byte $00,$7C,$7F,$3F,$78,$7F,$1F,$00
        .byte $00,$7E,$7F,$7F,$70,$7F,$3F,$00
        .byte $00,$7F,$7F,$7F,$43,$7F,$7F,$00
        .byte $00,$7F,$7F,$7F,$07,$7F,$7F,$00
        .byte $40,$7F,$7F,$7F,$1F,$7E,$7F,$01
        .byte $60,$7F,$7F,$7F,$3F,$7C,$7F,$03
        .byte $60,$7F,$7F,$7F,$7F,$78,$7F,$03
        .byte $70,$7F,$7F,$7F,$7F,$61,$7F,$07
        .byte $70,$7F,$7F,$7F,$7F,$43,$7F,$07
        .byte $78,$7F,$7F,$7F,$7F,$07,$7F,$0F
        .byte $78,$7F,$7F,$7F,$7F,$0F,$7E,$0F
        .byte $78,$7F,$7F,$7F,$7F,$1F,$7C,$0F
        .byte $7C,$7F,$7F,$7F,$7F,$3F,$70,$1F
        .byte $7C,$7F,$7F,$7F,$7F,$7F,$40,$1F
        .byte $7C,$7F,$7F,$7F,$7F,$7F,$03,$1E
        .byte $7C,$7F,$7F,$7F,$7F,$7F,$07,$1C
        .byte $7C,$7F,$7F,$7F,$7F,$7F,$3F,$1C
        .byte $7C,$7F,$7F,$7F,$7F,$7F,$7F,$1F
        .byte $7C,$7F,$7F,$7F,$7F,$7F,$7F,$1F
        .byte $7C,$7F,$7F,$7F,$7F,$7F,$7F,$1F
        .byte $7C,$7F,$7F,$7F,$7F,$7F,$7F,$1F
        .byte $7C,$7F,$7F,$7F,$7F,$7F,$7F,$1F
        .byte $78,$7F,$7F,$7F,$7F,$7F,$7F,$0F
        .byte $78,$7F,$7F,$7F,$7F,$7F,$7F,$0F
        .byte $78,$7F,$7F,$7F,$7F,$7F,$7F,$0F
        .byte $70,$7F,$7F,$7F,$7F,$7F,$7F,$07
        .byte $70,$7F,$7F,$7F,$7F,$7F,$7F,$07
        .byte $60,$7F,$7F,$7F,$7F,$7F,$7F,$03
        .byte $60,$7F,$7F,$7F,$7F,$7F,$7F,$03
        .byte $40,$7F,$7F,$7F,$7F,$7F,$7F,$01
        .byte $00,$7F,$7F,$7F,$7F,$7F,$7F,$00
        .byte $00,$7F,$7F,$7F,$7F,$7F,$7F,$00
        .byte $00,$7E,$7F,$7F,$7F,$7F,$3F,$00
        .byte $00,$7C,$7F,$7F,$7F,$7F,$1F,$00
        .byte $00,$78,$7F,$7F,$7F,$7F,$0F,$00
        .byte $00,$70,$7F,$7F,$7F,$7F,$07,$00
        .byte $00,$40,$7F,$7F,$7F,$7F,$01,$00
        .byte $00,$00,$7F,$7F,$7F,$7F,$00,$00
        .byte $00,$00,$7C,$7F,$7F,$1F,$00,$00
        .byte $00,$00,$60,$7F,$7F,$03,$00,$00
        .byte $00,$00,$00,$7C,$1F,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00
; Frame 3 (rotation 67.5deg)
        .byte $00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$7C,$1F,$00,$00,$00
        .byte $00,$00,$60,$7F,$7F,$03,$00,$00
        .byte $00,$00,$7C,$7F,$7F,$1F,$00,$00
        .byte $00,$00,$7F,$7F,$7F,$7F,$00,$00
        .byte $00,$40,$7F,$7F,$7F,$7F,$01,$00
        .byte $00,$70,$7F,$7F,$7F,$7F,$07,$00
        .byte $00,$78,$7F,$7F,$7F,$7F,$0F,$00
        .byte $00,$3C,$70,$7F,$7F,$7F,$1F,$00
        .byte $00,$1E,$40,$7F,$7F,$7F,$3F,$00
        .byte $00,$4F,$01,$7E,$7F,$7F,$7F,$00
        .byte $00,$7F,$0F,$78,$7F,$7F,$7F,$00
        .byte $40,$7F,$7F,$70,$7F,$7F,$7F,$01
        .byte $60,$7F,$7F,$41,$7F,$7F,$7F,$03
        .byte $60,$7F,$7F,$07,$7F,$7F,$7F,$03
        .byte $70,$7F,$7F,$0F,$7C,$7F,$7F,$07
        .byte $70,$7F,$7F,$3F,$78,$7F,$7F,$07
        .byte $78,$7F,$7F,$7F,$70,$7F,$7F,$0F
        .byte $78,$7F,$7F,$7F,$61,$7F,$7F,$0F
        .byte $78,$7F,$7F,$7F,$07,$7F,$7F,$0F
        .byte $7C,$7F,$7F,$7F,$0F,$7E,$7F,$1F
        .byte $7C,$7F,$7F,$7F,$1F,$7C,$7F,$1F
        .byte $7C,$7F,$7F,$7F,$3F,$78,$7F,$1F
        .byte $7C,$7F,$7F,$7F,$7F,$70,$7F,$1F
        .byte $7C,$7F,$7F,$7F,$7F,$41,$7F,$1F
        .byte $7C,$7F,$7F,$7F,$7F,$03,$7F,$1F
        .byte $7C,$7F,$7F,$7F,$7F,$0F,$7C,$1F
        .byte $7C,$7F,$7F,$7F,$7F,$1F,$40,$1C
        .byte $7C,$7F,$7F,$7F,$7F,$3F,$00,$1C
        .byte $7C,$7F,$7F,$7F,$7F,$7F,$01,$1C
        .byte $78,$7F,$7F,$7F,$7F,$7F,$47,$0F
        .byte $78,$7F,$7F,$7F,$7F,$7F,$7F,$0F
        .byte $78,$7F,$7F,$7F,$7F,$7F,$7F,$0F
        .byte $70,$7F,$7F,$7F,$7F,$7F,$7F,$07
        .byte $70,$7F,$7F,$7F,$7F,$7F,$7F,$07
        .byte $60,$7F,$7F,$7F,$7F,$7F,$7F,$03
        .byte $60,$7F,$7F,$7F,$7F,$7F,$7F,$03
        .byte $40,$7F,$7F,$7F,$7F,$7F,$7F,$01
        .byte $00,$7F,$7F,$7F,$7F,$7F,$7F,$00
        .byte $00,$7F,$7F,$7F,$7F,$7F,$7F,$00
        .byte $00,$7E,$7F,$7F,$7F,$7F,$3F,$00
        .byte $00,$7C,$7F,$7F,$7F,$7F,$1F,$00
        .byte $00,$78,$7F,$7F,$7F,$7F,$0F,$00
        .byte $00,$70,$7F,$7F,$7F,$7F,$07,$00
        .byte $00,$40,$7F,$7F,$7F,$7F,$01,$00
        .byte $00,$00,$7F,$7F,$7F,$7F,$00,$00
        .byte $00,$00,$7C,$7F,$7F,$1F,$00,$00
        .byte $00,$00,$60,$7F,$7F,$03,$00,$00
        .byte $00,$00,$00,$7C,$1F,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00
; Frame 4 (rotation 90.0deg)
        .byte $00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$7C,$1F,$00,$00,$00
        .byte $00,$00,$60,$7F,$7F,$03,$00,$00
        .byte $00,$00,$7C,$7F,$7F,$1F,$00,$00
        .byte $00,$00,$7F,$7F,$7F,$7F,$00,$00
        .byte $00,$40,$7F,$7F,$7F,$7F,$01,$00
        .byte $00,$70,$7F,$7F,$7F,$7F,$07,$00
        .byte $00,$78,$7F,$7F,$7F,$7F,$0F,$00
        .byte $00,$7C,$7F,$7F,$7F,$7F,$1F,$00
        .byte $00,$7E,$7F,$7F,$7F,$7F,$3F,$00
        .byte $00,$7F,$7F,$7F,$7F,$7F,$7F,$00
        .byte $00,$7F,$7F,$7F,$7F,$7F,$7F,$00
        .byte $40,$7F,$7F,$7F,$7F,$7F,$7F,$01
        .byte $60,$07,$7F,$7F,$7F,$7F,$7F,$03
        .byte $60,$01,$7C,$7F,$7F,$7F,$7F,$03
        .byte $70,$00,$70,$7F,$7F,$7F,$7F,$07
        .byte $30,$3C,$60,$7F,$7F,$7F,$7F,$07
        .byte $38,$7F,$01,$7F,$7F,$7F,$7F,$0F
        .byte $78,$7F,$07,$7E,$7F,$7F,$7F,$0F
        .byte $78,$7F,$1F,$7C,$7F,$7F,$7F,$0F
        .byte $7C,$7F,$3F,$70,$7F,$7F,$7F,$1F
        .byte $7C,$7F,$7F,$60,$7F,$7F,$7F,$1F
        .byte $7C,$7F,$7F,$43,$7F,$7F,$7F,$1F
        .byte $7C,$7F,$7F,$07,$7F,$7F,$7F,$1F
        .byte $7C,$7F,$7F,$0F,$7E,$7F,$7F,$1F
        .byte $7C,$7F,$7F,$3F,$78,$7F,$7F,$1F
        .byte $7C,$7F,$7F,$7F,$70,$7F,$7F,$1F
        .byte $7C,$7F,$7F,$7F,$61,$7F,$7F,$1F
        .byte $7C,$7F,$7F,$7F,$03,$7F,$7F,$1F
        .byte $7C,$7F,$7F,$7F,$07,$7E,$7F,$1F
        .byte $78,$7F,$7F,$7F,$1F,$7C,$7F,$0F
        .byte $78,$7F,$7F,$7F,$3F,$70,$7F,$0F
        .byte $78,$7F,$7F,$7F,$7F,$40,$7F,$0E
        .byte $70,$7F,$7F,$7F,$7F,$03,$1E,$06
        .byte $70,$7F,$7F,$7F,$7F,$07,$00,$07
        .byte $60,$7F,$7F,$7F,$7F,$1F,$40,$03
        .byte $60,$7F,$7F,$7F,$7F,$7F,$70,$03
        .byte $40,$7F,$7F,$7F,$7F,$7F,$7F,$01
        .byte $00,$7F,$7F,$7F,$7F,$7F,$7F,$00
        .byte $00,$7F,$7F,$7F,$7F,$7F,$7F,$00
        .byte $00,$7E,$7F,$7F,$7F,$7F,$3F,$00
        .byte $00,$7C,$7F,$7F,$7F,$7F,$1F,$00
        .byte $00,$78,$7F,$7F,$7F,$7F,$0F,$00
        .byte $00,$70,$7F,$7F,$7F,$7F,$07,$00
        .byte $00,$40,$7F,$7F,$7F,$7F,$01,$00
        .byte $00,$00,$7F,$7F,$7F,$7F,$00,$00
        .byte $00,$00,$7C,$7F,$7F,$1F,$00,$00
        .byte $00,$00,$60,$7F,$7F,$03,$00,$00
        .byte $00,$00,$00,$7C,$1F,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00
; Frame 5 (rotation 112.5deg)
        .byte $00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$7C,$1F,$00,$00,$00
        .byte $00,$00,$60,$7F,$7F,$03,$00,$00
        .byte $00,$00,$7C,$7F,$7F,$1F,$00,$00
        .byte $00,$00,$7F,$7F,$7F,$7F,$00,$00
        .byte $00,$40,$7F,$7F,$7F,$7F,$01,$00
        .byte $00,$70,$7F,$7F,$7F,$7F,$07,$00
        .byte $00,$78,$7F,$7F,$7F,$7F,$0F,$00
        .byte $00,$7C,$7F,$7F,$7F,$7F,$1F,$00
        .byte $00,$7E,$7F,$7F,$7F,$7F,$3F,$00
        .byte $00,$7F,$7F,$7F,$7F,$7F,$7F,$00
        .byte $00,$7F,$7F,$7F,$7F,$7F,$7F,$00
        .byte $40,$7F,$7F,$7F,$7F,$7F,$7F,$01
        .byte $60,$7F,$7F,$7F,$7F,$7F,$7F,$03
        .byte $60,$7F,$7F,$7F,$7F,$7F,$7F,$03
        .byte $70,$7F,$7F,$7F,$7F,$7F,$7F,$07
        .byte $70,$7F,$7F,$7F,$7F,$7F,$7F,$07
        .byte $78,$7F,$7F,$7F,$7F,$7F,$7F,$0F
        .byte $78,$7F,$7F,$7F,$7F,$7F,$7F,$0F
        .byte $78,$71,$7F,$7F,$7F,$7F,$7F,$0F
        .byte $1C,$40,$7F,$7F,$7F,$7F,$7F,$1F
        .byte $1C,$00,$7E,$7F,$7F,$7F,$7F,$1F
        .byte $1C,$01,$7C,$7F,$7F,$7F,$7F,$1F
        .byte $7C,$1F,$78,$7F,$7F,$7F,$7F,$1F
        .byte $7C,$7F,$60,$7F,$7F,$7F,$7F,$1F
        .byte $7C,$7F,$41,$7F,$7F,$7F,$7F,$1F
        .byte $7C,$7F,$07,$7F,$7F,$7F,$7F,$1F
        .byte $7C,$7F,$0F,$7E,$7F,$7F,$7F,$1F
        .byte $7C,$7F,$1F,$7C,$7F,$7F,$7F,$1F
        .byte $7C,$7F,$3F,$78,$7F,$7F,$7F,$1F
        .byte $78,$7F,$7F,$70,$7F,$7F,$7F,$0F
        .byte $78,$7F,$7F,$43,$7F,$7F,$7F,$0F
        .byte $78,$7F,$7F,$07,$7F,$7F,$7F,$0F
        .byte $70,$7F,$7F,$0F,$7E,$7F,$7F,$07
        .byte $70,$7F,$7F,$1F,$78,$7F,$7F,$07
        .byte $60,$7F,$7F,$7F,$70,$7F,$7F,$03
        .byte $60,$7F,$7F,$7F,$41,$7F,$7F,$03
        .byte $40,$7F,$7F,$7F,$07,$7F,$7F,$01
        .byte $00,$7F,$7F,$7F,$0F,$78,$7F,$00
        .byte $00,$7F,$7F,$7F,$3F,$40,$79,$00
        .byte $00,$7E,$7F,$7F,$7F,$01,$3C,$00
        .byte $00,$7C,$7F,$7F,$7F,$07,$1E,$00
        .byte $00,$78,$7F,$7F,$7F,$7F,$0F,$00
        .byte $00,$70,$7F,$7F,$7F,$7F,$07,$00
        .byte $00,$40,$7F,$7F,$7F,$7F,$01,$00
        .byte $00,$00,$7F,$7F,$7F,$7F,$00,$00
        .byte $00,$00,$7C,$7F,$7F,$1F,$00,$00
        .byte $00,$00,$60,$7F,$7F,$03,$00,$00
        .byte $00,$00,$00,$7C,$1F,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00
; Frame 6 (rotation 135.0deg)
        .byte $00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$7C,$1F,$00,$00,$00
        .byte $00,$00,$60,$7F,$7F,$03,$00,$00
        .byte $00,$00,$7C,$7F,$7F,$1F,$00,$00
        .byte $00,$00,$7F,$7F,$7F,$7F,$00,$00
        .byte $00,$40,$7F,$7F,$7F,$7F,$01,$00
        .byte $00,$70,$7F,$7F,$7F,$7F,$07,$00
        .byte $00,$78,$7F,$7F,$7F,$7F,$0F,$00
        .byte $00,$7C,$7F,$7F,$7F,$7F,$1F,$00
        .byte $00,$7E,$7F,$7F,$7F,$7F,$3F,$00
        .byte $00,$7F,$7F,$7F,$7F,$7F,$7F,$00
        .byte $00,$7F,$7F,$7F,$7F,$7F,$7F,$00
        .byte $40,$7F,$7F,$7F,$7F,$7F,$7F,$01
        .byte $60,$7F,$7F,$7F,$7F,$7F,$7F,$03
        .byte $60,$7F,$7F,$7F,$7F,$7F,$7F,$03
        .byte $70,$7F,$7F,$7F,$7F,$7F,$7F,$07
        .byte $70,$7F,$7F,$7F,$7F,$7F,$7F,$07
        .byte $78,$7F,$7F,$7F,$7F,$7F,$7F,$0F
        .byte $78,$7F,$7F,$7F,$7F,$7F,$7F,$0F
        .byte $78,$7F,$7F,$7F,$7F,$7F,$7F,$0F
        .byte $7C,$7F,$7F,$7F,$7F,$7F,$7F,$1F
        .byte $7C,$7F,$7F,$7F,$7F,$7F,$7F,$1F
        .byte $7C,$7F,$7F,$7F,$7F,$7F,$7F,$1F
        .byte $7C,$7F,$7F,$7F,$7F,$7F,$7F,$1F
        .byte $7C,$7F,$7F,$7F,$7F,$7F,$7F,$1F
        .byte $1C,$7E,$7F,$7F,$7F,$7F,$7F,$1F
        .byte $1C,$70,$7F,$7F,$7F,$7F,$7F,$1F
        .byte $3C,$60,$7F,$7F,$7F,$7F,$7F,$1F
        .byte $7C,$01,$7F,$7F,$7F,$7F,$7F,$1F
        .byte $7C,$07,$7E,$7F,$7F,$7F,$7F,$1F
        .byte $78,$1F,$7C,$7F,$7F,$7F,$7F,$0F
        .byte $78,$3F,$78,$7F,$7F,$7F,$7F,$0F
        .byte $78,$7F,$70,$7F,$7F,$7F,$7F,$0F
        .byte $70,$7F,$61,$7F,$7F,$7F,$7F,$07
        .byte $70,$7F,$43,$7F,$7F,$7F,$7F,$07
        .byte $60,$7F,$0F,$7F,$7F,$7F,$7F,$03
        .byte $60,$7F,$1F,$7E,$7F,$7F,$7F,$03
        .byte $40,$7F,$3F,$7C,$7F,$7F,$7F,$01
        .byte $00,$7F,$7F,$70,$7F,$7F,$7F,$00
        .byte $00,$7F,$7F,$61,$7F,$7F,$7F,$00
        .byte $00,$7E,$7F,$07,$7F,$7F,$3F,$00
        .byte $00,$7C,$7F,$0F,$7E,$7F,$1F,$00
        .byte $00,$78,$7F,$3F,$78,$7F,$0F,$00
        .byte $00,$70,$7F,$7F,$41,$7F,$07,$00
        .byte $00,$40,$7F,$7F,$07,$78,$01,$00
        .byte $00,$00,$7F,$7F,$3F,$7E,$00,$00
        .byte $00,$00,$7C,$7F,$7F,$1F,$00,$00
        .byte $00,$00,$60,$7F,$7F,$03,$00,$00
        .byte $00,$00,$00,$7C,$1F,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00
; Frame 7 (rotation 157.5deg)
        .byte $00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$7C,$1F,$00,$00,$00
        .byte $00,$00,$60,$7F,$7F,$03,$00,$00
        .byte $00,$00,$7C,$7F,$7F,$1F,$00,$00
        .byte $00,$00,$7F,$7F,$7F,$7F,$00,$00
        .byte $00,$40,$7F,$7F,$7F,$7F,$01,$00
        .byte $00,$70,$7F,$7F,$7F,$7F,$07,$00
        .byte $00,$78,$7F,$7F,$7F,$7F,$0F,$00
        .byte $00,$7C,$7F,$7F,$7F,$7F,$1F,$00
        .byte $00,$7E,$7F,$7F,$7F,$7F,$3F,$00
        .byte $00,$7F,$7F,$7F,$7F,$7F,$7F,$00
        .byte $00,$7F,$7F,$7F,$7F,$7F,$7F,$00
        .byte $40,$7F,$7F,$7F,$7F,$7F,$7F,$01
        .byte $60,$7F,$7F,$7F,$7F,$7F,$7F,$03
        .byte $60,$7F,$7F,$7F,$7F,$7F,$7F,$03
        .byte $70,$7F,$7F,$7F,$7F,$7F,$7F,$07
        .byte $70,$7F,$7F,$7F,$7F,$7F,$7F,$07
        .byte $78,$7F,$7F,$7F,$7F,$7F,$7F,$0F
        .byte $78,$7F,$7F,$7F,$7F,$7F,$7F,$0F
        .byte $78,$7F,$7F,$7F,$7F,$7F,$7F,$0F
        .byte $7C,$7F,$7F,$7F,$7F,$7F,$7F,$1F
        .byte $7C,$7F,$7F,$7F,$7F,$7F,$7F,$1F
        .byte $7C,$7F,$7F,$7F,$7F,$7F,$7F,$1F
        .byte $7C,$7F,$7F,$7F,$7F,$7F,$7F,$1F
        .byte $7C,$7F,$7F,$7F,$7F,$7F,$7F,$1F
        .byte $7C,$7F,$7F,$7F,$7F,$7F,$7F,$1F
        .byte $7C,$7F,$7F,$7F,$7F,$7F,$7F,$1F
        .byte $7C,$7F,$7F,$7F,$7F,$7F,$7F,$1F
        .byte $7C,$7F,$7F,$7F,$7F,$7F,$7F,$1F
        .byte $5C,$7F,$7F,$7F,$7F,$7F,$7F,$1F
        .byte $18,$7F,$7F,$7F,$7F,$7F,$7F,$0F
        .byte $38,$7E,$7F,$7F,$7F,$7F,$7F,$0F
        .byte $38,$78,$7F,$7F,$7F,$7F,$7F,$0F
        .byte $70,$70,$7F,$7F,$7F,$7F,$7F,$07
        .byte $70,$63,$7F,$7F,$7F,$7F,$7F,$07
        .byte $60,$47,$7F,$7F,$7F,$7F,$7F,$03
        .byte $60,$0F,$7F,$7F,$7F,$7F,$7F,$03
        .byte $40,$1F,$7E,$7F,$7F,$7F,$7F,$01
        .byte $00,$3F,$78,$7F,$7F,$7F,$7F,$00
        .byte $00,$7F,$71,$7F,$7F,$7F,$7F,$00
        .byte $00,$7E,$63,$7F,$7F,$7F,$3F,$00
        .byte $00,$7C,$47,$7F,$7F,$7F,$1F,$00
        .byte $00,$78,$0F,$7F,$7F,$7F,$0F,$00
        .byte $00,$70,$1F,$7E,$7F,$7F,$07,$00
        .byte $00,$40,$7F,$78,$7F,$7F,$01,$00
        .byte $00,$00,$7F,$63,$7F,$7F,$00,$00
        .byte $00,$00,$7C,$0F,$7F,$1F,$00,$00
        .byte $00,$00,$60,$7F,$7F,$03,$00,$00
        .byte $00,$00,$00,$7C,$1F,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00
