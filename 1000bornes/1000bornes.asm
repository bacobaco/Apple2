; =============================================================================
; 1000 BORNES POUR APPLE II (6502) - REPLIQUE GRAPHIQUE HGR THOMSON MO5
; Auteur original : J.Y. Boucrot (1985, Free Game Blot & Dujardin International)
; Adaptation complete Apple II Haute Resolution (HGR 280x192) par Antigravity
; Compatible assembleur 64tass (F5 / Apple2TS Studio)
; =============================================================================

.cpu "6502"
* = $4000

    jmp MainInit

; =============================================================================
; CONSTANTES MATERIELLES APPLE II
; =============================================================================
KBD         = $C000     ; Touche pressee si bit 7 = 1
KBDSTRB     = $C010     ; Acquittement frappe clavier
SPEAKER     = $C030     ; Clic haut-parleur
TXTCLR      = $C050     ; Mode graphique
TXTSET      = $C051     ; Mode texte
MIXCLR      = $C052     ; Plein ecran graphique (pas de split texte)
TXTPAGE1    = $C054     ; Page 1 ($2000-$3FFF)
HIRES       = $C057     ; Haute Resolution (280x192)

; =============================================================================
; VARIABLES ZERO-PAGE (CHACUNE DEDIEE POUR EVITER TOUT CONFLIT)
; =============================================================================
PTR_LO      = $06
PTR_HI      = $07
PTR2_LO     = $08
PTR2_HI     = $09

HGR_COL     = $E0       ; Colonne octet (0..39)
HGR_ROW     = $E1       ; Rangée texte (0..23)
STR_LO      = $E2       ; Pointeur de chaine
STR_HI      = $E3
CARD_COL    = $E4       ; Colonne octet pour carte
CARD_SCAN   = $E5       ; Scanline Y pour carte
CARD_ID     = $E6       ; Type de carte (0..20)
SLOT_NUM    = $E7       ; Emplacement (1..20)
STR_IDX     = $E8       ; Index d'iteration chaine (independant)
DEC_IDX     = $E9       ; Index d'iteration decimal (independant)
CHAR_Y      = $EA       ; Index scanline caractere (independant)
CARD_Y      = $ED       ; Index scanline carte (independant)
INV_FLAG    = $EE       ; $00 = normal, $7F = cartouche blanc, $2A/$55/$AA = blanc sur couleur

RND_SEED    = $EB       ; 2 octets pour LFSR ($EB, $EC)
HAND_X      = $F7       ; Index boucle main joueur (isole pour eviter tout conflit)
ERASE_B1    = $F8       ; Octet remplissage 1 pour EraseSlot
ERASE_B2    = $F9       ; Octet remplissage 2 pour EraseSlot
TEMP_A      = $FA
TEMP_X      = $FB
TEMP_Y      = $FC
NUM_LO      = $FD       ; Variable 16-bit pour conversion decimale
NUM_HI      = $FE

; =============================================================================
; IDENTIFIANTS DES CARTES (0..19 + 20=Vide)
; =============================================================================
CARD_NONE       = 0     ; Borne vide / Titre
CARD_PANNE      = 1     ; Attaque : Panne d'essence
CARD_ACCIDENT   = 2     ; Attaque : Accident
CARD_CREVAISON  = 3     ; Attaque : Crevaison
CARD_LIMITATION = 4     ; Attaque : Limitation 50 km/h
CARD_FEUROUGE   = 5     ; Attaque : Feu Rouge
CARD_ESSENCE    = 6     ; Parade  : Essence
CARD_REPARATION = 7     ; Parade  : Reparations
CARD_ROUESECOUR = 8     ; Parade  : Roue de secours
CARD_FINLIMITE  = 9     ; Parade  : Fin de limitation
CARD_FEUVERT    = 10    ; Parade  : Feu Vert
CARD_200KM      = 11    ; Etape 200 km
CARD_100KM      = 12    ; Etape 100 km
CARD_75KM       = 13    ; Etape 75 km
CARD_50KM       = 14    ; Etape 50 km
CARD_25KM       = 15    ; Etape 25 km
CARD_CITERNE    = 16    ; Botte : Citerne d'essence (prioritaire sur Panne)
CARD_ASVOLANT   = 17    ; Botte : As du volant (prioritaire sur Accident)
CARD_INCREVABLE = 18    ; Botte : Increvable (prioritaire sur Crevaison)
CARD_VEHPRIO    = 19    ; Botte : Vehicule prioritaire (prioritaire sur Feu Rouge & Limite)
CARD_EMPTY_SLOT = 20    ; Cadre d'emplacement vide

; =============================================================================
; VARIABLES DU JEU (EN RAM $0300-$03FF)
; =============================================================================
DEC_BUF         = $0300 ; Tampon conversion decimale (6 octets)
PLAYER_NAME     = $0310 ; Nom du joueur (8 octets, termine par 0)
THOMSON_NAME    = $0320 ; "THOMSON"

; =============================================================================
; POINT D'ENTREE DU PROGRAMME
; =============================================================================
MainInit:
    ; Acquitte toute frappe residuelle au boot
    bit KBDSTRB

    ; Initialisation du generateur aleatoire
    lda #$4A
    sta RND_SEED
    lda #$9B
    sta RND_SEED+1

    ; Initialisation du mode graphique HGR plein ecran
    jsr InitHGR

    ; Nom par defaut du joueur
    ldx #0
_def_name_loop:
    lda DefName,x
    sta PLAYER_NAME,x
    inx
    cpx #8
    bne _def_name_loop

    ; Nom de Thomson
    ldx #0
_t_name_loop:
    lda StrThomson,x
    sta THOMSON_NAME,x
    inx
    cpx #8
    bne _t_name_loop

    ; Remise a zero des scores globaux du match
    lda #0
    sta MATCH_P_LO
    sta MATCH_P_HI
    sta MATCH_T_LO
    sta MATCH_T_HI
    sta ROUND_NUM

    ; 1. Ecran Titre & Animation MO5
    jsr TitleScreen

    ; 2. Saisie du nom du joueur
    jsr PromptPlayerName

GameLoop:
    ; Demarrage d'une nouvelle manche
    jsr PlayRound

    ; Verification score total >= 5000
    lda MATCH_P_HI
    cmp #>5000
    bcc _check_t_win
    bne MatchEnd
    lda MATCH_P_LO
    cmp #<5000
    bcs MatchEnd

_check_t_win:
    lda MATCH_T_HI
    cmp #>5000
    bcc GameLoop
    bne MatchEnd
    lda MATCH_T_LO
    cmp #<5000
    bcs MatchEnd
    jmp GameLoop

MatchEnd:
    jsr EndOfMatchScreen
    ; Une autre partie ?
    jsr WaitKey
    cmp #'O'
    beq _do_restart
    cmp #'o'
    beq _do_restart
    ; Quitter : retour mode texte propre
    sta TXTSET
    rts

_do_restart:
    jmp MainInit

DefName:
    .text "JOUEUR", 0, 0
StrThomson:
    .text "THOMSON", 0

; =============================================================================
; GESTION DU MODE HGR APPLE II
; =============================================================================
InitHGR:
    bit TXTCLR          ; Mode graphique
    bit MIXCLR          ; Plein ecran 192 lignes (sans split 4 lignes texte)
    bit TXTPAGE1        ; Page 1 ($2000-$3FFF)
    bit HIRES           ; Haute Resolution
    jsr ClearHGR        ; Efface l'ecran
    rts

ClearHGR:
    lda #$00
    ldx #$20            ; De $2000 a $3FFF (32 pages de 256 octets)
    stx PTR_HI
    ldy #$00
    sty PTR_LO
_clr_loop:
    sta (PTR_LO),y
    iny
    bne _clr_loop
    inc PTR_HI
    ldx PTR_HI
    cpx #$40
    bne _clr_loop
    rts

; =============================================================================
; DESSIN D'UNE CARTE HGR
; Entrees :
;   CARD_COL  : colonne octet (0..36)
;   CARD_SCAN : scanline Y de depart (0..152)
;   CARD_ID   : type de carte (0..20)
; =============================================================================
DrawCardAt:
    ldx CARD_ID
    lda CARD_PTR_LO,x
    sta PTR_LO
    lda CARD_PTR_HI,x
    sta PTR_HI

    lda #0
    sta CARD_Y
_card_scan_loop:
    lda CARD_Y
    clc
    adc CARD_SCAN       ; Y effectif a l'ecran
    tax                 ; Index de scanline (0..191)

    ; Adresse ecran HGR de la ligne
    lda HGR_ROW_LO,x
    clc
    adc CARD_COL
    sta PTR2_LO
    lda HGR_ROW_HI,x
    adc #0
    sta PTR2_HI

    ; Copie de 5 octets de la carte (avec gestion de phase colonne impaire)
    lda CARD_COL
    lsr
    bcs _card_odd_phase_check

_card_copy_standard:
    ldy #0
    lda (PTR_LO),y
    sta (PTR2_LO),y
    iny
    lda (PTR_LO),y
    sta (PTR2_LO),y
    iny
    lda (PTR_LO),y
    sta (PTR2_LO),y
    iny
    lda (PTR_LO),y
    sta (PTR2_LO),y
    iny
    lda (PTR_LO),y
    sta (PTR2_LO),y
    jmp _card_advance_scan

_card_odd_phase_check:
    lda CARD_ID
    cmp #CARD_FEUROUGE
    beq _cop_chk_rouge
    cmp #CARD_FEUVERT
    beq _cop_chk_vert
    ; Borne ? (CARD_NONE=0, ou 11..15)
    cmp #CARD_NONE
    beq _cop_chk_dome
    cmp #CARD_200KM
    bcc _card_copy_standard
    cmp #CARD_25KM+1
    bcs _card_copy_standard
_cop_chk_dome:
    lda CARD_Y
    cmp #8
    bcc _card_copy_standard
    cmp #16
    bcs _card_copy_standard
    sec
    sbc #8
    tax
    lda Mul5_8_Table,x
    tax
    ldy #0
-   lda DomeOddTable,x
    sta (PTR2_LO),y
    inx
    iny
    cpy #5
    bne -
    jmp _card_advance_scan

_cop_chk_rouge:
    lda CARD_Y
    cmp #9
    bcc _card_copy_standard
    cmp #15
    bcs _card_copy_standard
    sec
    sbc #9
    tax
    lda Mul5_6_Table,x
    tax
    ldy #0
-   lda FeuRougeOddTable,x
    sta (PTR2_LO),y
    inx
    iny
    cpy #5
    bne -
    jmp _card_advance_scan

_cop_chk_vert:
    lda CARD_Y
    cmp #25
    bcc _cop_vert_skip
    cmp #31
    bcc _cop_vert_in_range
_cop_vert_skip:
    jmp _card_copy_standard
_cop_vert_in_range:
    sec
    sbc #25
    tax
    lda Mul5_6_Table,x
    tax
    ldy #0
-   lda FeuVertOddTable,x
    sta (PTR2_LO),y
    inx
    iny
    cpy #5
    bne -

_card_advance_scan:
    ; Avance pointeur source de 5 octets
    lda PTR_LO
    clc
    adc #5
    sta PTR_LO
    bcc _no_src_hi_inc
    inc PTR_HI
_no_src_hi_inc:
    inc CARD_Y
    lda CARD_Y
    cmp #40
    beq +
    jmp _card_scan_loop
+   rts

Mul5_8_Table:   .byte 0, 5, 10, 15, 20, 25, 30, 35
Mul5_6_Table:   .byte 0, 5, 10, 15, 20, 25

DomeOddTable:
    .byte $7E, $AF, $D5, $FE, $1F
    .byte $7E, $AB, $D5, $FA, $1F
    .byte $7E, $AB, $D5, $EA, $1F
    .byte $7E, $AA, $D5, $EA, $1F
    .byte $FE, $AA, $D5, $AA, $1F
    .byte $FE, $AA, $D5, $AA, $1F
    .byte $DE, $AA, $D5, $AA, $9F
    .byte $DE, $AA, $D5, $AA, $9F

FeuRougeOddTable:
    .byte $76, $06, $0B, $7E, $1F
    .byte $7E, $A7, $D5, $FF, $1F
    .byte $7E, $A7, $FD, $FF, $1F
    .byte $7E, $A7, $FD, $FF, $1F
    .byte $7E, $A7, $F5, $FF, $1F
    .byte $7E, $07, $67, $7F, $1F

FeuVertOddTable:
    .byte $7E, $07, $0B, $7E, $1F
    .byte $7E, $27, $55, $7F, $1F
    .byte $7E, $27, $7D, $7F, $1F
    .byte $7E, $27, $7D, $7F, $1F
    .byte $7E, $27, $75, $7F, $1F
    .byte $7E, $07, $67, $7F, $1F

; =============================================================================
; DESSIN D'UNE CARTE PAR EMPLACEMENT (SLOT 1..20)
; =============================================================================
DrawCardInSlot:
    ldx SLOT_NUM
    lda SlotCols,x
    sta CARD_COL
    lda SlotRows,x
    sta CARD_SCAN
    jsr DrawCardAt
    rts

EraseSlot:
    ldx SLOT_NUM
    lda SlotCols,x
    sta CARD_COL
    lda SlotRows,x
    sta CARD_SCAN

    ; Determine couleur de fond du slot
    ; 1..7 = main (vert)
    ; 8..11 = bottes joueur (magenta)
    ; 12..15 = bottes thomson (orange)
    ; 16..17 = piles joueur (magenta)
    ; 18 = defausse (vert)
    ; 19..20 = piles thomson (orange)
    cpx #8
    bcc _slot_felt
    cpx #12
    bcc _slot_magenta
    cpx #16
    bcc _slot_orange
    cpx #18
    bcc _slot_magenta
    beq _slot_felt
_slot_orange:
    ; Orange uni : pair = $AA, impair = $D5
    lda #$AA
    sta ERASE_B1
    lda #$D5
    sta ERASE_B2
    jmp _slot_prep_bytes
_slot_magenta:
    ; Magenta uni : pair = $55, impair = $2A
    lda #$55
    sta ERASE_B1
    lda #$2A
    sta ERASE_B2
    jmp _slot_prep_bytes
_slot_felt:
    ; Vert uni : pair = $2A, impair = $55
    lda #$2A
    sta ERASE_B1
    lda #$55
    sta ERASE_B2

_slot_prep_bytes:
    ; Si CARD_COL est impair, inverse ERASE_B1 et ERASE_B2
    lda CARD_COL
    lsr
    bcc _slot_col_even
    ldy ERASE_B1
    lda ERASE_B2
    sta ERASE_B1
    sty ERASE_B2
_slot_col_even:
    lda #0
    sta CARD_Y
_slot_fill_loop:
    lda CARD_Y
    clc
    adc CARD_SCAN
    tax
    lda HGR_ROW_LO,x
    clc
    adc CARD_COL
    sta PTR2_LO
    lda HGR_ROW_HI,x
    adc #0
    sta PTR2_HI

    ldy #0
    lda ERASE_B1
    sta (PTR2_LO),y
    iny
    lda ERASE_B2
    sta (PTR2_LO),y
    iny
    lda ERASE_B1
    sta (PTR2_LO),y
    iny
    lda ERASE_B2
    sta (PTR2_LO),y
    iny
    lda ERASE_B1
    sta (PTR2_LO),y

    inc CARD_Y
    lda CARD_Y
    cmp #40
    bne _slot_fill_loop
    rts

; Coordonnees colonnes (en octets 0..39) des 20 emplacements
SlotCols:
    .byte 0
    ; Main du joueur (slots 1..7)
    .byte 2, 7, 12, 17, 22, 27, 32
    ; Bottes du joueur (slots 8..11)
    .byte 0, 5, 10, 15
    ; Bottes de Thomson (slots 12..15)
    .byte 20, 25, 30, 35
    ; Piles joueur (16=Limite, 17=Bataille)
    .byte 1, 6
    ; Defausse centrale (18)
    .byte 17
    ; Piles Thomson (19=Bataille, 20=Limite)
    .byte 28, 34

; Coordonnees lignes (scanlines 0..191) des 20 emplacements
SlotRows:
    .byte 0
    ; Main du joueur (scanline 16)
    .byte 16, 16, 16, 16, 16, 16, 16
    ; Bottes du joueur (scanline 72)
    .byte 72, 72, 72, 72
    ; Bottes de Thomson (scanline 72)
    .byte 72, 72, 72, 72
    ; Piles joueur (scanline 148)
    .byte 148, 148
    ; Defausse centrale (scanline 122)
    .byte 122
    ; Piles Thomson (scanline 148)
    .byte 148, 148

; =============================================================================
; MOTEUR DE RENDU DE TEXTE HGR (POLICE 7x8)
; =============================================================================
; HGR_PrintChar : Affiche caractere dans A a la position (HGR_COL, HGR_ROW)
; =============================================================================
HGR_PrintChar:
    pha
    lda HGR_COL
    cmp #40
    bcc _hpc_col_ok
    pla
    rts
_hpc_col_ok:
    pla
    pha
    and #$7F            ; 0..127
    sta TEMP_A
    txa
    pha
    tya
    pha
    lda #0
    sta PTR_HI
    lda TEMP_A
    asl
    rol PTR_HI
    asl
    rol PTR_HI
    asl
    rol PTR_HI
    clc
    adc #<FONT_7X8
    sta PTR_LO
    lda PTR_HI
    adc #>FONT_7X8
    sta PTR_HI

    ; Scanline de depart = HGR_ROW * 8
    lda HGR_ROW
    asl
    asl
    asl
    tax                 ; Scanline de base dans X

    ; Boucle sur 8 scanlines du caractere
    lda #0
    sta CHAR_Y
_char_scan_loop:
    lda HGR_ROW_LO,x
    clc
    adc HGR_COL
    sta PTR2_LO
    lda HGR_ROW_HI,x
    adc #0
    sta PTR2_HI

    lda INV_FLAG
    bne _print_bg_mode
    ; Mode 0 : Blanc sur fond noir standard
    ldy CHAR_Y
    lda (PTR_LO),y
    ldy #0
    sta (PTR2_LO),y
    jmp _print_char_next
_print_bg_mode:
    cmp #$7F
    beq _hpc_cartouche_mode

    ; Modes couleur ($2A, $55, $AA) : Texte blanc éclatant avec halo d'ombre noire
    cmp #$2A
    beq _hpc_bg_green
    cmp #$55
    beq _hpc_bg_magenta
    ; Orange ($AA) : pair = $AA, impair = $D5
    lda HGR_COL
    lsr
    lda #$AA
    bcc _hpc_got_bg
    lda #$D5
    jmp _hpc_got_bg
_hpc_bg_magenta:
    ; Magenta ($55) : pair = $55, impair = $2A
    lda HGR_COL
    lsr
    lda #$55
    bcc _hpc_got_bg
    lda #$2A
    jmp _hpc_got_bg
_hpc_bg_green:
    ; Vert ($2A) : pair = $2A, impair = $55
    lda HGR_COL
    lsr
    lda #$2A
    bcc _hpc_got_bg
    lda #$55

_hpc_got_bg:
    sta TEMP_X          ; Fond dans TEMP_X
    ldy CHAR_Y
    lda (PTR_LO),y      ; Glyphe (bits 0..6)
    sta TEMP_Y

    ; 1. Masque halo noir autour de la lettre : g | (g >> 1) | (g << 1)
    lsr
    ora TEMP_Y
    sta TEMP_A
    lda TEMP_Y
    asl
    and #$7F
    ora TEMP_A
    eor #$7F
    ora #$80
    and TEMP_X
    sta TEMP_X

    ; 2. Texte blanc : paires de bits blancs (g | (g >> 1))
    lda TEMP_Y
    lsr
    ora TEMP_Y
    and #$7F
    ora TEMP_X

    ; 3. Palette bit 7
    ldy INV_FLAG
    cpy #$AA
    bne _hpc_not_orange
    ora #$80
    bne _hpc_write_byte
_hpc_not_orange:
    and #$7F
_hpc_write_byte:
    ldy #0
    sta (PTR2_LO),y
    jmp _print_char_next

_hpc_cartouche_mode:
    ; Cartouche blanc pur avec texte noir
    ldy CHAR_Y
    lda (PTR_LO),y
    eor #$7F
    ora #$80
    ldy #0
    sta (PTR2_LO),y
    jmp _print_char_next
_print_char_next:
    inx
    inc CHAR_Y
    lda CHAR_Y
    cmp #8
    beq _char_scan_done
    jmp _char_scan_loop
_char_scan_done:

    pla
    tay
    pla
    tax
    pla
    inc HGR_COL         ; Avance curseur
    rts

; =============================================================================
; HGR_PrintString : Affiche chaine pointee par STR_LO/STR_HI
; =============================================================================
HGR_PrintString:
    lda #0
    sta STR_IDX
_str_loop:
    ldy STR_IDX
    lda (STR_LO),y
    beq _str_done
    inc STR_IDX
    jsr HGR_PrintChar
    jmp _str_loop
_str_done:
    rts

; =============================================================================
; HGR_PrintDec : Affiche entier 16-bit NUM_LO/NUM_HI
; =============================================================================
HGR_PrintDec:
    jsr Bin2Dec         ; Convertit NUM_LO/NUM_HI dans DEC_BUF
    ldy #0
_skip_zeros:
    lda DEC_BUF,y
    cmp #'0'
    bne _start_print_digits
    cpy #4              ; Dernier chiffre ?
    beq _start_print_digits
    iny
    bne _skip_zeros

_start_print_digits:
    sty DEC_IDX
_dec_print_loop:
    ldy DEC_IDX
    cpy #5
    beq _print_dec_done
    lda DEC_BUF,y
    beq _print_dec_done
    inc DEC_IDX
    jsr HGR_PrintChar
    jmp _dec_print_loop
_print_dec_done:
    rts

; Conversion 16 bits en 5 chiffres decimaux ASCII
Bin2Dec:
    lda NUM_LO
    sta $02
    lda NUM_HI
    sta $03
    ldx #0
_div_outer:
    lda #0
    sta $04             ; Reste
    ldy #16
_div_inner:
    asl $02
    rol $03
    rol $04
    lda $04
    sec
    sbc #10
    bcc _div_no_sub
    sta $04
    inc $02
_div_no_sub:
    dey
    bne _div_inner
    lda $04
    clc
    adc #'0'
    pha
    inx
    cpx #5
    bne _div_outer

    ldy #0
_pop_digits:
    pla
    sta DEC_BUF,y
    iny
    cpy #5
    bne _pop_digits
    lda #0
    sta DEC_BUF,y
    rts

; =============================================================================
; ECRAN DE TITRE & ANIMATION ORIGINALE MO5
; =============================================================================
TitleScreen:
    jsr ClearHGR

    ; 1. Logo "1000" (gauche) et "BORNES" (droite)
    lda #3
    sta HGR_COL
    lda #2
    sta HGR_ROW
    lda #<StrTitle1000
    sta STR_LO
    lda #>StrTitle1000
    sta STR_HI
    jsr HGR_PrintString

    lda #23
    sta HGR_COL
    lda #2
    sta HGR_ROW
    lda #<StrTitleBornes
    sta STR_LO
    lda #>StrTitleBornes
    sta STR_HI
    jsr HGR_PrintString

    ; 2. Dessin de la borne logo au centre (Carte 0)
    lda #17
    sta CARD_COL
    lda #16
    sta CARD_SCAN
    lda #CARD_NONE
    sta CARD_ID
    jsr DrawCardAt

    ; 3. Credits originaux MO5 1985
    ; Cote gauche
    lda #1
    sta HGR_COL
    lda #5
    sta HGR_ROW
    lda #<StrCred1
    sta STR_LO
    lda #>StrCred1
    sta STR_HI
    jsr HGR_PrintString

    lda #2
    sta HGR_COL
    lda #7
    sta HGR_ROW
    lda #<StrCred2
    sta STR_LO
    lda #>StrCred2
    sta STR_HI
    jsr HGR_PrintString

    lda #2
    sta HGR_COL
    lda #10
    sta HGR_ROW
    lda #<StrPress1
    sta STR_LO
    lda #>StrPress1
    sta STR_HI
    jsr HGR_PrintString

    lda #2
    sta HGR_COL
    lda #11
    sta HGR_ROW
    lda #<StrPress2
    sta STR_LO
    lda #>StrPress2
    sta STR_HI
    jsr HGR_PrintString

    lda #2
    sta HGR_COL
    lda #12
    sta HGR_ROW
    lda #<StrPress3
    sta STR_LO
    lda #>StrPress3
    sta STR_HI
    jsr HGR_PrintString

    ; Cote droit
    lda #24
    sta HGR_COL
    lda #5
    sta HGR_ROW
    lda #<StrCred3
    sta STR_LO
    lda #>StrCred3
    sta STR_HI
    jsr HGR_PrintString

    lda #22
    sta HGR_COL
    lda #7
    sta HGR_ROW
    lda #<StrCred4
    sta STR_LO
    lda #>StrCred4
    sta STR_HI
    jsr HGR_PrintString

    lda #26
    sta HGR_COL
    lda #10
    sta HGR_ROW
    lda #<StrCred5
    sta STR_LO
    lda #>StrCred5
    sta STR_HI
    jsr HGR_PrintString

    lda #24
    sta HGR_COL
    lda #11
    sta HGR_ROW
    lda #<StrCred6
    sta STR_LO
    lda #>StrCred6
    sta STR_HI
    jsr HGR_PrintString

    ; Acquitte clavier avant l'animation
    bit KBDSTRB

    ; 4. Animation cyclique des cartes qui tombent (Lignes 257-263 du MO5)
AnimLoop:
    ldx #0
_next_demo_card:
    stx DEMO_IDX
    lda DemoCardList,x
    bne _do_demo_drop
    jmp AnimLoop

_do_demo_drop:
    sta DEMO_CARD

    ; Animation de chute : scanline 16 a 56 par pas de 4
    lda #16
    sta DEMO_Y
_drop_step_loop:
    ; 1. Efface la zone précédente au-dessus de la carte (4 scanlines de noir)
    lda DEMO_Y
    cmp #16
    beq _no_top_erase
    sec
    sbc #4
    tax                 ; Scanline Y a effacer
    ldy #0
_erase_step_top_loop:
    lda HGR_ROW_LO,x
    clc
    adc #17
    sta PTR2_LO
    lda HGR_ROW_HI,x
    adc #0
    sta PTR2_HI
    lda #0
    sta (PTR2_LO),y
    iny
    sta (PTR2_LO),y
    iny
    sta (PTR2_LO),y
    iny
    sta (PTR2_LO),y
    iny
    sta (PTR2_LO),y
    ldy #0
    inx
    txa
    cmp DEMO_Y
    bne _erase_step_top_loop
_no_top_erase:

    ; 2. Dessine la carte a DEMO_Y
    lda #17
    sta CARD_COL
    lda DEMO_Y
    sta CARD_SCAN
    lda DEMO_CARD
    sta CARD_ID
    jsr DrawCardAt

    ; Bip sonore
    jsr BeepSound

    ; Temporisation fluide (~35ms par pas)
    lda #25
    jsr DelayRoutine

    ; Verification touche pressee
    lda KBD
    bmi _exit_demo_title

    lda DEMO_Y
    clc
    adc #4
    sta DEMO_Y
    cmp #56
    bcc _drop_step_loop
    beq _drop_step_loop

    ; Carte arrivee a Y=56 : affichage du nom centre au dessous
    jsr EraseDemoTextLine
    ldx DEMO_CARD
    lda CardNamesLo,x
    sta STR_LO
    lda CardNamesHi,x
    sta STR_HI
    lda CardNamesCol,x  ; Colonne centree
    sta HGR_COL
    lda #14
    sta HGR_ROW
    jsr HGR_PrintString

    ; Pause pour admirer la carte (~1.5 seconde)
    ldy #50
_demo_pause:
    lda #25
    jsr DelayRoutine
    lda KBD
    bmi _exit_demo_title
    dey
    bne _demo_pause

    ; Efface completement la carte a Y=56 (40 lignes de cols 17..21 a zero)
    lda #56
    sta CARD_SCAN
    lda #17
    sta CARD_COL
    lda #0
    sta CARD_Y
_erase_full_demo_card:
    lda CARD_Y
    clc
    adc CARD_SCAN
    tax
    lda HGR_ROW_LO,x
    clc
    adc CARD_COL
    sta PTR2_LO
    lda HGR_ROW_HI,x
    adc #0
    sta PTR2_HI
    ldy #0
    lda #0
    sta (PTR2_LO),y
    iny
    sta (PTR2_LO),y
    iny
    sta (PTR2_LO),y
    iny
    sta (PTR2_LO),y
    iny
    sta (PTR2_LO),y
    inc CARD_Y
    lda CARD_Y
    cmp #40
    bne _erase_full_demo_card

    jsr EraseDemoTextLine

    ldx DEMO_IDX
    inx
    jmp _next_demo_card

_exit_demo_title:
    bit KBDSTRB         ; Acquitte la touche
    rts

DEMO_IDX:   .byte 0
DEMO_CARD:  .byte 0
DEMO_Y:     .byte 0

EraseDemoTextLine:
    lda #2
    sta HGR_COL
    lda #14
    sta HGR_ROW
    lda #<StrBlankLine
    sta STR_LO
    lda #>StrBlankLine
    sta STR_HI
    jsr HGR_PrintString
    rts

DemoCardList:
    .byte CARD_25KM, CARD_50KM, CARD_75KM, CARD_100KM, CARD_200KM
    .byte CARD_FEUROUGE, CARD_FEUVERT, CARD_PANNE, CARD_ESSENCE
    .byte CARD_ACCIDENT, CARD_REPARATION, CARD_CREVAISON, CARD_ROUESECOUR
    .byte CARD_LIMITATION, CARD_FINLIMITE
    .byte CARD_CITERNE, CARD_ASVOLANT, CARD_INCREVABLE, CARD_VEHPRIO
    .byte 0

StrTitle1000:       .text "* 1 0 0 0 *", 0
StrTitleBornes:     .text "= B O R N E S =", 0
StrCred1:           .text "Copyright 1985", 0
StrCred2:           .text "LES EDITIONS", 0
StrPress1:          .text "(appuyez sur", 0
StrPress2:          .text " une touche", 0
StrPress3:          .text "pour jouer)", 0
StrCred3:           .text "DUJARDIN INT.", 0
StrCred4:           .text "FREE GAME BLOT &", 0
StrCred5:           .text "Auteur :", 0
StrCred6:           .text "J.Y. BOUCROT", 0
StrBlankLine:       .text "                                    ", 0

; =============================================================================
; SAISIE DU NOM DU JOUEUR EN HGR
; =============================================================================
PromptPlayerName:
    jsr ClearHGR
    bit KBDSTRB

    lda #10
    sta HGR_COL
    lda #10
    sta HGR_ROW
    lda #<StrAskName
    sta STR_LO
    lda #>StrAskName
    sta STR_HI
    jsr HGR_PrintString

    ldx #0
_name_input_loop:
    lda KBD
    bpl _name_input_loop
    bit KBDSTRB
    and #$7F

    cmp #$0D            ; Entree ?
    beq _name_done
    cmp #$08            ; Backspace ?
    beq _name_backspace
    cmp #$7F
    beq _name_backspace

    cmp #' '
    bcc _name_input_loop
    cpx #7
    bcs _name_input_loop
    sta PLAYER_NAME,x
    inx
    lda #0
    sta PLAYER_NAME,x
    jsr DisplayNameBuffer
    jmp _name_input_loop

_name_backspace:
    cpx #0
    beq _name_input_loop
    dex
    lda #0
    sta PLAYER_NAME,x
    jsr DisplayNameBuffer
    jmp _name_input_loop

_name_done:
    lda PLAYER_NAME
    bne _name_ok
    ldx #0
_restore_def:
    lda DefName,x
    sta PLAYER_NAME,x
    inx
    cpx #8
    bne _restore_def
_name_ok:
    rts

DisplayNameBuffer:
    lda #23
    sta HGR_COL
    lda #10
    sta HGR_ROW
    lda #<StrBlankName
    sta STR_LO
    lda #>StrBlankName
    sta STR_HI
    jsr HGR_PrintString

    lda #23
    sta HGR_COL
    lda #10
    sta HGR_ROW
    lda #<PLAYER_NAME
    sta STR_LO
    lda #>PLAYER_NAME
    sta STR_HI
    jsr HGR_PrintString
    rts

StrAskName:     .text "VOTRE NOM : ", 0
StrBlankName:   .text "       ", 0

; =============================================================================
; REMPLISSAGE DU FOND DE JEU HGR SELON LE LAYOUT MO5 (BOUCROT 1985)
; =============================================================================
FillBoardBackground:
    ldx #0
_fbb_scan_loop:
    stx TEMP_X
    lda HGR_ROW_LO,x
    sta PTR2_LO
    lda HGR_ROW_HI,x
    sta PTR2_HI

    cpx #8
    bcs _fbb_not_menu
    ; Ligne 0 (scanlines 0..7) : Menu blanc pur ($7F)
    lda #$7F
    ldy #39
_fbb_m_loop:
    sta (PTR2_LO),y
    dey
    bpl _fbb_m_loop
    jmp _fbb_next_scan

_fbb_not_menu:
    cpx #64
    bcs _fbb_panels
    ; Lignes 1..7 (scanlines 8..63) : Tapis vert uni ($2A / $55)
    ldy #0
_fbb_g_loop:
    lda #$2A
    sta (PTR2_LO),y
    iny
    lda #$55
    sta (PTR2_LO),y
    iny
    cpy #40
    bne _fbb_g_loop
    jmp _fbb_next_scan

_fbb_panels:
    cpx #120
    bcs _fbb_lower_panels
    ; Lignes 8..14 (scanlines 64..119) :
    ; Cols 0..19 Magenta uni ($55 / $2A)
    ; Cols 20..39 Orange uni ($AA / $D5)
    ldy #0
_fbb_mag1:
    lda #$55
    sta (PTR2_LO),y
    iny
    lda #$2A
    sta (PTR2_LO),y
    iny
    cpy #20
    bne _fbb_mag1
_fbb_ora1:
    lda #$AA
    sta (PTR2_LO),y
    iny
    lda #$D5
    sta (PTR2_LO),y
    iny
    cpy #40
    bne _fbb_ora1
    jmp _fbb_next_scan

_fbb_lower_panels:
    ; Lignes 15..23 (scanlines 120..191) :
    ; Cols 0..15 : Joueur Magenta ($55 / $2A)
    ; Cols 16..23 : Defausse Vert ($2A / $55)
    ; Cols 24..39 : Thomson Orange ($AA / $D5)
    ldy #0
_fbb_mag2:
    lda #$55
    sta (PTR2_LO),y
    iny
    lda #$2A
    sta (PTR2_LO),y
    iny
    cpy #16
    bne _fbb_mag2
_fbb_felt2:
    lda #$2A
    sta (PTR2_LO),y
    iny
    lda #$55
    sta (PTR2_LO),y
    iny
    cpy #24
    bne _fbb_felt2
_fbb_ora2:
    lda #$AA
    sta (PTR2_LO),y
    iny
    lda #$D5
    sta (PTR2_LO),y
    iny
    cpy #40
    bne _fbb_ora2

_fbb_next_scan:
    ldx TEMP_X
    inx
    cpx #192
    beq _fbb_done
    jmp _fbb_scan_loop
_fbb_done:
    rts

; =============================================================================
; DESSIN DU PLATEAU DE JEU COMPLET EN HGR
; =============================================================================
DrawBoardHGR:
    jsr FillBoardBackground

    ; 1. Ligne 0 : Barre de menu superieure
    lda #0
    sta MENU_SEL
    jsr DrawMenuDraw

    ; 2. Noms et libelles du jeu
    ; Joueur (Panneau Magenta) : Cartouche blanc de 8 caracteres
    lda #$7F
    sta INV_FLAG
    lda #1
    sta HGR_COL
    lda #14
    sta HGR_ROW
    lda #<StrBlank8
    sta STR_LO
    lda #>StrBlank8
    sta STR_HI
    jsr HGR_PrintString

    lda #1
    sta HGR_COL
    lda #14
    sta HGR_ROW
    lda #<PLAYER_NAME
    sta STR_LO
    lda #>PLAYER_NAME
    sta STR_HI
    jsr HGR_PrintString

    ; Thomson (Panneau Orange) : Cartouche blanc de 8 caracteres
    lda #$7F
    sta INV_FLAG
    lda #25
    sta HGR_COL
    lda #14
    sta HGR_ROW
    lda #<StrThomsonPlate
    sta STR_LO
    lda #>StrThomsonPlate
    sta STR_HI
    jsr HGR_PrintString

    ; Les scores sont affiches dynamiquement sous la forme [XXX] KMS par UpdateScoresAndDrawCount

    ; Defausse et Pioche (Centre vert)
    lda #$2A
    sta INV_FLAG
    lda #16
    sta HGR_COL
    lda #15
    sta HGR_ROW
    lda #<StrDefausse
    sta STR_LO
    lda #>StrDefausse
    sta STR_HI
    jsr HGR_PrintString

    lda #16
    sta HGR_COL
    lda #21
    sta HGR_ROW
    lda #<StrResteLabel
    sta STR_LO
    lda #>StrResteLabel
    sta STR_HI
    jsr HGR_PrintString

    lda #17
    sta HGR_COL
    lda #22
    sta HGR_ROW
    lda #<StrCartesLabel
    sta STR_LO
    lda #>StrCartesLabel
    sta STR_HI
    jsr HGR_PrintString

    lda #0
    sta INV_FLAG

    ; 3. Compteurs de kilometres et talon
    jsr UpdateScoresAndDrawCount
    rts

UpdateScoresAndDrawCount:
    ; Joueur KMS (fond magenta $55)
    lda #$55
    sta INV_FLAG
    lda P_KMS
    sta NUM_LO
    lda P_KMS+1
    sta NUM_HI
    jsr DrawScoreKMS

    ; Thomson KMS (fond orange $AA)
    lda #$AA
    sta INV_FLAG
    lda T_KMS
    sta NUM_LO
    lda T_KMS+1
    sta NUM_HI
    jsr DrawScoreKMS

    ; Reste de cartes au talon (Col 21, 2 chiffres, y=168, fond vert $2A)
    jsr DrawTalonDigits

    lda #0
    sta INV_FLAG
    rts

; =============================================================================
; DrawScoreKMS : Affiche dynamiquement "[Score] KMS" centre sur le panneau
; Entrees :
;   NUM_LO/NUM_HI : Valeur en kms (0..1000)
;   INV_FLAG      : $55 (Joueur, cols 0..15) ou $AA (Thomson, cols 24..39)
; Efface prealablement la zone de score puis trace les 5..8 grands caracteres
; =============================================================================
DrawScoreKMS:
    jsr Bin2Dec         ; DEC_BUF contient 5 chiffres ASCII

    ; 1. Effacement complet de la bande de score (scanlines 122..135)
    lda INV_FLAG
    cmp #$55
    bne _dsk_wipe_thomson

    ; Joueur : efface colonnes 2..13 (12 colonnes, y=122..135)
    ldx #122
_dsk_wipe_p_y:
    lda HGR_ROW_LO,x
    sta PTR2_LO
    lda HGR_ROW_HI,x
    sta PTR2_HI
    ldy #2
_dsk_wipe_p_x:
    lda #$55            ; Col 2 pair = $55
    sta (PTR2_LO),y
    iny
    lda #$2A            ; Col 3 impair = $2A
    sta (PTR2_LO),y
    iny
    cpy #14
    bne _dsk_wipe_p_x
    inx
    cpx #136
    bne _dsk_wipe_p_y
    jmp _dsk_build_str

_dsk_wipe_thomson:
    ; Thomson : efface colonnes 26..37 (12 colonnes, y=122..135)
    ldx #122
_dsk_wipe_t_y:
    lda HGR_ROW_LO,x
    sta PTR2_LO
    lda HGR_ROW_HI,x
    sta PTR2_HI
    ldy #26
_dsk_wipe_t_x:
    lda #$AA            ; Col 26 pair = $AA
    sta (PTR2_LO),y
    iny
    lda #$D5            ; Col 27 impair = $D5
    sta (PTR2_LO),y
    iny
    cpy #38
    bne _dsk_wipe_t_x
    inx
    cpx #136
    bne _dsk_wipe_t_y

_dsk_build_str:
    ; 2. Construction de la chaine sans zeros non significatifs
    lda DEC_BUF+1       ; Milliers
    cmp #'0'
    beq _dsk_chk_hun
    sec
    sbc #'0'
    sta ScoreCharIndices+0
    lda DEC_BUF+2
    sec
    sbc #'0'
    sta ScoreCharIndices+1
    lda DEC_BUF+3
    sec
    sbc #'0'
    sta ScoreCharIndices+2
    lda DEC_BUF+4
    sec
    sbc #'0'
    sta ScoreCharIndices+3
    lda #4
    sta ScoreNumDigits
    jmp _dsk_add_suffix

_dsk_chk_hun:
    lda DEC_BUF+2       ; Centaines
    cmp #'0'
    beq _dsk_chk_ten
    sec
    sbc #'0'
    sta ScoreCharIndices+0
    lda DEC_BUF+3
    sec
    sbc #'0'
    sta ScoreCharIndices+1
    lda DEC_BUF+4
    sec
    sbc #'0'
    sta ScoreCharIndices+2
    lda #3
    sta ScoreNumDigits
    jmp _dsk_add_suffix

_dsk_chk_ten:
    lda DEC_BUF+3       ; Dizaines
    cmp #'0'
    beq _dsk_chk_unit
    sec
    sbc #'0'
    sta ScoreCharIndices+0
    lda DEC_BUF+4
    sec
    sbc #'0'
    sta ScoreCharIndices+1
    lda #2
    sta ScoreNumDigits
    jmp _dsk_add_suffix

_dsk_chk_unit:
    lda DEC_BUF+4       ; Unites
    sec
    sbc #'0'
    sta ScoreCharIndices+0
    lda #1
    sta ScoreNumDigits

_dsk_add_suffix:
    ldx ScoreNumDigits
    lda #$FF            ; Espace inter-mots (1 colonne vide)
    sta ScoreCharIndices,x
    inx
    lda #10             ; 'K'
    sta ScoreCharIndices,x
    inx
    lda #11             ; 'M'
    sta ScoreCharIndices,x
    inx
    lda #12             ; 'S'
    sta ScoreCharIndices,x
    inx
    stx ScoreTotalLen   ; 5, 6, 7 ou 8 colonnes

    ; 3. Centrage horizontal dans la zone de 16 colonnes
    ; StartCol = Base + (16 - ScoreTotalLen) / 2
    lda #16
    sec
    sbc ScoreTotalLen
    lsr                 ; / 2
    ldy INV_FLAG
    cpy #$AA
    bne +
    clc
    adc #24             ; Base Thomson = 24
+   sta CARD_COL        ; Colonne de depart

    ; 4. Trace des caracteres
    lda #0
    sta STR_IDX
_dsk_col_loop:
    ldx STR_IDX
    lda ScoreCharIndices,x
    cmp #$FF
    beq _dsk_skip_col   ; Espace : deja vierge grace au wipe
    tax
    lda LargeDigitOffsets,x
    tax
    stx PTR_LO

    lda #0
    sta CHAR_Y
_dsk_scan_loop:
    lda #122
    clc
    adc CHAR_Y
    tax
    lda HGR_ROW_LO,x
    clc
    adc CARD_COL
    sta PTR2_LO
    lda HGR_ROW_HI,x
    adc #0
    sta PTR2_HI

    ldx PTR_LO
    lda LargeDigitsTable,x
    inc PTR_LO
    ldy INV_FLAG
    cpy #$AA
    bne +
    ora #$80
+   ldy #0
    sta (PTR2_LO),y

    inc CHAR_Y
    lda CHAR_Y
    cmp #14
    bne _dsk_scan_loop

_dsk_skip_col:
    inc CARD_COL
    inc STR_IDX
    lda STR_IDX
    cmp ScoreTotalLen
    beq +
    jmp _dsk_col_loop
+   rts

ScoreNumDigits:     .byte 0
ScoreTotalLen:      .byte 0
ScoreCharIndices:   .fill 10, 0

DrawTalonDigits:
    lda DECK_REMAIN
    sta NUM_LO
    lda #0
    sta NUM_HI
    jsr Bin2Dec

    ; Efface Col 21 en vert pour separer proprement 'reste' du chiffre
    lda #21
    sta CARD_COL
    jsr _erase_talon_digit_col

    lda #22
    sta CARD_COL
    lda DEC_BUF+3
    jsr _draw_one_talon_digit

    lda #23
    sta CARD_COL
    lda DEC_BUF+4
    jsr _draw_one_talon_digit
    rts

_erase_talon_digit_col:
    lda #0
    sta CHAR_Y
-   lda #168
    clc
    adc CHAR_Y
    tax
    lda HGR_ROW_LO,x
    clc
    adc CARD_COL
    sta PTR2_LO
    lda HGR_ROW_HI,x
    adc #0
    sta PTR2_HI
    lda CARD_COL
    lsr
    lda #$2A
    bcc +
    lda #$55
+   ldy #0
    sta (PTR2_LO),y
    inc CHAR_Y
    lda CHAR_Y
    cmp #8
    bne -
    rts

_draw_one_talon_digit:
    sec
    sbc #'0'
    asl
    asl
    asl                 ; * 8
    tax
    stx PTR_LO

    lda #0
    sta CHAR_Y
_dtd_scan_loop:
    lda #168
    clc
    adc CHAR_Y
    tax
    lda HGR_ROW_LO,x
    clc
    adc CARD_COL
    sta PTR2_LO
    lda HGR_ROW_HI,x
    adc #0
    sta PTR2_HI

    lda CARD_COL
    lsr
    lda #$2A
    bcc +
    lda #$55
+   sta TEMP_X

    ldx PTR_LO
    lda TalonDigitsTable,x
    sta TEMP_Y
    inc PTR_LO

    lda TEMP_Y
    eor #$7F
    and TEMP_X
    ora TEMP_Y

    ldy #0
    sta (PTR2_LO),y

    inc CHAR_Y
    lda CHAR_Y
    cmp #8
    bne _dtd_scan_loop
    rts

LargeDigitOffsets:
    .byte 0, 14, 28, 42, 56, 70, 84, 98, 112, 126, 140, 154, 168

LargeDigitsTable:
    ; 0 (Offset 0)
    .byte $3E, $3E, $36, $36, $36, $36, $36, $36, $36, $36, $36, $36, $3E, $3E
    ; 1 (Offset 14)
    .byte $0C, $1C, $18, $18, $18, $18, $18, $18, $18, $18, $18, $18, $3E, $3E
    ; 2 (Offset 28)
    .byte $3E, $3E, $30, $30, $30, $30, $3E, $3E, $06, $06, $06, $06, $3E, $3E
    ; 3 (Offset 42)
    .byte $3E, $3E, $30, $30, $30, $30, $3E, $3E, $30, $30, $30, $30, $3E, $3E
    ; 4 (Offset 56)
    .byte $36, $36, $36, $36, $36, $36, $3E, $3E, $30, $30, $30, $30, $30, $30
    ; 5 (Offset 70)
    .byte $3E, $3E, $06, $06, $06, $06, $3E, $3E, $30, $30, $30, $30, $3E, $3E
    ; 6 (Offset 84)
    .byte $3E, $3E, $06, $06, $06, $06, $3E, $3E, $36, $36, $36, $36, $3E, $3E
    ; 7 (Offset 98)
    .byte $3E, $3E, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
    ; 8 (Offset 112)
    .byte $3E, $3E, $36, $36, $36, $36, $3E, $3E, $36, $36, $36, $36, $3E, $3E
    ; 9 (Offset 126)
    .byte $3E, $3E, $36, $36, $36, $36, $3E, $3E, $30, $30, $30, $30, $3E, $3E
    ; 10: 'K' (Offset 140)
    .byte $36, $36, $1E, $1E, $0E, $0E, $0E, $0E, $1E, $1E, $36, $36, $36, $36
    ; 11: 'M' (Offset 154)
    .byte $36, $36, $3E, $3E, $1C, $1C, $0C, $0C, $36, $36, $36, $36, $36, $36
    ; 12: 'S' (Offset 168)
    .byte $3E, $3E, $06, $06, $06, $06, $3E, $3E, $30, $30, $30, $30, $3E, $3E

TalonDigitsTable:
    ; 0
    .byte $3F, $33, $33, $33, $33, $33, $33, $3F
    ; 1
    .byte $0C, $3C, $30, $30, $30, $30, $30, $3F
    ; 2
    .byte $3F, $30, $30, $3F, $03, $03, $03, $3F
    ; 3
    .byte $3F, $30, $30, $3F, $30, $30, $30, $3F
    ; 4
    .byte $33, $33, $33, $3F, $30, $30, $30, $30
    ; 5
    .byte $3F, $03, $03, $3F, $30, $30, $30, $3F
    ; 6
    .byte $3F, $03, $03, $3F, $33, $33, $33, $3F
    ; 7
    .byte $3F, $30, $30, $30, $30, $30, $30, $30
    ; 8
    .byte $3F, $33, $33, $3F, $33, $33, $33, $3F
    ; 9
    .byte $3F, $33, $33, $3F, $30, $30, $30, $3F

; =============================================================================
; GESTION DES MENUS DE LA BARRE SUPERIEURE (LIGNE 0)
; =============================================================================
ClearTopBar:
    ldx #0
_ctb_scan:
    lda HGR_ROW_LO,x
    sta PTR2_LO
    lda HGR_ROW_HI,x
    sta PTR2_HI
    lda #$7F
    ldy #39
_ctb_byte:
    sta (PTR2_LO),y
    dey
    bpl _ctb_byte
    inx
    cpx #8
    bne _ctb_scan
    rts

PrintTopBarText:
    sta HGR_COL
    lda #0
    sta HGR_ROW
    lda #$7F
    sta INV_FLAG        ; Noir sur blanc pur
    jsr HGR_PrintString
    lda #0
    sta INV_FLAG        ; Restaure standard
    rts

DrawMenuDraw:
    jsr ClearTopBar
    lda MENU_SEL
    bne _dmd_not_0
    lda #<StrMenuDraw0
    sta STR_LO
    lda #>StrMenuDraw0
    sta STR_HI
    lda #0
    jsr PrintTopBarText
    rts
_dmd_not_0:
    cmp #1
    bne _dmd_2
    lda #<StrMenuDraw1
    sta STR_LO
    lda #>StrMenuDraw1
    sta STR_HI
    lda #0
    jsr PrintTopBarText
    rts
_dmd_2:
    lda #<StrMenuDraw2
    sta STR_LO
    lda #>StrMenuDraw2
    sta STR_HI
    lda #0
    jsr PrintTopBarText
    rts

DrawMenuAction:
    jsr ClearTopBar
    lda MENU_SEL
    bne _dma_not_0
    lda #<StrMenuAct0
    sta STR_LO
    lda #>StrMenuAct0
    sta STR_HI
    lda #0
    jsr PrintTopBarText
    rts
_dma_not_0:
    cmp #1
    bne _dma_not_1
    lda #<StrMenuAct1
    sta STR_LO
    lda #>StrMenuAct1
    sta STR_HI
    lda #0
    jsr PrintTopBarText
    rts
_dma_not_1:
    cmp #2
    bne _dma_3
    lda #<StrMenuAct2
    sta STR_LO
    lda #>StrMenuAct2
    sta STR_HI
    lda #0
    jsr PrintTopBarText
    rts
_dma_3:
    lda #<StrMenuAct3
    sta STR_LO
    lda #>StrMenuAct3
    sta STR_HI
    lda #0
    jsr PrintTopBarText
    rts

DrawMenuPickPlay:
    jsr ClearTopBar
    lda #<StrPickPlay
    sta STR_LO
    lda #>StrPickPlay
    sta STR_HI
    lda #1
    jsr PrintTopBarText
    rts

DrawMenuPickDisc:
    jsr ClearTopBar
    lda #<StrPickDisc
    sta STR_LO
    lda #>StrPickDisc
    sta STR_HI
    lda #1
    jsr PrintTopBarText
    rts

FlashIllegalAction:
    jsr ClearTopBar
    lda #<StrActionIllegale
    sta STR_LO
    lda #>StrActionIllegale
    sta STR_HI
    lda #7
    jsr PrintTopBarText
    jsr ErrorBuzzSound
    lda #180            ; ~2.2s delay for clear reading
    jsr DelayRoutine
    rts

DrawMenuThomson:
    jsr ClearTopBar
    lda #<StrTourThomson
    sta STR_LO
    lda #>StrTourThomson
    sta STR_HI
    lda #11
    jsr PrintTopBarText
    rts

DisplayThomsonPlay:
    jsr ClearTopBar
    lda #<StrThomJoue
    sta STR_LO
    lda #>StrThomJoue
    sta STR_HI
    lda #1
    jsr PrintTopBarText
    ldx PLAY_CARD
    lda CardNamesLo,x
    sta STR_LO
    lda CardNamesHi,x
    sta STR_HI
    lda #15
    jsr PrintTopBarText
    rts

DisplayThomsonDisc:
    jsr ClearTopBar
    lda #<StrThomDefausse
    sta STR_LO
    lda #>StrThomDefausse
    sta STR_HI
    lda #1
    jsr PrintTopBarText
    ldx PLAY_CARD
    lda CardNamesLo,x
    sta STR_LO
    lda CardNamesHi,x
    sta STR_HI
    lda #17
    jsr PrintTopBarText
    rts

; =============================================================================
; GESTION DU CURSEUR DE SELECTION DE CARTE EN MAIN (LIGNE 7)
; =============================================================================
ClearAllCardCursors:
    ldx #56
_cac_scan:
    stx TEMP_X
    lda HGR_ROW_LO,x
    sta PTR2_LO
    lda HGR_ROW_HI,x
    sta PTR2_HI
    ldy #0
_cac_loop:
    lda #$2A
    sta (PTR2_LO),y
    iny
    lda #$55
    sta (PTR2_LO),y
    iny
    cpy #40
    bne _cac_loop
    ldx TEMP_X
    inx
    cpx #64
    bne _cac_scan
    rts

HighlightCardCursor:
    jsr ClearAllCardCursors
    ldx CURSOR_POS
    lda HandLabelCols,x
    sta HGR_COL
    lda #7
    sta HGR_ROW
    lda #<StrCursor
    sta STR_LO
    lda #>StrCursor
    sta STR_HI
    lda #0
    sta INV_FLAG
    jsr HGR_PrintString
    rts

ClearCardCursor:
    jsr ClearAllCardCursors
    rts

HandLabelCols:
    .byte 2, 7, 12, 17, 22, 27, 32

StrCursor:          .byte $5E, $5E, $5E, $5E, $5E, 0
StrBlank4:          .text "    ", 0
StrBlank2:          .text "  ", 0
StrBlank3:          .text "   ", 0
StrBlank8:          .text "        ", 0
StrThomsonPlate:    .text " THOMSON", 0
StrKmsLabel:        .text "kms :", 0
StrDefausse:        .text "defausse", 0
StrResteLabel:      .text "reste ", 0
StrCartesLabel:     .text "cartes", 0

StrMenuDraw0:       .text ">TIRER UNE CARTE<  COUP-FOURRE  ABANDON", 0
StrMenuDraw1:       .text " TIRER UNE CARTE >COUP-FOURRE<  ABANDON", 0
StrMenuDraw2:       .text " TIRER UNE CARTE  COUP-FOURRE >ABANDON<", 0

StrMenuAct0:        .text ">JOUER<   DEFAUSSER  C-FOURRE  ABANDON", 0
StrMenuAct1:        .text " JOUER  >DEFAUSSER<  C-FOURRE  ABANDON", 0
StrMenuAct2:        .text " JOUER   DEFAUSSER >C-FOURRE<  ABANDON", 0
StrMenuAct3:        .text " JOUER   DEFAUSSER  C-FOURRE >ABANDON<", 0

StrPickPlay:        .text " JOUER : CHOISIR UNE CARTE (1-7) / ESC  ", 0
StrPickDisc:        .text " DEFAUSSER : CHOISIR CARTE (1-7) / ESC  ", 0
StrActionIllegale:  .text "*** ACTION ILLEGALE ! ***", 0
StrTourThomson:     .text "TOUR DE THOMSON...", 0
StrThomJoue:        .text "THOMSON JOUE: ", 0
StrThomDefausse:    .text "THOMSON JETTE: ", 0
StrNoCF:            .text "PAS DE COUP-FOURRE POSSIBLE !", 0

; =============================================================================
; LOGIQUE DE DEROULEMENT D'UNE MANCHE
; =============================================================================
PlayRound:
    lda #0
    sta P_KMS
    sta P_KMS+1
    sta T_KMS
    sta T_KMS+1

    sta P_BATTLE
    sta T_BATTLE
    sta P_LIMIT
    sta T_LIMIT
    sta P_STARTED
    sta T_STARTED
    sta DISCARD_TOP

    sta P_BOTTE_COUNT
    sta T_BOTTE_COUNT
    sta P_CF_COUNT
    sta T_CF_COUNT
    sta P_200_COUNT
    sta T_200_COUNT
    sta ROUND_WINNER
    sta CURSOR_POS
    sta MENU_SEL
    sta PICK_MODE
    sta CF_HAND_IDX

    ldx #0
_reset_bottes_loop:
    sta P_BOTTES,x
    sta T_BOTTES,x
    inx
    cpx #4
    bne _reset_bottes_loop

    ldx #0
_reset_hands_loop:
    sta P_HAND,x
    sta T_HAND,x
    inx
    cpx #7
    bne _reset_hands_loop

    jsr InitDeck
    jsr DrawBoardHGR

    ; Distribution de 6 cartes chacun (slot 7 reste vide au debut)
    ldx #0
_deal_six_cards:
    stx TEMP_X
    jsr DrawCardFromDeck
    ldx TEMP_X
    sta P_HAND,x
    stx SLOT_NUM
    inc SLOT_NUM
    sta CARD_ID
    jsr DrawCardInSlot
    jsr BeepSound

    jsr DrawCardFromDeck
    ldx TEMP_X
    sta T_HAND,x

    ldx TEMP_X
    inx
    cpx #6
    bne _deal_six_cards

    lda #0
    sta P_HAND+6
    sta T_HAND+6

    jsr UpdateScoresAndDrawCount

    inc ROUND_NUM
    lda ROUND_NUM
    ror
    bcs _round_turn_loop
    jmp _start_thomson_turn

_round_turn_loop:
    ; ================= TOUR DU JOUEUR =================
    lda DECK_REMAIN
    beq _talon_exhausted

    jsr PlayerTurnAction
    lda ROUND_WINNER
    bne _finish_round_sequence

    lda P_KMS+1
    cmp #>700
    bne _check_deck_after_player
    lda P_KMS
    cmp #<700
    beq _player_hit_700

_check_deck_after_player:
    lda DECK_REMAIN
    beq _talon_exhausted

_start_thomson_turn:
    ; ================= TOUR DE THOMSON (IA) =================
    lda DECK_REMAIN
    beq _talon_exhausted
    jsr DrawThomsonCardFromDeck
    jsr UpdateScoresAndDrawCount

    jsr ThomsonTurnAction
    lda T_KMS+1
    cmp #>700
    bne _check_deck_after_thomson
    lda T_KMS
    cmp #<700
    beq _thomson_hit_700

_check_deck_after_thomson:
    lda DECK_REMAIN
    beq _talon_exhausted

    jmp _round_turn_loop

_player_hit_700:
    lda #1
    sta ROUND_WINNER
    jmp _finish_round_sequence

_thomson_hit_700:
    lda #2
    sta ROUND_WINNER
    jmp _finish_round_sequence

_talon_exhausted:
    lda #0
    sta ROUND_WINNER

_finish_round_sequence:
    jsr ResultsScreenHGR
    rts

ROUND_NUM:      .byte 0
ROUND_WINNER:   .byte 0

; =============================================================================
; GESTION DU TOUR DU JOUEUR (PHASES 1, 2, 3)
; =============================================================================
PlayerTurnAction:
    ; Phase 1 : Tirer une carte / Coup-Fourre / Abandon
    lda #0
    sta MENU_SEL
    jsr DrawMenuDraw

_wait_draw_key:
    lda KBD
    bpl _wait_draw_key
    bit KBDSTRB
    and #$7F

    cmp #$08            ; Fleche gauche
    beq _draw_prev_opt
    cmp #$15            ; Fleche droite
    beq _draw_next_opt

    cmp #'1'
    beq _do_tirer_carte
    cmp #'T'
    beq _do_tirer_carte
    cmp #'t'
    beq _do_tirer_carte
    cmp #' '
    beq _confirm_draw_opt
    cmp #$0D
    beq _confirm_draw_opt

    cmp #'2'
    beq _do_cf_from_draw
    cmp #'C'
    beq _do_cf_from_draw
    cmp #'c'
    beq _do_cf_from_draw

    cmp #'3'
    beq _jump_surrender_d
    cmp #'A'
    beq _jump_surrender_d
    cmp #'a'
    beq _jump_surrender_d
    cmp #'Q'
    beq _jump_surrender_d
    cmp #'q'
    beq _jump_surrender_d

    jmp _wait_draw_key

_jump_surrender_d:
    jmp PlayerSurrender

_draw_prev_opt:
    lda MENU_SEL
    beq _draw_wrap_right
    dec MENU_SEL
    jsr DrawMenuDraw
    jmp _wait_draw_key
_draw_wrap_right:
    lda #2
    sta MENU_SEL
    jsr DrawMenuDraw
    jmp _wait_draw_key

_draw_next_opt:
    lda MENU_SEL
    cmp #2
    beq _draw_wrap_left
    inc MENU_SEL
    jsr DrawMenuDraw
    jmp _wait_draw_key
_draw_wrap_left:
    lda #0
    sta MENU_SEL
    jsr DrawMenuDraw
    jmp _wait_draw_key

_confirm_draw_opt:
    lda MENU_SEL
    beq _do_tirer_carte
    cmp #1
    beq _do_cf_from_draw
    jmp PlayerSurrender

_do_cf_from_draw:
    jsr CheckAndExecuteCoupFourre
    jsr DrawMenuDraw
    jmp _wait_draw_key

_do_tirer_carte:
    jsr DrawPlayerCardFromDeck

PlayerTurnActionPhase:
    ; Phase 2 : Action avec 7 cartes (Jouer, Defausser, Coup-Fourre, Abandon)
    lda #0
    sta MENU_SEL
    jsr DrawMenuAction

_wait_action_key:
    lda KBD
    bpl _wait_action_key
    bit KBDSTRB
    and #$7F

    cmp #$08            ; Fleche gauche
    beq _act_prev_opt
    cmp #$15            ; Fleche droite
    beq _act_next_opt

    cmp #'1'
    beq _jump_play
    cmp #'J'
    beq _jump_play
    cmp #'j'
    beq _jump_play

    cmp #'2'
    beq _jump_disc
    cmp #'D'
    beq _jump_disc
    cmp #'d'
    beq _jump_disc

    cmp #'3'
    beq _do_cf_from_act
    cmp #'C'
    beq _do_cf_from_act
    cmp #'c'
    beq _do_cf_from_act

    cmp #'4'
    beq _jump_surrender
    cmp #'A'
    beq _jump_surrender
    cmp #'a'
    beq _jump_surrender
    cmp #'Q'
    beq _jump_surrender
    cmp #'q'
    beq _jump_surrender

    cmp #' '
    beq _confirm_action_opt
    cmp #$0D
    beq _confirm_action_opt

    jmp _wait_action_key

_jump_play:
    jmp _choose_play_card
_jump_disc:
    jmp _choose_disc_card
_jump_surrender:
    jmp PlayerSurrender

_act_prev_opt:
    lda MENU_SEL
    beq _act_wrap_right
    dec MENU_SEL
    jsr DrawMenuAction
    jmp _wait_action_key
_act_wrap_right:
    lda #3
    sta MENU_SEL
    jsr DrawMenuAction
    jmp _wait_action_key

_act_next_opt:
    lda MENU_SEL
    cmp #3
    beq _act_wrap_left
    inc MENU_SEL
    jsr DrawMenuAction
    jmp _wait_action_key
_act_wrap_left:
    lda #0
    sta MENU_SEL
    jsr DrawMenuAction
    jmp _wait_action_key

_confirm_action_opt:
    lda MENU_SEL
    beq _jump_play
    cmp #1
    beq _jump_disc
    cmp #2
    beq _do_cf_from_act
    jmp PlayerSurrender

_do_cf_from_act:
    jsr CheckAndExecuteCoupFourre
    jsr DrawMenuAction
    jmp _wait_action_key

; Phase 3 : Selection de la carte (1..7)
_choose_play_card:
    lda #1              ; Mode JOUER
    sta PICK_MODE
    jsr DrawMenuPickPlay
    jmp _enter_pick_loop

_choose_disc_card:
    lda #2              ; Mode DEFAUSSER
    sta PICK_MODE
    jsr DrawMenuPickDisc

_enter_pick_loop:
    lda #0
    sta CURSOR_POS
    jsr HighlightCardCursor

_pick_card_loop:
    lda KBD
    bpl _pick_card_loop
    bit KBDSTRB
    and #$7F

    cmp #$1B            ; ESC -> Retour au menu Action
    bne _chk_pick_arrows
    jsr ClearCardCursor
    jmp PlayerTurnActionPhase

_chk_pick_arrows:
    cmp #$08            ; Gauche
    beq _pick_left
    cmp #$15            ; Droite
    beq _pick_right

    cmp #'1'
    bcc _chk_pick_space
    cmp #'8'
    bcs _chk_pick_space
    sec
    sbc #'1'
    sta TEMP_A
    jsr _get_player_max_cursor
    cpx TEMP_A
    bcc _pick_card_loop ; Touche au-dela des cartes en main !
    lda TEMP_A
    jsr _change_cursor_pos
    jmp _pick_card_loop

_chk_pick_space:
    cmp #' '
    beq _confirm_card_selection
    cmp #$0D
    beq _confirm_card_selection
    jmp _pick_card_loop

_pick_left:
    lda CURSOR_POS
    beq _pick_wrap_right
    dec CURSOR_POS
    jmp _after_pick_move
_pick_wrap_right:
    jsr _get_player_max_cursor
    stx CURSOR_POS
_after_pick_move:
    jsr HighlightCardCursor
    jmp _pick_card_loop

_pick_right:
    jsr _get_player_max_cursor
    cpx CURSOR_POS
    beq _pick_wrap_left
    inc CURSOR_POS
    jmp _after_pick_move
_pick_wrap_left:
    lda #0
    sta CURSOR_POS
    jmp _after_pick_move

_get_player_max_cursor:
    ldx #0
-   lda P_HAND,x
    beq +
    inx
    cpx #7
    bne -
+   dex
    bpl +
    ldx #0
+   rts

_change_cursor_pos:
    sta TEMP_A
    jsr ClearCardCursor
    lda TEMP_A
    sta CURSOR_POS
    jsr HighlightCardCursor
    rts

_confirm_card_selection:
    ldx CURSOR_POS
    lda P_HAND,x
    bne _valid_hand_card
    jmp _pick_card_loop

_valid_hand_card:
    sta PLAY_CARD
    lda PICK_MODE
    cmp #2
    beq _do_discard_selected_card

    ; Mode JOUER
    jsr CanPlayerPlayCard
    bcs _card_play_is_legal
    jsr FlashIllegalAction
    jsr DrawMenuPickPlay
    jsr HighlightCardCursor
    jmp _pick_card_loop

_card_play_is_legal:
    jsr ClearCardCursor
    jsr ApplyPlayerCard
    jsr RemovePlayedCard
    jsr RedrawPlayerHand
    ; Si c'est une botte, le joueur pioche et rejoue !
    lda PLAY_CARD
    cmp #CARD_CITERNE
    bcc _finish_player_turn
    cmp #CARD_VEHPRIO+1
    bcs _finish_player_turn
    jsr DrawPlayerCardFromDeck
    jmp PlayerTurnActionPhase
_finish_player_turn:
    rts

_do_discard_selected_card:
    jsr ClearCardCursor
    lda PLAY_CARD
    sta DISCARD_TOP
    lda #18
    sta SLOT_NUM
    lda DISCARD_TOP
    sta CARD_ID
    jsr DrawCardInSlot
    jsr BeepSound
    jsr RemovePlayedCard
    jsr RedrawPlayerHand
    rts

PlayerSurrender:
    lda #2
    sta ROUND_WINNER
    rts

; Coup-Fourre : verification et declenchement
CheckAndExecuteCoupFourre:
    lda P_BATTLE
    beq _cf_chk_limit
    cmp #CARD_PANNE
    bne _cf_chk_acc
    lda #CARD_CITERNE
    jsr FindPlayerHandCard
    bcc _no_cf_possible
    jmp _do_cf_execute

_cf_chk_acc:
    cmp #CARD_ACCIDENT
    bne _cf_chk_crev
    lda #CARD_ASVOLANT
    jsr FindPlayerHandCard
    bcc _no_cf_possible
    jmp _do_cf_execute

_cf_chk_crev:
    cmp #CARD_CREVAISON
    bne _cf_chk_feu
    lda #CARD_INCREVABLE
    jsr FindPlayerHandCard
    bcc _no_cf_possible
    jmp _do_cf_execute

_cf_chk_feu:
    cmp #CARD_FEUROUGE
    bne _cf_chk_limit
    lda #CARD_VEHPRIO
    jsr FindPlayerHandCard
    bcc _no_cf_possible
    jmp _do_cf_execute

_cf_chk_limit:
    lda P_LIMIT
    cmp #CARD_LIMITATION
    bne _no_cf_possible
    lda #CARD_VEHPRIO
    jsr FindPlayerHandCard
    bcc _no_cf_possible
    jmp _do_cf_execute

_no_cf_possible:
    jsr ClearTopBar
    lda #<StrNoCF
    sta STR_LO
    lda #>StrNoCF
    sta STR_HI
    lda #5
    jsr PrintTopBarText
    jsr ErrorBuzzSound
    lda #25
    jsr DelayRoutine
    rts

_do_cf_execute:
    stx CF_HAND_IDX
    sta PLAY_CARD
    jsr ApplyPlayerCard
    ldx CF_HAND_IDX
    stx CURSOR_POS
    jsr RemovePlayedCard
    jsr DrawPlayerCardFromDeck
    jsr RedrawPlayerHand
    jsr AnnounceCoupFourre
    rts

FindPlayerHandCard:
    ldx #0
_fphc_loop:
    cmp P_HAND,x
    beq _found_ph_card
    inx
    cpx #7
    bne _fphc_loop
    clc
    rts
_found_ph_card:
    sec
    rts

RedrawPlayerHand:
    ldx #0
_redraw_hand_loop:
    stx HAND_X
    stx SLOT_NUM
    inc SLOT_NUM
    lda P_HAND,x
    beq _erase_empty_hand_slot
    sta CARD_ID
    jsr DrawCardInSlot
    jmp _next_hand_redraw
_erase_empty_hand_slot:
    jsr EraseSlot
_next_hand_redraw:
    ldx HAND_X
    inx
    cpx #7
    bne _redraw_hand_loop
    rts

RemovePlayedCard:
    ldx CURSOR_POS
    lda #0
    sta P_HAND,x
    jsr CompactPlayerHand
    rts

CompactPlayerHand:
    ldx #0
    ldy #0
_cph_copy:
    lda P_HAND,x
    beq _cph_skip
    sta P_HAND,y
    iny
_cph_skip:
    inx
    cpx #7
    bne _cph_copy

_cph_fill:
    cpy #7
    beq _cph_done
    lda #0
    sta P_HAND,y
    iny
    bne _cph_fill
_cph_done:
    rts

DrawPlayerCardFromDeck:
    lda DECK_REMAIN
    beq _dpcd_empty
    jsr CompactPlayerHand
    ldx #0
_dpcd_find_slot:
    lda P_HAND,x
    beq _dpcd_found_slot
    inx
    cpx #7
    bne _dpcd_find_slot
    rts
_dpcd_found_slot:
    stx TEMP_X
    jsr DrawCardFromDeck
    ldx TEMP_X
    sta P_HAND,x
    jsr RedrawPlayerHand
    jsr UpdateScoresAndDrawCount
    jsr BeepSound
_dpcd_empty:
    rts

ErrorBuzzSound:
    ldx #25
_eb_outer:
    bit SPEAKER
    ldy #200
_eb_inner:
    dey
    bne _eb_inner
    dex
    bne _eb_outer
    rts

CURSOR_POS:     .byte 0
PLAY_CARD:      .byte 0

; =============================================================================
; REGLES DE VALIDATION ET APPLICATION DES COUPS DU JOUEUR
; =============================================================================
CanPlayerPlayCard:
    lda PLAY_CARD
    cmp #CARD_CITERNE
    bcc _not_botte_rule
    jmp _legal_move_exit

_not_botte_rule:
    cmp #CARD_PANNE
    beq _check_atk_thomson
    cmp #CARD_ACCIDENT
    beq _check_atk_thomson
    cmp #CARD_CREVAISON
    beq _check_atk_thomson
    cmp #CARD_FEUROUGE
    beq _check_atk_thomson
    cmp #CARD_LIMITATION
    beq _check_lim_thomson

    cmp #CARD_ESSENCE
    beq _check_rem_self
    cmp #CARD_REPARATION
    beq _check_rem_self
    cmp #CARD_ROUESECOUR
    beq _check_rem_self
    cmp #CARD_FEUVERT
    beq _check_green_self
    cmp #CARD_FINLIMITE
    bne +
    jmp _check_endlim_self
+

    cmp #CARD_200KM
    bne +
    jmp _check_dist_200
+   cmp #CARD_100KM
    beq _to_check_dist_std
    cmp #CARD_75KM
    beq _to_check_dist_std
    cmp #CARD_50KM
    beq _to_check_dist_std
    cmp #CARD_25KM
    beq _to_check_dist_std
    clc
    rts

_to_check_dist_std:
    jmp _check_dist_standard

_to_illegal_move:
    clc
    rts

_to_legal_move:
    sec
    rts

_check_atk_thomson:
    lda PLAY_CARD
    cmp #CARD_FEUROUGE
    bne _check_botte_imm
    lda T_BOTTES+3
    bne _to_illegal_move
_check_botte_imm:
    lda PLAY_CARD
    sec
    sbc #1
    tax
    cpx #3
    bcs _check_t_green_light
    lda T_BOTTES,x
    bne _to_illegal_move
_check_t_green_light:
    lda T_BATTLE
    cmp #CARD_FEUVERT
    bne _to_illegal_move
    sec
    rts

_check_lim_thomson:
    lda T_STARTED
    beq _to_illegal_move   ; Thomson n'a pas encore pose de Feu Vert en debut de partie !
    lda T_BOTTES+3
    bne _to_illegal_move   ; Thomson possede le Vehicule Prioritaire
    lda T_LIMIT
    cmp #CARD_LIMITATION
    beq _to_illegal_move   ; Thomson est deja limite
    sec
    rts

_check_rem_self:
    lda PLAY_CARD
    sec
    sbc #5
    cmp P_BATTLE
    bne _illegal_move_exit
    sec
    rts

_check_green_self:
    lda P_BOTTES+3
    bne _illegal_move_exit
    lda P_BATTLE
    beq _legal_move_exit
    cmp #CARD_FEUROUGE
    beq _legal_move_exit
    cmp #CARD_ESSENCE
    beq _legal_move_exit
    cmp #CARD_REPARATION
    beq _legal_move_exit
    cmp #CARD_ROUESECOUR
    beq _legal_move_exit
    clc
    rts

_check_endlim_self:
    lda P_LIMIT
    cmp #CARD_LIMITATION
    bne _illegal_move_exit
    sec
    rts

_check_dist_200:
    lda P_200_COUNT
    cmp #2
    bcs _illegal_move_exit
    jmp _check_dist_standard

_check_dist_standard:
    lda P_BOTTES+3
    bne _check_speed_limit
    lda P_BATTLE
    cmp #CARD_FEUVERT
    bne _illegal_move_exit

_check_speed_limit:
    lda P_LIMIT
    cmp #CARD_LIMITATION
    bne _check_700_cap
    lda PLAY_CARD
    cmp #CARD_50KM
    bcc _illegal_move_exit

_check_700_cap:
    jsr GetCardKm
    lda P_KMS
    clc
    adc TEMP_A
    sta NUM_LO
    lda P_KMS+1
    adc TEMP_X
    sta NUM_HI
    lda NUM_HI
    cmp #>700
    bcc _local_legal_exit
    bne _illegal_move_exit
    lda NUM_LO
    cmp #<700
    beq _local_legal_exit
    bcc _local_legal_exit
    jmp _illegal_move_exit

_local_legal_exit:
    sec
    rts

_illegal_move_exit:
    clc
    rts

_legal_move_exit:
    sec
    rts

; =============================================================================
; APPLICATION DE LA CARTE JOUEE PAR LE JOUEUR
; =============================================================================
ApplyPlayerCard:
    lda PLAY_CARD
    cmp #CARD_CITERNE
    bcc _not_player_botte

    sec
    sbc #CARD_CITERNE   ; 0..3
    tax
    lda #1
    sta P_BOTTES,x
    cpx #3              ; Vehicule Prioritaire ?
    bne +
    sta P_STARTED       ; Permet de rouler des le debut
+
    lda P_BOTTE_COUNT
    cmp #4
    bcs _p_skip_botte_draw
    clc
    adc #8
    sta SLOT_NUM
    inc P_BOTTE_COUNT
    lda PLAY_CARD
    sta CARD_ID
    jsr DrawCardInSlot
    jsr BeepSound
_p_skip_botte_draw:

    txa
    clc
    adc #1
    cmp P_BATTLE
    bne _no_p_cf
    inc P_CF_COUNT
    lda #1
    sta P_STARTED
    lda #CARD_FEUVERT
    sta P_BATTLE
    lda #17
    sta SLOT_NUM
    lda #CARD_FEUVERT
    sta CARD_ID
    jsr DrawCardInSlot
    jsr AnnounceCoupFourre
_no_p_cf:
    rts

_not_player_botte:
    cmp #CARD_PANNE
    bcc _not_player_attack
    cmp #CARD_FEUROUGE+1
    bcs _not_player_attack
    cmp #CARD_LIMITATION
    beq _p_limit_t
    sta T_BATTLE
    lda #19
    sta SLOT_NUM
    lda T_BATTLE
    sta CARD_ID
    jsr DrawCardInSlot
    jsr BeepSound
    rts

_p_limit_t:
    sta T_LIMIT
    lda #20
    sta SLOT_NUM
    lda T_LIMIT
    sta CARD_ID
    jsr DrawCardInSlot
    jsr BeepSound
    rts

_not_player_attack:
    cmp #CARD_ESSENCE
    bcc _is_player_km
    cmp #CARD_FEUVERT+1
    bcs _is_player_km
    cmp #CARD_FEUVERT
    bne _p_not_feuvert
    lda #1
    sta P_STARTED
    lda PLAY_CARD
_p_not_feuvert:
    cmp #CARD_FINLIMITE
    beq _p_end_limit
    sta P_BATTLE
    lda #17
    sta SLOT_NUM
    lda P_BATTLE
    sta CARD_ID
    jsr DrawCardInSlot
    jsr BeepSound
    rts

_p_end_limit:
    lda #0
    sta P_LIMIT
    lda #16
    sta SLOT_NUM
    jsr EraseSlot
    jsr BeepSound
    rts

_is_player_km:
    jsr GetCardKm
    lda P_KMS
    clc
    adc TEMP_A
    sta P_KMS
    lda P_KMS+1
    adc TEMP_X
    sta P_KMS+1

    lda PLAY_CARD
    cmp #CARD_200KM
    bne _p_no_200_inc
    inc P_200_COUNT
_p_no_200_inc:
    jsr UpdateScoresAndDrawCount
    jsr BeepSound
    rts

GetCardKm:
    lda PLAY_CARD
    cmp #CARD_200KM
    bne _gck_100
    lda #200
    sta TEMP_A
    lda #0
    sta TEMP_X
    rts
_gck_100:
    cmp #CARD_100KM
    bne _gck_75
    lda #100
    sta TEMP_A
    lda #0
    sta TEMP_X
    rts
_gck_75:
    cmp #CARD_75KM
    bne _gck_50
    lda #75
    sta TEMP_A
    lda #0
    sta TEMP_X
    rts
_gck_50:
    cmp #CARD_50KM
    bne _gck_25
    lda #50
    sta TEMP_A
    lda #0
    sta TEMP_X
    rts
_gck_25:
    cmp #CARD_25KM
    bne _gck_zero
    lda #25
    sta TEMP_A
    lda #0
    sta TEMP_X
    rts
_gck_zero:
    lda #0
    sta TEMP_A
    sta TEMP_X
    rts

AnnounceCoupFourre:
    lda #4
    sta HGR_COL
    lda #0
    sta HGR_ROW
    lda #<StrCoupFourre
    sta STR_LO
    lda #>StrCoupFourre
    sta STR_HI
    jsr HGR_PrintString
    jsr FanfareSound
    lda #20
    jsr DelayRoutine
    jsr DrawMenuAction
    rts

StrCoupFourre:  .text "***** COUP-FOURRE ! (+300) *****", 0

; =============================================================================
; IA THOMSON (ADAPTATION EXACTE DES HEURISTIQUES DE BOUCROT 1985 - MO5)
; =============================================================================
ThomsonTurnAction:
    jsr DrawMenuThomson

    ; -------------------------------------------------------------------------
    ; 1. COUP GAGNANT IMMEDIAT : Peut-on atteindre exactement 700 km ce tour ?
    ; -------------------------------------------------------------------------
    jsr ThomsonCanRoll
    bcc _t_not_winning_now

    lda #<700
    sec
    sbc T_KMS
    bne +
    jmp _t_not_winning_now
+   cmp #200
    bne _twin_100
    lda #CARD_200KM
    jsr FindThomsonCard
    bcc _t_not_winning_now
    jsr CanThomsonAddDist
    bcc _t_not_winning_now
    jmp _t_play_found_card

_twin_100:
    cmp #100
    bne _twin_75
    lda #CARD_100KM
    jsr FindThomsonCard
    bcc _t_not_winning_now
    jsr CanThomsonAddDist
    bcc _t_not_winning_now
    jmp _t_play_found_card

_twin_75:
    cmp #75
    bne _twin_50
    lda #CARD_75KM
    jsr FindThomsonCard
    bcc _t_not_winning_now
    jsr CanThomsonAddDist
    bcc _t_not_winning_now
    jmp _t_play_found_card

_twin_50:
    cmp #50
    bne _twin_25
    lda #CARD_50KM
    jsr FindThomsonCard
    bcc _t_not_winning_now
    jsr CanThomsonAddDist
    bcc _t_not_winning_now
    jmp _t_play_found_card

_twin_25:
    cmp #25
    bne _t_not_winning_now
    lda #CARD_25KM
    jsr FindThomsonCard
    bcc _t_not_winning_now
    jsr CanThomsonAddDist
    bcc _t_not_winning_now
    jmp _t_play_found_card

_t_not_winning_now:

    ; -------------------------------------------------------------------------
    ; 2. ATTAQUE D'URGENCE : Si le joueur est proche de 700 (>= 500 kms)
    ; -------------------------------------------------------------------------
    lda P_KMS+1
    cmp #>500
    bcc _t_check_my_repairs
    bne _t_do_emergency_attack
    lda P_KMS
    cmp #<500
    bcc _t_check_my_repairs

_t_do_emergency_attack:
    jsr ThomsonTryAttackPlayer
    bcc _t_check_my_repairs
    jmp _t_play_found_card

_t_check_my_repairs:
    ; -------------------------------------------------------------------------
    ; 3. PARADE / REPARATIONS (Si Thomson est attaque)
    ; -------------------------------------------------------------------------
    lda T_BATTLE
    bne +
    jmp _t_check_start_game
+   cmp #CARD_PANNE
    beq _t_parade_panne
    cmp #CARD_ACCIDENT
    beq _t_parade_accident
    cmp #CARD_CREVAISON
    beq _t_parade_crevaison
    cmp #CARD_FEUROUGE
    beq _t_parade_feurouge
    jmp _t_check_lim_parade

_t_parade_panne:
    lda #CARD_ESSENCE
    jsr FindThomsonCard
    bcc _t_chk_panne_botte
    jmp _t_play_found_card
_t_chk_panne_botte:
    lda DECK_REMAIN
    cmp #10
    bcs +
    lda #CARD_CITERNE
    jsr FindThomsonCard
    bcc +
    jmp _t_play_botte
+   jmp _t_try_attack_or_discard

_t_parade_accident:
    lda #CARD_REPARATION
    jsr FindThomsonCard
    bcc _t_chk_acc_botte
    jmp _t_play_found_card
_t_chk_acc_botte:
    lda DECK_REMAIN
    cmp #10
    bcs +
    lda #CARD_ASVOLANT
    jsr FindThomsonCard
    bcc +
    jmp _t_play_botte
+   jmp _t_try_attack_or_discard

_t_parade_crevaison:
    lda #CARD_ROUESECOUR
    jsr FindThomsonCard
    bcc _t_chk_crev_botte
    jmp _t_play_found_card
_t_chk_crev_botte:
    lda DECK_REMAIN
    cmp #10
    bcs +
    lda #CARD_INCREVABLE
    jsr FindThomsonCard
    bcc +
    jmp _t_play_botte
+   jmp _t_try_attack_or_discard

_t_parade_feurouge:
    lda #CARD_FEUVERT
    jsr FindThomsonCard
    bcc _t_chk_feu_botte
    jmp _t_play_found_card
_t_chk_feu_botte:
    lda DECK_REMAIN
    cmp #10
    bcs +
    lda #CARD_VEHPRIO
    jsr FindThomsonCard
    bcc +
    jmp _t_play_botte
+   jmp _t_try_attack_or_discard

_t_check_lim_parade:
    lda T_LIMIT
    cmp #CARD_LIMITATION
    bne _t_normal_drive
    lda #CARD_FINLIMITE
    jsr FindThomsonCard
    bcc +
    jmp _t_play_found_card
+

_t_check_start_game:
    lda #CARD_FEUVERT
    jsr FindThomsonCard
    bcc _t_check_start_botte
    jmp _t_play_found_card
_t_check_start_botte:
    lda DECK_REMAIN
    cmp #50
    bcs +
    lda #CARD_VEHPRIO
    jsr FindThomsonCard
    bcc +
    jmp _t_play_botte
+   jmp _t_try_attack_or_discard

_t_normal_drive:
    ; -------------------------------------------------------------------------
    ; 4. JOUER DE LA DISTANCE (BORNES)
    ; -------------------------------------------------------------------------
    jsr ThomsonCanRoll
    bcc _t_try_attack_or_discard

    lda #CARD_200KM
    jsr FindThomsonCard
    bcc _t_dist_100
    jsr CanThomsonAddDist
    bcc _t_dist_100
    jmp _t_play_found_card

_t_dist_100:
    lda #CARD_100KM
    jsr FindThomsonCard
    bcc _t_dist_75
    jsr CanThomsonAddDist
    bcc _t_dist_75
    jmp _t_play_found_card

_t_dist_75:
    lda #CARD_75KM
    jsr FindThomsonCard
    bcc _t_dist_50
    jsr CanThomsonAddDist
    bcc _t_dist_50
    jmp _t_play_found_card

_t_dist_50:
    lda #CARD_50KM
    jsr FindThomsonCard
    bcc _t_dist_25
    jsr CanThomsonAddDist
    bcc _t_dist_25
    jmp _t_play_found_card

_t_dist_25:
    lda #CARD_25KM
    jsr FindThomsonCard
    bcc _t_try_attack_or_discard
    jsr CanThomsonAddDist
    bcc _t_try_attack_or_discard
    jmp _t_play_found_card

_t_try_attack_or_discard:
    ; -------------------------------------------------------------------------
    ; 5. ATTAQUER LE JOUEUR (Attaque standard)
    ; -------------------------------------------------------------------------
    jsr ThomsonTryAttackPlayer
    bcc +
    jmp _t_play_found_card
+

    ; -------------------------------------------------------------------------
    ; 6. POSER UNE BOTTE SEULEMENT SI FIN DE PAQUET (DECK_REMAIN <= 4)
    ; -------------------------------------------------------------------------
    lda DECK_REMAIN
    cmp #5
    bcs _t_no_end_botte
    ldx #0
_t_scan_end_botte:
    lda T_HAND,x
    cmp #CARD_CITERNE
    bcc +
    cmp #CARD_VEHPRIO+1
    bcs +
    stx T_PLAY_IDX
    jmp _t_play_botte
+   inx
    cpx #7
    bne _t_scan_end_botte

_t_no_end_botte:
    ; -------------------------------------------------------------------------
    ; 7. DEFAUSSE INTELLIGENTE (Smart Discard MO5)
    ; -------------------------------------------------------------------------
    jmp ThomsonSmartDiscard

; =============================================================================
; EXECUTION DES COUPS DE THOMSON
; =============================================================================
_t_play_botte:
    ldx T_PLAY_IDX
    lda T_HAND,x
    sta PLAY_CARD
    jsr DisplayThomsonPlay

    ; Active la botte dans T_BOTTES
    lda PLAY_CARD
    sec
    sbc #CARD_CITERNE   ; 0..3
    tax
    lda #1
    sta T_BOTTES,x
    cpx #3              ; Vehicule Prioritaire ?
    bne +
    sta T_STARTED
+

    ; Dessin de la botte dans l'emplacement 12..15 si < 4
    lda T_BOTTE_COUNT
    cmp #4
    bcs _t_skip_botte_draw
    clc
    adc #12
    sta SLOT_NUM
    inc T_BOTTE_COUNT
    lda PLAY_CARD
    sta CARD_ID
    jsr DrawCardInSlot
    jsr BeepSound

_t_skip_botte_draw:
    ; Effet immédiat de la botte jouée sur les attaques actives
    lda PLAY_CARD
    cmp #CARD_VEHPRIO
    bne _t_chk_hazard_botte
    ; Vehicule Prioritaire annule Limitation :
    lda #0
    sta T_LIMIT
    lda #20
    sta SLOT_NUM
    jsr EraseSlot
    ; Et debloque le feu rouge en feu vert si stopped :
    lda T_BATTLE
    cmp #CARD_FEUROUGE
    bne _t_finish_botte_play
    lda #CARD_FEUVERT
    sta T_BATTLE
    lda #19
    sta SLOT_NUM
    lda #CARD_FEUVERT
    sta CARD_ID
    jsr DrawCardInSlot
    jmp _t_finish_botte_play

_t_chk_hazard_botte:
    sec
    sbc #15             ; 16->1 (Panne), 17->2 (Accident), 18->3 (Crevaison)
    cmp T_BATTLE
    bne _t_finish_botte_play
    ; Attaque levee par la botte ! Elle equivaut a un Feu Vert officiel
    lda #CARD_FEUVERT
    sta T_BATTLE
    lda #19
    sta SLOT_NUM
    lda #CARD_FEUVERT
    sta CARD_ID
    jsr DrawCardInSlot

_t_finish_botte_play:
    ldx T_PLAY_IDX
    lda #0
    sta T_HAND,x
    jsr CompactThomsonHand
    ; Thomson pioche et rejoue !
    jsr DrawThomsonCardFromDeck
    jsr UpdateScoresAndDrawCount
    lda #30
    jsr DelayRoutine
    jmp ThomsonTurnAction

_t_play_found_card:
    ldx T_PLAY_IDX
    lda T_HAND,x
    sta PLAY_CARD
    jsr DisplayThomsonPlay
    lda PLAY_CARD        ; Restaure l'identifiant de la carte apres affichage

    ; Est-ce une distance ? (11..15)
    cmp #CARD_200KM
    bcc _t_not_km
    cmp #CARD_25KM+1
    bcs _t_not_km
    jsr GetCardKm
    lda T_KMS
    clc
    adc TEMP_A
    sta T_KMS
    lda T_KMS+1
    adc TEMP_X
    sta T_KMS+1
    lda PLAY_CARD
    cmp #CARD_200KM
    bne _t_no_inc_200
    inc T_200_COUNT
_t_no_inc_200:
    jsr UpdateScoresAndDrawCount
    jsr BeepSound
    jmp _t_finish_action

_t_not_km:
    ; Est-ce une attaque ? (1..5)
    cmp #CARD_PANNE
    bcc _t_not_atk
    cmp #CARD_FEUROUGE+1
    bcs _t_not_atk
    cmp #CARD_LIMITATION
    beq _t_apply_lim
    sta P_BATTLE
    lda #17
    sta SLOT_NUM
    lda P_BATTLE
    sta CARD_ID
    jsr DrawCardInSlot
    jsr BeepSound
    jmp _t_finish_action

_t_apply_lim:
    sta P_LIMIT
    lda #16
    sta SLOT_NUM
    lda P_LIMIT
    sta CARD_ID
    jsr DrawCardInSlot
    jsr BeepSound
    jmp _t_finish_action

_t_not_atk:
    ; Est-ce une parade ? (6..10)
    cmp #CARD_ESSENCE
    bcc _t_finish_action
    cmp #CARD_FEUVERT+1
    bcs _t_finish_action
    cmp #CARD_FEUVERT
    bne _t_not_fv
    lda #1
    sta T_STARTED
    lda PLAY_CARD
_t_not_fv:
    cmp #CARD_FINLIMITE
    beq _t_apply_endlim
    sta T_BATTLE
    lda #19
    sta SLOT_NUM
    lda T_BATTLE
    sta CARD_ID
    jsr DrawCardInSlot
    jsr BeepSound
    jmp _t_finish_action

_t_apply_endlim:
    lda #0
    sta T_LIMIT
    lda #20
    sta SLOT_NUM
    jsr EraseSlot
    jsr BeepSound

_t_finish_action:
    ldx T_PLAY_IDX
    lda #0
    sta T_HAND,x
    jsr CompactThomsonHand
    lda #30
    jsr DelayRoutine
    rts

; =============================================================================
; DEFAUSSE INTELLIGENTE SELON LES CRITERES ORIGINAUX DU MO5
; =============================================================================
ThomsonSmartDiscard:
    lda #0
    sta BEST_DISC_SCORE
    lda #6
    sta BEST_DISC_IDX

    ldx #0
_eval_disc_loop:
    stx CURR_EVAL_IDX
    lda T_HAND,x
    bne +
    jmp _skip_eval_card
+   sta PLAY_CARD

    ; Ne jamais défausser une botte (Score 0)
    cmp #CARD_CITERNE
    bcc _eval_non_botte
    cmp #CARD_VEHPRIO+1
    bcs _eval_non_botte
    lda #0
    jmp _compare_score

_eval_non_botte:
    ; 1. Attaque contre un joueur immunise ? (Score 90)
    cmp #CARD_FEUROUGE
    bne _chk_disc_crev
    lda P_BOTTES+3
    beq _chk_disc_acc
    lda #90
    jmp _compare_score

_chk_disc_crev:
    cmp #CARD_CREVAISON
    bne _chk_disc_acc
    lda P_BOTTES+2
    beq _chk_disc_acc
    lda #90
    jmp _compare_score

_chk_disc_acc:
    cmp #CARD_ACCIDENT
    bne _chk_disc_panne
    lda P_BOTTES+1
    beq _chk_disc_panne
    lda #90
    jmp _compare_score

_chk_disc_panne:
    cmp #CARD_PANNE
    bne _chk_disc_lim
    lda P_BOTTES+0
    beq _chk_disc_lim
    lda #90
    jmp _compare_score

_chk_disc_lim:
    cmp #CARD_LIMITATION
    bne _chk_disc_dist
    lda P_BOTTES+3
    beq _chk_disc_dist
    lda #90
    jmp _compare_score

_chk_disc_dist:
    ; 2. Distance depassant 700 ou 200km epuise ? (Score 80)
    lda PLAY_CARD
    cmp #CARD_200KM
    bcc _chk_disc_parade_imm
    cmp #CARD_25KM+1
    bcs _chk_disc_parade_imm

    cmp #CARD_200KM
    bne _chk_dist_val_sum
    lda T_200_COUNT
    cmp #2
    bcc _chk_dist_val_sum
    lda #80
    jmp _compare_score

_chk_dist_val_sum:
    jsr GetCardKm
    lda T_KMS
    clc
    adc TEMP_A
    sta NUM_LO
    lda T_KMS+1
    adc TEMP_X
    sta NUM_HI
    lda NUM_HI
    cmp #>700
    bcc _dist_not_over
    bne _dist_is_over
    lda NUM_LO
    cmp #<700
    beq _dist_not_over
    bcc _dist_not_over
_dist_is_over:
    lda #80
    jmp _compare_score

_dist_not_over:
    ; Plus la distance est faible, plus elle est defaussable (25km=Score 35, 200km=Score 27)
    lda PLAY_CARD
    asl
    clc
    adc #5
    jmp _compare_score

_chk_disc_parade_imm:
    ; 3. Parade pour une panne dont on est immunise ? (Score 70)
    lda PLAY_CARD
    cmp #CARD_ESSENCE
    bne _chk_p_rep
    lda T_BOTTES+0
    beq _chk_p_default
    lda #70
    jmp _compare_score

_chk_p_rep:
    cmp #CARD_REPARATION
    bne _chk_p_roue
    lda T_BOTTES+1
    beq _chk_p_default
    lda #70
    jmp _compare_score

_chk_p_roue:
    cmp #CARD_ROUESECOUR
    bne _chk_p_finlim
    lda T_BOTTES+2
    beq _chk_p_default
    lda #70
    jmp _compare_score

_chk_p_finlim:
    cmp #CARD_FINLIMITE
    bne _chk_p_feuvert
    lda T_BOTTES+3
    beq _chk_p_default
    lda #70
    jmp _compare_score

_chk_p_feuvert:
    cmp #CARD_FEUVERT
    bne _chk_p_default
    lda T_BOTTES+3
    beq _chk_p_default
    lda #70
    jmp _compare_score

_chk_p_default:
    lda #40

_compare_score:
    cmp BEST_DISC_SCORE
    bcc _next_eval_card
    sta BEST_DISC_SCORE
    ldy CURR_EVAL_IDX
    sty BEST_DISC_IDX

_next_eval_card:
_skip_eval_card:
    ldx CURR_EVAL_IDX
    inx
    cpx #7
    beq +
    jmp _eval_disc_loop
+
    ; Defausse effective de la carte choisie
    ldx BEST_DISC_IDX
    stx T_PLAY_IDX
    lda T_HAND,x
    sta DISCARD_TOP
    sta PLAY_CARD
    jsr DisplayThomsonDisc
    lda #18
    sta SLOT_NUM
    lda DISCARD_TOP
    sta CARD_ID
    jsr DrawCardInSlot
    jsr BeepSound
    ldx T_PLAY_IDX
    lda #0
    sta T_HAND,x
    jsr CompactThomsonHand
    lda #30
    jsr DelayRoutine
    rts

BEST_DISC_SCORE:    .byte 0
BEST_DISC_IDX:      .byte 0
CURR_EVAL_IDX:      .byte 0
T_PLAY_IDX:         .byte 0

; =============================================================================
; ROUTINES UTILITAIRES DE DECISION POUR L'IA THOMSON
; =============================================================================
FindThomsonCard:
    ldx #0
_find_t_loop:
    cmp T_HAND,x
    beq _found_t_card
    inx
    cpx #7
    bne _find_t_loop
    clc
    rts
_found_t_card:
    stx T_PLAY_IDX
    sec
    rts

ThomsonCanRoll:
    lda T_BATTLE
    cmp #CARD_PANNE
    beq _t_roll_no
    cmp #CARD_ACCIDENT
    beq _t_roll_no
    cmp #CARD_CREVAISON
    beq _t_roll_no
    cmp #CARD_FEUROUGE
    beq _t_roll_no
    lda T_BOTTES+3      ; Vehicule Prioritaire ?
    bne _t_roll_yes
    lda T_BATTLE
    cmp #CARD_FEUVERT
    beq _t_roll_yes
_t_roll_no:
    clc
    rts
_t_roll_yes:
    sec
    rts

ThomsonTryAttackPlayer:
    lda P_BATTLE
    cmp #CARD_FEUVERT
    bne _tatk_chk_lim

    lda P_BOTTES+3
    bne _tatk_chk_crev
    lda #CARD_FEUROUGE
    jsr FindThomsonCard
    bcs _tatk_ok

_tatk_chk_crev:
    lda P_BOTTES+2
    bne _tatk_chk_acc
    lda #CARD_CREVAISON
    jsr FindThomsonCard
    bcs _tatk_ok

_tatk_chk_acc:
    lda P_BOTTES+1
    bne _tatk_chk_panne
    lda #CARD_ACCIDENT
    jsr FindThomsonCard
    bcs _tatk_ok

_tatk_chk_panne:
    lda P_BOTTES+0
    bne _tatk_chk_lim
    lda #CARD_PANNE
    jsr FindThomsonCard
    bcs _tatk_ok

_tatk_chk_lim:
    lda P_STARTED       ; Le joueur a-t-il pose un Feu Vert ou Botte Prioritaire ?
    beq _tatk_fail      ; Non : interdiction absolue de poser une limitation de vitesse !
    lda P_LIMIT
    cmp #CARD_LIMITATION
    beq _tatk_fail      ; Deja limite
    lda P_BOTTES+3
    bne _tatk_fail      ; Immunise par Vehicule Prioritaire
    lda #CARD_LIMITATION
    jsr FindThomsonCard
    bcs _tatk_ok

_tatk_fail:
    clc
    rts
_tatk_ok:
    sec
    rts

CanThomsonAddDist:
    pha
    sta PLAY_CARD

    ; Verification limitation de vitesse
    lda T_LIMIT
    cmp #CARD_LIMITATION
    bne _ctad_chk_cap
    lda T_BOTTES+3
    bne _ctad_chk_cap   ; Vehicule Prioritaire ignore la limitation
    lda PLAY_CARD
    cmp #CARD_50KM
    beq _ctad_chk_cap
    cmp #CARD_25KM
    beq _ctad_chk_cap
    pla
    clc
    rts

_ctad_chk_cap:
    lda PLAY_CARD
    cmp #CARD_200KM
    bne _ctad_calc_sum
    lda T_200_COUNT
    cmp #2
    bcc _ctad_calc_sum
    pla
    clc
    rts

_ctad_calc_sum:
    jsr GetCardKm
    lda T_KMS
    clc
    adc TEMP_A
    sta NUM_LO
    lda T_KMS+1
    adc TEMP_X
    sta NUM_HI

    lda NUM_HI
    cmp #>700
    bcc _t_dist_legal
    bne _t_dist_illegal
    lda NUM_LO
    cmp #<700
    beq _t_dist_legal
    bcc _t_dist_legal
_t_dist_illegal:
    pla
    clc
    rts
_t_dist_legal:
    pla
    sec
    rts

DrawThomsonCardFromDeck:
    lda DECK_REMAIN
    beq _dtcd_done
    jsr CompactThomsonHand
    ldx #0
-   lda T_HAND,x
    beq _dtcd_found
    inx
    cpx #7
    bne -
    rts
_dtcd_found:
    stx TEMP_X
    jsr DrawCardFromDeck
    ldx TEMP_X
    sta T_HAND,x
_dtcd_done:
    rts

CompactThomsonHand:
    ldx #0
    ldy #0
_cmp_copy:
    lda T_HAND,x
    beq _cmp_skip
    sta T_HAND,y
    iny
_cmp_skip:
    inx
    cpx #7
    bne _cmp_copy

_cmp_fill:
    cpy #7
    beq _cmp_done
    lda #0
    sta T_HAND,y
    iny
    bne _cmp_fill
_cmp_done:
    rts

; =============================================================================
; INITIALISATION ET MELANGE DU PAQUET (FISHER-YATES LFSR)
; =============================================================================
InitDeck:
    ldx #0
    lda #CARD_FEUVERT
    ldy #10
    jsr FillDeckSegment
    lda #CARD_FEUROUGE
    ldy #5
    jsr FillDeckSegment
    lda #CARD_ESSENCE
    ldy #6
    jsr FillDeckSegment
    lda #CARD_REPARATION
    ldy #6
    jsr FillDeckSegment
    lda #CARD_ROUESECOUR
    ldy #6
    jsr FillDeckSegment
    lda #CARD_PANNE
    ldy #3
    jsr FillDeckSegment
    lda #CARD_ACCIDENT
    ldy #3
    jsr FillDeckSegment
    lda #CARD_CREVAISON
    ldy #3
    jsr FillDeckSegment
    lda #CARD_LIMITATION
    ldy #4
    jsr FillDeckSegment
    lda #CARD_FINLIMITE
    ldy #6
    jsr FillDeckSegment
    lda #CARD_200KM
    ldy #4
    jsr FillDeckSegment
    lda #CARD_100KM
    ldy #12
    jsr FillDeckSegment
    lda #CARD_75KM
    ldy #10
    jsr FillDeckSegment
    lda #CARD_50KM
    ldy #10
    jsr FillDeckSegment
    lda #CARD_25KM
    ldy #10
    jsr FillDeckSegment
    lda #CARD_CITERNE
    sta DECK_DATA,x
    inx
    lda #CARD_ASVOLANT
    sta DECK_DATA,x
    inx
    lda #CARD_INCREVABLE
    sta DECK_DATA,x
    inx
    lda #CARD_VEHPRIO
    sta DECK_DATA,x
    inx

    lda #106
    sta DECK_REMAIN

    ; Melange Fisher-Yates
    ldx #105
_shuffle_loop:
    stx TEMP_X
    jsr GetRandomByte
    sta NUM_LO
    lda #0
    sta NUM_HI
    ldx TEMP_X
    inx
    stx TEMP_A
    lda NUM_LO
_mod_loop:
    cmp TEMP_A
    bcc _mod_done
    sbc TEMP_A
    jmp _mod_loop
_mod_done:
    tay
    ldx TEMP_X
    lda DECK_DATA,x
    pha
    lda DECK_DATA,y
    sta DECK_DATA,x
    pla
    sta DECK_DATA,y

    ldx TEMP_X
    dex
    bne _shuffle_loop
    rts

FillDeckSegment:
_fill_seg_loop:
    sta DECK_DATA,x
    inx
    dey
    bne _fill_seg_loop
    rts

DrawCardFromDeck:
    lda DECK_REMAIN
    beq _deck_is_empty
    dec DECK_REMAIN
    ldx DECK_REMAIN
    lda DECK_DATA,x
    rts
_deck_is_empty:
    lda #0
    rts

GetRandomByte:
    lda RND_SEED+1
    lsr
    lda RND_SEED
    ror
    bcc _no_xor_lfsr
    eor #$B4
_no_xor_lfsr:
    sta RND_SEED
    lda RND_SEED+1
    ror
    sta RND_SEED+1
    lda RND_SEED
    rts

; =============================================================================
; FEUILLE DE MARQUE DES RESULTATS (EXACTE REPLIQUE MO5)
; =============================================================================
ResultsScreenHGR:
    jsr ClearHGR

    ; Titre
    lda #12
    sta HGR_COL
    lda #1
    sta HGR_ROW
    lda #<StrResultats
    sta STR_LO
    lda #>StrResultats
    sta STR_HI
    jsr HGR_PrintString

    ; En-tetes colonnes
    lda #18
    sta HGR_COL
    lda #3
    sta HGR_ROW
    lda #<PLAYER_NAME
    sta STR_LO
    lda #>PLAYER_NAME
    sta STR_HI
    jsr HGR_PrintString

    lda #29
    sta HGR_COL
    lda #3
    sta HGR_ROW
    lda #<THOMSON_NAME
    sta STR_LO
    lda #>THOMSON_NAME
    sta STR_HI
    jsr HGR_PrintString

    ; Affichage des 8 lignes de score
    lda #0
    sta RES_P_TOTAL
    sta RES_P_TOTAL+1
    sta RES_T_TOTAL
    sta RES_T_TOTAL+1

    ; Ligne 1 : Bornes
    ldx #0
    lda P_KMS
    sta SCORE_P_VAL
    lda P_KMS+1
    sta SCORE_P_VAL+1
    lda T_KMS
    sta SCORE_T_VAL
    lda T_KMS+1
    sta SCORE_T_VAL+1
    jsr PrintScoreRow

    ; Ligne 2 : Bottes (100 pts par botte, +300 bonus si 4 bottes)
    ldx #1
    lda P_BOTTE_COUNT
    jsr CalcBottesScore
    sta SCORE_P_VAL
    stx SCORE_P_VAL+1
    lda T_BOTTE_COUNT
    jsr CalcBottesScore
    sta SCORE_T_VAL
    stx SCORE_T_VAL+1
    ldx #1
    jsr PrintScoreRow

    ; Ligne 3 : Coups-fourres (+300 par CF)
    ldx #2
    lda P_CF_COUNT
    jsr CalcCFScore
    sta SCORE_P_VAL
    stx SCORE_P_VAL+1
    lda T_CF_COUNT
    jsr CalcCFScore
    sta SCORE_T_VAL
    stx SCORE_T_VAL+1
    ldx #2
    jsr PrintScoreRow

    ; Ligne 4 : Manche gagnee (+400 si 700 km)
    lda #0
    sta SCORE_P_VAL
    sta SCORE_P_VAL+1
    sta SCORE_T_VAL
    sta SCORE_T_VAL+1
    lda ROUND_WINNER
    cmp #1
    bne _sc_m4_check_t
    lda #<400
    sta SCORE_P_VAL
    lda #>400
    sta SCORE_P_VAL+1
    jmp _sc_m4_print
_sc_m4_check_t:
    cmp #2
    bne _sc_m4_print
    lda #<400
    sta SCORE_T_VAL
    lda #>400
    sta SCORE_T_VAL+1
_sc_m4_print:
    ldx #3
    jsr PrintScoreRow

    ; Ligne 5 : Pas d'etape 200 (+300 pts)
    lda #0
    sta SCORE_P_VAL
    sta SCORE_P_VAL+1
    sta SCORE_T_VAL
    sta SCORE_T_VAL+1
    lda ROUND_WINNER
    cmp #1
    bne _sc_m5_check_t
    lda P_200_COUNT
    bne _sc_m5_print
    lda #<300
    sta SCORE_P_VAL
    lda #>300
    sta SCORE_P_VAL+1
    jmp _sc_m5_print
_sc_m5_check_t:
    cmp #2
    bne _sc_m5_print
    lda T_200_COUNT
    bne _sc_m5_print
    lda #<300
    sta SCORE_T_VAL
    lda #>300
    sta SCORE_T_VAL+1
_sc_m5_print:
    ldx #4
    jsr PrintScoreRow

    ; Ligne 6 : Capot (+500 si adversaire a 0 km)
    lda #0
    sta SCORE_P_VAL
    sta SCORE_P_VAL+1
    sta SCORE_T_VAL
    sta SCORE_T_VAL+1
    lda ROUND_WINNER
    cmp #1
    bne _sc_m6_check_t
    lda T_KMS
    ora T_KMS+1
    bne _sc_m6_print
    lda #<500
    sta SCORE_P_VAL
    lda #>500
    sta SCORE_P_VAL+1
    jmp _sc_m6_print
_sc_m6_check_t:
    cmp #2
    bne _sc_m6_print
    lda P_KMS
    ora P_KMS+1
    bne _sc_m6_print
    lda #<500
    sta SCORE_T_VAL
    lda #>500
    sta SCORE_T_VAL+1
_sc_m6_print:
    ldx #5
    jsr PrintScoreRow

    ; Ligne 7 : Total manche
    ldx #6
    lda RES_P_TOTAL
    sta SCORE_P_VAL
    lda RES_P_TOTAL+1
    sta SCORE_P_VAL+1
    lda RES_T_TOTAL
    sta SCORE_T_VAL
    lda RES_T_TOTAL+1
    sta SCORE_T_VAL+1
    jsr PrintScoreRow

    ; Ligne 8 : Report manche precedente
    ldx #7
    lda MATCH_P_LO
    sta SCORE_P_VAL
    lda MATCH_P_HI
    sta SCORE_P_VAL+1
    lda MATCH_T_LO
    sta SCORE_T_VAL
    lda MATCH_T_HI
    sta SCORE_T_VAL+1
    jsr PrintScoreRow

    ; Ligne 9 : GRAND TOTAL
    lda MATCH_P_LO
    clc
    adc RES_P_TOTAL
    sta MATCH_P_LO
    lda MATCH_P_HI
    adc RES_P_TOTAL+1
    sta MATCH_P_HI

    lda MATCH_T_LO
    clc
    adc RES_T_TOTAL
    sta MATCH_T_LO
    lda MATCH_T_HI
    adc RES_T_TOTAL+1
    sta MATCH_T_HI

    lda #4
    sta HGR_COL
    lda #21
    sta HGR_ROW
    lda #<StrTotalGeneral
    sta STR_LO
    lda #>StrTotalGeneral
    sta STR_HI
    jsr HGR_PrintString

    lda #20
    sta HGR_COL
    lda #21
    sta HGR_ROW
    lda MATCH_P_LO
    sta NUM_LO
    lda MATCH_P_HI
    sta NUM_HI
    jsr HGR_PrintDec

    lda #30
    sta HGR_COL
    lda #21
    sta HGR_ROW
    lda MATCH_T_LO
    sta NUM_LO
    lda MATCH_T_HI
    sta NUM_HI
    jsr HGR_PrintDec

    ; Invite a continuer
    lda #3
    sta HGR_COL
    lda #23
    sta HGR_ROW
    lda #<StrPressCont
    sta STR_LO
    lda #>StrPressCont
    sta STR_HI
    jsr HGR_PrintString

    jsr WaitKey
    rts

PrintScoreRow:
    stx ROW_IDX
    ; Libelle critere
    lda #3
    sta HGR_COL
    lda RowScanY,x
    sta HGR_ROW
    lda ScoreLabelsLo,x
    sta STR_LO
    lda ScoreLabelsHi,x
    sta STR_HI
    jsr HGR_PrintString

    ; Score Joueur
    lda #20
    sta HGR_COL
    ldx ROW_IDX
    lda RowScanY,x
    sta HGR_ROW
    lda SCORE_P_VAL
    sta NUM_LO
    lda SCORE_P_VAL+1
    sta NUM_HI
    jsr HGR_PrintDec

    ; Score Thomson
    lda #30
    sta HGR_COL
    ldx ROW_IDX
    lda RowScanY,x
    sta HGR_ROW
    lda SCORE_T_VAL
    sta NUM_LO
    lda SCORE_T_VAL+1
    sta NUM_HI
    jsr HGR_PrintDec

    ; Bip sonore
    jsr BeepSound
    lda #10
    jsr DelayRoutine

    ; Cumul total manche si index <= 5
    ldx ROW_IDX
    cpx #6
    bcs _no_subtotal_add
    lda RES_P_TOTAL
    clc
    adc SCORE_P_VAL
    sta RES_P_TOTAL
    lda RES_P_TOTAL+1
    adc SCORE_P_VAL+1
    sta RES_P_TOTAL+1

    lda RES_T_TOTAL
    clc
    adc SCORE_T_VAL
    sta RES_T_TOTAL
    lda RES_T_TOTAL+1
    adc SCORE_T_VAL+1
    sta RES_T_TOTAL+1
_no_subtotal_add:
    rts

CalcBottesScore:
    cmp #0
    beq _bottes_zero
    cmp #4
    beq _bottes_four
    ldx #0
    tay
    lda #0
_b_mult_loop:
    clc
    adc #100
    bcc _b_mult_no_hi
    inx
_b_mult_no_hi:
    dey
    bne _b_mult_loop
    rts
_bottes_four:
    lda #<700
    ldx #>700
    rts
_bottes_zero:
    lda #0
    ldx #0
    rts

CalcCFScore:
    cmp #0
    beq _cf_zero
    ldx #0
    tay
    lda #0
_cf_mult_loop:
    clc
    adc #<300
    pha
    txa
    adc #>300
    tax
    pla
    dey
    bne _cf_mult_loop
    rts
_cf_zero:
    lda #0
    ldx #0
    rts

ROW_IDX:        .byte 0
SCORE_P_VAL:    .word 0
SCORE_T_VAL:    .word 0
RES_P_TOTAL:    .word 0
RES_T_TOTAL:    .word 0

RowScanY:
    .byte 5, 7, 9, 11, 13, 15, 17, 19

ScoreLabelsLo:
    .byte <StrSc1, <StrSc2, <StrSc3, <StrSc4, <StrSc5, <StrSc6, <StrSc7, <StrSc8
ScoreLabelsHi:
    .byte >StrSc1, >StrSc2, >StrSc3, >StrSc4, >StrSc5, >StrSc6, >StrSc7, >StrSc8

StrResultats:       .text "R E S U L T A T S", 0
StrSc1:             .text "Bornes", 0
StrSc2:             .text "Bottes", 0
StrSc3:             .text "Coups-fourres", 0
StrSc4:             .text "Manche gagnee", 0
StrSc5:             .text "Pas d'etape 200", 0
StrSc6:             .text "Capot", 0
StrSc7:             .text "Total manche...", 0
StrSc8:             .text ".........Report", 0
StrTotalGeneral:    .text "T O T A L", 0
StrPressCont:       .text "TAPER UNE TOUCHE POUR CONTINUER...", 0

; =============================================================================
; ECRAN DE FIN DE PARTIE
; =============================================================================
EndOfMatchScreen:
    jsr ClearHGR

    lda #11
    sta HGR_COL
    lda #4
    sta HGR_ROW
    lda #<StrFinPartie
    sta STR_LO
    lda #>StrFinPartie
    sta STR_HI
    jsr HGR_PrintString

    ; Qui a gagne ?
    lda MATCH_P_HI
    cmp MATCH_T_HI
    bcc _t_won_match
    bne _p_won_match
    lda MATCH_P_LO
    cmp MATCH_T_LO
    bcc _t_won_match
    bne _p_won_match

    ; Match nul
    lda #13
    sta HGR_COL
    lda #8
    sta HGR_ROW
    lda #<StrNul
    sta STR_LO
    lda #>StrNul
    sta STR_HI
    jsr HGR_PrintString
    jmp _ask_replay_prompt

_p_won_match:
    lda #11
    sta HGR_COL
    lda #8
    sta HGR_ROW
    lda #<PLAYER_NAME
    sta STR_LO
    lda #>PLAYER_NAME
    sta STR_HI
    jsr HGR_PrintString

    lda #19
    sta HGR_COL
    lda #8
    sta HGR_ROW
    lda #<StrGagne
    sta STR_LO
    lda #>StrGagne
    sta STR_HI
    jsr HGR_PrintString
    jmp _display_comment

_t_won_match:
    lda #11
    sta HGR_COL
    lda #8
    sta HGR_ROW
    lda #<StrTGagne
    sta STR_LO
    lda #>StrTGagne
    sta STR_HI
    jsr HGR_PrintString

_display_comment:
    lda #13
    sta HGR_COL
    lda #12
    sta HGR_ROW
    lda #<StrBrillamment
    sta STR_LO
    lda #>StrBrillamment
    sta STR_HI
    jsr HGR_PrintString

_ask_replay_prompt:
    lda #7
    sta HGR_COL
    lda #18
    sta HGR_ROW
    lda #<StrReplay
    sta STR_LO
    lda #>StrReplay
    sta STR_HI
    jsr HGR_PrintString
    rts

StrFinPartie:   .text "FIN DE LA PARTIE", 0
StrNul:         .text "MATCH NUL !!!", 0
StrGagne:       .text "GAGNE !!!", 0
StrTGagne:      .text "THOMSON GAGNE !!!", 0
StrBrillamment: .text "BRILLAMMENT !!!", 0
StrReplay:      .text "UNE AUTRE PARTIE (O/N) ? ", 0

; =============================================================================
; ROUTINES UTILITAIRES ET EFFETS SONORES
; =============================================================================
WaitKey:
    lda KBD
    bpl WaitKey
    bit KBDSTRB
    and #$7F
    rts

BeepSound:
    ldx #12
_beep_loop:
    bit SPEAKER
    ldy #30
_beep_delay:
    dey
    bne _beep_delay
    dex
    bne _beep_loop
    rts

FanfareSound:
    ; Note 1 (Do / C4 : ~523 Hz -> delay 45)
    ldx #35
_ff_n1:
    bit SPEAKER
    ldy #45
-   dey
    bne -
    dex
    bne _ff_n1

    lda #4
    jsr DelayRoutine

    ; Note 2 (Mi / E4 : ~659 Hz -> delay 36)
    ldx #40
_ff_n2:
    bit SPEAKER
    ldy #36
-   dey
    bne -
    dex
    bne _ff_n2

    lda #4
    jsr DelayRoutine

    ; Note 3 (Sol / G4 : ~784 Hz -> delay 30)
    ldx #45
_ff_n3:
    bit SPEAKER
    ldy #30
-   dey
    bne -
    dex
    bne _ff_n3

    lda #4
    jsr DelayRoutine

    ; Note 4 (Do aigu / C5 : ~1046 Hz -> delay 22)
    ldx #80
_ff_n4:
    bit SPEAKER
    ldy #22
-   dey
    bne -
    dex
    bne _ff_n4
    rts

DelayRoutine:
    pha
    txa
    pha
    tya
    pha
    tsx
    lda $0103,x         ; A original (nombre d'iterations)
    tax
_del_outer:
    ldy #0
_del_inner:
    dey
    bne _del_inner
    dex
    bne _del_outer
    pla
    tay
    pla
    tax
    pla
    rts

; Table des noms de cartes
CardNamesLo:
    .byte <StrCN0, <StrCN1, <StrCN2, <StrCN3, <StrCN4, <StrCN5, <StrCN6, <StrCN7
    .byte <StrCN8, <StrCN9, <StrCN10, <StrCN11, <StrCN12, <StrCN13, <StrCN14
    .byte <StrCN15, <StrCN16, <StrCN17, <StrCN18, <StrCN19, <StrCN20
CardNamesHi:
    .byte >StrCN0, >StrCN1, >StrCN2, >StrCN3, >StrCN4, >StrCN5, >StrCN6, >StrCN7
    .byte >StrCN8, >StrCN9, >StrCN10, >StrCN11, >StrCN12, >StrCN13, >StrCN14
    .byte >StrCN15, >StrCN16, >StrCN17, >StrCN18, >StrCN19, >StrCN20
CardNamesCol:
    .byte 15, 13, 16, 16, 10, 16, 17, 15, 13, 12, 16
    .byte 14, 14, 14, 14, 14, 12, 14, 15, 10, 20

StrCN0:     .text "1000 BORNES", 0
StrCN1:     .text "PANNE D'ESSENCE", 0
StrCN2:     .text "ACCIDENT", 0
StrCN3:     .text "CREVAISON", 0
StrCN4:     .text "LIMITATION DE VITESSE", 0
StrCN5:     .text "FEU ROUGE", 0
StrCN6:     .text "ESSENCE", 0
StrCN7:     .text "REPARATIONS", 0
StrCN8:     .text "ROUE DE SECOURS", 0
StrCN9:     .text "FIN DE LIMITATION", 0
StrCN10:    .text "FEU VERT", 0
StrCN11:    .text "ETAPE 200 KM", 0
StrCN12:    .text "ETAPE 100 KM", 0
StrCN13:    .text "ETAPE 75 KM", 0
StrCN14:    .text "ETAPE 50 KM", 0
StrCN15:    .text "ETAPE 25 KM", 0
StrCN16:    .text "BOTTE : CITERNE", 0
StrCN17:    .text "BOTTE : AS DU VOLANT", 0
StrCN18:    .text "BOTTE : INCREVABLE", 0
StrCN19:    .text "BOTTE : VEHICULE PRIORITAIRE", 0
StrCN20:    .text " ", 0

; =============================================================================
; INCLUSION DES DONNEES GRAPHIQUES HGR (BITMAPS DES 20 CARTES + POLICE 7X8)
; =============================================================================
.include "cards_gfx.asm"

; =============================================================================
; VARIABLES GLOBALES EN RAM
; =============================================================================
P_KMS:          .word 0
T_KMS:          .word 0
MATCH_P_LO:     .byte 0
MATCH_P_HI:     .byte 0
MATCH_T_LO:     .byte 0
MATCH_T_HI:     .byte 0

P_HAND:         .fill 7, 0
T_HAND:         .fill 7, 0
P_BOTTES:       .fill 4, 0
T_BOTTES:       .fill 4, 0
P_BATTLE:       .byte 0
T_BATTLE:       .byte 0
P_LIMIT:        .byte 0
T_LIMIT:        .byte 0
P_STARTED:      .byte 0
T_STARTED:      .byte 0
DISCARD_TOP:    .byte 0

P_BOTTE_COUNT:  .byte 0
T_BOTTE_COUNT:  .byte 0
P_CF_COUNT:     .byte 0
T_CF_COUNT:     .byte 0
P_200_COUNT:    .byte 0
T_200_COUNT:    .byte 0

DECK_REMAIN:    .byte 0
DECK_DATA:      .fill 106, 0
MENU_SEL:       .byte 0
PICK_MODE:      .byte 0
CF_HAND_IDX:    .byte 0

.end
