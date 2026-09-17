; =============================================================================
; CARDS_GFX.ASM - DONNEES GRAPHIQUES HGR POUR 1000 BORNES APPLE II
; Genere automatiquement a partir des DEFGR$ du Thomson MO5 (J.Y. Boucrot 1985)
; Format : 5 octets x 40 lignes (200 octets par carte, 35x40 pixels, 1:1 exact)
; =============================================================================

; --- TABLES D'ADRESSES DES 192 LIGNES HGR ($2000-$3FFF) ---
HGR_ROW_LO
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $80, $80, $80, $80, $80, $80, $80, $80
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $80, $80, $80, $80, $80, $80, $80, $80
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $80, $80, $80, $80, $80, $80, $80, $80
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $80, $80, $80, $80, $80, $80, $80, $80
    .byte $28, $28, $28, $28, $28, $28, $28, $28, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8
    .byte $28, $28, $28, $28, $28, $28, $28, $28, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8
    .byte $28, $28, $28, $28, $28, $28, $28, $28, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8
    .byte $28, $28, $28, $28, $28, $28, $28, $28, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8
    .byte $50, $50, $50, $50, $50, $50, $50, $50, $D0, $D0, $D0, $D0, $D0, $D0, $D0, $D0
    .byte $50, $50, $50, $50, $50, $50, $50, $50, $D0, $D0, $D0, $D0, $D0, $D0, $D0, $D0
    .byte $50, $50, $50, $50, $50, $50, $50, $50, $D0, $D0, $D0, $D0, $D0, $D0, $D0, $D0
    .byte $50, $50, $50, $50, $50, $50, $50, $50, $D0, $D0, $D0, $D0, $D0, $D0, $D0, $D0

HGR_ROW_HI
    .byte $20, $24, $28, $2C, $30, $34, $38, $3C, $20, $24, $28, $2C, $30, $34, $38, $3C
    .byte $21, $25, $29, $2D, $31, $35, $39, $3D, $21, $25, $29, $2D, $31, $35, $39, $3D
    .byte $22, $26, $2A, $2E, $32, $36, $3A, $3E, $22, $26, $2A, $2E, $32, $36, $3A, $3E
    .byte $23, $27, $2B, $2F, $33, $37, $3B, $3F, $23, $27, $2B, $2F, $33, $37, $3B, $3F
    .byte $20, $24, $28, $2C, $30, $34, $38, $3C, $20, $24, $28, $2C, $30, $34, $38, $3C
    .byte $21, $25, $29, $2D, $31, $35, $39, $3D, $21, $25, $29, $2D, $31, $35, $39, $3D
    .byte $22, $26, $2A, $2E, $32, $36, $3A, $3E, $22, $26, $2A, $2E, $32, $36, $3A, $3E
    .byte $23, $27, $2B, $2F, $33, $37, $3B, $3F, $23, $27, $2B, $2F, $33, $37, $3B, $3F
    .byte $20, $24, $28, $2C, $30, $34, $38, $3C, $20, $24, $28, $2C, $30, $34, $38, $3C
    .byte $21, $25, $29, $2D, $31, $35, $39, $3D, $21, $25, $29, $2D, $31, $35, $39, $3D
    .byte $22, $26, $2A, $2E, $32, $36, $3A, $3E, $22, $26, $2A, $2E, $32, $36, $3A, $3E
    .byte $23, $27, $2B, $2F, $33, $37, $3B, $3F, $23, $27, $2B, $2F, $33, $37, $3B, $3F

; --- TABLES DE POINTEURS VERS LES BITMAPS DES CARTES (200 octets par carte) ---
CARD_PTR_LO
    .byte <CARD_GFX_00, <CARD_GFX_01, <CARD_GFX_02, <CARD_GFX_03, <CARD_GFX_04, <CARD_GFX_05, <CARD_GFX_06, <CARD_GFX_07, <CARD_GFX_08, <CARD_GFX_09, <CARD_GFX_10, <CARD_GFX_11, <CARD_GFX_12, <CARD_GFX_13, <CARD_GFX_14, <CARD_GFX_15, <CARD_GFX_16, <CARD_GFX_17, <CARD_GFX_18, <CARD_GFX_19, <CARD_GFX_20
CARD_PTR_HI
    .byte >CARD_GFX_00, >CARD_GFX_01, >CARD_GFX_02, >CARD_GFX_03, >CARD_GFX_04, >CARD_GFX_05, >CARD_GFX_06, >CARD_GFX_07, >CARD_GFX_08, >CARD_GFX_09, >CARD_GFX_10, >CARD_GFX_11, >CARD_GFX_12, >CARD_GFX_13, >CARD_GFX_14, >CARD_GFX_15, >CARD_GFX_16, >CARD_GFX_17, >CARD_GFX_18, >CARD_GFX_19, >CARD_GFX_20

; Carte 00 : 00_BORNE_TITRE (200 octets, 5 octets x 40 lignes)
CARD_GFX_00
    .byte $00, $00, $00, $00, $00
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $D7, $AA, $FD, $1F
    .byte $7E, $D7, $AA, $F5, $1F
    .byte $7E, $D5, $AA, $F5, $1F
    .byte $7E, $D5, $AA, $D5, $1F
    .byte $BE, $D5, $AA, $D5, $1F
    .byte $BE, $D5, $AA, $D5, $1F
    .byte $BE, $D5, $AA, $D5, $9E
    .byte $BE, $D5, $AA, $D5, $9E
    .byte $7E, $7F, $7D, $6F, $1F
    .byte $7E, $7F, $7E, $5F, $1F
    .byte $7E, $7F, $7E, $1B, $1F
    .byte $7E, $3F, $7B, $09, $18
    .byte $7E, $3F, $76, $01, $10
    .byte $7E, $0F, $68, $00, $00
    .byte $7E, $07, $00, $00, $00
    .byte $7E, $03, $00, $00, $00
    .byte $7E, $61, $70, $61, $00
    .byte $7E, $21, $6F, $5E, $00
    .byte $7E, $40, $1F, $3F, $00
    .byte $7E, $42, $19, $33, $10
    .byte $7E, $42, $19, $33, $10
    .byte $7E, $58, $1F, $3F, $07
    .byte $7E, $3F, $6F, $5E, $1F
    .byte $7E, $7F, $70, $61, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $00, $00, $00, $00, $00

; Carte 01 : 01_PANNE_ESSENCE (200 octets, 5 octets x 40 lignes)
CARD_GFX_01
    .byte $00, $00, $00, $00, $00
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $06, $7F, $7F, $7F, $1F
    .byte $76, $7E, $7F, $7F, $1F
    .byte $76, $7E, $7F, $7F, $1F
    .byte $06, $7F, $7F, $7F, $1F
    .byte $76, $7F, $7F, $7F, $1F
    .byte $76, $0F, $15, $7A, $1F
    .byte $76, $6F, $55, $7B, $1F
    .byte $7E, $0F, $15, $7A, $1F
    .byte $7E, $6F, $55, $7B, $1F
    .byte $76, $6F, $11, $62, $17
    .byte $6A, $7F, $7F, $7F, $13
    .byte $6A, $1F, $00, $7E, $17
    .byte $76, $63, $7B, $71, $17
    .byte $76, $7C, $7B, $4F, $1F
    .byte $1E, $1F, $00, $3E, $1E
    .byte $6E, $63, $7F, $71, $1D
    .byte $76, $7D, $7F, $4F, $1B
    .byte $1A, $7E, $7F, $3F, $17
    .byte $1A, $7F, $7F, $7F, $16
    .byte $56, $7E, $7F, $7F, $19
    .byte $7E, $7D, $7F, $7F, $1F
    .byte $7E, $7B, $7F, $7F, $1F
    .byte $7E, $77, $7F, $7F, $1F
    .byte $7E, $6F, $7F, $7F, $1F
    .byte $7E, $5F, $7F, $7F, $1F
    .byte $7E, $3F, $7F, $7F, $1F
    .byte $7E, $7F, $7E, $7F, $1F
    .byte $7E, $7F, $79, $7F, $1F
    .byte $7E, $7F, $7B, $1F, $1C
    .byte $7E, $7F, $7F, $5F, $1B
    .byte $7E, $7F, $7F, $5F, $1B
    .byte $7E, $7F, $7F, $1F, $1C
    .byte $7E, $7F, $7F, $5F, $1F
    .byte $7E, $7F, $7F, $5F, $1F
    .byte $7E, $7F, $7F, $5F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $00, $00, $00, $00, $00

; Carte 02 : 02_ACCIDENT (200 octets, 5 octets x 40 lignes)
CARD_GFX_02
    .byte $00, $00, $00, $00, $00
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $0E, $3F, $7E, $7F, $1F
    .byte $76, $5E, $7D, $7F, $1F
    .byte $76, $6E, $7D, $7F, $1F
    .byte $06, $76, $7D, $7F, $1F
    .byte $76, $7A, $7D, $7F, $1F
    .byte $76, $76, $7D, $7F, $1F
    .byte $76, $6E, $7D, $7F, $1F
    .byte $7E, $4F, $7D, $7F, $1F
    .byte $7E, $17, $0C, $7E, $1F
    .byte $7E, $67, $07, $7E, $1F
    .byte $7E, $67, $07, $7E, $1F
    .byte $7E, $71, $77, $7D, $1F
    .byte $7E, $79, $77, $7D, $1F
    .byte $7E, $7C, $7B, $7D, $1F
    .byte $7E, $6C, $7B, $7B, $1F
    .byte $7E, $5C, $39, $73, $1F
    .byte $7E, $5C, $1C, $01, $1F
    .byte $3E, $1E, $1D, $00, $1E
    .byte $3E, $5E, $0B, $00, $1C
    .byte $1E, $1F, $00, $00, $1C
    .byte $1E, $07, $00, $00, $1C
    .byte $4E, $0F, $1E, $0C, $1C
    .byte $4E, $07, $6C, $0B, $1C
    .byte $70, $73, $71, $07, $18
    .byte $4E, $7B, $33, $06, $1A
    .byte $1E, $1B, $33, $06, $1A
    .byte $1E, $13, $71, $77, $18
    .byte $3E, $70, $69, $7B, $1F
    .byte $7E, $00, $18, $3C, $1C
    .byte $7E, $7F, $7F, $5F, $1B
    .byte $7E, $7F, $7F, $5F, $1B
    .byte $7E, $7F, $7F, $1F, $18
    .byte $7E, $7F, $7F, $5F, $1B
    .byte $7E, $7F, $7F, $5F, $1B
    .byte $7E, $7F, $7F, $5F, $1B
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $00, $00, $00, $00, $00

; Carte 03 : 03_CREVAISON (200 octets, 5 octets x 40 lignes)
CARD_GFX_03
    .byte $00, $00, $00, $00, $00
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $0E, $7E, $7F, $7F, $1F
    .byte $76, $7F, $7F, $7F, $1F
    .byte $76, $7F, $7F, $7F, $1F
    .byte $76, $7F, $7F, $7F, $1F
    .byte $76, $7F, $7F, $7F, $1F
    .byte $76, $7F, $7F, $7F, $1F
    .byte $0E, $7E, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $00, $7F, $1F
    .byte $7E, $3F, $00, $7E, $1F
    .byte $7E, $3F, $7F, $7E, $1F
    .byte $7E, $5F, $7F, $7D, $1F
    .byte $7E, $5F, $7F, $7D, $1F
    .byte $7E, $6F, $7F, $7B, $1F
    .byte $7E, $6F, $3F, $73, $1F
    .byte $7E, $37, $1F, $01, $1F
    .byte $7E, $67, $1E, $00, $1E
    .byte $7E, $01, $0D, $00, $1C
    .byte $7E, $00, $00, $00, $1C
    .byte $3E, $00, $00, $00, $1C
    .byte $1E, $0C, $7E, $0F, $1C
    .byte $1E, $74, $0D, $08, $1C
    .byte $0E, $78, $03, $00, $18
    .byte $2E, $18, $73, $07, $1A
    .byte $2E, $18, $33, $06, $1A
    .byte $0E, $7B, $23, $72, $18
    .byte $7E, $77, $65, $73, $1F
    .byte $7E, $0F, $06, $38, $18
    .byte $7E, $7F, $7F, $5F, $1F
    .byte $7E, $7F, $7F, $5F, $1F
    .byte $7E, $7F, $7F, $5F, $1F
    .byte $7E, $7F, $7F, $5F, $1F
    .byte $7E, $7F, $7F, $5F, $1F
    .byte $7E, $7F, $7F, $3F, $18
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $00, $00, $00, $00, $00

; Carte 04 : 04_LIMITATION_50 (200 octets, 5 octets x 40 lignes)
CARD_GFX_04
    .byte $00, $00, $00, $00, $00
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $76, $7F, $7F, $7F, $1F
    .byte $76, $7F, $7F, $7F, $1F
    .byte $76, $7F, $7F, $7F, $1F
    .byte $76, $7F, $7F, $7F, $1F
    .byte $76, $7F, $7F, $7F, $1F
    .byte $76, $7F, $61, $7F, $1F
    .byte $06, $3E, $1E, $7F, $1F
    .byte $7E, $5F, $7F, $7E, $1F
    .byte $7E, $6F, $7F, $7D, $1F
    .byte $7E, $37, $18, $7B, $1F
    .byte $7E, $37, $6F, $7A, $1F
    .byte $7E, $3B, $6F, $76, $1F
    .byte $7E, $3B, $6C, $76, $1F
    .byte $7E, $7B, $6B, $76, $1F
    .byte $7E, $3B, $6B, $76, $1F
    .byte $7E, $77, $1C, $7B, $1F
    .byte $7E, $77, $7F, $7B, $1F
    .byte $7E, $6F, $7F, $7D, $1F
    .byte $7E, $5F, $7F, $7E, $1F
    .byte $7E, $3F, $1E, $7F, $1F
    .byte $7E, $7F, $61, $7F, $1F
    .byte $7E, $7F, $73, $7F, $1F
    .byte $7E, $7F, $73, $7F, $1F
    .byte $7E, $7F, $73, $7F, $1F
    .byte $7E, $7F, $73, $7F, $1F
    .byte $7E, $7F, $73, $7F, $1F
    .byte $7E, $7F, $73, $7F, $1F
    .byte $7E, $7F, $73, $7F, $1F
    .byte $7E, $7F, $73, $5F, $1F
    .byte $7E, $7F, $7F, $5F, $1F
    .byte $7E, $7F, $7F, $5F, $1F
    .byte $7E, $7F, $7F, $5F, $1F
    .byte $7E, $7F, $7F, $5F, $1F
    .byte $7E, $7F, $7F, $5F, $1F
    .byte $7E, $7F, $7F, $1F, $18
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $00, $00, $00, $00, $00

; Carte 05 : 05_FEU_ROUGE (200 octets, 5 octets x 40 lignes)
CARD_GFX_05
    .byte $00, $00, $00, $00, $00
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $06, $7F, $7F, $7F, $1F
    .byte $76, $7E, $7F, $7F, $1F
    .byte $76, $7E, $7F, $7F, $1F
    .byte $06, $7F, $7F, $7F, $1F
    .byte $56, $7F, $7F, $7F, $1F
    .byte $36, $07, $00, $7C, $1F
    .byte $76, $06, $0B, $7E, $1F
    .byte $7E, $C7, $AA, $7F, $1F
    .byte $7E, $C7, $FA, $7F, $1F
    .byte $7E, $C7, $FA, $7F, $1F
    .byte $7E, $C7, $EA, $7F, $1F
    .byte $7E, $07, $67, $7F, $1F
    .byte $7E, $07, $60, $7F, $1F
    .byte $7E, $07, $00, $7C, $1F
    .byte $7E, $07, $0B, $7E, $1F
    .byte $7E, $47, $0F, $7F, $1F
    .byte $7E, $67, $5F, $7F, $1F
    .byte $7E, $67, $7F, $7F, $1F
    .byte $7E, $47, $6F, $7F, $1F
    .byte $7E, $07, $67, $7F, $1F
    .byte $7E, $07, $60, $7F, $1F
    .byte $7E, $07, $00, $7C, $1F
    .byte $7E, $07, $0B, $7E, $1F
    .byte $7E, $47, $0F, $7F, $1F
    .byte $7E, $67, $5F, $7F, $1F
    .byte $7E, $67, $7F, $7F, $1F
    .byte $7E, $47, $6F, $7F, $1F
    .byte $7E, $07, $67, $7F, $1F
    .byte $7E, $07, $60, $1F, $1C
    .byte $7E, $7F, $7C, $5F, $1B
    .byte $7E, $7F, $7C, $5F, $1B
    .byte $7E, $7F, $7C, $1F, $1C
    .byte $7E, $7F, $7C, $5F, $1E
    .byte $7E, $7F, $7C, $5F, $1D
    .byte $7E, $7F, $7C, $5F, $1B
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $00, $00, $00, $00, $00

; Carte 06 : 06_ESSENCE (200 octets, 5 octets x 40 lignes)
CARD_GFX_06
    .byte $00, $00, $00, $00, $00
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $06, $7E, $7F, $7F, $1F
    .byte $76, $7F, $7F, $7F, $1F
    .byte $76, $7F, $7F, $7F, $1F
    .byte $06, $7F, $7F, $7F, $1F
    .byte $76, $7F, $7F, $7F, $1F
    .byte $76, $03, $00, $70, $1F
    .byte $06, $02, $00, $70, $1F
    .byte $7E, $73, $4E, $63, $1F
    .byte $7E, $73, $4E, $43, $1F
    .byte $7E, $73, $4E, $13, $1F
    .byte $7E, $03, $00, $10, $1F
    .byte $7E, $03, $00, $10, $1F
    .byte $7E, $03, $00, $10, $1F
    .byte $7E, $5F, $7F, $5C, $1F
    .byte $7E, $5F, $7F, $5A, $1F
    .byte $7E, $5F, $7F, $5A, $1F
    .byte $7E, $5F, $7F, $5A, $1F
    .byte $7E, $3F, $3F, $3D, $1F
    .byte $7E, $3F, $3F, $3D, $1F
    .byte $7E, $3F, $3F, $3D, $1F
    .byte $7E, $3F, $3F, $4B, $1F
    .byte $7E, $7F, $5E, $77, $1F
    .byte $7E, $7F, $5E, $7F, $1F
    .byte $7E, $7F, $5E, $7F, $1F
    .byte $7E, $7F, $6D, $7F, $1F
    .byte $7E, $7F, $6D, $7F, $1F
    .byte $7E, $7F, $6D, $7F, $1F
    .byte $7E, $07, $00, $78, $1F
    .byte $7E, $7F, $7F, $1F, $18
    .byte $7E, $7F, $7F, $5F, $1F
    .byte $7E, $7F, $7F, $5F, $1F
    .byte $7E, $7F, $7F, $1F, $1C
    .byte $7E, $7F, $7F, $5F, $1F
    .byte $7E, $7F, $7F, $5F, $1F
    .byte $7E, $7F, $7F, $1F, $18
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $00, $00, $00, $00, $00

; Carte 07 : 07_REPARATIONS (200 octets, 5 octets x 40 lignes)
CARD_GFX_07
    .byte $00, $00, $00, $00, $00
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $06, $7F, $7F, $7F, $1F
    .byte $76, $7E, $00, $7F, $1F
    .byte $76, $3E, $00, $7E, $1F
    .byte $06, $3F, $7F, $7E, $1F
    .byte $56, $5F, $7F, $7D, $1F
    .byte $36, $5F, $7F, $7D, $1F
    .byte $76, $6E, $7F, $7B, $1F
    .byte $5E, $6F, $3F, $73, $1F
    .byte $3E, $37, $1F, $01, $1F
    .byte $3E, $67, $1E, $00, $1E
    .byte $7E, $02, $0D, $00, $1C
    .byte $7E, $00, $00, $00, $1C
    .byte $7E, $01, $00, $00, $1C
    .byte $56, $0C, $1E, $0C, $1C
    .byte $06, $74, $6D, $0B, $1C
    .byte $06, $78, $73, $07, $18
    .byte $02, $18, $33, $06, $1A
    .byte $06, $18, $33, $06, $1A
    .byte $56, $79, $73, $77, $18
    .byte $3E, $74, $6D, $7B, $1F
    .byte $7E, $0F, $1E, $7C, $1F
    .byte $1E, $00, $00, $00, $1E
    .byte $4E, $7F, $65, $7F, $1C
    .byte $66, $7F, $65, $7F, $19
    .byte $76, $7F, $65, $7F, $1B
    .byte $7E, $7F, $40, $7F, $1F
    .byte $7E, $7F, $40, $7F, $1F
    .byte $7E, $03, $00, $70, $1F
    .byte $7E, $7F, $7F, $1F, $1C
    .byte $7E, $7F, $7F, $5F, $1B
    .byte $7E, $7F, $7F, $5F, $1B
    .byte $7E, $7F, $7F, $1F, $1C
    .byte $7E, $7F, $7F, $5F, $1E
    .byte $7E, $7F, $7F, $5F, $1D
    .byte $7E, $7F, $7F, $5F, $1B
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $00, $00, $00, $00, $00

; Carte 08 : 08_ROUE_SECOURS (200 octets, 5 octets x 40 lignes)
CARD_GFX_08
    .byte $00, $00, $00, $00, $00
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $0E, $7E, $7F, $7F, $1F
    .byte $76, $7F, $7F, $7F, $1F
    .byte $0E, $7F, $7F, $7F, $1F
    .byte $7E, $7E, $7F, $7F, $1F
    .byte $7E, $7E, $7F, $7F, $1F
    .byte $76, $7E, $40, $7F, $1F
    .byte $0E, $1F, $00, $7E, $1F
    .byte $7E, $0F, $00, $7C, $1F
    .byte $7E, $03, $00, $70, $1F
    .byte $7E, $01, $00, $60, $1F
    .byte $7E, $01, $00, $60, $1F
    .byte $7E, $00, $1E, $40, $1F
    .byte $3E, $38, $61, $00, $1F
    .byte $3E, $20, $1E, $01, $1F
    .byte $1E, $20, $3F, $01, $1E
    .byte $1E, $50, $73, $02, $1E
    .byte $1E, $50, $6D, $02, $1E
    .byte $1E, $50, $6D, $02, $1E
    .byte $1E, $50, $73, $02, $1E
    .byte $1E, $20, $3F, $01, $1E
    .byte $3E, $20, $1E, $01, $1F
    .byte $3E, $40, $61, $00, $1F
    .byte $7E, $00, $1E, $40, $1F
    .byte $7E, $01, $00, $70, $1D
    .byte $7E, $01, $00, $60, $1F
    .byte $7E, $03, $00, $70, $1F
    .byte $7E, $0F, $00, $7C, $1F
    .byte $7E, $1F, $00, $7E, $1F
    .byte $7E, $7F, $40, $3F, $18
    .byte $7E, $7F, $7F, $5F, $1F
    .byte $7E, $7F, $7F, $3F, $1C
    .byte $7E, $7F, $7F, $7F, $1B
    .byte $7E, $7F, $7F, $7F, $1B
    .byte $7E, $7F, $7F, $5F, $1B
    .byte $7E, $7F, $7F, $3F, $1C
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $00, $00, $00, $00, $00

; Carte 09 : 09_FIN_LIMITATION (200 octets, 5 octets x 40 lignes)
CARD_GFX_09
    .byte $00, $00, $00, $00, $00
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $06, $7E, $7F, $7F, $1F
    .byte $76, $7F, $7F, $7F, $1F
    .byte $76, $7F, $7F, $7F, $1F
    .byte $06, $7F, $7F, $7F, $1F
    .byte $76, $7F, $7F, $7F, $1F
    .byte $76, $7F, $61, $7F, $1F
    .byte $76, $3F, $1E, $7F, $1F
    .byte $7E, $5F, $3F, $7E, $1F
    .byte $7E, $6F, $1F, $7C, $1F
    .byte $7E, $77, $0F, $78, $1F
    .byte $7E, $77, $07, $78, $1F
    .byte $7E, $5F, $01, $76, $1F
    .byte $7E, $7B, $01, $77, $1F
    .byte $7E, $7B, $40, $77, $1F
    .byte $7E, $3B, $60, $77, $1F
    .byte $7E, $17, $70, $7B, $1F
    .byte $7E, $07, $78, $7B, $1F
    .byte $7E, $0F, $7C, $7D, $1F
    .byte $7E, $1F, $7E, $7E, $1F
    .byte $7E, $3F, $1E, $7F, $1F
    .byte $7E, $7F, $61, $7F, $1F
    .byte $7E, $7F, $73, $7F, $1F
    .byte $7E, $7F, $73, $7F, $1F
    .byte $7E, $7F, $73, $7F, $1F
    .byte $7E, $7F, $73, $7F, $1F
    .byte $7E, $7F, $73, $7F, $1F
    .byte $7E, $7F, $73, $7F, $1F
    .byte $7E, $7F, $73, $7F, $1F
    .byte $7E, $7F, $73, $1F, $18
    .byte $7E, $7F, $7F, $5F, $1F
    .byte $7E, $7F, $7F, $5F, $1F
    .byte $7E, $7F, $7F, $1F, $1C
    .byte $7E, $7F, $7F, $5F, $1F
    .byte $7E, $7F, $7F, $5F, $1F
    .byte $7E, $7F, $7F, $5F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $00, $00, $00, $00, $00

; Carte 10 : 10_FEU_VERT (200 octets, 5 octets x 40 lignes)
CARD_GFX_10
    .byte $00, $00, $00, $00, $00
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $76, $7E, $7F, $7F, $1F
    .byte $76, $7E, $7F, $7F, $1F
    .byte $76, $7E, $7F, $7F, $1F
    .byte $76, $7E, $7F, $7F, $1F
    .byte $2E, $7F, $7F, $7F, $1F
    .byte $2E, $07, $00, $7C, $1F
    .byte $5E, $07, $0B, $7E, $1F
    .byte $7E, $47, $0F, $7F, $1F
    .byte $7E, $67, $5F, $7F, $1F
    .byte $7E, $67, $7F, $7F, $1F
    .byte $7E, $47, $6F, $7F, $1F
    .byte $7E, $07, $67, $7F, $1F
    .byte $7E, $07, $60, $7F, $1F
    .byte $7E, $07, $00, $7C, $1F
    .byte $7E, $07, $0B, $7E, $1F
    .byte $7E, $47, $0F, $7F, $1F
    .byte $7E, $67, $5F, $7F, $1F
    .byte $7E, $67, $7F, $7F, $1F
    .byte $7E, $47, $6F, $7F, $1F
    .byte $7E, $07, $67, $7F, $1F
    .byte $7E, $07, $60, $7F, $1F
    .byte $7E, $07, $00, $7C, $1F
    .byte $7E, $07, $0B, $7E, $1F
    .byte $7E, $47, $2A, $7F, $1F
    .byte $7E, $47, $7A, $7F, $1F
    .byte $7E, $47, $7A, $7F, $1F
    .byte $7E, $47, $6A, $7F, $1F
    .byte $7E, $07, $67, $7F, $1F
    .byte $7E, $07, $60, $5F, $1B
    .byte $7E, $7F, $7C, $5F, $1B
    .byte $7E, $7F, $7C, $5F, $1B
    .byte $7E, $7F, $7C, $5F, $1B
    .byte $7E, $7F, $7C, $3F, $1D
    .byte $7E, $7F, $7C, $3F, $1D
    .byte $7E, $7F, $7C, $7F, $1E
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $00, $00, $00, $00, $00

; Carte 11 : 11_ETAPE_200KM (200 octets, 5 octets x 40 lignes)
CARD_GFX_11
    .byte $00, $00, $00, $00, $00
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $D7, $AA, $FD, $1F
    .byte $7E, $D7, $AA, $F5, $1F
    .byte $7E, $D5, $AA, $F5, $1F
    .byte $7E, $D5, $AA, $D5, $1F
    .byte $BE, $D5, $AA, $D5, $1F
    .byte $BE, $D5, $AA, $D5, $1F
    .byte $BE, $D5, $AA, $D5, $9E
    .byte $BE, $D5, $AA, $D5, $9E
    .byte $5E, $6F, $7F, $7F, $1E
    .byte $5E, $6F, $7F, $7F, $1E
    .byte $5E, $6F, $7F, $7F, $1E
    .byte $5E, $6F, $7F, $7F, $1E
    .byte $5E, $6F, $1C, $67, $1E
    .byte $5E, $2F, $6B, $5A, $1E
    .byte $5E, $6F, $6B, $5A, $1E
    .byte $5E, $6F, $6B, $5A, $1E
    .byte $5E, $6F, $6C, $5A, $1E
    .byte $5E, $2F, $6F, $5A, $1E
    .byte $5E, $2F, $6F, $5A, $1E
    .byte $5E, $2F, $18, $67, $1E
    .byte $5E, $6F, $7F, $7F, $1E
    .byte $5E, $6F, $7F, $7F, $1E
    .byte $5E, $6F, $7F, $7F, $1E
    .byte $1E, $00, $00, $00, $1E
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $00, $00, $00, $00, $00

; Carte 12 : 12_ETAPE_100KM (200 octets, 5 octets x 40 lignes)
CARD_GFX_12
    .byte $00, $00, $00, $00, $00
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $D7, $AA, $FD, $1F
    .byte $7E, $D7, $AA, $F5, $1F
    .byte $7E, $D5, $AA, $F5, $1F
    .byte $7E, $D5, $AA, $D5, $1F
    .byte $BE, $D5, $AA, $D5, $1F
    .byte $BE, $D5, $AA, $D5, $1F
    .byte $BE, $D5, $AA, $D5, $9E
    .byte $BE, $D5, $AA, $D5, $9E
    .byte $5E, $6F, $7F, $7F, $1E
    .byte $5E, $6F, $7F, $7F, $1E
    .byte $5E, $6F, $7F, $7F, $1E
    .byte $5E, $6F, $7F, $7F, $1E
    .byte $5E, $6F, $1B, $67, $1E
    .byte $5E, $6F, $69, $5A, $1E
    .byte $5E, $6F, $6A, $5A, $1E
    .byte $5E, $6F, $6B, $5A, $1E
    .byte $5E, $6F, $6B, $5A, $1E
    .byte $5E, $6F, $6B, $5A, $1E
    .byte $5E, $6F, $6B, $5A, $1E
    .byte $5E, $6F, $1B, $67, $1E
    .byte $5E, $6F, $7F, $7F, $1E
    .byte $5E, $6F, $7F, $7F, $1E
    .byte $5E, $6F, $7F, $7F, $1E
    .byte $1E, $00, $00, $00, $1E
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $00, $00, $00, $00, $00

; Carte 13 : 13_ETAPE_75KM (200 octets, 5 octets x 40 lignes)
CARD_GFX_13
    .byte $00, $00, $00, $00, $00
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $D7, $AA, $FD, $1F
    .byte $7E, $D7, $AA, $F5, $1F
    .byte $7E, $D5, $AA, $F5, $1F
    .byte $7E, $D5, $AA, $D5, $1F
    .byte $BE, $D5, $AA, $D5, $1F
    .byte $BE, $D5, $AA, $D5, $1F
    .byte $BE, $D5, $AA, $D5, $9E
    .byte $BE, $D5, $AA, $D5, $9E
    .byte $5E, $6F, $7F, $7F, $1E
    .byte $5E, $6F, $7F, $7F, $1E
    .byte $5E, $6F, $7F, $7F, $1E
    .byte $5E, $6F, $7F, $7F, $1E
    .byte $5E, $6F, $61, $70, $1E
    .byte $5E, $6F, $6F, $7E, $1E
    .byte $5E, $6F, $77, $7E, $1E
    .byte $5E, $6F, $77, $78, $1E
    .byte $5E, $6F, $7B, $77, $1E
    .byte $5E, $6F, $7B, $77, $1E
    .byte $5E, $6F, $7D, $77, $1E
    .byte $5E, $6F, $7D, $78, $1E
    .byte $5E, $6F, $7F, $7F, $1E
    .byte $5E, $6F, $7F, $7F, $1E
    .byte $5E, $6F, $7F, $7F, $1E
    .byte $1E, $00, $00, $00, $1E
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $00, $00, $00, $00, $00

; Carte 14 : 14_ETAPE_50KM (200 octets, 5 octets x 40 lignes)
CARD_GFX_14
    .byte $00, $00, $00, $00, $00
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $D7, $AA, $FD, $1F
    .byte $7E, $D7, $AA, $F5, $1F
    .byte $7E, $D5, $AA, $F5, $1F
    .byte $7E, $D5, $AA, $D5, $1F
    .byte $BE, $D5, $AA, $D5, $1F
    .byte $BE, $D5, $AA, $D5, $1F
    .byte $BE, $D5, $AA, $D5, $9E
    .byte $BE, $D5, $AA, $D5, $9E
    .byte $5E, $6F, $7F, $7F, $1E
    .byte $5E, $6F, $7F, $7F, $1E
    .byte $5E, $6F, $7F, $7F, $1E
    .byte $5E, $6F, $7F, $7F, $1E
    .byte $5E, $6F, $61, $79, $1E
    .byte $5E, $6F, $7D, $76, $1E
    .byte $5E, $6F, $7D, $76, $1E
    .byte $5E, $6F, $71, $76, $1E
    .byte $5E, $6F, $6F, $76, $1E
    .byte $5E, $6F, $6F, $76, $1E
    .byte $5E, $6F, $6F, $76, $1E
    .byte $5E, $6F, $71, $79, $1E
    .byte $5E, $6F, $7F, $7F, $1E
    .byte $5E, $6F, $7F, $7F, $1E
    .byte $5E, $6F, $7F, $7F, $1E
    .byte $1E, $00, $00, $00, $1E
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $00, $00, $00, $00, $00

; Carte 15 : 15_ETAPE_25KM (200 octets, 5 octets x 40 lignes)
CARD_GFX_15
    .byte $00, $00, $00, $00, $00
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $D7, $AA, $FD, $1F
    .byte $7E, $D7, $AA, $F5, $1F
    .byte $7E, $D5, $AA, $F5, $1F
    .byte $7E, $D5, $AA, $D5, $1F
    .byte $BE, $D5, $AA, $D5, $1F
    .byte $BE, $D5, $AA, $D5, $1F
    .byte $BE, $D5, $AA, $D5, $9E
    .byte $BE, $D5, $AA, $D5, $9E
    .byte $5E, $6F, $7F, $7F, $1E
    .byte $5E, $6F, $7F, $7F, $1E
    .byte $5E, $6F, $7F, $7F, $1E
    .byte $5E, $6F, $7F, $7F, $1E
    .byte $5E, $6F, $73, $70, $1E
    .byte $5E, $6F, $6D, $7E, $1E
    .byte $5E, $6F, $6F, $7E, $1E
    .byte $5E, $6F, $6F, $78, $1E
    .byte $5E, $6F, $73, $77, $1E
    .byte $5E, $6F, $7D, $77, $1E
    .byte $5E, $6F, $7D, $77, $1E
    .byte $5E, $6F, $63, $78, $1E
    .byte $5E, $6F, $7F, $7F, $1E
    .byte $5E, $6F, $7F, $7F, $1E
    .byte $5E, $6F, $7F, $7F, $1E
    .byte $1E, $00, $00, $00, $1E
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $00, $00, $00, $00, $00

; Carte 16 : 16_CITERNE_ESSENCE (200 octets, 5 octets x 40 lignes)
CARD_GFX_16
    .byte $00, $00, $00, $00, $00
    .byte $2E, $6F, $7F, $7E, $1A
    .byte $5E, $6F, $7F, $7E, $1D
    .byte $06, $6E, $7F, $3E, $10
    .byte $5E, $6F, $7F, $7E, $1D
    .byte $2E, $6F, $7F, $7E, $1A
    .byte $7E, $1F, $3C, $7C, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $3F, $1C, $1E
    .byte $7E, $7F, $7F, $3E, $1F
    .byte $3E, $40, $1F, $00, $18
    .byte $1E, $00, $4F, $00, $12
    .byte $5E, $3F, $4F, $00, $12
    .byte $6E, $7F, $46, $00, $12
    .byte $6E, $7F, $46, $00, $12
    .byte $76, $7F, $45, $00, $12
    .byte $76, $5F, $41, $00, $12
    .byte $5A, $4F, $40, $00, $12
    .byte $32, $0F, $40, $00, $12
    .byte $40, $06, $48, $00, $12
    .byte $00, $00, $48, $00, $12
    .byte $00, $00, $58, $00, $1A
    .byte $02, $0C, $1E, $3F, $18
    .byte $02, $74, $05, $50, $17
    .byte $12, $78, $03, $60, $0F
    .byte $12, $18, $03, $60, $0C
    .byte $02, $18, $7B, $6F, $0C
    .byte $0E, $78, $7B, $6F, $0F
    .byte $7E, $77, $7D, $5F, $17
    .byte $7E, $0F, $7E, $3F, $18
    .byte $7E, $1F, $3C, $7C, $1F
    .byte $2E, $6F, $7F, $7E, $1A
    .byte $5E, $6F, $7F, $7E, $1D
    .byte $06, $6E, $7F, $3E, $10
    .byte $5E, $6F, $7F, $7E, $1D
    .byte $2E, $6F, $7F, $7E, $1A
    .byte $7E, $1F, $3C, $7C, $1F
    .byte $00, $00, $00, $00, $00

; Carte 17 : 17_AS_DU_VOLANT (200 octets, 5 octets x 40 lignes)
CARD_GFX_17
    .byte $00, $00, $00, $00, $00
    .byte $2E, $6F, $5D, $7B, $1A
    .byte $5E, $6F, $5D, $7B, $1D
    .byte $06, $0E, $5C, $3B, $10
    .byte $5E, $6F, $3D, $7D, $1D
    .byte $2E, $6F, $3D, $7D, $1A
    .byte $7E, $6F, $7D, $7E, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $0F, $7F, $1F
    .byte $7E, $7F, $07, $0C, $10
    .byte $7E, $7F, $03, $7C, $1F
    .byte $7E, $7F, $01, $18, $18
    .byte $7E, $7F, $01, $78, $1F
    .byte $7E, $5F, $3D, $78, $1F
    .byte $7E, $6F, $3D, $58, $1D
    .byte $7E, $6F, $01, $24, $13
    .byte $7E, $57, $03, $46, $1E
    .byte $7E, $33, $07, $01, $1D
    .byte $7E, $61, $7E, $01, $1E
    .byte $7E, $00, $00, $00, $1C
    .byte $3E, $00, $00, $00, $1C
    .byte $1E, $40, $07, $0F, $1C
    .byte $0E, $04, $0F, $0E, $12
    .byte $0E, $78, $75, $0B, $1D
    .byte $1E, $58, $33, $47, $1E
    .byte $3E, $38, $73, $26, $1F
    .byte $7E, $70, $63, $47, $1F
    .byte $7E, $4F, $1B, $77, $1F
    .byte $7E, $3F, $7C, $78, $1F
    .byte $7E, $1F, $5E, $7B, $1F
    .byte $2E, $6F, $5D, $7B, $1A
    .byte $5E, $6F, $5D, $7B, $1D
    .byte $06, $0E, $5C, $3B, $10
    .byte $5E, $6F, $3D, $7D, $1D
    .byte $2E, $6F, $3D, $7D, $1A
    .byte $7E, $6F, $7D, $7E, $1F
    .byte $00, $00, $00, $00, $00

; Carte 18 : 18_INCREVABLE (200 octets, 5 octets x 40 lignes)
CARD_GFX_18
    .byte $00, $00, $00, $00, $00
    .byte $2E, $3F, $1F, $7B, $1A
    .byte $5E, $3F, $5F, $7A, $1D
    .byte $06, $3E, $5F, $39, $10
    .byte $5E, $3F, $5F, $7B, $1D
    .byte $2E, $3F, $5F, $7B, $1A
    .byte $7E, $1F, $5E, $7B, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $7E, $7F, $00, $7F, $1F
    .byte $7E, $3F, $00, $7E, $1F
    .byte $7E, $3F, $7F, $7E, $1F
    .byte $7E, $5F, $7F, $7D, $1F
    .byte $7E, $5F, $7F, $7D, $1F
    .byte $7E, $6F, $7F, $7B, $1F
    .byte $7E, $6F, $3F, $73, $1F
    .byte $7E, $37, $1F, $01, $1F
    .byte $7E, $67, $1E, $00, $1E
    .byte $7E, $01, $0D, $00, $1C
    .byte $7E, $00, $00, $00, $1C
    .byte $3E, $00, $00, $00, $1C
    .byte $5E, $6F, $45, $68, $1D
    .byte $4E, $79, $3D, $5F, $19
    .byte $6E, $70, $18, $36, $1F
    .byte $3E, $60, $3D, $63, $1F
    .byte $7E, $31, $6F, $01, $1F
    .byte $3E, $1B, $46, $43, $1F
    .byte $7E, $3E, $6F, $67, $1F
    .byte $7E, $45, $08, $71, $1F
    .byte $7E, $1F, $5E, $7B, $1F
    .byte $2E, $3F, $1F, $7B, $1A
    .byte $5E, $3F, $5F, $7A, $1D
    .byte $06, $3E, $5F, $39, $10
    .byte $5E, $3F, $5F, $7B, $1D
    .byte $2E, $3F, $5F, $7B, $1A
    .byte $7E, $1F, $5E, $7B, $1F
    .byte $00, $00, $00, $00, $00

; Carte 19 : 19_VEHICULE_PRIORITAIRE (200 octets, 5 octets x 40 lignes)
CARD_GFX_19
    .byte $00, $00, $00, $00, $00
    .byte $2E, $6F, $5D, $7B, $1A
    .byte $5E, $6F, $5D, $7B, $1D
    .byte $06, $6E, $1D, $3C, $10
    .byte $5E, $5F, $5E, $7F, $1D
    .byte $2E, $5F, $5E, $7F, $1A
    .byte $7E, $3F, $5F, $7F, $1F
    .byte $7E, $7F, $7F, $7F, $1F
    .byte $5E, $56, $2A, $55, $1E
    .byte $0E, $00, $00, $00, $18
    .byte $6E, $6F, $7F, $5F, $1B
    .byte $7E, $6F, $7F, $5F, $17
    .byte $3E, $40, $7F, $5F, $1F
    .byte $1E, $00, $7F, $5E, $1B
    .byte $5E, $3F, $0E, $00, $18
    .byte $6E, $7F, $06, $00, $10
    .byte $6E, $7F, $16, $00, $14
    .byte $76, $7F, $55, $7F, $15
    .byte $76, $5F, $11, $00, $14
    .byte $5A, $4F, $00, $00, $10
    .byte $32, $0F, $10, $08, $11
    .byte $40, $06, $50, $4F, $13
    .byte $00, $00, $10, $68, $17
    .byte $00, $00, $00, $70, $0E
    .byte $02, $0C, $1E, $6C, $17
    .byte $02, $74, $6D, $4B, $1B
    .byte $12, $78, $73, $07, $1D
    .byte $12, $18, $33, $76, $1E
    .byte $02, $18, $33, $76, $1F
    .byte $0E, $78, $73, $77, $1F
    .byte $7E, $77, $6D, $7B, $1F
    .byte $7E, $0F, $1E, $7C, $1F
    .byte $7E, $6F, $1D, $7C, $1F
    .byte $2E, $6F, $5D, $7B, $1A
    .byte $5E, $6F, $5D, $7B, $1D
    .byte $06, $6E, $1D, $3C, $10
    .byte $5E, $5F, $5E, $7F, $1D
    .byte $2E, $5F, $5E, $7F, $1A
    .byte $7E, $3F, $5F, $7F, $1F
    .byte $00, $00, $00, $00, $00

; Carte 20 : 20_SLOT_EMPTY (Cadre vide, 200 octets)
CARD_GFX_20
    .byte $7F, $7F, $7F, $7F, $7F
    .byte $01, $00, $00, $00, $40
    .byte $01, $00, $00, $00, $40
    .byte $01, $00, $00, $00, $40
    .byte $01, $00, $00, $00, $40
    .byte $01, $00, $00, $00, $40
    .byte $01, $00, $00, $00, $40
    .byte $01, $00, $00, $00, $40
    .byte $01, $00, $00, $00, $40
    .byte $01, $00, $00, $00, $40
    .byte $01, $00, $00, $00, $40
    .byte $01, $00, $00, $00, $40
    .byte $01, $00, $00, $00, $40
    .byte $01, $00, $00, $00, $40
    .byte $01, $00, $00, $00, $40
    .byte $01, $00, $00, $00, $40
    .byte $01, $00, $00, $00, $40
    .byte $01, $00, $00, $00, $40
    .byte $01, $00, $00, $00, $40
    .byte $01, $00, $00, $00, $40
    .byte $01, $00, $00, $00, $40
    .byte $01, $00, $00, $00, $40
    .byte $01, $00, $00, $00, $40
    .byte $01, $00, $00, $00, $40
    .byte $01, $00, $00, $00, $40
    .byte $01, $00, $00, $00, $40
    .byte $01, $00, $00, $00, $40
    .byte $01, $00, $00, $00, $40
    .byte $01, $00, $00, $00, $40
    .byte $01, $00, $00, $00, $40
    .byte $01, $00, $00, $00, $40
    .byte $01, $00, $00, $00, $40
    .byte $01, $00, $00, $00, $40
    .byte $01, $00, $00, $00, $40
    .byte $01, $00, $00, $00, $40
    .byte $01, $00, $00, $00, $40
    .byte $01, $00, $00, $00, $40
    .byte $01, $00, $00, $00, $40
    .byte $01, $00, $00, $00, $40
    .byte $7F, $7F, $7F, $7F, $7F

; --- POLICE DE CARACTERES HGR 7x8 (128 caracteres x 8 octets = 1024 octets) ---
FONT_7X8
    ; Ch 0 (0)
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    ; Ch 1 (1)
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    ; Ch 2 (2)
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    ; Ch 3 (3)
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    ; Ch 4 (4)
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    ; Ch 5 (5)
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    ; Ch 6 (6)
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    ; Ch 7 (7)
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    ; Ch 8 (8)
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    ; Ch 9 (9)
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    ; Ch 10 (10)
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    ; Ch 11 (11)
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    ; Ch 12 (12)
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    ; Ch 13 (13)
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    ; Ch 14 (14)
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    ; Ch 15 (15)
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    ; Ch 16 (16)
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    ; Ch 17 (17)
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    ; Ch 18 (18)
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    ; Ch 19 (19)
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    ; Ch 20 (20)
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    ; Ch 21 (21)
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    ; Ch 22 (22)
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    ; Ch 23 (23)
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    ; Ch 24 (24)
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    ; Ch 25 (25)
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    ; Ch 26 (26)
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    ; Ch 27 (27)
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    ; Ch 28 (28)
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    ; Ch 29 (29)
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    ; Ch 30 (30)
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    ; Ch 31 (31)
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    ; Ch 32 (' ')
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    ; Ch 33 ('!')
    .byte $08, $08, $08, $08, $08, $00, $08, $00
    ; Ch 34 ('"')
    .byte $14, $14, $14, $00, $00, $00, $00, $00
    ; Ch 35 ('#')
    .byte $14, $14, $3E, $14, $3E, $14, $14, $00
    ; Ch 36 ('$')
    .byte $08, $3C, $0A, $1C, $28, $1E, $08, $00
    ; Ch 37 ('%')
    .byte $22, $12, $08, $04, $02, $24, $22, $00
    ; Ch 38 ('&')
    .byte $0C, $12, $0A, $04, $2A, $12, $2C, $00
    ; Ch 39 ("'")
    .byte $08, $08, $04, $00, $00, $00, $00, $00
    ; Ch 40 ('(')
    .byte $10, $08, $04, $04, $04, $08, $10, $00
    ; Ch 41 (')')
    .byte $04, $08, $10, $10, $10, $08, $04, $00
    ; Ch 42 ('*')
    .byte $00, $14, $08, $3E, $08, $14, $00, $00
    ; Ch 43 ('+')
    .byte $00, $08, $08, $3E, $08, $08, $00, $00
    ; Ch 44 (',')
    .byte $00, $00, $00, $00, $08, $08, $04, $00
    ; Ch 45 ('-')
    .byte $00, $00, $00, $3E, $00, $00, $00, $00
    ; Ch 46 ('.')
    .byte $00, $00, $00, $00, $00, $18, $18, $00
    ; Ch 47 ('/')
    .byte $20, $10, $08, $04, $02, $00, $00, $00
    ; Ch 48 ('0')
    .byte $1C, $22, $22, $22, $22, $22, $1C, $00
    ; Ch 49 ('1')
    .byte $08, $0C, $0A, $08, $08, $08, $3E, $00
    ; Ch 50 ('2')
    .byte $1C, $22, $20, $10, $08, $04, $3E, $00
    ; Ch 51 ('3')
    .byte $3E, $20, $10, $1C, $20, $22, $1C, $00
    ; Ch 52 ('4')
    .byte $10, $18, $14, $12, $3E, $10, $10, $00
    ; Ch 53 ('5')
    .byte $3E, $02, $1E, $20, $20, $22, $1C, $00
    ; Ch 54 ('6')
    .byte $1C, $02, $02, $1E, $22, $22, $1C, $00
    ; Ch 55 ('7')
    .byte $3E, $20, $10, $08, $04, $04, $04, $00
    ; Ch 56 ('8')
    .byte $1C, $22, $22, $1C, $22, $22, $1C, $00
    ; Ch 57 ('9')
    .byte $1C, $22, $22, $3C, $20, $20, $1C, $00
    ; Ch 58 (':')
    .byte $00, $18, $18, $00, $18, $18, $00, $00
    ; Ch 59 (';')
    .byte $00, $18, $18, $00, $08, $08, $04, $00
    ; Ch 60 ('<')
    .byte $20, $10, $08, $04, $08, $10, $20, $00
    ; Ch 61 ('=')
    .byte $00, $3E, $00, $3E, $00, $00, $00, $00
    ; Ch 62 ('>')
    .byte $02, $04, $08, $10, $08, $04, $02, $00
    ; Ch 63 ('?')
    .byte $1C, $22, $10, $08, $08, $00, $08, $00
    ; Ch 64 ('@')
    .byte $1C, $22, $3A, $2A, $3A, $02, $3C, $00
    ; Ch 65 ('A')
    .byte $1C, $22, $22, $3E, $22, $22, $22, $00
    ; Ch 66 ('B')
    .byte $1E, $22, $22, $1E, $22, $22, $1E, $00
    ; Ch 67 ('C')
    .byte $3C, $02, $02, $02, $02, $02, $3C, $00
    ; Ch 68 ('D')
    .byte $0E, $12, $22, $22, $22, $12, $0E, $00
    ; Ch 69 ('E')
    .byte $3E, $02, $02, $1E, $02, $02, $3E, $00
    ; Ch 70 ('F')
    .byte $3E, $02, $02, $1E, $02, $02, $02, $00
    ; Ch 71 ('G')
    .byte $3C, $02, $02, $3A, $22, $22, $3C, $00
    ; Ch 72 ('H')
    .byte $22, $22, $22, $3E, $22, $22, $22, $00
    ; Ch 73 ('I')
    .byte $1C, $08, $08, $08, $08, $08, $1C, $00
    ; Ch 74 ('J')
    .byte $30, $20, $20, $20, $20, $22, $1C, $00
    ; Ch 75 ('K')
    .byte $22, $12, $0A, $06, $0A, $12, $22, $00
    ; Ch 76 ('L')
    .byte $02, $02, $02, $02, $02, $02, $3E, $00
    ; Ch 77 ('M')
    .byte $22, $36, $2A, $22, $22, $22, $22, $00
    ; Ch 78 ('N')
    .byte $22, $26, $2A, $32, $22, $22, $22, $00
    ; Ch 79 ('O')
    .byte $1C, $22, $22, $22, $22, $22, $1C, $00
    ; Ch 80 ('P')
    .byte $1E, $22, $22, $1E, $02, $02, $02, $00
    ; Ch 81 ('Q')
    .byte $1C, $22, $22, $22, $32, $22, $5C, $00
    ; Ch 82 ('R')
    .byte $1E, $22, $22, $1E, $0A, $12, $22, $00
    ; Ch 83 ('S')
    .byte $3C, $02, $02, $1C, $20, $22, $1C, $00
    ; Ch 84 ('T')
    .byte $3E, $08, $08, $08, $08, $08, $08, $00
    ; Ch 85 ('U')
    .byte $22, $22, $22, $22, $22, $22, $1C, $00
    ; Ch 86 ('V')
    .byte $22, $22, $22, $22, $14, $14, $08, $00
    ; Ch 87 ('W')
    .byte $22, $22, $22, $2A, $2A, $36, $22, $00
    ; Ch 88 ('X')
    .byte $22, $22, $14, $08, $14, $22, $22, $00
    ; Ch 89 ('Y')
    .byte $22, $22, $14, $08, $08, $08, $08, $00
    ; Ch 90 ('Z')
    .byte $3E, $20, $10, $08, $04, $02, $3E, $00
    ; Ch 91 ('[')
    .byte $1C, $04, $04, $04, $04, $04, $1C, $00
    ; Ch 92 ('\\')
    .byte $02, $04, $08, $10, $20, $00, $00, $00
    ; Ch 93 (']')
    .byte $1C, $10, $10, $10, $10, $10, $1C, $00
    ; Ch 94 ('^')
    .byte $08, $14, $22, $00, $00, $00, $00, $00
    ; Ch 95 ('_')
    .byte $00, $00, $00, $00, $00, $00, $3E, $00
    ; Ch 96 ('`')
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    ; Ch 97 ('a')
    .byte $00, $00, $1C, $20, $3C, $22, $3C, $00
    ; Ch 98 ('b')
    .byte $02, $02, $1E, $22, $22, $22, $1E, $00
    ; Ch 99 ('c')
    .byte $00, $00, $3C, $02, $02, $02, $3C, $00
    ; Ch 100 ('d')
    .byte $20, $20, $3C, $22, $22, $22, $3C, $00
    ; Ch 101 ('e')
    .byte $00, $00, $1C, $22, $3E, $02, $3C, $00
    ; Ch 102 ('f')
    .byte $18, $24, $04, $0E, $04, $04, $04, $00
    ; Ch 103 ('g')
    .byte $00, $00, $3C, $22, $22, $3C, $20, $1C
    ; Ch 104 ('h')
    .byte $02, $02, $1E, $22, $22, $22, $22, $00
    ; Ch 105 ('i')
    .byte $08, $00, $0C, $08, $08, $08, $1C, $00
    ; Ch 106 ('j')
    .byte $10, $00, $18, $10, $10, $12, $0C, $00
    ; Ch 107 ('k')
    .byte $02, $02, $12, $0A, $06, $0A, $12, $00
    ; Ch 108 ('l')
    .byte $0C, $08, $08, $08, $08, $08, $1C, $00
    ; Ch 109 ('m')
    .byte $00, $00, $36, $2A, $2A, $22, $22, $00
    ; Ch 110 ('n')
    .byte $00, $00, $1E, $22, $22, $22, $22, $00
    ; Ch 111 ('o')
    .byte $00, $00, $1C, $22, $22, $22, $1C, $00
    ; Ch 112 ('p')
    .byte $00, $00, $1E, $22, $22, $1E, $02, $02
    ; Ch 113 ('q')
    .byte $00, $00, $3C, $22, $22, $3C, $20, $20
    ; Ch 114 ('r')
    .byte $00, $00, $3A, $26, $02, $02, $02, $00
    ; Ch 115 ('s')
    .byte $00, $00, $3C, $02, $1C, $20, $1E, $00
    ; Ch 116 ('t')
    .byte $04, $04, $0E, $04, $04, $24, $18, $00
    ; Ch 117 ('u')
    .byte $00, $00, $22, $22, $22, $32, $2C, $00
    ; Ch 118 ('v')
    .byte $00, $00, $22, $22, $14, $14, $08, $00
    ; Ch 119 ('w')
    .byte $00, $00, $22, $22, $2A, $2A, $14, $00
    ; Ch 120 ('x')
    .byte $00, $00, $22, $14, $08, $14, $22, $00
    ; Ch 121 ('y')
    .byte $00, $00, $22, $22, $3C, $20, $1C, $00
    ; Ch 122 ('z')
    .byte $00, $00, $3E, $10, $08, $04, $3E, $00
    ; Ch 123 ('{')
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    ; Ch 124 ('|')
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    ; Ch 125 ('}')
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    ; Ch 126 ('~')
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    ; Ch 127 (127)
    .byte $00, $00, $00, $00, $00, $00, $00, $00
