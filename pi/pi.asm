; ===================================================================
; PI STREAMING CALCULATOR - MULTI-PAGE DYNAMIC BUFFER
; Unbounded spigot (Gibbons / Lambert continued fraction)
; Memory range: $1000 to $8800 (5 bignums x 24 pages = 30 KB)
; Automatically expands active pages (1 to 24)
; Clean exit when buffer is full or user presses ESC
; ===================================================================

* = $1000
.cpu "6502"

; --- Apple II ROM ---
COUT     = $FDED
HOME     = $FC58
CROUT    = $FD8E
KBD      = $C000
KBDSTRB  = $C010
INVFLG   = $32

; --- Config ---
NUM_PAGES = 24          ; 24 pages = 6144 bytes per bignum (~1270 digits)

; --- Bignum base addresses (6 KB each, $1800-$8FFF) ---
; Leaves $0801-$0FFF intact for Applesoft BASIC program (HELLO)
BQ       = $1800        ; $1800 - $2FFF
BR       = $3000        ; $3000 - $47FF
BT       = $4800        ; $4800 - $5FFF
BX       = $6000        ; $6000 - $77FF
BY       = $7800        ; $7800 - $8FFF

; --- Bignum index table ---
IX_Q     = 0
IX_R     = 1
IX_T     = 2
IX_X     = 3
IX_Y     = 4

; --- Zero page (Official Apple II scratchpad $06-$09) ---
P1       = $06          ; bignum ptr 1 (2 bytes: $06-$07)
P2       = $08          ; bignum ptr 2 (2 bytes: $08-$09)

; ===================================================================
; MAIN
; ===================================================================
Start:
    tsx
    stx saved_sp        ; Save DOS 3.3 stack pointer
    bit KBDSTRB         ; Clear any pending keystroke from previous menu
    lda #$FF
    sta INVFLG          ; normal text mode
    jsr $FB2F           ; SETTXT: reset text window
    jsr HOME

    ; Print title
    ldx #0
-   lda TitleStr,x
    beq +
    ora #$80
    jsr COUT
    inx
    bne -
+   jsr CROUT

    ; Zero all 120 pages of BQ..BY ($1800..$8FFF)
    lda #<$1800
    sta P1
    lda #>$1800
    sta P1+1
    ldx #120            ; 24 * 5 = 120 pages
    lda #0
    ldy #0
clr_all_lp:
    sta (P1),y
    iny
    bne clr_all_lp
    inc P1+1
    dex
    bne clr_all_lp

    ; Q=1, R=0, T=1
    lda #1
    sta CUR_PAGES
    sta BQ
    sta BT
    sta KV
    lda #0
    sta KV+1
    sta RSGN
    sta DOTF
    sta OVF_FLAG

; --- Main loop ---
mlp:
    lda OVF_FLAG
    bne buf_full
    jsr try_ext
    bcc mabs
    jsr outd
    jsr check_kbd       ; Check key / pause after digit
    jmp mlp
mabs:
    jsr check_kbd       ; Check key / pause before absorbing term
    jsr absorb
    jmp mlp

buf_full:
    jsr CROUT
    ldx #0
-   lda StrBufFull,x
    beq +
    ora #$80
    jsr COUT
    inx
    bne -
+   jsr CROUT
    ldx #0
-   lda StrPressKey,x
    beq +
    ora #$80
    jsr COUT
    inx
    bne -
+   bit KBDSTRB
wait_key:
    lda KBD
    bpl wait_key
    sta KBDSTRB
    jmp clean_exit

; ===================================================================
; KEYBOARD CHECK & PAUSE HANDLER
; - ESC ($1B / $9B): clean exit and return to caller (RTS)
; - Any other key: PAUSE until next keypress (ESC quits, other resumes)
; ===================================================================
check_kbd:
    lda KBD             ; Check keyboard ($C000)
    bpl +               ; Bit 7 = 0 -> no key pressed, return
    sta KBDSTRB         ; Clear keyboard strobe ($C010)
    and #$7F            ; Strip high bit
    cmp #$1B            ; ESC key?
    beq clean_exit      ; Yes -> return cleanly to caller

    ; Any other key pressed -> PAUSE!
pause_loop:
    lda KBD
    bpl pause_loop      ; Wait for next keypress
    sta KBDSTRB         ; Clear keyboard strobe
    and #$7F
    cmp #$1B            ; ESC pressed during pause?
    beq clean_exit      ; Yes -> return cleanly to caller
    ; Any other key -> resume streaming
+   rts

; ===================================================================
; CLEAN EXIT TO CALLER (ESC KEY OR BUFFER FULL)
; ===================================================================
clean_exit:
    sta KBDSTRB         ; Clear keyboard strobe ($C010)
    lda #$FF
    sta INVFLG          ; Normal text mode (White on Black, INVFLG = $FF)
    jsr $FB2F           ; SETTXT: Reset text window to full 40x24 (0, 40, 0, 24)
    jsr CROUT           ; Carriage return ($FD8E)
    sta KBDSTRB         ; Clear keyboard strobe again
    ldx saved_sp        ; Restore caller stack pointer
    txs

    ; Check if stack has a valid 2-byte return address from JSR
    cpx #$FE
    bcs fallback_exit   ; Stack empty ($FE or $FF) -> fallback

    ; Read high byte of return address on stack (at $0102,x)
    inx
    inx
    lda $0100,x         ; A = High byte of return address
    ldx saved_sp
    txs

    ; Validate high byte:
    ; $C0..$C7: Hardware I/O / slot ROM (never valid caller code)
    ; $00..$01: Zero page / stack page (never valid caller code)
    cmp #$C0
    bcc +
    cmp #$C8
    bcc fallback_exit   ; In $C0..$C7 -> invalid!
+   cmp #$02
    bcc fallback_exit   ; < $0200 -> invalid!

    ; Valid return address on stack -> return cleanly to caller!
    rts

fallback_exit:
    ; No valid JSR caller: clean exit to Applesoft / DOS 3.3 prompt
    lda $3D0
    cmp #$4C            ; DOS 3.3 warm start vector present?
    bne +
    jmp $3D0            ; DOS 3.3 warm restart -> Applesoft prompt ']'
+   jmp $E003           ; Applesoft BASIC ROM warm restart -> prompt ']'

; Local variables (in RAM / code segment, no zero-page conflict)
saved_sp:    .byte 0
MLO:         .byte 0    ; multiplier lo
MHI:         .byte 0    ; multiplier hi
KV:          .byte 0, 0 ; term counter (lo, hi)
CYL:         .byte 0    ; carry lo
CYH:         .byte 0    ; carry hi
MC:          .byte 0    ; multiplicand (mul8x8)
MT:          .byte 0    ; mul temp
RL:          .byte 0    ; result lo
RH:          .byte 0    ; result hi
A0:          .byte 0    ; accum bytes
A1:          .byte 0
A2:          .byte 0
RSGN:        .byte 0    ; R sign: 0=pos, 1=neg
DIG:         .byte 0    ; current digit
DOTF:        .byte 0    ; dot printed flag
SY:          .byte 0
V4K2:        .word 0
V2K1:        .word 0
CUR_PAGES:   .byte 1
OVF_FLAG:    .byte 0
PG_CTR:      .byte 0
PTR_H_SAVE:  .byte 0
PTR2_H_SAVE: .byte 0
P1_TOP_H:    .byte 0
P2_TOP_H:    .byte 0

; ===================================================================
; OUTPUT DIGIT
; ===================================================================
outd:
    lda DOTF
    bne od2
    lda DIG
    ora #$B0
    jsr COUT
    lda #$AE            ; "."
    jsr COUT
    inc DOTF
    rts
od2:
    lda DIG
    ora #$B0
    jsr COUT
    rts

; ===================================================================
; TRY EXTRACT - returns C=1 if extracted (digit in DIG), C=0 if not
; ===================================================================
try_ext:
    ; --- d3 = floor((3Q+R)/T) ---
    ldx #IX_X
    ldy #IX_Q
    jsr sp12
    jsr b_cpy           ; X = Q
    ldx #IX_X
    jsr sp1
    lda #3
    sta MLO
    lda #0
    sta MHI
    jsr b_muls          ; X = 3Q

    ; X += signed R
    jsr addR_X
    bcs +
    clc
    rts
+

    ; d3 = X / T
    ldx #IX_X
    ldy #IX_T
    jsr sp12
    jsr b_divb
    sta DIG

    ; --- d4 = floor((4Q+R)/T) ---
    ldx #IX_X
    ldy #IX_Q
    jsr sp12
    jsr b_cpy
    ldx #IX_X
    jsr sp1
    lda #4
    sta MLO
    lda #0
    sta MHI
    jsr b_muls

    jsr addR_X
    bcc te_no

    ldx #IX_X
    ldy #IX_T
    jsr sp12
    jsr b_divb

    cmp DIG
    bne te_no

    ; --- EXTRACT digit DIG ---
    ; X = DIG * T
    ldx #IX_X
    ldy #IX_T
    jsr sp12
    jsr b_cpy
    ldx #IX_X
    jsr sp1
    lda DIG
    sta MLO
    lda #0
    sta MHI
    jsr b_muls          ; X = d*T

    ; R = R - X (signed)
    jsr subX_from_R

    ; Q *= 10
    ldx #IX_Q
    jsr sp1
    lda #10
    sta MLO
    lda #0
    sta MHI
    jsr b_muls

    ; R *= 10 (magnitude; sign preserved)
    ldx #IX_R
    jsr sp1
    lda #10
    sta MLO
    lda #0
    sta MHI
    jsr b_muls

    sec
    rts
te_no:
    clc
    rts

; ===================================================================
; ABSORB TERM K
; new_R = Q*(4K+2) + R*(2K+1)   [signed]
; new_Q = Q*K
; new_T = T*(2K+1)
; ===================================================================
absorb:
    ; Compute 4K+2
    lda KV
    asl
    sta V4K2
    lda KV+1
    rol
    sta V4K2+1          ; 2K
    asl V4K2
    rol V4K2+1          ; 4K
    clc
    lda V4K2
    adc #2
    sta V4K2
    bcc +
    inc V4K2+1
+
    ; Compute 2K+1
    lda KV
    asl
    sta V2K1
    lda KV+1
    rol
    sta V2K1+1          ; 2K
    clc
    lda V2K1
    adc #1
    sta V2K1
    bcc +
    inc V2K1+1
+
    ; X = Q * (4K+2)
    ldx #IX_X
    ldy #IX_Q
    jsr sp12
    jsr b_cpy
    ldx #IX_X
    jsr sp1
    lda V4K2
    sta MLO
    lda V4K2+1
    sta MHI
    jsr b_muls

    ; Y = R * (2K+1)  [magnitude; sign = RSGN]
    ldx #IX_Y
    ldy #IX_R
    jsr sp12
    jsr b_cpy
    ldx #IX_Y
    jsr sp1
    lda V2K1
    sta MLO
    lda V2K1+1
    sta MHI
    jsr b_muls

    ; new_R = X + signed(Y)
    lda RSGN
    bne ab_rneg

    ; R positive: X += Y, result positive
    ldx #IX_X
    ldy #IX_Y
    jsr sp12
    jsr b_add
    lda #0
    sta RSGN
    jmp ab_copyR

ab_rneg:
    ; R negative: X -= Y
    ldx #IX_X
    ldy #IX_Y
    jsr sp12
    jsr b_cmp
    bcs ab_xbig

    ; Y > X: result = Y-X, negative
    ldx #IX_Y
    ldy #IX_X
    jsr sp12
    jsr b_sub           ; Y -= X
    ldx #IX_X
    ldy #IX_Y
    jsr sp12
    jsr b_cpy
    lda #1
    sta RSGN
    jmp ab_copyR

ab_xbig:
    ; X >= Y: X -= Y, positive
    jsr b_sub
    lda #0
    sta RSGN

ab_copyR:
    ; R = X
    ldx #IX_R
    ldy #IX_X
    jsr sp12
    jsr b_cpy

    ; Q *= K
    ldx #IX_Q
    jsr sp1
    lda KV
    sta MLO
    lda KV+1
    sta MHI
    jsr b_muls

    ; T *= (2K+1)
    ldx #IX_T
    jsr sp1
    lda V2K1
    sta MLO
    lda V2K1+1
    sta MHI
    jsr b_muls

    ; K++
    inc KV
    bne +
    inc KV+1
+   rts

; ===================================================================
; HELPER: add signed R to BX (TMP1)
; Sets P1=BX, P2=BR. Returns C=1 if result>=0, C=0 if negative.
; ===================================================================
addR_X:
    ldx #IX_X
    ldy #IX_R
    jsr sp12            ; P1=X, P2=R

    lda RSGN
    bne arx_neg

    ; R positive: X += R
    jsr b_add
    sec
    rts

arx_neg:
    ; R negative: X -= |R|
    jsr b_cmp           ; X vs R
    bcs arx_ok
    ; X < R: result negative
    clc
    rts
arx_ok:
    jsr b_sub           ; X -= R (ptrs set)
    sec
    rts

; ===================================================================
; HELPER: R = R - BX (signed subtraction)
; BX is always positive (= d*T)
; ===================================================================
subX_from_R:
    lda RSGN
    bne sxr_neg

    ; R positive: R -= X
    ldx #IX_R
    ldy #IX_X
    jsr sp12
    jsr b_cmp
    bcs sxr_rsub
    ; R < X: result = X-R, negative
    ldx #IX_X
    ldy #IX_R
    jsr sp12
    jsr b_sub           ; X -= R
    ldx #IX_R
    ldy #IX_X
    jsr sp12
    jsr b_cpy
    lda #1
    sta RSGN
    rts

sxr_rsub:
    ; R >= X: R -= X
    jsr b_sub           ; ptrs set from b_cmp
    rts

sxr_neg:
    ; R negative: |R| += X, stays negative
    ldx #IX_R
    ldy #IX_X
    jsr sp12
    jsr b_add
    rts

; ===================================================================
; POINTER SETUP
; ===================================================================
sp1:
    lda AddrTblL,x
    sta P1
    lda AddrTblH,x
    sta P1+1
    rts

sp12:
    lda AddrTblL,x
    sta P1
    lda AddrTblH,x
    sta P1+1
    lda AddrTblL,y
    sta P2
    lda AddrTblH,y
    sta P2+1
    rts

AddrTblL: .byte <BQ, <BR, <BT, <BX, <BY
AddrTblH: .byte >BQ, >BR, >BT, >BX, >BY

; ===================================================================
; 8x8 UNSIGNED MULTIPLY:  A * MC -> RH:RL
; ===================================================================
mul88:
    sta MT
    lda #0
    ldx #8
m8lp:
    lsr MT
    bcc m8sk
    clc
    adc MC
m8sk:
    ror
    ror RL
    dex
    bne m8lp
    sta RH
    rts

; ===================================================================
; BIGNUM CLEAR: zero CUR_PAGES pages at (P1)
; ===================================================================
b_clr:
    lda P1+1
    sta PTR_H_SAVE
    lda CUR_PAGES
    sta PG_CTR
    lda #0
    ldy #0
bcl_lp:
    sta (P1),y
    iny
    bne bcl_lp
    inc P1+1
    dec PG_CTR
    bne bcl_lp
    lda PTR_H_SAVE
    sta P1+1
    rts

; ===================================================================
; BIGNUM COPY: (P1) = (P2), CUR_PAGES pages
; ===================================================================
b_cpy:
    lda P1+1
    sta PTR_H_SAVE
    lda P2+1
    sta PTR2_H_SAVE
    lda CUR_PAGES
    sta PG_CTR
    ldy #0
bcp_lp:
    lda (P2),y
    sta (P1),y
    iny
    bne bcp_lp
    inc P1+1
    inc P2+1
    dec PG_CTR
    bne bcp_lp
    lda PTR_H_SAVE
    sta P1+1
    lda PTR2_H_SAVE
    sta P2+1
    rts

; ===================================================================
; BIGNUM ADD: (P1) += (P2), CUR_PAGES pages
; ===================================================================
b_add:
    lda P1+1
    sta PTR_H_SAVE
    lda P2+1
    sta PTR2_H_SAVE
    lda CUR_PAGES
    sta PG_CTR
    clc
    ldy #0
bad_lp:
    lda (P1),y
    adc (P2),y
    sta (P1),y
    iny
    bne bad_lp
    inc P1+1
    inc P2+1
    dec PG_CTR
    bne bad_lp

    bcc bad_done
    ; Top page carried!
    lda CUR_PAGES
    cmp #NUM_PAGES
    bcs bad_ovf
    ldy #0
    lda #1
    sta (P1),y
    inc CUR_PAGES
    bne bad_done
bad_ovf:
    lda #1
    sta OVF_FLAG
bad_done:
    lda PTR_H_SAVE
    sta P1+1
    lda PTR2_H_SAVE
    sta P2+1
    rts

; ===================================================================
; BIGNUM SUB: (P1) -= (P2), CUR_PAGES pages (assumes P1 >= P2)
; ===================================================================
b_sub:
    lda P1+1
    sta PTR_H_SAVE
    lda P2+1
    sta PTR2_H_SAVE
    lda CUR_PAGES
    sta PG_CTR
    sec
    ldy #0
bsb_lp:
    lda (P1),y
    sbc (P2),y
    sta (P1),y
    iny
    bne bsb_lp
    inc P1+1
    inc P2+1
    dec PG_CTR
    bne bsb_lp
    lda PTR_H_SAVE
    sta P1+1
    lda PTR2_H_SAVE
    sta P2+1
    rts

; ===================================================================
; BIGNUM COMPARE: (P1) vs (P2), unsigned
; Returns C=1 if P1>=P2, C=0 if P1<P2
; ===================================================================
b_cmp:
    lda P1+1
    sta PTR_H_SAVE
    lda P2+1
    sta PTR2_H_SAVE

    clc
    lda P1+1
    adc CUR_PAGES
    sec
    sbc #1
    sta P1_TOP_H

    clc
    lda P2+1
    adc CUR_PAGES
    sec
    sbc #1
    sta P2_TOP_H

    lda CUR_PAGES
    sta PG_CTR

bcmp_page:
    lda P1_TOP_H
    sta P1+1
    lda P2_TOP_H
    sta P2+1
    ldy #$FF
bcmp_byte:
    lda (P1),y
    cmp (P2),y
    bcc bcmp_lt
    bne bcmp_gt
    dey
    cpy #$FF
    bne bcmp_byte

    dec P1_TOP_H
    dec P2_TOP_H
    dec PG_CTR
    bne bcmp_page
    sec
    bcs bcmp_done

bcmp_lt:
    clc
    bcc bcmp_done
bcmp_gt:
    sec

bcmp_done:
    php
    lda PTR_H_SAVE
    sta P1+1
    lda PTR2_H_SAVE
    sta P2+1
    plp
    rts

; ===================================================================
; BIGNUM MUL SMALL: (P1) *= MLO:MHI (16-bit), unsigned
; ===================================================================
b_muls:
    lda P1+1
    sta PTR_H_SAVE
    lda CUR_PAGES
    sta PG_CTR
    lda #0
    sta CYL
    sta CYH
    ldy #0

bms_page:
bms_lp:
    lda (P1),y
    sta MC
    sty SY

    ; MC * MLO -> RH:RL
    lda MLO
    jsr mul88

    clc
    lda RL
    adc CYL
    sta A0
    lda RH
    adc CYH
    sta A1
    lda #0
    adc #0
    sta A2

    lda MHI
    beq bms_noh
    jsr mul88
    clc
    lda A1
    adc RL
    sta A1
    lda A2
    adc RH
    sta A2
bms_noh:
    ldy SY
    lda A0
    sta (P1),y
    lda A1
    sta CYL
    lda A2
    sta CYH

    iny
    bne bms_lp
    inc P1+1
    dec PG_CTR
    bne bms_page

    ; Check carry out of top page
    lda CYL
    ora CYH
    beq bms_done

    lda CUR_PAGES
    cmp #NUM_PAGES
    bcs bms_ovf
    ldy #0
    lda CYL
    sta (P1),y
    iny
    lda CYH
    sta (P1),y
    inc CUR_PAGES
    bne bms_done
bms_ovf:
    lda #1
    sta OVF_FLAG
bms_done:
    lda PTR_H_SAVE
    sta P1+1
    rts

; ===================================================================
; BIGNUM DIV BYTE: floor((P1) / (P2)) -> A (single byte 0-9)
; Destructive: modifies (P1) (leaves remainder)
; ===================================================================
b_divb:
    ldx #0
bdlp:
    jsr b_cmp
    bcc bddone      ; P1 < P2 -> done
    jsr b_sub        ; P1 -= P2
    inx
    jmp bdlp
bddone:
    txa
    rts

; ===================================================================
; DATA
; ===================================================================
TitleStr:   .text "PI (ESC:QUITTER - TOUCHE:PAUSE):",0
StrBufFull: .text "[FIN MEMOIRE TAMPON (LIMITE ATTEINTE)]",0
StrPressKey: .text "PRESSEZ UNE TOUCHE POUR QUITTER...",0
