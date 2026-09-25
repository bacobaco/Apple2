; ===================================================================
; BACH EN DUO : SYNTHESE SONORE 2 VOIX POLYPHONIQUE POUR APPLE II
; Moteur officiel Electric Duet (Paul Lutus, Arachnoid.com 1981)
;
; Synthese Time-Domain Multiplexing (TDM) / PWM 12.94 kHz sur $C030
;
; -------------------------------------------------------------------
; EXPLICATION DU PROBLEME INITIAL (POURQUOI LE SON ETAIT DU BRUIT) :
; -------------------------------------------------------------------
; Sur l'Apple II, le haut-parleur ($C030) est commande par une simple
; bascule 1-bit (flip-flop). Chaque acces inverse l'etat du HP.
; Si l'on tente une synthese numerique naive en inversant la bascule a
; chaque debordement d'accumulateur de la Voix 1 et de la Voix 2,
; l'etat resultant est un OU EXCLUSIF (XOR) logique :
;     S(t) = S1(t) XOR S2(t)
; Le XOR de deux signaux carres correspond a une modulation en anneau
; (ring modulation / multiplication analogique). Il engendre des
; frequences de battement f1 + f2, f1 - f2, 3f1 - f2, etc., qui
; detruisent completement les fondamentales des notes. Des que la
; deuxieme voix entre, toute harmonie disparait sous un bruit metallique.
;
; -------------------------------------------------------------------
; LA SOLUTION DE PAUL LUTUS (ELECTRIC DUET, 1981) :
; -------------------------------------------------------------------
; Paul Lutus a resolu ce defi avec une elegance mathematique :
; 1. La boucle d'emission tourne a temps rigoureusement constant :
;    exactement 79 cycles 6502 par tour, soit 12 937 Hz (~13 kHz).
; 2. Les deux voix sont multiplexees dans le temps (TDM) :
;    - Si les deux voix sont a 0 : HP = 0 (0% duty cycle, niveau 0.0V)
;    - Si les deux voix sont a 1 : HP = 1 (100% duty cycle, niveau 1.0V)
;    - Si une seule voix est a 1 : HP commute a chaque demi-boucle
;      (50% PWM a 12.9 kHz, niveau analogique moyen 0.5V).
; 3. Le haut-parleur physique ne peut pas osciller a 13 kHz a cause de
;    l'inertie mecanique de sa membrane. Il agit comme un filtre
;    passe-bas acoustique et integre la moyenne du signal PWM :
;        V_hp(t) = (V1(t) + V2(t)) / 2
;    C'est une SOMMATION LINEAIRE PURE !
;    Les produits d'intermodulation sont totalement elimines.
;
; Oeuvres interpretees :
;   [1] J.S. Bach - Fuga II en Do mineur (BWV 847) - Clavecin bien tempéré
;   [2] The Beatles - Hey Jude (Paul McCartney, 1968)
;   [3] The Beatles - Let It Be (Paul McCartney, 1970)
;   [4] The Beatles - I Want You (She's So Heavy) (John Lennon, 1969)
;
; Assembleur : 64tass (compatible DOS 3.3 BRUN en $4000)
; ===================================================================

    * = $4000

; --- Constantes Materiel Apple II ---
SPEAKER   = $C030       ; Toggle bascule haut-parleur (1-bit click)
KEYBD     = $C000       ; Registre clavier (Bit 7 = 1 si touche pressee)
KBDSTRB   = $C010       ; Remise a zero du strobe clavier
TEXTMODE  = $C051       ; Bascule affichage texte
PAGE1     = $C054       ; Affiche Page 1 texte
NOMIXED   = $C052       ; Plein ecran texte (24 lignes)

; --- Routines ROM Apple II ---
HOME      = $FC58       ; Efface l'ecran texte et place curseur en (0,0)
COUT      = $FDED       ; Affiche caractere (Acc) a la position curseur
CROUT     = $FD8E       ; Retour chariot ecran

; --- Variables en Page Zero pour Electric Duet ---
; $06 : Periode Voix 1
; $07 : Periode Voix 2
; $08 : Compteur de duree de note (externe)
; $09 : Duty cycle Voix 1 (par defaut 1 = 50%)
; $1D : Duty cycle Voix 2 (par defaut 1 = 50%)
; $1E : Pointeur partition Low
; $1F : Pointeur partition High
; $4E : Etat bit Voix 1 durant la boucle
; $4F : Compteur de duree boucle interne (256 boucles par unite)

; Variables pour l'interface
PTR_TXT_L = $1A
PTR_TXT_H = $1B

; ===================================================================
; POINT D'ENTREE PRINCIPAL
; ===================================================================
START:
    STA TEXTMODE
    STA PAGE1
    STA NOMIXED

SHOW_MENU:
    JSR HOME

    LDA #<MENU_TEXT
    LDY #>MENU_TEXT
    JSR PRINT_STRING

WAIT_INPUT:
    LDA KEYBD
    BPL WAIT_INPUT
    STA KBDSTRB         ; Acquitte la touche
    AND #$7F            ; Ignore bit 7

    CMP #'1'
    BEQ PLAY_PIECE_1
    CMP #'2'
    BEQ PLAY_PIECE_2
    CMP #'3'
    BEQ PLAY_PIECE_3
    CMP #'4'
    BEQ PLAY_PIECE_4
    CMP #'5'
    BEQ PLAY_PIECE_5
    CMP #'Q'
    BEQ EXIT_TO_DOS
    CMP #'q'
    BEQ EXIT_TO_DOS
    CMP #$1B            ; ESC
    BEQ EXIT_TO_DOS

    BNE WAIT_INPUT

EXIT_TO_DOS:
    JSR HOME
    RTS                 ; Retour propre a Applesoft / DOS 3.3

; ===================================================================
; LECTURE PIECE 1 : BWV 847 (FUGA II EN DO MINEUR)
; ===================================================================
PLAY_PIECE_1:
    JSR HOME
    LDA #<PLAY_BWV847_TEXT
    LDY #>PLAY_BWV847_TEXT
    JSR PRINT_STRING

    LDA #<BWV847_SCORE
    STA $1E
    LDA #>BWV847_SCORE
    STA $1F

    JSR LUTUS_PLAYER

    STA KBDSTRB         ; Acquitte toute touche pressee pour arreter
    JMP SHOW_MENU

; ===================================================================
; LECTURE PIECE 2 : TOMASO ALBINONI - ADAGIO EN SOL MINEUR
; ===================================================================
PLAY_PIECE_2:
    JSR HOME
    LDA #<PLAY_ALBINONI_TEXT
    LDY #>PLAY_ALBINONI_TEXT
    JSR PRINT_STRING

    LDA #<ALBINONI_SCORE
    STA $1E
    LDA #>ALBINONI_SCORE
    STA $1F

    JSR LUTUS_PLAYER

    STA KBDSTRB         ; Acquitte toute touche pressee pour arreter
    JMP SHOW_MENU

; ===================================================================
; LECTURE PIECE 3 : THE BEATLES - HEY JUDE (1968)
; ===================================================================
PLAY_PIECE_3:
    JSR HOME
    LDA #<PLAY_HEYJUDE_TEXT
    LDY #>PLAY_HEYJUDE_TEXT
    JSR PRINT_STRING

    LDA #<HEYJUDE_SCORE
    STA $1E
    LDA #>HEYJUDE_SCORE
    STA $1F

    JSR LUTUS_PLAYER

    STA KBDSTRB         ; Acquitte toute touche pressee pour arreter
    JMP SHOW_MENU

; ===================================================================
; LECTURE PIECE 4 : THE BEATLES - LET IT BE (1970)
; ===================================================================
PLAY_PIECE_4:
    JSR HOME
    LDA #<PLAY_LETITBE_TEXT
    LDY #>PLAY_LETITBE_TEXT
    JSR PRINT_STRING

    LDA #<LETITBE_SCORE
    STA $1E
    LDA #>LETITBE_SCORE
    STA $1F

    JSR LUTUS_PLAYER

    STA KBDSTRB         ; Acquitte toute touche pressee pour arreter
    JMP SHOW_MENU

; ===================================================================
; LECTURE PIECE 5 : THE BEATLES - I WANT YOU (SHE'S SO HEAVY) (1969)
; ===================================================================
PLAY_PIECE_5:
    JSR HOME
    LDA #<PLAY_IWANTYOU_TEXT
    LDY #>PLAY_IWANTYOU_TEXT
    JSR PRINT_STRING

    LDA #<IWANTYOU_SCORE
    STA $1E
    LDA #>IWANTYOU_SCORE
    STA $1F

    JSR LUTUS_PLAYER

    STA KBDSTRB         ; Acquitte toute touche pressee pour arreter
    JMP SHOW_MENU

; ===================================================================
; ROUTINE D'AFFICHAGE DE CHAINE NULL-TERMINATED
; In : A = Adresse basse, Y = Adresse haute
; ===================================================================
PRINT_STRING:
    STA PTR_TXT_L
    STY PTR_TXT_H
    LDY #0
_pstr_loop:
    LDA (PTR_TXT_L),Y
    BEQ _pstr_done
    ORA #$80
    JSR COUT
    INY
    BNE _pstr_loop
    INC PTR_TXT_H
    BNE _pstr_loop
_pstr_done:
    RTS

; ===================================================================
; MOTEUR OFFICIEL "ELECTRIC DUET" DE PAUL LUTUS (1981)
; Synthese polyphonique 2 voix en boucle rigoureusement calibree
; a 79 cycles par iteration (frequence porteuse = 12 937 Hz).
;
; Format des donnees :
;   Octet 0 : Duree en unites de ~20 ms (256 * 79 cycles = 20224 cycles)
;   Octet 1 : Periode Voix 1 (P = round(12600 / freq), 0 = silence)
;   Octet 2 : Periode Voix 2 (P = round(12600 / freq), 0 = silence)
;   Fin de partition : .byte $00, $00, $00
; ===================================================================
LUTUS_PLAYER:
    LDA #$01
    STA $09             ; Rapport cyclique par defaut Voix 1 (50%)
    STA $1D             ; Rapport cyclique par defaut Voix 2 (50%)
    PHA
    PHA
    PHA
    BNE PLAY_NEXT_EVENT

FETCH_DUTY_EVENT:
    INY
    LDA ($1E),Y
    STA $09
    INY
    LDA ($1E),Y
    STA $1D

ADVANCE_SCORE:
    LDA $1E
    CLC
    ADC #$03
    STA $1E
    BCC +
    INC $1F
+

PLAY_NEXT_EVENT:
    LDY #$00
    LDA ($1E),Y
    CMP #$01
    BEQ FETCH_DUTY_EVENT
    BCS START_NOTE_EVENT

    ; Fin de partition : depile les 3 registres internes et quitte
    PLA
    PLA
    PLA

CHECK_NOTE_PARAM:
    LDX #$49            ; Opcode EOR #imm (active l'oscillation)
    INY
    LDA ($1E),Y
    BNE EXIT_CHECK
    LDX #$C9            ; Opcode CMP #imm (coupe le son / silence)
EXIT_CHECK:
    RTS

START_NOTE_EVENT:
    STA $08             ; Duree de la note
    JSR CHECK_NOTE_PARAM
    STX MOD_V1_OP       ; Modifie instruction EOR/CMP Voix 1
    STA $06             ; Periode Voix 1
    LDX $09
_shift_v1:
    LSR A
    DEX
    BNE _shift_v1
    STA MOD_V1_DUTY     ; Seuil de transition duty cycle Voix 1

    JSR CHECK_NOTE_PARAM
    STX MOD_V2_OP       ; Modifie instruction EOR/CMP Voix 2
    STA $07             ; Periode Voix 2
    LDX $1D
_shift_v2:
    LSR A
    DEX
    BNE _shift_v2
    STA MOD_V2_DUTY     ; Seuil de transition duty cycle Voix 2

    PLA
    TAY
    PLA
    TAX
    PLA

    BNE LOOP_ENTRY_SKIP_SPK
LOOP_ENTRY_CLICK_SPK:
    BIT SPEAKER
LOOP_ENTRY_SKIP_SPK:
    CMP #$00
    BMI _spk_v2_high
    NOP
    BPL _spk_v2_done
_spk_v2_high:
    BIT SPEAKER
_spk_v2_done:
    STA $4E

    ; Verification du clavier : quitte immediatement si touche pressee
    BIT KEYBD
    BMI EXIT_CHECK

    ; --- DECOMPTE ET COMMUTATION VOIX 1 ---
    DEY
    BNE _v1_not_zero
    BEQ _v1_reload
_v1_not_zero:
    CPY #$00
MOD_V1_DUTY = * - 1
    BEQ _v1_flip_bit
    BNE _v1_check_done
_v1_reload:
    LDY $06
_v1_flip_bit:
    EOR #$40
MOD_V1_OP = * - 2
_v1_check_done:
    BIT $4E
    BVC _v1_low
    BVS _v1_high
_v1_high:
    BPL _tdm_click
    NOP
    BMI _tdm_skip
_v1_low:
    NOP
    BMI _tdm_click
    NOP
    BPL _tdm_skip
_tdm_click:
    CMP SPEAKER
_tdm_skip:
    ; --- GESTION DU TEMPS DE NOTE (256 BOUCLES DE 79 CYCLES) ---
    DEC $4F
    BNE _dur_not_expired
    DEC $08
    BNE _dur_not_expired

    BVC _note_end_skip_spk
    BIT SPEAKER
_note_end_skip_spk:
    PHA
    TXA
    PHA
    TYA
    PHA
    JMP ADVANCE_SCORE

_dur_not_expired:
    ; --- DECOMPTE ET COMMUTATION VOIX 2 ---
    DEX
    BNE _v2_not_zero
    BEQ _v2_reload
_v2_not_zero:
    CPX #$00
MOD_V2_DUTY = * - 1
    BEQ _v2_flip_bit
    BNE _v2_check_done
_v2_reload:
    LDX $07
_v2_flip_bit:
    EOR #$80
MOD_V2_OP = * - 2
_v2_check_done:
    BVS LOOP_ENTRY_CLICK_SPK
    NOP
    BVC LOOP_ENTRY_SKIP_SPK

; ===================================================================
; TEXTES DE L'INTERFACE UTILISATEUR
; ===================================================================
MENU_TEXT:
    .text "****************************************", $0D
    .text "*     DUO POLYPHONIQUE SUR APPLE II    *", $0D
    .text "*      MOTEUR ELECTRIC DUET (1981)     *", $0D
    .text "*    SOMMATION LINEAIRE TDM SUR $C030  *", $0D
    .text "****************************************", $0D
    .text $0D
    .text "ZERO BRUIT D'INTERMODULATION (SANS XOR)!", $0D
    .text "PORTEUSE 12.9 KHZ / FILTRE MECANIQUE HP", $0D
    .text "----------------------------------------", $0D
    .text "SELECTIONNEZ UN MORCEAU :", $0D
    .text " [1] J.S. BACH : FUGUE II COMPLETE", $0D
    .text " [2] T. ALBINONI : ADAGIO EN SOL MINEUR", $0D
    .text " [3] THE BEATLES : HEY JUDE (1968)", $0D
    .text " [4] THE BEATLES : LET IT BE (1970)", $0D
    .text " [5] THE BEATLES : I WANT YOU (1969)", $0D
    .text " [Q] QUITTER VERS LE DOS 3.3", $0D
    .text "----------------------------------------", $0D
    .text "VOTRE CHOIX [1..5, Q] ? ", $00

PLAY_BWV847_TEXT:
    .text "========================================", $0D
    .text "***     LECTURE EN COURS (2 VOIX)    ***", $0D
    .text "========================================", $0D
    .text $0D
    .text "OEUVRE : FUGUE II EN DO MINEUR (BWV 847)", $0D
    .text "AUTEUR : J.S. BACH (31 MESURES COMPLETES)", $0D
    .text $0D
    .text "VOIX 1 : SOPRANO / CONTRE-SUJET & THEME", $0D
    .text "VOIX 2 : ALTO & BASSE / SUJET PRINCIPAL", $0D
    .text $0D
    .text "PORTEUSE : 12 937 HZ SUR LE HP ($C030)", $0D
    .text "DECOUPE  : PWM 50% / MULTIPLEXAGE TDM", $0D
    .text "FILTRE   : INTEGRATION MECANIQUE DU CONE", $0D
    .text $0D
    .text "----------------------------------------", $0D
    .text "APPUYEZ SUR N'IMPORTE QUELLE TOUCHE", $0D
    .text "POUR ARRETER LA LECTURE...", $0D
    .text "----------------------------------------", $00

PLAY_ALBINONI_TEXT:
    .text "========================================", $0D
    .text "***     LECTURE EN COURS (2 VOIX)    ***", $0D
    .text "========================================", $0D
    .text $0D
    .text "OEUVRE : ADAGIO EN SOL MINEUR (~1.27 MIN)", $0D
    .text "AUTEUR : TOMASO ALBINONI / R. GIAZOTTO", $0D
    .text $0D
    .text "VOIX 1 : VIOLON SOLO LYRIQUE & EXPRESSIF", $0D
    .text "VOIX 2 : BASSE CONTINUE PIZZICATO & ORGUE", $0D
    .text $0D
    .text "PORTEUSE : 12 937 HZ SUR LE HP ($C030)", $0D
    .text "DECOUPE  : PWM 50% / MULTIPLEXAGE TDM", $0D
    .text "FILTRE   : INTEGRATION MECANIQUE DU CONE", $0D
    .text $0D
    .text "----------------------------------------", $0D
    .text "APPUYEZ SUR N'IMPORTE QUELLE TOUCHE", $0D
    .text "POUR ARRETER LA LECTURE...", $0D
    .text "----------------------------------------", $00

PLAY_HEYJUDE_TEXT:
    .text "========================================", $0D
    .text "***     LECTURE EN COURS (2 VOIX)    ***", $0D
    .text "========================================", $0D
    .text $0D
    .text "OEUVRE : HEY JUDE (SINGLE APPLE, 1968)", $0D
    .text "AUTEURS: JOHN LENNON & PAUL MCCARTNEY", $0D
    .text $0D
    .text "VOIX 1 : CHANT LEAD (PAUL MCCARTNEY)", $0D
    .text "VOIX 2 : PIANO ACCOMPAGNATEUR & BASSE", $0D
    .text $0D
    .text "PORTEUSE : 12 937 HZ SUR LE HP ($C030)", $0D
    .text "DECOUPE  : PWM 50% / MULTIPLEXAGE TDM", $0D
    .text "FILTRE   : INTEGRATION MECANIQUE DU CONE", $0D
    .text $0D
    .text "----------------------------------------", $0D
    .text "APPUYEZ SUR N'IMPORTE QUELLE TOUCHE", $0D
    .text "POUR ARRETER LA LECTURE...", $0D
    .text "----------------------------------------", $00

PLAY_LETITBE_TEXT:
    .text "========================================", $0D
    .text "***     LECTURE EN COURS (2 VOIX)    ***", $0D
    .text "========================================", $0D
    .text $0D
    .text "OEUVRE : LET IT BE (SINGLE APPLE, 1970)", $0D
    .text "AUTEUR : PAUL MCCARTNEY (THE BEATLES)", $0D
    .text $0D
    .text "VOIX 1 : CHANT LEAD (GOSPEL-ROCK)", $0D
    .text "VOIX 2 : ACCORDS DE PIANO & BASSE", $0D
    .text $0D
    .text "PORTEUSE : 12 937 HZ SUR LE HP ($C030)", $0D
    .text "DECOUPE  : PWM 50% / MULTIPLEXAGE TDM", $0D
    .text "FILTRE   : INTEGRATION MECANIQUE DU CONE", $0D
    .text $0D
    .text "----------------------------------------", $0D
    .text "APPUYEZ SUR N'IMPORTE QUELLE TOUCHE", $0D
    .text "POUR ARRETER LA LECTURE...", $0D
    .text "----------------------------------------", $00

PLAY_IWANTYOU_TEXT:
    .text "========================================", $0D
    .text "***     LECTURE EN COURS (2 VOIX)    ***", $0D
    .text "========================================", $0D
    .text $0D
    .text "OEUVRE : I WANT YOU (SHE'S SO HEAVY)", $0D
    .text "AUTEUR : JOHN LENNON (ABBEY ROAD, 1969)", $0D
    .text $0D
    .text "VOIX 1 : ARPEGE MYTHIQUE & CHANT BLUES", $0D
    .text "VOIX 2 : RIFF HEAVY ROCK & BASSE LOURDE", $0D
    .text $0D
    .text "PORTEUSE : 12 937 HZ SUR LE HP ($C030)", $0D
    .text "DECOUPE  : PWM 50% / MULTIPLEXAGE TDM", $0D
    .text "FILTRE   : INTEGRATION MECANIQUE DU CONE", $0D
    .text $0D
    .text "----------------------------------------", $0D
    .text "APPUYEZ SUR N'IMPORTE QUELLE TOUCHE", $0D
    .text "POUR ARRETER LA LECTURE...", $0D
    .text "----------------------------------------", $00

; ===================================================================
; DONNEES DES PARTITIONS (FORMAT ELECTRIC DUET)
; ===================================================================
.include "bach_duet_data.asm"
