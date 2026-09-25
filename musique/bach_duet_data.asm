; ===================================================================
; PARTITIONS AU FORMAT ELECTRIC DUET (PAUL LUTUS)
; Format : .byte DUREE, PERIODE_VOIX1, PERIODE_VOIX2
; Termine par .byte $00, $00, $00
; ===================================================================

; ===================================================================
; 1. J.S. BACH - FUGA II EN DO MINEUR (BWV 847) COMPLETE
; 31 mesures completes du Clavecin bien tempere (Livre 1, 1722)
; Sujet Alto, Reponse Soprano, Entree Basse, 4 episodes, Climax Picardie
; 397 evenements
; Format : .byte DUREE, PERIODE_VOIX1, PERIODE_VOIX2
; ===================================================================
BWV847_SCORE:
    .byte  18,   0,   0
    .byte   9,   0,  24
    .byte   9,   0,  26
    .byte  18,   0,  24
    .byte  18,   0,  32
    .byte  18,   0,  30
    .byte   9,   0,  24
    .byte   9,   0,  26
    .byte  18,   0,  24
    .byte  18,   0,  21
    .byte  18,   0,  32
    .byte   9,   0,  24
    .byte   9,   0,  26
    .byte  18,   0,  24
    .byte  18,   0,  21
    .byte   9,   0,  36
    .byte   9,   0,  32
    .byte  36,   0,  30
    .byte   9,   0,  32
    .byte   9,   0,  36
    .byte   9,  40,   0
    .byte   9,  24,   0
    .byte   9,  16,  26
    .byte   9,  17,  29
    .byte   9,  16,  32
    .byte   9,  16,  36
    .byte   9,  24,  40
    .byte   9,  24,  43
    .byte  18,  20,  48
    .byte   9,  16,  20
    .byte   9,  17,  20
    .byte  18,  16,  21
    .byte  18,  14,  24
    .byte  18,  21,  27
    .byte   9,  16,  29
    .byte   9,  17,  29
    .byte  18,  16,  27
    .byte  18,  14,  24
    .byte   9,  24,  34
    .byte   9,  21,  34
    .byte  18,  20,  32
    .byte  18,  20,  29
    .byte   9,  21,  34
    .byte   9,  24,  34
    .byte  18,  27,  32
    .byte   9,  20,  32
    .byte   9,  21,  32
    .byte   9,  20,   0
    .byte   9,  20,  48
    .byte   9,  32,  43
    .byte   9,  32,  40
    .byte   9,  30,  36
    .byte   9,  30,  32
    .byte   9,  18,  30
    .byte   9,  20,  30
    .byte   9,  18,  30
    .byte   9,  18,  43
    .byte   9,  29,  40
    .byte   9,  29,  36
    .byte   9,  27,  32
    .byte   9,  27,  29
    .byte   9,  16,  27
    .byte   9,  18,  27
    .byte   9,  16,  27
    .byte   9,  16,  40
    .byte   9,  26,  36
    .byte   9,  26,  32
    .byte   9,  24,  30
    .byte   9,  24,  32
    .byte   9,  21,  36
    .byte   9,  20,  40
    .byte  18,  18,  43
    .byte   9,  18,  24
    .byte   9,  18,  26
    .byte  18,  18,  24
    .byte   9,  20,  48
    .byte   9,  21,  51
    .byte   9,  24,  48
    .byte   9,  27,  48
    .byte   9,  30,  64
    .byte   9,  32,  64
    .byte  18,  36,  61
    .byte   9,  15,  48
    .byte   9,  15,  51
    .byte  18,  16,  48
    .byte  18,  18,  43
    .byte  18,  20,  64
    .byte   9,  21,  48
    .byte   9,  21,  51
    .byte  18,  20,  48
    .byte  18,  18,  43
    .byte   9,  26,  72
    .byte   9,  26,  64
    .byte  18,  24,  61
    .byte  18,  21,  61
    .byte   9,  26,  64
    .byte   9,  26,  72
    .byte   9,  24,  81
    .byte   9,  24,  48
    .byte   9,  16,  51
    .byte   9,  17,  57
    .byte   9,  16,  64
    .byte   9,  16,  72
    .byte   9,  21,  81
    .byte   9,  21,  86
    .byte   9,  20,  96
    .byte   9,  20,  86
    .byte   9,  20,  81
    .byte   9,  20,  86
    .byte   9,  24,  96
    .byte   9,  24,  54
    .byte   9,  19,  60
    .byte   9,  19,  64
    .byte   9,  18,  72
    .byte   9,  18,  54
    .byte   9,  18,  61
    .byte   9,  19,  64
    .byte   9,  18,  72
    .byte   9,  18,  81
    .byte   9,  24,  86
    .byte   9,  24,  96
    .byte   9,  21,  54
    .byte   9,  21,  96
    .byte   9,  21,  86
    .byte   9,  21,  96
    .byte   9,  27,  54
    .byte   9,  27,  60
    .byte   9,  21,  64
    .byte   9,  21,  72
    .byte   9,  20,  81
    .byte   9,  20,  61
    .byte   9,  20,  64
    .byte   9,  21,  72
    .byte   9,  20,  81
    .byte   9,  20,  91
    .byte   9,  27,  96
    .byte   9,  27,  54
    .byte  18,  24,  60
    .byte   9,  20,  48
    .byte   9,  21,  48
    .byte  18,  20,  54
    .byte  18,  18,  61
    .byte  18,  27,  64
    .byte   9,  20,  72
    .byte   9,  21,  72
    .byte  18,  20,  64
    .byte  18,  18,  61
    .byte   9,  30,  86
    .byte   9,  27,  86
    .byte  18,  24,  81
    .byte  18,  24,  72
    .byte   9,  27,  86
    .byte   9,  30,  86
    .byte   9,  32,  81
    .byte   9,  40,  81
    .byte   9,  36,  61
    .byte   9,  32,  61
    .byte   9,  30,  64
    .byte   9,  27,  64
    .byte   9,  24,  72
    .byte   9,  21,  72
    .byte   9,  20,  64
    .byte   9,  21,  64
    .byte   9,  24,  81
    .byte   9,  21,  81
    .byte   9,  20,  86
    .byte   9,  18,  86
    .byte   9,  16,  96
    .byte   9,  14,  96
    .byte   9,  14,  86
    .byte   9,  36,  86
    .byte   9,  32,  54
    .byte   9,  30,  54
    .byte   9,  27,  61
    .byte   9,  24,  61
    .byte   9,  21,  64
    .byte   9,  19,  64
    .byte   9,  18,  61
    .byte   9,  20,  61
    .byte   9,  21,  72
    .byte   9,  20,  72
    .byte   9,  18,  81
    .byte   9,  16,  81
    .byte   9,  14,  86
    .byte   9,  13,  86
    .byte  18,  12,  81
    .byte   9,  13,  32
    .byte   9,  14,  34
    .byte   9,  16,  32
    .byte   9,  18,  32
    .byte   9,  20,  48
    .byte   9,  21,  48
    .byte  18,  24,  40
    .byte  18,  20,  96
    .byte  18,  21,  54
    .byte  18,  24,  57
    .byte  18,  27,  43
    .byte  18,  29,  81
    .byte  18,  27,  86
    .byte  18,  24,  96
    .byte  18,  34,  86
    .byte   9,  32,  96
    .byte   9,  32,  54
    .byte  18,  29,  96
    .byte  18,  34,  86
    .byte  18,  32,  64
    .byte   9,  21,  54
    .byte   9,  24,  57
    .byte  18,  21,  54
    .byte   9,  38,  86
    .byte   9,  34,  86
    .byte   9,  32,  81
    .byte   9,  29,  81
    .byte   9,  19,  48
    .byte   9,  21,  54
    .byte  18,  19,  48
    .byte   9,  36,  76
    .byte   9,  32,  76
    .byte   9,  29,  72
    .byte   9,  27,  72
    .byte   9,  17,  43
    .byte   9,  19,  48
    .byte  18,  17,  43
    .byte   9,  32,  68
    .byte   9,  29,  68
    .byte  18,  27,  64
    .byte   9,  32,  64
    .byte   9,  36,  64
    .byte   9,  32,  40
    .byte   9,  32,  64
    .byte   9,  64,  57
    .byte   9,  64,  51
    .byte   9,  61,  96
    .byte   9,  61,  86
    .byte   9,  29,  81
    .byte   9,  32,  81
    .byte   9,  29,  81
    .byte   9,  29,  57
    .byte   9,  57,  54
    .byte   9,  57,  96
    .byte   9,  54,  86
    .byte   9,  54,  81
    .byte   9,  26,  72
    .byte   9,  29,  72
    .byte   9,  26,  72
    .byte   9,  26,  51
    .byte   9,  51,  96
    .byte   9,  51,  86
    .byte   9,  48,  81
    .byte   9,  36,  81
    .byte   9,  24,  40
    .byte   9,  26,  43
    .byte   9,  24,  48
    .byte   9,  24,  54
    .byte  18,  32,  76
    .byte  18,  30,  72
    .byte   9,  24,  72
    .byte   9,  26,  72
    .byte  18,  24,  81
    .byte  18,  21,  86
    .byte  18,  32,  40
    .byte   9,  24,  60
    .byte   9,  26,  60
    .byte  18,  24,  64
    .byte  18,  21,  72
    .byte   9,  36,  64
    .byte   9,  32,  64
    .byte   9,  30,  72
    .byte   9,  30,  81
    .byte  18,  30,  72
    .byte   9,  32,  64
    .byte   9,  36,  64
    .byte   9,  40,  96
    .byte   9,  40,  86
    .byte   9,  24,  81
    .byte   9,  26,  86
    .byte   9,  24,  96
    .byte   9,  24,  54
    .byte   9,  32,  60
    .byte   9,  32,  64
    .byte   9,  30,  72
    .byte   9,  30,  54
    .byte   9,  30,  61
    .byte   9,  30,  64
    .byte   9,  36,  72
    .byte   9,  36,  81
    .byte   9,  29,  86
    .byte   9,  29,  96
    .byte   9,  27,  54
    .byte   9,  27,  96
    .byte   9,  27,  86
    .byte   9,  29,  96
    .byte   9,  27,  54
    .byte   9,  27,  60
    .byte   9,  36,  64
    .byte   9,  36,  72
    .byte   9,  32,  81
    .byte   9,  32,  61
    .byte   9,  32,  64
    .byte   9,  32,  72
    .byte   9,  40,  81
    .byte   9,  40,  86
    .byte   9,  32,  96
    .byte   9,  32,  54
    .byte   9,  32,  60
    .byte   9,  32,  54
    .byte   9,  30,  96
    .byte   9,  27,  54
    .byte   9,  24,  60
    .byte   9,  26,  64
    .byte   9,  24,  72
    .byte   9,  30,  81
    .byte   9,  36,  86
    .byte   9,  36,  64
    .byte   9,  36,  72
    .byte   9,  36,  81
    .byte   9,  36,  86
    .byte   9,  36,  96
    .byte   9,  36,  51
    .byte   9,  36,  57
    .byte  18,  36,  64
    .byte   9,  21,  64
    .byte   9,  24,  64
    .byte  18,  21,   0
    .byte  18,  36,  51
    .byte   9,  40,  48
    .byte   9,  40,  64
    .byte   9,  20,  57
    .byte   9,  21,  51
    .byte   9,  20,  96
    .byte   9,  20,  86
    .byte   9,  32,  81
    .byte   9,  32,  72
    .byte   9,  36,  64
    .byte   9,  36,  72
    .byte   9,  18,  61
    .byte   9,  20,  64
    .byte   9,  18,  72
    .byte   9,  18,  81
    .byte   9,  30,  86
    .byte   9,  30,  96
    .byte   9,  32,  51
    .byte   9,  18,  51
    .byte   9,  20,  96
    .byte   9,  21,  51
    .byte   9,  24,  96
    .byte   9,  26,  96
    .byte   9,  29,  64
    .byte   9,  32,  64
    .byte  18,  24,  60
    .byte   9,  18,  96
    .byte   9,  18,  51
    .byte  18,  20,  96
    .byte  18,  21,  86
    .byte  18,  40,  64
    .byte   9,  30,  96
    .byte   9,  30,  51
    .byte  18,  32,  96
    .byte  18,  36,  86
    .byte   9,  32,  72
    .byte   9,  32,  64
    .byte   9,  36,  60
    .byte   9,  40,  60
    .byte  18,  36,  60
    .byte   9,  43,  64
    .byte   9,  43,  72
    .byte  18,  30,  81
    .byte  18,  32,  81
    .byte  18,   0,   0
    .byte  18,  29,  81
    .byte  18,  26,  86
    .byte  18,  24,  96
    .byte   9,  36,  64
    .byte   9,  40,  64
    .byte   9,  43,  64
    .byte   9,  48,  64
    .byte  18,  48,  96
    .byte   9,  24,  96
    .byte   9,  26,  96
    .byte  18,  24,  96
    .byte  18,  32,  96
    .byte  18,  30,  96
    .byte   9,  24,  96
    .byte   9,  26,  96
    .byte  18,  24,  96
    .byte  18,  21,  96
    .byte  18,  32,  96
    .byte   9,  24,  96
    .byte   9,  26,  96
    .byte  18,  24,  96
    .byte  18,  21,  96
    .byte   9,  36,  96
    .byte   9,  32,  96
    .byte  36,  30,  96
    .byte   9,  32,  96
    .byte   9,  36,  96
    .byte  72,  38,  96
    .byte   0,   0,   0 ; Fin de partition

; ===================================================================
; 2. TOMASO ALBINONI / R. GIAZOTTO - ADAGIO EN SOL MINEUR
; Chef-d'oeuvre baroque pour violon solo expressif et basse d'orgue
; Duree > 90 secondes (~1.5 min), 32 mesures a ~83 BPM
; 80 evenements
; Format : .byte DUREE, PERIODE_VOIX1, PERIODE_VOIX2
; ===================================================================
ALBINONI_SCORE:
    .byte  58,   0, 128
    .byte  58,   0,  64
    .byte  59,   0, 128
    .byte  58,  21, 128
    .byte  44,  24,  64
    .byte  14,  27,  64
    .byte  44,  29, 128
    .byte  14,  32, 128
    .byte  59,  32, 114
    .byte  58,  32,  57
    .byte  58,  34, 114
    .byte  58,  20, 114
    .byte  44,  21,  57
    .byte  14,  24,  57
    .byte  44,  27, 114
    .byte  15,  29, 114
    .byte  58,  29, 108
    .byte  58,  29,  54
    .byte  58,  32, 108
    .byte  59,  16, 108
    .byte  29,  18,  54
    .byte  29,  16,  54
    .byte  19,  20, 108
    .byte  20,  18, 108
    .byte  19,  21, 108
    .byte  58,  20,  96
    .byte  58,  20,  48
    .byte  59,  20,  96
    .byte  58,  18, 114
    .byte  29,  20,  57
    .byte  29,  18,  57
    .byte  20,  21, 114
    .byte  19,  20, 114
    .byte  19,  24, 114
    .byte  59,  21, 108
    .byte  58,  21,  54
    .byte  58,  21, 108
    .byte  58,  20, 128
    .byte  29,  21,  64
    .byte  29,  20,  64
    .byte  20,  24, 128
    .byte  19,  21, 128
    .byte  20,  27, 128
    .byte  58,  24, 114
    .byte  58,  24,  57
    .byte  58,  24, 114
    .byte  59,  21, 108
    .byte  58,  21,  54
    .byte  58,  20,  96
    .byte 175,  21,  86
    .byte 116,  21,  86
    .byte  29,   0,  86
    .byte  29,  16,  86
    .byte  29,  14,  86
    .byte  30,  13,  86
    .byte  29,  14,  86
    .byte  29,  16,  86
    .byte  29,  17,  86
    .byte  29,  16,  86
    .byte  58,  18, 102
    .byte  58,  18,  51
    .byte  59,  18, 102
    .byte  58,  20,  96
    .byte  29,  20,  48
    .byte  29,  24,  48
    .byte  44,  20,  96
    .byte  14,  16,  96
    .byte  59,  21, 108
    .byte  29,  21,  54
    .byte  29,  27,  54
    .byte  43,  21, 108
    .byte  15,  16, 108
    .byte  58,  24, 121
    .byte  58,  24,  60
    .byte  59,  24, 121
    .byte 174,  27,  86
    .byte 175,  29,  86
    .byte  58,  32, 128
    .byte  58,  32,  64
    .byte  59,  32, 128
    .byte   0,   0,   0 ; Fin de partition

HEYJUDE_SCORE:
    .byte  16,   0,   0 ; V1=REST  V2=REST 
    .byte  32,  48,   0 ; V1=C4    V2=REST 
    .byte  32,  57,  72 ; V1=A3    V2=F3   
    .byte  32,  57,  96 ; V1=A3    V2=C3   
    .byte  16,  57, 115 ; V1=A3    V2=A2   
    .byte  16,  48, 115 ; V1=C4    V2=A2   
    .byte  32,  43,  96 ; V1=D4    V2=C3   
    .byte  32,  64,  76 ; V1=G3    V2=E3   
    .byte  32,  64,  96 ; V1=G3    V2=C3   
    .byte  32,  64, 129 ; V1=G3    V2=G2   
    .byte  32,   0,  96 ; V1=REST  V2=C3   
    .byte  16,  64,  76 ; V1=G3    V2=E3   
    .byte  16,  57,  76 ; V1=A3    V2=E3   
    .byte  32,  54,  64 ; V1=Bb3   V2=G3   
    .byte  32,  36,  54 ; V1=F4    V2=Bb3  
    .byte  16,  38,  96 ; V1=E4    V2=C3   
    .byte  16,  48,  96 ; V1=C4    V2=C3   
    .byte  16,  43,  72 ; V1=D4    V2=F3   
    .byte  16,  48,  72 ; V1=C4    V2=F3   
    .byte  32,  54,  96 ; V1=Bb3   V2=C3   
    .byte  32,  57, 115 ; V1=A3    V2=A2   
    .byte  32,  57,  96 ; V1=A3    V2=C3   
    .byte  32,  48,  86 ; V1=C4    V2=D3   
    .byte  24,  43, 108 ; V1=D4    V2=Bb2  
    .byte   8,  43, 108 ; V1=D4    V2=Bb2  
    .byte  16,  43, 144 ; V1=D4    V2=F2   
    .byte  16,  43, 144 ; V1=D4    V2=F2   
    .byte  16,  36, 108 ; V1=F4    V2=Bb2  
    .byte  16,  38, 108 ; V1=E4    V2=Bb2  
    .byte  16,  43,  72 ; V1=D4    V2=F3   
    .byte  16,  48,  72 ; V1=C4    V2=F3   
    .byte  16,  72,  96 ; V1=F3    V2=C3   
    .byte  16,  57,  96 ; V1=A3    V2=C3   
    .byte  32,  48, 115 ; V1=C4    V2=A2   
    .byte  32,  48, 144 ; V1=C4    V2=F2   
    .byte  16,  43, 129 ; V1=D4    V2=G2   
    .byte  16,  48, 129 ; V1=C4    V2=G2   
    .byte  16,  54,  96 ; V1=Bb3   V2=C3   
    .byte  16,  57,  96 ; V1=A3    V2=C3   
    .byte  16,  64,  76 ; V1=G3    V2=E3   
    .byte  16,  57,  76 ; V1=A3    V2=E3   
    .byte  16,  64,  96 ; V1=G3    V2=C3   
    .byte  16,  96,  96 ; V1=C3    V2=C3   
    .byte  32,  72, 144 ; V1=F3    V2=F2   
    .byte  32,  72,  96 ; V1=F3    V2=C3   
    .byte  32,  72,  72 ; V1=F3    V2=F3   
    .byte  32,  72,  96 ; V1=F3    V2=C3   
    .byte  64,  36,  48 ; Naaaaaa (F4/C4)
    .byte  32,  29,  36 ; na (A4/F4)
    .byte  32,  24,  29 ; na (C5/A4)
    .byte   8,  16,  20 ; na- (G5/Eb5)
    .byte   8,  18,  21 ; -na- (F5/D5)
    .byte  16,  16,  20 ; -na- (G5/Eb5)
    .byte  96,  18,  21 ; naaaaa (F5/D5)
    .byte   8,  16,  20 ; na- (G5/Eb5)
    .byte   8,  18,  21 ; -na- (F5/D5)
    .byte  16,  16,  21 ; -na- (G5/D5)
    .byte  64,  18,  21 ; naaaaa (F5/D5)
    .byte  16,  20,  24 ; Hey (Eb5/C5)
    .byte  16,  21,  27 ; Jude (D5/Bb4)
    .byte 128,  24,  29 ; Juuuuude (C5/A4)
    .byte  64,  36,  48 ; Naaaaaa (F4/C4)
    .byte  32,  29,  36 ; na (A4/F4)
    .byte  32,  24,  29 ; na (C5/A4)
    .byte   8,  16,  20 ; na- (G5/Eb5)
    .byte   8,  18,  21 ; -na- (F5/D5)
    .byte  16,  16,  20 ; -na- (G5/Eb5)
    .byte  96,  18,  21 ; naaaaa (F5/D5)
    .byte   8,  16,  20 ; na- (G5/Eb5)
    .byte   8,  18,  21 ; -na- (F5/D5)
    .byte  16,  16,  21 ; -na- (G5/D5)
    .byte  64,  18,  21 ; naaaaa (F5/D5)
    .byte  16,  20,  24 ; Hey (Eb5/C5)
    .byte  16,  21,  27 ; Jude (D5/Bb4)
    .byte 128,  24,  29 ; Juuuuude (C5/A4)
    .byte  64,  36,  48 ; Naaaaaa (F4/C4)
    .byte  32,  29,  36 ; na (A4/F4)
    .byte  32,  24,  29 ; na (C5/A4)
    .byte   8,  16,  20 ; na- (G5/Eb5)
    .byte   8,  18,  21 ; -na- (F5/D5)
    .byte  16,  16,  20 ; -na- (G5/Eb5)
    .byte  96,  18,  21 ; naaaaa (F5/D5)
    .byte   8,  16,  20 ; na- (G5/Eb5)
    .byte   8,  18,  21 ; -na- (F5/D5)
    .byte  16,  16,  21 ; -na- (G5/D5)
    .byte  64,  18,  21 ; naaaaa (F5/D5)
    .byte  16,  20,  24 ; Hey (Eb5/C5)
    .byte  16,  21,  27 ; Jude (D5/Bb4)
    .byte 128,  24,  29 ; Juuuuude (C5/A4)
    .byte  64,  36,  48 ; Naaaaaa (F4/C4)
    .byte  32,  29,  36 ; na (A4/F4)
    .byte  32,  24,  29 ; na (C5/A4)
    .byte   8,  16,  20 ; na- (G5/Eb5)
    .byte   8,  18,  21 ; -na- (F5/D5)
    .byte  16,  16,  20 ; -na- (G5/Eb5)
    .byte  96,  18,  21 ; naaaaa (F5/D5)
    .byte   8,  16,  20 ; na- (G5/Eb5)
    .byte   8,  18,  21 ; -na- (F5/D5)
    .byte  16,  16,  21 ; -na- (G5/D5)
    .byte  64,  18,  21 ; naaaaa (F5/D5)
    .byte  16,  20,  24 ; Hey (Eb5/C5)
    .byte  16,  21,  27 ; Jude (D5/Bb4)
    .byte 128,  24,  29 ; Juuuuude (C5/A4)
    .byte  64,  36,  48 ; Naaaaaa (F4/C4)
    .byte  32,  29,  36 ; na (A4/F4)
    .byte  32,  24,  29 ; na (C5/A4)
    .byte   8,  16,  20 ; na- (G5/Eb5)
    .byte   8,  18,  21 ; -na- (F5/D5)
    .byte  16,  16,  20 ; -na- (G5/Eb5)
    .byte  96,  18,  21 ; naaaaa (F5/D5)
    .byte   8,  16,  20 ; na- (G5/Eb5)
    .byte   8,  18,  21 ; -na- (F5/D5)
    .byte  16,  16,  21 ; -na- (G5/D5)
    .byte  64,  18,  21 ; naaaaa (F5/D5)
    .byte  16,  20,  24 ; Hey (Eb5/C5)
    .byte  16,  21,  27 ; Jude (D5/Bb4)
    .byte 128,  24,  29 ; Juuuuude (C5/A4)
    .byte  64,  36,  48 ; Naaaaaa (F4/C4)
    .byte  32,  29,  36 ; na (A4/F4)
    .byte  32,  24,  29 ; na (C5/A4)
    .byte   8,  16,  20 ; na- (G5/Eb5)
    .byte   8,  18,  21 ; -na- (F5/D5)
    .byte  16,  16,  20 ; -na- (G5/Eb5)
    .byte  96,  18,  21 ; naaaaa (F5/D5)
    .byte   8,  16,  20 ; na- (G5/Eb5)
    .byte   8,  18,  21 ; -na- (F5/D5)
    .byte  16,  16,  21 ; -na- (G5/D5)
    .byte  64,  18,  21 ; naaaaa (F5/D5)
    .byte  16,  20,  24 ; Hey (Eb5/C5)
    .byte  16,  21,  27 ; Jude (D5/Bb4)
    .byte 128,  24,  29 ; Juuuuude (C5/A4)
    .byte 128,  36,  48 ; Accord final F (F4/C4)
    .byte   0,   0,   0 ; Fin de partition

; ===================================================================
; THE BEATLES - LET IT BE (PAUL MCCARTNEY, 1970)
; Arrangement 100% CHANT PUR (sans intro, duo vocal harm 3ce)
; Couplet 1 + Couplet 2 + Refrain complet + Cadence
; 89 evenements
; Format : .byte DUREE, PERIODE_VOIX1, PERIODE_VOIX2
; ===================================================================

LETITBE_SCORE:
    .byte  10,  64,  76 ; When (G3/E3)
    .byte  10,  64,  76 ; I (G3/E3)
    .byte  20,  64,  76 ; find (G3/E3)
    .byte  10,  64,  76 ; my- (G3/E3)
    .byte  20,  57,  72 ; self (A3/F3)
    .byte  20,  76,  96 ; in (E3/C3)
    .byte  30,  64,  76 ; times (G3/E3)
    .byte  20,  64,  76 ; of (G3/E3)
    .byte  10,  48,  64 ; trou- (C4/G3)
    .byte  30,  43,  51 ; ble, (D4/B3)
    .byte  10,  38,  48 ; Mo- (E4/C4)
    .byte  10,  38,  48 ; ther (E4/C4)
    .byte  40,  38,  48 ; Ma- (E4/C4)
    .byte  10,  43,  51 ; ry (D4/B3)
    .byte  20,  43,  51 ; comes (D4/B3)
    .byte  10,  48,  57 ; to (C4/A3)
    .byte  40,  48,  57 ; me (C4/A3)
    .byte  10,   0,   0 ; silence
    .byte  10,  38,  48 ; spea- (E4/C4)
    .byte  30,  38,  48 ; king (E4/C4)
    .byte  20,  36,  43 ; words (F4/D4)
    .byte  10,  38,  48 ; of (E4/C4)
    .byte  20,  38,  48 ; wis- (E4/C4)
    .byte  30,  43,  51 ; dom, (D4/B3)
    .byte  10,   0,   0 ; silence
    .byte  10,  38,  48 ; let (E4/C4)
    .byte  10,  43,  51 ; it (D4/B3)
    .byte  20,  43,  57 ; be (D4/A3)
    .byte  80,  48,  64 ; . (C4/G3)
    .byte  20,   0,   0 ; respiration
    .byte  10,  64,  76 ; And (G3/E3)
    .byte  20,  64,  76 ; in (G3/E3)
    .byte  10,  64,  76 ; my (G3/E3)
    .byte  20,  57,  72 ; hour (A3/F3)
    .byte  20,  76,  96 ; of (E3/C3)
    .byte  30,  64,  76 ; dark- (G3/E3)
    .byte  20,  64,  76 ; ness (G3/E3)
    .byte  10,  48,  64 ; she (C4/G3)
    .byte  30,  43,  51 ; is (D4/B3)
    .byte  10,  38,  48 ; stan- (E4/C4)
    .byte  10,  38,  48 ; ding (E4/C4)
    .byte  40,  38,  48 ; right (E4/C4)
    .byte  10,  43,  51 ; in (D4/B3)
    .byte  20,  43,  51 ; front (D4/B3)
    .byte  10,  48,  57 ; of (C4/A3)
    .byte  40,  48,  57 ; me (C4/A3)
    .byte  10,   0,   0 ; silence
    .byte  10,  38,  48 ; spea- (E4/C4)
    .byte  30,  38,  48 ; king (E4/C4)
    .byte  20,  36,  43 ; words (F4/D4)
    .byte  10,  38,  48 ; of (E4/C4)
    .byte  20,  38,  48 ; wis- (E4/C4)
    .byte  30,  43,  51 ; dom, (D4/B3)
    .byte  10,   0,   0 ; silence
    .byte  10,  38,  48 ; let (E4/C4)
    .byte  10,  43,  51 ; it (D4/B3)
    .byte  20,  43,  57 ; be (D4/A3)
    .byte  80,  48,  64 ; . (C4/G3)
    .byte  20,   0,   0 ; respiration
    .byte  10,  38,  48 ; Let (E4/C4)
    .byte  20,  43,  51 ; it (D4/B3)
    .byte  50,  48,  57 ; be, (C4/A3)
    .byte  10,  38,  48 ; let (E4/C4)
    .byte  20,  32,  38 ; it (G4/E4)
    .byte  50,  29,  36 ; be, (A4/F4)
    .byte  10,  32,  38 ; let (G4/E4)
    .byte  10,  32,  38 ; it (G4/E4)
    .byte  10,  38,  48 ; be, (E4/C4)
    .byte  10,  43,  51 ; yeah (D4/B3)
    .byte  40,  48,  57 ; let (C4/A3)
    .byte  10,  57,  72 ; it (A3/F3)
    .byte  20,  64,  76 ; be (G3/E3)
    .byte  70,  38,  48 ; . (E4/C4)
    .byte  10,   0,   0 ; silence
    .byte  10,  38,  48 ; Whis- (E4/C4)
    .byte  10,  38,  48 ; per (E4/C4)
    .byte  10,  38,  48 ; words (E4/C4)
    .byte  20,  36,  43 ; of (F4/D4)
    .byte  10,  38,  48 ; wis- (E4/C4)
    .byte  10,  38,  48 ; dom, (E4/C4)
    .byte  40,  43,  51 ; -- (D4/B3)
    .byte  10,  38,  48 ; let (E4/C4)
    .byte  10,  43,  51 ; it (D4/B3)
    .byte  20,  43,  57 ; be (D4/A3)
    .byte  70,  48,  64 ; . (C4/G3)
    .byte  20,  36,  57 ; Cadence F (F4/A3)
    .byte  20,  38,  64 ; Cadence Em (E4/G3)
    .byte  20,  43,  72 ; Cadence Dm (D4/F3)
    .byte  90,  48,  76 ; Accord final C (C4/E3)
    .byte   0,   0,   0 ; Fin de partition

IWANTYOU_SCORE:
    .byte  18,  86, 170 ; V1=D3    V2=D2   
    .byte  18,  57, 170 ; V1=A3    V2=D2   
    .byte  18,  43, 170 ; V1=D4    V2=D2   
    .byte  18,  36,  86 ; V1=F4    V2=D3   
    .byte  18,  43,  86 ; V1=D4    V2=D3   
    .byte  18,  57,  86 ; V1=A3    V2=D3   
    .byte  18,  76, 153 ; V1=E3    V2=E2   
    .byte  18,  57, 153 ; V1=A3    V2=E2   
    .byte  18,  43, 153 ; V1=D4    V2=E2   
    .byte  18,  36,  76 ; V1=F4    V2=E3   
    .byte  18,  43,  76 ; V1=D4    V2=E3   
    .byte  18,  57,  76 ; V1=A3    V2=E3   
    .byte  18,  72, 144 ; V1=F3    V2=F2   
    .byte  18,  57, 144 ; V1=A3    V2=F2   
    .byte  18,  43, 144 ; V1=D4    V2=F2   
    .byte  18,  36,  72 ; V1=F4    V2=F3   
    .byte  18,  43,  72 ; V1=D4    V2=F3   
    .byte  18,  57,  72 ; V1=A3    V2=F3   
    .byte  18,  76, 153 ; V1=E3    V2=E2   
    .byte  18,  60, 153 ; V1=G#3   V2=E2   
    .byte  18,  43, 153 ; V1=D4    V2=E2   
    .byte  18,  36,  76 ; V1=F4    V2=E3   
    .byte  18,  43,  76 ; V1=D4    V2=E3   
    .byte  18,  60,  76 ; V1=G#3   V2=E3   
    .byte  18, 108, 108 ; V1=Bb2   V2=Bb2  
    .byte  18,  72, 108 ; V1=F3    V2=Bb2  
    .byte  18,  60, 108 ; V1=G#3   V2=Bb2  
    .byte  18,  43, 108 ; V1=D4    V2=Bb2  
    .byte  18,  36, 108 ; V1=F4    V2=Bb2  
    .byte  18,  43, 108 ; V1=D4    V2=Bb2  
    .byte  18, 115, 115 ; V1=A2    V2=A2   
    .byte  18,  76, 115 ; V1=E3    V2=A2   
    .byte  18,  64, 115 ; V1=G3    V2=A2   
    .byte  18,  45, 115 ; V1=C#4   V2=A2   
    .byte  36,  36, 115 ; V1=F4    V2=A2   
    .byte  18,   0, 115 ; V1=REST  V2=A2   
    .byte  32,  43, 170 ; V1=D4    V2=D2   
    .byte  16,  36, 115 ; V1=F4    V2=A2   
    .byte  48,  43,  86 ; V1=D4    V2=D3   
    .byte  16,  86, 170 ; V1=D3    V2=D2   
    .byte  16,  72, 170 ; V1=F3    V2=D2   
    .byte  16,  64, 170 ; V1=G3    V2=D2   
    .byte  16,  60, 170 ; V1=G#3   V2=D2   
    .byte  32,  57, 170 ; V1=A3    V2=D2   
    .byte  32,  43, 170 ; V1=D4    V2=D2   
    .byte  16,  36, 115 ; V1=F4    V2=A2   
    .byte  16,  43,  86 ; V1=D4    V2=D3   
    .byte  16,  48, 115 ; V1=C4    V2=A2   
    .byte  48,  43, 170 ; V1=D4    V2=D2   
    .byte  16, 115, 115 ; V1=A2    V2=A2   
    .byte  16,  96, 115 ; V1=C3    V2=A2   
    .byte  16,  86, 115 ; V1=D3    V2=A2   
    .byte  16,  81, 115 ; V1=D#3   V2=A2   
    .byte  32,  76, 115 ; V1=E3    V2=A2   
    .byte  16,  36, 170 ; V1=F4    V2=D2   
    .byte  16,  36, 170 ; V1=F4    V2=D2   
    .byte  16,  43, 144 ; V1=D4    V2=F2   
    .byte  16,  48, 144 ; V1=C4    V2=F2   
    .byte  32,  43, 129 ; V1=D4    V2=G2   
    .byte  16,  36, 129 ; V1=F4    V2=G2   
    .byte  16,  36, 108 ; V1=F4    V2=Bb2  
    .byte  16,  43, 108 ; V1=D4    V2=Bb2  
    .byte  16,  48, 115 ; V1=C4    V2=A2   
    .byte  48,  43, 115 ; V1=D4    V2=A2   
    .byte  16,  29, 170 ; V1=A4    V2=D2   
    .byte  16,  27, 170 ; V1=Bb4   V2=D2   
    .byte  16,  29, 170 ; V1=A4    V2=D2   
    .byte  16,  32, 170 ; V1=G4    V2=D2   
    .byte  32,  36, 115 ; V1=F4    V2=A2   
    .byte  64,  43, 170 ; V1=D4    V2=D2   
    .byte  32,  43, 115 ; V1=D4    V2=A2   
    .byte  32,  43,  86 ; V1=D4    V2=D3   
    .byte  18,  86, 170 ; V1=D3    V2=D2   
    .byte  18,  57, 170 ; V1=A3    V2=D2   
    .byte  18,  43, 170 ; V1=D4    V2=D2   
    .byte  18,  36,  86 ; V1=F4    V2=D3   
    .byte  18,  43,  86 ; V1=D4    V2=D3   
    .byte  18,  57,  86 ; V1=A3    V2=D3   
    .byte  18,  76, 153 ; V1=E3    V2=E2   
    .byte  18,  57, 153 ; V1=A3    V2=E2   
    .byte  18,  43, 153 ; V1=D4    V2=E2   
    .byte  18,  36,  76 ; V1=F4    V2=E3   
    .byte  18,  43,  76 ; V1=D4    V2=E3   
    .byte  18,  57,  76 ; V1=A3    V2=E3   
    .byte  18,  72, 144 ; V1=F3    V2=F2   
    .byte  18,  57, 144 ; V1=A3    V2=F2   
    .byte  18,  43, 144 ; V1=D4    V2=F2   
    .byte  18,  36,  72 ; V1=F4    V2=F3   
    .byte  18,  43,  72 ; V1=D4    V2=F3   
    .byte  18,  57,  72 ; V1=A3    V2=F3   
    .byte  18,  76, 153 ; V1=E3    V2=E2   
    .byte  18,  60, 153 ; V1=G#3   V2=E2   
    .byte  18,  43, 153 ; V1=D4    V2=E2   
    .byte  18,  36,  76 ; V1=F4    V2=E3   
    .byte  18,  43,  76 ; V1=D4    V2=E3   
    .byte  18,  60,  76 ; V1=G#3   V2=E3   
    .byte  18, 108, 108 ; V1=Bb2   V2=Bb2  
    .byte  18,  72, 108 ; V1=F3    V2=Bb2  
    .byte  18,  60, 108 ; V1=G#3   V2=Bb2  
    .byte  18,  43, 108 ; V1=D4    V2=Bb2  
    .byte  18,  36, 108 ; V1=F4    V2=Bb2  
    .byte  18,  43, 108 ; V1=D4    V2=Bb2  
    .byte  18, 115, 115 ; V1=A2    V2=A2   
    .byte  18,  76, 115 ; V1=E3    V2=A2   
    .byte  18,  64, 115 ; V1=G3    V2=A2   
    .byte  18,  45, 115 ; V1=C#4   V2=A2   
    .byte  36,  36, 115 ; V1=F4    V2=A2   
    .byte  18,   0, 115 ; V1=REST  V2=A2   
    .byte  96,  43, 170 ; V1=D4    V2=D2   
    .byte   0,   0,   0 ; Fin de partition
