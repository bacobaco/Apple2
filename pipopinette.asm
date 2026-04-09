; =============================================
; PIPOPIPETTE - Version Minimale pour Débogage
; Assembleur: 64tass
; Adresse: $6000
; Garantie: Affiche une grille 5x5 ou un pixel blanc
; =============================================

* = $6000

; --- Constantes ---
HGR_PAGE1      = $20        ; Page HGR (pour HPOSN)
HCOLOR         = $E4        ; Registre couleur

; =============================================
; INITIALISATION MINIMALE
; =============================================
INIT:
    ; --- Activer le mode HGR ---
    BIT $C050           ; Mode graphique
    BIT $C052           ; Désactiver Mix-Mode
    BIT $C057           ; Plein écran

    ; --- Couleur blanche pour la grille ---
    LDA #$FF
    STA HCOLOR

    ; --- Dessiner UN SEUL PIXEL pour test ---
    LDA #0              ; X=0
    TAY                 ; Y=0
    JSR $F411           ; HPOSN (calcule l'adresse)
    LDA #$FF
    STA ($25),Y        ; Écrire un pixel blanc en (0,0)

    ; --- Dessiner la grille 5x5 ---
    JSR DRAW_GRID

    ; --- Boucle infinie ---
    JMP *

; =============================================
; DRAW_GRID - Dessine une grille 5x5
; =============================================
DRAW_GRID:
    LDY #0              ; Boucle Y (0-4)
DRAW_Y_LOOP:
    LDX #0              ; Boucle X (0-4)
DRAW_X_LOOP:
    ; --- Calculer l'adresse HGR pour (X,Y) ---
    TYA                 ; Y dans A
    ASL                 ; Y*2
    ASL                 ; Y*4
    ASL                 ; Y*8
    ASL                 ; Y*16
    ASL                 ; Y*32
    STA $06             ; Bas de l'adresse
    LDA #0
    STA $07             ; Haut de l'adresse (toujours 0)

    TXA                 ; X dans A
    ASL                 ; X*2
    ASL                 ; X*4
    ASL                 ; X*8
    ASL                 ; X*16
    ASL                 ; X*32
    ASL                 ; X*64 (car 40=32+8)
    CLC
    ADC $06             ; Ajouter Y*32
    STA $06
    LDA $07
    ADC #0              ; Propager la retenue
    STA $07

    ; --- Appeler HPOSN pour obtenir l'adresse finale ---
    LDA $06
    LSR                 ; Diviser par 2 pour HPOSN
    TAY
    LDA $07
    JSR $F411           ; HPOSN -> résultat dans $25/$26

    ; --- Dessiner un point 2x2 pixels ---
    LDA #$FF
    STA ($25),Y        ; Premier pixel
    INY
    STA ($25),Y        ; Deuxième pixel

    ; --- Passer au point suivant ---
    INX
    CPX #5
    BNE DRAW_X_LOOP

    ; --- Passer à la ligne suivante (ajuster Y) ---
    TYA
    CLC
    ADC #40             ; 40 colonnes par ligne
    TAY
    INY                 ; Espacement vertical
    INY
    INY
    INY
    INY
    CPY #5*40           ; 5 lignes * 40 pixels
    BNE DRAW_Y_LOOP
    RTS