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
TEMP_PTR:         .byte 0
TEMP_CHAR:        .byte 0
AI_LEVEL:         .byte 1 
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
MsgLevel:         .byte 22, 15, 32, 15, 22, 43, 255 ; "LEVEL="

LH: .fill 30, 0
LV: .fill 30, 0
BX: .fill 25, 0

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
SPINNER_STATE: .byte 0
SIM_LH:   .fill 30, 0
SIM_LV:   .fill 30, 0
SIM_BX:   .fill 25, 0
MC_PROG_LO: .byte 0
MC_PROG_HI: .byte 0

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

MsgP1:       .byte 26, 22, 11, 35, 15, 28, 255 ; PLAYER
MsgP2:       .byte 13, 25, 23, 26, 255         ; COMP
MsgP1Wins:   .byte 26, 22, 11, 35, 15, 28, 0, 33, 19, 24, 29, 255 ; PLAYER WINS
MsgP2Wins:   .byte 13, 25, 23, 26, 0, 33, 19, 24, 29, 255         ; COMP WINS
MsgReplay:   .byte 28, 15, 26, 22, 11, 35, 44, 0, 35, 45, 24, 255 ; REPLAY? Y/N
MsgTitle:    .byte 26, 19, 26, 25, 26, 19, 26, 15, 30, 30, 15, 255 ; PIPOPIPETTE
TitleColors: .byte 1, 6, 3, 1, 6, 3, 1, 6, 3, 1, 6
Start:
    sta TXTCLR
    sta MIXCLR
    sta TXTPAGE1
    sta HIRES
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
    sta BX,x
    inx
    cpx #30
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
    
    ; 1. Blink Update
    inc BLINK_TIMER
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

ML_InputPass:
    ; 3. Global Checks
    lda KBD
    bpl ML_NoKbd
    sta KBDSTRB
    
    cmp #$B1 ; '1'
    bne k1
    lda #0 
    sta AI_LEVEL 
    jsr DrawLabels
    jmp JoyDone ; Keyboard action done, skip joy
k1  cmp #$B2 ; '2'
    bne k2
    lda #1 
    sta AI_LEVEL 
    jsr DrawLabels
    jmp JoyDone
k2  cmp #$B3 ; '3'
    bne k3
    lda #2 
    sta AI_LEVEL 
    jsr DrawLabels
    jmp JoyDone
k3  cmp #$8B ; Up Arrow
    bne k4
    jsr DoMoveUp
    jmp JoyDone
k4  cmp #$8A ; Down Arrow
    bne k5
    jsr DoMoveDown
    jmp JoyDone
k5  cmp #$88 ; Left Arrow
    bne k6
    jsr DoMoveLeft
    jmp JoyDone
k6  cmp #$95 ; Right Arrow
    bne k7
    jsr DoMoveRight
    jmp JoyDone
k7  cmp #$A0 ; Space
    bne k8
    jsr DoModeToggle
    jmp JoyDone
k8  cmp #$8D ; Enter
    bne ML_NoKbd
    jsr DoPlacer
    jmp JoyDone
ML_NoKbd:

    lda P1_SCORE
    clc 
    adc P2_SCORE 
    cmp #25
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
    ; Horizontal (5x6)
    lda TEMP_CX
    cmp #5
    bcs CAT_Fail
    lda TEMP_CY
    cmp #6
    bcs CAT_Fail
    lda TEMP_CX
    sta DRAW_X
    lda TEMP_CY
    sta DRAW_Y
    jsr GetIndLH
    tax
    lda LH,x
    rts
+   ; Vertical (6x5)
    lda TEMP_CX
    cmp #6
    bcs CAT_Fail
    lda TEMP_CY
    cmp #5
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
    cmp #5
    bcc FAM_X
    jmp FAM_NextX
FAM_CY_H:
    lda TEMP_CY
    cmp #6
    bcc FAM_X
FAM_NextX:
    inc TEMP_CX
    lda MODE
    beq FAM_CX_H
    lda TEMP_CX
    cmp #6
    bcc FAM_Y
    jmp FAM_Fail
FAM_CX_H:
    lda TEMP_CX
    cmp #5
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
    jsr Mult30 
    clc 
    adc #60 
    sta X1LO
    lda CURSOR_Y 
    jsr Mult25 
    clc 
    adc #30 
    sta Y1
    jsr DrawSingleDot
    
    ; Dot 2 (End)
    lda MODE
    bne RLD_Vert
    ; Horizontal: Dot is at (X+1, Y)
    lda CURSOR_X 
    clc 
    adc #1 
    jsr Mult30 
    clc 
    adc #60 
    sta X1LO
    lda CURSOR_Y 
    jsr Mult25 
    clc 
    adc #30 
    sta Y1
    jsr DrawSingleDot
    rts
RLD_Vert:
    ; Vertical: Dot is at (X, Y+1)
    lda CURSOR_X 
    jsr Mult30 
    clc 
    adc #60 
    sta X1LO
    lda CURSOR_Y 
    clc 
    adc #1 
    jsr Mult25 
    clc 
    adc #30 
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
    ; Vertical frame (W:4, H:29)
    lda CURSOR_X
    jsr Mult30
    clc
    adc #60
    sec
    sbc #2
    sta BOX_LX
    
    lda CURSOR_Y
    jsr Mult25
    clc
    adc #30
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
    adc #29
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
    lda #29
    sta TEMP_LEN
    jsr DrawVLineFromX1
    ; Right
    lda BOX_LX
    clc
    adc #4
    sta X1LO
    lda BOX_LY
    sta Y1
    lda #29
    sta TEMP_LEN
    jsr DrawVLineFromX1
    rts

HGR_DrawH:
    ; Horizontal frame (W:34, H:4)
    lda CURSOR_X
    jsr Mult30
    clc
    adc #60
    sec
    sbc #2
    sta BOX_LX
    
    lda CURSOR_Y
    jsr Mult25
    clc
    adc #30
    sec
    sbc #2
    sta BOX_LY
    
    ; Top
    lda BOX_LX
    sta X1LO
    lda BOX_LY
    sta Y1
    lda #34
    sta TEMP_LEN
    jsr DrawHLineFromX1
    ; Bottom
    lda BOX_LY
    clc
    adc #4
    sta Y1
    lda BOX_LX
    sta X1LO
    lda #34
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
    adc #34
    sta X1LO
    lda BOX_LY
    sta Y1
    lda #4
    sta TEMP_LEN
    jsr DrawVLineFromX1
    rts

DoMoveRight:
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
+   rts

DoMoveLeft:
    lda #0
    sta BLINK_TIMER
    lda #100
    sta PREV_ON 
    lda CURSOR_X
    beq +
    dec CURSOR_X
+   rts

DoMoveDown:
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
+   rts

DoMoveUp:
    lda #0
    sta BLINK_TIMER
    lda #100
    sta PREV_ON 
    lda CURSOR_Y
    beq +
    dec CURSOR_Y
+   rts





CheckBoundsX:
    lda MODE
    beq CBX_H
    ; Vertical (6 wide)
    lda TEMP_W
    cmp #6
    rts
CBX_H:
    ; Horizontal (5 wide)
    lda TEMP_W
    cmp #5
    rts

CheckBoundsY:
    lda MODE
    beq CBY_H
    ; Vertical (5 high)
    lda TEMP_W
    cmp #5
    rts
CBY_H:
    ; Horizontal (6 high)
    lda TEMP_W
    cmp #6
    rts

ClampCursorByMode:
    lda CURSOR_X
    sta TEMP_W
    jsr CheckBoundsX
    bcc +
    lda MODE
    beq CC_H_X
    lda #5
    sta CURSOR_X
    jmp +
CC_H_X:
    lda #4
    sta CURSOR_X
+   lda CURSOR_Y
    sta TEMP_W
    jsr CheckBoundsY
    bcc +
    lda MODE
    beq CC_H_Y
    lda #4
    sta CURSOR_Y
    rts
CC_H_Y:
    lda #5
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
    cmp #255
    beq DS_Done
    sty TEMP_HI
    jsr DrawChar
    lda X1LO
    clc
    adc #8
    ldx IS_BOLD
    beq +
    clc
    adc #0 ; Gain encore 1 pixel: 8 pixels total for bold
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
    lda #0
    sta IS_BOLD
    lda #3
    sta COLOR
    lda #2
    sta X1LO
    lda #5
    sta Y1
    lda #<MsgLevel
    ldy #>MsgLevel
    jsr DrawString
    
    lda AI_LEVEL
    clc
    adc #2  ; Index 2 is '1'
    jsr DrawChar
    
    lda #0
    sta IS_BOLD ; Ensure bold is off for other things
    
    jsr DrawTitleColored
    rts

EraseAILvlBox:
    lda #5
    sta TEMP_HI
E_AI_YLoop:
    ldy TEMP_HI
    lda HGR_LO,y
    sta PTR
    lda HGR_HI,y
    sta PTR+1
    lda #0
    ldy #0 
E_AI_XLoop:
    sta (PTR),y
    iny
    cpy #9 
    bcc E_AI_XLoop
    inc TEMP_HI
    lda TEMP_HI
    cmp #15
    bcc E_AI_YLoop
    rts

DrawTitleColored:
    lda #1
    sta IS_BOLD
    lda #96
    sta X1LO
    lda #5
    sta Y1
    ldy #0
DTC_Loop:
    lda MsgTitle,y
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
    
    ; Draw White Border
    lda #3
    sta COLOR
    
    ; Top Line
    lda #90
    sta X1LO
    lda #3
    sta Y1
    lda #100
    sta TEMP_LEN
    jsr DrawHLineFromX1
    
    ; Bottom Line
    lda #90
    sta X1LO
    lda #16
    sta Y1
    lda #100
    sta TEMP_LEN
    jsr DrawHLineFromX1
    
    ; Left Side
    lda #90
    sta X1LO
    lda #3
    sta Y1
    lda #14
    sta TEMP_LEN
    jsr DrawVLineFromX1
    
    ; Right Side
    lda #189
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
    lda #84
    sta X1LO
    lda #178
    sta Y1
    lda #3
    sta COLOR
    lda #<MsgReplay
    ldy #>MsgReplay
    jsr DrawString
    rts
    
StateGameOver:
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
    sta TXTSET
    rts

; ===================================================================
; GAMEPLAY ENGINE
; ===================================================================
DoPlacer:
    lda MODE
    beq PlaceHoriz
    
    ; Bounds check V
    lda CURSOR_X
    cmp #6
    bcs DP_Fail
    lda CURSOR_Y
    cmp #5
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
    cmp #5
    bcs DP_Fail
    lda CURSOR_Y
    cmp #6
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
    jsr Mult30
    clc
    adc #60
    sta X1LO
    lda CURSOR_Y
    jsr Mult25
    clc
    adc #30
    sta Y1
    
    lda MODE
    beq Pl_H
    lda #25
    sta TEMP_LEN
    jsr DrawThickVLine
    jmp Pl_Done
Pl_H:
    lda #30
    sta TEMP_LEN
    jsr DrawThickHLine
Pl_Done:
CP_SimModeSkip2:
    
    jsr BoxCheck
    
    ; Check Game Over (Total Score = 25)
    lda P1_SCORE
    clc
    adc P2_SCORE
    cmp #25
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
    cmp #5
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
    cmp #5
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
    cmp #5
    bcc +
    rts ; Safety
+   jsr Mult30
    clc
    adc #63
    sta DRAW_X
    pha                 
    
    lda Y1
    cmp #5
    bcc +
    pla ; restore stack
    rts ; Safety
+   jsr Mult25
    clc
    adc #33
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
    lda #19
    sta TEMP_C
FillY:
    pla
    pha                 
    sta DRAW_X
    lda #24
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
    jsr ThinkDelay
    lda #0
    sta TEMP_W

    ; 1. Try to close a box
    jsr ScanClose
    bcs FoundSmartMove
    
    ; 2. Add Level 3 Monaco
    lda AI_LEVEL
    cmp #2
    bne AIL_L1_2
    jsr Monaco
    rts
AIL_L1_2:
    
    ; 3. If Med (0), skip safety
    lda AI_LEVEL
    beq AIRetry
    
    ; 4. Try to find a safe move
    jsr ScanSafe
    bcs FoundSmartMove

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
    
    jsr CheckAvailCursor ; New variant of CheckAvailTemp
    beq FoundSmartMove
    
    inc AI_LOOP_CTR
    lda AI_LOOP_CTR
    cmp #255
    bcc AIRetryLoop            
    
    jsr FindFallbackOrNext
    beq FoundSmartMove
    rts ; Simply return if no moves found, MainLoop handles game state
    
FoundSmartMove:
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
    cmp #5
    bcc SC_LoopX
    inc TEMP_CX
    lda TEMP_CX
    cmp #5
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
    lda CURSOR_X
    cmp #6
    bcc SS_XLoop
    inc CURSOR_Y
    lda CURSOR_Y
    cmp #6
    bcc SS_YLoop
    inc MODE
    lda MODE
    cmp #2
    bcc SS_ModeLoop
    clc
    rts

Monaco:
    jsr SaveState
    
    lda #0
    sta SPINNER_STATE
    sta MC_PROG_LO
    sta MC_PROG_HI

    lda #0
    sta BEST_SCORE
    sta BEST_M
    sta BEST_X
    sta BEST_Y
    
    ; Setup Rollouts per move (increased to 4 for extreme depth)
    lda #4
    sta MC_ACC ; Temp storage for rollout count per move
    
    lda #0
    sta MC_M
M_ModeLoop:
    lda #0
    sta MC_Y
M_YLoop:
    lda #0
    sta MC_X
M_XLoop:
    jsr SpinnerTick
    
    lda MC_M
    sta MODE
    lda MC_X
    sta CURSOR_X
    lda MC_Y
    sta CURSOR_Y
    jsr CheckAvailCursor
    beq M_CheckValid
    jmp M_NextPoint
M_CheckValid:
    lda #0
    sta MC_ACC ; Reset accumulator for this candidate move
    lda #4 ; Rollouts per move
    sta MC_R
M_RolloutLoop:
    lda #1
    sta SIM_MODE
    
    lda MC_M
    sta MODE
    lda MC_X
    sta CURSOR_X
    lda MC_Y
    sta CURSOR_Y
    jsr DoPlacer
    
    jsr SimulateGame
    
    lda P2_SCORE
    clc
    adc MC_ACC
    sta MC_ACC
    
    jsr LoadState
    lda #0
    sta SIM_MODE
    
    dec MC_R
    beq M_RolloutEnd
    jmp M_RolloutLoop
    
M_RolloutEnd:
    lda MC_ACC
    cmp BEST_SCORE
    beq M_NextPoint ; Keep the first best
    bcc M_NextPoint ; Less than best
    sta BEST_SCORE
    lda MC_M
    sta BEST_M
    lda MC_X
    sta BEST_X
    lda MC_Y
    sta BEST_Y
    
M_NextPoint:
    inc MC_X
    lda MC_X
    cmp #6
    bcs M_NP_Y
    jmp M_XLoop
M_NP_Y:
    inc MC_Y
    lda MC_Y
    cmp #6
    bcs M_NP_M
    jmp M_YLoop
M_NP_M:
    inc MC_M
    lda MC_M
    cmp #2
    bcs M_NP_Done
    jmp M_ModeLoop
M_NP_Done:
    lda #0
    sta COLOR
    sta IS_BOLD
    lda #2
    sta X1LO
    lda #15
    sta Y1
    lda SPINNER_STATE
    clc
    adc #37
    jsr DrawChar
    
    lda BEST_M
    sta MODE
    lda BEST_X
    sta CURSOR_X
    lda BEST_Y
    sta CURSOR_Y
    jsr DoPlacer
    sec
    rts

SimulateGame:
SG_Loop:
    lda P1_SCORE
    clc
    adc P2_SCORE
    cmp #25
    bcs SG_Done
    
    jsr ScanClose
    bcs SG_Found
    
    jsr ScanSafe
    bcs SG_Found
    
SG_Rand:
    lda #10 ; 10 attempts for a truly random spot
    sta AI_LOOP_CTR
SG_RETry:
    jsr LFSR
    and #1
    sta MODE
    jsr LFSR
    and #7
    cmp #6
    bcs SG_RENext
    sta CURSOR_X
    jsr LFSR
    and #7
    cmp #6
    bcs SG_RENext
    sta CURSOR_Y
    
    jsr CheckAvailCursor
    beq SG_Found
SG_RENext:
    dec AI_LOOP_CTR
    bne SG_RETry

    ; If random failed, use fallback
    jsr FindFallbackOrNext
    beq SG_Found
    jmp SG_Done

SG_Found:
    jsr DoPlacer
    jmp SG_Loop
SG_Done:
    rts

SpinnerTick:
    lda COLOR
    pha
    lda IS_BOLD
    pha
    lda X1LO
    pha
    lda Y1
    pha

    ; EFFAÇAGE TOTAL DE LA ZONE (X=2 à X=50, Y=15 à Y=23)
    lda #0
    sta COLOR
    ldy #15
_ST_Erase:
    tya
    pha ; Save Y on stack
    sta DRAW_Y
    lda #2
    sta DRAW_X
    lda #50
    sta TEMP_LEN
    jsr DrawHLine
    pla
    tay ; Restore Y
    iny
    cpy #24
    bcc _ST_Erase

    ; Update Spinner State
    inc SPINNER_STATE
    lda SPINNER_STATE
    and #3
    sta SPINNER_STATE
    
    ; Update Progress (72 iterations max)
    ; (~1.39 par itér = $63 en part fractionnaire 8 bits)
    clc
    lda MC_PROG_LO
    adc #$63 
    sta MC_PROG_LO
    lda MC_PROG_HI
    adc #1
    sta MC_PROG_HI
    cmp #101
    bcc +
    lda #100
    sta MC_PROG_HI
+
    ; DESSIN DU SPINNER
    lda #3 ; White
    sta COLOR
    lda #0
    sta IS_BOLD
    lda #2
    sta X1LO
    lda #15
    sta Y1
    lda SPINNER_STATE
    clc
    adc #37
    jsr DrawChar
    
    ; DESSIN DU POURCENTAGE
    lda #10
    sta X1LO
    lda MC_PROG_HI
    jsr Draw3Digits
    
    pla
    sta Y1
    pla
    sta X1LO
    pla
    sta IS_BOLD
    pla
    sta COLOR
    rts

Draw3Digits:
    ; A = Valeur en entrée (0-100)
    sta TEMP_DIGIT
    
    ; Centaines
    lda TEMP_DIGIT
    jsr Div100
    beq _D3_Skip100
    clc
    adc #1 ; '1'
    jsr DrawChar
    jmp _D3_Next100
_D3_Skip100:
    lda #0 ; Espace
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
    adc #1 ; Digit base
    jsr DrawChar
    jmp _D3_Next10
_D3_Skip10:
    ; On met un espace si les centaines sont aussi 0
    lda TEMP_DIGIT
    jsr Div100
    bne _D3_Zero10 ; Si 100+, on écrit le 0 de 10x
    lda #0 ; Espace
    jsr DrawChar
    jmp _D3_Next10
_D3_Zero10:
    lda #1 ; '0'
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
    adc #1
    jsr DrawChar
    
    ; Symbole %
    lda X1LO
    clc
    adc #8
    sta X1LO
    lda #42 ; Index du '%'
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

SaveState:
    ldx #0
SSLoop:
    lda LH,x
    sta SIM_LH,x
    lda LV,x
    sta SIM_LV,x
    cpx #25
    bcs SSLSkip
    lda BX,x
    sta SIM_BX,x
SSLSkip:
    inx
    cpx #30
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
    rts
    
LoadState:
    ldx #0
LSLoop:
    lda SIM_LH,x
    sta LH,x
    lda SIM_LV,x
    sta LV,x
    cpx #25
    bcs LSLSkip
    lda SIM_BX,x
    sta BX,x
LSLSkip:
    inx
    cpx #30
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
    cmp #5
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
    cmp #5
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
    ldy #250
TD_Out:
    ldx #250
TD_In:
    dex
    bne TD_In
    dey
    bne TD_Out
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
    cpx #$40
    bcc CS_Loop
    rts

PlotPixel:
    ldy DRAW_Y
    lda HGR_LO,y
    sta PTR
    lda HGR_HI,y
    sta PTR+1
    
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
    jsr Mult30
    clc
    adc #60
    sta X1LO
    
    lda TEMP_HI
    jsr Mult25
    clc
    adc #30
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
    cmp #6
    bne LoopDX
    
    inc TEMP_HI
    lda TEMP_HI
    cmp #6
    bne LoopDY
    rts

Mult30:
    sta TEMP_MUL
    lda #0
    ldx TEMP_MUL
    beq M30D
M30_Loop:
    clc
    adc #30
    dex
    bne M30_Loop
M30D: rts

Mult25:
    sta TEMP_MUL
    lda #0
    ldx TEMP_MUL
    beq M25D
M25_Loop:
    clc
    adc #25
    dex
    bne M25_Loop
M25D: rts

GetIndLH:
    lda DRAW_Y
    asl
    asl
    clc
    adc DRAW_Y
    clc
    adc DRAW_X
    rts

GetIndBX:
    lda DRAW_Y
    asl
    asl
    clc
    adc DRAW_Y
    clc
    adc DRAW_X
    rts


GetIndLV:
    lda DRAW_Y
    asl
    clc
    adc DRAW_Y
    asl
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
    adc #1
    jsr DrawChar
    
    lda X1LO
    clc
    adc #8
    sta X1LO
    
    lda DIGIT0
    clc
    adc #1
    jsr DrawChar
    rts


DrawChar:
    pha
    jsr DrawCharOnce
    pla
    ldx IS_BOLD
    beq +
    pha
    inc X1LO
    jsr DrawCharOnce
    dec X1LO
    pla
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
