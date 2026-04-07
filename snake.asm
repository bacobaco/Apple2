; ==========================================
; SNAKE pour Apple II+ (40x24)
; Assembleur: 64tass
; Adresse: $4000
; ==========================================
        * = $4000

; --- Page Zéro (obligatoire pour (addr),Y) ---
ZP_SCR_LO = $F8
ZP_SCR_HI = $F9

; --- Variables (Zone absolue à $4800, après le code) ---
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
FRUIT_VAL= VAR_BASE + $1A  ; 2 octets (Valeur en points du prochain fruit)
WIPE_C   = VAR_BASE + $1C  ; Compteur animation colonne
WIPE_R   = VAR_BASE + $1D  ; Compteur animation ligne
DROP_C   = VAR_BASE + $1E  ; Animation texte (index)
DROP_CH  = VAR_BASE + $1F  ; Animation texte (caractere)
SNAKE_X  = VAR_BASE + $20    ; 256 octets max
SNAKE_Y  = VAR_BASE + $120   ; 256 octets max

SCREEN_BASE = $0400

; ==========================================
; INITIALISATION
; ==========================================
RESET_ALL:
        LDA #0
        STA HI_SCORE
        STA HI_SCORE+1
        STA HI_SCORE+2
INIT:
        ; Efface écran $0400-$07FF avec espaces ($A0)
        LDA #$A0
        LDY #$00
CLR_LOOP:
        STA $0400,Y
        STA $0500,Y
        STA $0600,Y
        STA $0700,Y
        INY
        BNE CLR_LOOP

        ; Position initiale (20,12), longueur 3
        LDA #20
        STA SNAKE_X
        STA SNAKE_X+1
        STA SNAKE_X+2
        LDA #12
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
        LDA #$B0            ; Vitesse de départ (délai initial)
        STA CUR_SPEED
        LDA #$30            ; Valeur initiale du 1er fruit (30 pts en BCD)
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
; CLAVIER (Flèches)
; ==========================================
CHECK_KEY:
        LDX Q_TAIL
        CPX Q_HEAD
        BEQ CHECK_KEY_DONE  ; File vide
        INX
        TXA
        AND #$03
        STA Q_TAIL
        TAX
        LDA KEY_Q,X

        CMP #$8B            ; Flèche Haut
        BNE CHK_LEFT
        LDA DIR_Y
        CMP #1
        BEQ CHECK_KEY       ; Si invalide (demi-tour direct), essaie la touche suivante
        LDA #0
        STA DIR_X
        LDA #$FF
        STA DIR_Y
        RTS

CHK_LEFT: CMP #$88          ; Flèche Gauche
        BNE CHK_DOWN
        LDA DIR_X
        CMP #1
        BEQ CHECK_KEY
        LDA #$FF
        STA DIR_X
        LDA #0
        STA DIR_Y
        RTS

CHK_DOWN: CMP #$8A          ; Flèche Bas
        BNE CHK_RIGHT
        LDA DIR_Y
        CMP #$FF
        BEQ CHECK_KEY
        LDA #0
        STA DIR_X
        LDA #1
        STA DIR_Y
        RTS

CHK_RIGHT: CMP #$95         ; Flèche Droite
        BNE CHECK_KEY       ; Touche non valide, ignorer
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
; CALCUL TÊTE & COLLISIONS
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
        ; Bornes X: 0-39 (Traversée de l'écran)
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
        ; Bornes Y: 0-22 (Ligne 23 réservée au score)
        LDA NEW_HY
        BPL CHK_Y_MAX
        LDA #22
        STA NEW_HY
        BNE CHK_SELF
CHK_Y_MAX:
        CMP #23
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
; GAME OVER (Placé juste après les tests pour branchement court)
; ==========================================
DO_GAME_OVER:
        ; Mise à jour du High Score (sur 3 octets)
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
        ; Affiche "GAME OVER" (ligne 11, col 14)
        LDA #$C7
        LDY #11
        LDX #14
        JSR DRAW_CHAR          ; G
        LDA #$C1
        INX
        JSR DRAW_CHAR          ; A
        LDA #$CD
        INX
        JSR DRAW_CHAR          ; M
        LDA #$C5
        INX
        JSR DRAW_CHAR          ; E
        LDA #$A0
        INX
        JSR DRAW_CHAR          ;   (espace)
        LDA #$CF
        INX
        JSR DRAW_CHAR          ; O
        LDA #$D6
        INX
        JSR DRAW_CHAR          ; V
        LDA #$C5
        INX
        JSR DRAW_CHAR          ; E
        LDA #$D2
        INX
        JSR DRAW_CHAR          ; R

        ; Affiche "REPLAY Y/N?" (ligne 13, col 14)
        LDY #13
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
        ; Nettoie le buffer clavier matériel avant d'attendre
        BIT $C010
HALT:
        ; Boucle infinie d'attente d'une touche
        LDA $C000
        BPL HALT
        BIT $C010
        AND #$DF         ; Convertit minuscules en majuscules
        CMP #$D9         ; Touche 'Y'
        BEQ PLAY_AGAIN
        CMP #$CE         ; Touche 'N'
        BEQ QUIT_GAME
        BNE HALT

PLAY_AGAIN:
        PLA              ; Nettoie l'adresse de retour (de CHECK_COLLIDE)
        PLA              ; sur la pile pour éviter un débordement (Stack Overflow)
        JMP INIT

QUIT_GAME:
        ; Effet de balayage entrelacé (Erase screen)
        LDA #0
        STA WIPE_R
WIPE_EVEN_ROW:
        LDA #0
        STA WIPE_C
WIPE_EVEN_COL:
        LDX WIPE_C
        LDY WIPE_R
        LDA #$A0
        JSR DRAW_CHAR
        JSR DELAY_SHORT
        INC WIPE_C
        LDA WIPE_C
        CMP #40
        BNE WIPE_EVEN_COL
        INC WIPE_R
        INC WIPE_R
        LDA WIPE_R
        CMP #24
        BCC WIPE_EVEN_ROW

        LDA #1
        STA WIPE_R
WIPE_ODD_ROW:
        LDA #39
        STA WIPE_C
WIPE_ODD_COL:
        LDX WIPE_C
        LDY WIPE_R
        LDA #$A0
        JSR DRAW_CHAR
        JSR DELAY_SHORT
        DEC WIPE_C
        BPL WIPE_ODD_COL
        INC WIPE_R
        INC WIPE_R
        LDA WIPE_R
        CMP #24
        BCC WIPE_ODD_ROW

        ; Animation "SALUT L'ARTISTE!" : Les lettres tombent du ciel
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
        ADC #12        ; Colonne d'arrivée (12)
        TAX
        LDY WIPE_R
        LDA DROP_CH
        JSR DRAW_CHAR
        
        JSR DELAY_TYPING ; Vitesse de chute de la lettre
        
        LDA WIPE_R
        CMP #11        ; Ligne d'arrivée finale (11)
        BEQ DROP_ARRIVED
        
        LDA DROP_C
        CLC
        ADC #12
        TAX
        LDY WIPE_R
        LDA #$A0       ; Efface la trace derrière la lettre
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
        JSR $FC58        ; ROM Apple II: Efface l'écran (HOME)
        JMP $E003        ; ROM Applesoft: Warm Start (Retour 100% sûr au prompt BASIC)

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
        LDA #1
        STA EATEN
        INC LEN
        
        ; Augmente la vitesse (réduit le délai)
        LDA CUR_SPEED
        CMP #$20          ; Limite de vitesse maximale (ne pas descendre sous $20)
        BCC SKIP_SPEED
        SBC #$02          ; Le Carry est déjà positionné par le CMP (>= $20)
        STA CUR_SPEED
SKIP_SPEED:
        SED               ; Mode Décimal BCD !
        LDA SCORE
        CLC
        ADC FRUIT_VAL     ; Ajoute la valeur dynamique du fruit
        STA SCORE
        LDA SCORE+1
        ADC FRUIT_VAL+1   ; Retenue décimale (centaines/milliers)
        STA SCORE+1
        LDA SCORE+2
        ADC #0            ; Retenue dizaines/centaines de milliers
        STA SCORE+2
        
        ; Augmente la valeur du prochain fruit de 10 points
        LDA FRUIT_VAL
        CLC
        ADC #$10
        STA FRUIT_VAL
        LDA FRUIT_VAL+1
        ADC #0
        STA FRUIT_VAL+1
        CLD               ; Sortie mode Décimal
        JSR PLACE_FOOD
        JSR UPDATE_SCORE
        JMP SHIFT_BODY

MOVE_BODY:
        LDA #0
        STA EATEN

        ; Efface queue
        LDX LEN
        DEX
        LDA SNAKE_X,X
        PHA
        LDY SNAKE_Y,X
        PLA
        TAX
        LDA #$A0
        JSR DRAW_CHAR

SHIFT_BODY:
        ; Décale corps
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

; ==========================================
; GESTION DU SCORE (Pénalité de déplacement)
; ==========================================
MOVE_PENALTY:
        LDA SCORE
        ORA SCORE+1
        ORA SCORE+2
        BEQ ZERO_SCORE    ; Si le score est de 0, on ne retire rien
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
        JSR UPDATE_SCORE  ; Met à jour l'écran pour voir les points descendre
ZERO_SCORE:
        RTS

; ==========================================
; AFFICHAGE
; ==========================================
UPDATE_SCR:
        ; Corps ($CF = 'O' normal) sur l'ancienne position de la tête
        LDX SNAKE_X+1
        LDY SNAKE_Y+1
        LDA #$CF
        JSR DRAW_CHAR

        ; Nouvelle tête ($00 = '@' inversé, bloc plein)
        LDX SNAKE_X
        LDY SNAKE_Y
        LDA #$00
        JSR DRAW_CHAR
        ; Nourriture ($AA = '*')
        LDX FOOD_X
        LDY FOOD_Y
        LDA #$AA
        JSR DRAW_CHAR
        RTS

; ==========================================
; AFFICHAGE DU SCORE
; ==========================================
UPDATE_SCORE:
        LDY #23
        LDX #0
LOOP1:  LDA TXT_SCORE,X
        BEQ SC_VAL
        JSR DRAW_CHAR
        INX
        BNE LOOP1
SC_VAL:
        LDX #6            ; Score commence col 6
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
        ADC #15           ; "HI:" commence col 15
        TAX
        PLA
        JSR DRAW_CHAR
        TXA
        SEC
        SBC #15
        TAX
        INX
        BNE LOOP2
HI_VAL:
        LDX #18           ; Valeur HI commence col 18
        LDA HI_SCORE+2
        JSR DRAW_HEX
        LDA HI_SCORE+1
        JSR DRAW_HEX
        LDA HI_SCORE
        JSR DRAW_HEX

        LDX #0
LOOP3:  LDA TXT_CREDIT,X
        BEQ END_SCORE
        PHA
        TXA
        CLC
        ADC #27           ; "(C) 2026..." commence col 27
        TAX
        PLA
        JSR DRAW_CHAR
        TXA
        SEC
        SBC #27
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

TXT_SCORE: .byte $D3,$C3,$CF,$D2,$C5,$BA,$00 ; "SCORE:"
TXT_HI:    .byte $C8,$C9,$BA,$00             ; "HI:"
TXT_REPLAY:.byte $D2,$C5,$D0,$CC,$C1,$D9,$A0,$D9,$AF,$CE,$BF,$00 ; "REPLAY Y/N?"
TXT_BYE:   .byte $D3,$C1,$CC,$D5,$D4,$A0,$CC,$A7,$C1,$D2,$D4,$C9,$D3,$D4,$C5,$A1,$00 ; "SALUT L'ARTISTE!"
TXT_CREDIT:.byte $A8,$C3,$A9,$A0,$B2,$B0,$B2,$B6,$A0,$C2,$C1,$C3,$CF,$00 ; "(C) 2026 BACO"

DRAW_CHAR:
        ; A=caractère, X=col, Y=ligne
        PHA
        STY TEMP_Y
        TXA
        JSR GET_ADDR
        PLA
        LDY #0
        STA (ZP_SCR_LO),Y
        LDY TEMP_Y
        RTS

GET_ADDR:
        ; Calcule adresse écran Apple II: $0400 + (Y&7)*128 + (Y&$18)*5 + X
        STA ZP_SCR_LO

        ; (Y & 7) * 128
        TYA
        AND #7
        LSR
        STA ZP_SCR_HI
        BCC EVEN_ROW
        LDA #$80
        CLC
        ADC ZP_SCR_LO
        STA ZP_SCR_LO
EVEN_ROW:
        ; (Y & $18) * 5
        TYA
        AND #$18
        STA TEMP
        ASL
        ASL
        CLC
        ADC TEMP
        CLC
        ADC ZP_SCR_LO
        STA ZP_SCR_LO
        BCC NC2
        INC ZP_SCR_HI
NC2:
        ; + $0400
        LDA #>SCREEN_BASE
        CLC
        ADC ZP_SCR_HI
        STA ZP_SCR_HI
        RTS

; ==========================================
; GÉNÉRATION NOURRITURE
; ==========================================
PLACE_FOOD:
RAND_LOOP:
        ; LCG: seed = seed*5 + 1
        LDA SEED
        ASL
        ASL
        CLC
        ADC SEED
        CLC
        ADC #1
        STA SEED

        ; X = seed % 40
        AND #$3F
        CMP #40
        BCC X_OK
        SBC #40
X_OK:
        STA FOOD_X

        ; Nouvelle frame pseudo-aléatoire pour Y
        LDA SEED
        ASL
        ASL
        CLC
        ADC SEED
        CLC
        ADC #1
        STA SEED

        ; Y = seed % 23 (Limite jouable à cause des scores)
        LDA SEED
        AND #$1F
        CMP #23
        BCC Y_OK
        SBC #23
Y_OK:
        STA FOOD_Y

        ; Vérifie chevauchement serpent
        LDX #0
CHK_OVER:
        CPX LEN
        BEQ FOOD_OK
        LDA SNAKE_X,X
        CMP FOOD_X
        BNE NEXT_OVER
        LDA SNAKE_Y,X
        CMP FOOD_Y
        BEQ RAND_LOOP
NEXT_OVER:
        INX
        BNE CHK_OVER
FOOD_OK:
        RTS

; ==========================================
; DÉLAI
; ==========================================
DELAY:
        LDA CUR_SPEED
        STA DLY_X
DLY1:   LDA #$50
        STA DLY_Y
DLY2:
        LDA $C000
        BPL NOKEY
        PHA             ; Sauvegarder la touche
        BIT $C010       ; Acquittement
        LDX Q_HEAD
        INX
        TXA
        AND #$03
        CMP Q_TAIL
        BEQ Q_FULL      ; File pleine, on drop
        TAX
        PLA             ; Récupérer la touche
        STA KEY_Q,X
        STX Q_HEAD
        JMP NOKEY
Q_FULL:
        PLA             ; Nettoyer la pile
NOKEY:
        DEC DLY_Y
        BNE DLY2
        DEC DLY_X
        BNE DLY1
        RTS

; ==========================================
; ANIMATIONS DELAYS
; ==========================================
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