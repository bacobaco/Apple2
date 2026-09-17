# -*- coding: utf-8 -*-
"""
build_disk.py - Compilation et génération de l'image disquette SNAKE.dsk
contenant les 4 déclinaisons de Snake pour Apple II:
  1. Snake HGR (280x192 Haute Résolution)
  2. Snake GR (40x40 Basse Résolution)
  3. Snake Texte (40x24 Mode Texte Pur)
  4. Snake Accélération KIMI (Mode Texte Dynamique)
  + Snake 2-Lignes (Applesoft BASIC minimaliste)
"""

import os
import sys
import struct
import subprocess

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT_DIR = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))

if ROOT_DIR not in sys.path:
    sys.path.insert(0, ROOT_DIR)

import bas2dsk

DSK_NAME_SCRATCH = os.path.join(ROOT_DIR, "scratch", "SNAKE.dsk")
AI_ASM_DSK = os.path.join(ROOT_DIR, "AI-ASM.DSK")

SNAKE_GAMES = [
    {
        "src": os.path.join(SCRIPT_DIR, "snake-hgr.asm"),
        "bin": os.path.join(SCRIPT_DIR, "snake-hgr.bin"),
        "cat_name": "SNAKE-HGR",
        "addr": 0x4000,
        "desc": "SNAKE HGR (280x192 Haute Resolution)"
    },
    {
        "src": os.path.join(SCRIPT_DIR, "snake-gr.asm"),
        "bin": os.path.join(SCRIPT_DIR, "snake-gr.bin"),
        "cat_name": "SNAKE-GR",
        "addr": 0x4000,
        "desc": "SNAKE LORES (GR 40x40 Basse Resolution)"
    },
    {
        "src": os.path.join(SCRIPT_DIR, "snake-txt.asm"),
        "bin": os.path.join(SCRIPT_DIR, "snake-txt.bin"),
        "cat_name": "SNAKE-TXT",
        "addr": 0x4000,
        "desc": "SNAKE TEXTE (40x24 Mode Texte)"
    },
    {
        "src": os.path.join(SCRIPT_DIR, "snake_kimi.asm"),
        "bin": os.path.join(SCRIPT_DIR, "snake_kimi.bin"),
        "cat_name": "SNAKE-KIMI",
        "addr": 0x6000,
        "desc": "SNAKE ACCELERATION (KIMI)"
    }
]

HELLO_MENU_BASIC = (
    '5 PRINT CHR$(4);"MAXFILES 1"\n'
    '10 TEXT : HOME\n'
    '20 INVERSE : HTAB 10: PRINT " *** ANTHOLOGIE SNAKE *** "; : NORMAL\n'
    '30 VTAB 3: HTAB 7: PRINT "LES 4 DECLINAISONS APPLE II"\n'
    '40 VTAB 4: HTAB 7: PRINT "---------------------------"\n'
    '50 VTAB 6: HTAB 4: PRINT "1. SNAKE HGR (280x192 HAUTE RES.)"\n'
    '60 VTAB 8: HTAB 4: PRINT "2. SNAKE GR (40x40 BASSE RES.)"\n'
    '70 VTAB 10: HTAB 4: PRINT "3. SNAKE TEXTE (40x24 PUR TEXTE)"\n'
    '80 VTAB 12: HTAB 4: PRINT "4. SNAKE ACCELERATION (KIMI)"\n'
    '90 VTAB 14: HTAB 4: PRINT "5. SNAKE 2-LIGNES (BASIC MINIMAL)"\n'
    '100 VTAB 17: HTAB 4: PRINT "Q. QUITTER VERS LE PROMPT DOS"\n'
    '110 VTAB 19: HTAB 4: PRINT "---------------------------"\n'
    '120 VTAB 21: HTAB 6: PRINT "VOTRE CHOIX [1-5, Q] : ";\n'
    '130 GET A$: PRINT A$\n'
    '140 IF A$ = "1" THEN PRINT CHR$(4);"BRUN SNAKE-HGR"\n'
    '150 IF A$ = "2" THEN PRINT CHR$(4);"BRUN SNAKE-GR"\n'
    '160 IF A$ = "3" THEN PRINT CHR$(4);"BRUN SNAKE-TXT"\n'
    '170 IF A$ = "4" THEN PRINT CHR$(4);"BRUN SNAKE-KIMI"\n'
    '180 IF A$ = "5" THEN PRINT CHR$(4);"RUN SNAKE_2L"\n'
    '190 IF A$ = "Q" OR A$ = "q" THEN TEXT : HOME : END\n'
    '200 GOTO 120\n'
)

def compile_asm():
    print("--- [1/3] Compilation des 4 versions de Snake (64tass) ---")
    for game in SNAKE_GAMES:
        src = game["src"]
        bin_file = game["bin"]
        rel_src = os.path.relpath(src, SCRIPT_DIR)
        rel_bin = os.path.relpath(bin_file, SCRIPT_DIR)
        print(f"  Assemblage de {rel_src} -> {rel_bin}...")
        res = subprocess.run(["64tass", "-b", src, "-o", bin_file], capture_output=True, text=True)
        if res.returncode != 0:
            print(f"  [ERREUR] Echec lors de la compilation de {rel_src}:\n{res.stderr}")
            sys.exit(1)
        size = os.path.getsize(bin_file)
        print(f"    -> Succes ({size} octets)")

def create_snake_disk():
    print(f"\n--- [2/3] Generation de {os.path.basename(DSK_NAME_SCRATCH)} (archive scratch) ---")
    template_candidates = [
        os.path.join(ROOT_DIR, "scratch", "MASTER.DSK"),
        os.path.join(ROOT_DIR, "MASTER.DSK"),
        AI_ASM_DSK
    ]
    template_path = next((p for p in template_candidates if os.path.exists(p)), None)
    if not template_path:
        print("  [ERREUR] Aucune disquette gabarit amorcable trouvee !")
        sys.exit(1)

    with open(template_path, "rb") as f:
        master_data = bytearray(f.read())

    new_disk = bytearray(bas2dsk.DISK_SIZE)
    dos_len = 3 * bas2dsk.TRACK_SIZE
    new_disk[:dos_len] = master_data[:dos_len]

    # VTOC
    vtoc = bytearray(256)
    vtoc[0x01] = 17
    vtoc[0x02] = 15
    vtoc[0x03] = 3
    vtoc[0x27] = 122
    vtoc[0x30] = 35
    vtoc[0x31] = 16
    struct.pack_into("<H", vtoc, 0x32, 256)

    for t in range(35):
        off = 0x38 + t * 4
        if t < 3:
            vtoc[off:off+4] = bytes([0x00, 0x00, 0x00, 0x00])
        elif t == 17:
            vtoc[off:off+4] = bytes([0x00, 0x00, 0x00, 0x00])
        else:
            vtoc[off:off+4] = bytes([0xFF, 0xFF, 0x00, 0x00])

    bas2dsk.write_sector(new_disk, bas2dsk.VTOC_TRACK, bas2dsk.VTOC_SECTOR, vtoc)

    # Secteurs catalogue (15 a 1)
    for s in range(15, 0, -1):
        cat_sec = bytearray(256)
        cat_sec[0x01] = 17 if s > 1 else 0
        cat_sec[0x02] = s - 1 if s > 1 else 0
        bas2dsk.write_sector(new_disk, 17, s, cat_sec)

    with open(DSK_NAME_SCRATCH, "wb") as f:
        f.write(new_disk)
    print("  Systeme DOS 3.3 initialise.")

    # 1. Ecriture du menu HELLO
    print("  Injection du menu interactif HELLO...")
    hello_tokens = bas2dsk.tokenize_program(HELLO_MENU_BASIC)
    hello_payload = struct.pack("<H", len(hello_tokens)) + hello_tokens
    bas2dsk.write_file_to_dsk(DSK_NAME_SCRATCH, "HELLO", hello_payload, 0x02)

    # 2. Injection des 4 binaires
    for game in SNAKE_GAMES:
        with open(game["bin"], "rb") as f:
            raw_data = f.read()
        addr = game["addr"]
        cat_name = game["cat_name"]
        
        # Enleve l'en-tete CBM 2-octets si present
        if len(raw_data) >= 2 and raw_data[0] == (addr & 0xFF) and raw_data[1] == (addr >> 8):
            raw_data = raw_data[2:]

        dos_bin_data = struct.pack("<HH", addr, len(raw_data)) + raw_data
        bas2dsk.write_file_to_dsk(DSK_NAME_SCRATCH, cat_name, dos_bin_data, 0x04)
        print(f"  Installe '{cat_name}' (${addr:04X}, {len(raw_data)} octets) - {game['desc']}")

    # 3. Alias 'SNAKE' pointant sur SNAKE-TXT (pour compatibilite BRUN SNAKE)
    with open(os.path.join(SCRIPT_DIR, "snake-txt.bin"), "rb") as f:
        txt_raw = f.read()
    txt_bin_data = struct.pack("<HH", 0x4000, len(txt_raw)) + txt_raw
    bas2dsk.write_file_to_dsk(DSK_NAME_SCRATCH, "SNAKE", txt_bin_data, 0x04)
    print("  Installe alias 'SNAKE' -> SNAKE-TXT ($4000)")

    # 4. Injection de SNAKE_2L (BASIC)
    snake_2l_path = os.path.join(SCRIPT_DIR, "snake_2l.bas")
    if os.path.exists(snake_2l_path):
        with open(snake_2l_path, "r", encoding="utf-8") as f:
            snake_2l_text = f.read()
        snake_2l_tokens = bas2dsk.tokenize_program(snake_2l_text)
        snake_2l_payload = struct.pack("<H", len(snake_2l_tokens)) + snake_2l_tokens
        bas2dsk.write_file_to_dsk(DSK_NAME_SCRATCH, "SNAKE_2L", snake_2l_payload, 0x02)
        print("  Installe 'SNAKE_2L' (Applesoft BASIC)")

    # Verification de l'espace libre
    with open(DSK_NAME_SCRATCH, "rb") as f:
        disk_check = bytearray(f.read())
    vtoc_check = bas2dsk.read_sector(disk_check, bas2dsk.VTOC_TRACK, bas2dsk.VTOC_SECTOR)
    free_sectors = sum(
        1 for t in range(bas2dsk.TRACK_COUNT)
        for s in range(bas2dsk.SECTORS_PER_TRACK)
        if bas2dsk.is_sector_free(vtoc_check, t, s)
    )
    print(f"  Succes ! Secteurs libres sur SNAKE.dsk (scratch) : {free_sectors} (~{free_sectors * 256 // 1024} Ko)")

def update_ai_asm_disk():
    print(f"\n--- [3/3] Synchronisation optionnelle avec {os.path.basename(AI_ASM_DSK)} ---")
    if not os.path.exists(AI_ASM_DSK):
        print(f"  (AI-ASM.DSK non present, ignore)")
        return

    for game in SNAKE_GAMES:
        with open(game["bin"], "rb") as f:
            raw_data = f.read()
        addr = game["addr"]
        cat_name = game["cat_name"]
        
        if len(raw_data) >= 2 and raw_data[0] == (addr & 0xFF) and raw_data[1] == (addr >> 8):
            raw_data = raw_data[2:]

        dos_bin_data = struct.pack("<HH", addr, len(raw_data)) + raw_data
        try:
            bas2dsk.write_file_to_dsk(AI_ASM_DSK, cat_name, dos_bin_data, 0x04)
            print(f"  Mis a jour '{cat_name}' dans AI-ASM.DSK")
        except Exception as e:
            print(f"  [ATTENTION] Impossible de synchroniser '{cat_name}' dans AI-ASM.DSK: {e}")

if __name__ == "__main__":
    compile_asm()
    create_snake_disk()
    update_ai_asm_disk()
    print("\n========================================================")
    print("  TOUS LES 4 SNAKES SONT ASSEMBLES ET PRETS A JOUER !")
    print("========================================================")
