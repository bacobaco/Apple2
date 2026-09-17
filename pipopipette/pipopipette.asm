* = $6000               

.cpu "6502"

    jmp Start           

; ===================================================================
; CONSTANTS AND MEMORY ADDRESSES
; ===================================================================
TXTCLR   = $C050        
TXTSET   = $C051        
MIXCLR   = $C052        
MIXSET   = $C053
TXTPAGE1 = $C054        
HIRES    = $C057        
PDL      = $FB1E        
BTN0     = $C061        
BTN1     = $C062        
KBD      = $C000        
KBDSTRB  = $C010        
SPEAKER  = $C030        

PTR      = $06          
TEMP_W   = $08          
TEMP_C   = $09          
X1LO     = $0A          
Y1       = $0B          
TEMP_HI  = $0C          
TEMP_MUL = $0D          
DRAW_X   = $0E          
DRAW_Y   = $0F          
COLOR    = $10          
TEMP_LEN = $11          
TEMP_CX  = $12
TEMP_DIGIT = $16
MC_ACC     = $17
TEMP_CY  = $13
STR_PTR  = $1A
FONT_PTR = $1C
SCROLL_X = $1E
SCROLL_T = $1F
HIRES_PAGE_OFF = $62 ; New ZP for page offset

TURN:             .byte 0
MODE:             .byte 0
P1_SCORE:         .byte 0
P2_SCORE:         .byte 0
GAME_OVER:        .byte 0
IS_BOLD:          .byte 0
BTN0_STATE:       .byte 0
BTN1_STATE:       .byte 0
CURSOR_X:         .byte 0
CURSOR_Y:         .byte 0
JOY_DIR_X:        .byte 0
JOY_DIR_Y:        .byte 0
CURSOR_ON:        .byte 0
BLINK_TIMER:      .byte 0
RANDOM_VAL:       .byte $55
NUM_BOXES_CLOSED: .byte 0
DIGIT0:           .byte 0
DIGIT1:           .byte 0
ABORT_AI:         .byte 0
TEMP_PTR:         .byte 0
TEMP_CHAR:        .byte 0
AI_LEVEL:         .byte 3 
PREV_CX:          .byte 0
PREV_CY:          .byte 0
PREV_MODE:        .byte 0
PREV_ON:          .byte 0
TEMP_LH_IND:      .byte 0
TEMP_LV_IND:      .byte 0
AI_LOOP_CTR:      .byte 0
TEMP_BT7:         .byte 0
PARITY_EN:        .byte 0
LOCAL_X:          .byte 0
BOX_LX:           .byte 0
BOX_LY:           .byte 0
BOX_LEN:          .byte 0
CURSOR_VIS_TEMP:  .byte 0

GRID_CONFIG_IDX:   .byte 0 ; 0=5x5, 1=6x6, 2=7x7
INTRO_SEL:         .byte 0
GRID_SIZE:         .byte 5
GRID_SIZE_P1:      .byte 6
GRID_SIZE_M1:      .byte 4
TOTAL_BOXES:       .byte 25
TOTAL_LH:          .byte 30
TOTAL_LV:          .byte 30
CELL_W:            .byte 30
CELL_H:            .byte 25
FILL_W:            .byte 24
FILL_H:            .byte 19
CUR_HW:            .byte 34
CUR_VH:            .byte 29
GRID_OFFSET_TABLE: .byte 0

LH: .fill 56, 0
LV: .fill 56, 0
BX: .fill 49, 0

SIM_MODE: .byte 0
SIM_P1:   .byte 0
SIM_P2:   .byte 0
SIM_TURN: .byte 0
SIM_NUM_BOXES: .byte 0
SIM_GAME_OVER: .byte 0
MC_X:     .byte 0
MC_Y:     .byte 0
MC_M:     .byte 0
MC_R:     .byte 0
BEST_SCORE: .byte 0
BEST_X:   .byte 0
BEST_Y:   .byte 0
BEST_M:   .byte 0
MC_ITER:  .byte 0
MC_TOTAL_CAND: .byte 0
MC_CAND_IDX:   .byte 0
CAND_M:        .fill 8, 0
CAND_X:        .fill 8, 0
CAND_Y:        .fill 8, 0
REMAINING_BOXES:  .byte 0
SAFE_COUNT:       .byte 0
CAND_HOLD_M:      .byte 0
CAND_HOLD_X:      .byte 0
CAND_HOLD_Y:      .byte 0
SIM_BASE_SCORE:   .byte 0

FSCS_BEST_SCORE:  .byte 0
FSCS_BEST_X:      .byte 0
FSCS_BEST_Y:      .byte 0
FSCS_BEST_M:      .byte 0
PREV_SIM_MODE:    .byte 0

REAL_LH:          .fill 56, 0
REAL_LV:          .fill 56, 0
REAL_BX:          .fill 49, 0
REAL_P1:          .byte 0
REAL_P2:          .byte 0
REAL_TURN:        .byte 0
REAL_NUM_BOXES:   .byte 0
REAL_GAME_OVER:   .byte 0
REAL_BASE_SCORE:  .byte 0

HO_CAND_M:        .byte 0
HO_CAND_X:        .byte 0
HO_CAND_Y:        .byte 0
SPINNER_STATE: .byte 0
SCROLL_IDX:    .byte 0
SCROLL_COUNT:  .byte 0
BANNER_TIMER:  .byte 0
BANNER_PHASE:  .byte 0
SIM_LH:   .fill 56, 0
SIM_LV:   .fill 56, 0
SIM_BX:   .fill 49, 0
MC_PROG_LO: .byte 0
MC_PROG_HI: .byte 0
FAREWELL_TEMP:     .byte 0
FAREWELL_PITCH:    .byte 0
FAREWELL_DUR:      .byte 0
FAREWELL_BX:       .byte 0
FAREWELL_BY:       .byte 0
FAREWELL_BW:       .byte 0
FAREWELL_BH:       .byte 0
FAREWELL_NOTE_IDX: .byte 0

HGR_LO:
.for y = 0, y < 192, y += 1
    .byte <($2000 + (y & 7) * 1024 + ((y / 8) & 7) * 128 + (y / 64) * 40)
.next

HGR_HI:
.for y = 0, y < 192, y += 1
    .byte >($2000 + (y & 7) * 1024 + ((y / 8) & 7) * 128 + (y / 64) * 40)
.next

X_COL_TAB:
.for x = 0, x < 256, x += 1
  .byte (x / 7)
.next

X_BIT_TAB:
.for x = 0, x < 256, x += 1
  .byte (x - ((x / 7) * 7))
.next

BIT_MASKS:
.byte $01, $02, $04, $08, $10, $20, $40

INV_BIT_MASKS:
.byte $FE, $FD, $FB, $F7, $EF, $DF, $BF

.include "fonttable.asm"

MsgP1:           .text "PLAYER",0
MsgP2:           .text "COMP",0
MsgLevel:        .text "NIV",0
MsgLvl1:         .text "1:BON",0
MsgLvl2:         .text "2:EXCELLENT",0
MsgLvl3:         .text "3:IMBATTABLE",0
MsgTitle:        .text "PIPOPIPETTE",0
MsgP1Wins:   .text "PLAYER WINS",0
MsgP2Wins:   .text "COMP WINS",0
MsgTie:      .text "EGALITE !",0
MsgReplay:   .text "REPLAY? Y/N",0
TitleColors: .byte 1, 6, 3, 1, 6, 3, 1, 6, 3, 1, 6
MsgLongScroll: .text " COMMANDES: FLECHES=BOUGER   ESPACE=PIVOTER   ENTREE=VALIDER   R=RESETER   1-3=NIVEAU IA    "
               .byte 0

MsgSubTitle:   .text "JEU DES PETITS CARRES",0
MsgChooseGrid: .text "CHOIX DE LA GRILLE:",0
MsgCard1A:     .text "1. GRILLE 5X5 - 25 CASES",0
MsgCard1B:     .text "   RAPIDE ET TACTIQUE",0
MsgCard2A:     .text "2. GRILLE 6X6 - 36 CASES",0
MsgCard2B:     .text "   STANDARD EQUILIBREE",0
MsgCard3A:     .text "3. GRILLE 7X7 - 49 CASES",0
MsgCard3B:     .text "   GRAND DEFI STRATEGIQUE",0
MsgIntroHelp1: .text "   1-3 OU FLECHES OU JOYSTICK",0
MsgIntroHelp2: .text "APPLE II - 100% ASEMBLEUR",0

Start:
    sta $C0E8          ; Turn OFF drive motor
    sta KBDSTRB
    lda #0
    sta HIRES_PAGE_OFF ; Ensure we start on Page 1
    
    bit TXTCLR
    sta MIXCLR
    sta HIRES
    jsr ShowIntroScreen

StartNewGame:
    jsr ClearScreen

    lda #0
    sta TURN
    sta MODE
    sta P1_SCORE
    sta P2_SCORE
    sta GAME_OVER
    sta JOY_DIR_X
    sta JOY_DIR_Y
    sta CURSOR_X
    sta CURSOR_Y
    sta CURSOR_ON
    sta BLINK_TIMER
    
    ldx #0
    txa
ClearArrs:
    sta LH,x
    sta LV,x
    cpx #49
    bcs +
    sta BX,x
+   inx
    cpx #56
    bcc ClearArrs
    
    lda #1
    sta BTN0_STATE
    sta BTN1_STATE
    
    jsr DrawLabels
    jsr DrawAllDots
    jsr RedrawScores

    lda #1
    sta CURSOR_ON
    lda #1
    jsr DrawCursor

MainLoop:
    jsr FrameEntropy
    inc BLINK_TIMER
    
    ; Toggle Banners every ~3 seconds (180 frames)
    inc BANNER_TIMER
    lda BANNER_TIMER
    cmp #180
    bcc +
    lda #0
    sta BANNER_TIMER
    lda BANNER_PHASE
    eor #1
    sta BANNER_PHASE
    jsr DrawStaticBanner
+   
    lda BLINK_TIMER
    cmp #20
    bcc ML_BlinkJoin
    lda #0 
    sta BLINK_TIMER
    
    lda TURN
    beq ML_PlayerBlink
    lda #0 ; Force OFF during AI turn
    sta CURSOR_ON
    jmp ML_BlinkJoin
ML_PlayerBlink:
    lda CURSOR_ON 
    eor #1 
    sta CURSOR_ON
ML_BlinkJoin:

    ; 2. Change Check & Refresh
    lda CURSOR_X 
    cmp PREV_CX 
    bne ML_NeedRefresh
    lda CURSOR_Y 
    cmp PREV_CY 
    bne ML_NeedRefresh
    lda MODE 
    cmp PREV_MODE 
    bne ML_NeedRefresh
    lda CURSOR_ON 
    cmp PREV_ON 
    bne ML_NeedRefresh
    jmp ML_InputPass

ML_NeedRefresh:
    ; ERASE PREV (at OLD position)
    lda PREV_ON 
    beq EraseDone
    lda CURSOR_X 
    pha ; Save NEW state on stack
    lda CURSOR_Y 
    pha
    lda MODE 
    pha
    
    lda PREV_CX 
    sta CURSOR_X ; Load OLD state
    lda PREV_CY 
    sta CURSOR_Y
    lda PREV_MODE 
    sta MODE
    lda #0 
    jsr DrawCursor ; Erase OLD
    
    pla 
    sta MODE ; Restore NEW state
    pla 
    sta CURSOR_Y
    pla 
    sta CURSOR_X
EraseDone:
    ; DRAW CURR (at NEW position)
    lda CURSOR_ON 
    beq DrawDone
    lda #1 
    jsr DrawCursor
DrawDone:
    ; Update PREV state
    lda CURSOR_X 
    sta PREV_CX
    lda CURSOR_Y 
    sta PREV_CY
    lda MODE 
    sta PREV_MODE
    lda CURSOR_ON 
    sta PREV_ON
    jmp MainLoop ; Restart frame, don't fallback to input

ML_InputPass:
    ; 3. Global Checks
    lda KBD
    bpl ML_NoKbd
    ; Don't clear strobe yet, let CheckKbdOnly/Handlers do it
    
    cmp #$B1 ; '1'
    beq +
    cmp #$B2 ; '2'
    beq +
    cmp #$B3 ; '3'
    beq +
    jmp k3 ; Skip to moves
+   jsr CheckKbdOnly
    jsr DrawLabels
    jmp JoyDone
k3  cmp #$8B ; Up Arrow
    bne k4
    jsr DoMoveUp
    sta KBDSTRB
    jmp JoyDone
k4  cmp #$8A ; Down Arrow
    bne k5
    jsr DoMoveDown
    sta KBDSTRB
    jmp JoyDone
k5  cmp #$88 ; Left Arrow
    bne k6
    jsr DoMoveLeft
    sta KBDSTRB
    jmp JoyDone
k6  cmp #$95 ; Right Arrow
    bne k7
    jsr DoMoveRight
    sta KBDSTRB
    jmp JoyDone
k7  cmp #$A0 ; Space
    bne k_r
    jsr DoModeToggle
    sta KBDSTRB
    jmp JoyDone
k_r cmp #$D2 ; 'R'
    beq +
    cmp #$F2 ; 'r'
    bne k8
+   sta KBDSTRB
    jmp Start
k8  cmp #$8D ; Enter
    bne ML_NoKbd
    jsr DoPlacer
    sta KBDSTRB
    jmp JoyDone
ML_NoKbd:

    lda P1_SCORE
    clc 
    adc P2_SCORE 
    cmp TOTAL_BOXES
    bne +
    jmp ML_GameOver
+   lda GAME_OVER 
    beq +
    jmp ML_GameOver
+
    
    lda TURN
    beq ML_PlayerTurn
    jsr AILogic
    jmp MainLoop

ML_PlayerTurn:
    ; Poll Buttons and Joystick

    ; Button 0 - Place
    lda BTN0
    bpl +
    lda BTN0_STATE 
    bne Btn0_Skip
    lda #1 
    sta BTN0_STATE
    jsr DoPlacer
    jmp Btn0_Skip
+   lda #0 
    sta BTN0_STATE
Btn0_Skip:

    ; Button 1 - Mode
    lda BTN1
    bpl +
    lda BTN1_STATE 
    bne Btn1_Skip
    lda #1 
    sta BTN1_STATE
    lda MODE 
    eor #1 
    sta MODE
    jsr ClampCursorByMode
    jmp Btn1_Skip
+   lda #0 
    sta BTN1_STATE
Btn1_Skip:

    ; Joystick (Stabilité AppleWin)
    bit $C070      ; Trigger paddles
    lda #$20       ; Wait a bit
    jsr $FCA8      ; Monitor Wait
    
    ldx #0 
    jsr PDL        ; Read X
    tya 
    cmp #192 
    bcs JX_R
    cmp #64 
    bcc JX_L
    lda #0 
    sta JOY_DIR_X 
    jmp CheckY
JX_R:
    lda JOY_DIR_X 
    cmp #1 
    beq CheckY
    lda #1 
    sta JOY_DIR_X 
    jsr DoMoveRight 
    jmp CheckY
JX_L:
    lda JOY_DIR_X 
    cmp #2 
    beq CheckY
    lda #2 
    sta JOY_DIR_X 
    jsr DoMoveLeft 

CheckY:
    lda #$20       ; New delay between axis
    jsr $FCA8      ; Monitor Wait
    ldx #1 
    jsr PDL        ; Read Y
    tya 
    cmp #192 
    bcs JY_D
    cmp #64 
    bcc JY_U
    lda #0 
    sta JOY_DIR_Y 
    jmp JoyDone
JY_D:
    lda JOY_DIR_Y 
    cmp #1 
    beq JoyDone
    lda #1 
    sta JOY_DIR_Y 
    jsr DoMoveDown 
    jmp JoyDone
JY_U:
    lda JOY_DIR_Y 
    cmp #2 
    beq JoyDone
    lda #2 
    sta JOY_DIR_Y 
    jsr DoMoveUp 
JoyDone:
    jmp MainLoop

ML_GameOver:
    jmp StateGameOver

; ===================================================================
; HELPER ENGINE
; ===================================================================
CheckAvailCursor:
    lda CURSOR_X
    sta TEMP_CX
    lda CURSOR_Y
    sta TEMP_CY
    jmp CheckAvailTemp ; Reuse the logic

CheckAvailTemp:
    lda MODE
    bne +
    ; Horizontal
    lda TEMP_CX
    cmp GRID_SIZE
    bcs CAT_Fail
    lda TEMP_CY
    cmp GRID_SIZE_P1
    bcs CAT_Fail
    lda TEMP_CX
    sta DRAW_X
    lda TEMP_CY
    sta DRAW_Y
    jsr GetIndLH
    tax
    lda LH,x
    rts
+   ; Vertical
    lda TEMP_CX
    cmp GRID_SIZE_P1
    bcs CAT_Fail
    lda TEMP_CY
    cmp GRID_SIZE
    bcs CAT_Fail
    lda TEMP_CX
    sta DRAW_X
    lda TEMP_CY
    sta DRAW_Y
    jsr GetIndLV
    tax
    lda LV,x
    rts
CAT_Fail:
    lda #1
    rts

FindAnyInMode:
    lda #0
    sta TEMP_CX
FAM_Y:
    lda #0
    sta TEMP_CY
FAM_X:
    jsr CheckAvailTemp
    bne +
    ; Found it! Set CURSOR
    lda TEMP_CX
    sta CURSOR_X
    lda TEMP_CY
    sta CURSOR_Y
    lda #0
    rts
+   inc TEMP_CY
    lda MODE
    beq FAM_CY_H
    lda TEMP_CY
    cmp GRID_SIZE
    bcc FAM_X
    jmp FAM_NextX
FAM_CY_H:
    lda TEMP_CY
    cmp GRID_SIZE_P1
    bcc FAM_X
FAM_NextX:
    inc TEMP_CX
    lda MODE
    beq FAM_CX_H
    lda TEMP_CX
    cmp GRID_SIZE_P1
    bcc FAM_Y
    jmp FAM_Fail
FAM_CX_H:
    lda TEMP_CX
    cmp GRID_SIZE
    bcc FAM_Y
FAM_Fail:
    lda #1
    rts

DrawCursor:
    sta CURSOR_VIS_TEMP
    lda CURSOR_X 
    sta TEMP_CX
    lda CURSOR_Y 
    sta TEMP_CY
    lda #0
    sta PARITY_EN
    lda CURSOR_VIS_TEMP
    beq DC_PlayerTurn ; Always allow erase
    lda TURN
    beq DC_PlayerTurn
    rts ; Hide drawing during AI turn
DC_PlayerTurn:
    lda CURSOR_VIS_TEMP
    cmp #1
    beq DC_SolidDraw
    
DC_Erase:
    lda #0
    sta PARITY_EN
    lda #0 ; Background color (Black)
    sta COLOR
    jmp DC_Draw

DC_SolidDraw:
    lda #3 ; Always White for selector frame
    sta COLOR
    jmp DC_Draw
DC_SolidFree: ; (Label kept for structure but ignored)

DC_Draw:
    lda MODE
    beq DCH
    jsr HGR_DrawV
    jsr RedrawLocalDots ; Redraw the two dots involved
    rts
DCH:
    jsr HGR_DrawH
    jsr RedrawLocalDots ; Redraw the two dots involved
    rts

RedrawLocalDots:
    lda #3 
    sta COLOR
    
    ; Dot 1 (Start)
    lda CURSOR_X 
    jsr GetDotX
    sta X1LO
    lda CURSOR_Y 
    jsr GetDotY
    sta Y1
    jsr DrawSingleDot
    
    ; Dot 2 (End)
    lda MODE
    bne RLD_Vert
    ; Horizontal: Dot is at (X+1, Y)
    lda CURSOR_X 
    clc 
    adc #1 
    jsr GetDotX
    sta X1LO
    lda CURSOR_Y 
    jsr GetDotY
    sta Y1
    jsr DrawSingleDot
    rts
RLD_Vert:
    ; Vertical: Dot is at (X, Y+1)
    lda CURSOR_X 
    jsr GetDotX
    sta X1LO
    lda CURSOR_Y 
    clc 
    adc #1 
    jsr GetDotY
    sta Y1
    jsr DrawSingleDot
    rts

DrawSingleDot:
    ; (X1LO, Y1) is center
    lda X1LO
    sec
    sbc #1
    sta DRAW_X
    lda Y1
    sta DRAW_Y
    lda #3
    sta TEMP_LEN
    jsr DrawHLine
    lda X1LO
    sta DRAW_X
    lda Y1
    sec
    sbc #1
    sta DRAW_Y
    lda #3
    sta TEMP_LEN
    jsr DrawVLine
    rts



HGR_DrawV:
    ; Vertical frame (W:4, H:CUR_VH)
    lda CURSOR_X
    jsr GetDotX
    sec
    sbc #2
    sta BOX_LX
    
    lda CURSOR_Y
    jsr GetDotY
    sec
    sbc #2
    sta BOX_LY
    
    ; Top
    lda BOX_LX
    sta X1LO
    lda BOX_LY
    sta Y1
    lda #4
    sta TEMP_LEN
    jsr DrawHLineFromX1
    ; Bottom
    lda BOX_LY
    clc
    adc CUR_VH
    sta Y1
    lda BOX_LX
    sta X1LO
    lda #4
    sta TEMP_LEN
    jsr DrawHLineFromX1
    ; Left
    lda BOX_LY
    sta Y1
    lda BOX_LX
    sta X1LO
    lda CUR_VH
    sta TEMP_LEN
    jsr DrawVLineFromX1
    ; Right
    lda BOX_LX
    clc
    adc #4
    sta X1LO
    lda BOX_LY
    sta Y1
    lda CUR_VH
    sta TEMP_LEN
    jsr DrawVLineFromX1
    rts

HGR_DrawH:
    ; Horizontal frame (W:CUR_HW, H:4)
    lda CURSOR_X
    jsr GetDotX
    sec
    sbc #2
    sta BOX_LX
    
    lda CURSOR_Y
    jsr GetDotY
    sec
    sbc #2
    sta BOX_LY
    
    ; Top
    lda BOX_LX
    sta X1LO
    lda BOX_LY
    sta Y1
    lda CUR_HW
    sta TEMP_LEN
    jsr DrawHLineFromX1
    ; Bottom
    lda BOX_LY
    clc
    adc #4
    sta Y1
    lda BOX_LX
    sta X1LO
    lda CUR_HW
    sta TEMP_LEN
    jsr DrawHLineFromX1
    ; Left
    lda BOX_LY
    sta Y1
    lda BOX_LX
    sta X1LO
    lda #4
    sta TEMP_LEN
    jsr DrawVLineFromX1
    ; Right
    lda BOX_LX
    clc
    adc CUR_HW
    sta X1LO
    lda BOX_LY
    sta Y1
    lda #4
    sta TEMP_LEN
    jsr DrawVLineFromX1
    rts

DoMoveRight:
    lda #1
    sta JOY_DIR_X
    lda #0
    sta BLINK_TIMER
    lda #100
    sta PREV_ON 
    lda CURSOR_X
    sta TEMP_W
    inc TEMP_W
    jsr CheckBoundsX
    beq +
    inc CURSOR_X
+   jsr ThinkDelay ; Anti-double-move
    rts

DoMoveLeft:
    lda #2
    sta JOY_DIR_X ; Priority skip
    lda #0
    sta BLINK_TIMER
    lda #100
    sta PREV_ON 
    lda CURSOR_X
    beq +
    dec CURSOR_X
+   jsr ThinkDelay ; Anti-double-move
    rts

DoMoveDown:
    lda #1
    sta JOY_DIR_Y
    lda #0
    sta BLINK_TIMER
    lda #100
    sta PREV_ON 
    lda CURSOR_Y
    sta TEMP_W
    inc TEMP_W
    jsr CheckBoundsY
    beq +
    inc CURSOR_Y
+   jsr ThinkDelay ; Anti-double-move
    rts

DoMoveUp:
    lda #2
    sta JOY_DIR_Y
    lda #0
    sta BLINK_TIMER
    lda #100
    sta PREV_ON 
    lda CURSOR_Y
    beq +
    dec CURSOR_Y
+   jsr ThinkDelay ; Anti-double-move
    rts





CheckBoundsX:
    lda MODE
    beq CBX_H
    ; Vertical
    lda TEMP_W
    cmp GRID_SIZE_P1
    rts
CBX_H:
    ; Horizontal
    lda TEMP_W
    cmp GRID_SIZE
    rts

CheckBoundsY:
    lda MODE
    beq CBY_H
    ; Vertical
    lda TEMP_W
    cmp GRID_SIZE
    rts
CBY_H:
    ; Horizontal
    lda TEMP_W
    cmp GRID_SIZE_P1
    rts

ClampCursorByMode:
    lda CURSOR_X
    sta TEMP_W
    jsr CheckBoundsX
    bcc +
    lda MODE
    beq CC_H_X
    lda GRID_SIZE
    sta CURSOR_X
    jmp +
CC_H_X:
    lda GRID_SIZE_M1
    sta CURSOR_X
+   lda CURSOR_Y
    sta TEMP_W
    jsr CheckBoundsY
    bcc +
    lda MODE
    beq CC_H_Y
    lda GRID_SIZE_M1
    sta CURSOR_Y
    rts
CC_H_Y:
    lda GRID_SIZE
    sta CURSOR_Y
+   rts

DoModeToggle:
    lda MODE
    eor #1
    sta MODE
    jsr ClampCursorByMode
    ; Force refresh cycle
    lda #1
    sta CURSOR_ON
    lda #100
    sta PREV_ON
    rts





FindFallbackOrNext:
    jsr FindAnyInMode
    beq FFN_OK
    lda MODE
    eor #1
    sta MODE
    jsr FindAnyInMode
FFN_OK:
    pha
    lda TEMP_CX
    sta CURSOR_X
    lda TEMP_CY
    sta CURSOR_Y
    pla
    rts


; ===================================================================
; GAME OVER & LABELS
; ===================================================================
DrawString:
    sty STR_PTR+1
    sta STR_PTR
    ldy #0
DS_Loop:
    lda (STR_PTR),y
    beq DS_Done ; Stop on 0
    cmp #255    ; Also stop on 255 for legacy strings
    beq DS_Done
    sty TEMP_HI
    jsr DrawChar
    lda X1LO
    clc
    adc #8
    ldx IS_BOLD
    beq +
    clc
    adc #1 ; Gain 1 pixel for bold spacing
+   sta X1LO
    ldy TEMP_HI
    iny
    jmp DS_Loop
DS_Done:
    rts

DrawLabels:
    lda #1
    sta IS_BOLD

    lda #1
    sta COLOR
    lda #2
    sta X1LO
    lda #60
    sta Y1
    lda #<MsgP1
    ldy #>MsgP1
    jsr DrawString
    
    lda #1
    sta COLOR
    lda #2
    sta X1LO
    lda #70
    sta Y1
    lda #48
    sta TEMP_LEN
    jsr DrawThickHLine
    
    lda #6
    sta COLOR
    lda #220
    sta X1LO
    lda #60
    sta Y1
    lda #<MsgP2
    ldy #>MsgP2
    jsr DrawString
    
    lda #6
    sta COLOR
    lda #220
    sta X1LO
    lda #70
    sta Y1
    lda #32
    sta TEMP_LEN
    jsr DrawThickHLine
    
    ; Difficulty Level Display
    jsr EraseAILvlBox
    lda #1
    sta IS_BOLD
    lda #3
    sta COLOR
    lda #110
    sta X1LO
    lda #5
    sta Y1
    lda #<MsgLevel
    ldy #>MsgLevel
    jsr DrawString
    
    lda AI_LEVEL
    cmp #1
    bne _DL_L2
    lda #<MsgLvl1
    ldy #>MsgLvl1
    jmp _DL_Draw
_DL_L2:
    cmp #2
    bne _DL_L3
    lda #<MsgLvl2
    ldy #>MsgLvl2
    jmp _DL_Draw
_DL_L3:
    lda #<MsgLvl3
    ldy #>MsgLvl3
_DL_Draw:
    jsr DrawString
    
    lda #0
    sta IS_BOLD ; Ensure bold is off for other things
    
    jsr DrawTitleColored
    jsr DrawStaticBanner
    rts

EraseAILvlBox:
    lda #4
    sta TEMP_HI
E_AI_YLoop:
    ldy TEMP_HI
    lda HGR_LO,y
    sta PTR
    lda HGR_HI,y
    sta PTR+1
    lda #0
    ldy #15
E_AI_XLoop:
    sta (PTR),y
    iny
    cpy #40 
    bcc E_AI_XLoop
    inc TEMP_HI
    lda TEMP_HI
    cmp #25 ; Lines 4 to 24, bytes 15 to 39
    bcc E_AI_YLoop
    rts

DrawTitleColored:
    lda #1
    sta IS_BOLD
    lda #8
    sta X1LO
    lda #5
    sta Y1
    ldy #0
DTC_Loop:
    lda MsgTitle,y
    beq DTC_Done
    cmp #255
    beq DTC_Done
    sty TEMP_HI
    
    lda TitleColors,y
    sta COLOR
    
    lda MsgTitle,y
    jsr DrawChar
    lda X1LO
    clc
    adc #8 ; Same tight spacing as PLayer/Comp (8 pixels per char)
    sta X1LO
    ldy TEMP_HI
    iny
    jmp DTC_Loop
DTC_Done:
    lda #0
    sta IS_BOLD
    
    ; Draw White Border (X=4 to 98, Y=3 to 16)
    lda #3
    sta COLOR
    
    ; Top Line
    lda #4
    sta X1LO
    lda #3
    sta Y1
    lda #95
    sta TEMP_LEN
    jsr DrawHLineFromX1
    
    ; Bottom Line
    lda #4
    sta X1LO
    lda #16
    sta Y1
    lda #95
    sta TEMP_LEN
    jsr DrawHLineFromX1
    
    ; Left Side
    lda #4
    sta X1LO
    lda #3
    sta Y1
    lda #14
    sta TEMP_LEN
    jsr DrawVLineFromX1
    
    ; Right Side
    lda #98
    sta X1LO
    lda #3
    sta Y1
    lda #14
    sta TEMP_LEN
    jsr DrawVLineFromX1
    rts

DrawWinner:
    lda P1_SCORE
    cmp P2_SCORE
    beq DrawTie
    bcc DrawOWins
    
    lda #1
    sta COLOR
    lda #97
    sta X1LO
    lda #165
    sta Y1
    lda #<MsgP1Wins
    ldy #>MsgP1Wins
    jsr DrawString
    rts
DrawTie:
    lda #3
    sta COLOR
    lda #100
    sta X1LO
    lda #165
    sta Y1
    lda #<MsgTie
    ldy #>MsgTie
    jsr DrawString
    rts
DrawOWins:
    lda #6
    sta COLOR
    lda #104
    sta X1LO
    lda #165
    sta Y1
    lda #<MsgP2Wins
    ldy #>MsgP2Wins
    jsr DrawString
    rts

PrintReplay:
    ; 1. Clear the banner area Y=182..191 one last time
    lda #182
    sta DRAW_Y
PR_Clear:
    lda DRAW_Y
    jsr HGR_ADDR
    ldy #0
    lda #0
-   sta (PTR),y
    iny
    cpy #40
    bcc -
    inc DRAW_Y
    lda DRAW_Y
    cmp #191
    bcc PR_Clear

    ; 2. Draw the Replay message in the cleared zone
    lda #96
    sta X1LO
    lda #182
    sta Y1
    lda #3
    sta COLOR
    lda #0
    sta IS_BOLD
    lda #<MsgReplay
    ldy #>MsgReplay
    jsr DrawString
    rts
    
StateGameOver:
    jsr EraseSpinner
    jsr DrawWinner
    jsr PrintReplay
EndWait:
    jsr FrameEntropy
    lda KBD
    bpl EndWait
    sta KBDSTRB
    
    and #$DF       
    cmp #$D9       ; 'Y' High ASCII
    beq DoReplay
    cmp #$CE       ; 'N' High ASCII
    beq DoQuit
    jmp EndWait
DoReplay:
    jmp Start
DoQuit:
    jmp FarewellAnim

; ===================================================================
; FAREWELL ANIMATION & CLEAN SYSTEM EXIT
; ===================================================================
FarewellAnim:
    lda #0
    sta HIRES_PAGE_OFF
    sta PARITY_EN
    sta KBDSTRB         ; Clear pending key

    ; 1. Curtains close wipe
    jsr FarewellCurtains

    ; 2. Animated expanding box frame with rising whoosh
    jsr FarewellExpandBox

    ; 3. Draw inner border & clear interior
    jsr FarewellDrawWindow

    ; 4. Draw farewell message lines
    jsr FarewellDrawText

    ; 5. Sparkling starfield & joyful ascending fanfare
    jsr FarewellFanfareAndStars

    ; 6. Smooth box collapse animation
    jsr FarewellCollapseBox

    ; 7. Clean text mode & return to DOS 3.3 / Applesoft
    jsr CleanExitToSystem

FarewellCurtains:
    ldx #0
FC_Loop:
    stx FAREWELL_TEMP
    txa
    jsr EraseOneHgrLine
    lda #191
    sec
    sbc FAREWELL_TEMP
    jsr EraseOneHgrLine
    
    lda SPEAKER         ; Mechanical zipper click
    ldy #80
-   dey
    bne -
    
    ldx FAREWELL_TEMP
    inx
    cpx #96
    bcc FC_Loop
    rts

EraseOneHgrLine:
    jsr HGR_ADDR
    ldy #0
    lda #0
-   sta (PTR),y
    iny
    cpy #40
    bcc -
    rts

FarewellExpandBox:
    ldx #0
FEB_Loop:
    stx FAREWELL_TEMP
    lda BoxTabX1,x
    sta FAREWELL_BX
    lda BoxTabY1,x
    sta FAREWELL_BY
    lda BoxTabW,x
    sta FAREWELL_BW
    lda BoxTabH,x
    sta FAREWELL_BH
    
    lda #3              ; White
    sta COLOR
    jsr DrawHollowBox
    
    ; Rising audio tone
    lda FAREWELL_TEMP
    asl
    asl
    asl
    asl
    clc
    adc #30
    ldx #22
    jsr PlayFarewellTone
    
    ldx FAREWELL_TEMP
    cpx #5
    beq FEB_Done
    
    lda #0              ; Erase
    sta COLOR
    jsr DrawHollowBox
    
    ldx FAREWELL_TEMP
    inx
    jmp FEB_Loop
FEB_Done:
    rts

FarewellDrawWindow:
    jsr ClearBoxInterior
    
    lda #43
    sta FAREWELL_BX
    lda #58
    sta FAREWELL_BY
    lda #194
    sta FAREWELL_BW
    lda #76
    sta FAREWELL_BH
    lda #1              ; Green inner frame
    sta COLOR
    jsr DrawHollowBox
    rts

ClearBoxInterior:
    ldx #57
CBI_LineLoop:
    txa
    jsr HGR_ADDR
    lda #0
    ldy #6
CBI_ColLoop:
    sta (PTR),y
    iny
    cpy #34
    bcc CBI_ColLoop
    inx
    cpx #136
    bcc CBI_LineLoop
    rts

DrawHollowBox:
    ; Top line
    lda FAREWELL_BX
    sta X1LO
    lda FAREWELL_BY
    sta Y1
    lda FAREWELL_BW
    sta TEMP_LEN
    jsr DrawHLineFromX1
    
    ; Bottom line
    lda FAREWELL_BX
    sta X1LO
    lda FAREWELL_BY
    clc
    adc FAREWELL_BH
    sta Y1
    lda FAREWELL_BW
    sta TEMP_LEN
    jsr DrawHLineFromX1
    
    ; Left line
    lda FAREWELL_BX
    sta X1LO
    lda FAREWELL_BY
    sta Y1
    lda FAREWELL_BH
    sta TEMP_LEN
    jsr DrawVLineFromX1
    
    ; Right line
    lda FAREWELL_BX
    clc
    adc FAREWELL_BW
    sta X1LO
    lda FAREWELL_BY
    sta Y1
    lda FAREWELL_BH
    sta TEMP_LEN
    jsr DrawVLineFromX1
    rts

FarewellDrawText:
    ; Line 1: "*** A BIENTOT ! ***"
    lda #1
    sta IS_BOLD
    lda #3              ; White
    sta COLOR
    lda #54
    sta X1LO
    lda #66
    sta Y1
    lda #<MsgBye1
    ldy #>MsgBye1
    jsr DrawString

    ; Line 2: "MERCI D'AVOIR JOUE"
    lda #0
    sta IS_BOLD
    lda #1              ; Green
    sta COLOR
    lda #68
    sta X1LO
    lda #82
    sta Y1
    lda #<MsgBye2
    ldy #>MsgBye2
    jsr DrawString

    ; Line 3: "A PIPOPIPETTE !"
    lda #1
    sta IS_BOLD
    lda #6              ; Blue
    sta COLOR
    lda #72
    sta X1LO
    lda #98
    sta Y1
    lda #<MsgBye3
    ldy #>MsgBye3
    jsr DrawString

    ; Line 4: "- A LA PROCHAINE -"
    lda #0
    sta IS_BOLD
    lda #3              ; White
    sta COLOR
    lda #68
    sta X1LO
    lda #114
    sta Y1
    lda #<MsgBye4
    ldy #>MsgBye4
    jsr DrawString
    
    lda #0
    sta IS_BOLD
    rts

FarewellFanfareAndStars:
    ldx #0
FF_Loop:
    stx FAREWELL_NOTE_IDX
    
    ; Erase old star if X >= 3
    cpx #3
    bcc +
    txa
    sec
    sbc #3
    tay
    lda StarTabX,y
    sta DRAW_X
    lda StarTabY,y
    sta DRAW_Y
    ldx #0              ; Erase color
    lda DRAW_X
    ldy DRAW_Y
    jsr DrawSparkleCross
    ldx FAREWELL_NOTE_IDX
+
    ; Draw new star
    lda StarTabX,x
    sta DRAW_X
    lda StarTabY,x
    sta DRAW_Y
    lda StarTabCol,x
    tax
    lda DRAW_X
    ldy DRAW_Y
    jsr DrawSparkleCross
    
    ; Play note
    ldx FAREWELL_NOTE_IDX
    lda FanfarePitches,x
    sta FAREWELL_PITCH
    lda FanfareDurations,x
    tax
    lda FAREWELL_PITCH
    jsr PlayFarewellTone
    
    ; Check if user pressed key to skip
    lda KBD
    bmi FF_Skip
    
    ; Short silence between notes (~15ms)
    ldx #15
_FF_Pause1:
    ldy #200
_FF_Pause2:
    dey
    bne _FF_Pause2
    dex
    bne _FF_Pause1
    
    ldx FAREWELL_NOTE_IDX
    inx
    cpx #12
    bcc FF_Loop
    
    ; Twinkle pause after fanfare (~1.5s or until key pressed)
    lda #20
    sta FAREWELL_TEMP
FF_Twinkle:
    lda KBD
    bmi FF_Skip
    
    lda FAREWELL_TEMP
    and #7
    tay
    lda StarTabX,y
    sta DRAW_X
    lda StarTabY,y
    sta DRAW_Y
    lda FAREWELL_TEMP
    and #3
    tax                 ; Color 0..3
    lda DRAW_X
    ldy DRAW_Y
    jsr DrawSparkleCross
    
    ldx #70
_FF_Twink1:
    ldy #200
_FF_Twink2:
    dey
    bne _FF_Twink2
    dex
    bne _FF_Twink1
    
    dec FAREWELL_TEMP
    bne FF_Twinkle

FF_Skip:
    sta KBDSTRB         ; Clear strobe
    rts

DrawSparkleCross:
    stx COLOR
    sta DRAW_X
    sty DRAW_Y
    lda #0
    sta PARITY_EN
    
    jsr PlotPixel
    dec DRAW_Y
    jsr PlotPixel
    inc DRAW_Y
    inc DRAW_Y
    jsr PlotPixel
    dec DRAW_Y
    dec DRAW_X
    jsr PlotPixel
    inc DRAW_X
    inc DRAW_X
    jsr PlotPixel
    rts

PlayFarewellTone:
    sta FAREWELL_PITCH
    stx FAREWELL_DUR
PFT_Cycle:
    lda SPEAKER
    ldy FAREWELL_PITCH
_PFT_D1:
    dey
    bne _PFT_D1
    lda SPEAKER
    ldy FAREWELL_PITCH
_PFT_D2:
    dey
    bne _PFT_D2
    dec FAREWELL_DUR
    bne PFT_Cycle
    rts

FarewellCollapseBox:
    ; Skip collapse if user pressed any key
    lda KBD
    bpl +
    sta KBDSTRB
    rts
+
    ; Erase inner frame
    lda #43
    sta FAREWELL_BX
    lda #58
    sta FAREWELL_BY
    lda #194
    sta FAREWELL_BW
    lda #76
    sta FAREWELL_BH
    lda #0
    sta COLOR
    jsr DrawHollowBox
    
    jsr ClearBoxInterior
    
    ldx #5
FCB_Loop:
    stx FAREWELL_TEMP
    lda BoxTabX1,x
    sta FAREWELL_BX
    lda BoxTabY1,x
    sta FAREWELL_BY
    lda BoxTabW,x
    sta FAREWELL_BW
    lda BoxTabH,x
    sta FAREWELL_BH
    
    lda #3              ; White
    sta COLOR
    jsr DrawHollowBox
    
    ; Descending pitch sweep
    lda #40
    clc
    adc FAREWELL_TEMP
    adc FAREWELL_TEMP
    adc FAREWELL_TEMP
    adc FAREWELL_TEMP
    ldx #18
    jsr PlayFarewellTone
    
    lda #0              ; Erase
    sta COLOR
    jsr DrawHollowBox
    
    ldx FAREWELL_TEMP
    dex
    bpl FCB_Loop
    
    ; Extra pause on black screen (~100ms)
    ldx #50
_FCB_Pause1:
    ldy #200
_FCB_Pause2:
    dey
    bne _FCB_Pause2
    dex
    bne _FCB_Pause1
    rts

CleanExitToSystem:
    ; 1. Hardware softswitches to force standard full text mode
    sta TXTSET          ; $C051: Text mode ON
    sta MIXCLR          ; $C052: Full screen text (no mixed graphics)
    sta TXTPAGE1        ; $C054: Page 1
    bit $C056           ; Lo-res (clears hires $C057)
    
    ; 2. Ensure normal text mode (White on Black)
    lda #$FF
    sta $32             ; INVFLG = $FF
    
    ; 3. Standard Apple II Monitor ROM routines
    jsr $FB2F           ; SETTXT: Window 40x24 (0, 40, 0, 24)
    jsr $FC58           ; HOME: Clear 40x24 text screen, cursor at (0,0)
    
    ; 4. Clear keyboard strobe
    sta KBDSTRB
    
    ; 5. 100% safe return to Applesoft BASIC prompt ']'
    jmp $E003

BoxTabX1: .byte 125, 110, 90, 70, 55, 40
BoxTabY1: .byte 90,  84,  76, 68, 62, 56
BoxTabW:  .byte 30,  60,  100, 140, 170, 200
BoxTabH:  .byte 12,  24,  40, 56, 68, 80

StarTabX:   .byte 30,  85,  140, 195, 245, 115, 35,  85,  140, 195, 240, 110
StarTabY:   .byte 20,  32,  16,  35,  22,  25,  155, 172, 150, 168, 155, 165
StarTabCol: .byte 3,   1,   6,   3,   1,   6,   3,   1,   6,   3,   1,   3

FanfarePitches:   .byte 130, 116, 103, 87,  103, 87,  65,  77,  65,  58,  52,  43
FanfareDurations: .byte 80,  80,  80,  110, 80,  110, 160, 90,  110, 120, 140, 240

MsgBye1: .text "*** A BIENTOT ! ***",0
MsgBye2: .text "MERCI D'AVOIR JOUE",0
MsgBye3: .text "A PIPOPIPETTE !",0
MsgBye4: .text "- A LA PROCHAINE -",0


; ===================================================================
; GAMEPLAY ENGINE
; ===================================================================
DoPlacer:
    lda MODE
    beq PlaceHoriz
    
    ; Bounds check V
    lda CURSOR_X
    cmp GRID_SIZE_P1
    bcs DP_Fail
    lda CURSOR_Y
    cmp GRID_SIZE
    bcs DP_Fail
    
    lda CURSOR_X
    sta DRAW_X
    lda CURSOR_Y
    sta DRAW_Y
    jsr GetIndLV
    sta TEMP_LV_IND
    tax
    lda LV,x
    beq VFree 
    rts
DP_Fail:
    rts
VFree:
    lda #1
    sta LV,x ; Temporary, will be overwritten in CommitPlace
    jmp CommitPlace

PlaceHoriz:
    ; Bounds check H
    lda CURSOR_X
    cmp GRID_SIZE
    bcs DP_Fail
    lda CURSOR_Y
    cmp GRID_SIZE_P1
    bcs DP_Fail
    
    lda CURSOR_X
    sta DRAW_X
    lda CURSOR_Y
    sta DRAW_Y
    jsr GetIndLH
    sta TEMP_LH_IND
    tax
    lda LH,x
    beq HFree
    rts
HFree:
    lda #1
    sta LH,x

CommitPlace:
    lda SIM_MODE
    bne CP_SimModeSkip1
    jsr ClickSound
CP_SimModeSkip1:
    
    lda TURN
    beq SetColP1
    lda #6      ; Blue for P2
    jmp SetColDone
SetColP1:
    lda #1      ; Green for P1
SetColDone:
    sta COLOR
    
    ; Store the actual color in the map!
    pha
    lda MODE
    beq +
    ; Vertical
    pla
    pha
    ldx TEMP_LV_IND
    sta LV,x
    jmp P_PlDone
+   ; Horizontal
    pla
    pha
    ldx TEMP_LH_IND
    sta LH,x
P_PlDone:
    pla
    
    lda SIM_MODE
    bne CP_SimModeSkip2
    
    lda #100
    sta PREV_ON ; Force refresh after play
    
    lda CURSOR_X
    jsr GetDotX
    sta X1LO
    lda CURSOR_Y
    jsr GetDotY
    sta Y1
    
    lda MODE
    beq Pl_H
    lda CELL_H
    sta TEMP_LEN
    jsr DrawThickVLine
    jmp Pl_Done
Pl_H:
    lda CELL_W
    sta TEMP_LEN
    jsr DrawThickHLine
Pl_Done:
CP_SimModeSkip2:
    
    jsr BoxCheck
    
    ; Check Game Over
    lda P1_SCORE
    clc
    adc P2_SCORE
    cmp TOTAL_BOXES
    bne +
    inc GAME_OVER
+   
    lda NUM_BOXES_CLOSED
    bne KeepTurn
    lda TURN
    eor #1
    sta TURN
KeepTurn:
PlacerRet:
PlacerDone:
    rts
    
Pl_ExitSkip:
    rts

; Box Verification Logic
BoxCheck:
    lda #0
    sta NUM_BOXES_CLOSED
    lda MODE
    beq CheckHoriz
    jmp CheckVert

CheckHoriz:
    lda CURSOR_Y
    beq CH_SkipUp
    lda CURSOR_X
    sta X1LO        
    lda CURSOR_Y
    sec
    sbc #1
    sta Y1
    jsr CheckSingleBox
CH_SkipUp:
    lda CURSOR_Y
    cmp GRID_SIZE
    bcs CH_SkipDown
    lda CURSOR_X
    sta X1LO
    lda CURSOR_Y
    sta Y1
    jsr CheckSingleBox
CH_SkipDown:
    rts

CheckVert:
    lda CURSOR_X
    beq CV_SkipLeft
    lda CURSOR_X
    sec
    sbc #1
    sta X1LO
    lda CURSOR_Y
    sta Y1
    jsr CheckSingleBox
CV_SkipLeft:
    lda CURSOR_X
    cmp GRID_SIZE
    bcs CV_SkipRight
    lda CURSOR_X
    sta X1LO
    lda CURSOR_Y
    sta Y1
    jsr CheckSingleBox
CV_SkipRight:
    rts

CheckSingleBox:
    ; Check Top
    lda X1LO
    sta DRAW_X
    lda Y1
    sta DRAW_Y
    jsr GetIndLH
    tax
    lda LH,x
    beq CSB_NotClosed
    ; Check Bottom
    lda X1LO
    sta DRAW_X
    lda Y1
    clc
    adc #1
    sta DRAW_Y
    jsr GetIndLH
    tax
    lda LH,x
    beq CSB_NotClosed
    ; Check Left
    lda X1LO
    sta DRAW_X
    lda Y1
    sta DRAW_Y
    jsr GetIndLV
    tax
    lda LV,x
    beq CSB_NotClosed
    ; Check Right
    lda X1LO
    clc
    adc #1
    sta DRAW_X
    lda Y1
    sta DRAW_Y
    jsr GetIndLV
    tax
    lda LV,x
    beq CSB_NotClosed
    ; All 4 sides present!
    jmp BoxIsClosed
CSB_NotClosed:
    rts

BoxIsClosed:
    lda X1LO
    sta DRAW_X
    lda Y1
    sta DRAW_Y
    jsr GetIndBX
    tax
    lda BX,x
    beq CSB_Next5
    rts
CSB_Next5:
    lda TURN
    clc
    adc #1
    sta BX,x
    inc NUM_BOXES_CLOSED
    
    lda TURN
    beq P1Cl
    inc P2_SCORE
    jmp ScDone
P1Cl:
    inc P1_SCORE
ScDone:
    lda SIM_MODE
    bne ScDoneSim
    
    lda X1LO
    pha
    lda Y1
    pha
    jsr RedrawScores
    pla
    sta Y1
    pla
    sta X1LO
    jsr BoxSound
    jsr GfxFillBox
ScDoneSim:
    rts

GfxFillBox:
    lda X1LO
    cmp GRID_SIZE
    bcc +
    rts ; Safety
+   jsr GetDotX
    clc
    adc #3
    sta DRAW_X
    pha                 
    
    lda Y1
    cmp GRID_SIZE
    bcc +
    pla ; restore stack
    rts ; Safety
+   jsr GetDotY
    clc
    adc #3
    sta DRAW_Y
    
    lda TURN
    beq SetGrn
    lda #6
    sta COLOR
    jmp FillGo
SetGrn:
    lda #1
    sta COLOR

FillGo:
    lda FILL_H
    sta TEMP_C
FillY:
    pla
    pha                 
    sta DRAW_X
    lda FILL_W
    sta TEMP_LEN
FillX:
    lda COLOR
    cmp #1
    beq CheckOdd
    cmp #6
    beq CheckEv
    jsr PlotPixel
    jmp SkP
CheckOdd:
    lda DRAW_X
    and #1
    beq SkP
    jsr PlotPixel
    jmp SkP
CheckEv:
    lda DRAW_X
    and #1
    bne SkP
    jsr PlotPixel
SkP:
    inc DRAW_X
    dec TEMP_LEN
    bne FillX
    
    inc DRAW_Y
    dec TEMP_C
    bne FillY
    pla                 
    rts

; ===================================================================
; AI LOGIC
; ===================================================================
AILogic:
    lda #0
    sta ABORT_AI
    jsr ThinkDelay

    ; Level 3 handles its own captures with Double-Cross intelligence!
    lda AI_LEVEL
    cmp #3
    beq AI_Level3

    ; Level 1 & 2: Always take any immediate 3-sided box greedily
    jsr ScanClose
    bcs FoundSmartMove
    
    lda AI_LEVEL
    cmp #1
    bne +
    jmp AI_Level1
+   jmp AI_Level2

AI_Level1:
    jsr ScanSafe
    bcs FoundSmartMove
    jmp AIRetry

AI_Level2:
    jsr FindBestSafeMove
    bcs FoundSmartMove
    jsr FindMinSacrificeMove
    bcs FoundSmartMove
    jmp AIRetry

AI_Level3:
    ; Level 3: Master Engine (Double-Cross & Shortest Chain Sacrifice)
    ; 1. If 3-sided box exists, run ExpertCaptureChain
    jsr ScanClose
    bcc _L3_NoCapture
    jsr ExpertCaptureChain
    rts

_L3_NoCapture:
    ; 2. If safe moves exist, play the best strategic safe move
    jsr HasAnySafeMove
    bcc _L3_Sacrifice
    jsr ExpertBestSafeMove
    bcs FoundSmartMove

_L3_Sacrifice:
    ; 3. No safe moves: calculate and sacrifice the SHORTEST chain
    jsr FindShortestChainSacrifice
    bcs FoundSmartMove
    jmp AIRetry

AIRetry:
    jsr LFSR
    and #1
    sta MODE
    
    jsr LFSR
    lda #0
    sta AI_LOOP_CTR
AIRetryLoop:
    jsr LFSR
    and #7
    sta CURSOR_X
    jsr LFSR
    and #7
    sta CURSOR_Y
    jsr LFSR
    and #1
    sta MODE
    
    jsr CheckAvailCursor
    beq FoundSmartMove
    
    inc AI_LOOP_CTR
    lda AI_LOOP_CTR
    cmp #255
    bcc AIRetryLoop            
    
    jsr FindFallbackOrNext
    beq FoundSmartMove
    jsr EraseSpinner
    rts

FoundSmartMove:
    jsr EraseSpinner
    jsr DoPlacer
    rts

ScanClose:
    lda #0
    sta TEMP_CX
SC_LoopY:
    lda #0
    sta TEMP_CY
SC_LoopX:
    jsr CountSides
    cmp #3
    beq SC_CloseIt
    inc TEMP_CY
    lda TEMP_CY
    cmp GRID_SIZE
    bcc SC_LoopX
    inc TEMP_CX
    lda TEMP_CX
    cmp GRID_SIZE
    bcc SC_LoopY
    clc
    rts
SC_CloseIt:
    ; Find missing side
    lda TEMP_CX
    sta DRAW_X
    lda TEMP_CY
    sta DRAW_Y
    jsr GetIndLH ; Top
    tax
    lda LH,x
    bne SC_B
    lda #0
    sta MODE
    lda TEMP_CX
    sta CURSOR_X
    lda TEMP_CY
    sta CURSOR_Y
    sec
    rts
SC_B:
    lda TEMP_CY
    clc
    adc #1
    sta DRAW_Y
    jsr GetIndLH ; Bottom
    tax
    lda LH,x
    bne SC_L
    lda #0
    sta MODE
    lda TEMP_CX
    sta CURSOR_X
    lda TEMP_CY
    clc
    adc #1
    sta CURSOR_Y
    sec
    rts
SC_L:
    lda TEMP_CX
    sta DRAW_X
    lda TEMP_CY
    sta DRAW_Y
    jsr GetIndLV ; Left
    tax
    lda LV,x
    bne SC_R
    lda #1
    sta MODE
    lda TEMP_CX
    sta CURSOR_X
    lda TEMP_CY
    sta CURSOR_Y
    sec
    rts
SC_R:
    lda #1
    sta MODE
    lda TEMP_CX
    clc
    adc #1
    sta CURSOR_X
    lda TEMP_CY
    sta CURSOR_Y
    sec
    rts

ScanSafe:
    lda #0
    sta MODE
SS_ModeLoop:
    lda #0
    sta CURSOR_Y
SS_YLoop:
    lda #0
    sta CURSOR_X
SS_XLoop:
    lda CURSOR_X
    sta TEMP_CX
    lda CURSOR_Y
    sta TEMP_CY
    jsr CheckAvailTemp
    bne SS_NextPoint
    
    jsr IsSafe
    beq SS_NextPoint
    sec
    rts
SS_NextPoint:
    inc CURSOR_X
    lda MODE
    beq _SS_Horiz
    lda CURSOR_X
    cmp GRID_SIZE_P1
    bcc SS_XLoop
    inc CURSOR_Y
    lda CURSOR_Y
    cmp GRID_SIZE
    bcc SS_YLoop
    jmp _SS_NextMode
_SS_Horiz:
    lda CURSOR_X
    cmp GRID_SIZE
    bcc SS_XLoop
    inc CURSOR_Y
    lda CURSOR_Y
    cmp GRID_SIZE_P1
    bcc SS_YLoop
_SS_NextMode:
    inc MODE
    lda MODE
    cmp #2
    bcc SS_ModeLoop
    clc
    rts

HasAnySafeMove:
    jsr ScanSafe
    rts

FindBestSafeMove:
    lda #0
    sta BEST_SCORE
    sta MODE
FBSM_MLoop:
    lda #0
    sta CURSOR_Y
FBSM_YLoop:
    lda #0
    sta CURSOR_X
FBSM_XLoop:
    jsr CheckAvailTemp
    beq _FBSM_IsAvail
    jmp FBSM_Next
_FBSM_IsAvail:
    jsr IsSafe
    bne _FBSM_IsSafe
    jmp FBSM_Next
_FBSM_IsSafe:
    ; Candidate is safe! Compute safety quality score (base 10)
    lda #10
    sta TEMP_DIGIT
    
    lda MODE
    bne FBSM_Vert
    ; Horiz (Box Up, Box Down)
    lda CURSOR_Y
    beq _FBSM_H_UpDone
    lda CURSOR_X
    sta TEMP_CX
    lda CURSOR_Y
    sec
    sbc #1
    sta TEMP_CY
    jsr CountSides
    cmp #0
    bne _FBSM_H_Up1
    lda TEMP_DIGIT
    clc
    adc #6
    sta TEMP_DIGIT
    jmp _FBSM_H_UpDone
_FBSM_H_Up1:
    lda TEMP_DIGIT
    clc
    adc #2
    sta TEMP_DIGIT
_FBSM_H_UpDone:
    lda CURSOR_Y
    cmp GRID_SIZE
    bcs FBSM_EvalDone
    lda CURSOR_X
    sta TEMP_CX
    lda CURSOR_Y
    sta TEMP_CY
    jsr CountSides
    cmp #0
    bne _FBSM_H_Dn1
    lda TEMP_DIGIT
    clc
    adc #6
    sta TEMP_DIGIT
    jmp FBSM_EvalDone
_FBSM_H_Dn1:
    lda TEMP_DIGIT
    clc
    adc #2
    sta TEMP_DIGIT
    jmp FBSM_EvalDone

FBSM_Vert:
    lda CURSOR_X
    beq _FBSM_V_LeftDone
    lda CURSOR_X
    sec
    sbc #1
    sta TEMP_CX
    lda CURSOR_Y
    sta TEMP_CY
    jsr CountSides
    cmp #0
    bne _FBSM_V_Left1
    lda TEMP_DIGIT
    clc
    adc #6
    sta TEMP_DIGIT
    jmp _FBSM_V_LeftDone
_FBSM_V_Left1:
    lda TEMP_DIGIT
    clc
    adc #2
    sta TEMP_DIGIT
_FBSM_V_LeftDone:
    lda CURSOR_X
    cmp GRID_SIZE
    bcs FBSM_EvalDone
    lda CURSOR_X
    sta TEMP_CX
    lda CURSOR_Y
    sta TEMP_CY
    jsr CountSides
    cmp #0
    bne _FBSM_V_Right1
    lda TEMP_DIGIT
    clc
    adc #6
    sta TEMP_DIGIT
    jmp FBSM_EvalDone
_FBSM_V_Right1:
    lda TEMP_DIGIT
    clc
    adc #2
    sta TEMP_DIGIT

FBSM_EvalDone:
    jsr LFSR
    and #1
    clc
    adc TEMP_DIGIT
    sta TEMP_DIGIT
    
    cmp BEST_SCORE
    bcc FBSM_Next
    sta BEST_SCORE
    lda MODE
    sta BEST_M
    lda CURSOR_X
    sta BEST_X
    lda CURSOR_Y
    sta BEST_Y

FBSM_Next:
    inc CURSOR_X
    lda MODE
    beq _FBSM_StepHoriz
    lda CURSOR_X
    cmp GRID_SIZE_P1
    bcs +
    jmp FBSM_XLoop
+   inc CURSOR_Y
    lda CURSOR_Y
    cmp GRID_SIZE
    bcs +
    jmp FBSM_YLoop
+   jmp _FBSM_StepMode
_FBSM_StepHoriz:
    lda CURSOR_X
    cmp GRID_SIZE
    bcs +
    jmp FBSM_XLoop
+   inc CURSOR_Y
    lda CURSOR_Y
    cmp GRID_SIZE_P1
    bcs +
    jmp FBSM_YLoop
+
_FBSM_StepMode:
    inc MODE
    lda MODE
    cmp #2
    bcs +
    jmp FBSM_MLoop
+
    lda BEST_SCORE
    beq FBSM_Fail
    lda BEST_M
    sta MODE
    lda BEST_X
    sta CURSOR_X
    lda BEST_Y
    sta CURSOR_Y
    sec
    rts
FBSM_Fail:
    clc
    rts

FindMinSacrificeMove:
    lda #255
    sta BEST_SCORE
    lda #0
    sta MODE
FMS_MLoop:
    lda #0
    sta CURSOR_Y
FMS_YLoop:
    lda #0
    sta CURSOR_X
FMS_XLoop:
    jsr CheckAvailTemp
    beq _FMS_IsAvail
    jmp FMS_Next
_FMS_IsAvail:
    lda #0
    sta TEMP_DIGIT
    lda MODE
    bne FMS_Vert
    ; Horiz
    lda CURSOR_Y
    beq _FMS_H_UpDone
    lda CURSOR_X
    sta TEMP_CX
    lda CURSOR_Y
    sec
    sbc #1
    sta TEMP_CY
    jsr CountSides
    cmp #2
    bne _FMS_H_UpDone
    inc TEMP_DIGIT
_FMS_H_UpDone:
    lda CURSOR_Y
    cmp GRID_SIZE
    bcs FMS_CheckScore
    lda CURSOR_X
    sta TEMP_CX
    lda CURSOR_Y
    sta TEMP_CY
    jsr CountSides
    cmp #2
    bne FMS_CheckScore
    inc TEMP_DIGIT
    jmp FMS_CheckScore

FMS_Vert:
    lda CURSOR_X
    beq _FMS_V_LeftDone
    lda CURSOR_X
    sec
    sbc #1
    sta TEMP_CX
    lda CURSOR_Y
    sta TEMP_CY
    jsr CountSides
    cmp #2
    bne _FMS_V_LeftDone
    inc TEMP_DIGIT
_FMS_V_LeftDone:
    lda CURSOR_X
    cmp GRID_SIZE
    bcs FMS_CheckScore
    lda CURSOR_X
    sta TEMP_CX
    lda CURSOR_Y
    sta TEMP_CY
    jsr CountSides
    cmp #2
    bne FMS_CheckScore
    inc TEMP_DIGIT

FMS_CheckScore:
    lda TEMP_DIGIT
    cmp BEST_SCORE
    bcs FMS_Next
    sta BEST_SCORE
    lda MODE
    sta BEST_M
    lda CURSOR_X
    sta BEST_X
    lda CURSOR_Y
    sta BEST_Y

FMS_Next:
    inc CURSOR_X
    lda MODE
    beq _FMS_StepHoriz
    lda CURSOR_X
    cmp GRID_SIZE_P1
    bcs +
    jmp FMS_XLoop
+   inc CURSOR_Y
    lda CURSOR_Y
    cmp GRID_SIZE
    bcs +
    jmp FMS_YLoop
+   jmp _FMS_StepMode
_FMS_StepHoriz:
    lda CURSOR_X
    cmp GRID_SIZE
    bcs +
    jmp FMS_XLoop
+   inc CURSOR_Y
    lda CURSOR_Y
    cmp GRID_SIZE_P1
    bcs +
    jmp FMS_YLoop
+
_FMS_StepMode:
    inc MODE
    lda MODE
    cmp #2
    bcs +
    jmp FMS_MLoop
+
    lda BEST_SCORE
    cmp #255
    beq FMS_Fail
    lda BEST_M
    sta MODE
    lda BEST_X
    sta CURSOR_X
    lda BEST_Y
    sta CURSOR_Y
    sec
    rts
FMS_Fail:
    clc
    rts

; ===================================================================
; ROLLOUT SIMULATION ENGINE (Level 3 AI)
; ===================================================================

RunRollout:
_RR_Loop:
    ; Are all boxes closed?
    lda P1_SCORE
    clc
    adc P2_SCORE
    cmp TOTAL_BOXES
    bcs _RR_Done

    ; 1. Try immediate cascade captures
    jsr ScanClose
    bcc _RR_NoClose
    jsr DoPlacer
    jmp _RR_Loop

_RR_NoClose:
    ; 2. Try safe moves
    jsr ScanSafe
    bcc _RR_NoSafe
    jsr DoPlacer
    jmp _RR_Loop

_RR_NoSafe:
    ; 3. Must sacrifice shortest chain
    jsr FindShortestChainSacrifice
    bcc _RR_Done
    jsr DoPlacer
    jmp _RR_Loop

_RR_Done:
    lda P2_SCORE
    rts

; ===================================================================
; EXPERT CAPTURE CHAIN (Rollout-Guided Handout & Double-Cross)
; ===================================================================

ExpertCaptureChain:
    ; 1. If safe moves exist on board, NEVER double-cross! Take greedily!
    jsr HasAnySafeMove
    bcc +
    jsr EraseSpinner
    jsr ScanClose
    jsr DoPlacer
    rts
+
    ; 2. Calculate remaining boxes on board
    lda TOTAL_BOXES
    sec
    sbc P1_SCORE
    sbc P2_SCORE
    sta REMAINING_BOXES

    ; If remaining boxes <= 4, take all greedy to finish game:
    cmp #5
    bcs +
    jsr EraseSpinner
    jsr ScanClose
    jsr DoPlacer
    rts
+
    ; 3. Save real game state into REAL_*
    jsr SaveRealState
    lda P1_SCORE
    clc
    adc P2_SCORE
    sta REAL_BASE_SCORE

    ; Candidate 0: GREEDY CAPTURE
    jsr ScanClose
    lda MODE
    sta BEST_M
    lda CURSOR_X
    sta BEST_X
    lda CURSOR_Y
    sta BEST_Y

    ; Simulate playing greedy in RAM:
    lda #1
    sta SIM_MODE
    jsr DoPlacer
    jsr RunRollout
    sta BEST_SCORE ; P2_SCORE achieved with greedy rollout

    ; 4. Search for candidate HANDOUT moves among all free edges
    lda #0
    sta HO_CAND_M
_HO_MLoop:
    lda #0
    sta HO_CAND_Y
_HO_YLoop:
    lda #0
    sta HO_CAND_X
_HO_XLoop:
    jsr StepSpinner

    ; Restore real state to test candidate
    jsr LoadRealState
    lda #1
    sta SIM_MODE

    ; Check if (HO_CAND_M, HO_CAND_X, HO_CAND_Y) is available
    lda HO_CAND_M
    sta MODE
    lda HO_CAND_X
    sta TEMP_CX
    sta CURSOR_X
    lda HO_CAND_Y
    sta TEMP_CY
    sta CURSOR_Y
    jsr CheckAvailTemp
    beq +
    jmp _HO_NextCand
+
    ; Candidate is free! Play it in simulation:
    jsr DoPlacer

    ; 1. Did it close any box?
    lda P1_SCORE
    clc
    adc P2_SCORE
    cmp REAL_BASE_SCORE
    beq +
    jmp _HO_NextCand
+
    ; 2. Simulate opponent taking all cascading 3-sided boxes:
_HO_OppCascade:
    jsr ScanClose
    bcc _HO_OppDone
    jsr DoPlacer
    jmp _HO_OppCascade
_HO_OppDone:

    ; How many boxes did opponent get?
    lda P1_SCORE
    clc
    adc P2_SCORE
    sec
    sbc REAL_BASE_SCORE
    ; Opponent boxes must be 2 or 4:
    cmp #2
    beq _HO_BoxCountOk
    cmp #4
    beq _HO_BoxCountOk
    jmp _HO_NextCand

_HO_BoxCountOk:
    ; Opponent boxes must be strictly < REMAINING_BOXES:
    cmp REMAINING_BOXES
    bcc +
    jmp _HO_NextCand
+
    ; Valid handout candidate!
    ; Run rollout from here:
    jsr RunRollout
    ; A = P2_SCORE from this rollout
    cmp BEST_SCORE
    bcc _HO_NextCand
    beq _HO_NextCand
    ; Strictly higher score achieved by handout!
    sta BEST_SCORE
    lda HO_CAND_M
    sta BEST_M
    lda HO_CAND_X
    sta BEST_X
    lda HO_CAND_Y
    sta BEST_Y

_HO_NextCand:
    inc HO_CAND_X
    lda HO_CAND_M
    beq _HO_StepH
    lda HO_CAND_X
    cmp GRID_SIZE_P1
    bcs +
    jmp _HO_XLoop
+   inc HO_CAND_Y
    lda HO_CAND_Y
    cmp GRID_SIZE
    bcs +
    jmp _HO_YLoop
+   jmp _HO_StepM

_HO_StepH:
    lda HO_CAND_X
    cmp GRID_SIZE
    bcs +
    jmp _HO_XLoop
+   inc HO_CAND_Y
    lda HO_CAND_Y
    cmp GRID_SIZE_P1
    bcs +
    jmp _HO_YLoop
+
_HO_StepM:
    inc HO_CAND_M
    lda HO_CAND_M
    cmp #2
    bcs +
    jmp _HO_MLoop
+
    ; Evaluation complete! Restore real state
    jsr LoadRealState
    lda #0
    sta SIM_MODE

    ; Play best move in real game:
    jsr EraseSpinner
    lda BEST_M
    sta MODE
    lda BEST_X
    sta CURSOR_X
    lda BEST_Y
    sta CURSOR_Y
    jsr DoPlacer
    rts

; ===================================================================
; SHORTEST CHAIN SACRIFICE
; ===================================================================

FindShortestChainSacrifice:
    lda SIM_MODE
    sta PREV_SIM_MODE

    lda #255
    sta FSCS_BEST_SCORE
    lda #0
    sta FSCS_BEST_M
    sta FSCS_BEST_X
    sta FSCS_BEST_Y
    
    lda #0
    sta MODE
_FSCS_MLoop:
    lda #0
    sta CURSOR_Y
_FSCS_YLoop:
    lda #0
    sta CURSOR_X
_FSCS_XLoop:
    lda PREV_SIM_MODE
    bne +
    jsr StepSpinner
+
    lda CURSOR_X
    sta TEMP_CX
    lda CURSOR_Y
    sta TEMP_CY
    jsr CheckAvailTemp
    beq +
    jmp _FSCS_Next
+   
    ; Simulate edge
    jsr SaveState
    lda #1
    sta SIM_MODE
    jsr DoPlacer
    
    lda P1_SCORE
    clc
    adc P2_SCORE
    sta SIM_BASE_SCORE
_FSCS_Cascade:
    jsr ScanClose
    bcc _FSCS_DoneSim
    jsr DoPlacer
    jmp _FSCS_Cascade

_FSCS_DoneSim:
    lda P1_SCORE
    clc
    adc P2_SCORE
    sec
    sbc SIM_BASE_SCORE
    sta TEMP_DIGIT
    jsr LoadState
    lda PREV_SIM_MODE
    sta SIM_MODE
    
    ; Score = (TEMP_DIGIT * 4) - (1 if perimeter)
    lda TEMP_DIGIT
    asl
    asl
    sta TEMP_DIGIT

    lda MODE
    bne _FSCS_V_Perim
    lda CURSOR_Y
    beq _FSCS_IsPerim
    cmp GRID_SIZE
    beq _FSCS_IsPerim
    jmp _FSCS_Comp
_FSCS_V_Perim:
    lda CURSOR_X
    beq _FSCS_IsPerim
    cmp GRID_SIZE
    beq _FSCS_IsPerim
    jmp _FSCS_Comp
_FSCS_IsPerim:
    dec TEMP_DIGIT

_FSCS_Comp:
    lda TEMP_DIGIT
    cmp FSCS_BEST_SCORE
    bcs _FSCS_Next
    
    ; Strictly shorter sacrifice found!
    sta FSCS_BEST_SCORE
    lda MODE
    sta FSCS_BEST_M
    lda CURSOR_X
    sta FSCS_BEST_X
    lda CURSOR_Y
    sta FSCS_BEST_Y

_FSCS_Next:
    inc CURSOR_X
    lda MODE
    beq _FSCS_StepH
    lda CURSOR_X
    cmp GRID_SIZE_P1
    bcs +
    jmp _FSCS_XLoop
+   inc CURSOR_Y
    lda CURSOR_Y
    cmp GRID_SIZE
    bcs +
    jmp _FSCS_YLoop
+   jmp _FSCS_StepM
_FSCS_StepH:
    lda CURSOR_X
    cmp GRID_SIZE
    bcs +
    jmp _FSCS_XLoop
+   inc CURSOR_Y
    lda CURSOR_Y
    cmp GRID_SIZE_P1
    bcs +
    jmp _FSCS_YLoop
+
_FSCS_StepM:
    inc MODE
    lda MODE
    cmp #2
    bcs +
    jmp _FSCS_MLoop
+
    lda FSCS_BEST_SCORE
    cmp #255
    beq _FSCS_Fail
    lda FSCS_BEST_M
    sta MODE
    lda FSCS_BEST_X
    sta CURSOR_X
    lda FSCS_BEST_Y
    sta CURSOR_Y
    sec
    rts
_FSCS_Fail:
    clc
    rts

CountAllSafeMoves:
    lda #0
    sta SAFE_COUNT
    sta MODE
_CASM_MLoop:
    lda #0
    sta CURSOR_Y
_CASM_YLoop:
    lda #0
    sta CURSOR_X
_CASM_XLoop:
    lda CURSOR_X
    sta TEMP_CX
    lda CURSOR_Y
    sta TEMP_CY
    jsr CheckAvailTemp
    bne _CASM_Next
    jsr IsSafe
    beq _CASM_Next
    inc SAFE_COUNT
_CASM_Next:
    inc CURSOR_X
    lda MODE
    beq _CASM_StepH
    lda CURSOR_X
    cmp GRID_SIZE_P1
    bcs +
    jmp _CASM_XLoop
+   inc CURSOR_Y
    lda CURSOR_Y
    cmp GRID_SIZE
    bcs +
    jmp _CASM_YLoop
+   jmp _CASM_StepM
_CASM_StepH:
    lda CURSOR_X
    cmp GRID_SIZE
    bcs +
    jmp _CASM_XLoop
+   inc CURSOR_Y
    lda CURSOR_Y
    cmp GRID_SIZE_P1
    bcs +
    jmp _CASM_YLoop
+
_CASM_StepM:
    inc MODE
    lda MODE
    cmp #2
    bcs +
    jmp _CASM_MLoop
+   lda SAFE_COUNT
    rts

ExpertBestSafeMove:
    lda #0
    sta BEST_SCORE
    sta MODE
_EBSM_MLoop:
    lda #0
    sta CURSOR_Y
_EBSM_YLoop:
    lda #0
    sta CURSOR_X
_EBSM_XLoop:
    jsr StepSpinner
    lda CURSOR_X
    sta TEMP_CX
    lda CURSOR_Y
    sta TEMP_CY
    jsr CheckAvailTemp
    beq +
    jmp _EBSM_Next
+   jsr IsSafe
    bne +
    jmp _EBSM_Next
+
    ; Candidate is safe! Start with base score 100
    lda #100
    sta TEMP_DIGIT
    
    lda MODE
    bne _EBSM_Vert
    
    ; -------------------------------------------------------------
    ; Horizontal (CURSOR_X, CURSOR_Y)
    ; 1. Perimeter bonus: if Y == 0 or Y == GRID_SIZE, +25
    lda CURSOR_Y
    beq _EBSM_H_Perim
    cmp GRID_SIZE
    bne _EBSM_H_Boxes
_EBSM_H_Perim:
    lda TEMP_DIGIT
    clc
    adc #25
    sta TEMP_DIGIT

_EBSM_H_Boxes:
    ; Check Box Up: (CURSOR_X, CURSOR_Y - 1)
    lda CURSOR_Y
    beq _EBSM_H_Dn
    lda CURSOR_X
    sta TEMP_CX
    lda CURSOR_Y
    sec
    sbc #1
    sta TEMP_CY
    jsr CountSides
    cmp #0
    bne +
    ; 0 sides -> Fresh bonus +15
    lda TEMP_DIGIT
    clc
    adc #15
    sta TEMP_DIGIT
    jmp _EBSM_H_Dn
+   cmp #1
    bne _EBSM_H_Dn
    ; 1 side -> Creating 2-sided box! Penalty -25
    lda TEMP_DIGIT
    sec
    sbc #25
    sta TEMP_DIGIT

_EBSM_H_Dn:
    ; Check Box Down: (CURSOR_X, CURSOR_Y)
    lda CURSOR_Y
    cmp GRID_SIZE
    bcc +
    jmp _EBSM_SimLookahead
+   lda CURSOR_X
    sta TEMP_CX
    lda CURSOR_Y
    sta TEMP_CY
    jsr CountSides
    cmp #0
    bne +
    ; 0 sides -> Fresh bonus +15
    lda TEMP_DIGIT
    clc
    adc #15
    sta TEMP_DIGIT
    jmp _EBSM_SimLookahead
+   cmp #1
    bne +
    ; 1 side -> Creating 2-sided box! Penalty -25
    lda TEMP_DIGIT
    sec
    sbc #25
    sta TEMP_DIGIT
+   jmp _EBSM_SimLookahead

_EBSM_Vert:
    ; -------------------------------------------------------------
    ; Vertical (CURSOR_X, CURSOR_Y)
    ; 1. Perimeter bonus: if X == 0 or X == GRID_SIZE, +25
    lda CURSOR_X
    beq _EBSM_V_Perim
    cmp GRID_SIZE
    bne _EBSM_V_Boxes
_EBSM_V_Perim:
    lda TEMP_DIGIT
    clc
    adc #25
    sta TEMP_DIGIT

_EBSM_V_Boxes:
    ; Check Box Left: (CURSOR_X - 1, CURSOR_Y)
    lda CURSOR_X
    beq _EBSM_V_Rt
    lda CURSOR_X
    sec
    sbc #1
    sta TEMP_CX
    lda CURSOR_Y
    sta TEMP_CY
    jsr CountSides
    cmp #0
    bne +
    ; 0 sides -> Fresh bonus +15
    lda TEMP_DIGIT
    clc
    adc #15
    sta TEMP_DIGIT
    jmp _EBSM_V_Rt
+   cmp #1
    bne _EBSM_V_Rt
    ; 1 side -> Penalty -25
    lda TEMP_DIGIT
    sec
    sbc #25
    sta TEMP_DIGIT

_EBSM_V_Rt:
    ; Check Box Right: (CURSOR_X, CURSOR_Y)
    lda CURSOR_X
    cmp GRID_SIZE
    bcs _EBSM_SimLookahead
    lda CURSOR_X
    sta TEMP_CX
    lda CURSOR_Y
    sta TEMP_CY
    jsr CountSides
    cmp #0
    bne +
    ; 0 sides -> Fresh bonus +15
    lda TEMP_DIGIT
    clc
    adc #15
    sta TEMP_DIGIT
    jmp _EBSM_SimLookahead
+   cmp #1
    bne _EBSM_SimLookahead
    ; 1 side -> Penalty -25
    lda TEMP_DIGIT
    sec
    sbc #25
    sta TEMP_DIGIT

_EBSM_SimLookahead:
    ; -------------------------------------------------------------
    ; 3. Zugzwang & Parity Lookahead in RAM simulation
    lda MODE
    sta CAND_HOLD_M
    lda CURSOR_X
    sta CAND_HOLD_X
    lda CURSOR_Y
    sta CAND_HOLD_Y

    jsr SaveState
    lda #1
    sta SIM_MODE
    jsr DoPlacer
    jsr CountAllSafeMoves
    sta SAFE_COUNT
    jsr LoadState
    lda #0
    sta SIM_MODE

    ; Restore candidate move coordinates to CURSOR_X, CURSOR_Y, MODE
    lda CAND_HOLD_M
    sta MODE
    lda CAND_HOLD_X
    sta CURSOR_X
    lda CAND_HOLD_Y
    sta CURSOR_Y

    ; Check SAFE_COUNT:
    lda SAFE_COUNT
    bne _EBSM_CheckEven
    ; SAFE_COUNT == 0: OPPONENT HAS ZERO SAFE MOVES! +80 BONUS!
    lda TEMP_DIGIT
    clc
    adc #80
    sta TEMP_DIGIT
    jmp _EBSM_ScoreDone

_EBSM_CheckEven:
    and #1
    bne _EBSM_OddParity
    ; SAFE_COUNT is EVEN: AI has the parity advantage! +30 BONUS!
    lda TEMP_DIGIT
    clc
    adc #30
    sta TEMP_DIGIT
    jmp _EBSM_ScoreDone

_EBSM_OddParity:
    ; SAFE_COUNT is ODD: Opponent has the parity advantage! -20 PENALTY!
    lda TEMP_DIGIT
    sec
    sbc #20
    sta TEMP_DIGIT

_EBSM_ScoreDone:
    ; Add tiny tie-breaker from LFSR (0 or 1)
    jsr LFSR
    and #1
    clc
    adc TEMP_DIGIT
    sta TEMP_DIGIT
    
    cmp BEST_SCORE
    bcc _EBSM_Next
    sta BEST_SCORE
    lda MODE
    sta BEST_M
    lda CURSOR_X
    sta BEST_X
    lda CURSOR_Y
    sta BEST_Y

_EBSM_Next:
    inc CURSOR_X
    lda MODE
    beq _EBSM_StepH
    lda CURSOR_X
    cmp GRID_SIZE_P1
    bcs +
    jmp _EBSM_XLoop
+   inc CURSOR_Y
    lda CURSOR_Y
    cmp GRID_SIZE
    bcs +
    jmp _EBSM_YLoop
+   jmp _EBSM_StepM
_EBSM_StepH:
    lda CURSOR_X
    cmp GRID_SIZE
    bcs +
    jmp _EBSM_XLoop
+   inc CURSOR_Y
    lda CURSOR_Y
    cmp GRID_SIZE_P1
    bcs +
    jmp _EBSM_YLoop
+
_EBSM_StepM:
    inc MODE
    lda MODE
    cmp #2
    bcs +
    jmp _EBSM_MLoop
+
    lda BEST_SCORE
    beq _EBSM_Fail
    lda BEST_M
    sta MODE
    lda BEST_X
    sta CURSOR_X
    lda BEST_Y
    sta CURSOR_Y
    sec
    rts
_EBSM_Fail:
    clc
    rts

SpinnerFrames:
    .byte 38, 41, 40, 39 ; '|', '\', '-', '/'

StepSpinner:
    lda TURN
    beq + ; Only spin when it's COMP's turn!
    pha
    txa
    pha
    tya
    pha

    jsr EraseSpinner

    inc SPINNER_STATE
    lda SPINNER_STATE
    and #3
    sta SPINNER_STATE
    tax
    lda SpinnerFrames,x
    pha

    lda #3 ; White
    sta COLOR
    lda #0
    sta IS_BOLD
    lda #232 ; Centered directly under COMP score (P2_SCORE at X=228..242)
    sta X1LO
    lda #100 ; 12 scanlines below COMP score, completely clear of COMP label
    sta Y1
    pla
    jsr DrawCharOnce

    pla
    tay
    pla
    tax
    pla
+   rts

EraseSpinner:
    pha
    txa
    pha
    tya
    pha

    lda #100
    sta TEMP_HI
_ES_Loop:
    lda TEMP_HI
    jsr HGR_ADDR
    lda #0
    ldy #32
    sta (PTR),y
    iny
    sta (PTR),y
    iny
    sta (PTR),y
    iny
    sta (PTR),y
    inc TEMP_HI
    lda TEMP_HI
    cmp #108
    bcc _ES_Loop

    pla
    tay
    pla
    tax
    pla
    rts

CheckKbdOnly:
    lda KBD
    bpl +
    cmp #$D2 ; 'R'
    beq CK_Reset
    cmp #$F2 ; 'r'
    beq CK_Reset
    cmp #$B1 ; '1'
    beq CK_L1
    cmp #$B2 ; '2'
    beq CK_L2
    cmp #$B3 ; '3'
    beq CK_L3
    ; Other keys? (Optional: handle arrows to change speed?)
    sta KBDSTRB
+   rts

CK_Reset:
    sta KBDSTRB
    jmp Start
CK_L1:
    lda AI_LEVEL
    cmp #1
    beq +
    lda #1
    sta AI_LEVEL
    sta ABORT_AI
    jsr DrawLabels
+   sta KBDSTRB
    rts
CK_L2:
    lda AI_LEVEL
    cmp #2
    beq +
    lda #2
    sta AI_LEVEL
    sta ABORT_AI
    jsr DrawLabels
+   sta KBDSTRB
    rts
CK_L3:
    lda AI_LEVEL
    cmp #3
    beq +
    lda #3
    sta AI_LEVEL
    sta ABORT_AI
    jsr DrawLabels
+   sta KBDSTRB
    rts

Draw3Digits:
    ; A = Valeur en entrée (0-100)
    sta TEMP_DIGIT
    
    ; Centaines
    lda TEMP_DIGIT
    jsr Div100
    beq _D3_Skip100
    clc
    adc #$30 ; '1'
    jsr DrawChar
    jmp _D3_Next100
_D3_Skip100:
    lda #$20 ; Espace
    jsr DrawChar
_D3_Next100:
    lda X1LO
    clc
    adc #8
    sta X1LO

    ; Dizaines
    lda TEMP_DIGIT
    jsr Mod100
    jsr Div10
    beq _D3_Skip10
    clc
    adc #$30 ; Digit base
    jsr DrawChar
    jmp _D3_Next10
_D3_Skip10:
    ; On met un espace si les centaines sont aussi 0
    lda TEMP_DIGIT
    jsr Div100
    bne _D3_Zero10 ; Si 100+, on écrit le 0 de 10x
    lda #$20 ; Espace
    jsr DrawChar
    jmp _D3_Next10
_D3_Zero10:
    lda #$30 ; '0'
    jsr DrawChar
_D3_Next10:
    lda X1LO
    clc
    adc #8
    sta X1LO

    ; Unités
    lda TEMP_DIGIT
    jsr Mod10
    clc
    adc #$30
    jsr DrawChar
    
    ; Symbole %
    lda X1LO
    clc
    adc #8
    sta X1LO
    lda #$25 ; '%' ASCII
    jsr DrawChar
    rts

Mod10:
    sta TEMP_W
_M10L:
    lda TEMP_W
    cmp #10
    bcc _M10D
    sec
    sbc #10
    sta TEMP_W
    jmp _M10L
_M10D:
    lda TEMP_W
    rts

Mod100:
_M100L:
    cmp #100
    bcc _M100D
    sec
    sbc #100
    jmp _M100L
_M100D:
    rts

Div100:
    ldx #0
_D100L:
    cmp #100
    bcc _D100D
    sec
    sbc #100
    inx
    jmp _D100L
_D100D:
    txa
    rts

SaveRealState:
    ldx #0
_SRS_Loop:
    lda LH,x
    sta REAL_LH,x
    lda LV,x
    sta REAL_LV,x
    cpx TOTAL_BOXES
    bcs +
    lda BX,x
    sta REAL_BX,x
+   inx
    cpx TOTAL_LH
    bcc _SRS_Loop
    lda P1_SCORE
    sta REAL_P1
    lda P2_SCORE
    sta REAL_P2
    lda TURN
    sta REAL_TURN
    lda NUM_BOXES_CLOSED
    sta REAL_NUM_BOXES
    lda GAME_OVER
    sta REAL_GAME_OVER
    rts

LoadRealState:
    ldx #0
_LRS_Loop:
    lda REAL_LH,x
    sta LH,x
    lda REAL_LV,x
    sta LV,x
    cpx TOTAL_BOXES
    bcs +
    lda REAL_BX,x
    sta BX,x
+   inx
    cpx TOTAL_LH
    bcc _LRS_Loop
    lda REAL_P1
    sta P1_SCORE
    lda REAL_P2
    sta P2_SCORE
    lda REAL_TURN
    sta TURN
    lda REAL_NUM_BOXES
    sta NUM_BOXES_CLOSED
    lda REAL_GAME_OVER
    sta GAME_OVER
    rts

SaveState:
    ldx #0
SSLoop:
    lda LH,x
    sta SIM_LH,x
    lda LV,x
    sta SIM_LV,x
    cpx TOTAL_BOXES
    bcs SSLSkip
    lda BX,x
    sta SIM_BX,x
SSLSkip:
    inx
    cpx TOTAL_LH
    bcc SSLoop
    lda P1_SCORE
    sta SIM_P1
    lda P2_SCORE
    sta SIM_P2
    lda TURN
    sta SIM_TURN
    lda NUM_BOXES_CLOSED
    sta SIM_NUM_BOXES
    lda GAME_OVER
    sta SIM_GAME_OVER
    lda CURSOR_X
    sta MC_X
    lda CURSOR_Y
    sta MC_Y
    lda MODE
    sta MC_M
    rts
    
LoadState:
    ldx #0
LSLoop:
    lda SIM_LH,x
    sta LH,x
    lda SIM_LV,x
    sta LV,x
    cpx TOTAL_BOXES
    bcs LSLSkip
    lda SIM_BX,x
    sta BX,x
LSLSkip:
    inx
    cpx TOTAL_LH
    bcc LSLoop
    lda SIM_P1
    sta P1_SCORE
    lda SIM_P2
    sta P2_SCORE
    lda SIM_TURN
    sta TURN
    lda SIM_NUM_BOXES
    sta NUM_BOXES_CLOSED
    lda SIM_GAME_OVER
    sta GAME_OVER
    lda MC_X
    sta CURSOR_X
    lda MC_Y
    sta CURSOR_Y
    lda MC_M
    sta MODE
    rts

IsSafe:
    lda #1 
    sta TEMP_HI
    lda MODE
    beq ISH_Start
    
    ; Case: Vertical Line (X,Y)
    ; Boxes potentially created: (X-1, Y) and (X, Y)
    lda CURSOR_X
    beq ISV_SkipL
    ; Check Box Left: (X-1, Y)
    sec
    lda CURSOR_X
    sbc #1
    sta TEMP_CX
    lda CURSOR_Y
    sta TEMP_CY
    jsr CountSides
    cmp #2
    bne ISV_SkipL
    lda #0 ; Not safe
    sta TEMP_HI
    rts

ISV_SkipL:
    lda CURSOR_X
    cmp GRID_SIZE
    bcs IS_Done
    ; Check Box Right: (X, Y)
    lda CURSOR_X
    sta TEMP_CX
    lda CURSOR_Y
    sta TEMP_CY
    jsr CountSides
    cmp #2
    bne IS_Done
    lda #0 ; Not safe
    sta TEMP_HI
    rts

ISH_Start:
    ; Case: Horizontal Line (X,Y)
    ; Boxes potentially created: (X, Y-1) and (X, Y)
    lda CURSOR_Y
    beq ISH_SkipU
    ; Check Box Up: (X, Y-1)
    lda CURSOR_X
    sta TEMP_CX
    sec
    lda CURSOR_Y
    sbc #1
    sta TEMP_CY
    jsr CountSides
    cmp #2
    bne ISH_SkipU
    lda #0 ; Not safe
    sta TEMP_HI
    rts

ISH_SkipU:
    lda CURSOR_Y
    cmp GRID_SIZE
    bcs IS_Done
    ; Check Box Down: (X, Y)
    lda CURSOR_X
    sta TEMP_CX
    lda CURSOR_Y
    sta TEMP_CY
    jsr CountSides
    cmp #2
    bne IS_Done
    lda #0 ; Not safe
    sta TEMP_HI

IS_Done:
    lda TEMP_HI
    rts


CheckBoxSafe:
    lda TEMP_W
    sta TEMP_CX
    lda TEMP_MUL
    sta TEMP_CY
    jsr CountSides
    cmp #2
    bcc CBS_Ok
    lda #0
    sta TEMP_HI
CBS_Ok:
    rts

CountSides:
    lda #0
    sta DIGIT0 ; Use as Counter
    
    lda TEMP_CX
    sta DRAW_X
    lda TEMP_CY
    sta DRAW_Y
    jsr GetIndLH ; Top
    tax
    lda LH,x
    beq +
    inc DIGIT0
+   lda TEMP_CY
    clc
    adc #1
    sta DRAW_Y
    jsr GetIndLH ; Bottom
    tax
    lda LH,x
    beq +
    inc DIGIT0
+   lda TEMP_CX
    sta DRAW_X
    lda TEMP_CY
    sta DRAW_Y
    jsr GetIndLV ; Left
    tax
    lda LV,x
    beq +
    inc DIGIT0
+   lda TEMP_CX
    clc
    adc #1
    sta DRAW_X
    lda TEMP_CY
    sta DRAW_Y
    jsr GetIndLV ; Right
    tax
    lda LV,x
    beq +
    inc DIGIT0
+   lda DIGIT0
    rts

FrameEntropy:
    inc RANDOM_VAL
    rts

LFSR:
    lda RANDOM_VAL
    beq LFSR_Zero
    lsr
    bcc LFSR_Done
    eor #$B4
LFSR_Done:
    sta RANDOM_VAL
    rts
LFSR_Zero:
    lda #$AB
    sta RANDOM_VAL
    rts
    
    rts

ThinkDelay:
    ldy #6
_TD_Loop:
    jsr StepSpinner
    ldx #50
_TD_Inner1:
    lda #180
_TD_Inner2:
    sec
    sbc #1
    bne _TD_Inner2
    dex
    bne _TD_Inner1
    dey
    bne _TD_Loop
    rts

ClickSound:
    ldx #30
CS_Out:
    lda SPEAKER
    ldy #40
CS_In:
    dey
    bne CS_In
    dex
    bne CS_Out
    rts
    
BoxSound:
    ldx #100
BS_Out:
    lda SPEAKER
    ldy #20
BS_In:
    dey
    bne BS_In
    dex
    bne BS_Out
    rts

; ===================================================================
; GRAPHICS ENGINE
; ===================================================================
ClearScreen:
    lda #0
    ldx #$20
    ldy #0
    sty PTR
    stx PTR+1
CS_Loop:
    sta (PTR),y
    iny
    bne CS_Loop
    inc PTR+1
    ldx PTR+1
    cpx #$60 ; Clear Page 1 ($20) AND Page 2 ($40) up to $5FFF
    bcc CS_Loop
    rts

HGR_ADDR:
    tay
    lda HGR_LO,y
    sta PTR
    lda HGR_HI,y
    clc
    adc HIRES_PAGE_OFF ; 0 for Page 1, $20 for Page 2
    sta PTR+1
    rts

PlotPixel:
    lda DRAW_Y
    jsr HGR_ADDR
    
    lda COLOR
    beq ErsP
    
    ; Initial X
    lda DRAW_X
    sta LOCAL_X
    
    ; Determine Phase/Bit 7 (Standard Apple II)
    lda COLOR
    cmp #4
    bcs PP_HPhase
    lda #0 ; Phase 0 (Green/Purple/White1)
    sta TEMP_BT7
    jmp PP_Parity
PP_HPhase:
    lda #$80 ; Phase 1 (Blue/Orange/White2)
    sta TEMP_BT7

PP_Parity:
    lda PARITY_EN
    beq PP_DrawSolid ; If 0, draw every pixel (Fonts/UI)
    
    lda COLOR
    cmp #1 ; Green (P1)
    beq PP_GreenSkip
    cmp #6 ; Blue (AI)
    beq PP_BlueShift
    jmp PP_DrawSolid

PP_GreenSkip:
    lda LOCAL_X
    and #1
    beq PlotDone ; Skip EVEN columns for Green (restores Green on user's screen)
    jmp PP_DrawSolid

PP_BlueShift:
    lda LOCAL_X
    and #1
    beq PP_DrawSolid ; already EVEN, good (restores Blue on user's screen)
    inc LOCAL_X ; Shift ODD to EVEN for Blue parity

PP_DrawSolid:
    ldx LOCAL_X
    ldy X_COL_TAB,x
    lda (PTR),y
    pha
    lda X_BIT_TAB,x
    tax
    pla
    ora BIT_MASKS,x
    ora TEMP_BT7
    sta (PTR),y
PlotDone:
    rts

ErsP:
    ldx DRAW_X
    ldy X_COL_TAB,x
    lda (PTR),y
    pha
    lda X_BIT_TAB,x
    tax
    pla
    and INV_BIT_MASKS,x
    sta (PTR),y
    rts

DrawVLineFromX1:
    lda X1LO
    sta DRAW_X
    lda Y1
    sta DRAW_Y
DrawVLine:
    lda #1
    sta PARITY_EN
    inc TEMP_LEN
DVL_Loop:
    jsr PlotPixel
    inc DRAW_Y
    dec TEMP_LEN
    bne DVL_Loop
    lda #0
    sta PARITY_EN
    rts
    
DrawHLineFromX1:
    lda X1LO
    sta DRAW_X
    lda Y1
    sta DRAW_Y
DrawHLine:
    lda #1
    sta PARITY_EN
    inc TEMP_LEN
DHL_Loop:
    jsr PlotPixel
    inc DRAW_X
    dec TEMP_LEN
    bne DHL_Loop
    lda #0
    sta PARITY_EN
    rts


DrawThickHLine:
    lda TEMP_LEN
    pha
    jsr DrawHLineFromX1
    pla
    sta TEMP_LEN
    inc Y1
    jsr DrawHLineFromX1
    dec Y1
    rts

DrawThickVLine:
    lda TEMP_LEN
    pha
    jsr DrawVLineFromX1
    pla
    sta TEMP_LEN
    inc X1LO
    jsr DrawVLineFromX1
    dec X1LO
    rts




DrawAllDots:
    lda #3
    sta COLOR
    lda #0
    sta TEMP_HI
LoopDY:
    lda #0
    sta TEMP_W
LoopDX:
    lda TEMP_W
    jsr GetDotX
    sta X1LO
    
    lda TEMP_HI
    jsr GetDotY
    sta Y1
    
    lda X1LO
    sec
    sbc #1
    sta DRAW_X
    lda Y1
    sta DRAW_Y
    lda #3
    sta TEMP_LEN
    jsr DrawHLine
    
    lda X1LO
    sta DRAW_X
    lda Y1
    sec
    sbc #1
    sta DRAW_Y
    lda #3
    sta TEMP_LEN
    jsr DrawVLine
        
    inc TEMP_W
    lda TEMP_W
    cmp GRID_SIZE_P1
    bne LoopDX
    
    inc TEMP_HI
    lda TEMP_HI
    cmp GRID_SIZE_P1
    bne LoopDY
    rts

GetDotX:
    clc
    adc GRID_OFFSET_TABLE
    tax
    lda DotXTab,x
    rts

GetDotY:
    clc
    adc GRID_OFFSET_TABLE
    tax
    lda DotYTab,x
    rts

GetIndLH:
GetIndBX:
    ldy DRAW_Y
    lda GRID_OFFSET_TABLE
    sty TEMP_C
    clc
    adc TEMP_C
    tay
    lda RowOffset_G,y
    clc
    adc DRAW_X
    rts

GetIndLV:
    ldy DRAW_Y
    lda GRID_OFFSET_TABLE
    sty TEMP_C
    clc
    adc TEMP_C
    tay
    lda RowOffset_GP1,y
    clc
    adc DRAW_X
    rts

RedrawScores:
    lda #0
    sta COLOR
    lda #18
    sta X1LO
    lda #80
    sta Y1
    jsr EraseScoreBox
    
    lda #228
    sta X1LO
    lda #80
    sta Y1
    jsr EraseScoreBox
    
    lda #1
    sta IS_BOLD
    
    lda #18
    sta X1LO
    lda #1
    sta COLOR
    lda P1_SCORE
    jsr DrawScoreVal
    
    lda #228
    sta X1LO
    lda #6
    sta COLOR
    lda P2_SCORE
    jsr DrawScoreVal
    
    lda #0
    sta IS_BOLD
    rts

EraseScoreBox:
    lda Y1
    sta TEMP_HI
ESB_Loop:
    lda X1LO
    sta DRAW_X
    lda TEMP_HI
    sta DRAW_Y
    lda #16
    sta TEMP_LEN
    jsr DrawHLine
    inc TEMP_HI
    lda TEMP_HI
    sec
    sbc Y1
    cmp #8
    bne ESB_Loop
    rts
    
Div10:
    ldx #0
Div10_Loop:
    cmp #10
    bcc Div10_Done
    sec
    sbc #10
    inx
    jmp Div10_Loop
Div10_Done:
    pha
    txa
    tay
    pla
    tax
    tya
    rts

DrawScoreVal:
    jsr Div10
    sta DIGIT1
    stx DIGIT0

    lda DIGIT1
    clc
    adc #$30 ; Convert to ASCII '0'..'9'
    jsr DrawChar
    
    lda X1LO
    clc
    adc #8
    sta X1LO
    
    lda DIGIT0
    clc
    adc #$30 ; Convert to ASCII '0'..'9'
    jsr DrawChar
    rts


DrawChar:
    jsr MapCharToIndex
    pha ; Save index
    jsr DrawCharOnce
    pla ; Restore index
    ldx IS_BOLD
    beq +
    pha ; Save again for second pass
    inc X1LO
    jsr DrawCharOnce
    dec X1LO
    pla ; Restore index
+   rts

DrawCharOnce:
    sta FONT_PTR
    lda #0
    sta FONT_PTR+1
    
    asl FONT_PTR
    rol FONT_PTR+1
    asl FONT_PTR
    rol FONT_PTR+1
    asl FONT_PTR
    rol FONT_PTR+1
    
    lda FONT_PTR
    clc
    adc #<CharBitmap
    sta FONT_PTR
    lda FONT_PTR+1
    adc #>CharBitmap
    sta FONT_PTR+1
    
    lda Y1
    sta TEMP_C
    ldy #0
ChrYOnce:
    lda (FONT_PTR),y
    sta TEMP_CHAR
    iny
    sty TEMP_W
    
    lda X1LO
    sta DRAW_X
    lda TEMP_C
    sta DRAW_Y
    lda #8
    sta TEMP_MUL
ChrXOnce:
    asl TEMP_CHAR
    bcc SkipPOnce
    
    lda DRAW_X
    pha
    jsr PlotPixel
    pla
    sta DRAW_X
SkipPOnce:
    inc DRAW_X
    dec TEMP_MUL
    bne ChrXOnce
    
    ldy TEMP_W
    inc TEMP_C
    cpy #8
    bcc ChrYOnce
    rts

DrawStaticBanner:
    lda #0
    sta HIRES_PAGE_OFF
    sta PARITY_EN
    
    ; Clean Y=182..191 (Page 1)
    lda #182
    sta DRAW_Y
DSB_Clear:
    lda DRAW_Y
    jsr HGR_ADDR
    ldy #0
    lda #0
-   sta (PTR),y
    iny
    cpy #40
    bcc -
    inc DRAW_Y
    lda DRAW_Y
    cmp #191
    bcc DSB_Clear
    
    ; Draw current banner phase
    lda #0
    sta IS_BOLD
    lda #3
    sta COLOR
    lda #182
    sta Y1
    lda #5
    sta X1LO
    
    lda BANNER_PHASE
    beq DSB_B1
    lda #<MsgStaticB2
    ldy #>MsgStaticB2
    jmp DSB_Draw
DSB_B1:
    lda #<MsgStaticB1
    ldy #>MsgStaticB1
DSB_Draw:
    jsr DrawString
    rts

MsgStaticB1: .text "   ARROWS:MOVE   SPACE:PIVOT",0
MsgStaticB2: .text "  ENTER:OK  1-3:LEVEL  R:RESET",0
.byte 0

MapCharToIndex:
    and #$7F ; Strip Apple II bit 7
    cmp #$21 ; '!'
    beq MCI_Exclam
    cmp #$25 ; '%'
    beq MCI_Percent
    cmp #$27 ; '''
    beq MCI_Apos
    cmp #$3F ; '?'
    beq MCI_Quest
    cmp #$2F ; '/'
    beq MCI_Slash

    cmp #$61 ; 'a'
    bcc +
    cmp #$7B ; '{'
    bcs +
    sec
    sbc #$20 ; Convert lower to upper
+   cmp #$20 ; Space
    beq MCI_Space
    cmp #$2A ; '*'
    beq MCI_Star
    cmp #$3A ; ':'
    beq MCI_Colon
    cmp #$2D ; '-'
    beq MCI_Dash
    cmp #$3D ; '='
    beq MCI_Equal
    cmp #$30 ; '0'
    bcc MCI_Default
    cmp #$3A ; ':'
    bcc MCI_Num
    cmp #$41 ; 'A'
    bcc MCI_Default
    cmp #$5B ; '['
    bcc MCI_Alpha
MCI_Default:
MCI_Space:
    lda #0
    rts
MCI_Star:
    lda #50
    rts
MCI_Exclam:
    lda #48
    rts
MCI_Percent:
    lda #42
    rts
MCI_Apos:
    lda #49
    rts
MCI_Colon:
    lda #46
    rts
MCI_Dash:
    lda #47
    rts
MCI_Equal:
    lda #43
    rts
MCI_Num:
    sec
    sbc #$2F
    rts
MCI_Alpha:
    sec
    sbc #$36
    rts
MCI_Quest:
    lda #44
    rts
MCI_Slash:
    lda #45
    rts

; ===================================================================
; INTRODUCTION & GRID SELECTION ENGINE
; ===================================================================
ShowIntroScreen:
    jsr ClearScreen
    
    ; Title
    lda #1
    sta IS_BOLD
    lda #88
    sta X1LO
    lda #12
    sta Y1
    ldy #0
-   lda MsgTitle,y
    beq +
    sty TEMP_HI
    lda TitleColors,y
    sta COLOR
    lda MsgTitle,y
    jsr DrawChar
    lda X1LO
    clc
    adc #8
    sta X1LO
    ldy TEMP_HI
    iny
    bne -
+   lda #0
    sta IS_BOLD

    ; Decorative border around title
    lda #3 ; White
    sta COLOR
    lda #80
    sta X1LO
    lda #8
    sta Y1
    lda #120
    sta TEMP_LEN
    jsr DrawHLineFromX1
    lda #80
    sta X1LO
    lda #24
    sta Y1
    lda #120
    sta TEMP_LEN
    jsr DrawHLineFromX1
    lda #80
    sta X1LO
    lda #8
    sta Y1
    lda #16
    sta TEMP_LEN
    jsr DrawVLineFromX1
    lda #200
    sta X1LO
    lda #8
    sta Y1
    lda #16
    sta TEMP_LEN
    jsr DrawVLineFromX1

    ; Subtitle
    lda #6 ; Blue
    sta COLOR
    lda #56
    sta X1LO
    lda #32
    sta Y1
    lda #<MsgSubTitle
    ldy #>MsgSubTitle
    jsr DrawString

    ; Section header
    lda #1 ; Green
    sta COLOR
    lda #32
    sta X1LO
    lda #48
    sta Y1
    lda #<MsgChooseGrid
    ldy #>MsgChooseGrid
    jsr DrawString

    ; Draw the 3 options
    jsr DrawIntroCards

    ; Bottom Help / Instructions
    lda #3 ; White
    sta COLOR
    lda #12
    sta X1LO
    lda #168
    sta Y1
    lda #<MsgIntroHelp1
    ldy #>MsgIntroHelp1
    jsr DrawString

    lda #6 ; Blue
    sta COLOR
    lda #44
    sta X1LO
    lda #180
    sta Y1
    lda #<MsgIntroHelp2
    ldy #>MsgIntroHelp2
    jsr DrawString

    ; Default selection
    lda GRID_CONFIG_IDX
    cmp #3
    bcc +
    lda #0
+   sta INTRO_SEL
    lda #0
    sta JOY_DIR_Y

IntroRefresh:
    jsr HighlightIntroCard

IntroLoop:
    lda KBD
    bpl +
    jmp IntroKey
+   lda BTN0
    bmi _IL_DoConfirm
    lda BTN1
    bpl +
_IL_DoConfirm:
    jmp IntroConfirm
+

    ; Joystick (Haut / Bas)
    ldx #1
    jsr PDL
    tya
    cmp #192
    bcs _IL_JoyDown
    cmp #64
    bcc _IL_JoyUp
    lda #0
    sta JOY_DIR_Y
    jmp IntroLoop

_IL_JoyDown:
    lda JOY_DIR_Y
    bne +
    lda #1
    sta JOY_DIR_Y
    jmp IntroDown
+   jmp IntroLoop

_IL_JoyUp:
    lda JOY_DIR_Y
    bne +
    lda #1
    sta JOY_DIR_Y
    jmp IntroUp
+   jmp IntroLoop

IntroKey:
    sta KBDSTRB
    and #$7F
    
    ; Numbers '1', '5' -> 5x5
    cmp #$31 ; '1'
    beq Sel0_Conf
    cmp #$35 ; '5'
    beq Sel0_Conf
    
    ; Numbers '2', '6' -> 6x6
    cmp #$32 ; '2'
    beq Sel1_Conf
    cmp #$36 ; '6'
    beq Sel1_Conf
    
    ; Numbers '3', '7' -> 7x7
    cmp #$33 ; '3'
    beq Sel2_Conf
    cmp #$37 ; '7'
    beq Sel2_Conf

    ; Up Arrow ($0B) or Left Arrow ($08)
    cmp #$0B
    beq IntroUp
    cmp #$08
    beq IntroUp
    
    ; Down Arrow ($0A) or Right Arrow ($15)
    cmp #$0A
    beq IntroDown
    cmp #$15
    beq IntroDown
    
    ; Enter ($0D) or Space ($20)
    cmp #$0D
    beq IntroConfirm
    cmp #$20
    beq IntroConfirm

    jmp IntroLoop

IntroUp:
    lda INTRO_SEL
    beq +
    dec INTRO_SEL
    jsr ClickSound
    jmp IntroRefresh
+   jmp IntroLoop

IntroDown:
    lda INTRO_SEL
    cmp #2
    bcs +
    inc INTRO_SEL
    jsr ClickSound
    jmp IntroRefresh
+   jmp IntroLoop

Sel0_Conf:
    lda #0
    sta INTRO_SEL
    jmp IntroConfirm

Sel1_Conf:
    lda #1
    sta INTRO_SEL
    jmp IntroConfirm

Sel2_Conf:
    lda #2
    sta INTRO_SEL
    jmp IntroConfirm

IntroConfirm:
    jsr IntroConfirmChime
    lda INTRO_SEL
    jsr InitGridConfig
    rts

DrawIntroCards:
    ; Option 1: 5x5
    lda #3 ; White
    sta COLOR
    lda #38
    sta X1LO
    lda #66
    sta Y1
    lda #<MsgCard1A
    ldy #>MsgCard1A
    jsr DrawString

    lda #1 ; Green
    sta COLOR
    lda #38
    sta X1LO
    lda #76
    sta Y1
    lda #<MsgCard1B
    ldy #>MsgCard1B
    jsr DrawString

    ; Option 2: 6x6
    lda #3 ; White
    sta COLOR
    lda #38
    sta X1LO
    lda #102
    sta Y1
    lda #<MsgCard2A
    ldy #>MsgCard2A
    jsr DrawString

    lda #6 ; Blue
    sta COLOR
    lda #38
    sta X1LO
    lda #112
    sta Y1
    lda #<MsgCard2B
    ldy #>MsgCard2B
    jsr DrawString

    ; Option 3: 7x7
    lda #3 ; White
    sta COLOR
    lda #38
    sta X1LO
    lda #138
    sta Y1
    lda #<MsgCard3A
    ldy #>MsgCard3A
    jsr DrawString

    lda #1 ; Green
    sta COLOR
    lda #38
    sta X1LO
    lda #148
    sta Y1
    lda #<MsgCard3B
    ldy #>MsgCard3B
    jsr DrawString
    rts

HighlightIntroCard:
    ; Erase all 3 frames first
    lda #0
    sta COLOR
    lda #62
    sta Y1
    jsr DrawCardBox
    lda #98
    sta Y1
    jsr DrawCardBox
    lda #134
    sta Y1
    jsr DrawCardBox

    ; Draw active frame in White
    lda #3
    sta COLOR
    lda INTRO_SEL
    beq _HIC_Sel0
    cmp #1
    beq _HIC_Sel1
    lda #134
    sta Y1
    jmp _HIC_Draw
_HIC_Sel0:
    lda #62
    sta Y1
    jmp _HIC_Draw
_HIC_Sel1:
    lda #98
    sta Y1
_HIC_Draw:
    jsr DrawCardBox
    rts

DrawCardBox:
    lda #26
    sta X1LO
    lda #224
    sta TEMP_LEN
    jsr DrawHLineFromX1
    lda Y1
    clc
    adc #26
    sta Y1
    lda #26
    sta X1LO
    lda #224
    sta TEMP_LEN
    jsr DrawHLineFromX1
    lda Y1
    sec
    sbc #26
    sta Y1
    lda #26
    sta X1LO
    lda #26
    sta TEMP_LEN
    jsr DrawVLineFromX1
    lda #250
    sta X1LO
    lda #26
    sta TEMP_LEN
    jsr DrawVLineFromX1
    rts

IntroConfirmChime:
    lda #35
    ldx #20
    jsr PlayToneSimple
    lda #28
    ldx #25
    jsr PlayToneSimple
    lda #21
    ldx #35
    jsr PlayToneSimple
    rts

PlayToneSimple:
    sta FAREWELL_PITCH
PTS_Loop1:
    lda SPEAKER
    ldy FAREWELL_PITCH
PTS_Loop2:
    dey
    bne PTS_Loop2
    dex
    bne PTS_Loop1
    rts

InitGridConfig:
    sta GRID_CONFIG_IDX
    tax
    lda Tab_GridSize,x
    sta GRID_SIZE
    lda Tab_GridSizeP1,x
    sta GRID_SIZE_P1
    lda Tab_GridSizeM1,x
    sta GRID_SIZE_M1
    lda Tab_TotalBoxes,x
    sta TOTAL_BOXES
    lda Tab_TotalLH,x
    sta TOTAL_LH
    lda Tab_TotalLV,x
    sta TOTAL_LV
    lda Tab_CellW,x
    sta CELL_W
    lda Tab_CellH,x
    sta CELL_H
    lda Tab_FillW,x
    sta FILL_W
    lda Tab_FillH,x
    sta FILL_H
    lda Tab_CurHW,x
    sta CUR_HW
    lda Tab_CurVH,x
    sta CUR_VH
    lda Tab_RowOffsetBase,x
    sta GRID_OFFSET_TABLE
    rts

; Configuration Tables
Tab_GridSize:      .byte 5, 6, 7
Tab_GridSizeP1:    .byte 6, 7, 8
Tab_GridSizeM1:    .byte 4, 5, 6
Tab_TotalBoxes:    .byte 25, 36, 49
Tab_TotalLH:       .byte 30, 42, 56
Tab_TotalLV:       .byte 30, 42, 56
Tab_CellW:         .byte 30, 25, 22
Tab_CellH:         .byte 25, 21, 18
Tab_FillW:         .byte 24, 19, 16
Tab_FillH:         .byte 19, 15, 12
Tab_CurHW:         .byte 34, 29, 26
Tab_CurVH:         .byte 29, 25, 22
Tab_RowOffsetBase: .byte 0, 8, 16

DotXTab:
    ; G=5 (offset 0..7)
    .byte 60, 90, 120, 150, 180, 210, 0, 0
    ; G=6 (offset 8..15)
    .byte 60, 85, 110, 135, 160, 185, 210, 0
    ; G=7 (offset 16..23)
    .byte 57, 79, 101, 123, 145, 167, 189, 211

DotYTab:
    ; G=5 (offset 0..7)
    .byte 30, 55, 80, 105, 130, 155, 0, 0
    ; G=6 (offset 8..15)
    .byte 30, 51, 72, 93, 114, 135, 156, 0
    ; G=7 (offset 16..23)
    .byte 30, 48, 66, 84, 102, 120, 138, 156

RowOffset_G:
    ; G=5 (offset 0..7)
    .byte 0, 5, 10, 15, 20, 25, 30, 35
    ; G=6 (offset 8..15)
    .byte 0, 6, 12, 18, 24, 30, 36, 42
    ; G=7 (offset 16..23)
    .byte 0, 7, 14, 21, 28, 35, 42, 49

RowOffset_GP1:
    ; G=5 (G+1=6) (offset 0..7)
    .byte 0, 6, 12, 18, 24, 30, 36, 42
    ; G=6 (G+1=7) (offset 8..15)
    .byte 0, 7, 14, 21, 28, 35, 42, 49
    ; G=7 (G+1=8) (offset 16..23)
    .byte 0, 8, 16, 24, 32, 40, 48, 56

