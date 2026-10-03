; =============================================================================
; SPECIAL BIRTHDAY BOOT INTRO FOR APPLE II
; "Bon Anniversaire Grand Frere !" + Birthday Cake + Full GR Animations
; Jumps directly to ARTILLERIE ($4000) on any keypress.
; Traps RESET so it is completely inoperative.
; =============================================================================

* = $0800

; --- ROM Routines & Hardware Switches ---
TXTCLR      = $C050     ; Switch to graphics mode
MIXCLR      = $C052     ; Full screen graphics (40x48 pixels)
TXTPAGE1    = $C054     ; Select graphics page 1 ($0400..$07FF)
LORES       = $C056     ; Select Low-Res (GR) mode
KBD         = $C000     ; Keyboard data (bit 7 = key pressed)
KBDSTRB     = $C010     ; Clear keyboard strobe
SPEAKER     = $C030     ; Apple II 1-bit speaker toggle
TEXT_ROM    = $FB2F     ; ROM routine: standard text mode

; --- RWTS (Read/Write Track/Sector) in DOS 3.3 ---
RWTS_ENTRY  = $03D9     ; Standard Apple II DOS 3.3 page 3 RWTS vector ($03D9 -> $B7B5)
IOB_ADDR    = $B7E8
IOB_TRACK   = $B7EC
IOB_SECTOR  = $B7ED
IOB_BUF_LO  = $B7F0
IOB_BUF_HI  = $B7F1
IOB_CMD     = $B7F4

; --- Zero Page temporary variables ---
SCREEN_LO   = $04
SCREEN_HI   = $05
PTR_LO      = $06
PTR_HI      = $07
PTR2_LO     = $08
PTR2_HI     = $09
TEMP_COL    = $0A
TEMP_X      = $0B
TEMP_Y      = $0C
TEMP_VAL    = $0D
RND_SEED    = $0E
STR_INDEX   = $0F

Start:
    SEI
    CLD
    LDX #$FF
    TXS

    ; 1. Trap RESET immediately
    JSR SetResetTrap

RestartIntro:
    ; 2. Set up Low-Resolution Full Screen Graphics IMMEDIATELY
    STA TXTCLR          ; Graphics mode ($C050)
    STA MIXCLR          ; Full screen 40x48 ($C052)
    STA TXTPAGE1        ; Page 1 ($C054)
    STA LORES           ; Lo-Res color ($C056)

    JSR ClearScreen
    JSR DrawBackgroundScene
    JSR InitParticles

    ; 3. Disable CATALOG command in DOS command table
    JSR DisableCatalog

    ; 4. Mark game as not yet launched
    LDA #0
    STA GAME_ACTIVE

    ; 5. Play Birthday Chime on Startup
    JSR PlayBirthdayTune

; =============================================================================
; MAIN ANIMATION LOOP
; =============================================================================
MainLoop:
    ; A. Check keyboard
    LDA KBD
    BPL +
    JMP LaunchGame      ; Key pressed! Start Artillerie!
+   
    ; B. Update Animations
    JSR UpdateFlames
    JSR UpdateConfetti
    JSR UpdateSparkles
    JSR CycleTextShimmer

    ; C. Frame Delay
    LDY #$25
DelayOuter:
    LDX #$FF
DelayInner:
    LDA KBD
    BMI LaunchGame      ; Check keyboard during delay for instant response
    DEX
    BNE DelayInner
    DEY
    BNE DelayOuter

    INC FRAME_COUNTER
    JMP MainLoop

; =============================================================================
; LAUNCH ARTILLERIE
; =============================================================================
LaunchGame:
    STA KBDSTRB         ; Clear keyboard strobe
    LDA #1
    STA GAME_ACTIVE     ; Mark game as running for reset trap
    JSR TEXT_ROM        ; TEXT_ROM: reset screen cleanly before Artillerie inits HGR
    JSR LoadArtillerie  ; Load Artillerie from raw tracks 3, 4, 5
    JMP $4000           ; Jump directly to Artillery game!

; =============================================================================
; RESET TRAP (MAKES RESET KEY 100% INOPERATIVE)
; =============================================================================
SetResetTrap:
    LDA #<ResetHandler
    STA $03F2
    LDA #>ResetHandler
    STA $03F3
    EOR #$A5
    STA $03F4           ; Soft reset validation byte
    RTS

ResetHandler:
    SEI
    CLD
    LDX #$FF
    TXS
    JSR SetResetTrap
    LDA GAME_ACTIVE
    BNE +
    JMP RestartIntro
+   JMP $4000           ; If playing artillerie, restart artillerie!

; =============================================================================
; DISABLE CATALOG IN DOS COMMAND TABLE
; Overwrites "CATALOG" with zeros in DOS command parser ($9E52..$9FFF)
; =============================================================================
DisableCatalog:
    LDY #0
-   LDA $9E52,Y
    CMP #$43            ; 'C'
    BNE +
    LDA $9E53,Y
    CMP #$41            ; 'A'
    BNE +
    LDA $9E54,Y
    CMP #$54            ; 'T'
    BNE +
    ; Found CATALOG! Replace with XXXXXX\xD8 so typing CATALOG yields ?SYNTAX ERROR
    ; while preserving the high-bit command boundary required by DOS command scanner!
    LDA #$58            ; 'X'
    STA $9E52,Y
    STA $9E53,Y
    STA $9E54,Y
    STA $9E55,Y
    STA $9E56,Y
    STA $9E57,Y
    LDA #$D8            ; 'X' | $80
    STA $9E58,Y
    RTS
+   INY
    CPY #$A0
    BNE -
    RTS

; =============================================================================
; LOAD ARTILLERIE FROM TRACKS 3, 4, 5 INTO $4000..$6A00 VIA RWTS
; =============================================================================
LoadArtillerie:
    LDA #1
    STA $B7EA           ; Force Drive 1
    LDA #0
    STA $B7EB           ; Volume 0 = match any volume
    LDA #3
    STA CURR_TRACK
    LDA #0
    STA CURR_SECT
    LDA #$00
    STA IOB_BUF_LO
    LDA #$40
    STA IOB_BUF_HI

ReadSectorLoop:
    LDA #1              ; Command 1 = READ
    STA IOB_CMD
    LDA CURR_TRACK
    STA IOB_TRACK
    LDA CURR_SECT
    STA IOB_SECTOR
    
    LDY #<IOB_ADDR
    LDA #>IOB_ADDR
    JSR RWTS_ENTRY      ; Call DOS 3.3 RWTS

    INC IOB_BUF_HI      ; Advance memory page (+256 bytes)
    LDA IOB_BUF_HI
    CMP #$6A            ; Reached $6A00? (42 sectors loaded)
    BEQ LoadDone

    INC CURR_SECT
    LDA CURR_SECT
    CMP #16
    BNE ReadSectorLoop
    LDA #0
    STA CURR_SECT
    INC CURR_TRACK
    JMP ReadSectorLoop

LoadDone:
    RTS

CURR_TRACK      .byte 0
CURR_SECT       .byte 0
GAME_ACTIVE     .byte 0
FRAME_COUNTER   .byte 0

; =============================================================================
; LOW-RES GRAPHICS PLOT ROUTINE
; Input: X = column (0..39), Y = row (0..47), A = color (0..15)
; =============================================================================
PlotXY:
    STA TEMP_COL        ; Save color (0..15)
    STX TEMP_X          ; Save column X (0..39)
    STY TEMP_Y          ; Save row Y (0..47)

    TYA
    LSR A               ; Line 0..23 (row / 2)
    TAX
    LDA LineTableLo,X
    STA SCREEN_LO
    LDA LineTableHi,X
    STA SCREEN_HI

    LDA TEMP_Y          ; Check even/odd row
    LSR A
    BCS _plot_odd

_plot_even:
    LDY TEMP_X          ; Y = column index
    LDA (SCREEN_LO),Y   ; Read existing byte
    AND #$F0            ; Keep high nibble (odd row)
    ORA TEMP_COL        ; Set low nibble (even row)
    STA (SCREEN_LO),Y
    JMP _plot_done

_plot_odd:
    LDA TEMP_COL
    ASL A
    ASL A
    ASL A
    ASL A               ; Shift color into high nibble
    STA TEMP_COL
    LDY TEMP_X          ; Y = column index
    LDA (SCREEN_LO),Y   ; Read existing byte
    AND #$0F            ; Keep low nibble (even row)
    ORA TEMP_COL        ; Set high nibble (odd row)
    STA (SCREEN_LO),Y

_plot_done:
    LDX TEMP_X          ; Restore original X!
    LDY TEMP_Y          ; Restore original Y!
    RTS

; =============================================================================
; CLEAR SCREEN TO BLACK ($00)
; =============================================================================
ClearScreen:
    LDX #0
-   LDA #0
    STA $0400,X
    STA $0500,X
    STA $0600,X
    STA $0700,X
    INX
    BNE -
    RTS

; =============================================================================
; DRAW BACKGROUND SCENE (CAKE, TEXT, TABLE, CANDLES)
; =============================================================================
DrawBackgroundScene:
    ; 1. Draw Table (rows 45..47, Green $4 with Red $1 accents)
    LDY #45
TableLoopY:
    LDX #0
TableLoopX:
    LDA #4              ; Dark green
    CPX #10
    BEQ +
    CPX #20
    BEQ +
    CPX #30
    BNE _draw_tbl_pix
+   LDA #1              ; Deep red accent
_draw_tbl_pix:
    JSR PlotXY
    INX
    CPX #40
    BNE TableLoopX
    INY
    CPY #48
    BNE TableLoopY

    ; 2. Draw Cake Platter (rows 43..44, Light Blue $7 & Grey $5)
    LDX #3
PlatterLoop:
    LDY #43
    LDA #7              ; Light Blue rim
    JSR PlotXY
    LDY #44
    LDA #5              ; Grey base
    JSR PlotXY
    INX
    CPX #37
    BNE PlatterLoop

    ; 3. Draw Cake Tier 2 (Bottom, rows 36..42, X = 6..33)
    LDY #36
Tier2LoopY:
    LDX #6
Tier2LoopX:
    CPY #36
    BEQ _t2_frosting
    CPY #42
    BEQ _t2_cherries
    ; Sponge cake: Violet $3 with Chocolate $8 shading
    LDA #3
    CPX #8
    BCC +
    CPX #32
    BCS +
    JMP _t2_plot
+   LDA #8              ; Shadow edge
    JMP _t2_plot

_t2_frosting:
    ; Alternating Vanilla $D and Cream $F rosettes
    TXA
    AND #1
    BNE +
    LDA #13             ; Yellow
    BNE _t2_plot
+   LDA #15             ; White
    BNE _t2_plot

_t2_cherries:
    ; Red cherries on bottom border
    TXA
    AND #3
    BNE +
    LDA #1              ; Red cherry
    BNE _t2_plot
+   LDA #3              ; Violet sponge

_t2_plot:
    JSR PlotXY
    INX
    CPX #34
    BNE Tier2LoopX
    INY
    CPY #43
    BNE Tier2LoopY

    ; 4. Draw Cake Tier 1 (Top, rows 30..35, X = 11..28)
    LDY #30
Tier1LoopY:
    LDX #11
Tier1LoopX:
    CPY #30
    BEQ _t1_frosting
    CPY #31
    BEQ _t1_drips
    ; Chocolate cake: Brown $8 with Orange $9 center
    LDA #8
    CPX #15
    BCC +
    CPX #25
    BCS +
    LDA #9              ; Orange highlight
+   JMP _t1_plot

_t1_frosting:
    ; Pink $B and White $F cream
    TXA
    AND #1
    BNE +
    LDA #11             ; Pink
    BNE _t1_plot
+   LDA #15             ; White
    BNE _t1_plot

_t1_drips:
    TXA
    AND #3
    BNE +
    LDA #11             ; Pink drip
    BNE _t1_plot
+   LDA #8              ; Chocolate

_t1_plot:
    JSR PlotXY
    INX
    CPX #29
    BNE Tier1LoopX
    INY
    CPY #36
    BNE Tier1LoopY

    ; 5. Draw 3 Candle Sticks (rows 27..29 at X = 14, 20, 26)
    LDX #14
    JSR DrawCandleStick
    LDX #20
    JSR DrawCandleStick
    LDX #26
    JSR DrawCandleStick

    ; 6. Draw Messages
    JSR DrawAllMessages
    RTS

DrawCandleStick:
    LDY #27
    LDA #15             ; White
    JSR PlotXY
    LDY #28
    LDA #11             ; Pink stripe
    JSR PlotXY
    LDY #29
    LDA #15             ; White
    JSR PlotXY
    RTS

; =============================================================================
; DRAW MESSAGES IN GR COLOR
; Rows 1..5:   "BON"
; Rows 7..11:  "ANNI-"
; Rows 13..17: "VERSAIRE"
; Rows 19..23: "GRAND FRERE !"
; =============================================================================
DrawAllMessages:
    ; Draw "BON" at X=14, Y=1 in Yellow ($D)
    LDA #14
    STA TXT_X
    LDA #1
    STA TXT_Y
    LDA #13
    STA TXT_COL
    LDA #<STR_BON
    STA PTR_LO
    LDA #>STR_BON
    STA PTR_HI
    JSR RenderString

    ; Draw "ANNIV'" at X=9, Y=7 in Orange ($9)
    LDA #9
    STA TXT_X
    LDA #7
    STA TXT_Y
    LDA #9
    STA TXT_COL
    LDA #<STR_ANNIV
    STA PTR_LO
    LDA #>STR_ANNIV
    STA PTR_HI
    JSR RenderString

    ; Draw "GRAND" at X=10, Y=13 in Aqua ($E)
    LDA #10
    STA TXT_X
    LDA #13
    STA TXT_Y
    LDA #14
    STA TXT_COL
    LDA #<STR_GRAND
    STA PTR_LO
    LDA #>STR_GRAND
    STA PTR_HI
    JSR RenderString

    ; Draw "FRERE !" at X=7, Y=19 in Aqua ($E)
    LDA #7
    STA TXT_X
    LDA #19
    STA TXT_Y
    LDA #14
    STA TXT_COL
    LDA #<STR_FRERE
    STA PTR_LO
    LDA #>STR_FRERE
    STA PTR_HI
    JSR RenderString
    RTS

TXT_X   .byte 0
TXT_Y   .byte 0
TXT_COL .byte 0

STR_BON     .null "BON"
STR_ANNIV   .null "ANNIV'"
STR_GRAND   .null "GRAND"
STR_FRERE   .null "FRERE !"

; =============================================================================
; 3x5 FONT RENDERER
; Renders null-terminated ASCII string at (TXT_X, TXT_Y) with color TXT_COL
; =============================================================================
RenderString:
    LDY #0
StringLoop:
    LDA (PTR_LO),Y
    BEQ RenderStringDone
    STY STR_INDEX       ; Preserve string index
    JSR DrawChar        ; Draw character in A
    LDY STR_INDEX
    INY
    JMP StringLoop
RenderStringDone:
    RTS

DrawChar:
    CMP #32             ; Space?
    BNE +
    LDA TXT_X
    CLC
    ADC #3              ; Advance 3 pixels for space
    STA TXT_X
    RTS
+   
    ; Find glyph pointer (each glyph is 5 bytes, 1 byte per row, bits 2..0)
    JSR GetGlyphOffset
    ; Draw 5 rows
    LDA #0
    STA ROW_IDX
GlyphRowLoop:
    LDY ROW_IDX
    LDA (PTR2_LO),Y
    STA BIT_PATTERN

    ; Col 0 (Bit 2: %100 = 4)
    LDA BIT_PATTERN
    AND #4
    BEQ +
    LDX TXT_X
    LDY TXT_Y
    TYA
    CLC
    ADC ROW_IDX
    TAY
    LDA TXT_COL
    JSR PlotXY
+   
    ; Col 1 (Bit 1: %010 = 2)
    LDA BIT_PATTERN
    AND #2
    BEQ +
    LDX TXT_X
    INX
    LDY TXT_Y
    TYA
    CLC
    ADC ROW_IDX
    TAY
    LDA TXT_COL
    JSR PlotXY
+   
    ; Col 2 (Bit 0: %001 = 1)
    LDA BIT_PATTERN
    AND #1
    BEQ +
    LDX TXT_X
    INX
    INX
    LDY TXT_Y
    TYA
    CLC
    ADC ROW_IDX
    TAY
    LDA TXT_COL
    JSR PlotXY
+   
    INC ROW_IDX
    LDA ROW_IDX
    CMP #5
    BNE GlyphRowLoop

    ; Advance TXT_X by 4 (3 cols + 1 space)
    LDA TXT_X
    CLC
    ADC #4
    STA TXT_X
    RTS

ROW_IDX         .byte 0
BIT_PATTERN     .byte 0

GetGlyphOffset:
    ; Maps ASCII in A to 5-byte font table into PTR2_LO/HI
    CMP #'B'
    BNE +
    LDA #<GLYPH_B
    STA PTR2_LO
    LDA #>GLYPH_B
    STA PTR2_HI
    RTS
+   CMP #'O'
    BNE +
    LDA #<GLYPH_O
    STA PTR2_LO
    LDA #>GLYPH_O
    STA PTR2_HI
    RTS
+   CMP #'N'
    BNE +
    LDA #<GLYPH_N
    STA PTR2_LO
    LDA #>GLYPH_N
    STA PTR2_HI
    RTS
+   CMP #'A'
    BNE +
    LDA #<GLYPH_A
    STA PTR2_LO
    LDA #>GLYPH_A
    STA PTR2_HI
    RTS
+   CMP #'I'
    BNE +
    LDA #<GLYPH_I
    STA PTR2_LO
    LDA #>GLYPH_I
    STA PTR2_HI
    RTS
+   CMP #39             ; Apostrophe "'"
    BNE +
    LDA #<GLYPH_APOS
    STA PTR2_LO
    LDA #>GLYPH_APOS
    STA PTR2_HI
    RTS
+   CMP #'-'
    BNE +
    LDA #<GLYPH_DASH
    STA PTR2_LO
    LDA #>GLYPH_DASH
    STA PTR2_HI
    RTS
+   CMP #'V'
    BNE +
    LDA #<GLYPH_V
    STA PTR2_LO
    LDA #>GLYPH_V
    STA PTR2_HI
    RTS
+   CMP #'E'
    BNE +
    LDA #<GLYPH_E
    STA PTR2_LO
    LDA #>GLYPH_E
    STA PTR2_HI
    RTS
+   CMP #'R'
    BNE +
    LDA #<GLYPH_R
    STA PTR2_LO
    LDA #>GLYPH_R
    STA PTR2_HI
    RTS
+   CMP #'S'
    BNE +
    LDA #<GLYPH_S
    STA PTR2_LO
    LDA #>GLYPH_S
    STA PTR2_HI
    RTS
+   CMP #'G'
    BNE +
    LDA #<GLYPH_G
    STA PTR2_LO
    LDA #>GLYPH_G
    STA PTR2_HI
    RTS
+   CMP #'D'
    BNE +
    LDA #<GLYPH_D
    STA PTR2_LO
    LDA #>GLYPH_D
    STA PTR2_HI
    RTS
+   CMP #'F'
    BNE +
    LDA #<GLYPH_F
    STA PTR2_LO
    LDA #>GLYPH_F
    STA PTR2_HI
    RTS
+   CMP #'!'
    BNE +
    LDA #<GLYPH_EXCL
    STA PTR2_LO
    LDA #>GLYPH_EXCL
    STA PTR2_HI
    RTS
+   ; Default empty
    LDA #<GLYPH_SPACE
    STA PTR2_LO
    LDA #>GLYPH_SPACE
    STA PTR2_HI
    RTS

; 3-wide glyphs stored as bits 2..0 in each byte:
GLYPH_B     .byte %110, %101, %110, %101, %110
GLYPH_O     .byte %010, %101, %101, %101, %010
GLYPH_N     .byte %101, %111, %111, %101, %101
GLYPH_A     .byte %010, %101, %111, %101, %101
GLYPH_I     .byte %111, %010, %010, %010, %111
GLYPH_APOS  .byte %010, %010, %000, %000, %000
GLYPH_DASH  .byte %000, %000, %111, %000, %000
GLYPH_V     .byte %101, %101, %101, %101, %010
GLYPH_E     .byte %111, %100, %110, %100, %111
GLYPH_R     .byte %110, %101, %110, %101, %101
GLYPH_S     .byte %011, %100, %010, %001, %110
GLYPH_G     .byte %011, %100, %101, %101, %011
GLYPH_D     .byte %110, %101, %101, %101, %110
GLYPH_F     .byte %111, %100, %110, %100, %100
GLYPH_EXCL  .byte %010, %010, %010, %000, %010
GLYPH_SPACE .byte %000, %000, %000, %000, %000

; =============================================================================
; CANDLE FLAME ANIMATION (3 CANDLES AT X=14, 20, 26)
; =============================================================================
UpdateFlames:
    LDA FRAME_COUNTER
    LSR A
    LSR A               ; Update flame every 4 ticks
    AND #3
    STA FLAME_PHASE

    ; Candle 1 at X=14
    LDX #14
    LDA FLAME_PHASE
    JSR DrawFlameFrame

    ; Candle 2 at X=20
    LDX #20
    LDA FLAME_PHASE
    CLC
    ADC #1
    AND #3
    JSR DrawFlameFrame

    ; Candle 3 at X=26
    LDX #26
    LDA FLAME_PHASE
    CLC
    ADC #2
    AND #3
    JSR DrawFlameFrame
    RTS

FLAME_PHASE .byte 0

DrawFlameFrame:
    CMP #0
    BNE +
    ; Frame 0
    LDY #24
    LDA #0
    JSR PlotXY
    LDY #25
    LDA #13             ; Yellow
    JSR PlotXY
    LDY #26
    LDA #9              ; Orange
    JSR PlotXY
    RTS
+   CMP #1
    BNE +
    ; Frame 1
    LDY #24
    LDA #15             ; White tip
    JSR PlotXY
    LDY #25
    LDA #13             ; Yellow
    JSR PlotXY
    LDY #26
    LDA #9              ; Orange
    JSR PlotXY
    RTS
+   CMP #2
    BNE +
    ; Frame 2
    LDY #24
    LDA #9              ; Orange tip
    JSR PlotXY
    LDY #25
    LDA #13             ; Yellow
    JSR PlotXY
    LDY #26
    LDA #1              ; Red base
    JSR PlotXY
    RTS
+   ; Frame 3
    LDY #24
    LDA #0
    JSR PlotXY
    LDY #25
    LDA #13
    JSR PlotXY
    LDY #26
    LDA #9
    JSR PlotXY
    RTS

; =============================================================================
; CONFETTI SHOWER ANIMATION
; 16 animated particles drifting down across the screen
; =============================================================================
NUM_CONFETTI = 16

InitParticles:
    LDX #0
-   LDA InitialConfettiX,X
    STA CONF_X,X
    LDA InitialConfettiY,X
    STA CONF_Y,X
    LDA InitialConfettiC,X
    STA CONF_C,X
    INX
    CPX #NUM_CONFETTI
    BNE -
    RTS

UpdateConfetti:
    LDX #0
ConfettiLoop:
    STX CURR_CONF_IDX

    ; 1. Erase old particle IF in safe margin (Y < 42 and (X < 5 or X > 34))
    LDY CONF_Y,X
    CPY #42
    BCS _advance_confetti
    LDA CONF_X,X
    CMP #5
    BCC +                   ; Left margin (X < 5) -> safe to erase!
    CMP #35
    BCC _advance_confetti   ; Middle area (text/cake) -> NEVER ERASE!
+   LDA CONF_X,X            ; Column
    TAX
    LDA #0                  ; Black
    JSR PlotXY

_advance_confetti:
    LDX CURR_CONF_IDX
    INC CONF_Y,X
    LDA CONF_Y,X
    CMP #42                 ; Reached bottom (above platter)?
    BCC _draw_confetti

    ; Reached bottom -> respawn at top (Y=0) strictly in safe margins
    LDA #0
    STA CONF_Y,X
    TXA
    AND #1
    BNE _respawn_right

_respawn_left:
    ; Left margin: X = 1..4
    JSR GetRandom
    AND #3                  ; 0..3
    CLC
    ADC #1                  ; 1..4
    LDX CURR_CONF_IDX
    STA CONF_X,X
    JMP _pick_confetti_col

_respawn_right:
    ; Right margin: X = 35..38
    JSR GetRandom
    AND #3                  ; 0..3
    CLC
    ADC #35                 ; 35..38
    LDX CURR_CONF_IDX
    STA CONF_X,X

_pick_confetti_col:
    JSR GetRandom
    AND #7
    TAY
    LDA ConfettiColors,Y
    LDX CURR_CONF_IDX
    STA CONF_C,X

_draw_confetti:
    LDX CURR_CONF_IDX
    LDY CONF_Y,X
    CPY #42
    BCS _next_confetti
    LDA CONF_X,X
    CMP #5
    BCC +                   ; Left margin -> safe to draw!
    CMP #35
    BCC _next_confetti      ; Inside text/cake area -> NEVER DRAW!
+   LDA CONF_C,X
    PHA
    LDA CONF_X,X
    TAX
    PLA
    JSR PlotXY

_next_confetti:
    LDX CURR_CONF_IDX
    INX
    CPX #NUM_CONFETTI
    BEQ +
    JMP ConfettiLoop
+   RTS

CURR_CONF_IDX   .byte 0
CONF_X          .fill NUM_CONFETTI, 0
CONF_Y          .fill NUM_CONFETTI, 0
CONF_C          .fill NUM_CONFETTI, 0

; Initial confetti positions strictly in Left (X=1..4) and Right (X=35..38) margins
InitialConfettiX .byte 1, 35, 3, 37, 2, 36, 4, 38, 1, 35, 3, 37, 2, 36, 4, 38
InitialConfettiY .byte 0,  3, 6,  9, 12, 15, 18, 21, 24, 27, 30, 33, 36, 39, 41,  1
InitialConfettiC .byte 13, 14, 1, 12, 11, 9, 7, 15, 14, 13, 9, 11, 12, 1, 15, 7

ConfettiColors  .byte 13, 14, 1, 12, 11, 9, 7, 15

; Simple PRNG
GetRandom:
    LDA RND_SEED
    BEQ +
    ASL A
    BCC _rnd_done
    EOR #$1D
    JMP _rnd_done
+   LDA #$5A
_rnd_done:
    STA RND_SEED
    RTS

; =============================================================================
; TWINKLING SPARKLES (4 CORNERS OF THE TITLE)
; =============================================================================
UpdateSparkles:
    LDA FRAME_COUNTER
    LSR A
    LSR A
    LSR A
    AND #3
    TAY
    LDA SparkleColors,Y
    STA SPARKLE_COL

    ; Sparkle 1 at (2, 1)
    LDX #2
    LDY #1
    LDA SPARKLE_COL
    JSR PlotXY
    ; Sparkle 2 at (37, 2)
    LDX #37
    LDY #2
    LDA SPARKLE_COL
    JSR PlotXY
    ; Sparkle 3 at (1, 14)
    LDX #1
    LDY #14
    LDA SPARKLE_COL
    JSR PlotXY
    ; Sparkle 4 at (38, 15)
    LDX #38
    LDY #15
    LDA SPARKLE_COL
    JSR PlotXY
    RTS

SPARKLE_COL     .byte 0
SparkleColors   .byte 15, 7, 14, 0

; =============================================================================
; TEXT SHIMMER / COLOR CYCLING
; Gently shimmers "GRAND FRERE !" in Cyan / White
; =============================================================================
CycleTextShimmer:
    LDA FRAME_COUNTER
    AND #$1F            ; Every 32 frames
    BEQ +
    RTS
+   LDA STR_SHIMMER_IDX
    EOR #1
    STA STR_SHIMMER_IDX
    BNE _col_white
    LDA #14             ; Aqua
    STA TXT_COL
    JMP _redraw_frere
_col_white:
    LDA #15             ; White
    STA TXT_COL
_redraw_frere:
    LDA #7
    STA TXT_X
    LDA #19
    STA TXT_Y
    LDA #<STR_FRERE
    STA PTR_LO
    LDA #>STR_FRERE
    STA PTR_HI
    JSR RenderString

    ; Also refresh all greeting text every 64 frames to ensure permanent sharpness
    LDA FRAME_COUNTER
    AND #$3F
    BNE _shimmer_done

    ; Refresh "BON"
    LDA #14
    STA TXT_X
    LDA #1
    STA TXT_Y
    LDA #13
    STA TXT_COL
    LDA #<STR_BON
    STA PTR_LO
    LDA #>STR_BON
    STA PTR_HI
    JSR RenderString

    ; Refresh "ANNIV'"
    LDA #9
    STA TXT_X
    LDA #7
    STA TXT_Y
    LDA #9
    STA TXT_COL
    LDA #<STR_ANNIV
    STA PTR_LO
    LDA #>STR_ANNIV
    STA PTR_HI
    JSR RenderString

    ; Refresh "GRAND"
    LDA #10
    STA TXT_X
    LDA #13
    STA TXT_Y
    LDA #14
    STA TXT_COL
    LDA #<STR_GRAND
    STA PTR_LO
    LDA #>STR_GRAND
    STA PTR_HI
    JSR RenderString

_shimmer_done:
    RTS

STR_SHIMMER_IDX .byte 0

; =============================================================================
; BIRTHDAY TUNE PLAYER (SPEAKER ON STARTUP)
; Plays complete 25-note "Joyeux Anniversaire / Happy Birthday":
;   Phrase 1: Sol - Sol - La - Sol - Do - Si
;   Phrase 2: Sol - Sol - La - Sol - Ré - Do
;   Phrase 3: Sol - Sol - Sol(haut) - Mi - Do - Si - La
;   Phrase 4: Fa - Fa - Mi - Do - Ré - Do
; Can be interrupted at any millisecond if user presses a key!
; =============================================================================
NUM_TUNE_NOTES = 25

PlayBirthdayTune:
    LDX #0
TuneLoop:
    STX CURR_NOTE_IDX
    LDA TunePitches,X
    STA CURR_PITCH
    LDA TuneDurLo,X
    STA COUNT_LO
    LDA TuneDurHi,X
    STA COUNT_HI

    JSR PlayNote

    ; Check if key was pressed during note
    LDA KBD
    BMI TuneDone

    ; Update animations between notes so screen is alive!
    JSR UpdateFlames
    JSR UpdateConfetti
    JSR UpdateSparkles
    JSR CycleTextShimmer
    INC FRAME_COUNTER

    LDX CURR_NOTE_IDX
    INX
    CPX #NUM_TUNE_NOTES
    BNE TuneLoop

TuneDone:
    RTS

CURR_NOTE_IDX   .byte 0
CURR_PITCH      .byte 0
COUNT_LO        .byte 0
COUNT_HI        .byte 0

TunePitches:
    .byte 116, 116, 103, 116,  86,  92, 116, 116, 103, 116,  77,  86
    .byte 116, 116,  57,  68,  86,  92, 103,  64,  64,  68,  86,  77,  86

TuneDurLo:
    .byte $7D, $7D, $1A, $FB, $50, $75, $7D, $7D, $1A, $FB, $76, $A0
    .byte $7D, $7D, $F3, $A5, $50, $3A, $33, $DF, $DF, $A5, $50, $76, $47

TuneDurHi:
    .byte $00, $00, $01, $00, $01, $02, $00, $00, $01, $00, $01, $02
    .byte $00, $00, $01, $01, $01, $01, $02, $00, $00, $01, $01, $01, $03

PlayNote:
NoteLoop:
    BIT SPEAKER         ; Toggle speaker
    LDX CURR_PITCH
NoteInner:
    LDA KBD             ; Keyboard check every ~1 ms
    BMI NoteExit
    DEX
    BNE NoteInner

    ; 16-bit decrement of toggle count
    LDA COUNT_LO
    BNE +
    DEC COUNT_HI
+   DEC COUNT_LO
    LDA COUNT_LO
    ORA COUNT_HI
    BNE NoteLoop

    ; Small pause between notes (~25 ms) for clean articulation
    LDY #$0A
PauseOuter:
    LDX #$FF
PauseInner:
    LDA KBD
    BMI NoteExit
    DEX
    BNE PauseInner
    DEY
    BNE PauseOuter

NoteExit:
    RTS

; =============================================================================
; LOW-RES GRAPHICS LINE LOOKUP TABLES ($0400..$07FF)
; =============================================================================
LineTableLo:
    .byte $00, $80, $00, $80, $00, $80, $00, $80   ; Lines 0..7
    .byte $28, $A8, $28, $A8, $28, $A8, $28, $A8   ; Lines 8..15
    .byte $50, $D0, $50, $D0, $50, $D0, $50, $D0   ; Lines 16..23

LineTableHi:
    .byte $04, $04, $05, $05, $06, $06, $07, $07   ; Lines 0..7
    .byte $04, $04, $05, $05, $06, $06, $07, $07   ; Lines 8..15
    .byte $04, $04, $05, $05, $06, $06, $07, $07   ; Lines 16..23
