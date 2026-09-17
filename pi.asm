; ===================================================================
; PI GENERATOR - 4000 DIGITS - POWER VERSION
; ===================================================================

* = $0800 ; Code at $0800 (starts after Page 1 text)

.cpu "6502"

; Apple II Registers
COUT     = $FDED    
HOME     = $FC58    
CROUT    = $FD8E    
KBD      = $C000    
KBDSTRB  = $C010    

; Zero Page
PTR      = $06      
ACC      = $08      
ACC_HI   = $09
ACC_UH   = $0A
DIV      = $0B      
DIV_HI   = $0C
QUO      = $0D      
REM      = $0E      
REM_HI   = $0F
I_CTR    = $10      
I_CTR_HI = $11
ND_CTR   = $12      
ND_CTR_HI = $13
N9S      = $14      
N9S_HI   = $15
PREDIGIT = $16      
TEMP     = $17      
T1       = $18      
T2       = $19
T3       = $1A
S1       = $1B
S2       = $1C
S3       = $1D
DOT_FLAG = $1E

; Config
NDIGITS  = 4000     
LEN      = 13334    
A_ARRAY  = $1000    

Start:
    jsr HOME
    
    ldx #0
_pt_loop:
    lda Title,x
    beq _pt_done
    jsr COUT
    inx
    jmp _pt_loop
_pt_done:
    jsr CROUT

    lda #0
    sta N9S
    sta N9S_HI
    sta DOT_FLAG
    lda #$FF
    sta PREDIGIT

    ; Init Array to 2
    lda #<A_ARRAY
    sta PTR
    lda #>A_ARRAY
    sta PTR+1
    lda #<LEN
    sta TEMP
    lda #>LEN
    sta TEMP+1
_init_loop:
    ldy #0
    lda #2
    sta (PTR),y
    iny
    lda #0
    sta (PTR),y
    clc
    lda PTR
    adc #2
    sta PTR
    bcc _iskip
    inc PTR+1
_iskip:
    lda TEMP
    bne _idec
    dec TEMP+1
_idec:
    dec TEMP
    lda TEMP
    ora TEMP+1
    bne _init_loop

    ; --- Main Digit Loop ---
    lda #<NDIGITS
    sta ND_CTR
    lda #>NDIGITS
    sta ND_CTR_HI

_digit_loop:
    lda #0
    sta QUO
    lda #<LEN
    sta I_CTR
    lda #>LEN
    sta I_CTR_HI
    lda #< (A_ARRAY + (LEN-1)*2)
    sta PTR
    lda #> (A_ARRAY + (LEN-1)*2)
    sta PTR+1

_inner_loop:
    lda #0
    sta ACC
    sta ACC_HI
    sta ACC_UH
    lda QUO
    beq _no_q
    tax
_mul_loop:
    clc
    lda ACC
    adc I_CTR
    sta ACC
    lda ACC_HI
    adc I_CTR_HI
    sta ACC_HI
    lda ACC_UH
    adc #0
    sta ACC_UH
    dex
    bne _mul_loop
_no_q:

    ldy #0
    lda (PTR),y
    sta T1
    iny
    lda (PTR),y
    sta T2
    lda #0
    sta T3
    
    asl T1
    rol T2
    rol T3
    
    lda T1
    sta S1
    lda T2
    sta S2
    lda T3
    sta S3
    
    asl T1
    rol T2
    rol T3
    asl T1
    rol T2
    rol T3
    
    clc
    lda ACC
    adc T1
    sta ACC
    lda ACC_HI
    adc T2
    sta ACC_HI
    lda ACC_UH
    adc T3
    sta ACC_UH
    
    clc
    lda ACC
    adc S1
    sta ACC
    lda ACC_HI
    adc S2
    sta ACC_HI
    lda ACC_UH
    adc S3
    sta ACC_UH

    lda I_CTR
    asl
    sta DIV
    lda I_CTR_HI
    rol
    sta DIV_HI
    
    lda DIV
    bne _dsub
    dec DIV_HI
_dsub:
    dec DIV
    
    jsr _div24_16
    
    ldy #0
    lda REM
    sta (PTR),y
    iny
    lda REM_HI
    sta (PTR),y
    
    sec
    lda PTR
    sbc #2
    sta PTR
    bcs _pskip
    dec PTR+1
_pskip:
    lda I_CTR
    bne _icskip
    dec I_CTR_HI
_icskip:
    dec I_CTR
    lda I_CTR
    ora I_CTR_HI
    beq _inner_done
    jmp _inner_loop
_inner_done:

    lda QUO
    sta ACC
    lda #0
    sta ACC_HI
    sta ACC_UH
    lda #10
    sta DIV
    lda #0
    sta DIV_HI
    jsr _div24_16 
    
    lda REM
    sta A_ARRAY
    lda #0
    sta A_ARRAY+1
    
    lda QUO
    ldx PREDIGIT
    cpx #$FF
    bne _not_first
    sta PREDIGIT
    jmp _digit_done

_not_first:
    cmp #9
    beq _digit_9
    cmp #10
    beq _digit_10

_digit_normal:
    lda PREDIGIT
    jsr _out_digit
    lda DOT_FLAG
    bne _no_dot
    lda #$AE
    jsr COUT
    inc DOT_FLAG
_no_dot:
    jsr _out_n9s
    lda QUO
    sta PREDIGIT
    jmp _digit_done

_digit_9:
    inc N9S
    bne _d9skip
    inc N9S_HI
_d9skip:
    jmp _digit_done

_digit_10:
    lda PREDIGIT
    clc
    adc #1
    jsr _out_digit
    jsr _out_n9zeros
    lda #0
    sta PREDIGIT

_digit_done:
    lda KBD
    cmp #$9B
    beq _exit
    lda ND_CTR
    bne _ndskip
    dec ND_CTR_HI
_ndskip:
    dec ND_CTR
    lda ND_CTR
    ora ND_CTR_HI
    beq _exit
    jmp _digit_loop

_exit:
    bit KBDSTRB
    lda PREDIGIT
    jsr _out_digit
    jsr CROUT
    rts

Title: .text "PI GENERATOR (4000 DIGITS):",0

_out_digit:
    ora #$B0
    jsr COUT
    rts

_out_n9s:
_n9_loop:
    lda N9S
    ora N9S_HI
    beq _n9_done
    lda #9
    jsr _out_digit
    lda N9S
    bne _n9_s1
    dec N9S_HI
_n9_s1:
    dec N9S
    jmp _n9_loop
_n9_done:
    rts

_out_n9zeros:
_n0_loop:
    lda N9S
    ora N9S_HI
    beq _n0_done
    lda #0
    jsr _out_digit
    lda N9S
    bne _n0_s2
    dec N9S_HI
_n0_s2:
    dec N9S
    jmp _n0_loop
_n0_done:
    rts

_div24_16:
    lda #0
    sta REM
    sta REM_HI
    ldx #24
_d_loop:
    asl ACC
    rol ACC_HI
    rol ACC_UH
    rol REM
    rol REM_HI
    sec
    lda REM
    sbc DIV
    sta TEMP
    lda REM_HI
    sbc DIV_HI
    bcc _d_skip
    sta REM_HI
    lda TEMP
    sta REM
    inc ACC
_d_skip:
    dex
    bne _d_loop
    lda ACC
    sta QUO
    rts
