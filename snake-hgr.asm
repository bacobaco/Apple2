; ==========================================
; SNAKE HGR pour Apple II+ (Haute Résolution)
; Assembleur: 64tass
; Adresse: $4000
; ==========================================
        * = $4000

; --- Page Zéro ---
ZP_SCR_LO   = $F8
ZP_SCR_HI   = $F9
ZP_SHAPE_LO = $FA
ZP_SHAPE_HI = $FB

; --- Soft Switches Apple II ---
GFX_ON    = $C050
TXT_ON    = $C051
MIXED_ON  = $C053
PAGE1_ON  = $C054
HIRES_ON  = $C057
KBD       = $C000
KBD_STRB  = $C010
SPEAKER   = $C030

; --- Variables ---
VAR_BASE = $4800
DIR_X    = VAR_BASE + $00
DIR_Y    = VAR_BASE + $01
FOOD_X   = VAR_BASE + $02
FOOD_Y   = VAR_BASE + $03
SCORE    = VAR_BASE + $04  ; 3 octets
HI_SCORE = VAR_BASE + $07  ; 3 octets
SEED     = VAR_BASE + $0A
NEW_HX   = VAR_BASE + $0B
NEW_HY   = VAR_BASE + $0C
EATEN    = VAR_BASE + $0D
TEMP     = VAR_BASE + $0E
TEMP_Y   = VAR_BASE + $0F
LEN      = VAR_BASE + $10
Q_HEAD   = VAR_BASE + $11
Q_TAIL   = VAR_BASE + $12
KEY_Q    = VAR_BASE + $13  ; 4 octets
DLY_X    = VAR_BASE + $17
DLY_Y    = VAR_BASE + $18
CUR_SPEED= VAR_BASE + $19
FRUIT_VAL= VAR_BASE + $1A  ; 2 octets
FOOD_TYPE= VAR_BASE + $1C  ; Index de la forme du fruit (3, 4 ou 5)
WIPE_C   = VAR_BASE + $1D
WIPE_R   = VAR_BASE + $1E
DROP_C   = VAR_BASE + $1F
DROP_CH  = VAR_BASE + $20
TEMP_C   = VAR_BASE + $21
TEMP_R   = VAR_BASE + $22
SNAKE_X  = VAR_BASE + $30    ; 256 octets max
SNAKE_Y  = VAR_BASE + $130   ; 256 octets max

SCREEN_BASE = $0400
HGR_BASE    = $2000

; ==========================================
; INITIALISATION
; ==========================================
RESET_ALL:
        LDA #0
        STA HI_SCORE
        STA HI_SCORE+1
        STA HI_SCORE+2
INIT:
        ; Active le mode Graphique HIRES Mixte
        STA GFX_ON
        STA MIXED_ON
        STA PAGE1_ON
        STA HIRES_ON

        ; Efface la mémoire texte $0400-$07FF
        LDA #$A0
        LDY #$00
CLR_TXT:
        STA $0400,Y
        STA $0500,Y
        STA $0600,Y
        STA $0700,Y
        INY
        BNE CLR_TXT

        ; Efface la mémoire HGR Page 1 ($2000-$3FFF)
        LDA #$00
        LDY #$00
        LDX #>HGR_BASE
        STX ZP_SCR_HI
        STY ZP_SCR_LO
CLR_HGR:
        STA (ZP_SCR_LO),Y
        INY
        BNE CLR_HGR
        INC ZP_SCR_HI
        LDX ZP_SCR_HI
        CPX #$40
        BNE CLR_HGR

        ; Position initiale (20,10), longueur 3
        LDA #20
        STA SNAKE_X
        STA SNAKE_X+1
        STA SNAKE_X+2
        LDA #10
        STA SNAKE_Y
        STA SNAKE_Y+1
        STA SNAKE_Y+2
        LDA #3
        STA LEN

        ; Direction droite
        LDA #1
        STA DIR_X
        LDA #0
        STA DIR_Y

        LDA #0
        STA SCORE
        STA SCORE+1
        STA SCORE+2
        STA Q_HEAD
        STA Q_TAIL
        LDA #$5A
        STA SEED
        LDA #$B0            ; Vitesse de départ
        STA CUR_SPEED
        LDA #$30            ; 30 pts par fruit initialement
        STA FRUIT_VAL
        LDA #0
        STA FRUIT_VAL+1

        JSR PLACE_FOOD
        JSR UPDATE_SCORE

; ==========================================
; BOUCLE PRINCIPALE
; ==========================================
MAIN:
        JSR CHECK_KEY
        JSR CALC_HEAD
        JSR CHECK_COLLIDE
        JSR MOVE_PENALTY
        JSR CHECK_FOOD
        JSR UPDATE_SCR
        JSR DELAY
        JMP MAIN

; ==========================================
; CLAVIER
; ==========================================
CHECK_KEY:
        LDX Q_TAIL
        CPX Q_HEAD
        BEQ CHECK_KEY_DONE
        INX
        TXA
        AND #$03
        STA Q_TAIL
        TAX
        LDA KEY_Q,X

        CMP #$8B            ; Haut
        BNE CHK_LEFT
        LDA DIR_Y
        CMP #1
        BEQ CHECK_KEY
        LDA #0
        STA DIR_X
        LDA #$FF
        STA DIR_Y
        RTS

CHK_LEFT: CMP #$88          ; Gauche
        BNE CHK_DOWN
        LDA DIR_X
        CMP #1
        BEQ CHECK_KEY
        LDA #$FF
        STA DIR_X
        LDA #0
        STA DIR_Y
        RTS

CHK_DOWN: CMP #$8A          ; Bas
        BNE CHK_RIGHT
        LDA DIR_Y
        CMP #$FF
        BEQ CHECK_KEY
        LDA #0
        STA DIR_X
        LDA #1
        STA DIR_Y
        RTS

CHK_RIGHT: CMP #$95         ; Droite
        BNE CHECK_KEY
        LDA DIR_X
        CMP #$FF
        BEQ CHECK_KEY
        LDA #1
        STA DIR_X
        LDA #0
        STA DIR_Y
CHECK_KEY_DONE:
        RTS

; ==========================================
; CALCUL TÊTE & COLLISIONS (HGR = 40x20)
; ==========================================
CALC_HEAD:
        LDA SNAKE_X
        CLC
        ADC DIR_X
        STA NEW_HX
        LDA SNAKE_Y
        CLC
        ADC DIR_Y
        STA NEW_HY
        RTS

CHECK_COLLIDE:
        ; X: 0-39
        LDA NEW_HX
        BPL CHK_X_MAX
        LDA #39
        STA NEW_HX
        BNE CHK_Y_START
CHK_X_MAX:
        CMP #40
        BCC CHK_Y_START
        LDA #0
        STA NEW_HX
CHK_Y_START:
        ; Y: 0-19 (20 lignes pour HGR Mixte)
        LDA NEW_HY
        BPL CHK_Y_MAX
        LDA #19
        STA NEW_HY
        BNE CHK_SELF
CHK_Y_MAX:
        CMP #20
        BCC CHK_SELF
        LDA #0
        STA NEW_HY

        ; Collision avec soi-même
        LDX #1
CHK_SELF:
        CPX LEN
        BEQ COLLIDE_OK
        LDA SNAKE_X,X
        CMP NEW_HX
        BNE NEXT_SEG
        LDA SNAKE_Y,X
        CMP NEW_HY
        BEQ DO_GAME_OVER
NEXT_SEG:
        INX
        BNE CHK_SELF
COLLIDE_OK:
        RTS

; ==========================================
; GAME OVER
; ==========================================
DO_GAME_OVER:
        JSR BEEP_CRASH   ; Son grave d'écrasement
        
        LDA SCORE+2
        CMP HI_SCORE+2
        BCC DRAW_GO
        BNE NEW_HI
        LDA SCORE+1
        CMP HI_SCORE+1
        BCC DRAW_GO
        BNE NEW_HI
        LDA SCORE
        CMP HI_SCORE
        BCC DRAW_GO
        BEQ DRAW_GO
NEW_HI:
        LDA SCORE
        STA HI_SCORE
        LDA SCORE+1
        STA HI_SCORE+1
        LDA SCORE+2
        STA HI_SCORE+2
        JSR UPDATE_SCORE

DRAW_GO:
        ; "GAME OVER" (Y=21, Col=15)
        LDY #21
        LDX #15
        LDA #$C7
        JSR DRAW_CHAR
        INX
        LDA #$C1
        JSR DRAW_CHAR
        INX
        LDA #$CD
        JSR DRAW_CHAR
        INX
        LDA #$C5
        JSR DRAW_CHAR
        INX
        LDA #$A0
        JSR DRAW_CHAR
        INX
        LDA #$CF
        JSR DRAW_CHAR
        INX
        LDA #$D6
        JSR DRAW_CHAR
        INX
        LDA #$C5
        JSR DRAW_CHAR
        INX
        LDA #$D2
        JSR DRAW_CHAR

        ; "REPLAY Y/N?" (Y=22, Col=14)
        LDY #22
        LDX #0
ASK_LOOP:
        LDA TXT_REPLAY,X
        BEQ ASK_WAIT
        PHA
        TXA
        CLC
        ADC #14
        TAX
        PLA
        JSR DRAW_CHAR
        TXA
        SEC
        SBC #14
        TAX
        INX
        BNE ASK_LOOP

ASK_WAIT:
        BIT KBD_STRB
HALT:
        LDA KBD
        BPL HALT
        BIT KBD_STRB
        AND #$DF
        CMP #$D9         ; Y
        BEQ PLAY_AGAIN
        CMP #$CE         ; N
        BEQ QUIT_GAME
        BNE HALT

PLAY_AGAIN:
        PLA
        PLA
        JMP INIT

QUIT_GAME:
        STA TXT_ON
        JSR $FC58

        LDA #0
        STA DROP_C
DROP_NEXT_CHAR:
        LDX DROP_C
        LDA TXT_BYE,X
        BEQ BYE_DONE
        STA DROP_CH
        LDA #0
        STA WIPE_R
DROP_FALL:
        LDA DROP_C
        CLC
        ADC #12
        TAX
        LDY WIPE_R
        LDA DROP_CH
        JSR DRAW_CHAR
        JSR DELAY_TYPING
        LDA WIPE_R
        CMP #11
        BEQ DROP_ARRIVED
        LDA DROP_C
        CLC
        ADC #12
        TAX
        LDY WIPE_R
        LDA #$A0
        JSR DRAW_CHAR
        INC WIPE_R
        JMP DROP_FALL
DROP_ARRIVED:
        INC DROP_C
        JMP DROP_NEXT_CHAR

BYE_DONE:
        JSR DELAY_LONG
        JSR DELAY_LONG
        JSR DELAY_LONG
        JSR $FC58
        JMP $E003

; ==========================================
; NOURRITURE & MOUVEMENT
; ==========================================
CHECK_FOOD:
        LDA NEW_HX
        CMP FOOD_X
        BNE MOVE_BODY
        LDA NEW_HY
        CMP FOOD_Y
        BNE MOVE_BODY

        ; Mangé !
        JSR BEEP           ; Son simple rétro
        JSR ANIM_EAT       ; Joue l'animation transparente d'explosion
        LDA #1
        STA EATEN
        INC LEN
        
        LDA CUR_SPEED
        CMP #$20
        BCC SKIP_SPEED
        SBC #$02
        STA CUR_SPEED
SKIP_SPEED:
        SED
        LDA SCORE
        CLC
        ADC FRUIT_VAL
        STA SCORE
        LDA SCORE+1
        ADC FRUIT_VAL+1
        STA SCORE+1
        LDA SCORE+2
        ADC #0
        STA SCORE+2
        
        LDA FRUIT_VAL
        CLC
        ADC #$10
        STA FRUIT_VAL
        LDA FRUIT_VAL+1
        ADC #0
        STA FRUIT_VAL+1
        CLD
        JSR PLACE_FOOD
        JSR UPDATE_SCORE
        JMP SHIFT_BODY

MOVE_BODY:
        LDA #0
        STA EATEN
        LDX LEN
        DEX
        LDA SNAKE_X,X
        PHA
        LDY SNAKE_Y,X
        PLA
        TAX
        LDA #0           ; 0 = Shape Empty (Noir)
        JSR DRAW_BLOCK

SHIFT_BODY:
        LDX LEN
        DEX
        DEX
        BMI UPDATE_HEAD
SHIFT_LOOP:
        LDA SNAKE_X,X
        STA SNAKE_X+1,X
        LDA SNAKE_Y,X
        STA SNAKE_Y+1,X
        DEX
        BPL SHIFT_LOOP

UPDATE_HEAD:
        LDA NEW_HX
        STA SNAKE_X
        LDA NEW_HY
        STA SNAKE_Y
        RTS

MOVE_PENALTY:
        LDA SCORE
        ORA SCORE+1
        ORA SCORE+2
        BEQ ZERO_SCORE
        SED
        SEC
        LDA SCORE
        SBC #1
        STA SCORE
        LDA SCORE+1
        SBC #0
        STA SCORE+1
        LDA SCORE+2
        SBC #0
        STA SCORE+2
        CLD
        JSR UPDATE_SCORE
ZERO_SCORE:
        RTS

; ==========================================
; RENDU GRAPHIQUE HGR
; ==========================================
UPDATE_SCR:
        ; Corps sur l'ancienne position de la tête
        LDX SNAKE_X+1
        LDY SNAKE_Y+1
        LDA #1             ; 1 = Shape Body
        JSR DRAW_BLOCK

        ; Nouvelle Tête
        LDX SNAKE_X
        LDY SNAKE_Y
        LDA #2             ; 2 = Shape Head
        JSR DRAW_BLOCK

        ; Fruit
        LDX FOOD_X
        LDY FOOD_Y
        LDA FOOD_TYPE      ; Shape dynamique du fruit (3, 4 ou 5)
        JSR DRAW_BLOCK
        RTS

; ==========================================
; FONCTIONS D'AFFICHAGE HGR & TEXTE
; ==========================================
DRAW_BLOCK:
        ; Dessine un sprite 7x8 pixels en HGR.
        ; Input: X=Col (0-39), Y=Row (0-19), A=Shape ID (0-3)
        STX TEMP_C
        STY TEMP_R
        
        ; Calcule l'adresse de la shape: SHAPE_DATA + A * 8
        ASL
        ASL
        ASL
        CLC
        ADC #<SHAPE_DATA
        STA ZP_SHAPE_LO
        LDA #>SHAPE_DATA
        ADC #0
        STA ZP_SHAPE_HI

        ; Calcule l'adresse HGR de base pour la ligne
        LDY TEMP_R
        LDA HGR_ROW_LO,Y
        CLC
        ADC TEMP_C
        STA ZP_SCR_LO
        LDA HGR_ROW_HI,Y
        ADC #0
        STA ZP_SCR_HI

        ; Boucle de dessin des 8 scanlines du bloc
        LDX #0
LOOP_DRAW:
        TXA
        TAY
        LDA (ZP_SHAPE_LO),Y
        LDY #0
        STA (ZP_SCR_LO),Y
        
        ; Passe à la scanline suivante (Y+1) = Adresse + $0400
        LDA ZP_SCR_HI
        CLC
        ADC #$04
        STA ZP_SCR_HI
        
        INX
        CPX #8
        BNE LOOP_DRAW
        RTS

DRAW_BLOCK_XOR:
        ; Dessine un sprite 7x8 pixels en HGR avec XOR (Transparence parfaite)
        STX TEMP_C
        STY TEMP_R
        
        ASL
        ASL
        ASL
        CLC
        ADC #<SHAPE_DATA
        STA ZP_SHAPE_LO
        LDA #>SHAPE_DATA
        ADC #0
        STA ZP_SHAPE_HI

        LDY TEMP_R
        LDA HGR_ROW_LO,Y
        CLC
        ADC TEMP_C
        STA ZP_SCR_LO
        LDA HGR_ROW_HI,Y
        ADC #0
        STA ZP_SCR_HI

        LDX #0
LOOP_DRAW_XOR:
        TXA
        TAY
        LDA (ZP_SHAPE_LO),Y
        LDY #0
        EOR (ZP_SCR_LO),Y      ; Applique la transparence XOR
        STA (ZP_SCR_LO),Y
        
        LDA ZP_SCR_HI
        CLC
        ADC #$04
        STA ZP_SCR_HI
        
        INX
        CPX #8
        BNE LOOP_DRAW_XOR
        RTS

DRAW_CHAR:
        ; Dessine un caractère texte dans la fenêtre (Lignes 20-23)
        ; Input: A=Char, X=Col, Y=Ligne
        PHA
        STY TEMP_Y
        TYA
        JSR GET_TXT_ADDR
        TXA
        TAY
        PLA
        STA (ZP_SCR_LO),Y
        LDY TEMP_Y
        RTS

GET_TXT_ADDR:
        ; Calcule proprement l'adresse ligne texte Apple II
        PHA
        AND #$18
        STA TEMP
        ASL
        ASL
        CLC
        ADC TEMP
        STA ZP_SCR_LO
        PLA
        AND #7
        LSR
        STA ZP_SCR_HI
        BCC GET_TXT_EVEN
        LDA ZP_SCR_LO
        CLC
        ADC #$80
        STA ZP_SCR_LO
GET_TXT_EVEN:
        LDA #>SCREEN_BASE
        CLC
        ADC ZP_SCR_HI
        STA ZP_SCR_HI
        RTS

; ==========================================
; SCORE, FOOD, DELAYS ET SONS
; ==========================================
UPDATE_SCORE:
        LDY #20
        LDX #0
LOOP1:  LDA TXT_SCORE,X
        BEQ SC_VAL
        PHA
        TXA
        CLC
        ADC #2
        TAX
        PLA
        JSR DRAW_CHAR
        TXA
        SEC
        SBC #2
        TAX
        INX
        BNE LOOP1
SC_VAL:
        LDX #8
        LDA SCORE+2
        JSR DRAW_HEX
        LDA SCORE+1
        JSR DRAW_HEX
        LDA SCORE
        JSR DRAW_HEX

        LDX #0
LOOP2:  LDA TXT_HI,X
        BEQ HI_VAL
        PHA
        TXA
        CLC
        ADC #24
        TAX
        PLA
        JSR DRAW_CHAR
        TXA
        SEC
        SBC #24
        TAX
        INX
        BNE LOOP2
HI_VAL:
        LDX #27
        LDA HI_SCORE+2
        JSR DRAW_HEX
        LDA HI_SCORE+1
        JSR DRAW_HEX
        LDA HI_SCORE
        JSR DRAW_HEX

        LDY #23
        LDX #0
LOOP3:  LDA TXT_CREDIT,X
        BEQ END_SCORE
        PHA
        TXA
        CLC
        ADC #26
        TAX
        PLA
        JSR DRAW_CHAR
        TXA
        SEC
        SBC #26
        TAX
        INX
        BNE LOOP3
END_SCORE:
        RTS

DRAW_HEX:
        PHA
        LSR
        LSR
        LSR
        LSR
        ORA #$B0
        JSR DRAW_CHAR
        INX
        PLA
        AND #$0F
        ORA #$B0
        JSR DRAW_CHAR
        INX
        RTS

; ==========================================
; TEXTES & DONNEES GRAPHIQUES (SHAPES HGR)
; ==========================================
TXT_SCORE: .byte $D3,$C3,$CF,$D2,$C5,$BA,$00 ; "SCORE:"
TXT_HI:    .byte $C8,$C9,$BA,$00             ; "HI:"
TXT_REPLAY:.byte $D2,$C5,$D0,$CC,$C1,$D9,$A0,$D9,$AF,$CE,$BF,$00 ; "REPLAY Y/N?"
TXT_BYE:   .byte $D3,$C1,$CC,$D5,$D4,$A0,$CC,$A7,$C1,$D2,$D4,$C9,$D3,$D4,$C5,$A1,$00
TXT_CREDIT:.byte $A8,$C3,$A9,$A0,$B2,$B0,$B2,$B6,$A0,$C2,$C1,$C3,$CF,$00

; Table d'adresses pour les 20 lignes de la grille HGR
HGR_ROW_LO:
        .byte $00, $80, $00, $80, $00, $80, $00, $80
        .byte $28, $A8, $28, $A8, $28, $A8, $28, $A8
        .byte $50, $D0, $50, $D0
HGR_ROW_HI:
        .byte $20, $20, $21, $21, $22, $22, $23, $23
        .byte $20, $20, $21, $21, $22, $22, $23, $23
        .byte $20, $20, $21, $21

SHAPE_DATA:
        ; 0: Vide (Noir)
        .byte $00, $00, $00, $00, $00, $00, $00, $00
        ; 1: Corps du Serpent (Ecailles - Bloc avec bordure)
        .byte $7F, $41, $41, $41, $41, $41, $7F, $00
        ; 2: Tete du Serpent (Face avec deux trous pour les yeux)
        .byte $7F, $7F, $5D, $5D, $7F, $7F, $7F, $00
        ; 3: Pomme (Redessinée - Ronde avec tige)
        .byte $04, $08, $36, $7F, $7F, $3E, $1C, $00
        ; 4: Cerise (Redessinée - 2 fruits, 2 tiges liées)
        .byte $18, $24, $42, $63, $77, $77, $63, $00
        ; 5: Citron (Redessiné - Ovale en diagonale)
        .byte $00, $40, $70, $7C, $3E, $07, $01, $00
        ; 6: Animation Eat 1 (Boule centrale pleine)
        .byte $1C, $3E, $7F, $7F, $7F, $3E, $1C, $00
        ; 7: Animation Eat 2 (Croix directionnelle)
        .byte $08, $08, $08, $7F, $7F, $08, $08, $08
        ; 8: Animation Eat 3 (Onde de choc extérieure)
        .byte $41, $22, $14, $00, $00, $14, $22, $41

; ==========================================
; LOGIQUE DE JEU COMPLEMENTAIRE
; ==========================================
PLACE_FOOD:
RAND_LOOP:
        LDA SEED
        ASL
        ASL
        CLC
        ADC SEED
        CLC
        ADC #1
        STA SEED
        AND #$3F
        CMP #40
        BCC X_OK
        SBC #40
X_OK:   STA FOOD_X
        LDA SEED
        ASL
        ASL
        CLC
        ADC SEED
        CLC
        ADC #1
        STA SEED
        AND #$1F
        CMP #20          ; HGR grille a 20 lignes max
        BCC Y_OK
        SBC #20
Y_OK:   STA FOOD_Y
        LDX #0
CHK_OVER:
        CPX LEN
        BEQ GEN_FTYPE
        LDA SNAKE_X,X
        CMP FOOD_X
        BNE NEXT_OVER
        LDA SNAKE_Y,X
        CMP FOOD_Y
        BEQ RAND_LOOP
NEXT_OVER:
        INX
        BNE CHK_OVER
GEN_FTYPE:
        
        ; Choisit un fruit aléatoire (3, 4 ou 5)
        LDA SEED
        ASL
        ASL
        CLC
        ADC SEED
        CLC
        ADC #1
        STA SEED
        AND #$03
        CMP #3
        BCC SET_FTYPE
        LDA #0
SET_FTYPE:
        CLC
        ADC #3             ; Ajoute la base des index de fruits
        STA FOOD_TYPE
FOOD_OK:
        RTS

BEEP:
        TXA
        PHA
        TYA
        PHA
        LDX #$10
BP1:    LDY #$40
BP2:    DEY
        BNE BP2
        LDA SPEAKER
        DEX
        BNE BP1
        PLA
        TAY
        PLA
        TAX
        RTS

ANIM_EAT:
        ; Animation d'éclat transparente (XOR) locale autour de la tête
        TXA
        PHA
        TYA
        PHA

        ; --- Frame 1 ---
        LDX FOOD_X
        LDY FOOD_Y
        LDA #6
        JSR DRAW_BLOCK_XOR
        
        JSR DELAY_SHORT
        
        LDX FOOD_X
        LDY FOOD_Y
        LDA #6
        JSR DRAW_BLOCK_XOR  ; Efface proprement

        ; --- Frame 2 ---
        LDX FOOD_X
        LDY FOOD_Y
        LDA #7
        JSR DRAW_BLOCK_XOR
        
        JSR DELAY_SHORT

        LDX FOOD_X
        LDY FOOD_Y
        LDA #7
        JSR DRAW_BLOCK_XOR  ; Efface proprement

        ; --- Frame 3 ---
        LDX FOOD_X
        LDY FOOD_Y
        LDA #8
        JSR DRAW_BLOCK_XOR
        
        LDX FOOD_X
        LDY FOOD_Y
        LDA #8
        JSR DRAW_BLOCK_XOR  ; Efface proprement

        PLA
        TAY
        PLA
        TAX
        RTS

BEEP_CRASH:
        ; Son plus long et grave pour l'accident
        TXA
        PHA
        TYA
        PHA
        LDX #$80
BC1:    LDY #$80
BC2:    DEY
        BNE BC2
        LDA SPEAKER
        DEX
        BNE BC1
        PLA
        TAY
        PLA
        TAX
        RTS

DELAY:
        LDA CUR_SPEED
        STA DLY_X
DLY1:   LDA #$50
        STA DLY_Y
DLY2:   LDA KBD
        BPL NOKEY
        PHA
        BIT KBD_STRB
        LDX Q_HEAD
        INX
        TXA
        AND #$03
        CMP Q_TAIL
        BEQ Q_FULL
        TAX
        PLA
        STA KEY_Q,X
        STX Q_HEAD
        JMP NOKEY
Q_FULL: PLA
NOKEY:
        DEC DLY_Y
        BNE DLY2
        DEC DLY_X
        BNE DLY1
        RTS

DELAY_SHORT:
        TXA
        PHA
        TYA
        PHA
        LDX #$04
DS1:    LDY #$FF
DS2:    DEY
        BNE DS2
        DEX
        BNE DS1
        PLA
        TAY
        PLA
        TAX
        RTS

DELAY_TYPING:
        TXA
        PHA
        TYA
        PHA
        LDX #$15
DT1:    LDY #$FF
DT2:    DEY
        BNE DT2
        DEX
        BNE DT1
        PLA
        TAY
        PLA
        TAX
        RTS

DELAY_LONG:
        TXA
        PHA
        TYA
        PHA
        LDX #$FF
DL1:    LDY #$FF
DL2:    DEY
        BNE DL2
        DEX
        BNE DL1
        PLA
        TAY
        PLA
        TAX
        RTS
