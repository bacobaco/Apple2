; ---------------------------------------------------------
; HAPPY BIRD pour Apple II (HGR Double Buffering)
; Version Authentique - Rims, Scores Graphiques & Menu
; ---------------------------------------------------------

.cpu "6502"

* = $6000

; --- Variables Zero Page ---
PIPE_COLOR1 = $04
PIPE_COLOR2 = $05
BIRD_Y      = $06
BIRD_Y_HI   = $07
BIRD_VEL    = $08
BIRD_VEL_HI = $09
PIPE1_X     = $0A
PIPE1_GAP   = $0B
SCORE       = $0C
PAGE_FLG    = $0D
DRAW_PG_HI  = $0E ; Base page ($20 ou $40)
TEMP_COL    = $0F
TEMP_ROW    = $10
TEMP_VAL    = $11
DIGIT_PTR   = $12
SPRITE_ROW  = $13
TEMP_VAL1   = $14
PIPE2_X     = $15
PIPE2_GAP   = $16
RANDOM_CTR  = $17
CLEAR_LEFT_FLG   = $18
REDRAW_SCORE_FLG = $19
HIGH_SCORE  = $1A
BIRD_Y_P1   = $1B
FRAME_CTR   = $1C
BIRD_Y_P2   = $1D
PIPE_X      = $1E  ; Paramètre dessin / collision
PIPE_GAP    = $1F  ; Paramètre dessin / collision
TEMP_VAL2   = $20
TEMP_TYPE   = $21
FLAP_ACTIVE   = $22
FLAP_HOLD_CTR = $23
RIM_COLOR1  = $24
RIM_COLOR2  = $25
RIM_COLOR3  = $26
SCR_PTR     = $FC
SCR_PTR_HI  = $FD
TEMP_Y      = $FF

; --- Constantes ---
GRAVITY_LO  = $00
GRAVITY_HI  = $02
FLAP_LO     = $00
FLAP_HI     = $F6  ; Plus puissant pour monter plus haut (-10 au lieu de -6)
MAX_FALL_HI = $05

; Soft Switches Apple II
TXTCLR      = $C050
TXTSET      = $C051
MIXCLR      = $C052
MIXSET      = $C053
PAGE1       = $C054
PAGE2       = $C055
HIRES       = $C057
KEYPAD      = $C000
KEY_CLR     = $C010
VBLANK      = $C019

; ---------------------------------------------------------
; INITIALISATION
; ---------------------------------------------------------
START:
         STA $C000      ; Desactiver 80STORE
         STA HIRES      ; Passer en HGR
         STA MIXCLR     ; Plein ecran graphique
         STA TXTCLR     ; Activer mode graphique
         STA PAGE1      ; Afficher la page 1 initialement
         
         LDA #0
         STA HIGH_SCORE ; Reset du High Score à froid uniquement
         
RESTART:
         LDA #$00
         STA SCORE
         STA FRAME_CTR
         STA PAGE_FLG
         STA RANDOM_CTR
         STA FLAP_ACTIVE
         STA FLAP_HOLD_CTR
         LDA #2
         STA CLEAR_LEFT_FLG
         STA REDRAW_SCORE_FLG
         
         LDA #$00       ; Position Y fraction oiseau
         STA BIRD_Y
         LDA #$60       ; Position Y entier oiseau
         STA BIRD_Y_HI
         STA BIRD_Y_P1  ; Initialiser ancienne position Page 1
         STA BIRD_Y_P2  ; Initialiser ancienne position Page 2
         LDA #$00       ; Vitesse initiale
         STA BIRD_VEL
         STA BIRD_VEL_HI
         
         LDA #36        ; Tuyau 1 au milieu droit
         STA PIPE1_X
         LDA #70        ; Gap initial
         STA PIPE1_GAP
         
         LDA #56        ; Tuyau 2 décalé de 20 colonnes
         STA PIPE2_X
         LDA #90        ; Autre gap
         STA PIPE2_GAP
         
         ; Effacer les deux pages HGR
         LDA #$20
         STA DRAW_PG_HI
         JSR CLEAR_SCREEN
         LDA #$40
         STA DRAW_PG_HI
         JSR CLEAR_SCREEN
 
         ; Dessiner l'état de départ sur la Page 1 et l'afficher
         LDA #$20
         STA DRAW_PG_HI
         JSR DRAW_PIPES
         JSR DRAW_BIRD
         JSR DRAW_SCORE
         STA PAGE1
         
         ; Dessiner le même état sur la Page 2 (prête pour le flip)
         LDA #$40
         STA DRAW_PG_HI
         JSR DRAW_PIPES
         JSR DRAW_BIRD
         JSR DRAW_SCORE
         
         ; Configurer le prochain dessin sur la Page 2
         LDA #$40
         STA DRAW_PG_HI
         LDA #$00
         STA PAGE_FLG

; ---------------------------------------------------------
; ECRAN DE DEMARRAGE (START SCREEN)
; ---------------------------------------------------------
START_SCREEN:
         ; Attente d'un appui clavier pour lancer la partie
         LDA KEYPAD
         BPL START_SCREEN
         STA KEY_CLR       ; Acquitter la touche pressée
         
         ; Impulsion initiale vers le haut
         LDA #FLAP_LO
         STA BIRD_VEL
         LDA #FLAP_HI
         STA BIRD_VEL_HI

; ---------------------------------------------------------
; BOUCLE PRINCIPALE (MAIN GAME LOOP)
; ---------------------------------------------------------
MAIN_LOOP:
         ; 1. Synchronisation avec le balayage vertical (VBL)
WAIT_VBL1:
         LDA $C019
         BMI WAIT_VBL1   ; Attendre la fin du VBL actuel
WAIT_VBL2:
         LDA $C019
         BPL WAIT_VBL2   ; Attendre le début du prochain VBL

         ; 2. Swap Buffers IMMEDIATEMENT au début du VBL (tear-free)
         JSR SWAP_BUFFERS

         INC RANDOM_CTR  ; Incrémenter le compteur pour la randomisation des gaps

         ; 3. Detection touche Clavier (Saut)
         LDA KEYPAD
         BPL CHECK_HOLD
         
         ; Nouveau saut initialisé !
         LDA #FLAP_LO
         STA BIRD_VEL
         LDA #$FA        ; Saut initial un peu plus léger (-6)
         STA BIRD_VEL_HI
         
         LDA #1
         STA FLAP_ACTIVE
         LDA #0
         STA FLAP_HOLD_CTR
         
         STA KEY_CLR     ; Vider le tampon clavier et lire "Any Key Down"
         JMP NO_FLAP
         
CHECK_HOLD:
         LDA FLAP_ACTIVE
         BEQ NO_FLAP
         
         ; Si le saut est actif, on verifie si la touche est toujours enfoncee
         LDA $C010       ; Lire le registre Any Key Down (bit 7)
         BPL RELEASED    ; Si bit 7 = 0, la touche a ete relachee
         
         ; Touche toujours enfoncee -> appliquer un boost
         LDA BIRD_VEL_HI
         SEC
         SBC #1          ; Augmenter la vitesse vers le haut (soustraire 1)
         STA BIRD_VEL_HI
         
         INC FLAP_HOLD_CTR
         LDA FLAP_HOLD_CTR
         CMP #4          ; Boost maximum de 4 frames
         BCC NO_FLAP
         
RELEASED:
         LDA #0
         STA FLAP_ACTIVE
NO_FLAP:

         ; 4. Application de la gravite (Physique)
         CLC
         LDA BIRD_VEL
         ADC #GRAVITY_LO
         STA BIRD_VEL
         LDA BIRD_VEL_HI
         ADC #GRAVITY_HI
         STA BIRD_VEL_HI

         ; Limitation de la vitesse de chute
         LDA BIRD_VEL_HI
         BMI APPLY_VEL  ; Si l'oiseau monte (vitesse < 0), pas de bridage
         CMP #MAX_FALL_HI
         BCC APPLY_VEL
         LDA #MAX_FALL_HI
         STA BIRD_VEL_HI
         LDA #$00
         STA BIRD_VEL

APPLY_VEL:
         CLC
         LDA BIRD_Y
         ADC BIRD_VEL
         STA BIRD_Y
         LDA BIRD_Y_HI
         ADC BIRD_VEL_HI
         STA BIRD_Y_HI

         ; 5. Defilement des tuyaux (une fois toutes les 2 frames, ~30 Hz)
         INC FRAME_CTR
         LDA FRAME_CTR
         CMP #2
         BNE NO_SCROLL
         
         LDA #0
         STA FRAME_CTR
         
         ; Défiler Pipe 1
         DEC PIPE1_X
         LDA PIPE1_X
         CMP #255
         BNE P1_NO_RESET
         LDA #39
         STA PIPE1_X
         JSR RESET_PIPE1_GAP
         LDA #2
         STA CLEAR_LEFT_FLG
P1_NO_RESET:
         LDA PIPE1_X
         CMP #5
         BNE P1_NO_SCORE
         LDA SCORE
         CMP #99
         BCS P1_NO_SCORE
         INC SCORE
P1_NO_SCORE:

         ; Défiler Pipe 2
         DEC PIPE2_X
         LDA PIPE2_X
         CMP #255
         BNE P2_NO_RESET
         LDA #39
         STA PIPE2_X
         JSR RESET_PIPE2_GAP
         LDA #2
         STA CLEAR_LEFT_FLG
P2_NO_RESET:
         LDA PIPE2_X
         CMP #5
         BNE P2_NO_SCORE
         LDA SCORE
         CMP #99
         BCS P2_NO_SCORE
         INC SCORE
P2_NO_SCORE:

NO_SCROLL:
         ; 6. Gestion des effacements périodiques de la bordure gauche
         LDA CLEAR_LEFT_FLG
         BEQ NO_CLR_L
         JSR CLEAR_LEFT_EDGE
         DEC CLEAR_LEFT_FLG
NO_CLR_L:

         ; 7. Dessin sur le buffer invisible (Score, Tuyaux, Oiseau)
         JSR DRAW_SCORE
         JSR DRAW_PIPES
         JSR DRAW_BIRD

         ; 7. Collisions avec le sol et le plafond
         LDA BIRD_Y_HI
         CMP #184
         BCS GAME_OVER
         CMP #2
         BCC GAME_OVER

         ; 8. Collisions avec les deux tuyaux
         LDA PIPE1_X
         STA PIPE_X
         LDA PIPE1_GAP
         STA PIPE_GAP
         JSR CHECK_COLLISION
         BCS GAME_OVER
         
         LDA PIPE2_X
         STA PIPE_X
         LDA PIPE2_GAP
         STA PIPE_GAP
         JSR CHECK_COLLISION
         BCS GAME_OVER

NO_COLLIDE:
         JMP MAIN_LOOP

; ---------------------------------------------------------
; FIN DE PARTIE (GAME OVER)
; ---------------------------------------------------------
GAME_OVER:
         ; Delai pour eviter d'enregistrer le dernier flap
         LDX #$20
GO_D1:   LDY #$FF
GO_D2:   DEY
         BNE GO_D2
         DEX
         BNE GO_D1
         
         STA KEY_CLR    ; Vider le tampon clavier
         
WAIT_KEY:
         LDA KEYPAD
         BPL WAIT_KEY   ; Attendre n'importe quelle touche
         STA KEY_CLR
         
         JMP RESTART    ; Recommencer la partie (arcade loop)

SWAP_BUFFERS:
         LDA PAGE_FLG
         BEQ SHOW_P2
SHOW_P1:
         STA PAGE1
         LDA #$40       ; Prochain dessin sur la Page 2
         STA DRAW_PG_HI
         LDA #$00
         STA PAGE_FLG
         RTS
SHOW_P2:
         STA PAGE2
         LDA #$20       ; Prochain dessin sur la Page 1
         STA DRAW_PG_HI
         LDA #$01
         STA PAGE_FLG
         RTS

CLEAR_LEFT_EDGE:
         LDY #0
CLE_LP:  TYA
         PHA
         JSR GET_HGR_ADDR
         LDY #0
         LDA #0
         STA (SCR_PTR),Y
         INY
         STA (SCR_PTR),Y
         INY
         STA (SCR_PTR),Y
         INY
         STA (SCR_PTR),Y
         PLA
         TAY
         INY
         CPY #192
         BCC CLE_LP
         RTS
CLEAR_SCORE_AREA:
         LDA #4
         STA TEMP_ROW
CS_LP:   LDA TEMP_ROW
         JSR GET_HGR_ADDR
         
         ; Effacer la section gauche (col 0-9)
         LDY #0
         LDA #0
CS_L_LP: STA (SCR_PTR),Y
         INY
         CPY #10
         BCC CS_L_LP
         
         ; Effacer la section droite (col 25-39)
         LDY #25
CS_R_LP: STA (SCR_PTR),Y
         INY
         CPY #40
         BCC CS_R_LP
         
         INC TEMP_ROW
         LDA TEMP_ROW
         CMP #11
         BCC CS_LP
         RTS

; ---------------------------------------------------------
; SOUS-ROUTINE: EFFACER L'ECRAN CACHÉ
; ---------------------------------------------------------
CLEAR_SCREEN:
         LDA DRAW_PG_HI
         STA SCR_PTR_HI
         LDA #$00
         STA SCR_PTR
         LDY #$00
         TYA            ; A = 0
CLR_LP:  STA (SCR_PTR),Y
         INY
         BNE CLR_LP
         INC SCR_PTR_HI
         LDA SCR_PTR_HI
         AND #$1F       ; Un ecran HGR fait 32 pages ($2000 octets)
         BEQ CLR_DONE
         TYA            ; Y est a 0, donc A devient 0
         JMP CLR_LP
CLR_DONE:
         RTS

; ---------------------------------------------------------
; SOUS-ROUTINE: CALCUL D'ADRESSE LIGNE HGR
; Entree: A = Ligne Y (0-191)
; Sortie: SCR_PTR / SCR_PTR_HI = Adresse memoire ecran
; ---------------------------------------------------------
GET_HGR_ADDR:
         CMP #192
         BCC HGR_OK
         LDA #0         ; Caper a la ligne 0 en cas de debordement (securite)
HGR_OK:  TAX
         LDA HGR_LO,X
         STA SCR_PTR
         LDA HGR_HI,X
         CLC
         ADC DRAW_PG_HI
         STA SCR_PTR_HI
         RTS

; ---------------------------------------------------------
; SOUS-ROUTINE: DESSINER LES TUYAUX (Tuyaux avec chapeaux/rims)
; ---------------------------------------------------------
DRAW_PIPES:
         ; Dessiner le tuyau 1
         LDA PIPE1_X
         STA PIPE_X
         LDA PIPE1_GAP
         STA PIPE_GAP
         JSR DRAW_PIPE_SUB
         
         ; Dessiner le tuyau 2
         LDA PIPE2_X
         STA PIPE_X
         LDA PIPE2_GAP
         STA PIPE_GAP
         JSR DRAW_PIPE_SUB
         RTS

DRAW_PIPE_SUB:
         ; Déterminer les motifs de couleur en fonction de la parité de PIPE_X
         LDA PIPE_X
         AND #$01
         BEQ _even
         
         ; Case: PIPE_X is odd
         LDA #$2B
         STA PIPE_COLOR1
         LDA #$35
         STA PIPE_COLOR2
         LDA #$56
         STA RIM_COLOR1
         LDA #$2A
         STA RIM_COLOR2
         LDA #$35
         STA RIM_COLOR3
         JMP _color_set
         
_even:
         ; Case: PIPE_X is even
         LDA #$56
         STA PIPE_COLOR1
         LDA #$6A
         STA PIPE_COLOR2
         LDA #$2B
         STA RIM_COLOR1
         LDA #$55
         STA RIM_COLOR2
         LDA #$6A
         STA RIM_COLOR3
         
_color_set:

         ; Pre-calculer les colonnes dans la page zero
         LDA PIPE_X
         STA TEMP_VAL1       ; TEMP_VAL1 = PIPE_X
         
         CLC
         ADC #1
         STA TEMP_VAL2       ; TEMP_VAL2 = PIPE_X + 1
         
         CLC
         ADC #1
         STA TEMP_COL        ; TEMP_COL = PIPE_X + 2
         
         LDA PIPE_X
         SEC
         SBC #1
         STA TEMP_ROW        ; TEMP_ROW = PIPE_X - 1
         
         ; --- 1. Tuyau superieur (Y = 0 à PIPE_GAP - 1) ---
         LDA PIPE_GAP
         SEC
         SBC #8
         STA TEMP_VAL        ; Début du rebord du tuyau du haut
         
         LDX #0
TOP_LP:
         LDA HGR_LO,X
         STA SCR_PTR
         LDA HGR_HI,X
         ORA DRAW_PG_HI
         STA SCR_PTR_HI
         
         CPX TEMP_VAL
         BCS TOP_RIM
         
         ; Tuyau normal du haut
         LDY TEMP_VAL1
         CPY #40
         BCS _tns1
         LDA PIPE_COLOR1
         STA (SCR_PTR),Y
_tns1:   LDY TEMP_VAL2
         CPY #40
         BCS _tns2
         LDA PIPE_COLOR2
         STA (SCR_PTR),Y
_tns2:   LDY TEMP_COL
         CPY #40
         BCS _tns3
         LDA #$00
         STA (SCR_PTR),Y
_tns3:   JMP TOP_NEXT
      
TOP_RIM:
         ; Rebord du tuyau du haut
         LDY TEMP_ROW
         CPY #40
         BCS _trs1
         LDA RIM_COLOR1
         STA (SCR_PTR),Y
_trs1:   LDY TEMP_VAL1
         CPY #40
         BCS _trs2
         LDA RIM_COLOR2
         STA (SCR_PTR),Y
_trs2:   LDY TEMP_VAL2
         CPY #40
         BCS _trs3
         LDA RIM_COLOR3
         STA (SCR_PTR),Y
_trs3:   LDY TEMP_COL
         CPY #40
         BCS _trs4
         LDA #$00
         STA (SCR_PTR),Y
_trs4:
      
TOP_NEXT:
         INX
         CPX PIPE_GAP
         BCC TOP_LP
         
         ; --- 2. Tuyau inferieur (Y = PIPE_GAP + 35 à 191) ---
         LDA PIPE_GAP
         CLC
         ADC #43
         STA TEMP_VAL        ; Fin du rebord (début du tuyau normal du bas)
         
         LDA PIPE_GAP
         CLC
         ADC #35
         TAX                 ; X = ligne de départ du tuyau du bas
         
BOT_LP:
         CPX #192
         BCS BOT_DN
         
         LDA HGR_LO,X
         STA SCR_PTR
         LDA HGR_HI,X
         ORA DRAW_PG_HI
         STA SCR_PTR_HI
         
         CPX TEMP_VAL
         BCC BOT_RIM
         
         ; Tuyau normal du bas
         LDY TEMP_VAL1
         CPY #40
         BCS _bns1
         LDA PIPE_COLOR1
         STA (SCR_PTR),Y
_bns1:   LDY TEMP_VAL2
         CPY #40
         BCS _bns2
         LDA PIPE_COLOR2
         STA (SCR_PTR),Y
_bns2:   LDY TEMP_COL
         CPY #40
         BCS _bns3
         LDA #$00
         STA (SCR_PTR),Y
_bns3:   JMP BOT_NEXT
      
BOT_RIM:
         ; Rebord du tuyau du bas
         LDY TEMP_ROW
         CPY #40
         BCS _brs1
         LDA RIM_COLOR1
         STA (SCR_PTR),Y
_brs1:   LDY TEMP_VAL1
         CPY #40
         BCS _brs2
         LDA RIM_COLOR2
         STA (SCR_PTR),Y
_brs2:   LDY TEMP_VAL2
         CPY #40
         BCS _brs3
         LDA RIM_COLOR3
         STA (SCR_PTR),Y
_brs3:   LDY TEMP_COL
         CPY #40
         BCS _brs4
         LDA #$00
         STA (SCR_PTR),Y
_brs4:
      
BOT_NEXT:
         INX
         JMP BOT_LP
BOT_DN:
         RTS

; Subroutine de collision avec PIPE_X et PIPE_GAP
CHECK_COLLISION:
         LDA PIPE_X
         CMP #9         ; L'oiseau est aux octets 7 et 8
         BCS COLL_OK    ; Si tuyau >= 9, pas d'impact
         CMP #6
         BCC COLL_OK    ; Si tuyau < 6, pas d'impact
         
         LDA BIRD_Y_HI
         CMP PIPE_GAP
         BCC COLL_FAIL  ; Collision avec tuyau du haut
         SEC
         SBC PIPE_GAP
         CMP #28
         BCS COLL_FAIL  ; Collision avec tuyau du bas
COLL_OK:
         CLC
         RTS
COLL_FAIL:
         SEC
         RTS

; Sous-routines de réinitialisation des Gaps avec randomisation
RESET_PIPE1_GAP:
         LDA RANDOM_CTR
         AND #$3F       ; Valeur de 0 à 63
         CLC
         ADC #50        ; Gap entre 50 et 113
         STA PIPE1_GAP
         RTS

RESET_PIPE2_GAP:
         LDA RANDOM_CTR
         AND #$3F
         CLC
         ADC #50
         STA PIPE2_GAP
         RTS

; ---------------------------------------------------------
; SOUS-ROUTINE: DESSINER L'OISEAU (14x8 Pixel Art)
; ---------------------------------------------------------
ERASE_BIRD:
         ; TEMP_Y est initialisé avec BIRD_Y_P1 ou BIRD_Y_P2
         LDX #8         ; Hauteur 8 lignes
ER_B_LP: LDA TEMP_Y
         CMP #192
         BCS ER_B_SK
         
         TXA
         PHA
         LDA TEMP_Y
         JSR GET_HGR_ADDR
         
         LDY #7
         LDA #0
         STA (SCR_PTR),Y
         INY
         STA (SCR_PTR),Y
         
         PLA
         TAX
ER_B_SK: INC TEMP_Y
         DEX
         BNE ER_B_LP
         RTS

DRAW_BIRD:
         ; Déterminer quelle page effacer
         LDA DRAW_PG_HI
         CMP #$20
         BEQ ERASE_P1
ERASE_P2:
         LDA BIRD_Y_P2
         STA TEMP_Y
         JSR ERASE_BIRD
         LDA BIRD_Y_HI
         STA BIRD_Y_P2
         JMP DRAW_B_NOW
ERASE_P1:
         LDA BIRD_Y_P1
         STA TEMP_Y
         JSR ERASE_BIRD
         LDA BIRD_Y_HI
         STA BIRD_Y_P1

DRAW_B_NOW:
         LDA BIRD_Y_HI
         CMP #184
         BCS D_B_END
         STA TEMP_Y
         
         LDA #0
         STA SPRITE_ROW
         LDX #8         ; Hauteur 8 lignes
D_B_LP:  LDA TEMP_Y
         CMP #192
         BCS D_B_SK
         
         TXA
         PHA            ; Conserver le compteur de boucle
         
         ; Charger l'index du motif dans le sprite (2 octets par ligne)
         LDA SPRITE_ROW
         ASL A          ; * 2
         TAY
         LDA BIRD_SPRITE,Y
         STA TEMP_VAL1
         LDA BIRD_SPRITE+1,Y
         STA TEMP_VAL2
         
         LDA TEMP_Y
         JSR GET_HGR_ADDR
         
         ; Dessiner le sprite a la colonne 7 et 8
         LDY #7
         LDA TEMP_VAL1
         STA (SCR_PTR),Y
         INY
         LDA TEMP_VAL2
         STA (SCR_PTR),Y
         
         INC SPRITE_ROW
         PLA
         TAX            ; Restaurer le compteur de boucle
D_B_SK:  INC TEMP_Y
         DEX
         BNE D_B_LP
D_B_END: RTS

; ---------------------------------------------------------
; SOUS-ROUTINE: DESSINER LE SCORE (Centré, Haute Resolution)
; ---------------------------------------------------------
DRAW_SCORE:
         JSR CLEAR_SCORE_AREA
         
         ; --- 1. Dessiner le Label "SCORE = " (col 0-6, row 4) ---
         LDA #4
         LDY #0
         LDX #10        ; 'S'
         JSR DRAW_CHAR
         
         LDA #4
         LDY #1
         LDX #11        ; 'C'
         JSR DRAW_CHAR
         
         LDA #4
         LDY #2
         LDX #12        ; 'O'
         JSR DRAW_CHAR
         
         LDA #4
         LDY #3
         LDX #13        ; 'R'
         JSR DRAW_CHAR
         
         LDA #4
         LDY #4
         LDX #14        ; 'E'
         JSR DRAW_CHAR
         
         LDA #4
         LDY #6
         LDX #19        ; '='
         JSR DRAW_CHAR

         ; --- 2. Dessiner le Label "HIGH-SCORE = " (col 25-36, row 4) ---
         LDA #4
         LDY #25
         LDX #15        ; 'H'
         JSR DRAW_CHAR
         
         LDA #4
         LDY #26
         LDX #16        ; 'I'
         JSR DRAW_CHAR
         
         LDA #4
         LDY #27
         LDX #17        ; 'G'
         JSR DRAW_CHAR
         
         LDA #4
         LDY #28
         LDX #15        ; 'H'
         JSR DRAW_CHAR
         
         LDA #4
         LDY #29
         LDX #18        ; '-'
         JSR DRAW_CHAR
         
         LDA #4
         LDY #30
         LDX #10        ; 'S'
         JSR DRAW_CHAR
         
         LDA #4
         LDY #31
         LDX #11        ; 'C'
         JSR DRAW_CHAR
         
         LDA #4
         LDY #32
         LDX #12        ; 'O'
         JSR DRAW_CHAR
         
         LDA #4
         LDY #33
         LDX #13        ; 'R'
         JSR DRAW_CHAR
         
         LDA #4
         LDY #34
         LDX #14        ; 'E'
         JSR DRAW_CHAR
         
         LDA #4
         LDY #36
         LDX #19        ; '='
         JSR DRAW_CHAR

         ; --- 3. Dessiner le Score Courant (col 8-9, row 4) ---
         LDA SCORE
         LDX #0
DIV_LP:  CMP #10
         BCC DIV_DN
         SEC
         SBC #10
         INX
         JMP DIV_LP
DIV_DN:
         CPX #0
         BEQ DRAW_SINGLE_DIGIT
         
         PHA            ; Stocker le chiffre des unites
         TXA
         PHA            ; Stocker le chiffre des dizaines
         LDY #8         ; Colonne 8
         LDA #4         ; Ligne 4
         JSR DRAW_CHAR
         PLA
         TAX
         PLA
         
         LDY #9         ; Colonne 9
         LDA #4         ; Ligne 4
         JSR DRAW_CHAR
         JMP SCORE_DONE
         
DRAW_SINGLE_DIGIT:
         TAX
         LDY #8         ; Colonne 8
         LDA #4         ; Ligne 4
         JSR DRAW_CHAR
         
SCORE_DONE:

         ; --- 4. Dessiner le High Score (col 38-39, row 4) ---
         ; Mettre à jour le High Score si le score courant est plus grand
         LDA SCORE
         CMP HIGH_SCORE
         BCC NO_HS_UPDATE
         STA HIGH_SCORE
NO_HS_UPDATE:

         LDA HIGH_SCORE
         LDX #0
DIV_LP_H: CMP #10
         BCC DIV_DN_H
         SEC
         SBC #10
         INX
         JMP DIV_LP_H
DIV_DN_H:
         CPX #0
         BEQ DRAW_SINGLE_DIGIT_H
         
         PHA            ; Stocker le chiffre des unites
         TXA
         PHA            ; Stocker le chiffre des dizaines
         LDY #38        ; Colonne 38
         LDA #4         ; Ligne 4
         JSR DRAW_CHAR
         PLA
         TAX
         PLA
         
         LDY #39        ; Colonne 39
         LDA #4         ; Ligne 4
         JSR DRAW_CHAR
         JMP HS_DONE
         
DRAW_SINGLE_DIGIT_H:
         TAX
         LDY #38        ; Colonne 38
         LDA #4         ; Ligne 4
         JSR DRAW_CHAR
         
HS_DONE:
         RTS

; --- Helper: Dessin d'un caractere 5x7 ---
; Entree: X = caractere (0-17), Y = colonne (0-39), A = ligne Y (0-191)
DRAW_CHAR:
         STY TEMP_COL
         STA TEMP_ROW
         
         ; Calcul de l'index dans la police (X * 7)
         TXA
         STA DIGIT_PTR
         ASL A          ; 2X
         ASL A          ; 4X
         ASL A          ; 8X
         SEC
         SBC DIGIT_PTR  ; 7X
         TAX
         
         LDY #0
DRAW_D_LP:
         TYA
         PHA            ; Conserver l'index de ligne locale (0-6)
         
         LDA DIGIT_FONT,X
         STA TEMP_VAL
         
         TXA
         PHA            ; Proteger l'index de police
         
         LDA TEMP_ROW
         JSR GET_HGR_ADDR
         
         PLA
         TAX            ; Restaurer l'index
         
         LDY TEMP_COL
         LDA TEMP_VAL
         STA (SCR_PTR),Y
         
         INC TEMP_ROW
         INX
         PLA
         TAY
         INY
         CPY #7
         BNE DRAW_D_LP
         RTS

; ---------------------------------------------------------
; DONNEES DES SPRITES ET DE LA POLICE NUMERIQUE
; ---------------------------------------------------------
BIRD_SPRITE:
         .byte $78, $03  ; Ligne 0: Dessus de la tete
         .byte $7C, $09  ; Ligne 1: Oeil
         .byte $7E, $39  ; Ligne 2: Oeil & Bec
         .byte $7E, $3F  ; Ligne 3: Bec
         .byte $43, $0F  ; Ligne 4: Aile
         .byte $43, $07  ; Ligne 5: Aile
         .byte $7E, $03  ; Ligne 6: Corps
         .byte $78, $01  ; Ligne 7: Bas du corps

DIGIT_FONT:
         .byte $1C, $22, $22, $22, $22, $22, $1C  ; 0
         .byte $08, $0C, $08, $08, $08, $08, $1C  ; 1
         .byte $1C, $22, $20, $0C, $04, $02, $3E  ; 2
         .byte $1C, $22, $20, $1C, $20, $22, $1C  ; 3
         .byte $22, $22, $22, $3E, $20, $20, $20  ; 4
         .byte $3E, $02, $1E, $20, $20, $22, $1C  ; 5
         .byte $1C, $02, $1E, $22, $22, $22, $1C  ; 6
         .byte $3E, $20, $10, $08, $04, $04, $04  ; 7
         .byte $1C, $22, $22, $1C, $22, $22, $1C  ; 8
         .byte $1C, $22, $22, $3C, $20, $22, $1C  ; 9
         .byte $1C, $22, $02, $1C, $20, $22, $1C  ; S (10)
         .byte $1C, $22, $02, $02, $02, $22, $1C  ; C (11)
         .byte $1C, $22, $22, $22, $22, $22, $1C  ; O (12)
         .byte $1E, $22, $22, $1E, $0A, $12, $22  ; R (13)
         .byte $3E, $02, $02, $1E, $02, $02, $3E  ; E (14)
         .byte $22, $22, $22, $3E, $22, $22, $22  ; H (15)
         .byte $3E, $08, $08, $08, $08, $08, $3E  ; I (16)
         .byte $1C, $22, $02, $32, $22, $22, $1C  ; G (17)
         .byte $00, $00, $00, $1C, $00, $00, $00  ; - (18)
         .byte $00, $00, $1C, $00, $1C, $00, $00  ; = (19)


; ---------------------------------------------------------
; TABLES DE LOOKUP HGR CORRETES (192 Lignes)
; ---------------------------------------------------------
HGR_LO:
         .byte $00, $00, $00, $00, $00, $00, $00, $00, $80, $80, $80, $80, $80, $80, $80, $80
         .byte $00, $00, $00, $00, $00, $00, $00, $00, $80, $80, $80, $80, $80, $80, $80, $80
         .byte $00, $00, $00, $00, $00, $00, $00, $00, $80, $80, $80, $80, $80, $80, $80, $80
         .byte $00, $00, $00, $00, $00, $00, $00, $00, $80, $80, $80, $80, $80, $80, $80, $80
         .byte $28, $28, $28, $28, $28, $28, $28, $28, $a8, $a8, $a8, $a8, $a8, $a8, $a8, $a8
         .byte $28, $28, $28, $28, $28, $28, $28, $28, $a8, $a8, $a8, $a8, $a8, $a8, $a8, $a8
         .byte $28, $28, $28, $28, $28, $28, $28, $28, $a8, $a8, $a8, $a8, $a8, $a8, $a8, $a8
         .byte $28, $28, $28, $28, $28, $28, $28, $28, $a8, $a8, $a8, $a8, $a8, $a8, $a8, $a8
         .byte $50, $50, $50, $50, $50, $50, $50, $50, $d0, $d0, $d0, $d0, $d0, $d0, $d0, $d0
         .byte $50, $50, $50, $50, $50, $50, $50, $50, $d0, $d0, $d0, $d0, $d0, $d0, $d0, $d0
         .byte $50, $50, $50, $50, $50, $50, $50, $50, $d0, $d0, $d0, $d0, $d0, $d0, $d0, $d0
         .byte $50, $50, $50, $50, $50, $50, $50, $50, $d0, $d0, $d0, $d0, $d0, $d0, $d0, $d0

HGR_HI:
         .byte $00, $04, $08, $0c, $10, $14, $18, $1c, $00, $04, $08, $0c, $10, $14, $18, $1c
         .byte $01, $05, $09, $0d, $11, $15, $19, $1d, $01, $05, $09, $0d, $11, $15, $19, $1d
         .byte $02, $06, $0a, $0e, $12, $16, $1a, $1e, $02, $06, $0a, $0e, $12, $16, $1a, $1e
         .byte $03, $07, $0b, $0f, $13, $17, $1b, $1f, $03, $07, $0b, $0f, $13, $17, $1b, $1f
         .byte $00, $04, $08, $0c, $10, $14, $18, $1c, $00, $04, $08, $0c, $10, $14, $18, $1c
         .byte $01, $05, $09, $0d, $11, $15, $19, $1d, $01, $05, $09, $0d, $11, $15, $19, $1d
         .byte $02, $06, $0a, $0e, $12, $16, $1a, $1e, $02, $06, $0a, $0e, $12, $16, $1a, $1e
         .byte $03, $07, $0b, $0f, $13, $17, $1b, $1f, $03, $07, $0b, $0f, $13, $17, $1b, $1f
         .byte $00, $04, $08, $0c, $10, $14, $18, $1c, $00, $04, $08, $0c, $10, $14, $18, $1c
         .byte $01, $05, $09, $0d, $11, $15, $19, $1d, $01, $05, $09, $0d, $11, $15, $19, $1d
         .byte $02, $06, $0a, $0e, $12, $16, $1a, $1e, $02, $06, $0a, $0e, $12, $16, $1a, $1e
         .byte $03, $07, $0b, $0f, $13, $17, $1b, $1f, $03, $07, $0b, $0f, $13, $17, $1b, $1f