; ===================================================================
; SPACE INVADERS (1978) - 100% AUTHENTIC ARCADE REPLICA FOR APPLE //e
; 6502 Assembly - High Resolution Graphics (HGR) with Page-Flipping
; Target Assembler: 64tass
; ===================================================================

.cpu "6502"
* = $6000

    jmp Start

; ===================================================================
; HARDWARE EQUATES (APPLE //e)
; ===================================================================
TXTCLR   = $C050        ; Switch to Graphics mode
TXTSET   = $C051        ; Switch to Text mode
MIXCLR   = $C052        ; Full screen graphics (no 4-line bottom text)
MIXSET   = $C053        ; Mixed graphics + 4-line text
TXTPAGE1 = $C054        ; Select / Display HGR Page 1 ($2000-$3FFF)
TXTPAGE2 = $C055        ; Select / Display HGR Page 2 ($4000-$5FFF)
HIRES    = $C057        ; Enable High-Resolution mode (HGR 280x192)

KBD      = $C000        ; Keyboard data (Bit 7 = 1 if key pressed)
KBDSTRB  = $C010        ; Clear keyboard strobe
SPEAKER  = $C030        ; Speaker click toggle
BTN0     = $C061        ; Joystick button 0 (Bit 7 = 1 if pressed)
BTN1     = $C062        ; Joystick button 1 (Bit 7 = 1 if pressed)
PDL0     = $FB1E        ; ROM routine to read paddle/joystick 0 (X=0, returns Y)
COUT     = $FDED        ; ROM routine to output character in A (hooks DOS 3.3)

; ===================================================================
; ZERO PAGE VARIABLES & POINTERS ($06 - $4F)
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
STR_PTR_LO      = $11   ; Text string pointer LO
STR_PTR_HI      = $12   ; Text string pointer HI
FONT_CHAR       = $13   ; Current font character
RAND_SEED       = $14   ; LFSR pseudo-random seed
DRAW_PAGE_OFF   = $15   ; $00 for Page 1, $20 for Page 2
CURR_PAGE       = $16   ; 0 = Page 1 displayed, 1 = Page 2 displayed
TEMP_VAL        = $17   ; General temp variable
BCD_VAL_HI      = $18   ; BCD print temp HI
BCD_VAL_LO      = $19   ; BCD print temp LO
BOMB_SLOT       = $1A   ; Dedicated alien bomb slot index (0..2)

; ===================================================================
; GAME ENGINE CONSTANTS
; ===================================================================
PLAYFIELD_LEFT  = 4     ; Screen byte 4 (X=28 in 280x192)
PLAYFIELD_WIDTH = 32    ; 32 bytes wide (224 pixels)
SCREEN_WIDTH    = 40    ; 40 bytes per line

PLAYER_Y        = 162   ; Player cannon scanline
FLOOR_Y         = 174   ; Green baseline scanline
BUNKER_Y        = 140   ; Top of bunkers scanline (16 lines high: 140..155)
SAUCER_Y        = 21    ; Saucer flyway scanline (8 lines high: 21..28)

; ===================================================================
; DATA INCLUDES (Pre-shifted sprites, 8x8 font, bunker template, tables)
; ===================================================================
.include "invaders_data.asm"

; ===================================================================
; ===================================================================
; BSS BUFFERS IN FREE RAM ($1000 - $1FFF)
; (Preserves Applesoft BASIC program $0801-$0CDD, takes 0 bytes in binary!)
; ===================================================================
p1_save_state       = $1000    ; 325 bytes ($1000 - $1144)
p2_save_state       = $1148    ; 325 bytes ($1148 - $128C)
bunker_ram          = $1290    ; 256 bytes ($1290 - $138F)
div7_table          = $1390    ; 256 bytes ($1390 - $148F)
mod7_table          = $1490    ; 256 bytes ($1490 - $158F)
alien_alive_table   = $1590    ; 55 bytes  ($1590 - $15C6)
alien_old_x         = $15D0    ; 55 bytes  ($15D0 - $1606)
alien_old_y         = $1610    ; 55 bytes  ($1610 - $1646)
alien_row_table     = $1650    ; 55 bytes  ($1650 - $1686)

alien_row_y_table:
    .byte 0, 14, 28, 42, 56

; Shift offset tables: shift * 24 (for 16-bit sprites)
shift_offset_24:
    .byte 0, 24, 48, 72, 96, 120, 144

; Shift offset tables: shift * 16 (for 8-bit bomb sprites)
shift_offset_16:
    .byte 0, 16, 32, 48, 64, 80, 96

; Bit masks for 7-pixel Apple II HGR
bit_mask_table:
    .byte $01, $02, $04, $08, $10, $20, $40

bit_clear_table:
    .byte $FE, $FD, $FB, $F7, $EF, $DF, $BF

notch_mask_table:
    .byte $03, $07, $0E, $1C, $38, $70, $60

notch_clear_table:
    .byte $7C, $78, $71, $63, $47, $0F, $1F

; ===================================================================
; GAME STATE VARIABLES (RAM at $7100)
; ===================================================================
game_mode:          .byte 0     ; 0 = Attract mode, 1 = Gameplay
credits:            .byte 0     ; BCD credits ($00..$99)
score_p1_lo:        .byte 0     ; BCD Player 1 score LO (e.g. $00)
score_p1_hi:        .byte 0     ; BCD Player 1 score HI (e.g. $00)
score_p2_lo:        .byte 0     ; BCD Player 2 score LO (e.g. $00)
score_p2_hi:        .byte 0     ; BCD Player 2 score HI (e.g. $00)
score_hi_lo:        .byte 0     ; BCD High score LO
score_hi_hi:        .byte 0     ; BCD High score HI
lives:              .byte 3     ; Remaining lives of active player (3)
lives_p1:           .byte 3     ; Player 1 lives
lives_p2:           .byte 3     ; Player 2 lives
active_player:      .byte 0     ; 0 = Player 1, 1 = Player 2
num_players:        .byte 1     ; 1 or 2 players
wave:               .byte 1     ; Current wave (1, 2, 3...)
extra_life_awarded: .byte 0     ; 1 if 1500-pt bonus life already awarded P1
extra_life_awarded_p2: .byte 0  ; 1 if 1500-pt bonus life already awarded P2

; Player Cannon variables
player_x:           .byte 16    ; Player X (0..223, arcade initial $30-$20 = 16)
player_x_p1:        .byte 16    ; Previous player X on Page 1
player_x_p2:        .byte 16    ; Previous player X on Page 2
player_alive:       .byte 1     ; 1 = alive, 0 = dying
player_exp_timer:   .byte 0     ; Explosion timer
player_exp_frame:   .byte 0     ; 0 or 1 alternating explosion frame

; Player Missile variables
shot_active:        .byte 0     ; 0 = inactive, 1 = active, 2 = explosion splash
shot_active_p1:     .byte 0     ; 1 if drawn on Page 1
shot_active_p2:     .byte 0     ; 1 if drawn on Page 2
shot_x:             .byte 0     ; Shot X (0..223)
shot_y:             .byte 0     ; Shot Y (0..191)
shot_x_p1:          .byte 0     ; Previous shot X on Page 1
shot_y_p1:          .byte 0     ; Previous shot Y on Page 1
shot_x_p2:          .byte 0     ; Previous shot X on Page 2
shot_y_p2:          .byte 0     ; Previous shot Y on Page 2
shot_splash_timer:  .byte 0     ; Splash explosion timer

; Alien Fleet variables
fleet_x:            .byte 24    ; Reference alien X (0..223)
fleet_y:            .byte 34    ; Reference alien Y (initial 34)
fleet_dir:          .byte 1     ; 1 = right, $FF = left
fleet_edge_hit:     .byte 0     ; 1 if any alien touched edge during current sweep
fleet_frame:        .byte 0     ; 0 or 1 (animation frame)
alien_cur_idx:      .byte 0     ; 0..54 (single alien cursor step)
aliens_remaining:   .byte 55    ; Count of living aliens (initial 55)
alien_step_sound:   .byte 0     ; 0..3 (which of the 4 bass march tones to play)
alien_exp_active:   .byte 0     ; 1 if alien explosion on screen
alien_exp_x:        .byte 0     ; Explosion X
alien_exp_y:        .byte 0     ; Explosion Y
alien_exp_timer:    .byte 0     ; Explosion duration

; (alien_alive_table, alien_old_x, alien_old_y located in BSS at $0D90-$0E46)

; Alien Bombs (3 slots: 0 = Rolling, 1 = Plunger, 2 = Squiggly)
bomb_active:        .byte 0, 0, 0
bomb_active_p1:     .byte 0, 0, 0
bomb_active_p2:     .byte 0, 0, 0
bomb_x:             .byte 0, 0, 0
bomb_y:             .byte 0, 0, 0
bomb_prev_x_p1:     .byte 0, 0, 0
bomb_prev_y_p1:     .byte 0, 0, 0
bomb_prev_frame_p1: .byte 0, 0, 0
bomb_prev_x_p2:     .byte 0, 0, 0
bomb_prev_y_p2:     .byte 0, 0, 0
bomb_prev_frame_p2: .byte 0, 0, 0
bomb_frame:         .byte 0, 0, 0
bomb_reload:        .byte 0, 0, 0   ; Per-slot reload countdown
bomb_delta_y:       .byte 4, 4, 6   ; Per-slot Y speed: Rolling=4, Plunger=4, Squiggly=6
plunger_ptr:        .byte 0     ; Index into col_fire_table (0..15)
squiggly_ptr:       .byte 6     ; Index into col_fire_table (6..20)

; Score-based alien bomb reload rate table (original arcade: 1 entry per score MSB 0..7+)
; Values = minimum steps between shots. Lower = faster. Original: $30 at 0pts -> $07 at $3000pts
alien_reload_rate_table:
    .byte 48, 40, 32, 24, 18, 14, 10, 7

bomb_frames_lo:
    .byte <bomb_roll_f0, <bomb_roll_f1, <bomb_roll_f2, <bomb_roll_f3
    .byte <bomb_plung_f0, <bomb_plung_f1, <bomb_plung_f2, <bomb_plung_f3
    .byte <bomb_squig_f0, <bomb_squig_f1, <bomb_squig_f2, <bomb_squig_f3

bomb_frames_hi:
    .byte >bomb_roll_f0, >bomb_roll_f1, >bomb_roll_f2, >bomb_roll_f3
    .byte >bomb_plung_f0, >bomb_plung_f1, >bomb_plung_f2, >bomb_plung_f3
    .byte >bomb_squig_f0, >bomb_squig_f1, >bomb_squig_f2, >bomb_squig_f3

; Mystery Ship (Saucer / UFO) variables
saucer_active:      .byte 0     ; 0 = inactive, 1 = flying, 2 = hit explosion, 3 = score display
saucer_active_p1:   .byte 0     ; 1 if drawn on Page 1
saucer_active_p2:   .byte 0     ; 1 if drawn on Page 2
saucer_x:           .byte 0     ; Saucer X
saucer_dir:         .byte 1     ; 1 = left-to-right, $FF = right-to-left
saucer_prev_x_p1:   .byte 0
saucer_prev_x_p2:   .byte 0
saucer_timer:       .word 600   ; Countdown to spawn
saucer_score_ptr:   .byte 0     ; Index in saucer_score_table (0..14)
saucer_hit_timer:   .byte 0     ; Explosion / score display timer
saucer_hit_score:   .byte 0     ; BCD awarded score (e.g. $50, $00)
saucer_hit_hi:      .byte 0     ; High byte (e.g. $01, $03)

; (bunker_ram, p1_save_state, p2_save_state located in BSS at $1000-$1687)
p2_initialized:     .byte 0

; Bunker Collision & Crater Variables
bunker_collision_dir: .byte 0
bunker_curr_base:     .byte 0
bunker_local_x:       .byte 0
bunker_local_y:       .byte 0
bunker_x_times_4:     .byte 0

; Alien Bunker Erosion Variables
ebba_col0:            .byte 0
ebba_col1:            .byte 0
ebba_col2:            .byte 0
ebba_line_idx:        .byte 0
ebba_local_y4:        .byte 0
ebba_sprite_byte:     .byte 0

; Screen Column to Bunker Byte Mapping Table (40 bytes for columns 0..39)
col_to_bunker_table:
    .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
    .byte 0, 1, 2, 3
    .byte $FF, $FF, $FF
    .byte 64, 65, 66, 67
    .byte $FF, $FF
    .byte 128, 129, 130, 131
    .byte $FF, $FF
    .byte 192, 193, 194, 195
    .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF

; Attract Mode animation variables
saved_sp:           .byte $FF   ; Saved DOS 3.3 stack pointer for clean exit
attract_state:      .byte 0
attract_timer:      .word 0
attract_alien_x:    .byte 255
attract_y_char:     .byte 'y'   ; Initially inverted 'y'
attract_x_p1:       .byte 255
attract_x_p2:       .byte 255
attract_frame:      .byte 0
attract_y_col:      .byte 21    ; Column where the Y char is currently drawn (or 255=none)
attract_y_col_prev: .byte 21    ; Previous frame's Y col (for erasing)

; Texts
str_score_head:     .text "SCORE<1>      HI-SCORE      SCORE<2>", 0
str_play_msg:       .text "PLAy", 0
str_space_inv:      .text "SPACE  INVADERS", 0
str_score_adv:      .text "*SCORE ADVANCE TABLE*", 0
str_mystery:        .text "=? MYSTERY", 0
str_30_pts:         .text "=30 POINTS", 0
str_20_pts:         .text "=20 POINTS", 0
str_10_pts:         .text "=10 POINTS", 0
str_insert_coin:    .text "TAPE 'C' FOR CREDIT", 0
str_credit_lbl:     .text "CREDIT ", 0
str_game_over:      .text "GAME OVER", 0
str_play_player1:   .text "PLAY PLAYER<1>", 0
str_play_player2:   .text "PLAY PLAYER<2>", 0
str_blank_14:       .text "              ", 0
str_blank_19:       .text "                   ", 0
str_saucer_50:      .text " 50", 0
str_saucer_100:     .text "100", 0
str_saucer_150:     .text "150", 0
str_saucer_300:     .text "300", 0

; ===================================================================
; MAIN ENTRY POINT & SYSTEM INITIALIZATION
; ===================================================================
Start:
    tsx
    stx saved_sp        ; Save DOS 3.3 stack pointer for clean RTS exit
    sei                 ; Disable interrupts
    cld                 ; Clear decimal mode

    jsr InitDivMod7Tables

    lda #$5A
    sta RAND_SEED       ; Initialize random seed

    ; Reset game data
    lda #0
    sta credits
    sta score_p1_lo
    sta score_p1_hi
    sta score_hi_lo
    sta score_hi_hi
    sta game_mode

    ; Setup HGR Graphics Mode
    jsr InitGraphics

    ; Go to Attract Mode
    jmp EnterAttractMode

InitDivMod7Tables:
    ldx #0
    ldy #0              ; Y = quotient (0..36)
    lda #0              ; A = remainder (0..6)
-   sta mod7_table, x
    pha
    tya
    sta div7_table, x
    pla
    clc
    adc #1
    cmp #7
    bcc +
    lda #0
    iny
+   inx
    bne -

    ; Fill alien_row_table (55 entries: index / 11)
    ldx #0
_fill_art:
    txa
    ldy #0
-   cmp #11
    bcc +
    sbc #11
    iny
    bne -
+   tya
    sta alien_row_table, x
    inx
    cpx #55
    bcc _fill_art
    rts

; ===================================================================
; CLEAN EXIT TO DOS 3.3 / APPLESOFT MENU (ESC KEY)
; ===================================================================
QuitToMenu:
    sta KBDSTRB         ; Clear keyboard strobe ($C010)
    sta TXTSET          ; $C051: Switch to Text mode
    sta MIXCLR          ; $C052: Full screen text (no split)
    sta TXTPAGE1        ; $C054: Display text Page 1 ($0400-$07FF)
    bit $C056           ; Lo-res (clears hires $C057)
    lda #$FF
    sta $32             ; Normal text mode (White on Black, INVFLG = $FF)
    jsr $FB2F           ; SETTXT: Reset text window to full 40x24 (0, 40, 0, 24)
    jsr $FC58           ; HOME: Clear 40x24 text screen, cursor at (0,0)
    sta KBDSTRB         ; Clear keyboard strobe again
    ldx saved_sp        ; Restore DOS 3.3 stack pointer
    txs
    cli                 ; Re-enable interrupts

    ; Issue DOS 3.3 command: CR, Ctrl-D, "RUN HELLO", CR
    ; This fully resets DOS 3.3 buffers & hooks, restarting HELLO cleanly without OUT OF DATA errors!
    ldx #0
-   lda dos_cmd_run_hello, x
    beq +
    jsr COUT            ; Output character (intercepted by DOS 3.3)
    inx
    bne -
+   rts

dos_cmd_run_hello:
    .byte $8D           ; Carriage Return (ensures beginning of line)
    .byte $84           ; Ctrl-D (DOS 3.3 command intercept trigger)
    .byte 'R' | $80
    .byte 'U' | $80
    .byte 'N' | $80
    .byte ' ' | $80
    .byte 'H' | $80
    .byte 'E' | $80
    .byte 'L' | $80
    .byte 'L' | $80
    .byte 'O' | $80
    .byte $8D           ; Carriage Return (executes command)
    .byte 0

; ===================================================================
; HGR GRAPHICS SETUP & BUFFER FLIPPING
; ===================================================================
InitGraphics:
    bit TXTCLR          ; Switch to Graphics display
    bit MIXCLR          ; Full screen (no text at bottom)
    bit HIRES           ; High resolution graphics mode
    bit TXTPAGE1        ; Display Page 1 initially

    lda #0
    sta CURR_PAGE       ; Page 1 currently displayed
    lda #$20
    sta DRAW_PAGE_OFF   ; Back-buffer is Page 2 ($4000)

    ; Clear both Page 1 and Page 2 to pure black ($00)
    jsr ClearPage1
    jsr ClearPage2
    rts

ClearPage1:
    lda #0
    sta DRAW_PAGE_OFF
    jsr ClearActivePage
    rts

ClearPage2:
    lda #$20
    sta DRAW_PAGE_OFF
    jsr ClearActivePage
    rts

ClearActivePage:
    ldx #0
_cap_line:
    lda hgr_lo, x
    sta PTR_LO
    lda hgr_hi, x
    clc
    adc DRAW_PAGE_OFF
    sta PTR_HI
    lda #0
    ldy #39
_cap_byte:
    sta (PTR_LO), y
    dey
    bpl _cap_byte
    inx
    cpx #192
    bcc _cap_line
    rts

FlipBuffers:
    lda CURR_PAGE
    bne ShowPage1

    ; Currently showing Page 1 -> Flip to Page 2
    bit TXTPAGE2        ; Show Page 2
    lda #1
    sta CURR_PAGE
    lda #$00
    sta DRAW_PAGE_OFF   ; Next drawing writes to Page 1
    rts

ShowPage1:
    bit TXTPAGE1        ; Show Page 1
    lda #0
    sta CURR_PAGE
    lda #$20
    sta DRAW_PAGE_OFF   ; Next drawing writes to Page 2
    rts

RestoreDrawPage:
    lda CURR_PAGE
    beq +
    lda #$00
    sta DRAW_PAGE_OFF
    rts
+   lda #$20
    sta DRAW_PAGE_OFF
    rts

; Synchronize frame rate (tuned for responsive arcade pacing)
WaitFrameSync:
    txa
    pha
    tya
    pha
    lda aliens_remaining
    cmp #1
    bne +
    ldx #8              ; Very fast loop when only 1 alien remains!
    jmp _wfs_start
+   cmp #4
    bcs +
    ldx #16             ; Faster when <= 3 aliens remain
    jmp _wfs_start
+   ldx #32             ; Accelerated overall game pace (~1.8x faster)
_wfs_start:
_wfs1:
    ldy #50
_wfs2:
    dey
    bne _wfs2
    dex
    bne _wfs1
    pla
    tay
    pla
    tax
    rts

; ===================================================================
; PSEUDO-RANDOM NUMBER GENERATOR (8-bit Galois LFSR)
; ===================================================================
GetRandom:
    lda RAND_SEED
    lsr
    bcc +
    eor #$B8            ; Feedback polynomial
+   sta RAND_SEED
    rts

; ===================================================================
; SOUND SYNTHESIZER (CYCLE-ACCURATE SPEAKER $C030)
; ===================================================================

; Alien March: 4 authentic bass thud footsteps
PlayMarchSound:
    lda alien_step_sound
    and #$03
    tax
    lda march_delays, x
    sta TEMP_VAL

    ldx #8              ; 8 speaker clicks
_pms_click:
    bit SPEAKER
    ldy TEMP_VAL
_pms_wait:
    dey
    bne _pms_wait
    dex
    bne _pms_click

    ; Cycle to next tone (0 -> 1 -> 2 -> 3 -> 0)
    inc alien_step_sound
    rts

march_delays:
    .byte 190, 172, 155, 138

; Player Laser Shot: Fast descending pitch sweep
PlayShootSound:
    ldx #25             ; 25 pulses
    lda #20             ; Start period
    sta TEMP_VAL
_pss_loop:
    bit SPEAKER
    ldy TEMP_VAL
-   dey
    bne -
    inc TEMP_VAL        ; Sweep pitch down
    inc TEMP_VAL
    dex
    bne _pss_loop
    rts

; Alien Explosion: Crisp decaying white noise
PlayAlienHitSound:
    ldx #45             ; 45 noise clicks
_pah_loop:
    bit SPEAKER
    jsr GetRandom
    and #$1F            ; Random delay 0..31
    clc
    adc #10
    tay
-   dey
    bne -
    dex
    bne _pah_loop
    rts

; Player Explosion: Deep rumbling destruction crash
PlayPlayerHitSound:
    ldx #90             ; 90 noise clicks
_pph_loop:
    bit SPEAKER
    jsr GetRandom
    and #$3F            ; Random delay 0..63
    clc
    adc #20
    tay
-   dey
    bne -
    dex
    bne _pph_loop
    rts

; Saucer Siren: High-pitched warble pulse
PlaySaucerSiren:
    ldx #10
_psi_loop:
    bit SPEAKER
    ldy #48
-   dey
    bne -
    bit SPEAKER
    ldy #58
-   dey
    bne -
    dex
    bne _psi_loop
    rts

; Saucer Hit / Explosion: High-frequency shattering crash
PlaySaucerHitSound:
    ldx #60
_psh_loop:
    bit SPEAKER
    jsr GetRandom
    and #$1F
    clc
    adc #6
    tay
-   dey
    bne -
    dex
    bne _psh_loop
    rts

; Coin chime sound
PlayCoinSound:
    ldx #30
_pcs1:
    bit SPEAKER
    ldy #70
_pcs1_w:
    dey
    bne _pcs1_w
    dex
    bne _pcs1
    ldx #40
_pcs2:
    bit SPEAKER
    ldy #45
_pcs2_w:
    dey
    bne _pcs2_w
    dex
    bne _pcs2
    rts

; Extra life bonus player sound (ascending 3-tone arpeggio)
PlayExtraLifeSound:
    ldx #30
_pels_t1:
    bit SPEAKER
    ldy #70
_pels_w1:
    dey
    bne _pels_w1
    dex
    bne _pels_t1

    ldx #35
_pels_t2:
    bit SPEAKER
    ldy #50
_pels_w2:
    dey
    bne _pels_w2
    dex
    bne _pels_t2

    ldx #45
_pels_t3:
    bit SPEAKER
    ldy #35
_pels_w3:
    dey
    bne _pels_w3
    dex
    bne _pels_t3
    rts

; ===================================================================
; SPRITE RENDERING ENGINE (PRE-SHIFTED HGR BLITTERS)
; ===================================================================

; Draw a 16-bit wide, 8 scanlines tall pre-shifted sprite
; Inputs:
;   TMP_X = X (0..223)
;   TMP_Y = Y (0..191)
;   SRC_LO, SRC_HI = Base pointer of pre-shifted sprite table
DrawSprite16:
    ldx TMP_X
    lda div7_table, x
    clc
    adc #PLAYFIELD_LEFT ; Add 4 bytes left margin
    cmp #40
    bcc +
    rts                 ; Entirely off-screen right
+   sta TMP_COL

    lda mod7_table, x
    tax
    lda shift_offset_24, x
    clc
    adc SRC_LO
    sta PTR2_LO
    lda SRC_HI
    adc #0
    sta PTR2_HI

    ; Blit 8 scanlines (3 bytes each)
    ldx #0
_ds16_line:
    stx TEMP_VAL

    txa
    clc
    adc TMP_Y
    cmp #192
    bcs _ds16_skip
    tay
    lda hgr_lo, y
    sta PTR_LO
    lda hgr_hi, y
    clc
    adc DRAW_PAGE_OFF
    sta PTR_HI

    lda TEMP_VAL
    asl
    clc
    adc TEMP_VAL
    tay

    lda (PTR2_LO), y
    sta TMP_BYTE
    iny
    lda (PTR2_LO), y
    sta TMP_SHIFT
    iny
    lda (PTR2_LO), y
    sta FONT_CHAR

    ldy TMP_COL
    lda (PTR_LO), y
    ora TMP_BYTE
    sta (PTR_LO), y

    iny
    cpy #40
    bcs _ds16_skip
    lda (PTR_LO), y
    ora TMP_SHIFT
    sta (PTR_LO), y

    iny
    cpy #40
    bcs _ds16_skip
    lda (PTR_LO), y
    ora FONT_CHAR
    sta (PTR_LO), y

_ds16_skip:
    ldx TEMP_VAL
    inx
    cpx #8
    bcc _ds16_line
    rts

; Erase a 16-bit wide sprite using inverse bitmask (preserves neighbors!)
; Inputs:
;   TMP_X = X (0..223)
;   TMP_Y = Y (0..191)
;   SRC_LO, SRC_HI = Base pointer of pre-shifted sprite table
EraseMaskSprite16:
    ldx TMP_X
    lda div7_table, x
    clc
    adc #PLAYFIELD_LEFT
    cmp #40
    bcc +
    rts                 ; Entirely off-screen right
+   sta TMP_COL

    lda mod7_table, x
    tax
    lda shift_offset_24, x
    clc
    adc SRC_LO
    sta PTR2_LO
    lda SRC_HI
    adc #0
    sta PTR2_HI

    ldx #0
_ems16_line:
    stx TEMP_VAL

    txa
    clc
    adc TMP_Y
    cmp #192
    bcs _ems16_skip
    tay
    lda hgr_lo, y
    sta PTR_LO
    lda hgr_hi, y
    clc
    adc DRAW_PAGE_OFF
    sta PTR_HI

    lda TEMP_VAL
    asl
    clc
    adc TEMP_VAL
    tay

    lda (PTR2_LO), y
    eor #$7F
    ora #$80
    sta TMP_BYTE

    iny
    lda (PTR2_LO), y
    eor #$7F
    ora #$80
    sta TMP_SHIFT

    iny
    lda (PTR2_LO), y
    eor #$7F
    ora #$80
    sta FONT_CHAR

    ldy TMP_COL
    lda (PTR_LO), y
    and TMP_BYTE
    sta (PTR_LO), y

    iny
    cpy #40
    bcs _ems16_skip
    lda (PTR_LO), y
    and TMP_SHIFT
    sta (PTR_LO), y

    iny
    cpy #40
    bcs _ems16_skip
    lda (PTR_LO), y
    and FONT_CHAR
    sta (PTR_LO), y

_ems16_skip:
    ldx TEMP_VAL
    inx
    cpx #8
    bcc _ems16_line
    rts

; Erase a 16-bit wide, 8 scanlines tall sprite area
; Inputs:
;   TMP_X = X (0..223)
;   TMP_Y = Y (0..191)
EraseSprite16:
    ldx TMP_X
    lda div7_table, x
    clc
    adc #PLAYFIELD_LEFT
    cmp #40
    bcc +
    rts                 ; Entirely off-screen right
+   sta TMP_COL

    ldx #0
_es16_line:
    stx TEMP_VAL
    txa
    clc
    adc TMP_Y
    cmp #192
    bcs _es16_skip
    tay
    lda hgr_lo, y
    sta PTR_LO
    lda hgr_hi, y
    clc
    adc DRAW_PAGE_OFF
    sta PTR_HI

    ldy TMP_COL
    lda #0
    sta (PTR_LO), y
    iny
    cpy #40
    bcs _es16_skip
    sta (PTR_LO), y
    iny
    cpy #40
    bcs _es16_skip
    sta (PTR_LO), y

_es16_skip:
    ldx TEMP_VAL
    inx
    cpx #8
    bcc _es16_line
    rts

; Draw an 8-bit wide, 8 scanlines tall pre-shifted bomb sprite
; Inputs:
;   TMP_X = X (0..223)
;   TMP_Y = Y (0..191)
;   SRC_LO, SRC_HI = Pointer to pre-shifted bomb frame (16 bytes per shift)
DrawBombSprite:
    ldx TMP_X
    lda div7_table, x
    clc
    adc #PLAYFIELD_LEFT
    sta TMP_COL

    lda mod7_table, x
    tax
    lda shift_offset_16, x
    clc
    adc SRC_LO
    sta PTR2_LO
    lda SRC_HI
    adc #0
    sta PTR2_HI

    ldx #0
_dbs_line:
    stx TEMP_VAL

    txa
    clc
    adc TMP_Y
    cmp #FLOOR_Y
    bcs _dbs_skip_line  ; Never draw bomb onto or past FLOOR_Y!
    tay
    lda hgr_lo, y
    sta PTR_LO
    lda hgr_hi, y
    clc
    adc DRAW_PAGE_OFF
    sta PTR_HI

    lda TEMP_VAL
    asl                 ; line * 2
    tay

    lda (PTR2_LO), y
    sta TMP_BYTE
    iny
    lda (PTR2_LO), y
    sta TMP_SHIFT

    ldy TMP_COL
    lda (PTR_LO), y
    ora TMP_BYTE
    sta (PTR_LO), y

    iny
    lda (PTR_LO), y
    ora TMP_SHIFT
    sta (PTR_LO), y

_dbs_skip_line:
    ldx TEMP_VAL
    inx
    cpx #8
    bcc _dbs_line
    rts

; Erase an 8-bit wide, 8 scanlines tall bomb sprite area
; Inputs:
;   TMP_X = X (0..223)
;   TMP_Y = Y (0..191)
EraseMaskBombSprite:
    ldx TMP_X
    lda div7_table, x
    clc
    adc #PLAYFIELD_LEFT
    sta TMP_COL

    lda mod7_table, x
    tax
    lda shift_offset_16, x
    clc
    adc SRC_LO
    sta PTR2_LO
    lda SRC_HI
    adc #0
    sta PTR2_HI

    ldx #0
_embs_line:
    stx TEMP_VAL

    txa
    clc
    adc TMP_Y
    cmp #FLOOR_Y
    bcs _embs_skip_line  ; Never erase FLOOR_Y or past it!
    tay
    lda hgr_lo, y
    sta PTR_LO
    lda hgr_hi, y
    clc
    adc DRAW_PAGE_OFF
    sta PTR_HI

    lda TEMP_VAL
    asl                 ; line * 2
    tay

    lda (PTR2_LO), y
    eor #$7F
    ora #$80
    sta TMP_BYTE

    iny
    lda (PTR2_LO), y
    eor #$7F
    ora #$80
    sta TMP_SHIFT

    ldy TMP_COL
    lda (PTR_LO), y
    and TMP_BYTE
    sta (PTR_LO), y

    iny
    lda (PTR_LO), y
    and TMP_SHIFT
    sta (PTR_LO), y

_embs_skip_line:
    ldx TEMP_VAL
    inx
    cpx #8
    bcc _embs_line
    rts

; ===================================================================
; FAST FONT & STRING PRINTER
; ===================================================================

; Print a single character at (TMP_COL, TMP_Y)
; Character in Accumulator
DrawChar:
    cmp #' '
    bne +
    ; Blank space: clear 8 scanlines at TMP_COL
    ldx #0
-   txa
    clc
    adc TMP_Y
    tay
    lda hgr_lo, y
    sta PTR_LO
    lda hgr_hi, y
    clc
    adc DRAW_PAGE_OFF
    sta PTR_HI
    ldy TMP_COL
    lda #0
    sta (PTR_LO), y
    inx
    cpx #8
    bcc -
    rts

+   ; Find character glyph address in font_glyphs
    jsr GetFontPtr      ; Computes 16-bit SRC_LO / SRC_HI

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
    lda (SRC_LO), y
    ldy TMP_COL
    sta (PTR_LO), y

    inx
    cpx #8
    bcc _dc_line
    rts

GetFontPtr:
    cmp #'0'
    bcc _gfo_spec
    cmp #'9'+1
    bcs _gfo_alpha
    ; '0'..'9' (indices 0..9)
    sec
    sbc #'0'
    jmp _gfo_calc_ptr
_gfo_alpha:
    cmp #'A'
    bcc _gfo_spec
    cmp #'Z'+1
    bcc _gfo_upper
    ; Check lowercase 'a'..'z' (except 'y' which is upside-down Y!)
    cmp #'y'
    beq _gfo_spec
    cmp #'a'
    bcc _gfo_spec
    cmp #'z'+1
    bcs _gfo_spec
    sec
    sbc #'a'
    clc
    adc #10
    jmp _gfo_calc_ptr
_gfo_upper:
    ; 'A'..'Z' (indices 10..35)
    sec
    sbc #'A'
    clc
    adc #10
    jmp _gfo_calc_ptr
_gfo_spec:
    cmp #'<'
    bne +
    lda #36
    bne _gfo_calc_ptr
+   cmp #'>'
    bne +
    lda #37
    bne _gfo_calc_ptr
+   cmp #'='
    bne +
    lda #38
    bne _gfo_calc_ptr
+   cmp #'-'
    bne +
    lda #39
    bne _gfo_calc_ptr
+   cmp #':'
    bne +
    lda #40
    bne _gfo_calc_ptr
+   cmp #'/'
    bne +
    lda #41
    bne _gfo_calc_ptr
+   cmp #'*'
    bne +
    lda #42
    bne _gfo_calc_ptr
+   cmp #'?'
    bne +
    lda #43
    bne _gfo_calc_ptr
+   cmp #'y'            ; Upside down Y
    bne +
    lda #45
    bne _gfo_calc_ptr
+   cmp #$27            ; ''' (apostrophe, index 46)
    bne +
    lda #46
    bne _gfo_calc_ptr
+   lda #44             ; Default space
_gfo_calc_ptr:
    sta TEMP_VAL
    lda #0
    sta SRC_HI
    lda TEMP_VAL
    cmp #32
    bcc +
    inc SRC_HI          ; High byte = 1 if index >= 32!
+   lda TEMP_VAL
    asl
    asl
    asl                 ; Low byte = (index * 8) & $FF
    clc
    adc #<font_glyphs
    sta SRC_LO
    lda SRC_HI
    adc #>font_glyphs
    sta SRC_HI
    rts

; Print 0-terminated string at (TMP_COL, TMP_Y)
DrawString:
    ldy #0
_ds_loop:
    lda (STR_PTR_LO), y
    beq _ds_done
    tya
    pha
    lda (STR_PTR_LO), y
    jsr DrawChar
    inc TMP_COL
    pla
    tay
    iny
    jmp _ds_loop
_ds_done:
    rts

; Print 4 BCD digits at (TMP_COL, TMP_Y)
; A = BCD high, X = BCD low
Print4Digits:
    sta BCD_VAL_HI
    stx BCD_VAL_LO

    ; Digit 0 (Thousands)
    lda BCD_VAL_HI
    lsr
    lsr
    lsr
    lsr
    clc
    adc #'0'
    jsr DrawChar
    inc TMP_COL

    ; Digit 1 (Hundreds)
    lda BCD_VAL_HI
    and #$0F
    clc
    adc #'0'
    jsr DrawChar
    inc TMP_COL

    ; Digit 2 (Tens)
    lda BCD_VAL_LO
    lsr
    lsr
    lsr
    lsr
    clc
    adc #'0'
    jsr DrawChar
    inc TMP_COL

    ; Digit 3 (Ones)
    lda BCD_VAL_LO
    and #$0F
    clc
    adc #'0'
    jsr DrawChar
    inc TMP_COL
    rts

; ===================================================================
; BUNKER / SHIELD MANAGEMENT (4 ERODIBLE BUNKERS)
; ===================================================================

InitBunkers:
    ldx #0
_ib_copy:
    lda bunker_template, x
    sta bunker_ram, x           ; Bunker 0
    sta bunker_ram + 64, x      ; Bunker 1
    sta bunker_ram + 128, x     ; Bunker 2
    sta bunker_ram + 192, x     ; Bunker 3
    inx
    cpx #64
    bcc _ib_copy
    rts

DrawBunkers:
    ldx #0              ; Scanline 0..15
_db_line:
    txa
    clc
    adc #BUNKER_Y
    tay
    lda hgr_lo, y
    sta PTR_LO
    lda hgr_hi, y
    clc
    adc DRAW_PAGE_OFF
    sta PTR_HI

    ; Bunker 0: Col 8..11 (offset x*4)
    txa
    asl
    asl
    tax
    ldy #8
    lda bunker_ram, x
    sta (PTR_LO), y
    iny
    lda bunker_ram + 1, x
    sta (PTR_LO), y
    iny
    lda bunker_ram + 2, x
    sta (PTR_LO), y
    iny
    lda bunker_ram + 3, x
    sta (PTR_LO), y

    ; Bunker 1: Col 15..18
    ldy #15
    lda bunker_ram + 64, x
    sta (PTR_LO), y
    iny
    lda bunker_ram + 65, x
    sta (PTR_LO), y
    iny
    lda bunker_ram + 66, x
    sta (PTR_LO), y
    iny
    lda bunker_ram + 67, x
    sta (PTR_LO), y

    ; Bunker 2: Col 21..24
    ldy #21
    lda bunker_ram + 128, x
    sta (PTR_LO), y
    iny
    lda bunker_ram + 129, x
    sta (PTR_LO), y
    iny
    lda bunker_ram + 130, x
    sta (PTR_LO), y
    iny
    lda bunker_ram + 131, x
    sta (PTR_LO), y

    ; Bunker 3: Col 27..30
    ldy #27
    lda bunker_ram + 192, x
    sta (PTR_LO), y
    iny
    lda bunker_ram + 193, x
    sta (PTR_LO), y
    iny
    lda bunker_ram + 194, x
    sta (PTR_LO), y
    iny
    lda bunker_ram + 195, x
    sta (PTR_LO), y

    ; Restore line index X (x / 4)
    txa
    lsr
    lsr
    tax
    inx
    cpx #16
    bcs _db_done
    jmp _db_line
_db_done:
    rts

; ===================================================================
; BUNKER COLLISION & CRATER EROSION ENGINE (AUTHENTIC 1978 CRATERS)
; ===================================================================
; Two primary entry points:
;   1. CheckPlayerShotBunker: shot moving UP from below
;   2. CheckAlienBombBunker: bomb moving DOWN from above
; Inputs:
;   TMP_X = X coordinate (0..223)
;   TMP_Y = Y coordinate (0..191)
; Output:
;   Carry = 1 if hit & eroded bunker, Carry = 0 if missed / hole

CheckPlayerShotBunker:
    lda #0
    sta bunker_collision_dir
    jmp DoBunkerCollision

CheckAlienBombBunker:
    lda #1
    sta bunker_collision_dir
    jmp DoBunkerCollision

CheckBunkerCollision:
    ; Legacy fallback entry point defaults to player shot
    lda #0
    sta bunker_collision_dir

DoBunkerCollision:
    lda TMP_Y
    cmp #BUNKER_Y
    bcc _dbc_miss
    cmp #BUNKER_Y + 16
    bcs _dbc_miss

    ; Bunker 0 (X=28..55)
    lda TMP_X
    cmp #28
    bcc _dbc_miss
    cmp #56
    bcs +
    sec
    sbc #28
    ldy #0              ; Bunker 0 base offset
    jmp _dbc_calc
+
    ; Bunker 1 (X=77..104)
    cmp #77
    bcc _dbc_miss
    cmp #105
    bcs +
    sec
    sbc #77
    ldy #64             ; Bunker 1 base offset
    jmp _dbc_calc
+
    ; Bunker 2 (X=119..146)
    cmp #119
    bcc _dbc_miss
    cmp #147
    bcs +
    sec
    sbc #119
    ldy #128            ; Bunker 2 base offset
    jmp _dbc_calc
+
    ; Bunker 3 (X=161..188)
    cmp #161
    bcc _dbc_miss
    cmp #189
    bcs _dbc_miss
    sec
    sbc #161
    ldy #192            ; Bunker 3 base offset
    jmp _dbc_calc

_dbc_miss:
    clc                 ; Miss!
    rts

_dbc_calc:
    sty bunker_curr_base
    sta bunker_local_x

    ; local_x * 4 for table indexing (0..108)
    asl
    asl
    sta bunker_x_times_4

    ; Calculate local_y = TMP_Y - BUNKER_Y (0..15)
    lda TMP_Y
    sec
    sbc #BUNKER_Y
    sta bunker_local_y

    ; Calculate bunker_ram row base = bunker_curr_base + (local_y * 4)
    asl
    asl
    clc
    adc bunker_curr_base
    tax

    ; HIT TEST: check if any of the 3 pixels at impact point are solid
    ldy bunker_x_times_4
    lda bunker_ram + 0, x
    and bunker_hit_mask_table + 0, y
    bne _dbc_hit
    lda bunker_ram + 1, x
    and bunker_hit_mask_table + 1, y
    bne _dbc_hit
    lda bunker_ram + 2, x
    and bunker_hit_mask_table + 2, y
    bne _dbc_hit
    lda bunker_ram + 3, x
    and bunker_hit_mask_table + 3, y
    bne _dbc_hit

    ; All bits zero -> hole! Shot passes through!
    clc
    rts

_dbc_hit:
    ; HIT! Apply authentic directional crater erosion:
    lda bunker_collision_dir
    bne _dbc_hit_bomb

    ; -------------------------------------------------------------
    ; PLAYER SHOT (moving UP):
    ; Crater shape (deep upward indentation):
    ;   local_y - 2: width 1
    ;   local_y - 1: width 3
    ;   local_y    : width 5 (center)
    ;   local_y + 1: width 3
    ; -------------------------------------------------------------
    lda bunker_local_y
    sec
    sbc #2
    bmi +
    jsr ApplyCraterW1
+
    lda bunker_local_y
    sec
    sbc #1
    bmi +
    jsr ApplyCraterW3
+
    lda bunker_local_y
    jsr ApplyCraterW5

    lda bunker_local_y
    clc
    adc #1
    cmp #16
    bcs +
    jsr ApplyCraterW3
+
    jmp _dbc_redraw

_dbc_hit_bomb:
    ; -------------------------------------------------------------
    ; ALIEN BOMB (moving DOWN):
    ; Crater shape (deep downward indentation):
    ;   local_y - 1: width 3
    ;   local_y    : width 5 (center)
    ;   local_y + 1: width 3
    ;   local_y + 2: width 1
    ; -------------------------------------------------------------
    lda bunker_local_y
    sec
    sbc #1
    bmi +
    jsr ApplyCraterW3
+
    lda bunker_local_y
    jsr ApplyCraterW5

    lda bunker_local_y
    clc
    adc #1
    cmp #16
    bcs +
    jsr ApplyCraterW3
+
    lda bunker_local_y
    clc
    adc #2
    cmp #16
    bcs +
    jsr ApplyCraterW1
+

_dbc_redraw:
    ; Redraw bunkers immediately on both buffers
    lda #0
    sta DRAW_PAGE_OFF
    jsr DrawBunkers
    lda #$20
    sta DRAW_PAGE_OFF
    jsr DrawBunkers
    jsr RestoreDrawPage

    sec                 ; Hit!
    rts

; Crater helper subroutines: scanline in A (0..15)
ApplyCraterW5:
    asl
    asl
    clc
    adc bunker_curr_base
    tax
    ldy bunker_x_times_4
    lda bunker_ram + 0, x
    and bunker_crater_w5_table + 0, y
    sta bunker_ram + 0, x
    lda bunker_ram + 1, x
    and bunker_crater_w5_table + 1, y
    sta bunker_ram + 1, x
    lda bunker_ram + 2, x
    and bunker_crater_w5_table + 2, y
    sta bunker_ram + 2, x
    lda bunker_ram + 3, x
    and bunker_crater_w5_table + 3, y
    sta bunker_ram + 3, x
    rts

ApplyCraterW3:
    asl
    asl
    clc
    adc bunker_curr_base
    tax
    ldy bunker_x_times_4
    lda bunker_ram + 0, x
    and bunker_crater_w3_table + 0, y
    sta bunker_ram + 0, x
    lda bunker_ram + 1, x
    and bunker_crater_w3_table + 1, y
    sta bunker_ram + 1, x
    lda bunker_ram + 2, x
    and bunker_crater_w3_table + 2, y
    sta bunker_ram + 2, x
    lda bunker_ram + 3, x
    and bunker_crater_w3_table + 3, y
    sta bunker_ram + 3, x
    rts

ApplyCraterW1:
    asl
    asl
    clc
    adc bunker_curr_base
    tax
    ldy bunker_x_times_4
    lda bunker_ram + 0, x
    and bunker_crater_w1_table + 0, y
    sta bunker_ram + 0, x
    lda bunker_ram + 1, x
    and bunker_crater_w1_table + 1, y
    sta bunker_ram + 1, x
    lda bunker_ram + 2, x
    and bunker_crater_w1_table + 2, y
    sta bunker_ram + 2, x
    lda bunker_ram + 3, x
    and bunker_crater_w1_table + 3, y
    sta bunker_ram + 3, x
    rts

; ===================================================================
; ErodeBunkersByAlien
; Carves out the exact sprite shape of an alien from bunker_ram
; when the alien reaches bunker altitude (scanlines 140..155).
; Inputs:
;   TMP_X, TMP_Y = Alien coordinates
;   PTR2_LO, PTR2_HI = Pre-shifted 24-byte alien sprite
; ===================================================================
ErodeBunkersByAlien:
    lda TMP_Y
    cmp #BUNKER_Y + 16   ; 156
    bcc +
    rts                 ; Alien entirely below bunkers
+   clc
    adc #7
    cmp #BUNKER_Y       ; 140
    bcs +
    rts                 ; Alien entirely above bunkers
+

    ; Compute left screen column (0..39) of the 3-byte alien sprite
    ldx TMP_X
    lda div7_table, x
    clc
    adc #PLAYFIELD_LEFT
    sta ebba_col0
    clc
    adc #1
    sta ebba_col1
    clc
    adc #1
    sta ebba_col2

    ; Loop through alien's 8 scanlines (L = 0..7)
    ldx #0
_ebba_line_loop:
    stx ebba_line_idx

    txa
    clc
    adc TMP_Y
    cmp #BUNKER_Y       ; 140
    bcc _ebba_next_line
    cmp #BUNKER_Y + 16   ; 156
    bcs _ebba_next_line

    sec
    sbc #BUNKER_Y
    asl
    asl
    sta ebba_local_y4   ; local_y * 4 (0..60)

    ; Alien sprite byte offset for line L: L * 3
    lda ebba_line_idx
    asl
    clc
    adc ebba_line_idx
    tay

    ; Byte 0 at ebba_col0
    lda (PTR2_LO), y
    beq +
    sta ebba_sprite_byte
    lda ebba_col0
    jsr ErodeBunkerAtCol
+
    ; Byte 1 at ebba_col1
    lda ebba_line_idx
    asl
    clc
    adc ebba_line_idx
    tay
    iny
    lda (PTR2_LO), y
    beq +
    sta ebba_sprite_byte
    lda ebba_col1
    jsr ErodeBunkerAtCol
+
    ; Byte 2 at ebba_col2
    lda ebba_line_idx
    asl
    clc
    adc ebba_line_idx
    tay
    iny
    iny
    lda (PTR2_LO), y
    beq +
    sta ebba_sprite_byte
    lda ebba_col2
    jsr ErodeBunkerAtCol
+

_ebba_next_line:
    ldx ebba_line_idx
    inx
    cpx #8
    bcc _ebba_line_loop

_ebba_done:
    rts

ErodeBunkerAtCol:
    cmp #40
    bcs _ebac_ret
    tay
    lda col_to_bunker_table, y
    cmp #$FF
    beq _ebac_ret

    clc
    adc ebba_local_y4
    tax

    ; bunker_ram[x] &= ~(ebba_sprite_byte)
    lda ebba_sprite_byte
    eor #$7F
    and bunker_ram, x
    sta bunker_ram, x

_ebac_ret:
    rts

; Redraw green floor baseline
RedrawFloorLine:
    ldy #FLOOR_Y
    lda hgr_lo, y
    sta PTR_LO
    lda hgr_hi, y
    clc
    adc DRAW_PAGE_OFF
    sta PTR_HI
    lda #$7F
    ldy #4
-   sta (PTR_LO), y
    iny
    cpy #36
    bcc -
    rts

; ===================================================================
; STATIC PLAYFIELD RENDERING (HUD, FLOOR, SHIELDS)
; ===================================================================
DrawStaticPlayfield:
    ; Draw Top Score Headers
    lda #<str_score_head
    sta STR_PTR_LO
    lda #>str_score_head
    sta STR_PTR_HI
    lda #4              ; Col 4
    sta TMP_COL
    lda #2              ; Scanline 2
    sta TMP_Y
    jsr DrawString

    ; Draw Scores: Player 1 (Col 6), High Score (Col 18), Player 2 (Col 30)
    lda #6
    sta TMP_COL
    lda #11
    sta TMP_Y
    lda score_p1_hi
    ldx score_p1_lo
    jsr Print4Digits

    lda #18
    sta TMP_COL
    lda #11
    sta TMP_Y
    lda score_hi_hi
    ldx score_hi_lo
    jsr Print4Digits

    lda #30
    sta TMP_COL
    lda #11
    sta TMP_Y
    lda score_p2_hi
    ldx score_p2_lo
    jsr Print4Digits

    ; Draw 4 Bunkers
    jsr DrawBunkers

    ; Draw Green Floor Line (Scanline 174 across all 224 pixels: bytes 4..35)
    ldy #FLOOR_Y
    lda hgr_lo, y
    sta PTR_LO
    lda hgr_hi, y
    clc
    adc DRAW_PAGE_OFF
    sta PTR_HI
    lda #$7F            ; 7 green pixels per byte
    ldy #4
_ds_floor:
    sta (PTR_LO), y
    iny
    cpy #36
    bcc _ds_floor

    ; Draw Bottom Status: Lives Cannon icon + CREDIT
    jsr DrawLivesIndicator

    ; Draw mini reserve cannon icon at Col 6
    lda #<spr_player
    sta SRC_LO
    lda #>spr_player
    sta SRC_HI
    lda #14
    sta TMP_X
    lda #178
    sta TMP_Y
    jsr DrawSprite16

    ; Draw CREDIT label & value at Col 26
    lda #<str_credit_lbl
    sta STR_PTR_LO
    lda #>str_credit_lbl
    sta STR_PTR_HI
    lda #26
    sta TMP_COL
    lda #178
    sta TMP_Y
    jsr DrawString

    ; Print credit digits
    lda #33
    sta TMP_COL
    lda #178
    sta TMP_Y
    lda credits
    lsr
    lsr
    lsr
    lsr
    clc
    adc #'0'
    jsr DrawChar
    inc TMP_COL
    lda credits
    and #$0F
    clc
    adc #'0'
    jsr DrawChar
    rts

DrawLivesIndicator:
    lda #4
    sta TMP_COL
    lda #178
    sta TMP_Y
    lda active_player
    bne _dli_p2
    lda lives_p1
    jmp _dli_set
_dli_p2:
    lda lives_p2
_dli_set:
    sta lives
    clc
    adc #'0'
    jsr DrawChar
    rts

; ===================================================================
; ATTRACT MODE (AUTHENTIC TITLE SCREEN & ALIEN 'Y' ANIMATION)
; ===================================================================
EnterAttractMode:
    lda #0
    sta game_mode
    sta attract_state
    sta attract_timer
    sta attract_timer+1
    sta attract_frame
    lda #255            ; 255 = no alien drawn yet
    sta attract_alien_x
    sta attract_x_p1
    sta attract_x_p2
    lda #255            ; 255 = no Y drawn yet
    sta attract_y_col
    sta attract_y_col_prev
    lda #'y'
    sta attract_y_char

    ; Clear both screens and draw attract title
    jsr ClearPage1
    jsr ClearPage2

    ; Draw attract static text on Page 1
    lda #0
    sta DRAW_PAGE_OFF
    jsr DrawAttractStaticText

    ; Draw attract static text on Page 2
    lda #$20
    sta DRAW_PAGE_OFF
    jsr DrawAttractStaticText

    ; Show Page 1
    bit TXTPAGE1
    lda #0
    sta CURR_PAGE
    lda #$20
    sta DRAW_PAGE_OFF

AttractLoop:
    jsr CheckCoinAndStart

    ; Blink INSERT COIN if no credit, or keep static if credit >= 1
    jsr UpdateAttractBlinkCoin

    ; Animate attract mode
    jsr UpdateAttractAnimation

    jsr WaitFrameSync
    jsr FlipBuffers
    jmp AttractLoop

UpdateAttractBlinkCoin:
    lda credits
    bne _uabc_static
    ; Credits = 0: blink prompt based on timer bit 5
    lda attract_timer
    and #$20
    bne _uabc_show
    ; Hide (draw blank of 19 spaces)
    lda #<str_blank_19
    sta STR_PTR_LO
    lda #>str_blank_19
    sta STR_PTR_HI
    jmp _uabc_draw
_uabc_static:
_uabc_show:
    lda #<str_insert_coin
    sta STR_PTR_LO
    lda #>str_insert_coin
    sta STR_PTR_HI
_uabc_draw:
    lda #10             ; Centered for 19-char string (columns 10..28)
    sta TMP_COL
    lda #146
    sta TMP_Y
    lda CURR_PAGE
    bne +
    lda #$20
    sta DRAW_PAGE_OFF
    jsr DrawString
    jsr RestoreDrawPage
    rts
+   lda #0
    sta DRAW_PAGE_OFF
    jsr DrawString
    jsr RestoreDrawPage
    rts

DrawAttractStaticText:
    ; Score Header
    lda #<str_score_head
    sta STR_PTR_LO
    lda #>str_score_head
    sta STR_PTR_HI
    lda #4
    sta TMP_COL
    lda #2
    sta TMP_Y
    jsr DrawString

    ; Scores
    lda #6
    sta TMP_COL
    lda #11
    sta TMP_Y
    lda score_p1_hi
    ldx score_p1_lo
    jsr Print4Digits

    lda #18
    sta TMP_COL
    lda #11
    sta TMP_Y
    lda score_hi_hi
    ldx score_hi_lo
    jsr Print4Digits

    lda #30
    sta TMP_COL
    lda #11
    sta TMP_Y
    lda score_p2_hi
    ldx score_p2_lo
    jsr Print4Digits

    ; "PLAY"
    lda #<str_play_msg
    sta STR_PTR_LO
    lda #>str_play_msg
    sta STR_PTR_HI
    lda #18
    sta TMP_COL
    lda #26
    sta TMP_Y
    jsr DrawString

    ; "SPACE  INVADERS"
    lda #<str_space_inv
    sta STR_PTR_LO
    lda #>str_space_inv
    sta STR_PTR_HI
    lda #12
    sta TMP_COL
    lda #38
    sta TMP_Y
    jsr DrawString

    ; "*SCORE ADVANCE TABLE*"
    lda #<str_score_adv
    sta STR_PTR_LO
    lda #>str_score_adv
    sta STR_PTR_HI
    lda #9
    sta TMP_COL
    lda #56
    sta TMP_Y
    jsr DrawString

    ; "=? MYSTERY" + Saucer icon
    lda #<str_mystery
    sta STR_PTR_LO
    lda #>str_mystery
    sta STR_PTR_HI
    lda #15
    sta TMP_COL
    lda #74
    sta TMP_Y
    jsr DrawString

    lda #<spr_saucer
    sta SRC_LO
    lda #>spr_saucer
    sta SRC_HI
    lda #49             ; X = 49
    sta TMP_X
    lda #74
    sta TMP_Y
    jsr DrawSprite16

    ; "=30 POINTS" + Squid icon
    lda #<str_30_pts
    sta STR_PTR_LO
    lda #>str_30_pts
    sta STR_PTR_HI
    lda #15
    sta TMP_COL
    lda #90
    sta TMP_Y
    jsr DrawString

    lda #<spr_squid_f0
    sta SRC_LO
    lda #>spr_squid_f0
    sta SRC_HI
    lda #49
    sta TMP_X
    lda #90
    sta TMP_Y
    jsr DrawSprite16

    ; "=20 POINTS" + Crab icon
    lda #<str_20_pts
    sta STR_PTR_LO
    lda #>str_20_pts
    sta STR_PTR_HI
    lda #15
    sta TMP_COL
    lda #106
    sta TMP_Y
    jsr DrawString

    lda #<spr_crab_f0
    sta SRC_LO
    lda #>spr_crab_f0
    sta SRC_HI
    lda #49
    sta TMP_X
    lda #106
    sta TMP_Y
    jsr DrawSprite16

    ; "=10 POINTS" + Octopus icon
    lda #<str_10_pts
    sta STR_PTR_LO
    lda #>str_10_pts
    sta STR_PTR_HI
    lda #15
    sta TMP_COL
    lda #122
    sta TMP_Y
    jsr DrawString

    lda #<spr_octo_f0
    sta SRC_LO
    lda #>spr_octo_f0
    sta SRC_HI
    lda #49
    sta TMP_X
    lda #122
    sta TMP_Y
    jsr DrawSprite16

    ; "TAPE 'C' FOR CREDIT"
    lda #<str_insert_coin
    sta STR_PTR_LO
    lda #>str_insert_coin
    sta STR_PTR_HI
    lda #10             ; Centered for 19-char string (columns 10..28)
    sta TMP_COL
    lda #146
    sta TMP_Y
    jsr DrawString

    ; CREDIT status at bottom right (Col 26..34, matching gameplay)
    lda #<str_credit_lbl
    sta STR_PTR_LO
    lda #>str_credit_lbl
    sta STR_PTR_HI
    lda #26
    sta TMP_COL
    lda #178
    sta TMP_Y
    jsr DrawString

    lda #33
    sta TMP_COL
    lda #178
    sta TMP_Y
    lda credits
    lsr
    lsr
    lsr
    lsr
    clc
    adc #'0'
    jsr DrawChar
    inc TMP_COL
    lda credits
    and #$0F
    clc
    adc #'0'
    jsr DrawChar
    rts

; Authentic 1978 Alien Upside-down 'Y' Animation in Attract Mode
UpdateAttractAnimation:
    inc attract_timer
    bne +
    inc attract_timer+1
+
    ; Animate alien legs every 4 frames
    lda attract_timer
    lsr
    lsr
    and #1
    sta attract_frame

    ; Erase alien sprite from previous frame on current back buffer
    lda CURR_PAGE
    bne _uaa_er_p1
    ; Drawing on Page 2, so erase what was drawn on Page 2
    lda attract_x_p2
    cmp #255
    beq _uaa_fsm
    sta TMP_X
    lda #26
    sta TMP_Y
    jsr EraseSprite16
    jmp _uaa_fsm

_uaa_er_p1:
    ; Drawing on Page 1, so erase what was drawn on Page 1
    lda attract_x_p1
    cmp #255
    beq _uaa_fsm
    sta TMP_X
    lda #26
    sta TMP_Y
    jsr EraseSprite16

_uaa_fsm:
    lda attract_state
    bne _att_st1

    ; --- STATE 0: Initial pause showing "PLAy" with upside-down 'y' ---
    lda attract_timer
    cmp #90             ; ~1.5 sec pause
    bcs _att_s0_trans
    rts
_att_s0_trans:
    lda #0
    sta attract_timer
    sta attract_timer+1
    lda #1
    sta attract_state
    lda #252            ; Start from off-screen right (X=252 -> Col 40)
    sta attract_alien_x
    rts

_att_st1:
    ; --- STATE 1: Plain Squid alien walks left towards 'y' (252 -> 119) ---
    cmp #1
    bne _att_st2
    dec attract_alien_x
    lda attract_alien_x
    cmp #119
    bcs _att_draw_st1

    ; Reached 'y'! Transition to State 2: alien will pull y rightward
    lda #2
    sta attract_state
    lda #119            ; Start state 2 at x=119
    sta attract_alien_x

    ; Erase 'y' from text on BOTH buffers (it is now part of the composite sprite!)
    lda #21
    sta TMP_COL
    lda #26
    sta TMP_Y
    lda #0
    sta DRAW_PAGE_OFF
    lda #' '
    jsr DrawChar
    lda #$20
    sta DRAW_PAGE_OFF
    lda #' '
    jsr DrawChar
    jsr RestoreDrawPage
    jmp _att_draw_st2

_att_draw_st1:
    ; Draw normal Squid alien marching left (no Y attached here)
    lda attract_frame
    bne +
    lda #<spr_squid_f0
    sta SRC_LO
    lda #>spr_squid_f0
    sta SRC_HI
    jmp _att_draw_alien
+   lda #<spr_squid_f1
    sta SRC_LO
    lda #>spr_squid_f1
    sta SRC_HI
    jmp _att_draw_alien

_att_st2:
    ; --- STATE 2: Alien pulls inverted 'y' rightward off-screen (119 -> 252) ---
    cmp #2
    bne _att_st3

    inc attract_alien_x
    lda attract_alien_x
    cmp #252            ; Completely off-screen right (col 40)
    bcc _att_draw_st2

    ; Alien and 'y' completely off-screen right!
    lda #3
    sta attract_state
    lda #0
    sta attract_timer
    sta attract_timer+1

    ; Cleanly erase residual sprite from Page 1
    lda attract_x_p1
    cmp #255
    beq +
    sta TMP_X
    lda #26
    sta TMP_Y
    lda #0
    sta DRAW_PAGE_OFF
    jsr EraseSprite16
+
    ; Cleanly erase residual sprite from Page 2
    lda attract_x_p2
    cmp #255
    beq +
    sta TMP_X
    lda #26
    sta TMP_Y
    lda #$20
    sta DRAW_PAGE_OFF
    jsr EraseSprite16
+
    jsr RestoreDrawPage
    lda #255
    sta attract_x_p1
    sta attract_x_p2
    sta attract_alien_x
    rts

_att_draw_st2:
    ; Draw composite sprite: Squid alien pulling upside-down 'y'
    lda attract_frame
    bne +
    lda #<spr_squid_pull_y_f0
    sta SRC_LO
    lda #>spr_squid_pull_y_f0
    sta SRC_HI
    jmp _att_draw_alien
+   lda #<spr_squid_pull_y_f1
    sta SRC_LO
    lda #>spr_squid_pull_y_f1
    sta SRC_HI
    jmp _att_draw_alien

_att_st3:
    ; --- STATE 3: Off-screen pause ~0.75 sec (turning 'Y' right-side up) ---
    cmp #3
    bne _att_st4
    lda attract_timer
    cmp #45
    bcs _att_s3_trans
    rts
_att_s3_trans:
    lda #4
    sta attract_state
    lda #252            ; Return from off-screen right (X=252 -> Col 40)
    sta attract_alien_x
    jmp _att_draw_st4

_att_st4:
    ; --- STATE 4: Alien pushes upright 'Y' leftward (252 -> 119) ---
    cmp #4
    bne _att_st5

    dec attract_alien_x
    lda attract_alien_x
    cmp #119
    bcs _att_draw_st4

    ; 'Y' reached column 21 (X=119)! Transition to State 5
    lda #5
    sta attract_state
    lda #0
    sta attract_timer
    sta attract_timer+1

    ; Erase alien sprite from BOTH buffers at X=119
    lda #119
    sta TMP_X
    lda #26
    sta TMP_Y
    lda #0
    sta DRAW_PAGE_OFF
    jsr EraseSprite16
    lda #$20
    sta DRAW_PAGE_OFF
    jsr EraseSprite16

    ; Draw permanent upright 'Y' at col 21 on BOTH buffers
    lda #21
    sta TMP_COL
    lda #26
    sta TMP_Y
    lda #0
    sta DRAW_PAGE_OFF
    lda #'Y'
    jsr DrawChar
    lda #$20
    sta DRAW_PAGE_OFF
    lda #'Y'
    jsr DrawChar

    jsr RestoreDrawPage
    lda #255
    sta attract_x_p1
    sta attract_x_p2
    sta attract_alien_x
    rts

_att_draw_st4:
    ; Draw composite sprite: Squid alien pushing upright 'Y'
    lda attract_frame
    bne +
    lda #<spr_squid_push_y_f0
    sta SRC_LO
    lda #>spr_squid_push_y_f0
    sta SRC_HI
    jmp _att_draw_alien
+   lda #<spr_squid_push_y_f1
    sta SRC_LO
    lda #>spr_squid_push_y_f1
    sta SRC_HI
    jmp _att_draw_alien

_att_st5:
    ; --- STATE 5: Pause on completed screen, then loop back ---
    ; 16-bit compare for 600 frames (~10 seconds)
    lda attract_timer+1
    cmp #>600
    bcc _att_ret
    bne _att_st5_reset
    lda attract_timer
    cmp #<600
    bcc _att_ret

_att_st5_reset:
    ; Loop back: Redraw upside-down 'y' on BOTH buffers and restart!
    lda #0
    sta attract_state
    sta attract_timer
    sta attract_timer+1
    lda #21
    sta TMP_COL
    lda #26
    sta TMP_Y
    lda #0
    sta DRAW_PAGE_OFF
    lda #'y'
    jsr DrawChar
    lda #$20
    sta DRAW_PAGE_OFF
    lda #'y'
    jsr DrawChar
    jsr RestoreDrawPage
    rts

_att_draw_alien:
    lda attract_alien_x
    sta TMP_X
    lda #26
    sta TMP_Y
    jsr DrawSprite16

    lda CURR_PAGE
    beq +
    lda attract_alien_x
    sta attract_x_p1
    rts
+   lda attract_alien_x
    sta attract_x_p2
    rts

_att_ret:
    rts

CheckCoinAndStart:
    lda KBD
    bpl _cca_check_btn  ; No key pressed

    bit KBDSTRB         ; Acknowledge key

    ; Check ESC ($9B) to quit cleanly to menu
    cmp #$9B
    bne +
    jmp QuitToMenu
+

    ; Check 'C' ($C3) or '5' ($B5) for Coin
    cmp #$C3            ; 'C'
    beq _cca_coin
    cmp #$E3            ; 'c'
    beq _cca_coin
    cmp #$B5            ; '5'
    beq _cca_coin

    ; Check '1' ($B1) or Enter ($8D) for 1-Player Start
    cmp #$B1            ; '1'
    beq _cca_start1
    cmp #$8D            ; Return / Enter
    beq _cca_start1

    ; Check '2' ($B2) for 2-Player Start
    cmp #$B2            ; '2'
    beq _cca_start2

_cca_check_btn:
    lda BTN1
    bmi _cca_coin

    lda BTN0
    bmi _cca_start1
    rts

_cca_coin:
    sed
    lda credits
    clc
    adc #1
    sta credits
    cld
    jsr PlayCoinSound

    lda #0
    sta DRAW_PAGE_OFF
    jsr UpdateCreditDisplay
    lda #$20
    sta DRAW_PAGE_OFF
    jsr UpdateCreditDisplay
    jsr RestoreDrawPage
    rts

_cca_start1:
    lda credits
    beq _cca_ignore     ; Cannot start without credits!

    sed
    sec
    sbc #1
    sta credits
    cld

    lda #1
    sta num_players
    lda #0
    sta active_player

    pla
    pla
    jmp StartGameplay

_cca_start2:
    lda credits
    cmp #2              ; Need at least 2 credits for 2 players
    bcc _cca_ignore     ; Not enough credits!

    sed
    sec
    sbc #2
    sta credits
    cld

    lda #2
    sta num_players
    lda #0
    sta active_player

    pla
    pla
    jmp StartGameplay

_cca_ignore:
    rts

UpdateCreditDisplay:
    lda #33
    sta TMP_COL
    lda #178
    sta TMP_Y
    lda credits
    lsr
    lsr
    lsr
    lsr
    clc
    adc #'0'
    jsr DrawChar
    inc TMP_COL
    lda credits
    and #$0F
    clc
    adc #'0'
    jsr DrawChar
    rts

; ===================================================================
; GAMEPLAY INITIALIZATION & MAIN GAME LOOP
; ===================================================================
StartGameplay:
    lda #1
    sta game_mode
    lda #3
    sta lives
    sta lives_p1
    sta lives_p2
    lda #1
    sta wave
    lda #0
    sta score_p1_lo
    sta score_p1_hi
    sta score_p2_lo
    sta score_p2_hi
    sta extra_life_awarded
    sta extra_life_awarded_p2
    sta p2_initialized

    jsr InitNewWave

GameLoop:
    jsr RestoreDrawPage
    jsr ErasePrevAlienBombs  ; 1. Erase previous frame's bombs using mask!
    jsr RestoreDrawPage
    jsr DrawBunkers          ; 2. Refresh bunkers cleanly from bunker_ram on back buffer!
    jsr RestoreDrawPage
    jsr UpdatePlayer         ; 3. Refresh player cannon cleanly on back buffer!
    jsr RestoreDrawPage

    lda player_alive
    beq _gl_frozen          ; If player dead/exploding, freeze all other game objects!

    jsr UpdatePlayerShot
    jsr RestoreDrawPage
    jsr UpdateAlienBombs     ; 4. Update bomb physics & draw active bombs!
    jsr RestoreDrawPage
    jsr UpdateAlienFleet
    jsr RestoreDrawPage
    jsr UpdateSaucer
    jsr RestoreDrawPage
    jsr UpdateExplosions
    jsr RestoreDrawPage

_gl_frozen:
    jsr WaitFrameSync
    jsr FlipBuffers

    lda aliens_remaining
    bne +
    inc wave
    jsr InitNewWave
    jmp GameLoop
+
    lda player_alive
    bne GameLoop            ; Normal gameplay

    lda player_exp_timer
    bne GameLoop            ; Still exploding

    ; Player death animation just finished!
    jsr HandlePlayerDeathRespawn
    jmp GameLoop

HandlePlayerDeathRespawn:
    ; 1. Erase death explosion sprite on BOTH Page 1 and Page 2 at current player_x
    lda player_x
    sta TMP_X
    lda #PLAYER_Y
    sta TMP_Y

    lda #0
    sta DRAW_PAGE_OFF
    jsr EraseSprite16

    lda #$20
    sta DRAW_PAGE_OFF
    jsr EraseSprite16

    ; 2. Clear and erase all active alien bombs on both pages
    ldx #0
_hpdr_bombs:
    stx BOMB_SLOT
    lda bomb_active_p1, x
    beq +
    txa
    asl
    asl
    sta TMP_BYTE
    lda bomb_prev_frame_p1, x
    and #3
    clc
    adc TMP_BYTE
    tay
    lda bomb_frames_lo, y
    sta SRC_LO
    lda bomb_frames_hi, y
    sta SRC_HI
    ldx BOMB_SLOT
    lda bomb_prev_x_p1, x
    sta TMP_X
    lda bomb_prev_y_p1, x
    sta TMP_Y
    lda #0
    sta DRAW_PAGE_OFF
    jsr EraseMaskBombSprite
+   ldx BOMB_SLOT
    lda bomb_active_p2, x
    beq +
    txa
    asl
    asl
    sta TMP_BYTE
    lda bomb_prev_frame_p2, x
    and #3
    clc
    adc TMP_BYTE
    tay
    lda bomb_frames_lo, y
    sta SRC_LO
    lda bomb_frames_hi, y
    sta SRC_HI
    ldx BOMB_SLOT
    lda bomb_prev_x_p2, x
    sta TMP_X
    lda bomb_prev_y_p2, x
    sta TMP_Y
    lda #$20
    sta DRAW_PAGE_OFF
    jsr EraseMaskBombSprite
+   ldx BOMB_SLOT
    lda #0
    sta bomb_active, x
    sta bomb_active_p1, x
    sta bomb_active_p2, x
    inx
    cpx #3
    bcc _hpdr_bombs

    ; 3. Clear player shot if active on either page
    lda shot_active_p1
    beq +
    lda shot_x_p1
    sta TMP_X
    lda shot_y_p1
    sta TMP_Y
    lda #0
    sta DRAW_PAGE_OFF
    jsr ErasePrevPlayerShot
    lda #0
    sta shot_active_p1
+   lda shot_active_p2
    beq +
    lda shot_x_p2
    sta TMP_X
    lda shot_y_p2
    sta TMP_Y
    lda #$20
    sta DRAW_PAGE_OFF
    jsr ErasePrevPlayerShot
    lda #0
    sta shot_active_p2
+   lda #0
    sta shot_active

    ; 4. Decrement lives for active player
    lda active_player
    bne _hpdr_dec_p2
    dec lives_p1
    lda lives_p1
    sta lives
    jmp _hpdr_upd_lives
_hpdr_dec_p2:
    dec lives_p2
    lda lives_p2
    sta lives

_hpdr_upd_lives:
    lda #0
    sta DRAW_PAGE_OFF
    jsr DrawLivesIndicator
    lda #$20
    sta DRAW_PAGE_OFF
    jsr DrawLivesIndicator
    jsr RestoreDrawPage

    ; 5. Check 2-player switching or Game Over
    lda num_players
    cmp #2
    beq _hpdr_2p_check

    ; Single player: check if lives == 0
    lda lives
    bne +
    jmp DoGameOver
+   jmp _hpdr_do_respawn

_hpdr_2p_check:
    ; Check if other player is still alive
    lda active_player
    eor #1
    beq _hpdr_other_is_p1

    ; Other player is P2 (current active_player was 0)
    lda lives_p2
    bne _hpdr_switch_player
    ; P2 is dead, check if current (P1) is also dead
    lda lives_p1
    bne _hpdr_alive_p1
    jmp DoGameOver
_hpdr_alive_p1:
    jmp _hpdr_do_respawn

_hpdr_other_is_p1:
    ; Other player is P1 (current active_player was 1)
    lda lives_p1
    bne _hpdr_switch_player
    ; P1 is dead, check if current (P2) is also dead
    lda lives_p2
    bne _hpdr_alive_p2
    jmp DoGameOver
_hpdr_alive_p2:
    jmp _hpdr_do_respawn

_hpdr_switch_player:
    ; 1. Save state of currently active player BEFORE changing active_player
    jsr SaveActivePlayerState

    ; 2. Switch active player (0 -> 1, 1 -> 0)
    lda active_player
    eor #1
    sta active_player

    ; 3. Check if switching to Player 2 (active_player == 1) and P2 not yet initialized
    cmp #1
    bne _hsp_restore
    lda p2_initialized
    bne _hsp_restore

    ; Player 2's very first turn!
    lda #1
    sta p2_initialized
    sta wave
    jsr InitNewWave
    rts

_hsp_restore:
    ; Restore saved state of newly active player and redraw screen
    jsr RestoreActivePlayerState
    jsr RedrawRestoredGameScreen
    rts

_hpdr_do_respawn:
    ; 6. Respawn player at X = 16 (arcade authentic $30-$20 = 16, far left)
    lda #16
    sta player_x
    sta player_x_p1
    sta player_x_p2

    lda #<spr_player
    sta SRC_LO
    lda #>spr_player
    sta SRC_HI
    lda #16
    sta TMP_X
    lda #PLAYER_Y
    sta TMP_Y

    lda #0
    sta DRAW_PAGE_OFF
    jsr DrawSprite16

    lda #$20
    sta DRAW_PAGE_OFF
    jsr DrawSprite16
    jsr RestoreDrawPage

    ; Brief pause before resuming action (~30 frames)
    ldx #30
-   jsr WaitFrameSync
    dex
    bne -

    lda #1
    sta player_alive
    rts

DoGameOver:
    ; Draw GAME OVER at top of playfield (Col 15, Y = 28) on Page 1
    lda #<str_game_over
    sta STR_PTR_LO
    lda #>str_game_over
    sta STR_PTR_HI
    lda #15
    sta TMP_COL
    lda #28
    sta TMP_Y
    lda #0
    sta DRAW_PAGE_OFF
    jsr DrawString

    ; Draw on Page 2
    lda #<str_game_over
    sta STR_PTR_LO
    lda #>str_game_over
    sta STR_PTR_HI
    lda #15
    sta TMP_COL
    lda #28
    sta TMP_Y
    lda #$20
    sta DRAW_PAGE_OFF
    jsr DrawString

    lda active_player
    bne _dgo_chk_p2
    lda score_p1_hi
    cmp score_hi_hi
    bcc _dgo_noscore
    bne _dgo_setscore_p1
    lda score_p1_lo
    cmp score_hi_lo
    bcc _dgo_noscore
_dgo_setscore_p1:
    lda score_p1_hi
    sta score_hi_hi
    lda score_p1_lo
    sta score_hi_lo
    jmp _dgo_noscore
_dgo_chk_p2:
    lda score_p2_hi
    cmp score_hi_hi
    bcc _dgo_noscore
    bne _dgo_setscore_p2
    lda score_p2_lo
    cmp score_hi_lo
    bcc _dgo_noscore
_dgo_setscore_p2:
    lda score_p2_hi
    sta score_hi_hi
    lda score_p2_lo
    sta score_hi_lo
_dgo_noscore:

    ldx #180
-   lda KBD
    cmp #$9B
    beq +
    jsr WaitFrameSync
    dex
    bne -

    jmp EnterAttractMode
+   jmp QuitToMenu

InitNewWave:
    lda #55
    sta aliens_remaining
    lda #0
    sta alien_cur_idx
    sta alien_step_sound
    sta fleet_edge_hit
    sta fleet_frame
    sta alien_exp_active
    sta saucer_active
    lda #1
    sta fleet_dir

    lda #24
    sta fleet_x
    lda #34
    ldx wave
    dex
    beq +
    txa
    asl
    asl                 ; wave * 4
    clc
    adc #34
    cmp #50
    bcc +
    lda #50
+   sta fleet_y

    ldx #0
    lda #1
-   sta alien_alive_table, x
    inx
    cpx #55
    bcc -

    lda #1
    sta player_alive
    lda #16
    sta player_x
    sta player_x_p1
    sta player_x_p2
    lda #0
    sta shot_active
    sta shot_active_p1
    sta shot_active_p2
    sta bomb_active
    sta bomb_active+1
    sta bomb_active+2
    sta bomb_active_p1
    sta bomb_active_p1+1
    sta bomb_active_p1+2
    sta bomb_active_p2
    sta bomb_active_p2+1
    sta bomb_active_p2+2
    sta bomb_prev_x_p1
    sta bomb_prev_x_p1+1
    sta bomb_prev_x_p1+2
    sta bomb_prev_y_p1
    sta bomb_prev_y_p1+1
    sta bomb_prev_y_p1+2
    sta bomb_prev_x_p2
    sta bomb_prev_x_p2+1
    sta bomb_prev_x_p2+2
    sta bomb_prev_y_p2
    sta bomb_prev_y_p2+1
    sta bomb_prev_y_p2+2
    sta saucer_active_p1
    sta saucer_active_p2

    ; Stagger initial bomb reload timers
    lda #80
    sta bomb_reload
    lda #48
    sta bomb_reload+1
    lda #112
    sta bomb_reload+2

    jsr InitBunkers

    lda #<600
    sta saucer_timer
    lda #>600
    sta saucer_timer+1

    jsr ClearPage1
    jsr ClearPage2

    lda #0
    sta DRAW_PAGE_OFF
    jsr DrawStaticPlayfield
    jsr DrawFullAlienFleet

    lda #$20
    sta DRAW_PAGE_OFF
    jsr DrawStaticPlayfield
    jsr DrawFullAlienFleet

    ; Draw Player Cannon initially on Page 1 and Page 2
    lda #<spr_player
    sta SRC_LO
    lda #>spr_player
    sta SRC_HI
    lda player_x
    sta TMP_X
    lda #PLAYER_Y
    sta TMP_Y
    lda #0
    sta DRAW_PAGE_OFF
    jsr DrawSprite16
    lda #$20
    sta DRAW_PAGE_OFF
    jsr DrawSprite16

    ; Display "PLAY PLAYER<1>" or "PLAY PLAYER<2>" prompt on both buffers
    lda active_player
    bne _inw_prompt_p2
    lda #<str_play_player1
    sta STR_PTR_LO
    lda #>str_play_player1
    sta STR_PTR_HI
    jmp _inw_prompt_draw
_inw_prompt_p2:
    lda #<str_play_player2
    sta STR_PTR_LO
    lda #>str_play_player2
    sta STR_PTR_HI
_inw_prompt_draw:
    lda #13
    sta TMP_COL
    lda #110
    sta TMP_Y
    lda #0
    sta DRAW_PAGE_OFF
    jsr DrawString

    lda active_player
    bne _inw_prompt_p2_b
    lda #<str_play_player1
    sta STR_PTR_LO
    lda #>str_play_player1
    sta STR_PTR_HI
    jmp _inw_prompt_draw_b
_inw_prompt_p2_b:
    lda #<str_play_player2
    sta STR_PTR_LO
    lda #>str_play_player2
    sta STR_PTR_HI
_inw_prompt_draw_b:
    lda #13
    sta TMP_COL
    lda #110
    sta TMP_Y
    lda #$20
    sta DRAW_PAGE_OFF
    jsr DrawString

    ; Show Page 1 during prompt pause
    bit TXTPAGE1
    lda #0
    sta CURR_PAGE

    ldx #150            ; ~2.5s pause (lengthened by +1.5s) so players know who plays & take controller
-   lda KBD
    cmp #$9B            ; ESC key
    bne +
    jmp QuitToMenu
+   jsr WaitFrameSync
    dex
    bne -
    bit KBDSTRB         ; Clear keyboard strobe so stray presses don't fire immediately

    ; Erase "PLAY PLAYER<1>" prompt cleanly on both buffers
    lda #<str_blank_14
    sta STR_PTR_LO
    lda #>str_blank_14
    sta STR_PTR_HI
    lda #13
    sta TMP_COL
    lda #110
    sta TMP_Y
    lda #0
    sta DRAW_PAGE_OFF
    jsr DrawString

    lda #<str_blank_14
    sta STR_PTR_LO
    lda #>str_blank_14
    sta STR_PTR_HI
    lda #13
    sta TMP_COL
    lda #110
    sta TMP_Y
    lda #$20
    sta DRAW_PAGE_OFF
    jsr DrawString

    ; Ready to enter GameLoop: Page 1 displayed, Page 2 back buffer
    bit TXTPAGE1
    lda #0
    sta CURR_PAGE
    lda #$20
    sta DRAW_PAGE_OFF
    rts

DrawFullAlienFleet:
    ldx #0
_dfaf_loop:
    stx alien_cur_idx
    lda alien_alive_table, x
    beq _dfaf_next
    jsr ComputeAlienCoords
    ldx alien_cur_idx
    lda TMP_X
    sta alien_old_x, x
    lda TMP_Y
    sta alien_old_y, x
    jsr DrawCurrentAlien
_dfaf_next:
    ldx alien_cur_idx
    inx
    cpx #55
    bcc _dfaf_loop
    lda #0
    sta alien_cur_idx
    rts

; ===================================================================
; 2-PLAYER STATE SAVE & RESTORE ROUTINES
; ===================================================================
SaveActivePlayerState:
    lda active_player
    bne _saps_p2
    lda #<p1_save_state
    sta PTR_LO
    lda #>p1_save_state
    sta PTR_HI
    jmp _saps_do
_saps_p2:
    lda #<p2_save_state
    sta PTR_LO
    lda #>p2_save_state
    sta PTR_HI

_saps_do:
    ldy #0
    lda wave
    sta (PTR_LO), y
    iny
    lda fleet_x
    sta (PTR_LO), y
    iny
    lda fleet_y
    sta (PTR_LO), y
    iny
    lda fleet_dir
    sta (PTR_LO), y
    iny
    lda fleet_edge_hit
    sta (PTR_LO), y
    iny
    lda fleet_frame
    sta (PTR_LO), y
    iny
    lda alien_cur_idx
    sta (PTR_LO), y
    iny
    lda aliens_remaining
    sta (PTR_LO), y
    iny
    lda alien_step_sound
    sta (PTR_LO), y
    iny
    lda plunger_ptr
    sta (PTR_LO), y
    iny
    lda squiggly_ptr
    sta (PTR_LO), y
    iny
    lda saucer_score_ptr
    sta (PTR_LO), y
    iny

    ; Save 55 bytes of alien_alive_table
    ldx #0
-   lda alien_alive_table, x
    sta (PTR_LO), y
    iny
    inx
    cpx #55
    bcc -

    ; Advance PTR_LO/PTR_HI by 67 so Y can index 0..255 for bunker_ram
    clc
    lda PTR_LO
    adc #67
    sta PTR_LO
    lda PTR_HI
    adc #0
    sta PTR_HI

    ldy #0
-   lda bunker_ram, y
    sta (PTR_LO), y
    iny
    bne -
    rts

RestoreActivePlayerState:
    lda active_player
    bne _raps_p2
    lda #<p1_save_state
    sta PTR_LO
    lda #>p1_save_state
    sta PTR_HI
    jmp _raps_do
_raps_p2:
    lda #<p2_save_state
    sta PTR_LO
    lda #>p2_save_state
    sta PTR_HI

_raps_do:
    ldy #0
    lda (PTR_LO), y
    sta wave
    iny
    lda (PTR_LO), y
    sta fleet_x
    iny
    lda (PTR_LO), y
    sta fleet_y
    iny
    lda (PTR_LO), y
    sta fleet_dir
    iny
    lda (PTR_LO), y
    sta fleet_edge_hit
    iny
    lda (PTR_LO), y
    sta fleet_frame
    iny
    lda (PTR_LO), y
    sta alien_cur_idx
    iny
    lda (PTR_LO), y
    sta aliens_remaining
    iny
    lda (PTR_LO), y
    sta alien_step_sound
    iny
    lda (PTR_LO), y
    sta plunger_ptr
    iny
    lda (PTR_LO), y
    sta squiggly_ptr
    iny
    lda (PTR_LO), y
    sta saucer_score_ptr
    iny

    ; Restore 55 bytes of alien_alive_table
    ldx #0
-   lda (PTR_LO), y
    sta alien_alive_table, x
    iny
    inx
    cpx #55
    bcc -

    clc
    lda PTR_LO
    adc #67
    sta PTR_LO
    lda PTR_HI
    adc #0
    sta PTR_HI

    ldy #0
-   lda (PTR_LO), y
    sta bunker_ram, y
    iny
    bne -
    rts

RedrawRestoredGameScreen:
    lda alien_cur_idx
    pha                 ; Preserve alien_cur_idx across fleet drawing

    lda #1
    sta player_alive
    lda #16
    sta player_x
    sta player_x_p1
    sta player_x_p2
    lda #0
    sta shot_active
    sta shot_active_p1
    sta shot_active_p2
    sta bomb_active
    sta bomb_active+1
    sta bomb_active+2
    sta bomb_active_p1
    sta bomb_active_p1+1
    sta bomb_active_p1+2
    sta bomb_active_p2
    sta bomb_active_p2+1
    sta bomb_active_p2+2
    sta bomb_prev_x_p1
    sta bomb_prev_x_p1+1
    sta bomb_prev_x_p1+2
    sta bomb_prev_y_p1
    sta bomb_prev_y_p1+1
    sta bomb_prev_y_p1+2
    sta bomb_prev_x_p2
    sta bomb_prev_x_p2+1
    sta bomb_prev_x_p2+2
    sta bomb_prev_y_p2
    sta bomb_prev_y_p2+1
    sta bomb_prev_y_p2+2
    sta saucer_active
    sta saucer_active_p1
    sta saucer_active_p2
    sta alien_exp_active

    lda #80
    sta bomb_reload
    lda #48
    sta bomb_reload+1
    lda #112
    sta bomb_reload+2
    lda #<600
    sta saucer_timer
    lda #>600
    sta saucer_timer+1

    jsr ClearPage1
    jsr ClearPage2

    lda #0
    sta DRAW_PAGE_OFF
    jsr DrawStaticPlayfield
    jsr DrawFullAlienFleet

    lda #$20
    sta DRAW_PAGE_OFF
    jsr DrawStaticPlayfield
    jsr DrawFullAlienFleet

    ; Restore preserved alien_cur_idx after DrawFullAlienFleet reset it
    pla
    sta alien_cur_idx

    ; Draw Player Cannon on Page 1 and Page 2
    lda #<spr_player
    sta SRC_LO
    lda #>spr_player
    sta SRC_HI
    lda player_x
    sta TMP_X
    lda #PLAYER_Y
    sta TMP_Y
    lda #0
    sta DRAW_PAGE_OFF
    jsr DrawSprite16
    lda #$20
    sta DRAW_PAGE_OFF
    jsr DrawSprite16

    ; Display "PLAY PLAYER<1>" or "PLAY PLAYER<2>" prompt on both buffers
    lda active_player
    bne _rrg_prompt_p2
    lda #<str_play_player1
    sta STR_PTR_LO
    lda #>str_play_player1
    sta STR_PTR_HI
    jmp _rrg_prompt_draw
_rrg_prompt_p2:
    lda #<str_play_player2
    sta STR_PTR_LO
    lda #>str_play_player2
    sta STR_PTR_HI
_rrg_prompt_draw:
    lda #13
    sta TMP_COL
    lda #110
    sta TMP_Y
    lda #0
    sta DRAW_PAGE_OFF
    jsr DrawString

    lda active_player
    bne _rrg_prompt_p2_b
    lda #<str_play_player1
    sta STR_PTR_LO
    lda #>str_play_player1
    sta STR_PTR_HI
    jmp _rrg_prompt_draw_b
_rrg_prompt_p2_b:
    lda #<str_play_player2
    sta STR_PTR_LO
    lda #>str_play_player2
    sta STR_PTR_HI
_rrg_prompt_draw_b:
    lda #13
    sta TMP_COL
    lda #110
    sta TMP_Y
    lda #$20
    sta DRAW_PAGE_OFF
    jsr DrawString

    ; Show Page 1 during prompt pause
    bit TXTPAGE1
    lda #0
    sta CURR_PAGE

    ldx #150            ; ~2.5s pause (lengthened by +1.5s) so players know who plays & take controller
-   lda KBD
    cmp #$9B            ; ESC key
    bne +
    jmp QuitToMenu
+   jsr WaitFrameSync
    dex
    bne -
    bit KBDSTRB         ; Clear keyboard strobe so stray presses don't fire immediately

    ; Erase prompt cleanly on both buffers
    lda #<str_blank_14
    sta STR_PTR_LO
    lda #>str_blank_14
    sta STR_PTR_HI
    lda #13
    sta TMP_COL
    lda #110
    sta TMP_Y
    lda #0
    sta DRAW_PAGE_OFF
    jsr DrawString

    lda #<str_blank_14
    sta STR_PTR_LO
    lda #>str_blank_14
    sta STR_PTR_HI
    lda #13
    sta TMP_COL
    lda #110
    sta TMP_Y
    lda #$20
    sta DRAW_PAGE_OFF
    jsr DrawString

    ; Ready to enter GameLoop: Page 1 displayed, Page 2 back buffer
    bit TXTPAGE1
    lda #0
    sta CURR_PAGE
    lda #$20
    sta DRAW_PAGE_OFF
    rts

; ===================================================================
; PLAYER UPDATE (KEYBOARD & PADDLE / JOYSTICK)
; ===================================================================
UpdatePlayer:
    lda player_alive
    bne _up_alive
    jmp _up_dying
_up_alive:
    lda CURR_PAGE
    bne _up_p1
    lda player_x_p2
    sta TMP_X
    jmp _up_erase
_up_p1:
    lda player_x_p1
    sta TMP_X
_up_erase:
    lda #PLAYER_Y
    sta TMP_Y
    jsr EraseSprite16

    ; --- STEP 1: READ INPUTS (Movement & Fire independently) ---
    lda #0
    sta TEMP_VAL        ; bit 0 = Left, bit 1 = Right, bit 2 = Fire

    ; Check Joystick Button 0 / Open-Apple
    lda BTN0
    bpl +
    lda TEMP_VAL
    ora #$04            ; Bit 2 = Fire
    sta TEMP_VAL
+
    ; Check Joystick Button 1 / Solid-Apple
    lda BTN1
    bpl +
    lda TEMP_VAL
    ora #$04            ; Bit 2 = Fire
    sta TEMP_VAL
+
    ; Check Joystick / Paddle 0 horizontal position
    ldx #0
    jsr PDL0
    cpy #90
    bcs +
    lda TEMP_VAL
    ora #$01            ; Bit 0 = Left
    sta TEMP_VAL
    jmp _up_check_keyboard
+   cpy #165
    bcc _up_check_keyboard
    lda TEMP_VAL
    ora #$02            ; Bit 1 = Right
    sta TEMP_VAL

_up_check_keyboard:
    lda KBD
    bpl _up_apply_movement   ; No key pressed

    ; Check ESC ($9B) to quit cleanly to menu
    cmp #$9B
    bne +
    jmp QuitToMenu
+

    ; Key is pressed in KBD
    cmp #$88            ; Left arrow
    beq _up_k_left
    cmp #$C1            ; 'A'
    beq _up_k_left
    cmp #$E1            ; 'a'
    beq _up_k_left
    cmp #$D1            ; 'Q'
    beq _up_k_left
    cmp #$F1            ; 'q'
    beq _up_k_left
    cmp #$CA            ; 'J'
    beq _up_k_left
    cmp #$EA            ; 'j'
    beq _up_k_left

    cmp #$95            ; Right arrow
    beq _up_k_right
    cmp #$C4            ; 'D'
    beq _up_k_right
    cmp #$E4            ; 'd'
    beq _up_k_right
    cmp #$CC            ; 'L'
    beq _up_k_right
    cmp #$EC            ; 'l'
    beq _up_k_right

    cmp #$A0            ; Spacebar (Fire)
    beq _up_k_fire

    jmp _up_apply_movement

_up_k_left:
    lda TEMP_VAL
    ora #$01            ; Left
    sta TEMP_VAL
    jmp _up_apply_movement

_up_k_right:
    lda TEMP_VAL
    ora #$02            ; Right
    sta TEMP_VAL
    jmp _up_apply_movement

_up_k_fire:
    bit KBDSTRB         ; Clear strobe for Spacebar so it triggers cleanly
    lda TEMP_VAL
    ora #$04            ; Fire
    sta TEMP_VAL

_up_apply_movement:
    lda TEMP_VAL
    lsr                 ; Bit 0 -> Carry (Left)
    bcc _up_chk_right
    ; Move Left (2 pixels per step for responsive control)
    lda player_x
    sec
    sbc #2
    cmp #10             ; Far left boundary
    bcs +
    lda #10
+   sta player_x
    jmp _up_move_done
_up_chk_right:
    lsr                 ; Bit 1 -> Carry (Right)
    bcc _up_move_done
    ; Move Right (2 pixels per step)
    lda player_x
    clc
    adc #2
    cmp #205            ; Far right boundary
    bcc +
    lda #205
+   sta player_x
_up_move_done:
    ; --- STEP 2: HANDLE FIRE ---
    lda TEMP_VAL
    and #$04            ; Bit 2 = Fire?
    beq _up_draw

    ; Player wants to fire!
    lda shot_active
    bne _up_draw        ; Shot already active, ignore fire press

    lda #1
    sta shot_active
    lda player_x
    clc
    adc #7
    sta shot_x
    lda #PLAYER_Y - 2
    sta shot_y
    jsr PlayShootSound

_up_draw:
    lda #<spr_player
    sta SRC_LO
    lda #>spr_player
    sta SRC_HI
    lda player_x
    sta TMP_X
    lda #PLAYER_Y
    sta TMP_Y
    jsr DrawSprite16

    lda CURR_PAGE
    beq +
    lda player_x
    sta player_x_p1
    rts
+   lda player_x
    sta player_x_p2
    rts

_up_dying:
    dec player_exp_timer
    lda player_exp_timer
    and #$04
    lsr
    lsr
    sta player_exp_frame

    lda player_x
    sta TMP_X
    lda #PLAYER_Y
    sta TMP_Y
    jsr EraseSprite16

    lda player_exp_frame
    bne _up_exp1
    lda #<spr_player_exp0
    sta SRC_LO
    lda #>spr_player_exp0
    sta SRC_HI
    jmp _up_exp_draw
_up_exp1:
    lda #<spr_player_exp1
    sta SRC_LO
    lda #>spr_player_exp1
    sta SRC_HI
_up_exp_draw:
    lda player_x
    sta TMP_X
    lda #PLAYER_Y
    sta TMP_Y
    jsr DrawSprite16
    rts

; ===================================================================
; PLAYER MISSILE UPDATE & COLLISION LOGIC
; ===================================================================
UpdatePlayerShot:
    ; 1. Erase previously drawn shot on current back buffer if active on that buffer
    lda CURR_PAGE
    bne _ups_erase_p1

    ; Currently drawing on Page 2 (back buffer is Page 2)
    lda shot_active_p2
    beq _ups_check_active
    lda shot_x_p2
    sta TMP_X
    lda shot_y_p2
    sta TMP_Y
    jsr ErasePrevPlayerShot
    lda #0
    sta shot_active_p2
    jmp _ups_check_active

_ups_erase_p1:
    ; Currently drawing on Page 1 (back buffer is Page 1)
    lda shot_active_p1
    beq _ups_check_active
    lda shot_x_p1
    sta TMP_X
    lda shot_y_p1
    sta TMP_Y
    jsr ErasePrevPlayerShot
    lda #0
    sta shot_active_p1

_ups_check_active:
    lda shot_active
    bne +
    rts
+   cmp #2
    bne _ups_moving
    jmp _ups_splash
_ups_moving:
    lda shot_y
    sec
    sbc #4
    sta shot_y
    cmp #SAUCER_Y
    bcs +
    lda #0
    sta shot_active
    rts
+
    ; Check Saucer Collision
    lda saucer_active
    cmp #1
    bne _ups_check_aliens
    lda shot_y
    cmp #SAUCER_Y + 8
    bcs _ups_check_aliens
    cmp #SAUCER_Y
    bcc _ups_check_aliens
    lda shot_x
    sec
    sbc saucer_x
    cmp #16
    bcs _ups_check_aliens

    ; Saucer Hit!
    lda #2
    sta saucer_active
    lda #32
    sta saucer_hit_timer
    jsr PlaySaucerHitSound

    ldx saucer_score_ptr
    lda saucer_score_lo, x
    sta saucer_hit_score
    lda saucer_score_hi, x
    sta saucer_hit_hi
    inx
    cpx #15
    bcc +
    ldx #0
+   stx saucer_score_ptr

    sed
    lda active_player
    bne _us_score_p2
    lda score_p1_lo
    clc
    adc saucer_hit_score
    sta score_p1_lo
    lda score_p1_hi
    adc saucer_hit_hi
    sta score_p1_hi
    cld
    jmp +
_us_score_p2:
    lda score_p2_lo
    clc
    adc saucer_hit_score
    sta score_p2_lo
    lda score_p2_hi
    adc saucer_hit_hi
    sta score_p2_hi
    cld
+

    jsr RefreshHUDScore
    jsr RestoreDrawPage
    lda #0
    sta shot_active
    rts

_ups_check_aliens:
    ldx #0
_uca_loop:
    stx TEMP_VAL
    lda alien_alive_table, x
    bne _uca_alive
    jmp _uca_next
_uca_alive:
    ldx TEMP_VAL
    lda alien_old_x, x
    sta TMP_X
    lda alien_old_y, x
    sta TMP_Y

    lda shot_y
    sec
    sbc TMP_Y
    cmp #8
    bcc +
    jmp _uca_next
+
    lda shot_x
    sec
    sbc TMP_X
    cmp #14
    bcc +
    jmp _uca_next
+

    ; ALIEN HIT!
    ldx TEMP_VAL
    lda #0
    sta alien_alive_table, x
    dec aliens_remaining

    ; Erase dead alien using its sprite mask on BOTH buffers (no neighbor corruption!)
    lda alien_old_x, x
    sta TMP_X
    lda alien_old_y, x
    sta TMP_Y

    ldx TEMP_VAL
    stx alien_cur_idx
    lda #0
    jsr SetupAlienSpritePtr
    lda #0
    sta DRAW_PAGE_OFF
    jsr EraseMaskSprite16
    lda #$20
    sta DRAW_PAGE_OFF
    jsr EraseMaskSprite16

    lda #1
    jsr SetupAlienSpritePtr
    lda #0
    sta DRAW_PAGE_OFF
    jsr EraseMaskSprite16
    lda #$20
    sta DRAW_PAGE_OFF
    jsr EraseMaskSprite16
    jsr RestoreDrawPage

    ; If a previous explosion is still active, erase it before overwriting coordinates!
    lda alien_exp_active
    beq +
    lda #<spr_alien_exp
    sta SRC_LO
    lda #>spr_alien_exp
    sta SRC_HI
    lda alien_exp_x
    sta TMP_X
    lda alien_exp_y
    sta TMP_Y
    lda #0
    sta DRAW_PAGE_OFF
    jsr EraseMaskSprite16
    lda #$20
    sta DRAW_PAGE_OFF
    jsr EraseMaskSprite16
    jsr RestoreDrawPage
+
    lda #1
    sta alien_exp_active
    lda TMP_X
    sta alien_exp_x
    lda TMP_Y
    sta alien_exp_y
    lda #16
    sta alien_exp_timer
    jsr PlayAlienHitSound

    ldx TEMP_VAL
    txa
    ldy #0
-   cmp #11
    bcc +
    sbc #11
    iny
    bne -
+
    cpy #2
    bcc _pts_10
    cpy #4
    bcc _pts_20
    lda #$30
    jmp _pts_add
_pts_20:
    lda #$20
    jmp _pts_add
_pts_10:
    lda #$10
_pts_add:
    tax
    sed
    lda active_player
    bne _pts_add_p2
    txa
    clc
    adc score_p1_lo
    sta score_p1_lo
    lda score_p1_hi
    adc #0
    sta score_p1_hi
    cld
    jmp _uca_hit_done
_pts_add_p2:
    txa
    clc
    adc score_p2_lo
    sta score_p2_lo
    lda score_p2_hi
    adc #0
    sta score_p2_hi
    cld

_uca_hit_done:
    jsr RefreshHUDScore
    jsr RestoreDrawPage
    lda #0
    sta shot_active
    rts

_uca_next:
    ldx TEMP_VAL
    inx
    cpx #55
    bcs _uca_done
    jmp _uca_loop
_uca_done:

    lda shot_y
    cmp #BUNKER_Y + 16
    bcs _ups_draw
    cmp #BUNKER_Y
    bcc _ups_draw

    lda shot_x
    sta TMP_X
    lda shot_y
    sta TMP_Y
    jsr CheckPlayerShotBunker
    bcc _ups_draw
    lda #0
    sta shot_active
    rts

_ups_draw:
    ; Pre-compute column and bitmask OUTSIDE loop (X must stay as loop counter)
    ldx shot_x
    lda div7_table, x
    clc
    adc #PLAYFIELD_LEFT
    sta TMP_COL
    lda mod7_table, x
    tax
    lda bit_mask_table, x
    sta TMP_BYTE

    ldx #0
-   txa
    clc
    adc shot_y
    tay
    lda hgr_lo, y
    sta PTR_LO
    lda hgr_hi, y
    clc
    adc DRAW_PAGE_OFF
    sta PTR_HI

    ldy TMP_COL
    lda TMP_BYTE
    ora (PTR_LO), y
    sta (PTR_LO), y

    inx
    cpx #4
    bcc -

    lda CURR_PAGE
    beq +
    ; Currently drawing on Page 1
    lda shot_x
    sta shot_x_p1
    lda shot_y
    sta shot_y_p1
    lda #1
    sta shot_active_p1
    rts
+   ; Currently drawing on Page 2
    lda shot_x
    sta shot_x_p2
    lda shot_y
    sta shot_y_p2
    lda #1
    sta shot_active_p2
    rts

_ups_splash:
    dec shot_splash_timer
    bne +
    lda #0
    sta shot_active
+   rts

ErasePrevPlayerShot:
    ; Pre-compute column and clear mask OUTSIDE loop (X must stay as loop counter)
    ldx TMP_X
    lda div7_table, x
    clc
    adc #PLAYFIELD_LEFT
    sta TMP_COL
    lda mod7_table, x
    tax
    lda bit_clear_table, x
    sta TMP_BYTE

    ldx #0
-   txa
    clc
    adc TMP_Y
    tay
    lda hgr_lo, y
    sta PTR_LO
    lda hgr_hi, y
    clc
    adc DRAW_PAGE_OFF
    sta PTR_HI

    ldy TMP_COL
    lda TMP_BYTE
    and (PTR_LO), y
    sta (PTR_LO), y

    inx
    cpx #4
    bcc -
    rts

ErodeBunkerFromBelow:
    lda #0
    sta DRAW_PAGE_OFF
    jsr DrawBunkers
    lda #$20
    sta DRAW_PAGE_OFF
    jsr DrawBunkers
    jsr RestoreDrawPage
    rts

RefreshHUDScore:
    ; Check bonus player (extra life awarded at 1500 points BCD)
    lda active_player
    bne _rhs_p2_bonus
    lda extra_life_awarded
    bne _rhs_check_hi
    lda score_p1_hi
    cmp #$15
    bcc _rhs_check_hi
    inc extra_life_awarded
    inc lives_p1
    inc lives
    jmp _rhs_award_sound
_rhs_p2_bonus:
    lda extra_life_awarded_p2
    bne _rhs_check_hi
    lda score_p2_hi
    cmp #$15
    bcc _rhs_check_hi
    inc extra_life_awarded_p2
    inc lives_p2
    inc lives
_rhs_award_sound:
    lda #0
    sta DRAW_PAGE_OFF
    jsr DrawLivesIndicator
    lda #$20
    sta DRAW_PAGE_OFF
    jsr DrawLivesIndicator
    jsr RestoreDrawPage
    jsr PlayExtraLifeSound

_rhs_check_hi:
    ; Check active player's score against High Score
    lda active_player
    bne _rhs_hi_p2
    lda score_p1_hi
    cmp score_hi_hi
    bcc _rhs_draw
    bne _rhs_update_hi_p1
    lda score_p1_lo
    cmp score_hi_lo
    bcc _rhs_draw
_rhs_update_hi_p1:
    lda score_p1_hi
    sta score_hi_hi
    lda score_p1_lo
    sta score_hi_lo
    jmp _rhs_draw
_rhs_hi_p2:
    lda score_p2_hi
    cmp score_hi_hi
    bcc _rhs_draw
    bne _rhs_update_hi_p2
    lda score_p2_lo
    cmp score_hi_lo
    bcc _rhs_draw
_rhs_update_hi_p2:
    lda score_p2_hi
    sta score_hi_hi
    lda score_p2_lo
    sta score_hi_lo

_rhs_draw:
    lda #0
    sta DRAW_PAGE_OFF
    jsr _rhs_draw_scores
    lda #$20
    sta DRAW_PAGE_OFF
    jsr _rhs_draw_scores
    jsr RestoreDrawPage
    rts

_rhs_draw_scores:
    lda #6
    sta TMP_COL
    lda #11
    sta TMP_Y
    lda score_p1_hi
    ldx score_p1_lo
    jsr Print4Digits

    lda #18
    sta TMP_COL
    lda #11
    sta TMP_Y
    lda score_hi_hi
    ldx score_hi_lo
    jsr Print4Digits

    lda #30
    sta TMP_COL
    lda #11
    sta TMP_Y
    lda score_p2_hi
    ldx score_p2_lo
    jsr Print4Digits
    rts

; ===================================================================
; ALIEN FLEET UPDATE (SINGLE-ALIEN STEPPING MECHANISM)
; ===================================================================
UpdateAlienFleet:
    lda aliens_remaining
    bne +
    rts
+
_uaf_find_live:
    inc alien_cur_idx
    lda alien_cur_idx
    cmp #55
    bcc _uaf_check_alive

    ; Fleet cursor reached 55: full sweep completed!
    lda #0
    sta alien_cur_idx
    lda fleet_frame
    eor #1              ; Toggle animation frame (0 <-> 1)
    sta fleet_frame

    lda fleet_edge_hit
    beq _uaf_no_turn

    ; Edge hit during last sweep: invert direction and drop down
    lda fleet_dir
    eor #$FE            ; 1 <-> $FF
    sta fleet_dir
    lda fleet_y
    clc
    adc #8              ; Drop down 8 scanlines
    sta fleet_y
    lda #0
    sta fleet_edge_hit
    jmp _uaf_play_sound

_uaf_no_turn:
    lda fleet_dir
    bmi _uaf_dir_left
    ; Moving right
    lda fleet_x
    clc
    ldx aliens_remaining
    cpx #2
    bcs +
    adc #3              ; 3 pixels when 1 alien remains (arcade $18F8)
    bne _uaf_set_xr
+   adc #2
_uaf_set_xr:
    sta fleet_x
    jmp _uaf_play_sound

_uaf_dir_left:
    ; Moving left
    lda fleet_x
    sec
    ldx aliens_remaining
    cpx #2
    bcs +
    sbc #3              ; 3 pixels when 1 alien remains
    bne _uaf_set_xl
+   sbc #2
_uaf_set_xl:
    sta fleet_x

_uaf_play_sound:
    jsr PlayMarchSound

_uaf_check_alive:
    ldx alien_cur_idx
    lda alien_alive_table, x
    bne +
    jmp _uaf_find_live  ; Skip dead alien

+   ; 1. ERASE alien at previous coordinates using mask (both animation frames!) on BOTH buffers
    ldx alien_cur_idx
    lda alien_old_x, x
    sta TMP_X
    lda alien_old_y, x
    sta TMP_Y

    ; Erase frame 0 mask
    lda #0
    jsr SetupAlienSpritePtr
    lda #0
    sta DRAW_PAGE_OFF
    jsr EraseMaskSprite16
    lda #$20
    sta DRAW_PAGE_OFF
    jsr EraseMaskSprite16

    ; Erase frame 1 mask
    lda #1
    jsr SetupAlienSpritePtr
    lda #0
    sta DRAW_PAGE_OFF
    jsr EraseMaskSprite16
    lda #$20
    sta DRAW_PAGE_OFF
    jsr EraseMaskSprite16

    ; 2. Compute new coordinates for this living alien
    ldx alien_cur_idx
    jsr ComputeAlienCoords
    ldx alien_cur_idx

    ; 3. Check screen boundaries for this living alien
    lda fleet_dir
    bmi _uaf_chk_left
    lda TMP_X
    cmp #204
    bcc _uaf_chk_done
    lda #1
    sta fleet_edge_hit
    jmp _uaf_chk_done

_uaf_chk_left:
    lda TMP_X
    cmp #9
    bcs _uaf_chk_done
    lda #1
    sta fleet_edge_hit

_uaf_chk_done:
    ; 4. Check if fleet reached player cannon level (Invasion!)
    lda TMP_Y
    cmp #PLAYER_Y - 4
    bcc +
    lda #0
    sta player_alive
    lda #60
    sta player_exp_timer
    jsr PlayPlayerHitSound
+
    ; 5. DRAW alien at new coordinates on BOTH buffers
    lda fleet_frame
    jsr SetupAlienSpritePtr

    lda #0
    sta DRAW_PAGE_OFF
    jsr DrawSprite16

    lda #$20
    sta DRAW_PAGE_OFF
    jsr DrawSprite16

    jsr ErodeBunkersByAlien

    ; 6. Record new coordinates for next time this alien moves
    ldx alien_cur_idx
    lda TMP_X
    sta alien_old_x, x
    lda TMP_Y
    sta alien_old_y, x

    jsr RestoreDrawPage
    rts

ComputeAlienCoords:
    ldx alien_cur_idx
    txa
    ldy #0
-   cmp #11
    bcc +
    sbc #11
    iny
    bne -
+   sta TMP_COL
    sty TMP_BYTE

    lda TMP_COL
    asl
    asl
    asl
    asl
    clc
    adc fleet_x
    sta TMP_X

    lda #4
    sec
    sbc TMP_BYTE
    tay
    lda alien_row_y_table, y
    clc
    adc fleet_y
    sta TMP_Y
    ldx alien_cur_idx   ; Always preserve and return X = alien_cur_idx!
    rts

SetupAlienSpritePtr:
    ; Input: Accumulator = frame (0 or 1)
    ; Determines alien type directly from alien_row_table[alien_cur_idx]
    pha
    ldx alien_cur_idx
    lda alien_row_table, x
    cmp #2
    bcc _sasp_octo
    cmp #4
    bcc _sasp_crab

    pla
    bne +
    lda #<spr_squid_f0
    sta SRC_LO
    lda #>spr_squid_f0
    sta SRC_HI
    rts
+   lda #<spr_squid_f1
    sta SRC_LO
    lda #>spr_squid_f1
    sta SRC_HI
    rts

_sasp_crab:
    pla
    bne +
    lda #<spr_crab_f0
    sta SRC_LO
    lda #>spr_crab_f0
    sta SRC_HI
    rts
+   lda #<spr_crab_f1
    sta SRC_LO
    lda #>spr_crab_f1
    sta SRC_HI
    rts

_sasp_octo:
    pla
    bne +
    lda #<spr_octo_f0
    sta SRC_LO
    lda #>spr_octo_f0
    sta SRC_HI
    rts
+   lda #<spr_octo_f1
    sta SRC_LO
    lda #>spr_octo_f1
    sta SRC_HI
    rts

DrawCurrentAlien:
    lda fleet_frame
    jsr SetupAlienSpritePtr
    jsr DrawSprite16
    rts

; Find lowest living alien in column (0..10)
; Input: A = column index (0..10)
; Output: Carry = 1 if found (TMP_X, TMP_Y set to alien coords)
;         Carry = 0 if column is empty
FindLowestAlienInCol:
    sta TMP_COL
    ldy #0              ; Start from lowest row (row 0 = Octopus)
_flac_row_loop:
    sty TMP_BYTE
    tya
    asl
    asl
    asl                 ; y * 8
    clc
    adc TMP_BYTE        ; y * 9
    adc TMP_BYTE        ; y * 10
    adc TMP_BYTE        ; y * 11
    clc
    adc TMP_COL
    tax                 ; X = alien index (0..54)
    lda alien_alive_table, x
    bne _flac_found

    ldy TMP_BYTE
    iny
    cpy #5
    bcc _flac_row_loop
    clc
    rts

_flac_found:
    lda alien_cur_idx
    pha
    stx alien_cur_idx
    jsr ComputeAlienCoords
    pla
    sta alien_cur_idx
    sec
    rts

; ===================================================================
; ALIEN BOMBS UPDATE (ROLLING, PLUNGER, SQUIGGLY)
; ===================================================================
ErasePrevAlienBombs:
    lda CURR_PAGE
    bne _epb_erase_p1

    ; Erasing on Page 2
    ldx #0
_epb_ep2_loop:
    lda bomb_active_p2, x
    beq +
    stx BOMB_SLOT
    txa
    asl
    asl                 ; slot * 4
    sta TMP_BYTE
    lda bomb_prev_frame_p2, x
    and #3
    clc
    adc TMP_BYTE
    tay
    lda bomb_frames_lo, y
    sta SRC_LO
    lda bomb_frames_hi, y
    sta SRC_HI

    ldx BOMB_SLOT
    lda bomb_prev_x_p2, x
    sta TMP_X
    lda bomb_prev_y_p2, x
    sta TMP_Y
    jsr EraseMaskBombSprite

    ldx BOMB_SLOT
    lda #0
    sta bomb_active_p2, x
+   inx
    cpx #3
    bcc _epb_ep2_loop
    rts

_epb_erase_p1:
    ; Erasing on Page 1
    ldx #0
_epb_ep1_loop:
    lda bomb_active_p1, x
    beq +
    stx BOMB_SLOT
    txa
    asl
    asl                 ; slot * 4
    sta TMP_BYTE
    lda bomb_prev_frame_p1, x
    and #3
    clc
    adc TMP_BYTE
    tay
    lda bomb_frames_lo, y
    sta SRC_LO
    lda bomb_frames_hi, y
    sta SRC_HI

    ldx BOMB_SLOT
    lda bomb_prev_x_p1, x
    sta TMP_X
    lda bomb_prev_y_p1, x
    sta TMP_Y
    jsr EraseMaskBombSprite

    ldx BOMB_SLOT
    lda #0
    sta bomb_active_p1, x
+   inx
    cpx #3
    bcc _epb_ep1_loop
    rts

UpdateAlienBombs:
_uab_update_physics:
    ; 2. Update physics & collisions for all 3 slots
    ldx #0
_uab_slot_loop:
    stx BOMB_SLOT
    lda bomb_active, x
    bne +
    jmp _uab_check_spawn
+
    ; Advance animation frame
    inc bomb_frame, x

    ; Advance bomb Y by per-slot delta (Rolling=4, Plunger=4, Squiggly=6)
    lda bomb_y, x
    clc
    adc bomb_delta_y, x
    sta bomb_y, x

    ; Check floor collision (use wide zone since delta_y is 4 or 6)
    cmp #FLOOR_Y - 8
    bcc +
    ; Hit floor!
    ldx BOMB_SLOT
    lda #0
    sta bomb_active, x
    jsr RedrawFloorLine
    jmp _uab_next
+
    ; Check bunker collision
    lda bomb_x, x
    clc
    adc #3
    sta TMP_X
    lda bomb_y, x
    clc
    adc #7
    sta TMP_Y
    jsr CheckAlienBombBunker
    bcc +
    ; Hit bunker!
    ldx BOMB_SLOT
    lda #0
    sta bomb_active, x
    jmp _uab_next
+
    ; Check player collision
    lda player_alive
    beq _uab_check_shot_clash
    lda bomb_y, x
    cmp #PLAYER_Y - 8
    bcc _uab_check_shot_clash
    cmp #PLAYER_Y + 12
    bcs _uab_check_shot_clash
    lda bomb_x, x
    sec
    sbc player_x
    cmp #14
    bcs _uab_check_shot_clash
    ; Player is hit!
    lda #0
    sta player_alive
    lda #60
    sta player_exp_timer
    jsr PlayPlayerHitSound
    ldx BOMB_SLOT
    lda #0
    sta bomb_active, x
    jmp _uab_next

_uab_check_shot_clash:
    ; Check collision between alien bomb and player missile
    lda shot_active
    cmp #1
    beq +
    jmp _uab_next
+
    lda bomb_x, x
    sec
    sbc shot_x
    bpl +
    eor #$FF
    clc
    adc #1
+   cmp #6
    bcc +
    jmp _uab_next
+
    lda bomb_y, x
    sec
    sbc shot_y
    bpl +
    eor #$FF
    clc
    adc #1
+   cmp #6
    bcc +
    jmp _uab_next
+
    ; Clash! Both destroyed in mid-air
    lda #0
    sta shot_active
    jsr ErasePrevPlayerShot
    ldx BOMB_SLOT
    lda #0
    sta bomb_active, x
    jmp _uab_next

_uab_check_spawn:
    ; Bomb in slot X is inactive, check reload timer
    ldx BOMB_SLOT
    lda bomb_reload, x
    beq +
    dec bomb_reload, x
    beq +
    jmp _uab_next
+
    ; Reset reload delay based on score (higher score = faster reload)
    lda score_p1_hi     ; Score MSB (BCD e.g. $00, $01, $02...)
    lsr                 ; BCD hi nibble -> use upper digit as index
    lsr
    lsr
    lsr
    cmp #8
    bcc +
    lda #7              ; Cap at index 7
+   tay
    lda alien_reload_rate_table, y
    sta bomb_reload, x

    ; Try to spawn bomb for slot X
    cpx #0
    beq _uab_spawn_rolling
    cpx #1
    beq _uab_spawn_plunger
    jmp _uab_spawn_squiggly

_uab_spawn_rolling:
    ; Rolling bomb: targets player's column
    lda player_x
    sec
    sbc fleet_x
    bmi _uab_sr_zero
    lsr
    lsr
    lsr
    lsr                 ; / 16
    cmp #11
    bcc +
    lda #10
+   jmp _uab_sr_find
_uab_sr_zero:
    lda #0
_uab_sr_find:
    jsr FindLowestAlienInCol
    bcs +
    jmp _uab_next       ; No alien in this column
+   jmp _uab_do_spawn

_uab_spawn_plunger:
    ; Plunger bomb: uses col_fire_table[plunger_ptr]
    ldy plunger_ptr
    lda col_fire_table, y
    iny
    cpy #16
    bcc +
    ldy #0
+   sty plunger_ptr
    sec
    sbc #1              ; col_fire_table is 1-based (1..11) -> 0..10
    jsr FindLowestAlienInCol
    bcs +
    jmp _uab_next
+   jmp _uab_do_spawn

_uab_spawn_squiggly:
    ; Squiggly bomb: uses col_fire_table[squiggly_ptr]
    ldy squiggly_ptr
    lda col_fire_table, y
    iny
    cpy #32
    bcc +
    ldy #0
+   sty squiggly_ptr
    sec
    sbc #1              ; 1-based -> 0..10
    jsr FindLowestAlienInCol
    bcs +
    jmp _uab_next
+
_uab_do_spawn:
    ; Alien was found at TMP_X, TMP_Y
    ldx BOMB_SLOT
    lda #1
    sta bomb_active, x
    lda TMP_X
    clc
    adc #4
    sta bomb_x, x
    lda TMP_Y
    clc
    adc #8
    sta bomb_y, x
    lda #0
    sta bomb_frame, x

_uab_next:
    ldx BOMB_SLOT
    inx
    cpx #3
    bcs +
    jmp _uab_slot_loop
+

    ; 3. Draw all active bombs on current back buffer
    ldx #0
_uab_draw_loop:
    stx BOMB_SLOT
    lda bomb_active, x
    beq _uab_dl_next

    ; Determine sprite pointer: (slot * 4) + (bomb_frame & 3)
    txa
    asl
    asl                 ; slot * 4
    sta TMP_BYTE
    lda bomb_frame, x
    and #3
    clc
    adc TMP_BYTE
    tay
    lda bomb_frames_lo, y
    sta SRC_LO
    lda bomb_frames_hi, y
    sta SRC_HI

    ldx BOMB_SLOT
    lda bomb_x, x
    sta TMP_X
    lda bomb_y, x
    sta TMP_Y
    jsr DrawBombSprite

    ; Record prev coordinates for current back buffer
    ldx BOMB_SLOT
    lda CURR_PAGE
    bne _uab_rec_p1

    ; Currently drawing on Page 2
    lda bomb_x, x
    sta bomb_prev_x_p2, x
    lda bomb_y, x
    sta bomb_prev_y_p2, x
    lda bomb_frame, x
    sta bomb_prev_frame_p2, x
    lda #1
    sta bomb_active_p2, x
    jmp _uab_dl_next

_uab_rec_p1:
    ; Currently drawing on Page 1
    lda bomb_x, x
    sta bomb_prev_x_p1, x
    lda bomb_y, x
    sta bomb_prev_y_p1, x
    lda bomb_frame, x
    sta bomb_prev_frame_p1, x
    lda #1
    sta bomb_active_p1, x

_uab_dl_next:
    ldx BOMB_SLOT
    inx
    cpx #3
    bcc _uab_draw_loop
    jsr RestoreDrawPage
    rts

; ===================================================================
; MYSTERY SHIP (SAUCER / UFO) UPDATE
; ===================================================================
UpdateSaucer:
    ; Erase previous saucer on current back buffer if active on that buffer
    lda CURR_PAGE
    bne _us_erase_p1

    ; Erase on Page 2
    lda saucer_active_p2
    beq _us_check_active
    lda saucer_prev_x_p2
    sta TMP_X
    lda #SAUCER_Y
    sta TMP_Y
    jsr EraseSprite16
    lda #0
    sta saucer_active_p2
    jmp _us_check_active

_us_erase_p1:
    ; Erase on Page 1
    lda saucer_active_p1
    beq _us_check_active
    lda saucer_prev_x_p1
    sta TMP_X
    lda #SAUCER_Y
    sta TMP_Y
    jsr EraseSprite16
    lda #0
    sta saucer_active_p1

_us_check_active:
    lda saucer_active
    bne _us_active

    lda saucer_timer
    bne +
    lda saucer_timer+1
    beq _us_spawn
    dec saucer_timer+1
+   dec saucer_timer
    jsr RestoreDrawPage
    rts

_us_spawn:
    lda #<600
    sta saucer_timer
    lda #>600
    sta saucer_timer+1

    lda #1
    sta saucer_active
    lda #16
    sta saucer_x
    lda #1
    sta saucer_dir
    jsr RestoreDrawPage
    rts

_us_active:
    cmp #1
    bne _us_exploding

    lda saucer_dir
    bpl +
    ; Moving left: 2 pixels
    lda saucer_x
    sec
    sbc #2
    sta saucer_x
    jmp _us_chk_saucer_bound
+   ; Moving right: 2 pixels
    lda saucer_x
    clc
    adc #2
    sta saucer_x
_us_chk_saucer_bound:
    cmp #196
    bcc +
    lda #0
    sta saucer_active
    jsr RestoreDrawPage
    rts
+
    jsr PlaySaucerSiren

    lda #<spr_saucer
    sta SRC_LO
    lda #>spr_saucer
    sta SRC_HI
    lda saucer_x
    sta TMP_X
    lda #SAUCER_Y
    sta TMP_Y
    jsr DrawSprite16

    lda CURR_PAGE
    beq +
    ; Currently drawing on Page 1
    lda saucer_x
    sta saucer_prev_x_p1
    lda #1
    sta saucer_active_p1
    jsr RestoreDrawPage
    rts
+   ; Currently drawing on Page 2
    lda saucer_x
    sta saucer_prev_x_p2
    lda #1
    sta saucer_active_p2
    jsr RestoreDrawPage
    rts

_us_exploding:
    dec saucer_hit_timer
    bne _us_exp_show

    ; Timer expired: clean up on BOTH buffers and reset saucer!
    lda saucer_x
    sta TMP_X
    lda #SAUCER_Y
    sta TMP_Y
    lda #0
    sta DRAW_PAGE_OFF
    jsr EraseSprite16
    lda #$20
    sta DRAW_PAGE_OFF
    jsr EraseSprite16

    lda #0
    sta saucer_active
    sta saucer_active_p1
    sta saucer_active_p2
    lda #<600
    sta saucer_timer
    lda #>600
    sta saucer_timer+1
    jsr RestoreDrawPage
    rts

_us_exp_show:
    lda saucer_hit_timer
    cmp #24
    bcc _us_show_score

    ; Phase 1 (frames 32..24): Draw Saucer Explosion Sprite!
    lda #<spr_saucer_exp
    sta SRC_LO
    lda #>spr_saucer_exp
    sta SRC_HI
    lda saucer_x
    sta TMP_X
    lda #SAUCER_Y
    sta TMP_Y
    jsr DrawSprite16
    jmp _us_rec_buffer

_us_show_score:
    ; Phase 2 (frames 23..1): Draw 3-character score string at saucer position
    lda saucer_hit_hi
    bne +
    ; 50 points
    lda #<str_saucer_50
    sta STR_PTR_LO
    lda #>str_saucer_50
    sta STR_PTR_HI
    jmp _us_print_score
+   cmp #3
    bne +
    ; 300 points
    lda #<str_saucer_300
    sta STR_PTR_LO
    lda #>str_saucer_300
    sta STR_PTR_HI
    jmp _us_print_score
+   ; hi is 1: check lo for 50 (150) or 00 (100)
    lda saucer_hit_score
    beq +
    ; 150 points
    lda #<str_saucer_150
    sta STR_PTR_LO
    lda #>str_saucer_150
    sta STR_PTR_HI
    jmp _us_print_score
+   ; 100 points
    lda #<str_saucer_100
    sta STR_PTR_LO
    lda #>str_saucer_100
    sta STR_PTR_HI

_us_print_score:
    ldx saucer_x
    lda div7_table, x
    clc
    adc #PLAYFIELD_LEFT
    sta TMP_COL
    lda #SAUCER_Y
    sta TMP_Y
    jsr DrawString

_us_rec_buffer:
    lda CURR_PAGE
    beq +
    lda saucer_x
    sta saucer_prev_x_p1
    lda #1
    sta saucer_active_p1
    jsr RestoreDrawPage
    rts
+   lda saucer_x
    sta saucer_prev_x_p2
    lda #1
    sta saucer_active_p2
    jsr RestoreDrawPage
    rts

; ===================================================================
; EXPLOSIONS UPDATE
; ===================================================================
UpdateExplosions:
    lda alien_exp_active
    bne _ue_active
    jsr RestoreDrawPage
    rts
_ue_active:
    dec alien_exp_timer
    bne _ue_draw
    lda #0
    sta alien_exp_active
    lda #<spr_alien_exp
    sta SRC_LO
    lda #>spr_alien_exp
    sta SRC_HI
    lda alien_exp_x
    sta TMP_X
    lda alien_exp_y
    sta TMP_Y
    lda #0
    sta DRAW_PAGE_OFF
    jsr EraseMaskSprite16
    lda #$20
    sta DRAW_PAGE_OFF
    jsr EraseMaskSprite16
    jsr RestoreDrawPage
    rts
_ue_draw:
    lda #<spr_alien_exp
    sta SRC_LO
    lda #>spr_alien_exp
    sta SRC_HI
    lda alien_exp_x
    sta TMP_X
    lda alien_exp_y
    sta TMP_Y
    lda #0
    sta DRAW_PAGE_OFF
    jsr DrawSprite16
    lda #$20
    sta DRAW_PAGE_OFF
    jsr DrawSprite16
    jsr RestoreDrawPage
    rts
