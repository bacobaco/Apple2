; ============================================
; SNAKE GAME FOR APPLE II - SPEED & ACCEL (KIMI)
; Assembleur: 64tass
; Adresse: $6000
; ============================================

; Adresses Matériel
KEYBOARD    = $C000
KEYSTROBE   = $C010
HOME        = $FC58

; Pointeur Temporaire
PTR_L        = $EB
PTR_H        = $EC

; Mapping Page 3
SNAKE_LEN    = $0300
SNAKE_DIR    = $0301
HEAD_PTR     = $0302
TAIL_PTR     = $0303
APPLE_X      = $0304
APPLE_Y      = $0305
BCD_SCORE_L  = $0306
BCD_SCORE_H  = $0307
GAME_OVER_F  = $0308
SPEED        = $0309
RANDOM       = $030A
NEW_X        = $030B
NEW_Y        = $030C
CHECK_X      = $030D
CHECK_Y      = $030E
ATE_APPLE_F  = $030F
DRAW_X       = $0310
DRAW_Y       = $0311
DRAW_CHAR    = $0312
TEMP_X       = $0313

        * = $6000

START:
        JSR INIT_GAME
        
GAME_LOOP:
        LDA GAME_OVER_F
        BNE GAME_ENDED
        
        JSR READ_INPUT
        JSR MOVE_SNAKE
        JSR CHECK_COLLISION
        JSR DRAW_SNAKE
        JSR DRAW_APPLE
        JSR DRAW_SCORE
        
        INC RANDOM      
        JSR DELAY
        
        JMP GAME_LOOP

GAME_ENDED:
        JSR SHOW_GAME_OVER
        JSR WAIT_KEY
        JMP START

INIT_GAME:
        JSR HOME
        LDA #5
        STA SNAKE_LEN
        LDA #0
        STA HEAD_PTR
        STA TAIL_PTR
        STA BCD_SCORE_L
        STA BCD_SCORE_H
        STA GAME_OVER_F
        STA ATE_APPLE_F
        LDA #1
        STA SNAKE_DIR
        LDA #$30        ; VITESSE INITIALE DIVISÉE PAR 3
        STA SPEED
        LDA $4E
        ORA #$01
        STA RANDOM
        
        LDX #0
_clr:   
        LDA #0
        STA SNAKE_X,X
        STA SNAKE_Y,X
        INX
        BNE _clr

        LDX #0
_init:  
        TXA
        CLC
        ADC #10
        STA SNAKE_X,X
        LDA #12
        STA SNAKE_Y,X
        INX
        CPX #5
        BCC _init
        
        DEX
        STX HEAD_PTR
        JSR SPAWN_APPLE
        RTS

READ_INPUT:
        LDA KEYBOARD
        BPL _no_key
        STA KEYSTROBE
        CMP #$9B            ; ESC (Retour Applesoft BASIC)
        BEQ _esc
        CMP #$8B
        BEQ _up
        CMP #$DA
        BEQ _up
        CMP #$8A
        BEQ _dw
        CMP #$D3
        BEQ _dw
        CMP #$88
        BEQ _lf
        CMP #$D1
        BEQ _lf
        CMP #$95
        BEQ _rt
        CMP #$C4
        BEQ _rt
_no_key: 
        RTS

_esc:
        JSR HOME
        JMP $E003

_up: 
        LDA SNAKE_DIR
        CMP #2
        BEQ _no_key
        LDA #0
        STA SNAKE_DIR
        RTS
_rt: 
        LDA SNAKE_DIR
        CMP #3
        BEQ _no_key
        LDA #1
        STA SNAKE_DIR
        RTS
_dw: 
        LDA SNAKE_DIR
        CMP #0
        BEQ _no_key
        LDA #2
        STA SNAKE_DIR
        RTS
_lf: 
        LDA SNAKE_DIR
        CMP #1
        BEQ _no_key
        LDA #3
        STA SNAKE_DIR
        RTS

MOVE_SNAKE:
        LDX HEAD_PTR
        LDA SNAKE_X,X
        STA NEW_X
        LDA SNAKE_Y,X
        STA NEW_Y
        
        LDA SNAKE_DIR
        BEQ _m_up
        CMP #1
        BEQ _m_rt
        CMP #2
        BEQ _m_dw
_m_lf:  
        DEC NEW_X
        JMP _wrap
_m_rt:  
        INC NEW_X
        JMP _wrap
_m_up:  
        DEC NEW_Y
        JMP _wrap
_m_dw:  
        INC NEW_Y

_wrap:
        LDA NEW_X
        CMP #$FF
        BNE _x1
        LDA #39
        STA NEW_X
_x1:    
        LDA NEW_X
        CMP #40
        BCC _y1
        LDA #0
        STA NEW_X
_y1:    
        LDA NEW_Y
        CMP #$FF
        BNE _y2
        LDA #23
        STA NEW_Y
_y2:    
        LDA NEW_Y
        CMP #24
        BCC _ok
        LDA #0
        STA NEW_Y
_ok:
        INC HEAD_PTR
        LDX HEAD_PTR
        LDA NEW_X
        STA SNAKE_X,X
        LDA NEW_Y
        STA SNAKE_Y,X
        RTS

CHECK_COLLISION:
        LDA NEW_X
        CMP APPLE_X
        BNE _no_a
        LDA NEW_Y
        CMP APPLE_Y
        BNE _no_a
        
        LDA #1
        STA ATE_APPLE_F
        ; ACCELÉRATION : On diminue SPEED
        LDA SPEED
        CMP #2          ; Limite de vitesse (ne pas descendre sous 1)
        BCC _no_more_accel
        DEC SPEED
_no_more_accel:
        ; Mise à jour du score
        SED
        CLC
        LDA BCD_SCORE_L
        ADC #1
        STA BCD_SCORE_L
        LDA BCD_SCORE_H
        ADC #0
        STA BCD_SCORE_H
        CLD
        JSR SPAWN_APPLE
        RTS
_no_a:  
        JSR CHECK_SELF
        RTS

CHECK_SELF:
        LDX TAIL_PTR
_sl:    
        CPX HEAD_PTR
        BEQ _sd
        LDA SNAKE_X,X
        CMP NEW_X
        BNE _sn
        LDA SNAKE_Y,X
        CMP NEW_Y
        BNE _sn
        LDA #1
        STA GAME_OVER_F
        RTS
_sn:    
        INX
        JMP _sl
_sd:    
        RTS

DRAW_SNAKE:
        LDA ATE_APPLE_F
        BNE _ne
        LDX TAIL_PTR
        LDA SNAKE_X,X
        STA DRAW_X
        LDA SNAKE_Y,X
        STA DRAW_Y
        LDA #$A0
        STA DRAW_CHAR
        JSR PLOT
        INC TAIL_PTR
_ne:    
        LDA #0
        STA ATE_APPLE_F
        
        LDX TAIL_PTR
_dl:    
        CPX HEAD_PTR
        BEQ _dh
        LDA SNAKE_X,X
        STA DRAW_X
        LDA SNAKE_Y,X
        STA DRAW_Y
        LDA #$EF
        STA DRAW_CHAR
        JSR PLOT
        INX
        JMP _dl
_dh:    
        LDA SNAKE_X,X
        STA DRAW_X
        LDA SNAKE_Y,X
        STA DRAW_Y
        LDA #$C0
        STA DRAW_CHAR
        JSR PLOT
        RTS

DRAW_SCORE:
        LDA #0
        STA DRAW_Y
        LDA #30
        STA DRAW_X
        LDA #$D3        ; 'S'
        STA DRAW_CHAR
        JSR PLOT
        INC DRAW_X
        LDA #$C3        ; 'C'
        STA DRAW_CHAR
        JSR PLOT
        INC DRAW_X
        LDA #$BA        ; ':'
        STA DRAW_CHAR
        JSR PLOT
        INC DRAW_X
        LDA BCD_SCORE_H
        AND #$0F
        ORA #$B0
        STA DRAW_CHAR
        JSR PLOT
        INC DRAW_X
        LDA BCD_SCORE_L
        LSR
        LSR
        LSR
        LSR
        ORA #$B0
        STA DRAW_CHAR
        JSR PLOT
        INC DRAW_X
        LDA BCD_SCORE_L
        AND #$0F
        ORA #$B0
        STA DRAW_CHAR
        JSR PLOT
        RTS

SPAWN_APPLE:
        JSR RANDOM_NUM
        AND #$3F
        CMP #40
        BCS SPAWN_APPLE
        STA APPLE_X
_ya:    
        JSR RANDOM_NUM
        AND #$1F
        CMP #24
        BCS _ya
        STA APPLE_Y
        RTS

RANDOM_NUM:
        LDA RANDOM
        ASL
        BCC _rn
        EOR #$1D
_rn:    
        STA RANDOM
        RTS

DRAW_APPLE:
        LDA APPLE_X
        STA DRAW_X
        LDA APPLE_Y
        STA DRAW_Y
        LDA #$AA
        STA DRAW_CHAR
        JSR PLOT
        RTS

PLOT:
        STX TEMP_X
        LDX DRAW_Y
        LDA SCREEN_LO,X
        STA PTR_L
        LDA SCREEN_HI,X
        STA PTR_H
        LDY DRAW_X
        LDA DRAW_CHAR
        STA (PTR_L),Y
        LDX TEMP_X
        RTS

DELAY:
        LDX SPEED
_o:     
        LDY #$00
_i:     
        NOP
        DEY
        BNE _i
        DEX
        BNE _o
        RTS

SHOW_GAME_OVER:
        JSR HOME
        LDX #10
        LDA SCREEN_LO,X
        STA PTR_L
        LDA SCREEN_HI,X
        STA PTR_H
        LDY #15
        LDX #0
_p:     
        LDA MSG,X
        BEQ _do
        ORA #$80
        STA (PTR_L),Y
        INX
        INY
        JMP _p
_do:    
        RTS

WAIT_KEY:
        LDA KEYBOARD
        BPL WAIT_KEY
        STA KEYSTROBE
        CMP #$9B            ; ESC (Retour Applesoft BASIC)
        BEQ _esc_wk
        RTS
_esc_wk:
        PLA                 ; Depile l'adresse de retour
        PLA
        JSR HOME
        JMP $E003

MSG:       .text "GAME OVER!"
           .byte 0
SCREEN_LO: .byte $00,$80,$00,$80,$00,$80,$00,$80, $28,$A8,$28,$A8,$28,$A8,$28,$A8, $50,$D0,$50,$D0,$50,$D0,$50,$D0
SCREEN_HI: .byte $04,$04,$05,$05,$06,$06,$07,$07, $04,$04,$05,$05,$06,$06,$07,$07, $04,$04,$05,$05,$06,$06,$07,$07

SNAKE_X:     .fill 256, 0 
SNAKE_Y:     .fill 256, 0

        .end
