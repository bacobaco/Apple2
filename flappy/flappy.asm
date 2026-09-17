; Flappy Bird Apple II - Iconic Arcade Edition (City Skyline & Lush Ground)
; Assembler avec 64tass: 64tass --nostart -a -o flappy.bin flappy.asm

        .cpu "6502"
        * = $803

        jmp start

; === ROM Apple II ===
HGR     = $F3E2
KBD     = $C000
KBDSTRB = $C010
SPEAKER = $C030
TXTON   = $C051
FULLGR  = $C052
HOME    = $FC58
HPAG    = $E6

; Zero Page pointeurs
ptr     = $FA
ptr2    = $FC

NUM_PIPES  = 2
SKYLINE_Y  = 156        ; Début du paysage urbain & collines (lignes 156..175)
GROUND_Y   = 176        ; Ligne de sol / pelouse (lignes 176..191)

; Macro Hires lookup tables
hires_lo:
    .for i=0, i<192, i=i+1
        .byte <($2000 + (i & 7) * 1024 + ((i / 8) & 7) * 128 + ((i / 64) & 3) * 40)
    .next

hires_hi:
    .for i=0, i<192, i=i+1
        .byte >($2000 + (i & 7) * 1024 + ((i / 8) & 7) * 128 + ((i / 64) & 3) * 40)
    .next

div7:
    .for i=0, i<256, i=i+1
        .byte i / 7
    .next

mod7:
    .for i=0, i<256, i=i+1
        .byte i % 7
    .next

div7_hi:
    .for i=0, i<24, i=i+1
        .byte (256 + i) / 7
    .next

mod7_hi:
    .for i=0, i<24, i=i+1
        .byte (256 + i) % 7
    .next

bit_mask:
    .byte $01, $02, $04, $08, $10, $20, $40

bit_clear_mask:
    .byte $FE, $FD, $FB, $F7, $EF, $DF, $BF


start:
        jmp reset_game

main_loop:
        jsr move_pipes
        jsr calc_pipe_bounds
        jsr update_clouds
        jsr check_input
        
        inc random_seed
        inc frame_counter

        lda bird_vel
        bmi do_grav
        cmp #8
        bcs skip_grav
do_grav:
        inc bird_vel
skip_grav:
        lda bird_y
        sta bird_y_old
        clc
        adc bird_vel
        sta bird_y
        
        ; Plafond physique
        cmp #200            ; Les valeurs négatives (ex. 250) sont >= 200
        bcc ceiling_ok
        lda #0
        sta bird_y          
        sta bird_vel        
ceiling_ok:

        ; Sol physique : collision avec la pelouse verte (GROUND_Y = 176)
        ; Sprite 12 lignes : 164 + 11 = 175 < 176
        lda bird_y
        cmp #165
        bcc floor_ok
        jmp game_over
floor_ok:

        jsr erase_bird
        jsr draw_bird

        jsr check_collisions
        jsr check_score
        
        jsr wait_vbl
        jmp main_loop

; === Routines de Rendu Pixel ===

get_x_params:
        lda logic_x_hi
        bne high_x
        ldx logic_x
        ldy div7, x
        lda mod7, x
        tax
        jmp set_mask
high_x:
        ldx logic_x
        ldy div7_hi, x
        lda mod7_hi, x
        tax
set_mask:
        lda bit_mask, x
        sta tmp_mask
        lda bit_clear_mask, x
        sta tmp_mask_clear
        sty tmp_byte_offset
        rts

draw_v_line_on:
        ldx tmp_y1
        cpx tmp_y2
        bcs dv_on_done
        lda hires_lo, x
        sta ptr
        lda hires_hi, x
        sta ptr+1
        ldy tmp_byte_offset
        lda tmp_mask        ; Bit 7 = 0 : Palette verte NTSC
        sta tmp_val
dv_on_loop:
        lda (ptr), y
        ora tmp_val
        sta (ptr), y
        
        inx
        cpx tmp_y2
        bcs dv_on_done
        beq dv_on_done
        
        txa
        and #$07
        beq dv_on_slow
        lda ptr+1
        clc
        adc #4
        sta ptr+1
        jmp dv_on_loop
dv_on_slow:
        lda hires_lo, x
        sta ptr
        lda hires_hi, x
        sta ptr+1
        jmp dv_on_loop
dv_on_done:
        rts

draw_v_line_off:
        ldx tmp_y1
        cpx tmp_y2
        bcs dv_off_done
        lda hires_lo, x
        sta ptr
        lda hires_hi, x
        sta ptr+1
        ldy tmp_byte_offset
        lda tmp_mask_clear
        sta tmp_val
dv_off_loop:
        lda (ptr), y
        and tmp_val
        sta (ptr), y
        
        inx
        cpx tmp_y2
        bcs dv_off_done
        beq dv_off_done
        
        txa
        and #$07
        beq dv_off_slow
        lda ptr+1
        clc
        adc #4
        sta ptr+1
        jmp dv_off_loop
dv_off_slow:
        lda hires_lo, x
        sta ptr
        lda hires_hi, x
        sta ptr+1
        jmp dv_off_loop
dv_off_done:
        rts

erase_pipe:
        lda logic_x_hi
        bmi ep_skip
        cmp #1
        bcc ep_do
        bne ep_skip
        lda logic_x
        cmp #24
        bcs ep_skip
ep_do:
        jsr get_x_params
        jsr apply_score_column
        
        ; Effacer le tuyau supérieur (0 à tmp_gap)
        lda #0
        sta tmp_y1
        lda tmp_gap
        sta tmp_y2
        jsr draw_v_line_off
        
        ; Restaurer la colonne de nuage sous le tuyau supérieur
        jsr restore_cloud_column
        
        ; Effacer le tuyau inférieur au-dessus du décor (tmp_gap + 45 à SKYLINE_Y)
        lda tmp_gap
        clc
        adc #45
        sta tmp_y1
        lda #SKYLINE_Y
        sta tmp_y2
        jsr draw_v_line_off
        
        ; Restaurer la colonne de décor urbain et collines sous le tuyau !
        jsr restore_skyline_column
        
        jsr apply_score_column
ep_skip:
        rts

; Tuyau vert émeraude avec capuchon blanc élargi (Iconic Flappy Bird) :
; - Capuchon (rebord) de 16 pixels (rel_x = 0..15) avec collerette débordante
; - Corps de tuyau de 14 pixels (rel_x = 1..14) en VERT saturé NTSC (colonnes impaires)
draw_pipe:
        lda logic_x_hi
        bmi dp_skip
        cmp #1
        bcc dp_do
        bne dp_skip
        lda logic_x
        cmp #24
        bcc dp_do
dp_skip:
        rts
dp_do:
        inc pipe_drawn_flag
        jsr get_x_params
        jsr apply_score_column
        
        ; 1. Le capuchon (rebord blanc solide) est tracé sur TOUTES les colonnes
        ; Capuchon supérieur : tmp_gap - 8 à tmp_gap
        lda tmp_gap
        sec
        sbc #8
        sta tmp_y1
        lda tmp_gap
        sta tmp_y2
        jsr draw_v_line_on
        
        ; Capuchon inférieur : tmp_gap + 45 à tmp_gap + 53
        lda tmp_gap
        clc
        adc #45
        sta tmp_y1
        adc #8
        sta tmp_y2
        jsr draw_v_line_on
        
        ; 2. La tige du tuyau :
        ; - Sur colonnes impaires : ALLUMÉE (vert saturé NTSC)
        ; - Sur colonnes paires  : ÉTEINTE (noir opaque : occulte à 100% le décor derrière !)
        lda logic_x
        and #1
        beq dp_stem_even

dp_stem_odd:
        ; Tige supérieure : 0 à tmp_gap - 8
        lda #0
        sta tmp_y1
        lda tmp_gap
        sec
        sbc #8
        sta tmp_y2
        jsr draw_v_line_on
        
        ; Tige inférieure : tmp_gap + 53 à GROUND_Y (176)
        lda tmp_gap
        clc
        adc #53
        sta tmp_y1
        lda #GROUND_Y
        sta tmp_y2
        jsr draw_v_line_on
        jmp dp_score_post

dp_stem_even:
        ; Tige supérieure : 0 à tmp_gap - 8
        lda #0
        sta tmp_y1
        lda tmp_gap
        sec
        sbc #8
        sta tmp_y2
        jsr draw_v_line_off
        
        ; Tige inférieure : tmp_gap + 53 à GROUND_Y (176)
        lda tmp_gap
        clc
        adc #53
        sta tmp_y1
        lda #GROUND_Y
        sta tmp_y2
        jsr draw_v_line_off

dp_score_post:
        jsr apply_score_column
        rts

draw_full_pipe:
        lda pipe_x_lo, x
        sta tmp_pipe_fill
        lda pipe_x_hi, x
        sta tmp_pipe_fill_hi
        lda pipe_gap_y, x
        sta tmp_gap
        
        lda #0
        sta tmp_pipe_rel_x
df_loop:
        lda tmp_pipe_fill
        sta logic_x
        lda tmp_pipe_fill_hi
        sta logic_x_hi
        jsr draw_pipe
        
        inc tmp_pipe_fill
        bne df_no_hi
        inc tmp_pipe_fill_hi
df_no_hi:
        inc tmp_pipe_rel_x
        lda tmp_pipe_rel_x
        cmp #16
        bcc df_loop
        rts

move_pipes:
        lda #0
        sta pipes_on_screen
        
        ldx #0
mp_loop:
        stx tmp_pipe_idx
        
        ldx tmp_pipe_idx
        lda pipe_x_lo, x
        sta pipe_x_old_lo, x
        lda pipe_x_hi, x
        sta pipe_x_old_hi, x
        
        sec
        lda pipe_x_lo, x
        sbc #2
        sta pipe_x_lo, x
        lda pipe_x_hi, x
        sbc #0
        sta pipe_x_hi, x
        
        ; Disparition totale ? (pipe_x_old + 16 < 0)
        lda pipe_x_old_lo, x
        clc
        adc #16
        lda pipe_x_old_hi, x
        adc #0
        bpl mp_normal
        
        ldx tmp_pipe_idx
        ; Spawn nouveau tuyau tout à droite (X=280 = $0118)
        lda #$18
        sta pipe_x_lo, x
        sta pipe_x_old_lo, x
        lda #1
        sta pipe_x_hi, x
        sta pipe_x_old_hi, x
        
        jsr get_random
        and #$3F
        clc
        adc #25
        sta pipe_gap_y, x
        
        jmp mp_next

mp_normal:
        ; Effacer les 2 colonnes arrière du tuyau (rel_x 15 et 14)
        ldx tmp_pipe_idx
        lda pipe_x_old_lo, x
        clc
        adc #15
        sta logic_x
        lda pipe_x_old_hi, x
        adc #0
        sta logic_x_hi
        lda pipe_gap_y, x
        sta tmp_gap
        jsr erase_pipe

        lda logic_x
        sec
        sbc #1
        sta logic_x
        lda logic_x_hi
        sbc #0
        sta logic_x_hi
        jsr erase_pipe

        ; Dessiner les 2 colonnes avant du tuyau (rel_x 0 et 1)
        lda #0
        sta pipe_drawn_flag

        ldx tmp_pipe_idx
        lda pipe_x_lo, x
        sta logic_x
        lda pipe_x_hi, x
        sta logic_x_hi
        lda pipe_gap_y, x
        sta tmp_gap
        lda #0              ; rel_x = 0
        sta tmp_pipe_rel_x
        jsr draw_pipe

        lda logic_x
        clc
        adc #1
        sta logic_x
        lda logic_x_hi
        adc #0
        sta logic_x_hi
        lda #1              ; rel_x = 1
        sta tmp_pipe_rel_x
        jsr draw_pipe

        lda pipe_drawn_flag
        beq mp_not_on_screen
        inc pipes_on_screen
mp_not_on_screen:

mp_next:
        ldx tmp_pipe_idx
        inx
        cpx #NUM_PIPES
        beq mp_done
        jmp mp_loop
mp_done:
        rts

; === Rendu et Restauration du Paysage Urbain & Collines (Lignes 156..175) ===

restore_skyline_column:
        lda tmp_byte_offset
        and #$07
        sta tmp_val         ; Colonne dans le module de 8 octets (0..7)
        
        ldx #0
rsc_loop:
        stx tmp_y
        txa
        clc
        adc #SKYLINE_Y
        tay
        lda hires_lo, y
        sta ptr
        lda hires_hi, y
        sta ptr+1
        
        ; Récupère l'octet dans skyline_data : tmp_y * 8 + tmp_val
        lda tmp_y
        asl
        asl
        asl
        clc
        adc tmp_val
        tax
        lda skyline_data, x
        and tmp_mask
        sta tmp_bit_val     ; Pixel du skyline pour cette colonne uniquement
        
        ; Injecte uniquement ce pixel précis sur l'écran
        ldy tmp_byte_offset
        lda (ptr), y
        and tmp_mask_clear
        ora tmp_bit_val
        sta (ptr), y
        
        ldx tmp_y
        inx
        cpx #20
        bcc rsc_loop
        rts

init_ground:
        ; 1. Tracer le paysage urbain et collines statique (Lignes 156 à 175)
        ldx #0
ig_sky_row:
        stx tmp_y
        txa
        clc
        adc #SKYLINE_Y
        tay
        lda hires_lo, y
        sta ptr
        lda hires_hi, y
        sta ptr+1
        
        lda tmp_y
        asl
        asl
        asl
        sta tmp_val         ; tmp_y * 8
        
        ldy #39
ig_sky_col:
        tya
        and #$07
        clc
        adc tmp_val
        tax
        lda skyline_data, x
        sta (ptr), y
        dey
        bpl ig_sky_col
        
        ldx tmp_y
        inx
        cpx #20
        bcc ig_sky_row

        ; 2. Ligne de démarcation blanche/brillante de l'herbe (Ligne 176)
        lda hires_lo+GROUND_Y
        sta ptr
        lda hires_hi+GROUND_Y
        sta ptr+1
        lda #$7F
        ldy #39
ig_l176:
        sta (ptr), y
        dey
        bpl ig_l176

        ; 3. Pelouse VERTE UNIE sans scintillement ni code-barres (Lignes 177 à 180)
        ; Palette 0 (bit 7=0) : octets pairs=$2A, octets impairs=$55 -> VERT PUR CONTINU
        ldx #177
ig_lawn_row:
        lda hires_lo, x
        sta ptr
        lda hires_hi, x
        sta ptr+1
        ldy #39
ig_lawn_col:
        tya
        lsr
        bcs ig_lawn_odd
        lda #$2A            ; Octet pair
        bne ig_lawn_draw
ig_lawn_odd:
        lda #$55            ; Octet impair
ig_lawn_draw:
        sta (ptr), y
        dey
        bpl ig_lawn_col
        inx
        cpx #181
        bcc ig_lawn_row

        ; 4. Sol sablé / terre doré chaleureux (Lignes 181 à 191)
        ; Palette 1 (bit 7=1) : octets pairs=$AA, octets impairs=$D5 -> SABLE DORÉ UNIFORME
        ldx #181
ig_sand_row:
        lda hires_lo, x
        sta ptr
        lda hires_hi, x
        sta ptr+1
        ldy #39
ig_sand_col:
        tya
        lsr
        bcs ig_sand_odd
        lda #$AA            ; Octet pair en Groupe 1
        bne ig_sand_draw
ig_sand_odd:
        lda #$D5            ; Octet impair en Groupe 1
ig_sand_draw:
        sta (ptr), y
        dey
        bpl ig_sand_col
        inx
        cpx #192
        bcc ig_sand_row

        jsr render_high_score
        jsr draw_cloud1
        jsr draw_cloud2
        rts

; === Rendu High-Score en bas à droite (Lignes 183..189, Octets 34..38) ===

render_high_score:
        lda high_score
        ldx #0
        stx hi_digit_t
rhs_t_loop:
        cmp #10
        bcc rhs_t_done
        sbc #10
        inc hi_digit_t
        bne rhs_t_loop
rhs_t_done:
        sta hi_digit_u
        
        ; hi_digit_t offset = hi_digit_t * 7
        lda hi_digit_t
        asl
        clc
        adc hi_digit_t  ; * 3
        asl
        clc
        adc hi_digit_t  ; * 7
        sta tmp_hi_offset_t
        
        ; hi_digit_u offset = hi_digit_u * 7
        lda hi_digit_u
        asl
        clc
        adc hi_digit_u  ; * 3
        asl
        clc
        adc hi_digit_u  ; * 7
        sta tmp_hi_offset_u
        
        ldx #0
rhs_row_loop:
        stx tmp_y
        txa
        clc
        adc #183            ; Scanlines Y = 183..189 (au milieu du sable)
        tay
        lda hires_lo, y
        sta ptr
        lda hires_hi, y
        sta ptr+1
        
        ldx tmp_y
        ; Colonne 34 : H
        lda bold_font_h, x
        ldy #34
        sta (ptr), y
        
        ; Colonne 35 : I
        lda bold_font_i, x
        ldy #35
        sta (ptr), y
        
        ; Colonne 36 : :
        lda bold_font_colon, x
        ldy #36
        sta (ptr), y
        
        ; Colonne 37 : dizaines
        ldx tmp_hi_offset_t
        lda bold_digits, x
        ldy #37
        sta (ptr), y
        
        ; Colonne 38 : unités
        ldx tmp_hi_offset_u
        lda bold_digits, x
        ldy #38
        sta (ptr), y
        
        inc tmp_hi_offset_t
        inc tmp_hi_offset_u
        
        ldx tmp_y
        inx
        cpx #7
        bcc rhs_row_loop
        rts

; === Occlusion et Défilement Parallaxe du Paysage (Skyline) ===

calc_pipe_bounds:
        ; Calcule pipe0_byte_start / end et pipe1_byte_start / end
        ; Pipe 0
        lda pipe_x_hi+0
        bne cpb_p0_nz
        ldx pipe_x_lo+0
        lda div7, x
        sta pipe0_byte_start
        lda pipe_x_lo+0
        clc
        adc #15
        bcc cpb_p0_lo15
        lda div7_hi+0
        sta pipe0_byte_end
        jmp cpb_p1
cpb_p0_lo15:
        tax
        lda div7, x
        sta pipe0_byte_end
        jmp cpb_p1
cpb_p0_nz:
        cmp #1
        bne cpb_p0_neg
        lda pipe_x_lo+0
        cmp #24
        bcs cpb_p0_off
        tax
        lda div7_hi, x
        sta pipe0_byte_start
        lda #39
        sta pipe0_byte_end
        jmp cpb_p1
cpb_p0_neg:
        lda pipe_x_lo+0
        clc
        adc #15
        bmi cpb_p0_off
        tax
        lda #0
        sta pipe0_byte_start
        lda div7, x
        sta pipe0_byte_end
        jmp cpb_p1
cpb_p0_off:
        lda #$FF
        sta pipe0_byte_start
        sta pipe0_byte_end

cpb_p1:
        lda pipe_x_hi+1
        bne cpb_p1_nz
        ldx pipe_x_lo+1
        lda div7, x
        sta pipe1_byte_start
        lda pipe_x_lo+1
        clc
        adc #15
        bcc cpb_p1_lo15
        lda div7_hi+0
        sta pipe1_byte_end
        rts
cpb_p1_lo15:
        tax
        lda div7, x
        sta pipe1_byte_end
        rts
cpb_p1_nz:
        cmp #1
        bne cpb_p1_neg
        lda pipe_x_lo+1
        cmp #24
        bcs cpb_p1_off
        tax
        lda div7_hi, x
        sta pipe1_byte_start
        lda #39
        sta pipe1_byte_end
        rts
cpb_p1_neg:
        lda pipe_x_lo+1
        clc
        adc #15
        bmi cpb_p1_off
        tax
        lda #0
        sta pipe1_byte_start
        lda div7, x
        sta pipe1_byte_end
        rts
cpb_p1_off:
        lda #$FF
        sta pipe1_byte_start
        sta pipe1_byte_end
        rts



; Vérification d'occlusion du tuyau supérieur pour les nuages
; In: Y = colonne écran (0..39)
; Out: Carry SET si la tige supérieure couvre la ligne du nuage
is_pipe_cloud1:
        cpy pipe0_byte_start
        bcc ipc1_chk_p1
        cpy pipe0_byte_end
        bcc ipc1_p0_hit
        beq ipc1_p0_hit
        bcs ipc1_chk_p1
ipc1_p0_hit:
        lda pipe_gap_y+0
        cmp #29
        bcs ipc1_covered
ipc1_chk_p1:
        cpy pipe1_byte_start
        bcc ipc1_clear
        cpy pipe1_byte_end
        bcc ipc1_p1_hit
        beq ipc1_p1_hit
        bcs ipc1_clear
ipc1_p1_hit:
        lda pipe_gap_y+1
        cmp #29
        bcs ipc1_covered
ipc1_clear:
        clc
        rts
ipc1_covered:
        sec
        rts

is_pipe_cloud2:
        cpy pipe0_byte_start
        bcc ipc2_chk_p1
        cpy pipe0_byte_end
        bcc ipc2_p0_hit
        beq ipc2_p0_hit
        bcs ipc2_chk_p1
ipc2_p0_hit:
        lda pipe_gap_y+0
        cmp #49
        bcs ipc2_covered
ipc2_chk_p1:
        cpy pipe1_byte_start
        bcc ipc2_clear
        cpy pipe1_byte_end
        bcc ipc2_p1_hit
        beq ipc2_p1_hit
        bcs ipc2_clear
ipc2_p1_hit:
        lda pipe_gap_y+1
        cmp #49
        bcs ipc2_covered
ipc2_clear:
        clc
        rts
ipc2_covered:
        sec
        rts

; === Nuages Lents en Arrière-Plan ===

update_clouds:
        inc cloud1_timer
        lda cloud1_timer
        cmp #24
        bcc uc_chk_c2
        lda #0
        sta cloud1_timer
        jsr shift_cloud1_left
uc_chk_c2:
        inc cloud2_timer
        lda cloud2_timer
        cmp #36
        bcc uc_done
        lda #0
        sta cloud2_timer
        jsr shift_cloud2_left
uc_done:
        rts

draw_cloud1:
        ldx #0
dc1_row:
        stx tmp_y
        txa
        clc
        adc #28             ; Y = 28..34
        tay
        lda hires_lo, y
        sta ptr
        lda hires_hi, y
        sta ptr+1
        
        lda tmp_y
        asl
        clc
        adc tmp_y
        sta tmp_val
        
        ldx #0
dc1_col:
        stx tmp_c
        txa
        clc
        adc cloud1_x
        cmp #40
        bcc dc1_no_wrap
        sec
        sbc #40
dc1_no_wrap:
        tay
        jsr is_pipe_cloud1
        bcs dc1_skip_draw   ; Tige supérieure au premier plan : occlusion !
        
        ldx tmp_val
        lda cloud1_data, x
        sta (ptr), y
        
dc1_skip_draw:
        inc tmp_val
        ldx tmp_c
        inx
        cpx #3
        bcc dc1_col
        
        ldx tmp_y
        inx
        cpx #7
        bcc dc1_row
        rts

draw_cloud2:
        ldx #0
dc2_row:
        stx tmp_y
        txa
        clc
        adc #48             ; Y = 48..55
        tay
        lda hires_lo, y
        sta ptr
        lda hires_hi, y
        sta ptr+1
        
        lda tmp_y
        asl
        asl
        sta tmp_val
        
        ldx #0
dc2_col:
        stx tmp_c
        txa
        clc
        adc cloud2_x
        cmp #40
        bcc dc2_no_wrap
        sec
        sbc #40
dc2_no_wrap:
        tay
        jsr is_pipe_cloud2
        bcs dc2_skip_draw   ; Tige supérieure au premier plan : occlusion !
        
        ldx tmp_val
        lda cloud2_data, x
        sta (ptr), y
        
dc2_skip_draw:
        inc tmp_val
        ldx tmp_c
        inx
        cpx #4
        bcc dc2_col
        
        ldx tmp_y
        inx
        cpx #8
        bcc dc2_row
        rts

shift_cloud1_left:
        ; Effacer l'ancienne colonne de droite : (cloud1_x + 2) % 40
        lda cloud1_x
        clc
        adc #2
        cmp #40
        bcc sc1_e_nowrap
        sec
        sbc #40
sc1_e_nowrap:
        tay
        jsr is_pipe_cloud1
        bcs sc1_e_skip      ; Si sous la tige d'un tuyau : ne pas écraser
        
        ldx #28
sc1_e_loop:
        lda hires_lo, x
        sta ptr
        lda hires_hi, x
        sta ptr+1
        lda #0
        sta (ptr), y
        inx
        cpx #35
        bcc sc1_e_loop
sc1_e_skip:
        dec cloud1_x
        bpl sc1_x_ok
        lda #39
        sta cloud1_x
sc1_x_ok:
        jmp draw_cloud1

shift_cloud2_left:
        ; Effacer l'ancienne colonne de droite : (cloud2_x + 3) % 40
        lda cloud2_x
        clc
        adc #3
        cmp #40
        bcc sc2_e_nowrap
        sec
        sbc #40
sc2_e_nowrap:
        tay
        jsr is_pipe_cloud2
        bcs sc2_e_skip      ; Si sous la tige d'un tuyau : ne pas écraser
        
        ldx #48
sc2_e_loop:
        lda hires_lo, x
        sta ptr
        lda hires_hi, x
        sta ptr+1
        lda #0
        sta (ptr), y
        inx
        cpx #56
        bcc sc2_e_loop
sc2_e_skip:
        dec cloud2_x
        bpl sc2_x_ok
        lda #39
        sta cloud2_x
sc2_x_ok:
        jmp draw_cloud2

restore_cloud_column:
        ; Restaure les pixels de nuages sur la colonne tmp_byte_offset (lors du passage d'un tuyau)
        lda tmp_byte_offset
        sec
        sbc cloud1_x
        bpl rcc_c1_pos
        clc
        adc #40
rcc_c1_pos:
        cmp #3
        bcs rcc_chk_c2
        sta tmp_c
        ldx #0
rcc_c1_loop:
        stx tmp_y
        txa
        clc
        adc #28
        cmp tmp_gap
        bcs rcc_c1_skip_row ; Si dans l'ouverture (gap) : la ligne n'a pas été effacée !
        tay
        lda hires_lo, y
        sta ptr
        lda hires_hi, y
        sta ptr+1
        
        lda tmp_y
        asl
        clc
        adc tmp_y
        clc
        adc tmp_c
        tax
        lda cloud1_data, x
        and tmp_mask
        sta tmp_val
        
        ldy tmp_byte_offset
        lda (ptr), y
        and tmp_mask_clear
        ora tmp_val
        sta (ptr), y

rcc_c1_skip_row:
        ldx tmp_y
        inx
        cpx #7
        bcc rcc_c1_loop

rcc_chk_c2:
        lda tmp_byte_offset
        sec
        sbc cloud2_x
        bpl rcc_c2_pos
        clc
        adc #40
rcc_c2_pos:
        cmp #4
        bcs rcc_done
        sta tmp_c
        ldx #0
rcc_c2_loop:
        stx tmp_y
        txa
        clc
        adc #48
        cmp tmp_gap
        bcs rcc_c2_skip_row ; Si dans l'ouverture (gap) : la ligne n'a pas été effacée !
        tay
        lda hires_lo, y
        sta ptr
        lda hires_hi, y
        sta ptr+1
        
        lda tmp_y
        asl
        asl
        clc
        adc tmp_c
        tax
        lda cloud2_data, x
        and tmp_mask
        sta tmp_val
        
        ldy tmp_byte_offset
        lda (ptr), y
        and tmp_mask_clear
        ora tmp_val
        sta (ptr), y

rcc_c2_skip_row:
        ldx tmp_y
        inx
        cpx #8
        bcc rcc_c2_loop
rcc_done:
        rts

restore_clouds_bird:
        lda bird_y_old
        cmp #35
        bcs rcb_chk_c2
        lda bird_y_old
        clc
        adc #11
        cmp #28
        bcc rcb_chk_c2
        jsr draw_cloud1
rcb_chk_c2:
        lda bird_y_old
        cmp #56
        bcs rcb_done
        lda bird_y_old
        clc
        adc #11
        cmp #48
        bcc rcb_done
        jsr draw_cloud2
rcb_done:
        rts

; === Flappy Bird : Sprites Iconiques 17x12 & 3 Cadres d'Animation ===
; Position X=44..60 (Octets 6, 7, 8)
; Palette Groupe 1 (Bit 7 = 1) : Jaune/Orange, Blanc éclatant, Bec orange saillant, Pupille noire

bird_frame_glide:
    .byte $C0, $9F, $80 ; Row 0 : Sommet tête arrondi
    .byte $F0, $FF, $80 ; Row 1 : Front + haut oeil
    .byte $BC, $FE, $80 ; Row 2 : Aile médiane + haut oeil blanc
    .byte $FE, $FE, $80 ; Row 3 : Aile blanche + oeil blanc
    .byte $FE, $E6, $80 ; Row 4 : Aile blanche + PUPILLE NOIRE ($E6 = bits 3-4 à 0)
    .byte $FE, $FE, $BD ; Row 5 : Aile + bas oeil + lèvre supérieure
    .byte $BC, $FE, $FD ; Row 6 : Bas aile + ligne bouche + lèvre avancée
    .byte $F0, $FF, $FD ; Row 7 : Corps jaune + lèvre inférieure
    .byte $C0, $FF, $BD ; Row 8 : Ventre + bas lèvre
    .byte $C0, $FF, $80 ; Row 9 : Contour bas ventre
    .byte $80, $BF, $80 ; Row 10: Petites pattes
    .byte $80, $9E, $80 ; Row 11: Bout des pattes

bird_frame_flap:
    .byte $FC, $9F, $80 ; Row 0 : AILE EN HAUT (flapping)
    .byte $FC, $FF, $80 ; Row 1 : Aile relevée + oeil
    .byte $BC, $FE, $80 ; Row 2 : Aile relevée + oeil
    .byte $F0, $FE, $80 ; Row 3 : Corps + oeil blanc
    .byte $F0, $E6, $80 ; Row 4 : Corps + PUPILLE NOIRE
    .byte $F0, $FE, $BD ; Row 5 : Corps + bec supérieur
    .byte $F0, $FF, $FD ; Row 6 : Corps + lèvre avancée
    .byte $F0, $FF, $FD ; Row 7 : Corps + lèvre inférieure
    .byte $C0, $FF, $BD ; Row 8 : Ventre + bas lèvre
    .byte $C0, $FF, $80 ; Row 9 : Ventre
    .byte $80, $BF, $80 ; Row 10: Pattes
    .byte $80, $9E, $80 ; Row 11: Bout des pattes

bird_frame_dive:
    .byte $C0, $9F, $80 ; Row 0 : Tête
    .byte $F0, $FF, $80 ; Row 1 : Tête + oeil
    .byte $F0, $FF, $80 ; Row 2 : Tête + oeil
    .byte $F0, $FE, $80 ; Row 3 : Corps + oeil
    .byte $F0, $E6, $80 ; Row 4 : Corps + PUPILLE NOIRE
    .byte $F0, $FE, $BD ; Row 5 : Corps + bec
    .byte $BC, $FE, $FD ; Row 6 : AILE VERS LE BAS (chute/dive)
    .byte $FE, $FE, $FD ; Row 7 : Aile pointée vers le bas
    .byte $FE, $FE, $BD ; Row 8 : Aile plongeante + lèvre
    .byte $BC, $FE, $80 ; Row 9 : Bout de l'aile vers le bas
    .byte $80, $BF, $80 ; Row 10: Pattes
    .byte $80, $9E, $80 ; Row 11: Bout des pattes

erase_bird:
        ; Efface 12 lignes aux octets 6, 7, 8
        ldx #0
eb_row_loop:
        txa
        clc
        adc bird_y_old
        tay
        
        lda hires_lo, y
        sta ptr
        lda hires_hi, y
        sta ptr+1
        
        lda #0
        ldy #6
        sta (ptr), y
        iny
        sta (ptr), y
        iny
        sta (ptr), y
        
        inx
        cpx #12
        bcc eb_row_loop
        jsr restore_clouds_bird
        rts

draw_bird:
        ; Sélectionne le cadre d'animation selon la vélocité physique
        lda bird_vel
        bmi db_select_flap  ; Vitesse négative : impulsion vers le haut
        cmp #4
        bcs db_select_dive  ; Chute rapide : plongeon vers le bas
        
        ; Vol stationnaire / glissé médian
        lda #<bird_frame_glide
        sta ptr2
        lda #>bird_frame_glide
        sta ptr2+1
        jmp db_draw

db_select_flap:
        lda #<bird_frame_flap
        sta ptr2
        lda #>bird_frame_flap
        sta ptr2+1
        jmp db_draw

db_select_dive:
        lda #<bird_frame_dive
        sta ptr2
        lda #>bird_frame_dive
        sta ptr2+1

db_draw:
        ldx #0
db_row_loop:
        stx tmp_y
        txa
        clc
        adc bird_y
        tax
        
        lda hires_lo, x
        sta ptr
        lda hires_hi, x
        sta ptr+1
        
        ; Décalage dans la table = tmp_y * 3
        lda tmp_y
        asl
        clc
        adc tmp_y
        tay
        
        lda (ptr2), y
        sta sprite_byte0
        iny
        lda (ptr2), y
        sta sprite_byte1
        iny
        lda (ptr2), y       ; Octet 8
        
        ldy #8
        sta (ptr), y
        dey
        lda sprite_byte1
        sta (ptr), y
        dey
        lda sprite_byte0
        sta (ptr), y
        
        ldx tmp_y
        inx
        cpx #12
        bcc db_row_loop
        rts

check_collisions:
        ldx #0
col_loop:
        stx tmp_pipe_idx
        
        lda pipe_x_hi, x
        bmi col_next
        bne col_next
        
        ; Boîte de collision corps oiseau : X=46..58, Y=bird_y+1..bird_y+10
        lda pipe_x_lo, x
        cmp #59
        bcs col_next
        clc
        adc #15
        cmp #46
        bcc col_next
        
        lda bird_y
        clc
        adc #1
        cmp pipe_gap_y, x
        bcc trigger_game_over_jmp
        lda bird_y
        clc
        adc #10
        sta tmp_bird_bottom
        lda pipe_gap_y, x
        clc
        adc #45
        cmp tmp_bird_bottom
        bcc trigger_game_over_jmp
col_next:
        ldx tmp_pipe_idx
        inx
        cpx #NUM_PIPES
        bne col_loop
        rts

trigger_game_over_jmp:
        pla
        pla
        jmp game_over

check_score:
        ldx #0
score_loop:
        stx tmp_pipe_idx
        lda pipe_x_lo, x
        clc
        adc #15
        sta tmp_score_x
        lda pipe_x_hi, x
        adc #0
        bne score_next
        
        lda tmp_score_x
        cmp #46
        beq score_inc
        cmp #45
        bne score_next
score_inc:
        jsr erase_score
        inc score
        lda score
        cmp high_score
        bcc score_no_new_hi
        sta high_score
        jsr render_high_score
score_no_new_hi:
        jsr snd_score
        jsr render_score
score_next:
        ldx tmp_pipe_idx
        inx
        cpx #NUM_PIPES
        bne score_loop
        rts

; === Score Centré en Haut (Octets 17 à 22) avec Masquage des Zéros ===

apply_score_column:
        ldy tmp_byte_offset
        cpy #17
        bcc asc_end
        cpy #23
        bcs asc_end
        
        sty asc_screen_y
        
        tya
        sec
        sbc #17
        lsr                 ; 0: octets 17-18 (centaines), 1: 19-20 (dizaines), 2: 21-22 (unités)
        php
        tay
        
        ; Suppression des zéros non affichés
        cpy #0
        bne asc_check_t
        lda digit_h
        beq asc_skip_pop
        jmp asc_ok

asc_check_t:
        cpy #1
        bne asc_ok
        lda digit_t
        bne asc_ok
        lda digit_h
        beq asc_skip_pop

asc_ok:
        lda digit_h, y
        tay
        
        lda font_offset_lo, y
        sta ptr2
        lda font_offset_hi, y
        sta ptr2+1
        
        plp
        lda #0
        rol
        sta tmp_font_offset
        
        lda #4
        sta tmp_y

asc_loop:
        ldx tmp_y
        lda hires_lo, x
        clc
        adc asc_screen_y
        sta ptr
        lda hires_hi, x
        adc #0
        sta ptr+1
        
        ldy tmp_font_offset
        lda (ptr2), y
        and #$7F
        ldy #0
        eor (ptr), y
        sta (ptr), y
        
        lda tmp_font_offset
        clc
        adc #2
        sta tmp_font_offset
        
        inc tmp_y
        lda tmp_y
        cmp #24
        bcc asc_loop
asc_end:
        rts

asc_skip_pop:
        plp
        rts

erase_score:
        jmp rs_draw_start

render_score:
        lda score
        ldx #0
        stx digit_h
        stx digit_t
        stx digit_o
rs_h_loop:
        cmp #100
        bcc rs_t_loop
        sbc #100
        inc digit_h
        bne rs_h_loop
rs_t_loop:
        cmp #10
        bcc rs_o_loop
        sbc #10
        inc digit_t
        bne rs_t_loop
rs_o_loop:
        sta digit_o

rs_draw_start:
        lda digit_h
        bne rs_draw_h
        jmp rs_do_t
rs_draw_h:
        ldx #17
        jsr draw_digit
rs_do_t:
        lda digit_t
        bne rs_draw_t
        lda digit_h
        bne rs_draw_t
        jmp rs_do_o
rs_draw_t:
        ldx #19
        jsr draw_digit
rs_do_o:
        lda digit_o
        ldx #21
        jsr draw_digit
        rts

draw_digit:
        stx tmp_byte_offset
        tax
        lda font_offset_lo, x
        sta ptr2
        lda font_offset_hi, x
        sta ptr2+1

        lda #4
        sta tmp_y
        ldy #0
dd_loop:
        ldx tmp_y
        lda hires_lo, x
        clc
        adc tmp_byte_offset
        sta ptr
        lda hires_hi, x
        adc #0
        sta ptr+1
        
        lda (ptr2), y
        and #$7F
        tax
        iny
        lda (ptr2), y
        and #$7F
        iny
        sty tmp_font_y
        
        ldy #1
        eor (ptr), y
        sta (ptr), y
        dey
        txa
        eor (ptr), y
        sta (ptr), y
        
        ldy tmp_font_y

        inc tmp_y
        lda tmp_y
        cmp #24
        bne dd_loop
        rts

; === Routines Système & Audio ===

check_input:
        lda KBD
        bpl check_input_done
        bit KBDSTRB
        lda #-8             ; FLAP
        sta bird_vel
        jsr snd_flap
check_input_done:
        rts

get_random:
        lda random_seed
        asl
        bcc rand_no_eor
        eor #$1D
rand_no_eor:
        clc
        adc frame_counter
        adc bird_y
        sta random_seed
        rts

reset_game:
        lda #$20
        sta HPAG
        jsr HGR
        bit FULLGR
        
        lda #22
        sta cloud1_x
        lda #7
        sta cloud2_x
        lda #0
        sta cloud1_timer
        sta cloud2_timer
        
        lda #$FF
        sta pipe0_byte_start
        sta pipe0_byte_end
        sta pipe1_byte_start
        sta pipe1_byte_end
        
        jsr init_ground
        jsr detect_vbl
        
        lda #90
        sta bird_y
        sta bird_y_old
        lda #0
        sta bird_vel
        sta score
        sta frame_counter
        
        ; Initialiser tuyaux
        lda #$C8            ; 200
        sta pipe_x_lo+0
        sta pipe_x_old_lo+0
        lda #0
        sta pipe_x_hi+0
        sta pipe_x_old_hi+0
        lda #70
        sta pipe_gap_y+0
        
        lda #$54            ; 340
        sta pipe_x_lo+1
        sta pipe_x_old_lo+1
        lda #1
        sta pipe_x_hi+1
        sta pipe_x_old_hi+1
        lda #90
        sta pipe_gap_y+1
        
        ldx #0
        jsr draw_full_pipe
        
        jsr calc_pipe_bounds
        
        jsr render_score
        jsr draw_bird

        ; Écran d'attente "Prêt" avec animation d'ailes sur place
        bit KBDSTRB
ready_loop:
        inc frame_counter
        inc random_seed
        
        ; Battement d'ailes stationnaire
        lda frame_counter
        and #$0F
        bne ready_no_flap
        lda bird_vel
        eor #$80
        sta bird_vel
        jsr draw_bird
ready_no_flap:
        
        jsr wait_vbl
        
        lda KBD
        bpl ready_loop
        bit KBDSTRB
        
        ; Premier battement au lancement !
        lda #-8
        sta bird_vel
        jsr snd_flap
        
        jmp main_loop

game_over:
        jsr snd_crash
        
        ; Pause visuelle
        ldy #60
go_delay_outer:
        ldx #0
go_delay_inner:
        dex
        bne go_delay_inner
        dey
        bne go_delay_outer
        
        bit KBDSTRB
go_wait_key:
        lda KBD
        bpl go_wait_key
        bit KBDSTRB
        
        jmp reset_game

; Pépiement flap
snd_flap:
        ldy #10
sf_loop:
        lda SPEAKER
        ldx #12
sf_d:   dex
        bne sf_d
        dey
        bne sf_loop
        rts

; Point marqué (carillon 2 tons)
snd_score:
        ldy #20
ss_h1:  lda SPEAKER
        ldx #22
ss_d1:  dex
        bne ss_d1
        dey
        bne ss_h1
        ldy #30
ss_h2:  lda SPEAKER
        ldx #14
ss_d2:  dex
        bne ss_d2
        dey
        bne ss_h2
        rts

; Crash collision (bruit sourd)
snd_crash:
        lda #30
        sta tmp_val
sc_loop:
        lda SPEAKER
        ldx tmp_val
sc_delay:
        dex
        bne sc_delay
        inc tmp_val
        inc tmp_val
        lda tmp_val
        cmp #120
        bcc sc_loop
        rts

; Détection automatique du registre VBL ($C019)
detect_vbl:
        lda #0
        sta vbl_available
        ldx #15
        ldy #0
        lda $C019
        and #$80
        sta tmp_val
det_poll:
        lda $C019
        and #$80
        cmp tmp_val
        bne det_vbl_ok
        dey
        bne det_poll
        dex
        bne det_poll
        rts                 ; Pas de VBL matériel -> Apple II Plus
det_vbl_ok:
        lda #1
        sta vbl_available
        rts

; Régulateur de cadence constante à 60 FPS (VBL matériel ou délai compensé)
wait_vbl:
        lda vbl_available
        beq fallback_governor
        
        ; 1. S'assurer qu'on est dans l'affichage actif (Bit 7 = 1)
        ldx #6
wv_wait_active_outer:
        ldy #0
wv_wait_active:
        bit $C019
        bmi wv_in_active    ; Bit 7 = 1 : affichage actif !
        dey
        bne wv_wait_active
        dex
        bne wv_wait_active_outer
        jmp fallback_governor

wv_in_active:
        ; 2. Attendre le début exact du VBL (Bit 7 passe à 0)
        ldx #8
wv_wait_vbl_outer:
        ldy #0
wv_wait_vbl:
        bit $C019
        bpl wv_vbl_hit      ; Bit 7 = 0 : VBL atteint !
        dey
        bne wv_wait_vbl
        dex
        bne wv_wait_vbl_outer
        jmp fallback_governor

wv_vbl_hit:
        rts

fallback_governor:
        ; Compensation selon le nombre de tuyaux dessinés à l'écran
        lda pipes_on_screen
        cmp #2
        bcs fg_base         ; Si 2 tuyaux à l'écran : pas de compensation
        cmp #1
        beq fg_comp_one     ; Si 1 tuyau : compenser 1 tuyau (~2500 cycles)
        ; Si 0 tuyau : compenser 2 tuyaux (~5000 cycles)
        ldx #10
        jsr delay_x_500
        jmp fg_base
fg_comp_one:
        ldx #5
        jsr delay_x_500
fg_base:
        ; Délai de base pour stabiliser la cadence à 60 FPS
        ldx #8
        jsr delay_x_500
        rts

delay_x_500:
dx_l1:  ldy #100
dx_l2:  dey
        bne dx_l2
        dex
        bne dx_l1
        rts

; === Variables en RAM ===
vbl_available:      .byte 0
pipes_on_screen:    .byte 0
pipe_drawn_flag:    .byte 0

bird_y:         .byte 0
bird_y_old:     .byte 0
bird_vel:       .byte 0

pipe_x_lo:      .fill NUM_PIPES, 0
pipe_x_hi:      .fill NUM_PIPES, 0
pipe_x_old_lo:  .fill NUM_PIPES, 0
pipe_x_old_hi:  .fill NUM_PIPES, 0
pipe_gap_y:     .fill NUM_PIPES, 0

score:          .byte 0
frame_counter:  .byte 0
random_seed:    .byte $42

logic_x:        .byte 0
logic_x_hi:     .byte 0
tmp_x_lo:       .byte 0
tmp_x_hi:       .byte 0
tmp_y1:         .byte 0
tmp_y2:         .byte 0
tmp_w:          .byte 0
tmp_mask:       .byte 0
tmp_mask_clear: .byte 0
tmp_byte_offset:.byte 0
tmp_pipe_fill:  .byte 0
tmp_pipe_fill_hi:.byte 0
tmp_bird_bottom:.byte 0
tmp_score_x:    .byte 0
tmp_pipe_idx:   .byte 0
tmp_gap:        .byte 0
tmp_val:        .byte 0
tmp_pipe_rel_x: .byte 0

digit_h:        .byte 0
digit_t:        .byte 0
digit_o:        .byte 0
tmp_font_y:     .byte 0
tmp_y:          .byte 0
asc_screen_y:   .byte 0
tmp_font_offset:.byte 0
sprite_byte0:   .byte 0
sprite_byte1:   .byte 0
tmp_bit_val:    .byte 0

; Variables High-Score
high_score:         .byte 0
hi_digit_t:         .byte 0
hi_digit_u:         .byte 0
tmp_hi_offset_t:    .byte 0
tmp_hi_offset_u:    .byte 0

; Variables Nuages
cloud1_x:           .byte 22
cloud2_x:           .byte 7
cloud1_timer:       .byte 0
cloud2_timer:       .byte 0
tmp_c:              .byte 0

; Bornes d'occlusion des tuyaux
pipe0_byte_start:   .byte $FF
pipe0_byte_end:     .byte $FF
pipe1_byte_start:   .byte $FF
pipe1_byte_end:     .byte $FF

; === Table Décor Urbain Statique & Collines (20 lignes x 8 octets = 160 octets) ===
skyline_data:
    .byte $10, $00, $00, $00, $00, $00, $00, $00 ; Row  0 (Y=156) Antenne
    .byte $10, $00, $00, $00, $00, $00, $00, $00 ; Row  1 (Y=157)
    .byte $7C, $00, $00, $00, $00, $00, $00, $00 ; Row  2 (Y=158) Toit tour
    .byte $44, $00, $00, $00, $00, $00, $00, $00 ; Row  3 (Y=159)
    .byte $54, $60, $07, $00, $00, $00, $00, $00 ; Row  4 (Y=160) Fenêtres + 2e toit
    .byte $44, $20, $04, $00, $00, $00, $00, $00 ; Row  5 (Y=161)
    .byte $54, $20, $05, $00, $7C, $01, $00, $00 ; Row  6 (Y=162) Colline 1
    .byte $44, $20, $04, $00, $7F, $07, $00, $00 ; Row  7 (Y=163)
    .byte $54, $20, $05, $40, $7F, $0F, $7C, $00 ; Row  8 (Y=164) Colline 2
    .byte $44, $20, $64, $67, $7F, $1F, $7E, $01 ; Row  9 (Y=165)
    .byte $54, $20, $25, $64, $7F, $1F, $7F, $03 ; Row 10 (Y=166)
    .byte $44, $20, $24, $65, $7F, $1F, $7F, $03 ; Row 11 (Y=167)
    .byte $54, $20, $25, $64, $7F, $5F, $7F, $07 ; Row 12 (Y=168)
    .byte $44, $20, $24, $65, $7F, $5F, $7F, $07 ; Row 13 (Y=169)
    .byte $7C, $20, $24, $64, $7F, $5F, $7F, $07 ; Row 14 (Y=170)
    .byte $28, $60, $27, $45, $2A, $55, $2A, $05 ; Row 15 (Y=171) Collines vertes
    .byte $28, $40, $62, $47, $2A, $55, $2A, $05 ; Row 16 (Y=172)
    .byte $28, $40, $22, $45, $2A, $55, $2A, $05 ; Row 17 (Y=173)
    .byte $28, $40, $22, $45, $2A, $55, $2A, $05 ; Row 18 (Y=174)
    .byte $2A, $55, $2A, $55, $2A, $55, $2A, $05 ; Row 19 (Y=175) Base verte

font_offset_lo:
    .byte <(font_digits+0), <(font_digits+40), <(font_digits+80), <(font_digits+120), <(font_digits+160)
    .byte <(font_digits+200), <(font_digits+240), <(font_digits+280), <(font_digits+320), <(font_digits+360)
font_offset_hi:
    .byte >(font_digits+0), >(font_digits+40), >(font_digits+80), >(font_digits+120), >(font_digits+160)
    .byte >(font_digits+200), >(font_digits+240), >(font_digits+280), >(font_digits+320), >(font_digits+360)

font_digits:
; Digit 0
  .byte $FC, $87
  .byte $FE, $8F
  .byte $87, $9C
  .byte $87, $9C
  .byte $87, $9C
  .byte $87, $9C
  .byte $87, $9C
  .byte $87, $9C
  .byte $87, $9C
  .byte $87, $9C
  .byte $87, $9C
  .byte $87, $9C
  .byte $87, $9C
  .byte $87, $9C
  .byte $87, $9C
  .byte $87, $9C
  .byte $87, $9C
  .byte $87, $9C
  .byte $FE, $8F
  .byte $FC, $87
; Digit 1
  .byte $C0, $87
  .byte $F0, $87
  .byte $C0, $87
  .byte $C0, $87
  .byte $C0, $87
  .byte $C0, $87
  .byte $C0, $87
  .byte $C0, $87
  .byte $C0, $87
  .byte $C0, $87
  .byte $C0, $87
  .byte $C0, $87
  .byte $C0, $87
  .byte $C0, $87
  .byte $C0, $87
  .byte $C0, $87
  .byte $C0, $87
  .byte $C0, $87
  .byte $F0, $9F
  .byte $F0, $9F
; Digit 2
  .byte $FC, $87
  .byte $FE, $8F
  .byte $87, $9C
  .byte $87, $9C
  .byte $80, $9C
  .byte $80, $9C
  .byte $80, $9C
  .byte $80, $9C
  .byte $80, $8E
  .byte $80, $87
  .byte $C0, $83
  .byte $E0, $81
  .byte $F0, $80
  .byte $B8, $80
  .byte $9C, $80
  .byte $8E, $80
  .byte $87, $80
  .byte $87, $80
  .byte $FF, $9F
  .byte $FF, $9F
; Digit 3
  .byte $FC, $87
  .byte $FE, $8F
  .byte $87, $9C
  .byte $87, $9C
  .byte $80, $9C
  .byte $80, $9C
  .byte $80, $9C
  .byte $E0, $8F
  .byte $E0, $8F
  .byte $80, $9C
  .byte $80, $9C
  .byte $80, $9C
  .byte $80, $9C
  .byte $80, $9C
  .byte $80, $9C
  .byte $80, $9C
  .byte $87, $9C
  .byte $87, $9C
  .byte $FE, $8F
  .byte $FC, $87
; Digit 4
  .byte $80, $8F
  .byte $C0, $8F
  .byte $E0, $8E
  .byte $B0, $8E
  .byte $98, $8E
  .byte $8C, $8E
  .byte $86, $8E
  .byte $83, $8E
  .byte $83, $8E
  .byte $FF, $9F
  .byte $FF, $9F
  .byte $80, $8E
  .byte $80, $8E
  .byte $80, $8E
  .byte $80, $8E
  .byte $80, $8E
  .byte $80, $8E
  .byte $80, $8E
  .byte $80, $8E
  .byte $80, $8E
; Digit 5
  .byte $FF, $9F
  .byte $FF, $9F
  .byte $87, $80
  .byte $87, $80
  .byte $87, $80
  .byte $87, $80
  .byte $FF, $83
  .byte $FF, $87
  .byte $80, $8E
  .byte $80, $9C
  .byte $80, $9C
  .byte $80, $9C
  .byte $80, $9C
  .byte $80, $9C
  .byte $80, $9C
  .byte $80, $9C
  .byte $87, $9C
  .byte $87, $9C
  .byte $FE, $87
  .byte $FC, $83
; Digit 6
  .byte $F8, $83
  .byte $FC, $87
  .byte $8E, $8E
  .byte $87, $80
  .byte $87, $80
  .byte $87, $80
  .byte $FF, $83
  .byte $FF, $87
  .byte $87, $8E
  .byte $87, $9C
  .byte $87, $9C
  .byte $87, $9C
  .byte $87, $9C
  .byte $87, $9C
  .byte $87, $9C
  .byte $87, $9C
  .byte $87, $9C
  .byte $87, $9C
  .byte $FE, $8F
  .byte $FC, $87
; Digit 7
  .byte $FF, $9F
  .byte $FF, $9F
  .byte $87, $9C
  .byte $80, $9C
  .byte $80, $9C
  .byte $80, $8E
  .byte $80, $8E
  .byte $80, $87
  .byte $80, $87
  .byte $C0, $83
  .byte $C0, $83
  .byte $E0, $81
  .byte $E0, $81
  .byte $F0, $80
  .byte $F0, $80
  .byte $B8, $80
  .byte $B8, $80
  .byte $B8, $80
  .byte $B8, $80
  .byte $B8, $80
; Digit 8
  .byte $FC, $87
  .byte $FE, $8F
  .byte $87, $9C
  .byte $87, $9C
  .byte $87, $9C
  .byte $87, $9C
  .byte $87, $9C
  .byte $FE, $8F
  .byte $FC, $87
  .byte $FE, $8F
  .byte $87, $9C
  .byte $87, $9C
  .byte $87, $9C
  .byte $87, $9C
  .byte $87, $9C
  .byte $87, $9C
  .byte $87, $9C
  .byte $87, $9C
  .byte $FE, $8F
  .byte $FC, $87
; Digit 9
  .byte $FC, $87
  .byte $FE, $8F
  .byte $87, $9C
  .byte $87, $9C
  .byte $87, $9C
  .byte $87, $9C
  .byte $87, $9C
  .byte $87, $9C
  .byte $87, $9C
  .byte $87, $8E
  .byte $FE, $8F
  .byte $F8, $9F
  .byte $80, $9C
  .byte $80, $9C
  .byte $80, $9C
  .byte $80, $9C
  .byte $80, $9C
  .byte $8E, $8E
  .byte $FC, $87
  .byte $F8, $83

; === Données Police Grasse High-Score (Lignes 183..189) ===

bold_font_h:
    .byte $9B, $9B, $9B, $9F, $9B, $9B, $9B
bold_font_i:
    .byte $9F, $8C, $8C, $8C, $8C, $8C, $9F
bold_font_colon:
    .byte $80, $8C, $8C, $80, $8C, $8C, $80

bold_digits:
    ; 0
    .byte $8E, $9B, $9B, $9B, $9B, $9B, $8E
    ; 1
    .byte $8C, $8E, $8C, $8C, $8C, $8C, $9F
    ; 2
    .byte $8F, $98, $98, $9E, $83, $83, $9F
    ; 3
    .byte $8F, $98, $98, $9E, $98, $98, $8F
    ; 4
    .byte $9B, $9B, $9B, $9F, $98, $98, $98
    ; 5
    .byte $9F, $83, $8F, $98, $98, $98, $8F
    ; 6
    .byte $8E, $83, $8F, $9B, $9B, $9B, $8E
    ; 7
    .byte $9F, $98, $8C, $8C, $86, $86, $86
    ; 8
    .byte $8E, $9B, $9B, $8E, $9B, $9B, $8E
    ; 9
    .byte $8E, $9B, $9B, $9E, $98, $98, $8E

; === Données Graphiques des Nuages ===

cloud1_data:
    .byte $00, $3C, $00
    .byte $60, $7F, $03
    .byte $78, $7F, $0F
    .byte $7C, $7F, $1F
    .byte $7E, $7F, $3F
    .byte $7E, $7F, $3F
    .byte $70, $7F, $07

cloud2_data:
    .byte $00, $38, $1C, $00
    .byte $60, $7F, $3F, $03
    .byte $78, $7F, $7F, $0F
    .byte $7C, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $3F
    .byte $7E, $7F, $7F, $3F
    .byte $7E, $7F, $7F, $3F
    .byte $70, $7F, $7F, $07

