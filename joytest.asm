; ===================================================================
; JOYTEST - APPLE II JOYSTICK 4 POSITIONS & BUTTONS TESTER
; Displays P0 (X), P1 (Y), Buttons, and 4-Direction Status in real time
; ===================================================================
.cpu "6502"
* = $6000

HOME     = $FC58
COUT     = $FDED
PREAD    = $FB1E
KBD      = $C000
KBDSTRB  = $C010
BTN0     = $C061
BTN1     = $C062

VAL_P0   = $00
VAL_P1   = $01

Start:
    jsr HOME

    ; Print Title via COUT
    ldx #0
_pt_loop:
    lda title_str,x
    beq _pt_done
    jsr COUT
    inx
    bne _pt_loop
_pt_done:

MainLoop:
    ; Read Paddle 0 (X Axis)
    ldx #0
    jsr PREAD
    sty VAL_P0

    ; Read Paddle 1 (Y Axis)
    ldx #1
    jsr PREAD
    sty VAL_P1

    ; Line 4 ($04A8 + 15 = $04B7): Print P0 value (0..255)
    lda VAL_P0
    ldx #$B7
    ldy #$04
    jsr PrintDec3

    ; Line 4 ($04B7 + 5 = $04BC): Status [GAUCHE] / [CENTRE] / [DROITE]
    lda VAL_P0
    cmp #90
    bcc _p0_left
    cmp #160
    bcs _p0_right
    ldx #<str_center
    ldy #>str_center
    jmp _p0_show
_p0_left:
    ldx #<str_left
    ldy #>str_left
    jmp _p0_show
_p0_right:
    ldx #<str_right
    ldy #>str_right
_p0_show:
    lda #$BC
    sta $06
    lda #$04
    sta $07
    jsr PrintStrAt

    ; Line 6 ($05A8 + 15 = $05B7): Print P1 value (0..255)
    lda VAL_P1
    ldx #$B7
    ldy #$05
    jsr PrintDec3

    ; Line 6 ($05B7 + 5 = $05BC): Status [HAUT] / [CENTRE] / [BAS]
    lda VAL_P1
    cmp #90
    bcc _p1_up
    cmp #160
    bcs _p1_down
    ldx #<str_center
    ldy #>str_center
    jmp _p1_show
_p1_up:
    ldx #<str_up
    ldy #>str_up
    jmp _p1_show
_p1_down:
    ldx #<str_down
    ldy #>str_down
_p1_show:
    lda #$BC
    sta $06
    lda #$05
    sta $07
    jsr PrintStrAt

    ; Line 9 ($06A8 + 15 = $06B7): Button 0
    lda BTN0
    bmi _btn0_down
    ldx #<str_btn_rel
    ldy #>str_btn_rel
    jmp _btn0_show
_btn0_down:
    ldx #<str_btn_press
    ldy #>str_btn_press
_btn0_show:
    lda #$B7
    sta $06
    lda #$06
    sta $07
    jsr PrintStrAt

    ; Line 11 ($07A8 + 15 = $07B7): Button 1
    lda BTN1
    bmi _btn1_down
    ldx #<str_btn_rel
    ldy #>str_btn_rel
    jmp _btn1_show
_btn1_down:
    ldx #<str_btn_press
    ldy #>str_btn_press
_btn1_show:
    lda #$B7
    sta $06
    lda #$07
    sta $07
    jsr PrintStrAt

    ; Visual Compass display at lines 15..17 ($0700..$0780)
    ; Line 14 ($0680 + 18 = $0692): Top row (UP)
    ; Line 15 ($0700 + 18 = $0712): Center row (LEFT, CENTER, RIGHT)
    ; Line 16 ($0780 + 18 = $0792): Bottom row (DOWN)

    ; Clear the 3x3 compass area
    lda #' ' | $80
    sta $0691
    sta $0692
    sta $0693
    sta $0711
    sta $0712
    sta $0713
    sta $0791
    sta $0792
    sta $0793

    ; Crosshair center
    lda #'+' | $80
    sta $0712

    ; Determine Col offset (0, 1, 2)
    ldx #1          ; Center
    lda VAL_P0
    cmp #90
    bcc _c_left
    cmp #160
    bcc _c_col_ok
    ldx #2          ; Right
    bne _c_col_ok
_c_left:
    ldx #0          ; Left
_c_col_ok:

    ; Determine Row
    lda VAL_P1
    cmp #90
    bcc _r_up
    cmp #160
    bcc _r_center

    ; Row DOWN ($0791 + X)
    lda #'*' | $80
    cpx #0
    bne +
    sta $0791
    jmp _delay
+   cpx #1
    bne +
    sta $0792
    jmp _delay
+   sta $0793
    jmp _delay

_r_up:
    ; Row UP ($0691 + X)
    lda #'*' | $80
    cpx #0
    bne +
    sta $0691
    jmp _delay
+   cpx #1
    bne +
    sta $0692
    jmp _delay
+   sta $0693
    jmp _delay

_r_center:
    ; Row CENTER ($0711 + X)
    lda #'*' | $80
    cpx #0
    bne +
    sta $0711
    jmp _delay
+   cpx #1
    bne +
    sta $0712
    jmp _delay
+   sta $0713

_delay:
    ldx #$15
_del_out:
    ldy #$FF
_del_in:
    dey
    bne _del_in
    dex
    bne _del_out

    lda KBD
    bpl _next
    bit KBDSTRB
    cmp #$9B        ; ESC
    beq _quit
    cmp #$D1        ; 'Q'
    beq _quit
    cmp #$F1        ; 'q'
    beq _quit
_next:
    jmp MainLoop

_quit:
    jsr HOME
    ; Execute DOS command RUN HELLO via COUT with CHR$(4)
    ldx #0
-   lda run_hello_cmd,x
    beq +
    jsr COUT
    inx
    bne -
+   rts

PrintStrAt:
    stx $08
    sty $09
    ldy #0
-   lda ($08),y
    beq +
    sta ($06),y
    iny
    bne -
+   rts

PrintDec3:
    stx $06
    sty $07
    ldy #0
    ldx #'0' | $80
-   cmp #100
    bcc +
    sec
    sbc #100
    inx
    bne -
+   txa
    sta ($06),y
    iny

    ldx #'0' | $80
-   cmp #10
    bcc +
    sec
    sbc #10
    inx
    bne -
+   pha
    txa
    sta ($06),y
    iny

    pla
    clc
    adc #'0' | $80
    sta ($06),y
    rts

; All characters have bit 7 set for Apple II text screen
title_str:
    .byte $8D, $8D
    .text " *** TEST DES 4 POSITIONS DU JOYSTICK ***" | $80
    .byte $8D, $8D
    .text " AXE X (P0)  :                   " | $80
    .byte $8D, $8D
    .text " AXE Y (P1)  :                   " | $80
    .byte $8D, $8D, $8D
    .text " BOUTON 0    :                   " | $80
    .byte $8D
    .text " BOUTON 1    :                   " | $80
    .byte $8D, $8D
    .text " BOUSSOLE VISUELLE (4 POSITIONS):" | $80
    .byte $8D, $8D, $8D, $8D, $8D, $8D
    .text " SEUILS: GAUCHE/HAUT < 90" | $80
    .byte $8D
    .text "         DROITE/BAS  >= 160" | $80
    .byte $8D, $8D
    .text " APPUYER SUR 'ESC' OU 'Q' POUR REVENIR" | $80
    .byte 0

str_left:      .text "[ GAUCHE ]" | $80, 0
str_right:     .text "[ DROITE ]" | $80, 0
str_center:    .text "[ CENTRE ]" | $80, 0
str_up:        .text "[  HAUT  ]" | $80, 0
str_down:      .text "[  BAS   ]" | $80, 0
str_btn_rel:   .text "RELACHE " | $80, 0
str_btn_press: .text "APPUYE !" | $80, 0

run_hello_cmd:
    .byte 4                     ; Ctrl-D
    .text "RUN HELLO" | $80
    .byte $8D, 0
