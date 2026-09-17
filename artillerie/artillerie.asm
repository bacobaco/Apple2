; =============================================================================
; JEU D'ARTILLERIE POUR APPLE II (COMPATIBLE 64TASS)
; Code implanté en $6000
; =============================================================================

; --- Constantes ROM Apple II ---
TEXT_ROM    = $FB2F     ; Passage en mode texte full screen standard
HGR_ROM     = $F3E2     ; Init Hires, Page 1, Mixte et efface en noir
HCOLOR      = $F6F0     ; Fixe la couleur HGR (X = code couleur)
HPLOT       = $F457     ; Trace un point (A=Y, X=X_low, Y=X_high)
HPOSN       = $F411     ; Positionne le curseur HGR (A=Y, X=X_low, Y=X_high)
HGLINE      = $F53A     ; Trace une ligne depuis le curseur (X=dest_X_high, A=dest_X_low, Y=dest_Y)

TXTSET      = $C051     ; Mode texte
COUT        = $FDED     ; Print caractere dans A

; Pointers Zero-Page temporaires pour les tables
PTR_LO      = $06
PTR_HI      = $07
PTR2_LO     = $08
PTR2_HI     = $09

* = $4000

Start:
    TSX
    STX SAVED_SP
    JSR TEXT_ROM        ; S'assure d'être en mode texte propre au départ
    JSR ShowTitle
    JSR InitGraphics
    JSR InitTextWindow
    
NewGame:
    LDX SAVED_SP
    TXS
    LDA #1
    STA ROUND_NUM
    LDA #0
    STA SCORE_LO
    STA SCORE_HI
    STA HIT_COUNT
    STA P2_SCORE_LO
    STA P2_SCORE_HI
    STA P2_HIT_COUNT
    
NewRound:
    LDA #0
    STA SHOT_COUNT
    STA P1_SHOT_COUNT
    STA P2_SHOT_COUNT
    STA IS_CPU_TURN
    STA P1_BUF1_LEN
    STA P2_BUF1_LEN
    STA SELF_HIT
    JSR GetRandomCanonX
    JSR GetRandomTargetX
    JSR GenerateWind
    LDA RANDOM_SEED
    STA STAR_SEED
    LDA RANDOM_SEED+1
    STA STAR_SEED+1
    
    ; Initialisation des variables de tir CPU
    ; Angle aléatoire entre 40 et 55 degrés
    LDA RANDOM_SEED
    AND #15
    CLC
    ADC #40
    STA CPU_ANGLE
    
    ; Puissance aléatoire entre 70 et 100
    LDA RANDOM_SEED+1
    AND #31
    CLC
    ADC #70
    STA CPU_POWER
    
    JSR HGR_ROM         ; Efface l'écran et passe en mode mixte
    JSR GenerateTerrain
    JSR DrawStars       ; Ajoute du fun avec des étoiles dans le ciel
    JSR PlaceEntities
    
RoundLoop:
    LDA IS_CPU_TURN
    BNE _p2_erase
    
    ; Player 1 turn: Erase P1_BUF1, reset P1_BUF1_LEN
    JSR EraseP1Buf1
    LDA #0
    STA P1_BUF1_LEN
    JMP _erase_done
    
_p2_erase:
    ; Player 2 / CPU turn: Erase P2_BUF1, reset P2_BUF1_LEN
    JSR EraseP2Buf1
    LDA #0
    STA P2_BUF1_LEN
    
_erase_done:
    JSR RedrawActiveTrajectories
    JSR PlaceEntities           ; Redraw tanks & barrels

    LDA IS_CPU_TURN
    BEQ P1Turn
    
    LDA GAME_MODE
    BNE P2Turn
    JMP CPURound
    
P1Turn:
    JSR GetInput        ; Saisie de l'angle et de la force, attend Espace/Entrée
    INC P1_SHOT_COUNT
    JSR CalcVelocities  ; Calcule V_X et V_Y à partir d'ANGLE et POWER
    JSR FireProjectile  ; Simule le tir
    BCC +
    LDA SELF_HIT
    BNE P1SelfHit
    JMP HitTarget       ; Carry set = Touche !
+   
    ; Si raté ou hors limites
    JSR ClearStatusLine
    LDA RESULT
    BEQ MsgMissed
    
    ; Hors limites
    LDA #<MSG_OUT
    STA $06
    LDA #>MSG_OUT
    STA $07
    JMP PrintResult
    
MsgMissed:
    LDA GAME_MODE
    BNE P1MissPvP
    LDA #<MSG_MISS
    STA $06
    LDA #>MSG_MISS
    STA $07
    JMP PrintResult
P1MissPvP:
    LDA #<MSG_P1_MISS
    STA $06
    LDA #>MSG_P1_MISS
    STA $07
    
PrintResult:
    JSR PrintString
    JSR Delay2Seconds
    
    ; Passe le tour à l'ordinateur/J2
    LDA #1
    STA IS_CPU_TURN
    JMP RoundLoop

P1SelfHit:
    JSR ClearStatusLine
    JSR ExplodePlayerTank
    LDA #<MSG_SELF_HIT
    STA $06
    LDA #>MSG_SELF_HIT
    STA $07
    JSR PrintString
    JSR Delay2Seconds
    LDA #1
    STA IS_CPU_TURN
    JMP RoundLoop

P2Turn:
    JMP P2Round

CPURound:
    JSR CPULogic        ; Affiche les choix de visée du CPU
    INC P2_SHOT_COUNT
    JSR CalcVelocities  ; Calcule V_X et V_Y à partir de CPU_ANGLE/CPU_POWER
    JSR FireProjectile
    BCC +
    LDA SELF_HIT
    BNE CPUSelfHit
    JMP HitPlayer       ; Carry set = Ordi a touché le joueur !
+
    
    ; Ordi a raté
    JSR ClearStatusLine
    JSR AdjustCPUPower  ; Ajuste la puissance du CPU pour affiner sa visée (même hors limites)
    
    LDA RESULT
    BEQ MsgCPUMissed
    
    ; Hors limites
    LDA #<MSG_OUT
    STA $06
    LDA #>MSG_OUT
    STA $07
    JMP PrintCPUResult
    
MsgCPUMissed:
    LDA #<MSG_CPU_MISS
    STA $06
    LDA #>MSG_CPU_MISS
    STA $07
    
PrintCPUResult:
    JSR PrintString
    JSR Delay2Seconds
    LDA #0
    STA IS_CPU_TURN     ; Retour au joueur
    JMP RoundLoop

CPUSelfHit:
    JSR ClearStatusLine
    JSR ExplodeEnemyTank
    LDA #<MSG_CPU_SELF_HIT
    STA $06
    LDA #>MSG_CPU_SELF_HIT
    STA $07
    JSR PrintString
    JSR Delay2Seconds
    LDA #0
    STA IS_CPU_TURN
    JMP RoundLoop

HitTarget:
    ; Le joueur a touché le CPU / J2 !
    JSR ClearStatusLine
    JSR ExplodeEnemyTank
    LDA GAME_MODE
    BNE _p1_hit_pvp
    LDA #<MSG_HIT
    STA $06
    LDA #>MSG_HIT
    STA $07
    JMP _print_hit
_p1_hit_pvp:
    LDA #<MSG_P1_HIT
    STA $06
    LDA #>MSG_P1_HIT
    STA $07
_print_hit:
    JSR PrintString
    
    ; Calcul des points propres à J1
    LDA P1_SHOT_COUNT
    SEC
    SBC #1
    STA TEMP_VAL
    
    LDA TEMP_VAL
    STA MULT1
    LDA #100
    STA MULT2
    JSR Multiply8_8     ; NUM = (P1_SHOT_COUNT - 1) * 100
    
    ; Points = 1000 - NUM
    LDA #$E8
    SEC
    SBC NUM
    STA POINTS_LO
    LDA #$03
    SBC NUM+1
    STA POINTS_HI
    
    ; Si Points < 100, Points = 100 ($0064)
    LDA POINTS_HI
    BNE +
    LDA POINTS_LO
    CMP #100
    BCS +
    LDA #100
    STA POINTS_LO
    LDA #0
    STA POINTS_HI
+   
    ; Ajoute points au score
    CLC
    LDA SCORE_LO
    ADC POINTS_LO
    STA SCORE_LO
    LDA SCORE_HI
    ADC POINTS_HI
    STA SCORE_HI
    
    INC HIT_COUNT
    JSR Delay2Seconds
    
    ; Check si 5 manches terminées
    LDA ROUND_NUM
    CMP #5
    BNE +
    JMP GameOver
+   
    INC ROUND_NUM
    JMP NewRound

HitPlayer:
    ; L'ordinateur/J2 a touché J1 !
    JSR ClearStatusLine
    JSR ExplodePlayerTank
    LDA GAME_MODE
    BNE _p2_hit_pvp
    LDA #<MSG_CPU_HIT
    STA $06
    LDA #>MSG_CPU_HIT
    STA $07
    JMP _print_cpu_hit
_p2_hit_pvp:
    LDA #<MSG_P2_HIT
    STA $06
    LDA #>MSG_P2_HIT
    STA $07
_print_cpu_hit:
    JSR PrintString
    
    ; Calcul des points pour J2/CPU propres à ses tirs
    LDA P2_SHOT_COUNT
    SEC
    SBC #1
    STA TEMP_VAL
    
    LDA TEMP_VAL
    STA MULT1
    LDA #100
    STA MULT2
    JSR Multiply8_8     ; NUM = (P2_SHOT_COUNT - 1) * 100
    
    ; Points = 1000 - NUM
    LDA #$E8
    SEC
    SBC NUM
    STA POINTS_LO
    LDA #$03
    SBC NUM+1
    STA POINTS_HI
    
    ; Si Points < 100, Points = 100
    LDA POINTS_HI
    BNE +
    LDA POINTS_LO
    CMP #100
    BCS +
    LDA #100
    STA POINTS_LO
    LDA #0
    STA POINTS_HI
+   
    ; Ajoute points au score de J2/CPU
    CLC
    LDA P2_SCORE_LO
    ADC POINTS_LO
    STA P2_SCORE_LO
    LDA P2_SCORE_HI
    ADC POINTS_HI
    STA P2_SCORE_HI
    
    INC P2_HIT_COUNT
    JSR Delay2Seconds
    
    ; Check si 5 manches terminées
    LDA ROUND_NUM
    CMP #5
    BNE +
    JMP GameOver
+   
    INC ROUND_NUM
    JMP NewRound

GameOver:
    JSR TEXT_ROM        ; Repasse en texte pur propre
    JSR $FC58           ; HOME
    
    ; Title
    LDA #6
    JSR VTAB
    LDA #8
    STA $24             ; CH
    LDA #<MSG_GAMEOVER
    STA $06
    LDA #>MSG_GAMEOVER
    STA $07
    JSR PrintString
    
    ; Player 1 Stats on Line 10
    LDA #10
    JSR VTAB
    LDA #3
    STA $24
    LDA #<MSG_J1_FINAL
    STA $06
    LDA #>MSG_J1_FINAL
    STA $07
    JSR PrintString
    JSR PrintScore
    
    LDA #<MSG_FINAL_HITS
    STA $06
    LDA #>MSG_FINAL_HITS
    STA $07
    JSR PrintString
    LDA HIT_COUNT
    ORA #$B0
    JSR COUT
    LDA #<MSG_OF5_GAME
    STA $06
    LDA #>MSG_OF5_GAME
    STA $07
    JSR PrintString
    
    ; Player 2 / CPU Stats on Line 12
    LDA #12
    JSR VTAB
    LDA #3
    STA $24
    
    LDA GAME_MODE
    BNE _p2_final_text
    LDA #<MSG_CPU_FINAL
    STA $06
    LDA #>MSG_CPU_FINAL
    STA $07
    JSR PrintString
    JMP _p2_final_score
_p2_final_text:
    LDA #<MSG_J2_FINAL
    STA $06
    LDA #>MSG_J2_FINAL
    STA $07
    JSR PrintString
    
_p2_final_score:
    JSR PrintScoreP2
    
    LDA #<MSG_FINAL_HITS
    STA $06
    LDA #>MSG_FINAL_HITS
    STA $07
    JSR PrintString
    LDA P2_HIT_COUNT
    ORA #$B0
    JSR COUT
    LDA #<MSG_OF5_GAME
    STA $06
    LDA #>MSG_OF5_GAME
    STA $07
    JSR PrintString
    
    ; Winner Announcement on Line 15
    LDA #15
    JSR VTAB
    LDA #0
    STA $24
    
    ; Compare scores
    LDA SCORE_HI
    CMP P2_SCORE_HI
    BNE _not_equal
    LDA SCORE_LO
    CMP P2_SCORE_LO
    BNE _not_equal
    
    ; Equal score!
    LDA #<MSG_DRAW
    STA $06
    LDA #>MSG_DRAW
    STA $07
    JSR PrintString
    JMP _show_replay
    
_not_equal:
    BCS _j1_wins
    
    ; J2/CPU wins
    LDA GAME_MODE
    BNE _j2_real_wins
    LDA #<MSG_CPU_WINS
    STA $06
    LDA #>MSG_CPU_WINS
    STA $07
    JSR PrintString
    JMP _show_replay
_j2_real_wins:
    LDA #<MSG_J2_WINS
    STA $06
    LDA #>MSG_J2_WINS
    STA $07
    JSR PrintString
    JMP _show_replay
    
_j1_wins:
    LDA GAME_MODE
    BNE _j1_real_wins
    LDA #<MSG_YOU_WIN
    STA $06
    LDA #>MSG_YOU_WIN
    STA $07
    JSR PrintString
    JMP _show_replay
_j1_real_wins:
    LDA #<MSG_J1_WINS
    STA $06
    LDA #>MSG_J1_WINS
    STA $07
    JSR PrintString
    
_show_replay:
    ; Replay on Line 18
    LDA #18
    JSR VTAB
    LDA #12
    STA $24
    LDA #<MSG_REPLAY
    STA $06
    LDA #>MSG_REPLAY
    STA $07
    JSR PrintString
    
WaitReplay:
    LDA $C000
    BPL WaitReplay
    PHA
    BIT $C010
    PLA
    AND #$7F
    CMP #$4F            ; 'O'
    BEQ StartNewGame
    CMP #$6F            ; 'o'
    BEQ StartNewGame
    CMP #$4E            ; 'N'
    BEQ ExitToBasic
    CMP #$6E            ; 'n'
    BEQ ExitToBasic
    JMP WaitReplay

StartNewGame:
    JSR ShowTitle
    JSR InitTextWindow
    JMP NewGame

ExitToBasic:
    JSR TEXT_ROM
    JSR RestoreTextWindow
    JSR $FC58
    JMP $E003

; =============================================================================
; ÉCRAN DE TITRE
; =============================================================================
ShowTitle:
    JSR TEXT_ROM
    JSR $FC58           ; HOME
    
    ; Title
    LDA #4
    JSR VTAB           ; TABV
    LDA #9
    STA $24             ; CH
    LDA #<MSG_TITLE1
    STA $06
    LDA #>MSG_TITLE1
    STA $07
    JSR PrintString
    
    ; Mode 1
    LDA #8
    JSR VTAB
    LDA #8
    STA $24
    LDA #<MSG_MODE1
    STA $06
    LDA #>MSG_MODE1
    STA $07
    JSR PrintString
    
    ; Mode 2
    LDA #10
    JSR VTAB
    LDA #8
    STA $24
    LDA #<MSG_MODE2
    STA $06
    LDA #>MSG_MODE2
    STA $07
    JSR PrintString
    
    LDA #14
    JSR VTAB
    LDA #8
    STA $24
    LDA #<MSG_CHOICE
    STA $06
    LDA #>MSG_CHOICE
    STA $07
    JSR PrintString
    
    ; Version et copyright en bas d'écran
    LDA #23
    JSR VTAB
    LDA #2
    STA $24
    LDA #<MSG_VERSION
    STA $06
    LDA #>MSG_VERSION
    STA $07
    JSR PrintString
    
    LDA #23
    JSR VTAB
    LDA #26
    STA $24
    LDA #<MSG_COPYRIGHT
    STA $06
    LDA #>MSG_COPYRIGHT
    STA $07
    JSR PrintString
    
WaitMode:
    INC RANDOM_SEED
    BNE +
    INC RANDOM_SEED+1
+   LDA $C000
    BPL WaitMode
    PHA
    BIT $C010
    PLA
    AND #$7F
    
    CMP #$31            ; '1'
    BEQ SetPVE
    CMP #$32            ; '2'
    BEQ SetPVP
    JMP WaitMode

SetPVE:
    LDA #0
    STA GAME_MODE
    JMP ShowTerrainMenu

SetPVP:
    LDA #1
    STA GAME_MODE
    ; fall through to ShowTerrainMenu

ShowTerrainMenu:
    JSR $FC58           ; HOME
    
    ; Title
    LDA #4
    JSR VTAB
    LDA #9
    STA $24
    LDA #<MSG_TERRAIN_T
    STA $06
    LDA #>MSG_TERRAIN_T
    STA $07
    JSR PrintString
    
    ; Option 1
    LDA #8
    JSR VTAB
    LDA #8
    STA $24
    LDA #<MSG_TERRAIN_1
    STA $06
    LDA #>MSG_TERRAIN_1
    STA $07
    JSR PrintString
    
    ; Option 2
    LDA #10
    JSR VTAB
    LDA #8
    STA $24
    LDA #<MSG_TERRAIN_2
    STA $06
    LDA #>MSG_TERRAIN_2
    STA $07
    JSR PrintString
    
    ; Option 3
    LDA #12
    JSR VTAB
    LDA #8
    STA $24
    LDA #<MSG_TERRAIN_3
    STA $06
    LDA #>MSG_TERRAIN_3
    STA $07
    JSR PrintString
    
    LDA #16
    JSR VTAB
    LDA #6
    STA $24
    LDA #<MSG_TERRAIN_C
    STA $06
    LDA #>MSG_TERRAIN_C
    STA $07
    JSR PrintString
    
    ; Version et copyright en bas d'écran
    LDA #23
    JSR VTAB
    LDA #2
    STA $24
    LDA #<MSG_VERSION
    STA $06
    LDA #>MSG_VERSION
    STA $07
    JSR PrintString
    
    LDA #23
    JSR VTAB
    LDA #26
    STA $24
    LDA #<MSG_COPYRIGHT
    STA $06
    LDA #>MSG_COPYRIGHT
    STA $07
    JSR PrintString

WaitTerrain:
    INC RANDOM_SEED
    BNE +
    INC RANDOM_SEED+1
+   LDA $C000
    BPL WaitTerrain
    PHA
    BIT $C010
    PLA
    AND #$7F
    
    CMP #$31            ; '1'
    BEQ SetPlaine
    CMP #$32            ; '2'
    BEQ SetColline
    CMP #$33            ; '3'
    BEQ SetMontagne
    JMP WaitTerrain

SetPlaine:
    LDA #6
    STA AMP1
    LDA #5
    STA AMP2
    LDA #4
    STA AMP3
    LDA #3
    STA AMP4
    RTS

SetColline:
    LDA #16
    STA AMP1
    LDA #12
    STA AMP2
    LDA #10
    STA AMP3
    LDA #7
    STA AMP4
    RTS

SetMontagne:
    LDA #28
    STA AMP1
    LDA #22
    STA AMP2
    LDA #18
    STA AMP3
    LDA #12
    STA AMP4
    RTS

; =============================================================================
; INITIALISATION FENÊTRE DE TEXTE ET EFFACEMENT DE LIGNE
; =============================================================================
InitTextWindow:
    LDA #20
    STA $22             ; WNDTOP = 20
    JSR $FC58           ; HOME
    RTS

RestoreTextWindow:
    LDA #0
    STA $22             ; WNDTOP = 0
    RTS

ClearStatusLine:
    LDA #20
    STA TEMP_VAL
_clear_hud_loop:
    LDA TEMP_VAL
    JSR VTAB
    LDA #0
    STA $24
    JSR $FC9C           ; CLEOL
    INC TEMP_VAL
    LDA TEMP_VAL
    CMP #24
    BNE _clear_hud_loop
    
    LDA #20
    JSR VTAB
    LDA #0
    STA $24
    RTS
; =============================================================================
; GRAPHIQUES ET TERRAIN
; =============================================================================
InitGraphics:
    JSR HGR_ROM
    RTS

; --- Génération du terrain ---
GenerateTerrain:
    ; Randomize initial phases of the waves
    LDA RANDOM_SEED
    STA ACC1
    LDA RANDOM_SEED+1
    STA ACC1+1
    
    LDA RANDOM_SEED
    EOR #$55
    STA ACC2
    LDA RANDOM_SEED+1
    EOR #$AA
    STA ACC2+1
    
    LDA RANDOM_SEED
    EOR #$33
    STA ACC3
    LDA RANDOM_SEED+1
    EOR #$CC
    STA ACC3+1
    
    LDA RANDOM_SEED
    EOR #$0F
    STA ACC4
    LDA RANDOM_SEED+1
    EOR #$F0
    STA ACC4+1
    
    LDX #0              ; X_low démarre à 0
    STX X_HI            ; X_high démarre à 0
LoopTerrain:
    STX TEMP            ; Sauvegarde X_low
    
    ; Compute height using sines
    LDA #100
    STA CUR_HEIGHT
    
    LDA ACC1+1
    LDX AMP1
    JSR AddWave
    
    LDA ACC2+1
    LDX AMP2
    JSR AddWave
    
    LDA ACC3+1
    LDX AMP3
    JSR AddWave
    
    LDA ACC4+1
    LDX AMP4
    JSR AddWave
    
    ; Clamp to 40..150
    LDA CUR_HEIGHT
    CMP #40
    BCS _clamp_hi
    LDA #40
    JMP _clamp_done
_clamp_hi
    CMP #150
    BCC _clamp_done
    LDA #150
_clamp_done
    
    ; Store height in TERRAIN_Y
    LDY X_HI
    BNE _store_hi_1
    ; X_HI == 0
    LDX TEMP
    STA TERRAIN_Y,X
    JMP _store_done
_store_hi_1
    ; X_HI == 1
    LDX TEMP
    STA TERRAIN_Y+256,X
_store_done
    
    ; Update wave accumulators
    ; ACC1 += 234
    CLC
    LDA ACC1
    ADC #234
    STA ACC1
    LDA ACC1+1
    ADC #0
    STA ACC1+1
    
    ; ACC2 += 936 (high: 3, low: 168)
    CLC
    LDA ACC2
    ADC #168
    STA ACC2
    LDA ACC2+1
    ADC #3
    STA ACC2+1
    
    ; ACC3 += 2106 (high: 8, low: 58)
    CLC
    LDA ACC3
    ADC #58
    STA ACC3
    LDA ACC3+1
    ADC #8
    STA ACC3+1
    
    ; ACC4 += 4212 (high: 16, low: 116)
    CLC
    LDA ACC4
    ADC #116
    STA ACC4
    LDA ACC4+1
    ADC #16
    STA ACC4+1
    
    ; Increment X coordinates
    LDX TEMP
    INX
    BNE _skip_inc_hi
    INC X_HI
_skip_inc_hi
    
    LDA X_HI
    CMP #1
    BEQ _check_x_limit
    JMP LoopTerrain
_check_x_limit
    CPX #24             ; Arrêt à X = 280 (256 + 24)
    BEQ _gen_done
    JMP LoopTerrain
_gen_done
    JSR FlattenPlatforms
    JSR DrawTerrain
    RTS

FlattenPlatforms:
    ; 1. Plat pour Player 1 autour de CANON_X (de CANON_X - 10 à CANON_X + 10)
    LDA CANON_X
    SEC
    SBC #10
    TAX              ; Index de début
    
    LDA CANON_X
    CLC
    ADC #11          ; Fin + 1
    STA TEMP_HI
    
    LDY CANON_X
    LDA TERRAIN_Y,Y  ; Y plateforme P1
    
_flat_p1_loop:
    STA TERRAIN_Y,X
    INX
    CPX TEMP_HI
    BNE _flat_p1_loop

    ; 2. Plat pour Player 2 autour de CIBLE_X
    ; Début X = CIBLE_X - 10
    SEC
    LDA CIBLE_X
    SBC #10
    STA CUR_X_LO
    LDA CIBLE_X+1
    SBC #0
    STA CUR_X_HI
    
    ; Fin X = CIBLE_X + 11
    CLC
    LDA CIBLE_X
    ADC #11
    STA TEMP_LO
    LDA CIBLE_X+1
    ADC #0
    STA TEMP_HI
    
    ; Hauteur cible
    LDX CIBLE_X
    LDY CIBLE_X+1
    JSR GetHeight
    STA TEMP_VAL     ; Hauteur plateforme P2
    
_flat_p2_loop:
    LDX CUR_X_LO
    LDY CUR_X_HI
    BEQ _flat_p2_lo
    ; HI == 1
    LDA TEMP_VAL
    STA TERRAIN_Y+256,X
    JMP _flat_p2_next
_flat_p2_lo:
    LDA TEMP_VAL
    STA TERRAIN_Y,X
    
_flat_p2_next:
    INC CUR_X_LO
    BNE +
    INC CUR_X_HI
+  
    LDA CUR_X_LO
    CMP TEMP_LO
    BNE _flat_p2_loop
    LDA CUR_X_HI
    CMP TEMP_HI
    BNE _flat_p2_loop
    RTS

DrawTerrain:
    LDX #0              ; X_low = 0
    STX X_HI            ; X_high = 0
_draw_loop:
    STX TEMP            ; Sauvegarde X_low
    
    LDY X_HI
    BNE _get_hi_1
    LDA TERRAIN_Y,X
    JMP _get_done
_get_hi_1:
    LDA TERRAIN_Y+256,X
_get_done:
    STA START_Y          ; Start Y (surface)
    
    ; 1. Dessine l'herbe (Grass = Vert = 1)
    LDX #1
    JSR HCOLOR
    
    ; dest_Y = START_Y + 3
    LDA START_Y
    CLC
    ADC #3
    CMP #160
    BCC +
    LDA #159
+   STA TEMP_Y           ; TEMP_Y = dest_Y pour l'herbe
    
    ; Positionne le curseur a (X, START_Y)
    LDA START_Y
    LDX TEMP             ; X_low
    LDY X_HI             ; X_high
    JSR HPOSN
    
    ; Trace la ligne verticale jusqu'a TEMP_Y
    LDA TEMP             ; dest_X_low
    LDY TEMP_Y           ; dest_Y
    LDX X_HI             ; dest_X_high
    JSR HGLINE
    
    ; 2. Dessine la roche (Rock = Violet = 2)
    ; Check si START_Y + 4 < 160
    LDA START_Y
    CLC
    ADC #4
    CMP #160
    BCS _column_done     ; Si >= 160, pas de roche visible
    STA TEMP_Y           ; TEMP_Y = Y de debut de la roche
    
    LDX #2               ; Violet
    JSR HCOLOR
    
    ; Positionne le curseur a (X, START_Y + 4)
    LDA TEMP_Y
    LDX TEMP
    LDY X_HI
    JSR HPOSN
    
    ; Trace la ligne verticale jusqu'au bas de l'ecran (159)
    LDA TEMP             ; dest_X_low
    LDY #159             ; dest_Y
    LDX X_HI             ; dest_X_high
    JSR HGLINE
    
_column_done:
    LDX TEMP
    INX
    BNE _skip_inc_hi_draw
    INC X_HI
_skip_inc_hi_draw:
    LDA X_HI
    CMP #1
    BEQ _check_x_limit_draw
    JMP _draw_loop
_check_x_limit_draw:
    CPX #24
    BNE _draw_loop
    RTS

; --- Fonction de hauteur par lookup array ---
; Input: X = X_low, Y = X_high
; Output: A = Hauteur (Y coord)
GetHeight:
    CPY #0
    BNE _check_hi_1
    ; X_high == 0, index is X (0..255)
    LDA TERRAIN_Y,X
    RTS
_check_hi_1
    CPY #1
    BNE OutOfBoundsHeight
    CPX #24
    BCS OutOfBoundsHeight
    ; X_high == 1, index is 256 + X (256..279)
    LDA TERRAIN_Y+256,X
    RTS
OutOfBoundsHeight:
    LDA #159         ; Bottom of screen/default
    RTS

; --- Placement et dessin des Canons (Joueur et CPU) ---
PlaceEntities:
    JSR DrawPlayerTank
    JSR DrawCPUTank
    JSR DrawPlatforms
    
    ; Dessin initial du canon joueur en blanc
    LDX #$03
    JSR DrawPlayerBarrel
    
    ; Dessin initial du canon CPU en orange
    LDX #$05
    JSR DrawCPUBarrel
    RTS

; --- Dessin des étoiles dans le ciel ---
DrawStars:
    ; Fixe la couleur HGR en blanc (3)
    LDX #3
    JSR HCOLOR
    
    ; Initialise l'état LFSR interne pour le tirage des étoiles à partir du RANDOM_SEED actuel
    LDA STAR_SEED
    STA TEMP_LO
    LDA STAR_SEED+1
    STA TEMP_HI
    ORA TEMP_LO
    BNE +
    LDA #$A5
    STA TEMP_LO
    LDA #$5A
    STA TEMP_HI
+
    
    LDX #20             ; Dessine 20 étoiles
_star_loop:
    STX TEMP_VAL
    
    ; Génère coordonnée X aléatoire (0..279)
    JSR _next_rand
    LDA TEMP_LO
    STA STAR_X_LO
    JSR _next_rand
    LDA TEMP_LO
    AND #1
    STA STAR_X_HI
    
    ; Vérification des limites x (0..279)
    LDA STAR_X_HI
    BEQ _star_x_ok
    LDA STAR_X_LO
    CMP #24
    BCC _star_x_ok
    
    ; Si X >= 280, on retranche 24 pour le faire rentrer dans la zone écran 0..279
    LDA STAR_X_LO
    SEC
    SBC #24
    STA STAR_X_LO
_star_x_ok:
    
    ; Génère coordonnée Y aléatoire (10..60) dans la moitié haute du ciel
    JSR _next_rand
    LDA TEMP_LO
    AND #63
    CLC
    ADC #10
    STA STAR_Y_VAL
    
    ; Vérification si le point Y est bien dans le ciel (au-dessus du terrain)
    LDX STAR_X_LO
    LDY STAR_X_HI
    JSR GetHeight
    CMP STAR_Y_VAL
    BCC _skip_star      ; Si terrain Y <= STAR_Y_VAL (terrain plus haut), on saute l'étoile
    
    ; Affiche l'étoile en blanc
    LDA STAR_Y_VAL
    LDX STAR_X_LO
    LDY STAR_X_HI
    JSR HPLOT
    
_skip_star:
    LDX TEMP_VAL
    DEX
    BNE _star_loop
    RTS

_next_rand:
    ; LFSR simple pour le bruit blanc
    LDA TEMP_LO
    LSR
    STA TEMP_LO
    LDA TEMP_HI
    ROR
    STA TEMP_HI
    BCC +
    LDA TEMP_LO
    EOR #$95
    STA TEMP_LO
+   RTS

; --- Dessin des plateformes ---
DrawPlatforms:
    ; Plateforme Player 1 (Blanc = 3)
    LDX #$03            ; Couleur Blanche
    JSR HCOLOR
    
    ; Ligne 1 à CANON_Y + 1
    LDA CANON_Y
    CLC
    ADC #1
    PHA
    LDA CANON_X
    SEC
    SBC #10
    TAX
    LDY #0
    PLA
    JSR HPOSN
    
    LDA CANON_X
    CLC
    ADC #10
    PHA
    LDA CANON_Y
    CLC
    ADC #1
    TAY
    PLA
    LDX #0
    JSR HGLINE
    
    ; Ligne 2 à CANON_Y + 2
    LDA CANON_Y
    CLC
    ADC #2
    PHA
    LDA CANON_X
    SEC
    SBC #10
    TAX
    LDY #0
    PLA
    JSR HPOSN
    
    LDA CANON_X
    CLC
    ADC #10
    PHA
    LDA CANON_Y
    CLC
    ADC #2
    TAY
    PLA
    LDX #0
    JSR HGLINE

    ; Plateforme Player 2 / CPU (Blanc = 3)
    LDX #$03            ; Couleur Blanche
    JSR HCOLOR
    
    ; Ligne 1 à CIBLE_Y + 1
    LDA CIBLE_Y
    CLC
    ADC #1
    PHA
    LDA CIBLE_X
    SEC
    SBC #10
    TAX
    LDA CIBLE_X+1
    SBC #0
    TAY
    PLA
    JSR HPOSN
    
    LDA CIBLE_X
    CLC
    ADC #10
    PHA
    LDA CIBLE_X+1
    ADC #0
    TAX
    LDA CIBLE_Y
    CLC
    ADC #1
    TAY
    PLA
    JSR HGLINE
    
    ; Ligne 2 à CIBLE_Y + 2
    LDA CIBLE_Y
    CLC
    ADC #2
    PHA
    LDA CIBLE_X
    SEC
    SBC #10
    TAX
    LDA CIBLE_X+1
    SBC #0
    TAY
    PLA
    JSR HPOSN
    
    LDA CIBLE_X
    CLC
    ADC #10
    PHA
    LDA CIBLE_X+1
    ADC #0
    TAX
    LDA CIBLE_Y
    CLC
    ADC #2
    TAY
    PLA
    JSR HGLINE
    
    RTS


; --- Dessin du Tank du Joueur ---
DrawPlayerTank:
    LDX CANON_X
    LDY #0
    JSR GetHeight
    STA CANON_Y         ; Sauvegarde le Y de base
    STA CUR_Y
    
    LDA CANON_X
    STA CUR_X_LO
    LDA #0
    STA CUR_X_HI
    
    LDX #$03            ; Blanc
    JSR DrawTankBody
    RTS

; --- Dessin du Tank de l'Ordi ---
DrawCPUTank:
    LDA CIBLE_X
    LDY CIBLE_X+1
    TAX
    JSR GetHeight
    STA CIBLE_Y         ; Sauvegarde le Y de base
    STA CUR_Y
    
    LDA CIBLE_X
    STA CUR_X_LO
    LDA CIBLE_X+1
    STA CUR_X_HI
    
    LDX #$05            ; Orange (très visible)
    JSR DrawTankBody
    RTS

; --- Routines de dessin dynamique des canons (barrels) ---
DrawPlayerBarrel:
    ; Input: X = Couleur
    JSR HCOLOR
    
    ; delta Y = (12 * SIN(ANGLE)) / 256
    LDX ANGLE
    LDA SIN_TAB,X
    JSR MultBy12Div256
    STA TEMP_LO         ; delta Y
    
    ; delta X = (12 * COS(ANGLE)) / 256
    LDA #90
    SEC
    SBC ANGLE
    TAX
    LDA SIN_TAB,X
    JSR MultBy12Div256
    STA TEMP_HI         ; delta X
    
    ; --- Ligne 1 (Milieu) ---
    LDA CANON_Y
    SEC
    SBC #9
    PHA
    LDX CANON_X
    LDY #0
    PLA
    JSR HPOSN
    
    LDA CANON_X
    CLC
    ADC TEMP_HI
    PHA
    LDA CANON_Y
    SEC
    SBC #9
    SBC TEMP_LO
    TAY                 ; Dest Y
    PLA                 ; Dest X low
    LDX #0              ; Dest X high
    JSR HGLINE
    
    ; --- Ligne 2 (Décalage Y-1) ---
    LDA CANON_Y
    SEC
    SBC #10
    PHA
    LDX CANON_X
    LDY #0
    PLA
    JSR HPOSN
    
    LDA CANON_X
    CLC
    ADC TEMP_HI
    PHA
    LDA CANON_Y
    SEC
    SBC #10
    SBC TEMP_LO
    TAY                 ; Dest Y
    PLA                 ; Dest X low
    LDX #0              ; Dest X high
    JSR HGLINE
    
    ; --- Ligne 3 (Décalage X-1) ---
    LDA CANON_Y
    SEC
    SBC #9
    PHA
    LDA CANON_X
    SEC
    SBC #1
    TAX
    LDY #0
    PLA
    JSR HPOSN
    
    LDA CANON_X
    SEC
    SBC #1
    CLC
    ADC TEMP_HI
    PHA
    LDA CANON_Y
    SEC
    SBC #9
    SBC TEMP_LO
    TAY                 ; Dest Y
    PLA                 ; Dest X low
    LDX #0              ; Dest X high
    JSR HGLINE
    
    ; Redessine le dôme pour effacer d'éventuels trous
    LDA CANON_Y
    STA CUR_Y
    LDA CANON_X
    STA CUR_X_LO
    LDA #0
    STA CUR_X_HI
    LDX #$03            ; Blanc
    JSR DrawTurretDome
    RTS

DrawCPUBarrel:
    ; Input: X = Couleur
    JSR HCOLOR
    
    ; delta Y = (12 * SIN(CPU_ANGLE)) / 256
    LDX CPU_ANGLE
    LDA SIN_TAB,X
    JSR MultBy12Div256
    STA TEMP_LO         ; delta Y
    
    ; delta X = (12 * COS(CPU_ANGLE)) / 256
    LDA #90
    SEC
    SBC CPU_ANGLE
    TAX
    LDA SIN_TAB,X
    JSR MultBy12Div256
    STA TEMP_HI         ; delta X
    
    ; --- Ligne 1 (Milieu) ---
    LDA CIBLE_Y
    SEC
    SBC #9
    PHA
    LDX CIBLE_X
    LDY CIBLE_X+1
    PLA
    JSR HPOSN
    
    LDA CIBLE_X
    SEC
    SBC TEMP_HI
    PHA
    LDA CIBLE_X+1
    SBC #0
    TAX                 ; Dest X high
    LDA CIBLE_Y
    SEC
    SBC #9
    SBC TEMP_LO
    TAY                 ; Dest Y
    PLA                 ; Dest X low
    JSR HGLINE
    
    ; --- Ligne 2 (Décalage Y-1) ---
    LDA CIBLE_Y
    SEC
    SBC #10
    PHA
    LDX CIBLE_X
    LDY CIBLE_X+1
    PLA
    JSR HPOSN
    
    LDA CIBLE_X
    SEC
    SBC TEMP_HI
    PHA
    LDA CIBLE_X+1
    SBC #0
    TAX                 ; Dest X high
    LDA CIBLE_Y
    SEC
    SBC #10
    SBC TEMP_LO
    TAY                 ; Dest Y
    PLA                 ; Dest X low
    JSR HGLINE
    
    ; --- Ligne 3 (Décalage X+1) ---
    LDA CIBLE_Y
    SEC
    SBC #9
    PHA
    LDA CIBLE_X
    CLC
    ADC #1
    TAX
    LDA CIBLE_X+1
    ADC #0
    TAY
    PLA
    JSR HPOSN
    
    LDA CIBLE_X
    CLC
    ADC #1
    SEC
    SBC TEMP_HI
    PHA
    LDA CIBLE_X+1
    SBC #0
    TAX                 ; Dest X high
    LDA CIBLE_Y
    SEC
    SBC #9
    SBC TEMP_LO
    TAY                 ; Dest Y
    PLA                 ; Dest X low
    JSR HGLINE
    
    ; Redessine le dôme pour effacer d'éventuels trous
    LDA CIBLE_Y
    STA CUR_Y
    LDA CIBLE_X
    STA CUR_X_LO
    LDA CIBLE_X+1
    STA CUR_X_HI
    LDX #$05            ; Orange
    JSR DrawTurretDome
    RTS

MultBy12Div256:
    STA MULT1
    LDA #12
    STA MULT2
    JSR Multiply8_8
    LDA NUM+1           ; High byte of product
    RTS

; =============================================================================
; INTERACTIVITÉ ET SAISIE CLAVIER
; =============================================================================
GetInput:
    JSR UpdateText
    
WaitKey:
    INC RANDOM_SEED
    BNE +
    INC RANDOM_SEED+1
+   LDA $C000
    BPL WaitKey
    
    PHA
    BIT $C010
    PLA
    AND #$7F
    
    CMP #$08            ; Flèche Gauche
    BEQ DecAngle
    CMP #$4A            ; 'J'
    BEQ DecAngle
    CMP #$6A            ; 'j'
    BEQ DecAngle
    CMP #$3C            ; '<'
    BEQ DecAngle
    CMP #$2C            ; ','
    BEQ DecAngle
    
    CMP #$15            ; Flèche Droite
    BEQ IncAngle
    CMP #$4B            ; 'K'
    BEQ IncAngle
    CMP #$6B            ; 'k'
    BEQ IncAngle
    CMP #$3E            ; '>'
    BEQ IncAngle
    CMP #$2E            ; '.'
    BEQ IncAngle
    
    CMP #$0B            ; Flèche Haut
    BEQ IncPower
    CMP #$41            ; 'A'
    BEQ IncPower
    CMP #$61            ; 'a'
    BEQ IncPower
    CMP #$55            ; 'U'
    BEQ IncPower
    CMP #$75            ; 'u'
    BEQ IncPower
    CMP #$2B            ; '+'
    BEQ IncPower
    
    CMP #$0A            ; Flèche Bas
    BEQ DecPower
    CMP #$5A            ; 'Z'
    BEQ DecPower
    CMP #$7A            ; 'z'
    BEQ DecPower
    CMP #$44            ; 'D'
    BEQ DecPower
    CMP #$64            ; 'd'
    BEQ DecPower
    CMP #$2D            ; '-'
    BEQ DecPower
    
    CMP #$20            ; Espace
    BEQ FireKey
    CMP #$0D            ; Entrée
    BEQ FireKey
    CMP #$51            ; 'Q'
    BEQ QuitGame
    CMP #$71            ; 'q'
    BEQ QuitGame
    
    JMP WaitKey

DecAngle:
    LDA ANGLE
    BEQ +
    LDX #0
    JSR DrawPlayerBarrel
    DEC ANGLE
    LDX #3
    JSR DrawPlayerBarrel
+   JMP GetInput

IncAngle:
    LDA ANGLE
    CMP #90
    BCS +
    LDX #0
    JSR DrawPlayerBarrel
    INC ANGLE
    LDX #3
    JSR DrawPlayerBarrel
+   JMP GetInput

DecPower:
    LDA POWER
    BEQ +
    DEC POWER
+   JMP GetInput

IncPower:
    LDA POWER
    CMP #200
    BCS +
    INC POWER
+   JMP GetInput

FireKey:
    RTS

QuitGame:
    JSR TEXT_ROM
    JSR RestoreTextWindow
    JSR $FC58
    JMP $E003

; --- Mise à jour de la ligne de texte ---
UpdateText:
    JSR UpdateTextHUD
    RTS

UpdateTextP2:
    JSR UpdateTextHUD
    RTS

UpdateTextHUD:
    JSR DrawPlayerStats
    JSR DrawRoundAndWind
    JSR DrawActiveControls
    JSR DrawHelpAndCopyright
    RTS

DrawPlayerStats:
    LDA #20
    JSR VTAB
    LDA #0
    STA $24
    
    LDA #<MSG_J1_STAT
    STA $06
    LDA #>MSG_J1_STAT
    STA $07
    JSR PrintString
    
    JSR PrintScore
    
    LDA #<MSG_LPAREN
    STA $06
    LDA #>MSG_LPAREN
    STA $07
    JSR PrintString
    
    LDA HIT_COUNT
    ORA #$B0
    JSR COUT
    
    LDA #<MSG_OF5_STAT
    STA $06
    LDA #>MSG_OF5_STAT
    STA $07
    JSR PrintString
    
    LDA GAME_MODE
    BNE _stat_p2
    LDA #<MSG_ORDI_STAT
    STA $06
    LDA #>MSG_ORDI_STAT
    STA $07
    JSR PrintString
    JMP _stat_done
_stat_p2
    LDA #<MSG_J2_STAT
    STA $06
    LDA #>MSG_J2_STAT
    STA $07
    JSR PrintString
_stat_done
    JSR PrintScoreP2
    
    LDA #<MSG_LPAREN
    STA $06
    LDA #>MSG_LPAREN
    STA $07
    JSR PrintString
    
    LDA P2_HIT_COUNT
    ORA #$B0
    JSR COUT
    
    LDA #<MSG_RPAREN_STAT
    STA $06
    LDA #>MSG_RPAREN_STAT
    STA $07
    JSR PrintString
    JSR $FC9C           ; CLEOL
    RTS

DrawRoundAndWind:
    LDA #21
    JSR VTAB
    LDA #0
    STA $24
    
    LDA #<MSG_MANCHE
    STA $06
    LDA #>MSG_MANCHE
    STA $07
    JSR PrintString
    
    LDA ROUND_NUM
    ORA #$B0
    JSR COUT
    
    LDA #<MSG_OF5_SIMPLE
    STA $06
    LDA #>MSG_OF5_SIMPLE
    STA $07
    JSR PrintString
    
    LDA #<MSG_WIND_LABEL
    STA $06
    LDA #>MSG_WIND_LABEL
    STA $07
    JSR PrintString
    
    LDA WIND_VAL
    BEQ _wind_nil
    BPL _wind_right
    
    LDA WIND_VAL
    EOR #$FF
    CLC
    ADC #1
    TAX
-   PHA
    LDA #$BC            ; '<'
    JSR COUT
    PLA
    DEX
    BNE -
    JMP _wind_done
    
_wind_right:
    TAX
-   PHA
    LDA #$BE            ; '>'
    JSR COUT
    PLA
    DEX
    BNE -
    JMP _wind_done
    
_wind_nil:
    LDA #<MSG_WIND_NIL
    STA $06
    LDA #>MSG_WIND_NIL
    STA $07
    JSR PrintString
    
_wind_done:
    JSR $FC9C           ; CLEOL
    RTS

DrawActiveControls:
    LDA #22
    JSR VTAB
    LDA #0
    STA $24
    
    LDA IS_CPU_TURN
    BNE _p2_controls
    
    LDA #<MSG_P1_TURN
    STA $06
    LDA #>MSG_P1_TURN
    STA $07
    JSR PrintString
    
    LDA ANGLE
    JSR Print2Digits
    
    LDA #<MSG_P_PUISS
    STA $06
    LDA #>MSG_P_PUISS
    STA $07
    JSR PrintString
    
    LDA POWER
    JSR Print3Digits
    JMP _controls_done
    
_p2_controls:
    LDA GAME_MODE
    BNE _p2_real_controls
    
    LDA #<MSG_CPU_TURN
    STA $06
    LDA #>MSG_CPU_TURN
    STA $07
    JSR PrintString
    
    LDA CPU_ANGLE
    JSR Print2Digits
    
    LDA #<MSG_P_PUISS
    STA $06
    LDA #>MSG_P_PUISS
    STA $07
    JSR PrintString
    
    LDA CPU_POWER
    JSR Print3Digits
    JMP _controls_done
    
_p2_real_controls:
    LDA #<MSG_P2_TURN
    STA $06
    LDA #>MSG_P2_TURN
    STA $07
    JSR PrintString
    
    LDA CPU_ANGLE
    JSR Print2Digits
    
    LDA #<MSG_P_PUISS
    STA $06
    LDA #>MSG_P_PUISS
    STA $07
    JSR PrintString
    
    LDA CPU_POWER
    JSR Print3Digits
    
_controls_done:
    JSR $FC9C           ; CLEOL
    RTS

DrawHelpAndCopyright:
    LDA #23
    JSR VTAB
    LDA #0
    STA $24
    
    LDA IS_CPU_TURN
    BEQ +
    LDA GAME_MODE
    BNE +
    
    LDX #26
-   LDA #$A0
    JSR COUT
    DEX
    BNE -
    JMP _print_copyright
    
+   LDA #<MSG_HELP_LINE
    STA $06
    LDA #>MSG_HELP_LINE
    STA $07
    JSR PrintString
    
_print_copyright:
    LDA #<MSG_COPYRIGHT
    STA $06
    LDA #>MSG_COPYRIGHT
    STA $07
    JSR PrintString
    RTS

; =============================================================================
; DEUXIÈME JOUEUR (PVP) ET TRAJECTOIRES
; =============================================================================
P2Round:
    JSR GetInputP2      ; Saisie de l'angle et de la force pour J2
    INC P2_SHOT_COUNT
    JSR CalcVelocities  ; Calcule V_X et V_Y à partir de CPU_ANGLE/CPU_POWER
    JSR FireProjectile
    BCC +
    LDA SELF_HIT
    BNE P2SelfHit
    JMP HitPlayer       ; Carry set = J2 a touché J1 !
+
    ; J2 a raté
    JSR ClearStatusLine
    LDA RESULT
    BEQ MsgP2Missed
    
    ; Hors limites
    LDA #<MSG_OUT
    STA $06
    LDA #>MSG_OUT
    STA $07
    JMP PrintP2Result
    
MsgP2Missed:
    LDA #<MSG_P2_MISS
    STA $06
    LDA #>MSG_P2_MISS
    STA $07
    
PrintP2Result:
    JSR PrintString
    JSR Delay2Seconds
    LDA #0
    STA IS_CPU_TURN     ; Retour à J1
    JMP RoundLoop

P2SelfHit:
    JSR ClearStatusLine
    JSR ExplodeEnemyTank
    LDA #<MSG_P2_SELF_HIT
    STA $06
    LDA #>MSG_P2_SELF_HIT
    STA $07
    JSR PrintString
    JSR Delay2Seconds
    LDA #0
    STA IS_CPU_TURN     ; Retour à J1
    JMP RoundLoop

GetInputP2:
    JSR UpdateTextP2
    
WaitKeyP2:
    INC RANDOM_SEED
    BNE +
    INC RANDOM_SEED+1
+   LDA $C000
    BPL WaitKeyP2
    
    PHA
    BIT $C010
    PLA
    AND #$7F
    
    CMP #$08            ; Flèche Gauche
    BEQ DecAngleP2
    CMP #$4A            ; 'J'
    BEQ DecAngleP2
    CMP #$6A            ; 'j'
    BEQ DecAngleP2
    CMP #$3C            ; '<'
    BEQ DecAngleP2
    CMP #$2C            ; ','
    BEQ DecAngleP2
    
    CMP #$15            ; Flèche Droite
    BEQ IncAngleP2
    CMP #$4B            ; 'K'
    BEQ IncAngleP2
    CMP #$6B            ; 'k'
    BEQ IncAngleP2
    CMP #$3E            ; '>'
    BEQ IncAngleP2
    CMP #$2E            ; '.'
    BEQ IncAngleP2
    
    CMP #$0B            ; Flèche Haut
    BEQ IncPowerP2
    CMP #$41            ; 'A'
    BEQ IncPowerP2
    CMP #$61            ; 'a'
    BEQ IncPowerP2
    CMP #$55            ; 'U'
    BEQ IncPowerP2
    CMP #$75            ; 'u'
    BEQ IncPowerP2
    CMP #$2B            ; '+'
    BEQ IncPowerP2
    
    CMP #$0A            ; Flèche Bas
    BEQ DecPowerP2
    CMP #$5A            ; 'Z'
    BEQ DecPowerP2
    CMP #$7A            ; 'z'
    BEQ DecPowerP2
    CMP #$44            ; 'D'
    BEQ DecPowerP2
    CMP #$64            ; 'd'
    BEQ DecPowerP2
    CMP #$2D            ; '-'
    BEQ DecPowerP2
    
    CMP #$20            ; Espace
    BEQ FireKeyP2
    CMP #$0D            ; Entrée
    BEQ FireKeyP2
    CMP #$51            ; 'Q'
    BEQ QuitGameP2
    CMP #$71            ; 'q'
    BEQ QuitGameP2
    
    JMP WaitKeyP2

DecAngleP2:
    LDA CPU_ANGLE
    BEQ +
    LDX #0
    JSR DrawCPUBarrel
    DEC CPU_ANGLE
    LDX #5              ; Orange
    JSR DrawCPUBarrel
+   JMP GetInputP2

IncAngleP2:
    LDA CPU_ANGLE
    CMP #90
    BCS +
    LDX #0
    JSR DrawCPUBarrel
    INC CPU_ANGLE
    LDX #5              ; Orange
    JSR DrawCPUBarrel
+   JMP GetInputP2

DecPowerP2:
    LDA CPU_POWER
    BEQ +
    DEC CPU_POWER
+   JMP GetInputP2

IncPowerP2:
    LDA CPU_POWER
    CMP #200
    BCS +
    INC CPU_POWER
+   JMP GetInputP2

FireKeyP2:
    RTS

QuitGameP2:
    JMP QuitGame

; Les routines UpdateTextP2 et assimilées ont été intégrées ci-dessus.

GetTerrainColor:
    STA TEMP_Y_COL      ; Save Y coordinate
    STY TEMP_HI         ; Save X_high
    STX TEMP_LO         ; Save X_low
    
    ; 1. Check if Y is on P1 platform
    LDA TEMP_HI
    BNE _not_p1_plat    ; P1 platform is at X < 256, so X_high must be 0
    
    LDA TEMP_LO
    SEC
    SBC CANON_X
    CLC
    ADC #10
    CMP #21             ; 0..20 means |X - CANON_X| <= 10
    BCS _not_p1_plat
    
    LDA TEMP_Y_COL
    SEC
    SBC CANON_Y
    CMP #1
    BEQ _is_plat
    CMP #2
    BEQ _is_plat
    
_not_p1_plat:
    ; 2. Check if Y is on P2 platform
    SEC
    LDA CIBLE_X
    SBC #10
    STA TEMP_X_DIFF     ; START_X low
    LDA CIBLE_X+1
    SBC #0
    STA TEMP            ; START_X high
    
    SEC
    LDA TEMP_LO
    SBC TEMP_X_DIFF     ; Diff low
    STA TEMP_X_DIFF
    LDA TEMP_HI
    SBC TEMP            ; Diff high
    BNE _not_p2_plat
    
    LDA TEMP_X_DIFF
    CMP #21             ; 0..20
    BCS _not_p2_plat
    
    LDA TEMP_Y_COL
    SEC
    SBC CIBLE_Y
    CMP #1
    BEQ _is_plat
    CMP #2
    BEQ _is_plat
    
    JMP _check_mountain
    
_is_plat:
    LDX #3              ; White platform color
    RTS
    
_not_p2_plat:
_check_mountain:
    LDX TEMP_LO
    LDY TEMP_HI
    JSR GetHeight       ; A = Height of terrain
    STA TEMP            ; Save height
    
    LDA TEMP_Y_COL
    CMP TEMP            ; Compare with terrain height
    BCC _is_sky         ; If Y < GetHeight, it's sky
    
    SEC
    SBC TEMP            ; A = Y - GetHeight
    CMP #4
    BCC _is_grass
    
    LDX #2              ; Violet (Rock)
    RTS
    
_is_grass:
    LDX #1              ; Green (Grass)
    RTS
    
_is_sky:
    LDX #0              ; Black (Sky)
    RTS

EraseP1Buf1:
    LDA P1_BUF1_LEN
    BEQ _erase_done_p1
    
    LDX #0
_erase_loop_p1:
    STX TEMP_VAL
    
    LDA P1_BUF1_X_LO,X
    STA TEMP_LO
    LDA P1_BUF1_X_HI,X
    STA TEMP_HI
    LDA P1_BUF1_Y,X
    STA TEMP_Y
    
    LDX TEMP_LO
    LDY TEMP_HI
    LDA TEMP_Y
    JSR GetTerrainColor
    JSR HCOLOR
    
    LDA TEMP_Y
    LDX TEMP_LO
    LDY TEMP_HI
    JSR HPLOT
    
    LDX TEMP_VAL
    INX
    CPX P1_BUF1_LEN
    BNE _erase_loop_p1
_erase_done_p1:
    RTS

EraseP2Buf1:
    LDA P2_BUF1_LEN
    BEQ _erase_done_p2
    
    LDX #0
_erase_loop_p2:
    STX TEMP_VAL
    
    LDA P2_BUF1_X_LO,X
    STA TEMP_LO
    LDA P2_BUF1_X_HI,X
    STA TEMP_HI
    LDA P2_BUF1_Y,X
    STA TEMP_Y
    
    LDX TEMP_LO
    LDY TEMP_HI
    LDA TEMP_Y
    JSR GetTerrainColor
    JSR HCOLOR
    
    LDA TEMP_Y
    LDX TEMP_LO
    LDY TEMP_HI
    JSR HPLOT
    
    LDX TEMP_VAL
    INX
    CPX P2_BUF1_LEN
    BNE _erase_loop_p2
_erase_done_p2:
    RTS

RedrawActiveTrajectories:
    ; 1. Redraw P1_BUF1 (Violet = 2)
    LDA P1_BUF1_LEN
    BEQ _p2_buf1
    LDX #2              ; Violet
    JSR HCOLOR
    LDX #0
_redraw_p1_buf1:
    STX TEMP_VAL
    LDA P1_BUF1_X_LO,X
    STA TEMP_LO
    LDA P1_BUF1_X_HI,X
    TAY
    LDA P1_BUF1_Y,X
    LDX TEMP_LO
    JSR HPLOT
    LDX TEMP_VAL
    INX
    CPX P1_BUF1_LEN
    BNE _redraw_p1_buf1

_p2_buf1:
    ; 2. Redraw P2_BUF1 (Orange = 5)
    LDA P2_BUF1_LEN
    BEQ _redraw_done
    LDX #5              ; Orange
    JSR HCOLOR
    LDX #0
_redraw_p2_buf1:
    STX TEMP_VAL
    LDA P2_BUF1_X_LO,X
    STA TEMP_LO
    LDA P2_BUF1_X_HI,X
    TAY
    LDA P2_BUF1_Y,X
    LDX TEMP_LO
    JSR HPLOT
    LDX TEMP_VAL
    INX
    CPX P2_BUF1_LEN
    BNE _redraw_p2_buf1

_redraw_done:
    JSR DrawStars
    RTS

; =============================================================================
; INTELLIGENCE ARTIFICIELLE ET COMPORTEMENT DE L'ORDINATEUR
; =============================================================================
CPULogic:
    JSR UpdateTextHUD
    JSR Delay2Seconds
    RTS

AdjustCPUPower:
    LDA RESULT
    BEQ _adjust_normal
    
    ; Tir hors limites !
    ; Le CPU tire vers la gauche (VX négatif).
    ; Si X_POS+2 est négatif (BMI), le tir est sorti par la gauche -> trop puissant / trop loin !
    LDA X_POS+2
    BPL _out_right
    
    ; Sorti par la gauche -> trop loin, réduire la puissance de 12 à 27
    LDA RANDOM_SEED
    AND #15
    CLC
    ADC #12
    STA TEMP
    LDA CPU_POWER
    SEC
    SBC TEMP
    STA CPU_POWER
    CMP #30
    BCS +
    LDA #30
    STA CPU_POWER
+   RTS

_out_right:
    ; Sorti par la droite (rabattu par le vent) -> trop court, augmenter la puissance
    LDA RANDOM_SEED+1
    AND #15
    CLC
    ADC #12
    ADC CPU_POWER
    STA CPU_POWER
    CMP #200
    BCC +
    LDA #200
    STA CPU_POWER
+   RTS

_adjust_normal:
    ; Si le tir a atterri à X >= 256
    LDA X_POS+2
    BNE TooShort
    
    LDA CPU_LAST_X
    CMP CANON_X
    BCC TooFar          ; Si CPU_LAST_X < CANON_X, trop loin (dépassé par la gauche)
    
TooShort:
    ; Tir trop court, on augmente la puissance de 6 à 13
    LDA RANDOM_SEED
    AND #7
    CLC
    ADC #6
    ADC CPU_POWER
    STA CPU_POWER
    CMP #200
    BCC +
    LDA #200
    STA CPU_POWER
+   RTS

TooFar:
    ; Tir trop long, on diminue la puissance de 6 à 13
    LDA RANDOM_SEED+1
    AND #7
    CLC
    ADC #6
    STA TEMP
    
    LDA CPU_POWER
    SEC
    SBC TEMP
    STA CPU_POWER
    CMP #30
    BCS +
    LDA #30
    STA CPU_POWER
+   RTS

; =============================================================================
; CALCULS PHYSIQUES : V_X, V_Y ET GRAVITÉ
; =============================================================================
CalcVelocities:
    LDA IS_CPU_TURN
    BNE CalcCPU
    
    ; --- Calcul pour le joueur ---
    ; VX = (POWER / 30) * COS(ANGLE)
    ; VY = - (POWER / 30) * SIN(ANGLE)
    LDA #90
    SEC
    SBC ANGLE
    TAX
    LDA SIN_TAB,X
    STA MULT1
    LDA POWER
    STA MULT2
    JSR CalcVal
    
    LDA NUM_FRAC
    STA V_X
    LDA NUM_INT
    STA V_X+1
    LDA #0
    STA V_X+2
    
    LDX ANGLE
    LDA SIN_TAB,X
    STA MULT1
    LDA POWER
    STA MULT2
    JSR CalcVal
    JMP NegateVY
    
CalcCPU:
    ; --- Calcul pour l'ordinateur ---
    ; VX = - (CPU_POWER / 30) * COS(CPU_ANGLE) (vers la gauche !)
    LDA #90
    SEC
    SBC CPU_ANGLE
    TAX
    LDA SIN_TAB,X
    STA MULT1
    LDA CPU_POWER
    STA MULT2
    JSR CalcVal
    
    ; VX CPU négatif
    LDA NUM_FRAC
    EOR #$FF
    CLC
    ADC #1
    STA V_X
    LDA NUM_INT
    EOR #$FF
    ADC #0
    STA V_X+1
    LDA #0
    EOR #$FF
    ADC #0
    STA V_X+2
    
    LDX CPU_ANGLE
    LDA SIN_TAB,X
    STA MULT1
    LDA CPU_POWER
    STA MULT2
    JSR CalcVal

NegateVY:
    ; VY négatif (vers le haut)
    LDA NUM_FRAC
    EOR #$FF
    CLC
    ADC #1
    STA V_Y
    LDA NUM_INT
    EOR #$FF
    ADC #0
    STA V_Y+1
    LDA #0
    EOR #$FF
    ADC #0
    STA V_Y+2
    
    ; Gravité G = 0.04 (scaled * 256 = 10 ($0A))
    LDA #$0A
    STA GRAVITY
    LDA #0
    STA GRAVITY+1
    STA GRAVITY+2
    RTS

; Calcule MULT1 * MULT2 / 30 et sépare partie entière / fractionnaire
CalcVal:
    JSR Multiply8_8     ; NUM = MULT1 * MULT2
    JSR DivideBy30      ; NUM = NUM / 30
    LDA NUM
    STA NUM_FRAC        ; Partie fractionnaire
    LDA NUM+1
    STA NUM_INT         ; Partie entière
    RTS

; --- Multiplication 8.8 = 16 bits ---
Multiply8_8:
    LDA #0
    STA NUM
    STA NUM+1
    LDX #8
-   LSR MULT1
    BCC +
    CLC
    LDA NUM+1
    ADC MULT2
    STA NUM+1
+   ROR NUM+1
    ROR NUM
    DEX
    BNE -
    RTS

; --- Division 16 bits par 30 ---
DivideBy30:
    LDA #0
    STA REM
    LDX #16
-   ASL NUM
    ROL NUM+1
    LDA REM
    ROL
    CMP #30
    BCC +
    SBC #30
    INC NUM
+   STA REM
    DEX
    BNE -
    RTS

; =============================================================================
; SIMULATION DE LA TRAJECTOIRE
; =============================================================================
FireProjectile:
    LDA #0
    STA RESULT
    STA WAS_PLAYER_HIT
    STA WAS_CPU_HIT
    
    ; Compute TEMP_VX = V_X / 4 (signed 24-bit)
    LDA V_X
    STA TEMP_VX
    LDA V_X+1
    STA TEMP_VX+1
    LDA V_X+2
    STA TEMP_VX+2
    
    LDA TEMP_VX+2
    ASL A
    ROR TEMP_VX+2
    ROR TEMP_VX+1
    ROR TEMP_VX
    
    LDA TEMP_VX+2
    ASL A
    ROR TEMP_VX+2
    ROR TEMP_VX+1
    ROR TEMP_VX

    ; Compute TEMP_GRAV = GRAVITY / 4 (unsigned 24-bit)
    LDA GRAVITY
    STA TEMP_GRAV
    LDA GRAVITY+1
    STA TEMP_GRAV+1
    LDA GRAVITY+2
    STA TEMP_GRAV+2
    
    LSR TEMP_GRAV+2
    ROR TEMP_GRAV+1
    ROR TEMP_GRAV
    
    LSR TEMP_GRAV+2
    ROR TEMP_GRAV+1
    ROR TEMP_GRAV

    ; Compute TEMP_WIND = WIND_ACC / 4 (signed 24-bit)
    LDA WIND_ACC
    STA TEMP_WIND
    LDA WIND_ACC+1
    STA TEMP_WIND+1
    LDA WIND_ACC+2
    STA TEMP_WIND+2
    
    LDA TEMP_WIND+2
    ASL A
    ROR TEMP_WIND+2
    ROR TEMP_WIND+1
    ROR TEMP_WIND
    
    LDA TEMP_WIND+2
    ASL A
    ROR TEMP_WIND+2
    ROR TEMP_WIND+1
    ROR TEMP_WIND

    LDA IS_CPU_TURN
    BNE FireCPU
    
    ; --- Départ Joueur ---
    LDX ANGLE
    LDA SIN_TAB,X
    JSR MultBy12Div256
    STA TEMP_LO         ; delta Y
    
    ; delta X = (12 * COS(ANGLE)) / 256
    LDA #90
    SEC
    SBC ANGLE
    TAX
    LDA SIN_TAB,X
    JSR MultBy12Div256
    STA TEMP_HI         ; delta X
    
    LDA #0
    STA X_POS
    LDA CANON_X
    CLC
    ADC TEMP_HI
    STA X_POS+1
    LDA #0
    ADC #0
    STA X_POS+2
    
    LDA #0
    STA Y_POS
    LDA CANON_Y
    SEC
    SBC #9              ; Le canon part de YC - 9
    SBC TEMP_LO
    STA Y_POS+1
    LDA #0
    SBC #0
    STA Y_POS+2
    JMP StartSim
    
FireCPU:
    ; --- Départ CPU ---
    LDX CPU_ANGLE
    LDA SIN_TAB,X
    JSR MultBy12Div256
    STA TEMP_LO         ; delta Y
    
    ; delta X = (12 * COS(CPU_ANGLE)) / 256
    LDA #90
    SEC
    SBC CPU_ANGLE
    TAX
    LDA SIN_TAB,X
    JSR MultBy12Div256
    STA TEMP_HI         ; delta X
    
    LDA #0
    STA X_POS
    LDA CIBLE_X
    SEC
    SBC TEMP_HI
    STA X_POS+1
    LDA CIBLE_X+1
    SBC #0
    STA X_POS+2
    
    LDA #0
    STA Y_POS
    LDA CIBLE_Y
    SEC
    SBC #9              ; Le canon part de YC - 9
    SBC TEMP_LO
    STA Y_POS+1
    LDA #0
    SBC #0
    STA Y_POS+2

StartSim:
    JSR PlayFireSound
    
TrajectoryLoop:
    ; We do 4 sub-steps per frame
    LDA #4
    STA SUBSTEP_CNT

SubstepLoop:
    ; --- Test de sortie d'ecran (X) ---
    LDA X_POS+2
    BPL +
    JMP OutOfBounds     ; X < 0
+   CMP #2
    BCS +               ; Si X >= 512
    CMP #1
    BNE _x_ok           ; Si X_POS+2 == 0
    LDA X_POS+1
    CMP #24
    BCC _x_ok           ; Si X_POS+2 == 1 et X_POS+1 < 24
+   JMP OutOfBounds
_x_ok:

    ; --- Test de sortie d'ecran (Y) ---
    ; Si Y < 0, on autorise (le projectile est en cloche)
    LDA Y_POS+2
    BMI _y_ok           ; Si negatif, Y < 0, c'est OK
    
    ; Sinon, check si Y >= 160
    BNE +               ; Si Y_POS+2 > 0, alors Y >= 256, donc OutOfBounds
    LDA Y_POS+1
    CMP #160
    BCC _y_ok           ; Si Y < 160, c'est OK
+   JMP OutOfBounds
_y_ok:

    ; Compute TEMP_VY = V_Y / 4 (signed 24-bit)
    LDA V_Y
    STA TEMP_VY
    LDA V_Y+1
    STA TEMP_VY+1
    LDA V_Y+2
    STA TEMP_VY+2
    
    LDA TEMP_VY+2
    ASL A
    ROR TEMP_VY+2
    ROR TEMP_VY+1
    ROR TEMP_VY
    
    LDA TEMP_VY+2
    ASL A
    ROR TEMP_VY+2
    ROR TEMP_VY+1
    ROR TEMP_VY

    ; Euler Integration
    CLC
    LDA X_POS
    ADC TEMP_VX
    STA X_POS
    LDA X_POS+1
    ADC TEMP_VX+1
    STA X_POS+1
    LDA X_POS+2
    ADC TEMP_VX+2
    STA X_POS+2

    CLC
    LDA Y_POS
    ADC TEMP_VY
    STA Y_POS
    LDA Y_POS+1
    ADC TEMP_VY+1
    STA Y_POS+1
    LDA Y_POS+2
    ADC TEMP_VY+2
    STA Y_POS+2

    CLC
    LDA V_Y
    ADC TEMP_GRAV
    STA V_Y
    LDA V_Y+1
    ADC TEMP_GRAV+1
    STA V_Y+1
    LDA V_Y+2
    ADC TEMP_GRAV+2
    STA V_Y+2

    ; Applique le vent a V_X
    CLC
    LDA V_X
    ADC TEMP_WIND
    STA V_X
    LDA V_X+1
    ADC TEMP_WIND+1
    STA V_X+1
    LDA V_X+2
    ADC TEMP_WIND+2
    STA V_X+2

    ; --- Detection de collision Tank en plein vol ---
    JSR CheckTankCollisions
    BCC _no_col
    ; Un tank a ete touche !
    LDA IS_CPU_TURN
    BNE _cpu_turn_col
    ; Tour Joueur
    LDA WAS_CPU_HIT
    BNE _hit_confirmed
    ; Le joueur a touché son propre tank !
    LDA #1
    STA SELF_HIT
    SEC
    RTS
_cpu_turn_col:
    ; Tour CPU / J2
    LDA WAS_PLAYER_HIT
    BNE _hit_confirmed
    ; J2 / CPU a touché son propre tank !
    LDA #1
    STA SELF_HIT
    SEC
    RTS
_hit_confirmed:
    LDA #0
    STA SELF_HIT
    SEC
    RTS
_no_col:

    ; Si au-dessus de l'ecran, pas de collision sol
    LDA Y_POS+2
    BPL +
    JMP _next_substep
+

    ; Collision avec le terrain
    LDX X_POS+1
    LDY X_POS+2
    JSR GetHeight
    STA TEMP_Y
    
    LDA Y_POS+1
    CMP TEMP_Y
    BCS CollisionSol

_next_substep:
    DEC SUBSTEP_CNT
    BEQ _substeps_done
    JMP SubstepLoop

_substeps_done:
    ; --- Affichage et enregistrement du point (une fois par frame) ---
    ; Si Y < 0, on n'affiche rien et on n'enregistre rien (projectile trop haut)
    LDA Y_POS+2
    BMI _skip_frame_plot
    
    LDA IS_CPU_TURN
    BNE _color_p2
    LDX #$02            ; Violet for Player 1
    JSR HCOLOR
    JMP _color_done
_color_p2:
    LDX #$05            ; Orange for Player 2 / CPU
    JSR HCOLOR
_color_done:

    ; Affichage du point
    LDA Y_POS+1
    LDX X_POS+1
    LDY X_POS+2
    JSR HPLOT

    ; Enregistrement du point dans le bon BUF1
    LDA IS_CPU_TURN
    BNE _record_p2
    
    LDX P1_BUF1_LEN
    CPX #255
    BCS _skip_frame_plot
    LDA X_POS+1
    STA P1_BUF1_X_LO,X
    LDA X_POS+2
    STA P1_BUF1_X_HI,X
    LDA Y_POS+1
    STA P1_BUF1_Y,X
    INC P1_BUF1_LEN
    JMP _skip_frame_plot
    
_record_p2:
    LDX P2_BUF1_LEN
    CPX #255
    BCS _skip_frame_plot
    LDA X_POS+1
    STA P2_BUF1_X_LO,X
    LDA X_POS+2
    STA P2_BUF1_X_HI,X
    LDA Y_POS+1
    STA P2_BUF1_Y,X
    INC P2_BUF1_LEN

_skip_frame_plot:
    ; Temporisation (once per frame, i.e. every 4 sub-steps)
    LDY #$15
PauseL1:
    LDX #$FF
PauseL2:
    DEX
    BNE PauseL2
    DEY
    BNE PauseL1

    JMP TrajectoryLoop

HitFound:
    SEC
    RTS

CollisionSol:
    LDA IS_CPU_TURN
    BNE _collision_sol_cpu
    JMP Missed
_collision_sol_cpu:
    JMP MissedCPU

MissedCPU:
    LDA X_POS+1
    STA CPU_LAST_X
    STA IMPACT_X
    LDA X_POS+2
    STA IMPACT_X+1
    JSR DigCrater
    
    LDA #0
    STA RESULT
    CLC
    RTS

Missed:
    LDA X_POS+1
    STA IMPACT_X
    LDA X_POS+2
    STA IMPACT_X+1
    JSR DigCrater
    
    LDA #0
    STA RESULT
    CLC
    RTS

OutOfBounds:
    LDA #1
    STA RESULT
    CLC
    RTS

; =============================================================================
; FONCTIONS UTILITAIRES ET AFFICHAGE
; =============================================================================
VTAB:
    STA $25             ; Stocke la ligne verticale demandée (dans CV)
    JMP $FC22           ; Appelle la routine VTAB de la ROM pour calculer l'adresse base écran (BASL/BASH)

PrintString:
    LDY #0
-   LDA ($06),Y
    BEQ +
    ORA #$80
    JSR COUT
    INY
    BNE -
+   RTS

Print2Digits:
    STA TEMP_VAL
    LDX #0
-   CMP #10
    BCC +
    SBC #10
    INX
    BNE -
+   STA TEMP_VAL
    TXA
    ORA #$B0
    JSR COUT
    LDA TEMP_VAL
    ORA #$B0
    JSR COUT
    RTS

Print3Digits:
    STA TEMP_VAL
    LDX #0
-   CMP #100
    BCC +
    SBC #100
    INX
    BNE -
+   STA TEMP_VAL
    TXA
    ORA #$B0
    JSR COUT
    
    LDA TEMP_VAL
    LDX #0
-   CMP #10
    BCC +
    SBC #10
    INX
    BNE -
+   STA TEMP_VAL
    TXA
    ORA #$B0
    JSR COUT
    
    LDA TEMP_VAL
    ORA #$B0
    JSR COUT
    RTS

GenerateWind:
    ; Génère une valeur de vent aléatoire entre -5 et +5
    LDA RANDOM_SEED
    AND #15            ; 0 à 15
    SEC
    SBC #7             ; -7 à +8
    
    CMP #$FB           ; -5
    BPL _wind_ge_minus5
    LDA #$FB           ; -5
    JMP _wind_save
_wind_ge_minus5
    CMP #6
    BCC _wind_save
    LDA #5
_wind_save
    STA WIND_VAL
    
    ; Construit WIND_ACC (24-bit signé point-fixe)
    LDA WIND_VAL
    ASL A              ; WIND_VAL * 2 (entre -10 et +10)
    STA WIND_ACC
    LDX #0
    TAY
    BPL +
    LDX #$FF
+   STX WIND_ACC+1
    STX WIND_ACC+2
    RTS

PrintScore:
    LDA SCORE_LO
    LDY SCORE_HI
    JMP PrintScoreAny

PrintScoreP2:
    LDA P2_SCORE_LO
    LDY P2_SCORE_HI

PrintScoreAny:
    STA TEMP_NUM
    STY TEMP_NUM+1
    
    ; 1000s
    LDX #0
-   LDA TEMP_NUM
    SEC
    SBC #$E8
    TAY
    LDA TEMP_NUM+1
    SBC #$03
    BCC +
    STY TEMP_NUM
    STA TEMP_NUM+1
    INX
    BNE -
+   TXA
    ORA #$B0
    JSR COUT
    
    ; 100s
    LDX #0
-   LDA TEMP_NUM
    SEC
    SBC #$64
    TAY
    LDA TEMP_NUM+1
    SBC #$00
    BCC +
    STY TEMP_NUM
    STA TEMP_NUM+1
    INX
    BNE -
+   TXA
    ORA #$B0
    JSR COUT
    
    ; 10s
    LDX #0
-   LDA TEMP_NUM
    SEC
    SBC #$0A
    BCC +
    STA TEMP_NUM
    INX
    BNE -
+   TXA
    ORA #$B0
    JSR COUT
    
    ; 1s
    LDA TEMP_NUM
    ORA #$B0
    JSR COUT
    RTS

Delay2Seconds:
    LDA #3
    STA TEMP
-   JSR DelaySub
    DEC TEMP
    BNE -
    RTS

DelaySub:
    LDY #255
DelayL1:
    LDX #255
DelayL2:
    DEX
    BNE DelayL2
    DEY
    BNE DelayL1
    RTS

GetRandomTargetX:
    LDA RANDOM_SEED
-   SEC
    SBC #80
    BCS -
    ADC #80
    CLC
    ADC #180
    STA CIBLE_X
    LDA #0
    ADC #0
    STA CIBLE_X+1
    RTS

GetRandomCanonX:
    LDA RANDOM_SEED+1
-   SEC
    SBC #40
    BCS -
    ADC #40
    CLC
    ADC #30
    STA CANON_X
    RTS

; =============================================================================
; NOUVELLES ROUTINES DE JEU (COLISION TANK ET CREUSAGE)
; =============================================================================

CheckTankCollisions:
    ; Réinitialise les drapeaux d'impact
    LDA #0
    STA WAS_PLAYER_HIT
    STA WAS_CPU_HIT
    
    ; 1. Collision Tank Joueur
    LDA X_POS+2
    BNE CheckCPUTankCol
    
    LDA CANON_X
    SEC
    SBC #8
    STA TEMP_LO
    LDA X_POS+1
    CMP TEMP_LO
    BCC CheckCPUTankCol
    
    LDA CANON_X
    CLC
    ADC #8
    CMP X_POS+1
    BCC CheckCPUTankCol
    
    LDA Y_POS+2
    BNE CheckCPUTankCol
    
    LDA CANON_Y
    SEC
    SBC #9
    STA TEMP_LO
    LDA Y_POS+1
    CMP TEMP_LO
    BCC CheckCPUTankCol
    
    LDA CANON_Y
    CMP Y_POS+1
    BCC CheckCPUTankCol
    
    LDA #1
    STA WAS_PLAYER_HIT
    SEC
    RTS

CheckCPUTankCol:
    ; 2. Collision Tank CPU (16 bits)
    LDA CIBLE_X
    SEC
    SBC #8
    STA TEMP_LO
    LDA CIBLE_X+1
    SBC #0
    STA TEMP_HI
    
    LDA X_POS+1
    SEC
    SBC TEMP_LO
    STA TEMP_VAL
    LDA X_POS+2
    SBC TEMP_HI
    BNE _no_cpu_hit
    
    LDA TEMP_VAL
    CMP #17             ; Largeur du tank (17 pixels)
    BCS _no_cpu_hit
    
    LDA Y_POS+2
    BNE _no_cpu_hit
    
    LDA CIBLE_Y
    SEC
    SBC #9
    STA TEMP_LO
    LDA Y_POS+1
    CMP TEMP_LO
    BCC _no_cpu_hit
    
    LDA CIBLE_Y
    CMP Y_POS+1
    BCC _no_cpu_hit
    
    LDA #1
    STA WAS_CPU_HIT
    SEC
    RTS
_no_cpu_hit
    CLC
    RTS

PlayExplosionSound:
    ; Impact au sol : déflagration moyenne et fracas de terre à pitch descendant
    LDA #30
    STA SOUND_PITCH
    LDY #70
_pes_p1:
    LDA $C030
    JSR SoundRand
    AND #$1F
    CLC
    ADC SOUND_PITCH
    TAX
-   NOP
    NOP
    DEX
    BNE -
    INC SOUND_PITCH
    DEY
    BNE _pes_p1
    
    LDA #90
    STA SOUND_PITCH
    LDY #90
_pes_p2:
    LDA $C030
    JSR SoundRand
    AND #$3F
    CLC
    ADC SOUND_PITCH
    TAX
-   NOP
    NOP
    NOP
    DEX
    BNE -
    INC SOUND_PITCH
    DEY
    BNE _pes_p2
    RTS

DigCrater:
    JSR PlayExplosionSound
DigCraterSilent:
    ; Creuse un cratere centre sur IMPACT_X (16 bits)
    LDA #0
    STA LOOP_IDX
    
DigCraterLoop:
    ; col = IMPACT_X - 12 + LOOP_IDX
    SEC
    LDA IMPACT_X
    SBC #12
    STA CUR_X_LO
    LDA IMPACT_X+1
    SBC #0
    STA CUR_X_HI
    
    CLC
    LDA CUR_X_LO
    ADC LOOP_IDX
    STA CUR_X_LO
    LDA CUR_X_HI
    ADC #0
    STA CUR_X_HI
    
    ; Vérification des limites x du terrain (0..279)
    LDA CUR_X_HI
    BPL +
    JMP NextCol
+   CMP #2
    BCC +
    JMP NextCol
+   CMP #1
    BNE _x_limit_ok
    LDA CUR_X_LO
    CMP #24
    BCC _x_limit_ok
    JMP NextCol
_x_limit_ok
    ; abs(dx)
    LDA LOOP_IDX
    CMP #12
    BCS _idx_ge_12
    LDA #12
    SEC
    SBC LOOP_IDX
    JMP _store_abs_dx
_idx_ge_12
    SEC
    SBC #12
_store_abs_dx
    STA ABS_DX
    
    ; depth = CRATER_TAB[abs(dx)]
    TAX
    LDA CRATER_TAB,X
    STA CRATER_DEPTH
    
    ; Y_current = TERRAIN_Y[col]
    LDX CUR_X_LO
    LDY CUR_X_HI
    BNE _y_curr_hi_1
    LDA TERRAIN_Y,X
    JMP _y_curr_stored
_y_curr_hi_1
    LDA TERRAIN_Y+256,X
_y_curr_stored
    STA Y_OLD
    
    ; Y_new = Y_current + depth
    CLC
    ADC CRATER_DEPTH
    CMP #160
    BCC _y_new_ok
    LDA #159
_y_new_ok
    STA Y_NEW
    
    ; TERRAIN_Y[col] = Y_new
    LDA Y_NEW
    LDY CUR_X_HI
    BNE _y_new_hi_1
    LDX CUR_X_LO
    STA TERRAIN_Y,X
    JMP _terrain_updated
_y_new_hi_1
    LDX CUR_X_LO
    STA TERRAIN_Y+256,X
_terrain_updated
    ; Effacement des pixels creusés (dessin en noir 0)
    LDX #0
    JSR HCOLOR
    
    LDA Y_OLD
    STA TEMP_Y
_erase_loop
    LDA TEMP_Y
    CMP Y_NEW
    BCS NextCol
    
    LDX CUR_X_LO
    LDY CUR_X_HI
    JSR HPLOT
    
    INC TEMP_Y
    JMP _erase_loop
    
NextCol:
    INC LOOP_IDX
    LDA LOOP_IDX
    CMP #25
    BEQ _dig_done
    JMP DigCraterLoop
_dig_done
    RTS

; =============================================================================
; EFFETS SPÉCIAUX : EXPLOSIONS ET TIRS
; =============================================================================
ExplodePlayerTank:
    LDA CANON_X
    STA EXPLODE_X
    LDA #0
    STA EXPLODE_X+1
    LDA CANON_Y
    SEC
    SBC #5
    STA EXPLODE_Y
    JMP DoExplosion

ExplodeEnemyTank:
    LDA CIBLE_X
    STA EXPLODE_X
    LDA CIBLE_X+1
    STA EXPLODE_X+1
    LDA CIBLE_Y
    SEC
    SBC #5
    STA EXPLODE_Y
    JMP DoExplosion

DoExplosion:
    ; =========================================================================
    ; ÉTAPE 1 : ALLUMAGE & FLASH BLANC PUR (R=6)
    ; =========================================================================
    ; Boule de feu blanche compacte R=6 au point d'impact
    LDX #3              ; Blanc
    JSR HCOLOR
    LDA #6
    STA EXPLODE_RAD
    LDA #<FIRE_R6
    STA PTR_LO
    LDA #>FIRE_R6
    STA PTR_HI
    JSR DrawFilledFireball
    
    ; Son 1 : Claquement sec de rupture et début de détonation
    JSR ExplosionSound1
    
    ; =========================================================================
    ; ÉTAPE 2 : EXPANSION GÉANTE ORANGE (R=12) & COEUR INCANDESCENT BLANC (R=6)
    ; =========================================================================
    ; Boule de feu orange étendue R=12 (recouvre totalement l'étape 1)
    LDX #5              ; Orange
    JSR HCOLOR
    LDA #12
    STA EXPLODE_RAD
    LDA #<FIRE_R12
    STA PTR_LO
    LDA #>FIRE_R12
    STA PTR_HI
    JSR DrawFilledFireball
    
    ; Coeur blanc super-brûlant R=6 au centre
    LDX #3              ; Blanc
    JSR HCOLOR
    LDA #6
    STA EXPLODE_RAD
    LDA #<FIRE_R6
    STA PTR_LO
    LDA #>FIRE_R6
    STA PTR_HI
    JSR DrawFilledFireball
    
    ; Son 2 : Rugissement puissant et déflagration lourde
    JSR ExplosionSound2
    
    ; =========================================================================
    ; ÉTAPE 3 : MÉGA DÉFLAGRATION PLASMA R=18 (LIGNES ALTERNÉES BLANC / ORANGE)
    ; =========================================================================
    ; Boule de feu maximale R=18 striée plasma Blanc / Orange (recouvre totalement R=12)
    LDA #18
    STA EXPLODE_RAD
    LDA #<FIRE_R18
    STA PTR_LO
    LDA #>FIRE_R18
    STA PTR_HI
    JSR DrawFireballStriped
    
    ; Son 3 : Fracas de tonnerre dévastateur et basses lourdes
    JSR ExplosionSound3
    
    ; =========================================================================
    ; ÉTAPE 4 : ONDE DE CHOC EN ANNEAU (ANNEAU ORANGE R=18, COEUR NOIR R=8)
    ; =========================================================================
    ; Boule orange R=18
    LDX #5              ; Orange
    JSR HCOLOR
    LDA #18
    STA EXPLODE_RAD
    LDA #<FIRE_R18
    STA PTR_LO
    LDA #>FIRE_R18
    STA PTR_HI
    JSR DrawFilledFireball
    
    ; Coeur noir évidé R=8 au centre (forme un anneau de flammes pur)
    LDX #0              ; Noir
    JSR HCOLOR
    LDA #8
    STA EXPLODE_RAD
    LDA #<FIRE_R8
    STA PTR_LO
    LDA #>FIRE_R8
    STA PTR_HI
    JSR DrawFilledFireball
    
    ; Son 4 : Onde de choc résonnante et écho
    JSR ExplosionSound4
    
    ; =========================================================================
    ; ÉTAPE 5 : OBLITÉRATION, EFFACEMENT NET DU FEU & CREUSEMENT DU CRATÈRE
    ; =========================================================================
    ; Efface complètement la boule de feu R=18 en noir (aucun pixel résiduel)
    LDX #0              ; Noir
    JSR HCOLOR
    LDA #18
    STA EXPLODE_RAD
    LDA #<FIRE_R18
    STA PTR_LO
    LDA #>FIRE_R18
    STA PTR_HI
    JSR DrawFilledFireball
    
    ; Creuse le cratère sombre dans le terrain à l'emplacement exact
    LDA EXPLODE_X
    STA IMPACT_X
    LDA EXPLODE_X+1
    STA IMPACT_X+1
    JSR DigCraterSilent
    
    ; Son 5 : Impact métallique au sol et grondement sismique
    JSR ExplosionSound5
    
    ; =========================================================================
    ; ÉTAPE 6 : VOLUTE DE FUMÉE ÉVANESCENTE AU-DESSUS DU CRATÈRE
    ; =========================================================================
    ; Bouffée de fumée violette au-dessus du cratère
    LDX #2              ; Violet
    JSR HCOLOR
    
    LDA EXPLODE_Y
    SEC
    SBC #16
    JSR ClampY
    STA SMOKE_CY
    LDA EXPLODE_X
    STA SMOKE_CX
    LDA EXPLODE_X+1
    STA SMOKE_CX+1
    
    LDA #6
    STA EXPLODE_RAD
    LDA #<FIRE_R6
    STA PTR_LO
    LDA #>FIRE_R6
    STA PTR_HI
    JSR DrawSmokePuff
    
    ; Pause visuelle pour laisser la fumée visible
    LDY #180
-   NOP
    NOP
    NOP
    NOP
    DEX
    BNE -
    DEY
    BNE -
    
    ; Effacement propre de la fumée en noir (le ciel redevient parfaitement net)
    LDX #0              ; Noir
    JSR HCOLOR
    LDA #6
    STA EXPLODE_RAD
    LDA #<FIRE_R6
    STA PTR_LO
    LDA #>FIRE_R6
    STA PTR_HI
    JSR DrawSmokePuff
    RTS

; --- Tracé de boule de feu pleine par lignes horizontales ---
DrawFilledFireball:
    LDA EXPLODE_RAD
    STA EXP_DY
_dff_loop:
    LDY EXP_DY
    LDA (PTR_LO),Y
    BEQ _dff_skip
    STA EXP_DX
    
    ; Ligne positive : EXPLODE_Y + dy
    LDA EXPLODE_Y
    CLC
    ADC EXP_DY
    JSR ClampY
    STA EXP_CUR_Y
    JSR DrawSpan
    
    LDA EXP_DY
    BEQ _dff_done
    
    ; Ligne négative : EXPLODE_Y - dy
    LDA EXPLODE_Y
    SEC
    SBC EXP_DY
    JSR ClampY
    STA EXP_CUR_Y
    JSR DrawSpan
    
_dff_skip:
    DEC EXP_DY
    BPL _dff_loop
_dff_done:
    RTS

; --- Boule de feu striée (lignes alternées Blanc / Orange) ---
DrawFireballStriped:
    LDA EXPLODE_RAD
    STA EXP_DY
_dfs_loop:
    LDY EXP_DY
    LDA (PTR_LO),Y
    BEQ _dfs_skip
    STA EXP_DX
    
    ; Ligne positive
    LDA EXP_DY
    AND #1
    BNE _dfs_col_pos_w
    LDX #5              ; Pair = Orange
    JMP _dfs_col_pos_set
_dfs_col_pos_w:
    LDX #3              ; Impair = Blanc
_dfs_col_pos_set:
    JSR HCOLOR
    
    LDA EXPLODE_Y
    CLC
    ADC EXP_DY
    JSR ClampY
    STA EXP_CUR_Y
    JSR DrawSpan
    
    LDA EXP_DY
    BEQ _dfs_done
    
    ; Ligne négative
    LDA EXP_DY
    AND #1
    BNE _dfs_col_neg_w
    LDX #5              ; Pair = Orange
    JMP _dfs_col_neg_set
_dfs_col_neg_w:
    LDX #3              ; Impair = Blanc
_dfs_col_neg_set:
    JSR HCOLOR
    
    LDA EXPLODE_Y
    SEC
    SBC EXP_DY
    JSR ClampY
    STA EXP_CUR_Y
    JSR DrawSpan
    
_dfs_skip:
    DEC EXP_DY
    BPL _dfs_loop
_dfs_done:
    RTS

; --- Trace un segment horizontal de -EXP_DX à +EXP_DX ---
DrawSpan:
    SEC
    LDA EXPLODE_X
    SBC EXP_DX
    STA EXP_X1_LO
    LDA EXPLODE_X+1
    SBC #0
    STA EXP_X1_HI
    JSR ClampX1
    
    CLC
    LDA EXPLODE_X
    ADC EXP_DX
    STA EXP_X2_LO
    LDA EXPLODE_X+1
    ADC #0
    STA EXP_X2_HI
    JSR ClampX2
    
    LDA EXP_CUR_Y
    LDX EXP_X1_LO
    LDY EXP_X1_HI
    JSR HPOSN
    
    LDA EXP_X2_LO
    LDY EXP_CUR_Y
    LDX EXP_X2_HI
    JSR HGLINE
    RTS

; --- Tracé d'une bouffée de fumée pleine et nette ---
DrawSmokePuff:
    LDA EXPLODE_RAD
    STA EXP_DY
_dsp_loop:
    LDY EXP_DY
    LDA (PTR_LO),Y
    BEQ _dsp_skip
    STA EXP_DX
    
    ; Ligne positive
    LDA SMOKE_CY
    CLC
    ADC EXP_DY
    JSR ClampY
    STA EXP_CUR_Y
    JSR DrawSmokeSpan
    
    LDA EXP_DY
    BEQ _dsp_done
    
    ; Ligne négative
    LDA SMOKE_CY
    SEC
    SBC EXP_DY
    JSR ClampY
    STA EXP_CUR_Y
    JSR DrawSmokeSpan
    
_dsp_skip:
    DEC EXP_DY
    BPL _dsp_loop
_dsp_done:
    RTS

DrawSmokeSpan:
    SEC
    LDA SMOKE_CX
    SBC EXP_DX
    STA EXP_X1_LO
    LDA SMOKE_CX+1
    SBC #0
    STA EXP_X1_HI
    JSR ClampX1
    
    CLC
    LDA SMOKE_CX
    ADC EXP_DX
    STA EXP_X2_LO
    LDA SMOKE_CX+1
    ADC #0
    STA EXP_X2_HI
    JSR ClampX2
    
    LDA EXP_CUR_Y
    LDX EXP_X1_LO
    LDY EXP_X1_HI
    JSR HPOSN
    
    LDA EXP_X2_LO
    LDY EXP_CUR_Y
    LDX EXP_X2_HI
    JSR HGLINE
    RTS

; --- Routines de cadrage coordonnées (Clamping) ---
ClampX1:
    LDA EXP_X1_HI
    BPL +
    LDA #0
    STA EXP_X1_LO
    STA EXP_X1_HI
+   RTS

ClampX2:
    LDA EXP_X2_HI
    BPL _cx2_not_neg
    LDA #0
    STA EXP_X2_LO
    STA EXP_X2_HI
    RTS
_cx2_not_neg:
    BEQ +
    LDA EXP_X2_LO
    CMP #24
    BCC +
    LDA #23
    STA EXP_X2_LO
+   RTS

ClampX2_X1:
    LDA EXP_X1_HI
    BPL _cx1_not_neg
    LDA #0
    STA EXP_X1_LO
    STA EXP_X1_HI
    RTS
_cx1_not_neg:
    BEQ +
    LDA EXP_X1_LO
    CMP #24
    BCC +
    LDA #23
    STA EXP_X1_LO
+   RTS

ClampY:
    BPL +
    LDA #0
    RTS
+   CMP #160
    BCC +
    LDA #159
+   RTS

; =============================================================================
; SYNTHÈSE SONORE RÉALISTE POUR HAUT-PARLEUR 1-BIT ($C030)
; =============================================================================

; --- Générateur pseudo-aléatoire Galois LFSR 8 bits pour bruit blanc ---
SoundRand:
    LDA SOUND_LFSR
    BNE +
    LDA #$6E            ; Seed de départ si 0
    STA SOUND_LFSR
+   LSR
    BCC +
    EOR #$B4            ; Polynôme maximal x^8 + x^7 + x^6 + x^1 + 1
+   STA SOUND_LFSR
    RTS

; --- Coup de canon percutant (Détonation, résonance de tube et grondement) ---
PlayFireSound:
    ; Phase 1 : Détonation de culasse percutante (pitch 16 -> 76)
    LDA #16
    STA SOUND_PITCH
    LDY #60
_pfs_p1:
    LDA $C030
    JSR SoundRand
    AND #$0F
    CLC
    ADC SOUND_PITCH
    TAX
-   NOP
    DEX
    BNE -
    INC SOUND_PITCH
    DEY
    BNE _pfs_p1
    
    ; Phase 2 : Résonance lourde de canon (pitch 60 -> 140)
    LDA #60
    STA SOUND_PITCH
    LDY #80
_pfs_p2:
    LDA $C030
    JSR SoundRand
    AND #$1F
    CLC
    ADC SOUND_PITCH
    TAX
-   NOP
    NOP
    DEX
    BNE -
    INC SOUND_PITCH
    DEY
    BNE _pfs_p2
    
    ; Phase 3 : Écho et onde de choc résiduelle (pitch 130 -> 190)
    LDA #130
    STA SOUND_PITCH
    LDY #60
_pfs_p3:
    LDA $C030
    JSR SoundRand
    AND #$3F
    CLC
    ADC SOUND_PITCH
    TAX
-   NOP
    NOP
    NOP
    DEX
    BNE -
    INC SOUND_PITCH
    DEY
    BNE _pfs_p3
    RTS

; --- Effets sonores de la grande explosion à balayage fréquentiel descendant ---

ExplosionSound1:
    ; Étape 1 : Claquement sec de rupture (300 clics, pitch 12 -> 49)
    LDA #12
    STA SOUND_PITCH
    LDX #2
    STX SOUND_OUTER
_es1_outer:
    LDY #150
_es1_loop:
    LDA $C030
    JSR SoundRand
    AND #$0F
    CLC
    ADC SOUND_PITCH
    TAX
-   NOP
    DEX
    BNE -
    TYA
    AND #7
    BNE +
    INC SOUND_PITCH
+   DEY
    BNE _es1_loop
    DEC SOUND_OUTER
    BNE _es1_outer
    RTS

ExplosionSound2:
    ; Étape 2 : Déflagration lourde et onde de choc (320 clics, pitch 45 -> 125)
    LDA #45
    STA SOUND_PITCH
    LDX #2
    STX SOUND_OUTER
_es2_outer:
    LDY #160
_es2_loop:
    LDA $C030
    JSR SoundRand
    AND #$1F
    CLC
    ADC SOUND_PITCH
    TAX
-   NOP
    NOP
    DEX
    BNE -
    TYA
    AND #3
    BNE +
    INC SOUND_PITCH
+   DEY
    BNE _es2_loop
    DEC SOUND_OUTER
    BNE _es2_outer
    RTS

ExplosionSound3:
    ; Étape 3 : Méga détonation plasma et basses profondes (300 clics, pitch 110 -> 185)
    LDA #110
    STA SOUND_PITCH
    LDX #2
    STX SOUND_OUTER
_es3_outer:
    LDY #150
_es3_loop:
    LDA $C030
    JSR SoundRand
    AND #$3F
    CLC
    ADC SOUND_PITCH
    TAX
-   NOP
    NOP
    NOP
    DEX
    BNE -
    TYA
    AND #3
    BNE +
    INC SOUND_PITCH
+   DEY
    BNE _es3_loop
    DEC SOUND_OUTER
    BNE _es3_outer
    RTS

ExplosionSound4:
    ; Étape 4 : Onde de choc en anneau et grondement (260 clics, pitch 170 -> 235)
    LDA #170
    STA SOUND_PITCH
    LDX #2
    STX SOUND_OUTER
_es4_outer:
    LDY #130
_es4_loop:
    LDA $C030
    JSR SoundRand
    AND #$3F
    CLC
    ADC SOUND_PITCH
    TAX
-   NOP
    NOP
    NOP
    NOP
    DEX
    BNE -
    TYA
    AND #3
    BNE +
    INC SOUND_PITCH
+   DEY
    BNE _es4_loop
    DEC SOUND_OUTER
    BNE _es4_outer
    RTS

ExplosionSound5:
    ; Étape 5 : Impact métallique au sol et grondement sismique (180 clics, pitch 210 -> 255)
    LDA #210
    STA SOUND_PITCH
    LDY #180
_es5_loop:
    LDA $C030
    JSR SoundRand
    AND #$3F
    CLC
    ADC SOUND_PITCH
    BCC +
    LDA #$FE
+   TAX
-   NOP
    NOP
    NOP
    NOP
    DEX
    BNE -
    TYA
    AND #1
    BNE +
    INC SOUND_PITCH
+   DEY
    BNE _es5_loop
    RTS

AddWave:
    ; Phase de la vague dans A, amplitude dans X
    STX TEMP_AMP
    JSR GetSin          ; A = valeur absolue, Y = signe
    STY TEMP_SIGN
    
    ; Scale: A = A * Amplitude / 256
    LDX TEMP_AMP
    STA MULT1
    STX MULT2
    JSR Multiply8_8
    LDA NUM+1           ; Partie haute du produit
    
    LDY TEMP_SIGN
    BNE SubtractWave
    
    CLC
    ADC CUR_HEIGHT
    STA CUR_HEIGHT
    RTS
SubtractWave:
    STA TEMP_SUB
    LDA CUR_HEIGHT
    SEC
    SBC TEMP_SUB
    STA CUR_HEIGHT
    RTS

GetSin:
    ; Convertit phase 0..255 en Sinus
    TAY
    LDA #0
    STA SIN_SIGN
    TYA
    BPL _get_sin_pos
    LDA #1
    STA SIN_SIGN
_get_sin_pos
    TYA
    AND #$7F
    CMP #64
    BCC _get_sin_q1
    EOR #$7F
    SEC
    ADC #0
_get_sin_q1
    TAX
    LDA SIN_TAB_64,X
    LDY SIN_SIGN
    RTS

DrawTankBody:
    JSR HCOLOR
    
    ; Dessine la base de YC-5 à YC-1
    LDA CUR_Y
    SEC
    SBC #5
    STA TEMP_Y
    LDA #6
    STA TEMP_AMP
    JSR DrawTankRow
    
    LDA CUR_Y
    SEC
    SBC #4
    STA TEMP_Y
    LDA #7
    STA TEMP_AMP
    JSR DrawTankRow
    
    LDA CUR_Y
    SEC
    SBC #3
    STA TEMP_Y
    LDA #8
    STA TEMP_AMP
    JSR DrawTankRow
    
    LDA CUR_Y
    SEC
    SBC #2
    STA TEMP_Y
    LDA #8
    STA TEMP_AMP
    JSR DrawTankRow
    
    LDA CUR_Y
    SEC
    SBC #1
    STA TEMP_Y
    LDA #8
    STA TEMP_AMP
    JSR DrawTankRow
    
    ; Chenilles/Roues (au niveau YC)
    LDA CUR_Y
    STA TEMP_Y
    
    SEC
    LDA CUR_X_LO
    SBC #7
    TAX
    LDA CUR_X_HI
    SBC #0
    TAY
    LDA TEMP_Y
    JSR HPLOT
    
    SEC
    LDA CUR_X_LO
    SBC #4
    TAX
    LDA CUR_X_HI
    SBC #0
    TAY
    LDA TEMP_Y
    JSR HPLOT
    
    SEC
    LDA CUR_X_LO
    SBC #1
    TAX
    LDA CUR_X_HI
    SBC #0
    TAY
    LDA TEMP_Y
    JSR HPLOT
    
    CLC
    LDA CUR_X_LO
    ADC #2
    TAX
    LDA CUR_X_HI
    ADC #0
    TAY
    LDA TEMP_Y
    JSR HPLOT
    
    CLC
    LDA CUR_X_LO
    ADC #5
    TAX
    LDA CUR_X_HI
    ADC #0
    TAY
    LDA TEMP_Y
    JSR HPLOT
    
    CLC
    LDA CUR_X_LO
    ADC #8
    TAX
    LDA CUR_X_HI
    ADC #0
    TAY
    LDA TEMP_Y
    JSR HPLOT
    
    JSR DrawTurretDome
    RTS

DrawTurretDome:
    JSR HCOLOR
    
    LDA CUR_Y
    SEC
    SBC #6
    STA TEMP_Y
    LDA #4
    STA TEMP_AMP
    JSR DrawTankRow
    
    LDA CUR_Y
    SEC
    SBC #7
    STA TEMP_Y
    LDA #3
    STA TEMP_AMP
    JSR DrawTankRow
    
    LDA CUR_Y
    SEC
    SBC #8
    STA TEMP_Y
    LDA #2
    STA TEMP_AMP
    JSR DrawTankRow
    
    LDA CUR_Y
    SEC
    SBC #9
    STA TEMP_Y
    LDA #1
    STA TEMP_AMP
    JSR DrawTankRow
    RTS

DrawTankRow:
    SEC
    LDA CUR_X_LO
    SBC TEMP_AMP
    STA TEMP_LO
    LDA CUR_X_HI
    SBC #0
    STA TEMP_HI
    
    CLC
    LDA CUR_X_LO
    ADC TEMP_AMP
    STA MULT1
    LDA CUR_X_HI
    ADC #0
    STA MULT2
    
_draw_row_loop
    LDA TEMP_Y
    LDX TEMP_LO
    LDY TEMP_HI
    JSR HPLOT
    
    INC TEMP_LO
    BNE _skip_hi_inc
    INC TEMP_HI
_skip_hi_inc
    LDA TEMP_LO
    CMP MULT1
    LDA TEMP_HI
    SBC MULT2
    BCC _draw_row_loop
    
    LDA TEMP_Y
    LDX MULT1
    LDY MULT2
    JSR HPLOT
    RTS

; =============================================================================
; VARIABLES ET ESPACE MÉMOIRE
; =============================================================================
SAVED_SP    .byte 0
RANDOM_SEED .word 0

ROUND_NUM   .byte 0
SHOT_COUNT  .byte 0
P1_SHOT_COUNT .byte 0
P2_SHOT_COUNT .byte 0
HIT_COUNT   .byte 0
SCORE_LO    .byte 0
SCORE_HI    .byte 0

P2_HIT_COUNT .byte 0
P2_SCORE_LO  .byte 0
P2_SCORE_HI  .byte 0

STAR_SEED    .word 0
SELF_HIT     .byte 0

WIND_VAL    .byte 0
WIND_ACC    .byte 0, 0, 0
TEMP_WIND   .byte 0, 0, 0
START_Y     .byte 0
STAR_X_LO   .byte 0
STAR_X_HI   .byte 0
STAR_Y_VAL  .byte 0

POINTS_LO   .byte 0
POINTS_HI   .byte 0

ANGLE       .byte 45
POWER       .byte 100

RESULT      .byte 0

; Variables de tour CPU
IS_CPU_TURN .byte 0
CPU_ANGLE   .byte 0
CPU_POWER   .byte 0
CPU_LAST_X  .byte 0
GAME_MODE   .byte 0             ; 0 = Ordi, 1 = 2 Joueurs
AMP1        .byte 25
AMP2        .byte 20
AMP3        .byte 18
AMP4        .byte 12

; Positions 24 bits
X_POS       .byte 0, 0, 0
Y_POS       .byte 0, 0, 0

; Vitesses 24 bits
V_X         .byte 0, 0, 0
V_Y         .byte 0, 0, 0
GRAVITY     .byte 0, 0, 0

CANON_X     .byte 0
CANON_Y     .byte 0
CIBLE_X     .word 0
CIBLE_Y     .byte 0

; Variables de calcul internes
TEMP        .byte 0
X_HI        .byte 0
TEMP_Y      .byte 0
TEMP_LO     .byte 0
TEMP_HI     .byte 0
TEMP_Y_COL  .byte 0
TEMP_X_DIFF .byte 0

MULT1       .byte 0
MULT2       .byte 0
NUM_INT     .byte 0
NUM_FRAC    .byte 0
TEMP_VAL    .byte 0
REM         .byte 0
NUM         .word 0
TEMP_NUM    .word 0

; Messages
MSG_R           .text "R:", 0
MSG_OF5         .text "/5 S:", 0
MSG_A           .text " A:", 0
MSG_P           .text " P:", 0
MSG_FIRE        .text " [SPC] TIR", 0

MSG_HIT         .text "TOUCHE !!!", 0
MSG_MISS        .text "RATE !", 0
MSG_OUT         .text "HORS LIMITES !", 0

MSG_CPU_THINK   .text "TOUR ORDI...", 0
MSG_CPU_MISS    .text "ORDI A RATE !", 0
MSG_CPU_HIT     .text "ORDI A TOUCHE !!!", 0

MSG_TITLE1      .text "JEU D'ARTILLERIE 6502", 0
MSG_MODE1       .text "1 - CONTRE L'ORDINATEUR", 0
MSG_MODE2       .text "2 - DEUX JOUEURS", 0
MSG_CHOICE      .text "VOTRE CHOIX (1 OU 2) ?", 0

MSG_GAMEOVER    .text "--- FIN DE LA PARTIE ---", 0
MSG_FINALSCORE  .text "SCORE FINAL : ", 0
MSG_FINALHITS   .text "TOUCHE : ", 0
MSG_OF5_SIMPLE  .text " / 5", 0
MSG_REPLAY      .text "REJOUER (O/N) ?", 0

MSG_J1_STAT     .text "J1: ", 0
MSG_LPAREN      .text " (", 0
MSG_OF5_STAT    .text "/5)       ", 0
MSG_J2_STAT     .text "J2: ", 0
MSG_ORDI_STAT   .text "ORDI: ", 0
MSG_RPAREN_STAT .text "/5)", 0

MSG_MANCHE      .text "MANCHE ", 0
MSG_WIND_LABEL  .text "     VENT: ", 0
MSG_WIND_NIL    .text "NUL", 0

MSG_P1_TURN     .text "J1 ANGL: ", 0
MSG_P2_TURN     .text "J2 ANGL: ", 0
MSG_CPU_TURN    .text "ORDI ANGL: ", 0
MSG_P_PUISS     .text " PUISS: ", 0

MSG_HELP_LINE   .text "[ESPACE] TIR  [A/Z] PUISS ", 0
MSG_COPYRIGHT   .text "(C) BACO 2026", 0
MSG_VERSION     .text "VERSION 2.2", 0

MSG_SELF_HIT     .text "AUTO-DESTRUCTION !", 0
MSG_P2_SELF_HIT  .text "J2 S'EST AUTO-DETRUIT !", 0
MSG_CPU_SELF_HIT .text "ORDI S'EST AUTO-DETRUIT !", 0

MSG_J1_FINAL    .text "JOUEUR 1  SCORE: ", 0
MSG_J2_FINAL    .text "JOUEUR 2  SCORE: ", 0
MSG_CPU_FINAL   .text "ORDINAT.  SCORE: ", 0
MSG_FINAL_HITS  .text "  HITS: ", 0
MSG_OF5_GAME    .text "/5", 0

MSG_J1_WINS     .text "  *** JOUEUR 1 A GAGNE ! ***", 0
MSG_J2_WINS     .text "  *** JOUEUR 2 A GAGNE ! ***", 0
MSG_YOU_WIN     .text "   *** VOUS AVEZ GAGNE ! ***", 0
MSG_CPU_WINS    .text " *** L'ORDINATEUR A GAGNE ! ***", 0
MSG_DRAW        .text "       *** EGALITE ! ***", 0

MSG_P1_PREFIX   .text "J1 R:", 0
MSG_P2_PREFIX   .text "J2 R:", 0
MSG_P2_MIDDLE   .text "/5        A:", 0

MSG_P1_HIT      .text "JOUEUR 1 A TOUCHE !", 0
MSG_P2_HIT      .text "JOUEUR 2 A TOUCHE !", 0
MSG_P1_MISS     .text "JOUEUR 1 A RATE !", 0
MSG_P2_MISS     .text "JOUEUR 2 A RATE !", 0

MSG_TERRAIN_T   .text "TAILLE DES MONTAGNES", 0
MSG_TERRAIN_1   .text "1 - PLAINE", 0
MSG_TERRAIN_2   .text "2 - COLLINE", 0
MSG_TERRAIN_3   .text "3 - MONTAGNE", 0
MSG_TERRAIN_C   .text "VOTRE CHOIX (1, 2 OU 3) ?", 0

; Table trigonométrique SIN(angle) * 256
SIN_TAB
    .byte 0, 4, 8, 13, 17, 22, 26, 31, 35, 40
    .byte 44, 48, 53, 57, 61, 66, 70, 74, 79, 83
    .byte 87, 91, 95, 100, 104, 108, 112, 116, 120, 124
    .byte 128, 131, 135, 139, 143, 146, 150, 154, 157, 161
    .byte 164, 167, 171, 174, 177, 181, 184, 187, 190, 193
    .byte 196, 199, 201, 204, 207, 209, 212, 214, 217, 219
    .byte 221, 223, 226, 228, 230, 232, 234, 235, 237, 239
    .byte 240, 242, 243, 244, 246, 247, 248, 249, 250, 251
    .byte 252, 253, 253, 254, 254, 254, 255, 255, 255, 255
    .byte 255

; =============================================================================
; VARIABLES ET TABLES ADDITIONNELLES POUR LE TERRAIN ET LES CRATÈRES
; =============================================================================
ACC1            .word 0
ACC2            .word 0
ACC3            .word 0
ACC4            .word 0
SIN_SIGN        .byte 0
CUR_HEIGHT      .byte 0
TEMP_AMP        .byte 0
TEMP_SIGN       .byte 0
TEMP_SUB        .byte 0
CUR_X_LO        .byte 0
CUR_X_HI        .byte 0
CUR_Y           .byte 0
LOOP_IDX        .byte 0
ABS_DX          .byte 0
CRATER_DEPTH    .byte 0
Y_OLD           .byte 0
Y_NEW           .byte 0
IMPACT_X        .word 0
WAS_PLAYER_HIT  .byte 0
WAS_CPU_HIT     .byte 0

EXPLODE_X       .word 0
EXPLODE_Y       .byte 0
EXPLODE_RAD     .byte 0
EXP_X1_LO       .byte 0
EXP_X1_HI       .byte 0
EXP_X2_LO       .byte 0
EXP_X2_HI       .byte 0
EXP_Y1          .byte 0
EXP_Y2          .byte 0

EXP_DX          .byte 0
EXP_DY          .byte 0
EXP_CUR_Y       .byte 0
SMOKE_CX        .word 0
SMOKE_CY        .byte 0
SMOKE_R         .byte 0
SOUND_LFSR      .byte $6E
SOUND_OUTER     .byte 0
SOUND_PITCH     .byte 0

; Tables de demi-largeurs pour boules de feu circulaires
FIRE_R6     .byte 6, 6, 6, 5, 4, 3, 1
FIRE_R8     .byte 8, 8, 8, 7, 7, 6, 5, 4, 1
FIRE_R12    .byte 12, 12, 12, 12, 11, 11, 10, 10, 9, 8, 7, 5, 2
FIRE_R18    .byte 18, 18, 18, 18, 18, 17, 17, 16, 16, 15, 15, 14, 13, 12, 11, 10, 8, 6, 3

TEMP_VX         .byte 0, 0, 0
TEMP_VY         .byte 0, 0, 0
TEMP_GRAV       .byte 0, 0, 0
SUBSTEP_CNT     .byte 0

CRATER_TAB      .byte 15, 14, 13, 12, 11, 10, 8, 7, 5, 4, 3, 2, 1

; Table de sinus pour un quadrant (64 pas = 90 degrés), valeurs 0..255
SIN_TAB_64
    .byte 0, 6, 13, 19, 25, 31, 37, 44, 50, 56, 62, 68, 74, 80, 86, 92, 98, 103, 109, 115, 120, 126, 131, 136, 142, 147, 152, 157, 162, 167, 171, 176, 180, 185, 189, 193, 197, 201, 205, 208, 212, 215, 219, 222, 225, 228, 231, 233, 236, 238, 240, 242, 244, 246, 247, 249, 250, 251, 252, 253, 254, 254, 255, 255, 255

P1_BUF1_LEN    .byte 0
P1_BUF1_X_LO   .fill 256, 0
P1_BUF1_X_HI   .fill 256, 0
P1_BUF1_Y      .fill 256, 0

P2_BUF1_LEN    .byte 0
P2_BUF1_X_LO   .fill 256, 0
P2_BUF1_X_HI   .fill 256, 0
P2_BUF1_Y      .fill 256, 0

TERRAIN_Y       .fill 280, 0
