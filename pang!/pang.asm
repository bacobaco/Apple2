; ===================================================================
; PANG! (BUSTER BROS) - 100% AUTHENTIC ARCADE REPLICA FOR APPLE II
; 6502 Assembly - High Resolution Graphics (HGR 280x192)
; Full Color, Analog Joystick Support, Double-Buffering
; Symmetrical Per-Page Dirty-Rectangle Architecture
; Target Assembler: 64tass
; ===================================================================

.cpu "6502"
* = $6000

    jmp Start

; ===================================================================
; HARDWARE EQUATES (APPLE II / IIe / IIc)
; ===================================================================
TXTCLR   = $C050        ; Switch to Graphics mode
TXTSET   = $C051        ; Switch to Text mode
MIXCLR   = $C052        ; Full screen graphics (no bottom text)
MIXSET   = $C053        ; Mixed graphics + 4-line text
TXTPAGE1 = $C054        ; Display HGR Page 1 ($2000-$3FFF)
TXTPAGE2 = $C055        ; Display HGR Page 2 ($4000-$5FFF)
HIRES    = $C057        ; Enable High-Resolution mode (280x192)

KBD      = $C000        ; Keyboard data (Bit 7 = 1 if key pressed)
KBDSTRB  = $C010        ; Clear keyboard strobe
SPEAKER  = $C030        ; Speaker click toggle
BTN0     = $C061        ; Joystick Button 0 (Bit 7 = 1 if pressed)
BTN1     = $C062        ; Joystick Button 1 (Bit 7 = 1 if pressed)
PREAD    = $FB1E        ; ROM Paddle / Joystick read (X=0 -> Y=0..255)
COUT     = $FDED        ; ROM routine to output character in A
HOME     = $FC58        ; Clear text screen
SETTXT   = $FB2F        ; Set text window

; ===================================================================
; ZERO PAGE VARIABLES ($06 - $1F)
; ===================================================================
PTR_LO          = $06   ; Screen draw pointer LO
PTR_HI          = $07   ; Screen draw pointer HI
PTR2_LO         = $08   ; Secondary screen pointer LO
PTR2_HI         = $09   ; Secondary screen pointer HI
SRC_LO          = $0A   ; Source sprite pointer LO
SRC_HI          = $0B   ; Source sprite pointer HI
TMP_X           = $0C   ; Temp X coordinate
TMP_Y           = $0D   ; Temp Y coordinate
TMP_BYTE        = $0E   ; Temp byte
TMP_SHIFT       = $0F   ; Temp shift (0..6)
TMP_COL         = $10   ; Temp column (0..39)
TEMP_VAL        = $11   ; General temp variable
DRAW_PAGE_OFF   = $12   ; $00 for Page 1, $20 for Page 2
CURR_PAGE       = $13   ; 0 = Page 1 displayed, 1 = Page 2 displayed
BALL_IDX        = $14   ; Current ball slot index
TEMP_VAL2       = $15   ; Secondary temp variable
STR_PTR_LO      = $16   ; String pointer LO
STR_PTR_HI      = $17   ; String pointer HI
RAND_SEED       = $18   ; LFSR random seed
TEMP_LINES      = $19   ; Line counter for blitters
TEMP_BYTES      = $1A   ; Byte width counter for blitters
TMP_ROW         = $1B   ; Temp tile row (0..23)
TMP_TILE        = $1C   ; Temp tile ID

; ===================================================================
; GAME ENGINE CONSTANTS
; ===================================================================
LEFT_WALL_X     = 14    ; Screen X pixel 14 (byte column 2)
RIGHT_WALL_X    = 252   ; Screen X pixel 252 (byte column 36)
CEILING_Y       = 18    ; Top boundary scanline
FLOOR_Y         = 174   ; Ground baseline scanline
HUD_Y           = 182   ; HUD text scanline
PLAYER_START_X  = 126   ; Center starting X
PLAYER_FLOOR_Y  = 154   ; Player baseline (154 + 20 = 174)
PLAYER_H        = 20    ; Buster is 20 scanlines tall
PLAYER_W        = 14    ; Buster is 14 pixels wide
PLAYER_SPEED    = 2     ; Pixels per frame
WIRE_SPEED      = 5     ; Pixels per frame upward
MAX_BALLS       = 16    ; Up to 16 active ball slots
GRAVITY_FRAC    = 60    ; Fixed-point gravity acceleration (~0.23 px/frame^2)

; Colors in HGR (Bit 7 = 1)
COLOR_ORANGE    = $D5   ; %11010101
COLOR_BLUE      = $AA   ; %10101010
COLOR_WHITE     = $7F   ; %01111111

; Tile IDs
TILE_EMPTY      = 0
TILE_SOLID      = 1
TILE_BREAKABLE  = 2
TILE_LADDER     = 3

; ===================================================================
; BSS BUFFERS IN FREE RAM ($1000 - $15BF)
; ===================================================================
div7_table      = $1000 ; 256 bytes: X / 7
mod7_table      = $1100 ; 256 bytes: X % 7
tilemap         = $1200 ; 960 bytes: 40 cols x 24 rows

; ===================================================================
; DATA INCLUDES (Pre-shifted sprites & HGR line tables)
; ===================================================================
.include "pang_data.asm"

; ===================================================================
; GAME STATE VARIABLES
; ===================================================================
saved_sp:           .byte $FF
game_running:       .byte 1
stage_num:          .byte 1
lives:              .byte 3
score_lo:           .byte 0     ; BCD score
score_hi:           .byte 0
active_balls_count: .byte 0
stage_clear_timer:  .byte 0
player_hit_timer:   .byte 0
player_invinc_timer:.byte 0
fire_held:          .byte 0
fire_cooldown:      .byte 0
fire_requested:     .byte 0
control_mode:       .byte 0     ; 0=Keyboard, 1=Joystick
joy_connected:      .byte 0     ; 1 if joystick detected
joy_center_x:       .byte 127   ; Auto-calibrated center X
joy_center_y:       .byte 127   ; Auto-calibrated center Y

; Player State
player_x:           .byte PLAYER_START_X
player_y:           .byte 154
player_anim:        .byte 0     ; 0=stand, 1=walk1, 2=walk2, 3=shoot, 4=hit, 5=climb1, 6=climb2
player_shoot_timer: .byte 0
player_walk_phase:  .byte 0
player_dir:         .byte 0     ; 0=idle, 1=left, 2=right
player_vdir:        .byte 0     ; 0=idle, 1=up, 2=down
player_on_ladder:   .byte 0     ; 0=ground/platform, 1=climbing ladder
player_climb_anim_timer: .byte 0

; Harpoon / Wire State
wire_active:        .byte 0
wire_x:             .byte 0
wire_y:             .byte 0
wire_base_y:        .byte FLOOR_Y

; Bubble Slots (MAX_BALLS = 16)
ball_active:        .fill MAX_BALLS, 0
ball_size:          .fill MAX_BALLS, 0      ; 0=small, 1=med, 2=large, 3=huge
ball_x:             .fill MAX_BALLS, 0
ball_vx:            .fill MAX_BALLS, 0      ; Signed byte (-2..+2)
ball_y_int:         .fill MAX_BALLS, 0
ball_y_frac:        .fill MAX_BALLS, 0
ball_vy_int:        .fill MAX_BALLS, 0      ; Signed byte (-8..+8)
ball_vy_frac:       .fill MAX_BALLS, 0

; ===================================================================
; PER-BUFFER DRAWN OBJECT TRACKERS (100% CLEAN ERASING)
; ===================================================================
p1_player_drawn:    .byte 0
p1_player_x:        .byte 0
p1_player_y:        .byte 154
p1_player_anim:     .byte 0
p1_wire_drawn:      .byte 0
p1_wire_x:          .byte 0
p1_wire_y:          .byte 0
p1_ball_drawn:      .fill MAX_BALLS, 0
p1_ball_size:       .fill MAX_BALLS, 0
p1_ball_x:          .fill MAX_BALLS, 0
p1_ball_y:          .fill MAX_BALLS, 0

p2_player_drawn:    .byte 0
p2_player_x:        .byte 0
p2_player_y:        .byte 154
p2_player_anim:     .byte 0
p2_wire_drawn:      .byte 0
p2_wire_x:          .byte 0
p2_wire_y:          .byte 0
p2_ball_drawn:      .fill MAX_BALLS, 0
p2_ball_size:       .fill MAX_BALLS, 0
p2_ball_x:          .fill MAX_BALLS, 0
p2_ball_y:          .fill MAX_BALLS, 0

; Rect descriptor variables for ApplyStageTiles
rect_c1:            .byte 0
rect_c2:            .byte 0
rect_r1:            .byte 0
rect_r2:            .byte 0
rect_type:          .byte 0

; Precalculated tables for tile lookup
row40_table_lo:
    .byte 0, 40, 80, 120, 160, 200, 240, 24, 64, 104, 144, 184, 224, 8, 48, 88, 128, 168, 208, 248, 32, 72, 112, 152
row40_table_hi:
    .byte 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3

; ===================================================================
; STAGE DESCRIPTORS (RECT FORMAT: C1, C2, R1, R2, TYPE, $FF=END)
; ===================================================================
Stage1_Tiles:
    .byte $FF           ; Flat ground, open arena

Stage2_Tiles:
    ; Central solid steel girder platform (Row 12, Cols 10..29)
    .byte 10, 29, 12, 12, TILE_SOLID
    ; Central access ladder (Col 19, Rows 12..21)
    .byte 19, 19, 12, 21, TILE_LADDER
    ; Left breakable glass crystal blocks (Row 8, Cols 5..8)
    .byte 5, 8, 8, 8, TILE_BREAKABLE
    ; Right breakable glass crystal blocks (Row 8, Cols 31..34)
    .byte 31, 34, 8, 8, TILE_BREAKABLE
    .byte $FF

Stage3_Tiles:
    ; Left elevated platform (Row 12, Cols 4..16)
    .byte 4, 16, 12, 12, TILE_SOLID
    ; Left access ladder (Col 10, Rows 12..21)
    .byte 10, 10, 12, 21, TILE_LADDER
    ; Right elevated platform (Row 12, Cols 23..35)
    .byte 23, 35, 12, 12, TILE_SOLID
    ; Right access ladder (Col 29, Rows 12..21)
    .byte 29, 29, 12, 21, TILE_LADDER
    ; Central breakable bridge (Row 12, Cols 17..22)
    .byte 17, 22, 12, 12, TILE_BREAKABLE
    .byte $FF

; Physics lookup tables per size (0..3)
ball_widths:        .byte 8, 14, 20, 26
ball_heights:       .byte 8, 14, 20, 26
ball_clear_bytes:   .byte 2, 3, 4, 5
ball_bounce_vy:     .byte $FC, $FB, $FA, $F9   ; -4, -5, -6, -7 on floor bounce
ball_pop_vy:        .byte $FD, $FC, $FB, $FA   ; -3, -4, -5, -6 when popped

; HUD Strings
str_score_lbl:      .text "SCORE:", 0
str_stage_lbl:      .text "STAGE 01", 0
str_lives_lbl:      .text "LIVES:", 0

; ===================================================================
; MAIN ENTRY POINT
; ===================================================================
Start:
    tsx
    stx saved_sp
    sei
    cld

    jsr InitDivMod7Tables
    jsr InitGraphics
    jsr ResetGame
    jsr LoadStage

; ===================================================================
; MAIN GAME LOOP
; ===================================================================
MainLoop:
    ; 1. Input handling (Keyboard & Joystick)
    jsr ReadControls

    ; 2. Game logic & physics
    lda stage_clear_timer
    beq +
    dec stage_clear_timer
    bne _skip_logic
    inc stage_num
    jsr LoadStage
    jmp _skip_logic
+
    lda player_hit_timer
    beq +
    dec player_hit_timer
    bne _skip_logic
    jsr RespawnPlayer
    jmp _skip_logic
+
    jsr UpdatePlayer
    jsr UpdateWire
    jsr UpdateBalls
    jsr CheckCollisions

_skip_logic:
    ; 3. Rendering to active back-buffer
    jsr RenderFrame

    ; 4. Buffer flip
    jsr FlipBuffers

    ; 5. Pacing / Frame Sync
    jsr FrameSync

    ; Loop
    lda game_running
    bne MainLoop

QuitGame:
    bit TXTSET          ; Back to text mode
    bit $C056           ; Lo-res
    lda #$FF
    sta $32             ; Normal text
    jsr SETTXT
    jsr HOME
    sta KBDSTRB
    ldx saved_sp
    txs
    cli
    rts

; ===================================================================
; INITIALIZATION ROUTINES
; ===================================================================
InitDivMod7Tables:
    ldx #0
    ldy #0
    lda #0
-   sta mod7_table, x
    tya
    sta div7_table, x
    lda mod7_table, x
    clc
    adc #1
    cmp #7
    bcc +
    lda #0
    iny
+   inx
    bne -
    rts

InitGraphics:
    bit TXTCLR          ; Graphics mode
    bit MIXCLR          ; Full screen 192 lines
    bit HIRES           ; High resolution
    bit TXTPAGE1        ; Show Page 1

    lda #0
    sta CURR_PAGE
    lda #$20
    sta DRAW_PAGE_OFF   ; Back-buffer is Page 2 initially

    ; Clear both pages completely
    jsr ClearPage1
    jsr ClearPage2

    ; Draw permanent colored borders & HUD on both pages
    lda #0
    sta DRAW_PAGE_OFF
    jsr DrawArenaBorders
    jsr DrawHUD

    lda #$20
    sta DRAW_PAGE_OFF
    jsr DrawArenaBorders
    jsr DrawHUD

    rts

ClearPage1:
    lda #0
    sta DRAW_PAGE_OFF
    jmp ClearActivePage

ClearPage2:
    lda #$20
    sta DRAW_PAGE_OFF
    jmp ClearActivePage

ClearActivePage:
    ldx #0
-   lda hgr_lo, x
    sta PTR_LO
    lda hgr_hi, x
    clc
    adc DRAW_PAGE_OFF
    sta PTR_HI
    lda #0
    ldy #39
_cap_b:
    sta (PTR_LO), y
    dey
    bpl _cap_b
    inx
    cpx #192
    bcc -
    rts

FlipBuffers:
    lda CURR_PAGE
    bne _show_p1
    ; Currently showing P1 -> Show P2
    bit TXTPAGE2
    lda #1
    sta CURR_PAGE
    lda #0
    sta DRAW_PAGE_OFF   ; Back-buffer is now P1 ($00)
    rts
_show_p1:
    ; Currently showing P2 -> Show P1
    bit TXTPAGE1
    lda #0
    sta CURR_PAGE
    lda #$20
    sta DRAW_PAGE_OFF   ; Back-buffer is now P2 ($20)
    rts

FrameSync:
    ldx #12             ; Tuned from 18 to 12 to provide plenty of CPU headroom
_fs_outer:
    ldy #100
_fs_inner:
    dey
    bne _fs_inner
    dex
    bne _fs_outer
    rts

; ===================================================================
; ARENA & HUD DRAWING (COLORFUL & CRISP)
; ===================================================================
DrawArenaBorders:
    ; Left Pillar (Col 1 = solid BLUE $AA)
    ; Right Pillar (Col 36 = solid BLUE $AA)
    ldx #CEILING_Y
_dab_vert:
    txa
    tay
    lda hgr_lo, y
    sta PTR_LO
    lda hgr_hi, y
    clc
    adc DRAW_PAGE_OFF
    sta PTR_HI

    ldy #1
    lda #COLOR_BLUE
    sta (PTR_LO), y

    ldy #36
    lda #COLOR_ORANGE   ; In even column 36, $D5 displays as blue matching odd column 1!
    sta (PTR_LO), y

    inx
    cpx #FLOOR_Y + 1
    bcc _dab_vert

    ; Ceiling bar (Lines 16 and 17, columns 1..36 in Blue $AA)
    ldx #16
_dab_ceil:
    lda hgr_lo, x
    sta PTR_LO
    lda hgr_hi, x
    clc
    adc DRAW_PAGE_OFF
    sta PTR_HI
    ldy #1
    lda #COLOR_BLUE
-   sta (PTR_LO), y
    iny
    cpy #37
    bcc -
    inx
    cpx #18
    bcc _dab_ceil

    ; Floor ground (Lines 174 and 175 in solid Orange $D5, columns 1..36)
    ldx #FLOOR_Y
_dab_floor:
    lda hgr_lo, x
    sta PTR_LO
    lda hgr_hi, x
    clc
    adc DRAW_PAGE_OFF
    sta PTR_HI
    ldy #1
    lda #COLOR_ORANGE
-   sta (PTR_LO), y
    iny
    cpy #37
    bcc -
    inx
    cpx #FLOOR_Y + 2
    bcc _dab_floor

    rts

DrawHUD:
    lda #2
    sta TMP_COL
    lda #182
    sta TMP_Y
    lda #<str_score_lbl
    sta STR_PTR_LO
    lda #>str_score_lbl
    sta STR_PTR_HI
    jsr DrawString

    lda #9
    sta TMP_COL
    jsr PrintScoreDigits

    lda #18
    sta TMP_COL
    lda #<str_stage_lbl
    sta STR_PTR_LO
    lda #>str_stage_lbl
    sta STR_PTR_HI
    jsr DrawString

    lda #28
    sta TMP_COL
    lda #<str_lives_lbl
    sta STR_PTR_LO
    lda #>str_lives_lbl
    sta STR_PTR_HI
    jsr DrawString

    lda #35
    sta TMP_COL
    lda lives
    clc
    adc #'0'
    jsr DrawChar
    rts

UpdateHUDLives:
    pha
    txa
    pha
    tya
    pha

    lda #0
    sta DRAW_PAGE_OFF
    lda #HUD_Y
    sta TMP_Y
    lda #35
    sta TMP_COL
    lda lives
    clc
    adc #'0'
    jsr DrawChar

    lda #$20
    sta DRAW_PAGE_OFF
    lda #HUD_Y
    sta TMP_Y
    lda #35
    sta TMP_COL
    lda lives
    clc
    adc #'0'
    jsr DrawChar

    lda CURR_PAGE
    beq +
    lda #0
    sta DRAW_PAGE_OFF
    jmp _uhl_ret
+   lda #$20
    sta DRAW_PAGE_OFF
_uhl_ret:
    pla
    tay
    pla
    tax
    pla
    rts

UpdateHUDScore:
    pha
    txa
    pha
    tya
    pha

    lda #0
    sta DRAW_PAGE_OFF
    lda #HUD_Y
    sta TMP_Y
    lda #9
    sta TMP_COL
    jsr PrintScoreDigits

    lda #$20
    sta DRAW_PAGE_OFF
    lda #HUD_Y
    sta TMP_Y
    lda #9
    sta TMP_COL
    jsr PrintScoreDigits

    lda CURR_PAGE
    beq +
    lda #0
    sta DRAW_PAGE_OFF
    jmp _uhs_ret
+   lda #$20
    sta DRAW_PAGE_OFF
_uhs_ret:
    pla
    tay
    pla
    tax
    pla
    rts

PrintScoreDigits:
    lda score_hi
    lsr
    lsr
    lsr
    lsr
    clc
    adc #'0'
    jsr DrawChar
    inc TMP_COL
    lda score_hi
    and #$0F
    clc
    adc #'0'
    jsr DrawChar
    inc TMP_COL
    lda score_lo
    lsr
    lsr
    lsr
    lsr
    clc
    adc #'0'
    jsr DrawChar
    inc TMP_COL
    lda score_lo
    and #$0F
    clc
    adc #'0'
    jsr DrawChar
    rts

DrawString:
    ldy #0
-   lda (STR_PTR_LO), y
    beq _ds_done
    sty TEMP_VAL2
    jsr DrawChar
    inc TMP_COL
    ldy TEMP_VAL2
    iny
    bne -
_ds_done:
    rts

DrawChar:
    pha
    sec
    sbc #32             ; ASCII 32 (' ') is index 0
    cmp #59             ; Max index (90 - 32 = 58)
    bcc +
    lda #0              ; Out of range -> blank space
+
    sta PTR2_LO
    lda #0
    sta PTR2_HI
    asl PTR2_LO
    rol PTR2_HI
    asl PTR2_LO
    rol PTR2_HI
    asl PTR2_LO
    rol PTR2_HI

    lda PTR2_LO
    clc
    adc #<font_base_32
    sta PTR2_LO
    lda PTR2_HI
    adc #>font_base_32
    sta PTR2_HI

    ldx #0
_dc_line:
    txa
    clc
    adc TMP_Y
    tay
    lda hgr_lo, y
    sta PTR_LO
    lda hgr_hi, y
    clc
    adc DRAW_PAGE_OFF
    sta PTR_HI

    txa
    tay
    lda (PTR2_LO), y
    ldy TMP_COL
    sta (PTR_LO), y

    inx
    cpx #8
    bcc _dc_line
    pla
    rts

; ===================================================================
; GAMEPLAY MANAGEMENT
; ===================================================================
ResetGame:
    lda #1
    sta game_running
    sta stage_num
    lda #3
    sta lives
    lda #0
    sta score_lo
    sta score_hi
    sta stage_clear_timer
    sta player_hit_timer
    sta player_invinc_timer
    sta fire_held
    sta fire_cooldown

    rts

ClearTilemap:
    lda #0
    ldx #0
-   sta tilemap, x
    sta tilemap + $100, x
    sta tilemap + $200, x
    sta tilemap + $300, x
    inx
    bne -
    rts

GetTileAtPixelXY:
    ; Input: TMP_X, TMP_Y
    ; Output: A = tile ID, TEMP_VAL = col, Y = row
    ldx TMP_X
    lda div7_table, x
    sta TEMP_VAL        ; Col
    lda TMP_Y
    lsr
    lsr
    lsr                 ; Row = Y >> 3
    cmp #24
    bcc +
    lda #0              ; Out of bounds
    rts
+   sta TMP_ROW
    tay
    lda row40_table_lo, y
    clc
    adc #<tilemap
    sta PTR2_LO
    lda row40_table_hi, y
    adc #>tilemap
    sta PTR2_HI
    ldy TEMP_VAL
    lda (PTR2_LO), y
    ldy TMP_ROW         ; Guarantee Y = Row upon return!
    rts

GetTileAtColRowFast:
    ; Input: X = col, Y = row
    ; Output: A = tile ID
    cpy #24
    bcc +
    lda #0
    rts
+   lda row40_table_lo, y
    clc
    adc #<tilemap
    sta PTR2_LO
    lda row40_table_hi, y
    adc #>tilemap
    sta PTR2_HI
    txa
    tay
    lda (PTR2_LO), y
    rts

SetTileAtColRow:
    ; Input: X = col, Y = row, A = tile ID
    sta TEMP_VAL2
    cpy #24
    bcs +
    lda row40_table_lo, y
    clc
    adc #<tilemap
    sta PTR2_LO
    lda row40_table_hi, y
    adc #>tilemap
    sta PTR2_HI
    txa
    tay
    lda TEMP_VAL2
    sta (PTR2_LO), y
+   rts

DrawTileDirect:
    ; Input: col in X, row in Y, tile ID in A
    stx TMP_COL
    sta TEMP_VAL
    tya
    asl
    asl
    asl
    sta TMP_Y

    ldx #0
_dtd_loop:
    txa
    clc
    adc TMP_Y
    tay
    lda hgr_lo, y
    sta PTR_LO
    lda hgr_hi, y
    clc
    adc DRAW_PAGE_OFF
    sta PTR_HI

    lda TEMP_VAL
    bne +
    lda #0
    jmp _dtd_plot
+   cmp #TILE_SOLID
    bne +
    lda tile_solid_gfx, x
    jmp _dtd_plot
+   cmp #TILE_BREAKABLE
    bne +
    lda tile_breakable_gfx, x
    jmp _dtd_plot
+   lda tile_ladder_gfx, x
_dtd_plot:
    ldy TMP_COL
    sta (PTR_LO), y
    inx
    cpx #8
    bcc _dtd_loop
    rts

RestoreTilesInBoundingBox:
    ; Input: TMP_X, TMP_Y (pixels), TEMP_BYTES (width in cols), TEMP_LINES (height in scanlines)
    lda stage_num
    cmp #2
    bcs +
    rts
+
    lda TMP_Y
    lsr
    lsr
    lsr
    sta rect_r1         ; Start row (0..23)

    lda TMP_Y
    clc
    adc TEMP_LINES
    sec
    sbc #1
    lsr
    lsr
    lsr
    cmp #23
    bcc +
    lda #22             ; Max valid tile row before HUD
+   sta rect_r2         ; End row

    ldx TMP_X
    lda div7_table, x
    sta rect_c1         ; Start col
    clc
    adc TEMP_BYTES
    sec
    sbc #1
    cmp #36
    bcc +
    lda #35             ; Max valid col inside arena (Cols 2..35)
+   sta rect_c2         ; End col

    lda rect_r1
_rtbb_row_l:
    sta TMP_ROW
    tay
    lda row40_table_lo, y
    clc
    adc #<tilemap
    sta PTR2_LO
    lda row40_table_hi, y
    adc #>tilemap
    sta PTR2_HI

    lda rect_c1
_rtbb_col_l:
    sta TMP_COL
    tay
    lda (PTR2_LO), y
    beq _rtbb_next_c

    pha
    ldx TMP_COL
    ldy TMP_ROW
    pla
    jsr DrawTileDirect

    ; Re-establish PTR2 (DrawTileDirect modifies PTR2)
    ldy TMP_ROW
    lda row40_table_lo, y
    clc
    adc #<tilemap
    sta PTR2_LO
    lda row40_table_hi, y
    adc #>tilemap
    sta PTR2_HI

_rtbb_next_c:
    inc TMP_COL
    lda TMP_COL
    cmp rect_c2
    bcc _rtbb_col_l
    beq _rtbb_col_l

    inc TMP_ROW
    lda TMP_ROW
    cmp rect_r2
    bcc _rtbb_row_l
    beq _rtbb_row_l
    rts

ShatterTile:
    ; Input: col in X, row in Y
    stx TMP_COL
    sty TMP_ROW

    ; Set tilemap to 0
    lda #0
    jsr SetTileAtColRow

    ; Wipe on Page 1
    lda DRAW_PAGE_OFF
    pha
    lda #0
    sta DRAW_PAGE_OFF
    ldx TMP_COL
    ldy TMP_ROW
    lda #0
    jsr DrawTileDirect

    ; Wipe on Page 2
    lda #$20
    sta DRAW_PAGE_OFF
    ldx TMP_COL
    ldy TMP_ROW
    lda #0
    jsr DrawTileDirect
    pla
    sta DRAW_PAGE_OFF

    ; 100 points
    sed
    lda score_lo
    clc
    adc #$00
    sta score_lo
    lda score_hi
    adc #$01
    sta score_hi
    cld
    jsr UpdateHUDScore
    jsr PlayPopSound
    rts

ApplyStageTiles:
    ldy #0
_ast_rect_l:
    lda (STR_PTR_LO), y
    cmp #$FF
    beq _ast_done
    sta rect_c1
    iny
    lda (STR_PTR_LO), y
    sta rect_c2
    iny
    lda (STR_PTR_LO), y
    sta rect_r1
    iny
    lda (STR_PTR_LO), y
    sta rect_r2
    iny
    lda (STR_PTR_LO), y
    sta rect_type
    iny
    tya
    pha

    lda rect_r1
    sta TMP_ROW
_ast_row_l:
    lda rect_c1
    sta TMP_COL
_ast_col_l:
    ldx TMP_COL
    ldy TMP_ROW
    lda rect_type
    jsr SetTileAtColRow

    inc TMP_COL
    lda TMP_COL
    cmp rect_c2
    bcc _ast_col_l
    beq _ast_col_l

    inc TMP_ROW
    lda TMP_ROW
    cmp rect_r2
    bcc _ast_row_l
    beq _ast_row_l

    pla
    tay
    jmp _ast_rect_l
_ast_done:
    rts

DrawAllStageTiles:
    ldy #3
_dast_r:
    sty TMP_ROW
    ldx #2
_dast_c:
    stx TMP_COL
    ldy TMP_ROW
    jsr GetTileAtColRowFast
    beq +
    ldx TMP_COL
    ldy TMP_ROW
    jsr DrawTileDirect
+   ldx TMP_COL
    inx
    cpx #36
    bcc _dast_c
    ldy TMP_ROW
    iny
    cpy #22
    bcc _dast_r
    rts

LoadStage:
    ldx #0
-   lda #0
    sta ball_active, x
    sta p1_ball_drawn, x
    sta p2_ball_drawn, x
    inx
    cpx #MAX_BALLS
    bcc -

    lda #0
    sta wire_active
    sta p1_wire_drawn
    sta p2_wire_drawn
    sta player_shoot_timer
    sta player_anim
    sta player_on_ladder
    sta player_invinc_timer
    sta fire_held
    sta fire_cooldown

    lda #PLAYER_START_X
    sta player_x
    lda #154
    sta player_y
    sta p1_player_y
    sta p2_player_y

    jsr ClearTilemap

    lda stage_num
    cmp #3
    bne +
    jmp _ls_stage3
+   cmp #2
    beq _ls_stage2
    cmp #1
    beq _ls_stage1
    lda #1
    sta stage_num
_ls_stage1:
    lda #<Stage1_Tiles
    sta STR_PTR_LO
    lda #>Stage1_Tiles
    sta STR_PTR_HI
    jsr ApplyStageTiles

    lda #1
    sta ball_active + 0
    lda #3              ; Huge ball
    sta ball_size + 0
    lda #120
    sta ball_x + 0
    lda #40
    sta ball_y_int + 0
    lda #0
    sta ball_y_frac + 0
    sta ball_vy_int + 0
    sta ball_vy_frac + 0
    lda #1
    sta ball_vx + 0

    lda #1
    sta active_balls_count
    jmp _ls_draw_bg

_ls_stage2:
    lda #<Stage2_Tiles
    sta STR_PTR_LO
    lda #>Stage2_Tiles
    sta STR_PTR_HI
    jsr ApplyStageTiles

    lda #1
    sta ball_active + 0
    lda #2              ; Medium ball 1
    sta ball_size + 0
    lda #60
    sta ball_x + 0
    lda #40
    sta ball_y_int + 0
    lda #0
    sta ball_y_frac + 0
    sta ball_vy_int + 0
    sta ball_vy_frac + 0
    lda #1
    sta ball_vx + 0

    lda #1
    sta ball_active + 1
    lda #2              ; Medium ball 2
    sta ball_size + 1
    lda #190
    sta ball_x + 1
    lda #40
    sta ball_y_int + 1
    lda #0
    sta ball_y_frac + 1
    sta ball_vy_int + 1
    sta ball_vy_frac + 1
    lda #$FF
    sta ball_vx + 1

    lda #2
    sta active_balls_count
    jmp _ls_draw_bg

_ls_stage3:
    lda #<Stage3_Tiles
    sta STR_PTR_LO
    lda #>Stage3_Tiles
    sta STR_PTR_HI
    jsr ApplyStageTiles

    lda #1
    sta ball_active + 0
    lda #2              ; Medium ball 1
    sta ball_size + 0
    lda #70
    sta ball_x + 0
    lda #40
    sta ball_y_int + 0
    lda #0
    sta ball_y_frac + 0
    sta ball_vy_int + 0
    sta ball_vy_frac + 0
    lda #1
    sta ball_vx + 0

    lda #1
    sta ball_active + 1
    lda #2              ; Medium ball 2
    sta ball_size + 1
    lda #180
    sta ball_x + 1
    lda #40
    sta ball_y_int + 1
    lda #0
    sta ball_y_frac + 1
    sta ball_vy_int + 1
    sta ball_vy_frac + 1
    lda #$FF
    sta ball_vx + 1

    lda #2
    sta active_balls_count

_ls_draw_bg:
    lda stage_num
    clc
    adc #'0'
    sta str_stage_lbl + 7

    lda #0
    sta DRAW_PAGE_OFF
    jsr ClearActivePage
    jsr DrawArenaBorders
    jsr DrawHUD
    jsr DrawAllStageTiles

    lda #$20
    sta DRAW_PAGE_OFF
    jsr ClearActivePage
    jsr DrawArenaBorders
    jsr DrawHUD
    jsr DrawAllStageTiles

    lda CURR_PAGE
    beq +
    lda #0
    sta DRAW_PAGE_OFF
    rts
+   lda #$20
    sta DRAW_PAGE_OFF
    rts

RespawnPlayer:
    lda lives
    beq _game_over
    dec lives
    jsr UpdateHUDLives

    lda #PLAYER_START_X
    sta player_x
    lda #154
    sta player_y
    lda #0
    sta player_anim
    sta player_on_ladder
    sta player_shoot_timer
    sta wire_active
    lda #90
    sta player_invinc_timer
    rts
_game_over:
    lda #0
    sta game_running
    rts

; ===================================================================
; CONTROLS & INPUT (KEYBOARD + JOYSTICK SEAMLESS SUPPORT)
; ===================================================================
ReadControls:
    lda #0
    sta player_dir
    sta player_vdir     ; 0=idle, 1=up, 2=down
    sta fire_requested

    lda fire_cooldown
    beq +
    dec fire_cooldown
+

    ; 1. Check Joystick Fire Buttons
    lda BTN0
    bmi _rc_fire_joy
    lda BTN1
    bmi _rc_fire_joy
    jmp _rc_read_joy

_rc_fire_joy:
    inc fire_requested

_rc_read_joy:
    ; Read Joystick Analog X Axis (Paddle 0)
    ldx #0
    jsr PREAD           ; Returns Y = 0..255 (Center ~127)
    cpy #90             ; GAUCHE (LEFT): Y < 90
    bcc _rc_joy_left
    cpy #160            ; DROITE (RIGHT): Y >= 160 (effortless right!)
    bcs _rc_joy_right
    jmp _rc_check_joy_y

_rc_joy_left:
    lda #1
    sta player_dir
    jmp _rc_check_joy_y

_rc_joy_right:
    lda #2
    sta player_dir

_rc_check_joy_y:
    ; Read Joystick Analog Y Axis (Paddle 1)
    ldx #1
    jsr PREAD           ; Returns Y = 0..255 (Center ~127)
    cpy #90             ; HAUT (UP): Y < 90
    bcc _rc_joy_up
    cpy #160            ; BAS (DOWN): Y >= 160
    bcs _rc_joy_down
    jmp _rc_check_kbd

_rc_joy_up:
    lda #1
    sta player_vdir
    jmp _rc_check_kbd

_rc_joy_down:
    lda #2
    sta player_vdir

_rc_check_kbd:
    lda KBD
    bmi +
    jmp _rc_eval_fire
+   bit KBDSTRB         ; Clear strobe

    cmp #$9B            ; ESC -> Quit
    bne +
    lda #0
    sta game_running
    rts
+
    ; Stage warp hotkeys ('1', '2', '3')
    cmp #$B1            ; '1' key
    bne +
    lda #1
    sta stage_num
    jsr LoadStage
    jmp _rc_eval_fire
+   cmp #$B2            ; '2' key
    bne +
    lda #2
    sta stage_num
    jsr LoadStage
    jmp _rc_eval_fire
+   cmp #$B3            ; '3' key
    bne +
    lda #3
    sta stage_num
    jsr LoadStage
    jmp _rc_eval_fire
+
    ; Left keys
    cmp #$88            ; Left Arrow
    beq _rc_kbd_left
    cmp #$C1            ; 'A'
    beq _rc_kbd_left
    cmp #$E1            ; 'a'
    beq _rc_kbd_left
    cmp #$CA            ; 'J'
    beq _rc_kbd_left
    cmp #$EA            ; 'j'
    beq _rc_kbd_left

    ; Right keys
    cmp #$95            ; Right Arrow
    beq _rc_kbd_right
    cmp #$C4            ; 'D'
    beq _rc_kbd_right
    cmp #$E4            ; 'd'
    beq _rc_kbd_right
    cmp #$CC            ; 'L'
    beq _rc_kbd_right
    cmp #$EC            ; 'l'
    beq _rc_kbd_right

    ; Up keys
    cmp #$8B            ; Up Arrow
    beq _rc_kbd_up
    cmp #$D7            ; 'W'
    beq _rc_kbd_up
    cmp #$F7            ; 'w'
    beq _rc_kbd_up
    cmp #$DA            ; 'Z'
    beq _rc_kbd_up
    cmp #$FA            ; 'z'
    beq _rc_kbd_up
    cmp #$C9            ; 'I'
    beq _rc_kbd_up
    cmp #$E9            ; 'i'
    beq _rc_kbd_up

    ; Down keys
    cmp #$8A            ; Down Arrow
    beq _rc_kbd_down
    cmp #$D3            ; 'S'
    beq _rc_kbd_down
    cmp #$F3            ; 's'
    beq _rc_kbd_down
    cmp #$CB            ; 'K'
    beq _rc_kbd_down
    cmp #$EB            ; 'k'
    beq _rc_kbd_down

    ; Fire keys
    cmp #$A0            ; Space
    beq _rc_kbd_fire
    cmp #$8D            ; Return
    beq _rc_kbd_fire
    jmp _rc_eval_fire

_rc_kbd_left:
    lda #1
    sta player_dir
    jmp _rc_eval_fire

_rc_kbd_right:
    lda #2
    sta player_dir
    jmp _rc_eval_fire

_rc_kbd_up:
    lda #1
    sta player_vdir
    jmp _rc_eval_fire

_rc_kbd_down:
    lda #2
    sta player_vdir
    jmp _rc_eval_fire

_rc_kbd_fire:
    inc fire_requested

_rc_eval_fire:
    lda fire_requested
    beq _rc_fire_released

    lda fire_held
    bne _rc_done

    lda #1
    sta fire_held

    lda fire_cooldown
    bne _rc_done

    jsr TriggerFire
    rts

_rc_fire_released:
    lda #0
    sta fire_held
_rc_done:
    rts

TriggerFire:
    lda wire_active
    bne _tf_done

    lda #1
    sta wire_active
    lda player_x
    clc
    adc #4              ; Wire launches from center
    sta wire_x
    lda player_y
    sec
    sbc #2
    sta wire_y
    lda player_y
    clc
    adc #PLAYER_H
    sta wire_base_y

    lda #6              ; Shoot animation pose timer
    sta player_shoot_timer
    lda #3              ; Shoot sprite frame
    sta player_anim

    jsr PlayShootSound
_tf_done:
    rts

; ===================================================================
; ENTITY UPDATES
; ===================================================================
UpdatePlayer:
    lda player_invinc_timer
    beq +
    dec player_invinc_timer
+
    lda player_shoot_timer
    beq _up_check_state
    dec player_shoot_timer
    bne _up_no_reset_anim
    lda #0
    sta player_anim
_up_no_reset_anim:

_up_check_state:
    lda player_on_ladder
    bne +
    jmp _up_not_on_ladder
+

    ; ---------------------------------------------------------------
    ; BUSTER IS ON A LADDER
    ; ---------------------------------------------------------------
    lda player_dir
    beq _uol_vertical

    ; Left or Right pressed while on ladder: check if we can step off
    lda player_y
    cmp #154
    bcc _uol_check_plat_step
    ; Reached floor level, dismount to floor
    lda #0
    sta player_on_ladder
    jmp _up_not_on_ladder

_uol_check_plat_step:
    lda player_dir
    cmp #1              ; Left
    bne _uol_step_right
    ; Left foot check
    lda player_x
    sec
    sbc #2
    sta TMP_X
    lda player_y
    clc
    adc #PLAYER_H + 1
    sta TMP_Y
    jsr GetTileAtPixelXY
    cmp #TILE_SOLID
    beq _uol_do_dismount
    cmp #TILE_BREAKABLE
    beq _uol_do_dismount
    jmp _uol_vertical

_uol_step_right:
    ; Right foot check
    lda player_x
    clc
    adc #PLAYER_W + 2
    sta TMP_X
    lda player_y
    clc
    adc #PLAYER_H + 1
    sta TMP_Y
    jsr GetTileAtPixelXY
    cmp #TILE_SOLID
    beq _uol_do_dismount
    cmp #TILE_BREAKABLE
    beq _uol_do_dismount
    jmp _uol_vertical

_uol_do_dismount:
    lda #0
    sta player_on_ladder
    jmp _up_not_on_ladder

_uol_vertical:
    lda player_vdir
    beq _uol_idle

    cmp #1              ; UP
    bne _uol_down

    ; Moving UP on ladder
    lda player_y
    sec
    sbc #PLAYER_SPEED
    cmp #CEILING_Y + 10
    bcs +
    lda #CEILING_Y + 10
+   sta player_y

    jsr CycleClimbAnim

    ; Check if reached top of ladder (check waist)
    lda player_x
    clc
    adc #7
    sta TMP_X
    lda player_y
    clc
    adc #12
    sta TMP_Y
    jsr GetTileAtPixelXY
    cmp #TILE_LADDER
    beq _uol_done

    ; Reached platform surface!
    lda player_y
    clc
    adc #PLAYER_H
    lsr
    lsr
    lsr
    asl
    asl
    asl
    sec
    sbc #PLAYER_H
    sta player_y
    lda #0
    sta player_on_ladder
    sta player_anim
    rts

_uol_down:
    ; Moving DOWN on ladder
    lda player_y
    clc
    adc #PLAYER_SPEED
    cmp #154
    bcc +
    ; Reached floor
    lda #154
    sta player_y
    lda #0
    sta player_on_ladder
    sta player_anim
    rts
+   sta player_y
    jsr CycleClimbAnim
    rts

_uol_idle:
    lda player_shoot_timer
    bne _uol_done
    lda player_anim
    cmp #5
    beq _uol_done
    cmp #6
    beq _uol_done
    lda #5
    sta player_anim
_uol_done:
    rts

    ; ---------------------------------------------------------------
    ; BUSTER IS WALKING / ON SOLID GROUND / ELEVATED PLATFORM
    ; ---------------------------------------------------------------
_up_not_on_ladder:
    lda player_vdir
    cmp #1              ; UP pressed?
    beq _up_try_up_ladder
    cmp #2              ; DOWN pressed?
    beq _up_try_down_ladder
    jmp _up_walk        ; No vertical input -> walk / idle

_up_try_up_ladder:
    lda player_x
    clc
    adc #7
    sta TMP_X
    lda player_y
    clc
    adc #10
    sta TMP_Y
    jsr GetTileAtPixelXY
    cmp #TILE_LADDER
    beq +
    jmp _up_walk        ; No ladder at waist -> walk / idle
+
    ; Calculate Target X for ladder center: (Col * 7) - 3
    lda TEMP_VAL        ; Col
    asl
    asl
    asl
    sec
    sbc TEMP_VAL        ; Col * 7
    sec
    sbc #3              ; Target X
    sta TEMP_VAL2       ; Save Target X

    ; Natural alignment check: |player_x - Target X| <= 8
    sec
    sbc player_x        ; Target X - player_x
    bpl +
    eor #$FF            ; Absolute value
    clc
    adc #1
+   cmp #9              ; Within 8 pixels of ladder center
    bcc +
    jmp _up_walk        ; Too far from ladder -> walk / idle
+
    ; Mount ladder going UP!
    lda #1
    sta player_on_ladder
    lda TEMP_VAL2
    sta player_x        ; Snap cleanly to ladder center
    lda player_y
    sec
    sbc #PLAYER_SPEED
    sta player_y
    lda #5
    sta player_anim
    rts

_up_try_down_ladder:
    lda player_x
    clc
    adc #7
    sta TMP_X
    lda player_y
    clc
    adc #PLAYER_H + 2
    sta TMP_Y
    jsr GetTileAtPixelXY
    cmp #TILE_LADDER
    beq +
    jmp _up_walk
+
    ; Calculate Target X for ladder center: (Col * 7) - 3
    lda TEMP_VAL        ; Col
    asl
    asl
    asl
    sec
    sbc TEMP_VAL        ; Col * 7
    sec
    sbc #3              ; Target X
    sta TEMP_VAL2       ; Save Target X

    ; Natural alignment check: |player_x - Target X| <= 8
    sec
    sbc player_x
    bpl +
    eor #$FF
    clc
    adc #1
+   cmp #9
    bcc +
    jmp _up_walk
+
    ; Mount ladder going DOWN!
    lda #1
    sta player_on_ladder
    lda TEMP_VAL2
    sta player_x
    lda player_y
    clc
    adc #PLAYER_SPEED
    sta player_y
    lda #5
    sta player_anim
    rts

_up_walk:
    lda player_dir
    beq _up_idle

    cmp #1              ; Left
    bne _up_try_right
    lda player_x
    sec
    sbc #PLAYER_SPEED
    cmp #LEFT_WALL_X
    bcs +
    lda #LEFT_WALL_X
+   sta player_x
    jmp _up_cycle_walk

_up_try_right:
    lda player_x
    clc
    adc #PLAYER_SPEED
    cmp #RIGHT_WALL_X - PLAYER_W
    bcc +
    lda #RIGHT_WALL_X - PLAYER_W
+   sta player_x

_up_cycle_walk:
    lda player_shoot_timer
    bne _up_check_fall
    inc player_walk_phase
    lda player_walk_phase
    lsr
    and #1
    clc
    adc #1              ; Cycle walk1 (1) and walk2 (2)
    sta player_anim
    jmp _up_check_fall

_up_idle:
    lda player_shoot_timer
    bne _up_check_fall
    lda #0
    sta player_anim

_up_check_fall:
    lda player_y
    cmp #154            ; On floor?
    bcs _up_on_floor

    ; Check support beneath feet
    lda player_x
    clc
    adc #2
    sta TMP_X
    lda player_y
    clc
    adc #PLAYER_H
    sta TMP_Y
    jsr GetTileAtPixelXY
    cmp #TILE_SOLID
    beq _up_supported
    cmp #TILE_BREAKABLE
    beq _up_supported
    cmp #TILE_LADDER
    beq _up_supported

    lda player_x
    clc
    adc #11
    sta TMP_X
    lda player_y
    clc
    adc #PLAYER_H
    sta TMP_Y
    jsr GetTileAtPixelXY
    cmp #TILE_SOLID
    beq _up_supported
    cmp #TILE_BREAKABLE
    beq _up_supported
    cmp #TILE_LADDER
    beq _up_supported

    ; No support: fall down!
    lda player_y
    clc
    adc #3
    cmp #154
    bcc +
    lda #154
+   sta player_y
    rts

_up_on_floor:
    lda #154
    sta player_y
_up_supported:
    rts

CycleClimbAnim:
    inc player_climb_anim_timer
    lda player_climb_anim_timer
    lsr
    lsr
    and #1
    clc
    adc #5              ; 5 (climb1) or 6 (climb2)
    sta player_anim
    rts

UpdateWire:
    lda wire_active
    beq _uw_done

    lda wire_y
    sec
    sbc #WIRE_SPEED
    cmp #CEILING_Y
    bcs +
    lda #0
    sta wire_active
    lda #4
    sta fire_cooldown
    rts
+   sta wire_y

    ; Check wire tip vs tilemap
    lda wire_x
    clc
    adc #3
    sta TMP_X
    lda wire_y
    sta TMP_Y
    jsr CheckWireTileCollision
_uw_done:
    rts

CheckWireTileCollision:
    jsr GetTileAtPixelXY
    cmp #TILE_SOLID
    bne +
    ; Solid platform hit from below!
    lda #0
    sta wire_active
    lda #4
    sta fire_cooldown
    jsr PlayBounceSound
    rts
+   cmp #TILE_BREAKABLE
    bne _cwt_done
    ; Breakable brick shattered!
    lda #0
    sta wire_active
    lda #4
    sta fire_cooldown
    ldx TEMP_VAL
    jsr ShatterTile
_cwt_done:
    rts

UpdateBalls:
    ldx #0
_ub_loop:
    stx BALL_IDX
    lda ball_active, x
    bne +
    jmp _ub_next
+
    ; Horizontal movement
    lda ball_x, x
    clc
    adc ball_vx, x
    sta ball_x, x

    ldy ball_size, x
    lda ball_widths, y
    sta TEMP_VAL        ; Width

    lda ball_x, x
    cmp #LEFT_WALL_X
    bcs +
    lda #LEFT_WALL_X
    sta ball_x, x
    lda #1
    sta ball_vx, x
    jmp _ub_vert
+
    lda #RIGHT_WALL_X
    sec
    sbc TEMP_VAL
    cmp ball_x, x
    bcs _ub_vert
    sta ball_x, x
    lda #$FF            ; -1
    sta ball_vx, x

_ub_vert:
    ; Vertical movement with gravity
    lda ball_vy_frac, x
    clc
    adc #GRAVITY_FRAC
    sta ball_vy_frac, x
    lda ball_vy_int, x
    adc #0
    sta ball_vy_int, x

    lda ball_y_frac, x
    clc
    adc ball_vy_frac, x
    sta ball_y_frac, x
    lda ball_y_int, x
    adc ball_vy_int, x
    sta ball_y_int, x

    ; Floor bounce
    ldy ball_size, x
    lda ball_heights, y
    sta TEMP_VAL
    lda #FLOOR_Y
    sec
    sbc TEMP_VAL
    cmp ball_y_int, x
    bcs _ub_check_plat

    sta ball_y_int, x
    lda #0
    sta ball_y_frac, x
    ldy ball_size, x
    lda ball_bounce_vy, y
    sta ball_vy_int, x
    lda #0
    sta ball_vy_frac, x
    jsr PlayBounceSound
    jmp _ub_next

_ub_check_plat:
    ; Check platform bounce if falling downwards
    lda ball_vy_int, x
    bpl +
    jmp _ub_check_ceil  ; Moving UP -> cannot bounce on top of platform
+
    ; Ball bottom scanline:
    ldy ball_size, x
    lda ball_heights, y
    sta TEMP_VAL2       ; Preserve ball_height in TEMP_VAL2
    lda ball_y_int, x
    clc
    adc TEMP_VAL2       ; Y_bottom
    sta TMP_Y

    ; Check if ball crossed into or past a platform row
    lda TMP_Y
    lsr
    lsr
    lsr
    sta TMP_ROW
    cmp #22
    bcc +
    jmp _ub_check_ceil
+
    ; Anti-tunneling: If ball stepped into Row 13 in this frame,
    ; check if previous bottom was <= 99 (above/at Row 12)
    cmp #13
    bne _ub_chk_ptiles
    lda TMP_Y
    sec
    sbc ball_vy_int, x
    cmp #100
    bcc +
    jmp _ub_check_ceil
+   lda #12
    sta TMP_ROW

_ub_chk_ptiles:
    ; 1. Check left side of ball (ball_x + 3)
    lda ball_x, x
    clc
    adc #3
    tax
    lda div7_table, x
    tax
    ldy TMP_ROW
    jsr GetTileAtColRowFast
    jsr _ub_eval_tile
    beq _ub_do_plat_bounce

    ; 2. Check center of ball (ball_x + width/2)
    ldx BALL_IDX
    ldy ball_size, x
    lda ball_widths, y
    lsr
    clc
    adc ball_x, x
    tax
    lda div7_table, x
    tax
    ldy TMP_ROW
    jsr GetTileAtColRowFast
    jsr _ub_eval_tile
    beq _ub_do_plat_bounce

    ; 3. Check right side of ball (ball_x + width - 4)
    ldx BALL_IDX
    ldy ball_size, x
    lda ball_widths, y
    sec
    sbc #4
    clc
    adc ball_x, x
    tax
    lda div7_table, x
    tax
    ldy TMP_ROW
    jsr GetTileAtColRowFast
    jsr _ub_eval_tile
    beq _ub_do_plat_bounce

    jmp _ub_check_ceil

_ub_eval_tile:
    ; Input: A = tile ID. Returns Z=1 if bounce surface, Z=0 if no bounce
    cmp #TILE_SOLID
    beq _ub_tile_hit
    cmp #TILE_BREAKABLE
    beq _ub_tile_hit
    cmp #TILE_LADDER
    bne _ub_tile_miss
    ; Ladder only acts as platform surface at row 12!
    lda TMP_ROW
    cmp #12
    beq _ub_tile_hit
_ub_tile_miss:
    lda #1              ; Z = 0 (no hit)
    rts
_ub_tile_hit:
    lda #0              ; Z = 1 (hit!)
    rts

_ub_do_plat_bounce:
    ldx BALL_IDX
    lda TMP_ROW
    asl
    asl
    asl
    sec
    sbc TEMP_VAL2       ; (TMP_ROW * 8) - ball_height
    sta ball_y_int, x
    lda #0
    sta ball_y_frac, x
    sta ball_vy_frac, x
    ldy ball_size, x
    lda ball_bounce_vy, y
    sta ball_vy_int, x
    jsr PlayBounceSound
    jmp _ub_next

_ub_check_ceil:
    ldx BALL_IDX        ; Strictly ensure X is BALL_IDX
    lda ball_y_int, x
    cmp #CEILING_Y
    bcs _ub_next
    lda #CEILING_Y
    sta ball_y_int, x
    lda #0
    sta ball_vy_int, x

_ub_next:
    ldx BALL_IDX
    inx
    cpx #MAX_BALLS
    beq +
    jmp _ub_loop
+   rts

; ===================================================================
; COLLISION DETECTION
; ===================================================================
CheckCollisions:
    ; 1. Check Wire vs Balls
    lda wire_active
    beq _cc_check_player

    ldx #0
_cc_wire_loop:
    stx BALL_IDX
    lda ball_active, x
    bne +
    jmp _cc_next_wb
+
    ldy ball_size, x
    lda ball_widths, y
    sta TEMP_VAL

    ; Horizontal overlap:
    lda wire_x
    clc
    adc #6              ; Rightmost edge of 7-pixel tip
    cmp ball_x, x
    bcc _cc_next_wb     ; wire right < ball left -> miss

    lda ball_x, x
    clc
    adc TEMP_VAL        ; ball right edge
    cmp wire_x
    bcc _cc_next_wb     ; ball right < wire left -> miss

    ; Vertical overlap:
    lda ball_heights, y
    sta TEMP_VAL2

    lda ball_y_int, x
    clc
    adc TEMP_VAL2       ; ball bottom
    cmp wire_y
    bcc _cc_next_wb     ; ball bottom < wire top -> miss

    lda ball_y_int, x   ; ball top
    cmp wire_base_y
    bcs _cc_next_wb     ; ball top >= wire base (floor) -> miss

    ; Hit confirmed!
    lda #0
    sta wire_active
    lda #8              ; Reload cooldown to prevent instant multi-pop
    sta fire_cooldown

    ldx BALL_IDX
    jsr PopBubble
    jmp _cc_check_player

_cc_next_wb:
    ldx BALL_IDX
    inx
    cpx #MAX_BALLS
    bcc _cc_wire_loop

_cc_check_player:
    ; 2. Check Player vs Balls
    lda player_invinc_timer
    bne _cc_skip_player ; Invincible! Ignore balls!

    ldx #0
_cc_pl_loop:
    stx BALL_IDX
    lda ball_active, x
    bne +
    jmp _cc_next_pb
+
    ldy ball_size, x
    lda ball_widths, y
    sta TEMP_VAL
    lda ball_heights, y
    sta TEMP_VAL2

    lda player_x
    clc
    adc #PLAYER_W
    cmp ball_x, x
    bcc _cc_next_pb

    lda ball_x, x
    clc
    adc TEMP_VAL
    cmp player_x
    bcc _cc_next_pb

    lda player_y
    clc
    adc #PLAYER_H
    cmp ball_y_int, x
    bcc _cc_next_pb

    lda ball_y_int, x
    clc
    adc TEMP_VAL2
    cmp player_y
    bcc _cc_next_pb

    ; Player hit!
    jsr PlayDeathSound
    lda #40
    sta player_hit_timer
    lda #4              ; Hit frame
    sta player_anim
    rts

_cc_next_pb:
    ldx BALL_IDX
    inx
    cpx #MAX_BALLS
    bcc _cc_pl_loop
_cc_skip_player:
    rts

; ===================================================================
; BUBBLE SPLITTING LOGIC
; ===================================================================
PopBubble:
    ; Popped ball slot index is in BALL_IDX
    jsr PlayPopSound

    sed
    lda score_lo
    clc
    adc #$50
    sta score_lo
    lda score_hi
    adc #0
    sta score_hi
    cld

    jsr UpdateHUDScore

    ldx BALL_IDX
    ldy ball_size, x
    cpy #0
    bne _pb_split

    ; Size 0 -> Disappears
    lda #0
    sta ball_active, x
    dec active_balls_count
    bne _pb_done

    lda #60
    sta stage_clear_timer
_pb_done:
    rts

_pb_split:
    ldx BALL_IDX
    dey
    tya
    sta ball_size, x

    ; First child (parent slot X): moves left (-1)
    lda #$FF
    sta ball_vx, x
    lda ball_pop_vy, y
    sta ball_vy_int, x
    lda #0
    sta ball_vy_frac, x

    ; Find free slot for second child
    ldy #0
-   lda ball_active, y
    beq _pb_found_slot
    iny
    cpy #MAX_BALLS
    bcc -
    rts

_pb_found_slot:
    ; Y is the new free slot index
    ldx BALL_IDX        ; Strictly reload parent slot index X

    lda #1
    sta ball_active, y
    lda ball_size, x
    sta ball_size, y
    lda ball_x, x
    sta ball_x, y
    lda ball_y_int, x
    sta ball_y_int, y
    lda #0
    sta ball_y_frac, y
    sta ball_vy_frac, y
    lda #1
    sta ball_vx, y

    lda ball_size, y    ; New size (0..2)
    tax                 ; Index into ball_pop_vy
    lda ball_pop_vy, x
    sta ball_vy_int, y

    ; Clear drawn trackers on both pages for newly spawned child
    lda #0
    sta p1_ball_drawn, y
    sta p2_ball_drawn, y

    inc active_balls_count
    rts

; ===================================================================
; GRAPHICS RENDERING (PER-PAGE SYMMETRICAL DIRTY RECTANGLES)
; ===================================================================
RenderFrame:
    lda DRAW_PAGE_OFF
    beq _rf_page1
    jmp _rf_page2
_rf_page1:

    ; ===============================================================
    ; RENDERING ON PAGE 1 ($00)
    ; ===============================================================
    ; 1. Erase Page 1 previous objects
    lda p1_player_drawn
    beq +
    lda p1_player_x
    sta TMP_X
    lda p1_player_y
    sta TMP_Y
    jsr ErasePlayerSprite
    lda #0
    sta p1_player_drawn
+
    lda p1_wire_drawn
    beq +
    lda p1_wire_x
    sta TMP_X
    lda p1_wire_y
    sta TMP_Y
    jsr EraseWireDirect
    lda #0
    sta p1_wire_drawn
+
    ldx #0
_p1_eb_loop:
    stx BALL_IDX
    lda p1_ball_drawn, x
    beq _p1_eb_skip
    lda p1_ball_x, x
    sta TMP_X
    lda p1_ball_y, x
    sta TMP_Y
    lda p1_ball_size, x
    jsr EraseBallDirect
    ldx BALL_IDX
    lda #0
    sta p1_ball_drawn, x
_p1_eb_skip:
    ldx BALL_IDX
    inx
    cpx #MAX_BALLS
    bcc _p1_eb_loop

    ; 2. Draw current objects on Page 1
    lda wire_active
    beq +
    jsr DrawWire
    lda #1
    sta p1_wire_drawn
    lda wire_x
    sta p1_wire_x
    lda wire_y
    sta p1_wire_y
+
    lda player_invinc_timer
    beq _p1_draw_p
    and #4
    bne _p1_skip_p
_p1_draw_p:
    jsr DrawPlayer
    lda #1
    sta p1_player_drawn
    lda player_x
    sta p1_player_x
    lda player_y
    sta p1_player_y
    lda player_anim
    sta p1_player_anim
_p1_skip_p:

    ldx #0
_p1_db_loop:
    stx BALL_IDX
    lda ball_active, x
    beq _p1_db_skip
    jsr DrawSingleBall
    ldx BALL_IDX
    lda #1
    sta p1_ball_drawn, x
    lda ball_size, x
    sta p1_ball_size, x
    lda ball_x, x
    sta p1_ball_x, x
    lda ball_y_int, x
    sta p1_ball_y, x
_p1_db_skip:
    ldx BALL_IDX
    inx
    cpx #MAX_BALLS
    bcc _p1_db_loop
    rts

_rf_page2:
    ; ===============================================================
    ; RENDERING ON PAGE 2 ($20) - EXACT SYMMETRICAL CLEAN ERASING
    ; ===============================================================
    lda p2_player_drawn
    beq +
    lda p2_player_x
    sta TMP_X
    lda p2_player_y
    sta TMP_Y
    jsr ErasePlayerSprite
    lda #0
    sta p2_player_drawn
+
    lda p2_wire_drawn
    beq +
    lda p2_wire_x
    sta TMP_X
    lda p2_wire_y
    sta TMP_Y
    jsr EraseWireDirect
    lda #0
    sta p2_wire_drawn
+
    ldx #0
_p2_eb_loop:
    stx BALL_IDX
    lda p2_ball_drawn, x
    beq _p2_eb_skip
    lda p2_ball_x, x
    sta TMP_X
    lda p2_ball_y, x
    sta TMP_Y
    lda p2_ball_size, x
    jsr EraseBallDirect
    ldx BALL_IDX
    lda #0
    sta p2_ball_drawn, x
_p2_eb_skip:
    ldx BALL_IDX
    inx
    cpx #MAX_BALLS
    bcc _p2_eb_loop

    ; 2. Draw current objects on Page 2
    lda wire_active
    beq +
    jsr DrawWire
    lda #1
    sta p2_wire_drawn
    lda wire_x
    sta p2_wire_x
    lda wire_y
    sta p2_wire_y
+
    lda player_invinc_timer
    beq _p2_draw_p
    and #4
    bne _p2_skip_p
_p2_draw_p:
    jsr DrawPlayer
    lda #1
    sta p2_player_drawn
    lda player_x
    sta p2_player_x
    lda player_y
    sta p2_player_y
    lda player_anim
    sta p2_player_anim
_p2_skip_p:

    ldx #0
_p2_db_loop:
    stx BALL_IDX
    lda ball_active, x
    beq _p2_db_skip
    jsr DrawSingleBall
    ldx BALL_IDX
    lda #1
    sta p2_ball_drawn, x
    lda ball_size, x
    sta p2_ball_size, x
    lda ball_x, x
    sta p2_ball_x, x
    lda ball_y_int, x
    sta p2_ball_y, x
_p2_db_skip:
    ldx BALL_IDX
    inx
    cpx #MAX_BALLS
    bcc _p2_db_loop
    rts

; ===================================================================
; SPRITE RENDERING PRIMITIVES (BUSTER 14x20)
; ===================================================================
DrawPlayer:
    lda player_x
    sta TMP_X
    lda player_y
    sta TMP_Y
    lda player_anim
    cmp #1
    beq _dp_w1
    cmp #2
    beq _dp_w2
    cmp #3
    beq _dp_sh
    cmp #4
    beq _dp_hit
    cmp #5
    beq _dp_climb1
    cmp #6
    beq _dp_climb2
    lda #<spr_player_stand
    sta SRC_LO
    lda #>spr_player_stand
    sta SRC_HI
    jmp _dp_blit
_dp_w1:
    lda #<spr_player_walk1
    sta SRC_LO
    lda #>spr_player_walk1
    sta SRC_HI
    jmp _dp_blit
_dp_w2:
    lda #<spr_player_walk2
    sta SRC_LO
    lda #>spr_player_walk2
    sta SRC_HI
    jmp _dp_blit
_dp_sh:
    lda #<spr_player_shoot
    sta SRC_LO
    lda #>spr_player_shoot
    sta SRC_HI
    jmp _dp_blit
_dp_hit:
    lda #<spr_player_hit
    sta SRC_LO
    lda #>spr_player_hit
    sta SRC_HI
    jmp _dp_blit
_dp_climb1:
    lda #<spr_player_climb1
    sta SRC_LO
    lda #>spr_player_climb1
    sta SRC_HI
    jmp _dp_blit
_dp_climb2:
    lda #<spr_player_climb2
    sta SRC_LO
    lda #>spr_player_climb2
    sta SRC_HI

_dp_blit:
    ldx TMP_X
    lda div7_table, x
    sta TMP_COL
    lda mod7_table, x
    tax
    lda shift_player_offset_lo, x
    clc
    adc SRC_LO
    sta PTR2_LO
    lda shift_player_offset_hi, x
    adc SRC_HI
    sta PTR2_HI

    ldx #0
_dp_l:
    txa
    clc
    adc TMP_Y
    tay
    lda hgr_lo, y
    sta PTR_LO
    lda hgr_hi, y
    clc
    adc DRAW_PAGE_OFF
    sta PTR_HI

    ; Byte 1
    ldy mult3_table, x
    lda (PTR2_LO), y
    ldy TMP_COL
    cpy #2
    bcc +
    cpy #36
    bcs +
    ora (PTR_LO), y
    sta (PTR_LO), y
+
    ; Byte 2
    ldy mult3_table, x
    iny
    lda (PTR2_LO), y
    ldy TMP_COL
    iny
    cpy #2
    bcc +
    cpy #36
    bcs +
    ora (PTR_LO), y
    sta (PTR_LO), y
+
    ; Byte 3
    ldy mult3_table, x
    iny
    iny
    lda (PTR2_LO), y
    ldy TMP_COL
    iny
    iny
    cpy #2
    bcc +
    cpy #36
    bcs +
    ora (PTR_LO), y
    sta (PTR_LO), y
+
    inx
    cpx #PLAYER_H
    bcc _dp_l
    rts

ErasePlayerSprite:
    ldx TMP_X
    lda div7_table, x
    sta TMP_COL

    ldx #0
_eps_l:
    txa
    clc
    adc TMP_Y
    tay
    lda hgr_lo, y
    sta PTR_LO
    lda hgr_hi, y
    clc
    adc DRAW_PAGE_OFF
    sta PTR_HI

    lda #0
    ldy TMP_COL
    cpy #2
    bcc _eps_s1
    cpy #36
    bcs _eps_s1
    sta (PTR_LO), y
_eps_s1:
    iny
    cpy #2
    bcc _eps_s2
    cpy #36
    bcs _eps_s2
    sta (PTR_LO), y
_eps_s2:
    iny
    cpy #2
    bcc _eps_s3
    cpy #36
    bcs _eps_s3
    sta (PTR_LO), y
_eps_s3:
    inx
    cpx #PLAYER_H
    bcc _eps_l

    lda stage_num
    cmp #2
    bcc +
    lda #3
    sta TEMP_BYTES
    lda #PLAYER_H
    sta TEMP_LINES
    jsr RestoreTilesInBoundingBox
+   rts

; ===================================================================
; WIRE BLITTERS (OPTIMIZED HIGH-SPEED HARPOON ENGINE)
; ===================================================================
DrawWire:
    ; 1. Draw Harpoon Tip at wire_x, wire_y (8 lines)
    lda #<spr_harpoon_tip
    sta SRC_LO
    lda #>spr_harpoon_tip
    sta SRC_HI

    ldx wire_x
    lda div7_table, x
    sta TMP_COL
    lda mod7_table, x
    tax
    lda shift_harpoon_offset_lo, x
    clc
    adc SRC_LO
    sta PTR2_LO
    lda shift_harpoon_offset_hi, x
    adc SRC_HI
    sta PTR2_HI

    ldx #0
_dwt_l:
    txa
    clc
    adc wire_y
    tay
    lda hgr_lo, y
    sta PTR_LO
    lda hgr_hi, y
    clc
    adc DRAW_PAGE_OFF
    sta PTR_HI

    ldy mult2_table, x
    lda (PTR2_LO), y
    ldy TMP_COL
    ora (PTR_LO), y
    sta (PTR_LO), y

    ldy mult2_table, x
    iny
    lda (PTR2_LO), y
    ldy TMP_COL
    iny
    ora (PTR_LO), y
    sta (PTR_LO), y

    inx
    cpx #8
    bcc _dwt_l

    ; 2. Draw Cable from wire_y + 8 down to FLOOR_Y (Single-byte column blit)
    lda wire_x
    clc
    adc #3
    tax
    lda div7_table, x
    sta TMP_COL
    lda mod7_table, x
    tax
    lda bit_mask_table, x
    sta TMP_BYTE

    lda wire_y
    clc
    adc #8
    tax
    ldy TMP_COL
_dw_cable:
    cpx #FLOOR_Y
    bcs _dw_done
    lda hgr_lo, x
    sta PTR_LO
    lda hgr_hi, x
    clc
    adc DRAW_PAGE_OFF
    sta PTR_HI

    lda (PTR_LO), y
    ora TMP_BYTE
    sta (PTR_LO), y
    inx
    jmp _dw_cable
_dw_done:
    rts

EraseWireDirect:
    ; 1. Erase Tip (8 lines, columns TMP_COL and TMP_COL + 1)
    ldx TMP_X
    lda div7_table, x
    sta TMP_COL

    ldx #0
_ew_tip:
    txa
    clc
    adc TMP_Y
    cmp #FLOOR_Y
    bcs _ew_tip_skip
    tay
    lda hgr_lo, y
    sta PTR_LO
    lda hgr_hi, y
    clc
    adc DRAW_PAGE_OFF
    sta PTR_HI

    lda #0
    ldy TMP_COL
    sta (PTR_LO), y
    iny
    sta (PTR_LO), y
_ew_tip_skip:
    inx
    cpx #8
    bcc _ew_tip

    ; 2. Erase Cable from TMP_Y + 8 down to FLOOR_Y (1 single column byte!)
    lda TMP_X
    clc
    adc #3
    tax
    lda div7_table, x
    tay                 ; Y = cable column (constant for entire cable!)

    lda TMP_Y
    clc
    adc #8
    tax                 ; X = starting scanline (TMP_Y + 8)
_ew_cable:
    cpx #FLOOR_Y
    bcs _ew_done
    lda hgr_lo, x
    sta PTR_LO
    lda hgr_hi, x
    clc
    adc DRAW_PAGE_OFF
    sta PTR_HI

    lda #0
    sta (PTR_LO), y
    inx
    jmp _ew_cable
_ew_done:
    lda stage_num
    cmp #2
    bcc +
    ; 1. Restore tiles under tip (TMP_X, TMP_Y, 2 cols, 8 lines)
    lda #2
    sta TEMP_BYTES
    lda #8
    sta TEMP_LINES
    jsr RestoreTilesInBoundingBox

    ; 2. Restore tiles under cable (TMP_X + 3, TMP_Y + 8 down to FLOOR_Y)
    lda TMP_X
    clc
    adc #3
    sta TMP_X
    lda TMP_Y
    clc
    adc #8
    sta TMP_Y
    lda #1
    sta TEMP_BYTES
    lda #FLOOR_Y
    sec
    sbc TMP_Y
    sta TEMP_LINES
    jsr RestoreTilesInBoundingBox
+   rts

bit_mask_table:
    .byte $01, $02, $04, $08, $10, $20, $40

; ===================================================================
; BALL BLITTERS
; ===================================================================
DrawSingleBall:
    lda ball_x, x
    sta TMP_X
    lda ball_y_int, x
    sta TMP_Y
    lda ball_size, x

    cmp #0
    beq _dsb_0
    cmp #1
    beq _dsb_1
    cmp #2
    beq _dsb_2
    jmp BlitBall3
_dsb_0:
    jmp BlitBall0
_dsb_1:
    jmp BlitBall1
_dsb_2:
    jmp BlitBall2

BlitBall0:
    ; Size 0: 8 lines x 2 bytes
    lda #<spr_ball_size0
    sta SRC_LO
    lda #>spr_ball_size0
    sta SRC_HI
    ldx TMP_X
    lda div7_table, x
    sta TMP_COL
    lda mod7_table, x
    tax
    lda shift_ball0_offset_lo, x
    clc
    adc SRC_LO
    sta PTR2_LO
    lda shift_ball0_offset_hi, x
    adc SRC_HI
    sta PTR2_HI

    ldx #0
-   txa
    clc
    adc TMP_Y
    cmp #FLOOR_Y
    bcs _bb0_skip
    tay
    lda hgr_lo, y
    sta PTR_LO
    lda hgr_hi, y
    clc
    adc DRAW_PAGE_OFF
    sta PTR_HI

    ldy mult2_table, x
    lda (PTR2_LO), y
    ldy TMP_COL
    cpy #2
    bcc +
    cpy #36
    bcs +
    ora (PTR_LO), y
    sta (PTR_LO), y
+
    ldy mult2_table, x
    iny
    lda (PTR2_LO), y
    ldy TMP_COL
    iny
    cpy #2
    bcc +
    cpy #36
    bcs +
    ora (PTR_LO), y
    sta (PTR_LO), y
+
_bb0_skip:
    inx
    cpx #8
    bcc -
    rts

BlitBall1:
    ; Size 1: 14 lines x 3 bytes
    lda #<spr_ball_size1
    sta SRC_LO
    lda #>spr_ball_size1
    sta SRC_HI
    ldx TMP_X
    lda div7_table, x
    sta TMP_COL
    lda mod7_table, x
    tax
    lda shift_ball1_offset_lo, x
    clc
    adc SRC_LO
    sta PTR2_LO
    lda shift_ball1_offset_hi, x
    adc SRC_HI
    sta PTR2_HI

    ldx #0
-   txa
    clc
    adc TMP_Y
    cmp #FLOOR_Y
    bcs _bb1_skip
    tay
    lda hgr_lo, y
    sta PTR_LO
    lda hgr_hi, y
    clc
    adc DRAW_PAGE_OFF
    sta PTR_HI

    ldy mult3_table, x
    lda (PTR2_LO), y
    ldy TMP_COL
    cpy #2
    bcc +
    cpy #36
    bcs +
    ora (PTR_LO), y
    sta (PTR_LO), y
+
    ldy mult3_table, x
    iny
    lda (PTR2_LO), y
    ldy TMP_COL
    iny
    cpy #2
    bcc +
    cpy #36
    bcs +
    ora (PTR_LO), y
    sta (PTR_LO), y
+
    ldy mult3_table, x
    iny
    iny
    lda (PTR2_LO), y
    ldy TMP_COL
    iny
    iny
    cpy #2
    bcc +
    cpy #36
    bcs +
    ora (PTR_LO), y
    sta (PTR_LO), y
+
_bb1_skip:
    inx
    cpx #14
    bcc -
    rts

BlitBall2:
    ; Size 2: 20 lines x 4 bytes
    lda #<spr_ball_size2
    sta SRC_LO
    lda #>spr_ball_size2
    sta SRC_HI
    ldx TMP_X
    lda div7_table, x
    sta TMP_COL
    lda mod7_table, x
    tax
    lda shift_ball2_offset_lo, x
    clc
    adc SRC_LO
    sta PTR2_LO
    lda shift_ball2_offset_hi, x
    adc SRC_HI
    sta PTR2_HI

    ldx #0
-   txa
    clc
    adc TMP_Y
    cmp #FLOOR_Y
    bcs _bb2_skip
    tay
    lda hgr_lo, y
    sta PTR_LO
    lda hgr_hi, y
    clc
    adc DRAW_PAGE_OFF
    sta PTR_HI

    ldy mult4_table, x
    lda (PTR2_LO), y
    ldy TMP_COL
    cpy #2
    bcc +
    cpy #36
    bcs +
    ora (PTR_LO), y
    sta (PTR_LO), y
+
    ldy mult4_table, x
    iny
    lda (PTR2_LO), y
    ldy TMP_COL
    iny
    cpy #2
    bcc +
    cpy #36
    bcs +
    ora (PTR_LO), y
    sta (PTR_LO), y
+
    ldy mult4_table, x
    iny
    iny
    lda (PTR2_LO), y
    ldy TMP_COL
    iny
    iny
    cpy #2
    bcc +
    cpy #36
    bcs +
    ora (PTR_LO), y
    sta (PTR_LO), y
+
    ldy mult4_table, x
    iny
    iny
    iny
    lda (PTR2_LO), y
    ldy TMP_COL
    iny
    iny
    iny
    cpy #2
    bcc +
    cpy #36
    bcs +
    ora (PTR_LO), y
    sta (PTR_LO), y
+
_bb2_skip:
    inx
    cpx #20
    bcc -
    rts

BlitBall3:
    ; Size 3: 26 lines x 5 bytes (100% bug-free with mult5_table)
    lda #<spr_ball_size3
    sta SRC_LO
    lda #>spr_ball_size3
    sta SRC_HI
    ldx TMP_X
    lda div7_table, x
    sta TMP_COL
    lda mod7_table, x
    tax
    lda shift_ball3_offset_lo, x
    clc
    adc SRC_LO
    sta PTR2_LO
    lda shift_ball3_offset_hi, x
    adc SRC_HI
    sta PTR2_HI

    ldx #0
_bb3_loop:
    txa
    clc
    adc TMP_Y
    cmp #FLOOR_Y
    bcc +
    jmp _bb3_skip
+   tay
    lda hgr_lo, y
    sta PTR_LO
    lda hgr_hi, y
    clc
    adc DRAW_PAGE_OFF
    sta PTR_HI

    ldy mult5_table, x
    lda (PTR2_LO), y
    ldy TMP_COL
    cpy #2
    bcc +
    cpy #36
    bcs +
    ora (PTR_LO), y
    sta (PTR_LO), y
+
    ldy mult5_table, x
    iny
    lda (PTR2_LO), y
    ldy TMP_COL
    iny
    cpy #2
    bcc +
    cpy #36
    bcs +
    ora (PTR_LO), y
    sta (PTR_LO), y
+
    ldy mult5_table, x
    iny
    iny
    lda (PTR2_LO), y
    ldy TMP_COL
    iny
    iny
    cpy #2
    bcc +
    cpy #36
    bcs +
    ora (PTR_LO), y
    sta (PTR_LO), y
+
    ldy mult5_table, x
    iny
    iny
    iny
    lda (PTR2_LO), y
    ldy TMP_COL
    iny
    iny
    iny
    cpy #2
    bcc +
    cpy #36
    bcs +
    ora (PTR_LO), y
    sta (PTR_LO), y
+
    ldy mult5_table, x
    iny
    iny
    iny
    iny
    lda (PTR2_LO), y
    ldy TMP_COL
    iny
    iny
    iny
    iny
    cpy #2
    bcc +
    cpy #36
    bcs +
    ora (PTR_LO), y
    sta (PTR_LO), y
+
_bb3_skip:
    inx
    cpx #26
    bcs _bb3_done
    jmp _bb3_loop
_bb3_done:
    rts

EraseBallDirect:
    ; Inputs: A = ball size (0..3), TMP_X, TMP_Y
    ; COMPLETE & SURGICAL ERASE ACROSS FULL RECTANGLE
    tax
    lda ball_clear_bytes, x
    sta TEMP_BYTES

    lda ball_heights, x
    sta TEMP_LINES

    ldx TMP_X
    lda div7_table, x
    sta TMP_COL

    ldx #0
_ebd_line_loop:
    txa
    clc
    adc TMP_Y
    cmp #FLOOR_Y
    bcs _ebd_next_line
    tay
    lda hgr_lo, y
    sta PTR_LO
    lda hgr_hi, y
    clc
    adc DRAW_PAGE_OFF
    sta PTR_HI

    lda TEMP_BYTES
    sta TEMP_VAL2
    lda TMP_COL
    sta TMP_BYTE
_ebd_byte_loop:
    ldy TMP_BYTE
    cpy #2
    bcc _ebd_skip_byte
    cpy #36
    bcs _ebd_skip_byte
    lda #0
    sta (PTR_LO), y
_ebd_skip_byte:
    inc TMP_BYTE
    dec TEMP_VAL2
    bne _ebd_byte_loop

_ebd_next_line:
    inx
    cpx TEMP_LINES
    bcc _ebd_line_loop

    lda stage_num
    cmp #2
    bcc +
    jsr RestoreTilesInBoundingBox
+   rts

; ===================================================================
; SOUND SYNTHESIZER (SPEAKER $C030)
; ===================================================================
PlayShootSound:
    pha
    txa
    pha
    tya
    pha
    ldx #15
_pss_loop:
    bit SPEAKER
    txa
    asl
    tay
_pss_w:
    dey
    bne _pss_w
    dex
    bne _pss_loop
    pla
    tay
    pla
    tax
    pla
    rts

PlayPopSound:
    pha
    txa
    pha
    tya
    pha
    ldx #40
_pps_loop:
    bit SPEAKER
    lda RAND_SEED
    lsr
    bcc +
    eor #$B8
+   sta RAND_SEED
    and #$1F
    clc
    adc #5
    tay
_pps_w:
    dey
    bne _pps_w
    dex
    bne _pps_loop
    pla
    tay
    pla
    tax
    pla
    rts

PlayBounceSound:
    pha
    txa
    pha
    tya
    pha
    ldx #4
_pbs_loop:
    bit SPEAKER
    ldy #80
_pbs_w:
    dey
    bne _pbs_w
    dex
    bne _pbs_loop
    pla
    tay
    pla
    tax
    pla
    rts

PlayDeathSound:
    pha
    txa
    pha
    tya
    pha
    ldx #50
_pds_loop:
    bit SPEAKER
    txa
    tay
_pds_w:
    dey
    bne _pds_w
    dex
    bne _pds_loop
    pla
    tay
    pla
    tax
    pla
    rts
