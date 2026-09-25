# -*- coding: utf-8 -*-
"""
make_ai_asm.py - Recompiles all assembly games and generates the unified AI-ASM.DSK disk image.
Run anytime you modify or add assembly games:
    python make_ai_asm.py
"""
import os
import sys
import struct
import subprocess

# Ensure local tools (bas2dsk) can be imported
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)

import bas2dsk

# List of ASM games to compile and install
# (asm_source, binary_file, catalog_name, load_address, description)
GAMES = [
    (os.path.join("invaders", "invaders.asm"),       os.path.join("invaders", "invaders.bin"),       "INVADERS",    0x6000, "SPACE INVADERS (1978 HGR)"),
    (os.path.join("flappy", "flappy.asm"),           os.path.join("flappy", "flappy.bin"),           "FLAPPY",      0x0803, "FLAPPY BIRD (PARALLAX HGR)"),
    (os.path.join("flappy", "happybird.asm"),        os.path.join("flappy", "happybird.bin"),        "HAPPYBIRD",   0x6000, "HAPPY BIRD (HGR)"),
    (os.path.join("pong", "pong.asm"),               os.path.join("pong", "pong.bin"),               "PONG",        0x6000, "PONG ARCADE (HGR)"),
    (os.path.join("artillerie", "artillerie.asm"),   os.path.join("artillerie", "artillerie.bin"),   "ARTILLERIE",  0x4000, "ARTILLERIE (HGR)"),
    (os.path.join("pipopipette", "pipopipette.asm"), os.path.join("pipopipette", "pipopipette.bin"), "PIPOPIPETTE", 0x6000, "PIPOPIPETTE (HGR)"),
    (os.path.join("snake", "snake-hgr.asm"),         os.path.join("snake", "snake-hgr.bin"),         "SNAKE-HGR",   0x4000, "SNAKE HGR (280x192)"),
    (os.path.join("snake", "snake-gr.asm"),          os.path.join("snake", "snake-gr.bin"),          "SNAKE-GR",    0x4000, "SNAKE LORES (GR 40x40)"),
    (os.path.join("snake", "snake-txt.asm"),         os.path.join("snake", "snake-txt.bin"),         "SNAKE-TXT",   0x4000, "SNAKE TEXTE (40x24)"),
    (os.path.join("snake", "snake_kimi.asm"),        os.path.join("snake", "snake_kimi.bin"),        "SNAKE-KIMI",  0x6000, "SNAKE ACCELERATION (KIMI)"),
    (os.path.join("1000bornes", "1000bornes.asm"),   os.path.join("1000bornes", "1000bornes.bin"),   "BORNES",      0x4000, "1000 BORNES (MO5 1985)"),
    (os.path.join("musique", "bach.asm"),            os.path.join("musique", "bach.bin"),            "BACH",        0x4000, "JUKEBOX 2 VOIX (BACH & BEATLES)"),
    ("pi.asm",                                       "pi.bin",                                       "PI",          0x0800, "CALCUL DE PI (4000 DEC.)")
]

DSK_NAME = "AI-ASM.DSK"

def build_disk():
    print(f"=== BUILDING {DSK_NAME} ===")
    
    # 1. Compile all ASM games with 64tass
    for src, bin_out, cat_name, addr, desc in GAMES:
        print(f"Compiling {src} -> {bin_out}...")
        res = subprocess.run(["64tass", "--cbm-prg", "-o", bin_out, src], capture_output=True, text=True)
        if res.returncode != 0:
            print(f"ERROR assembling {src}:\n{res.stderr}")
            sys.exit(1)
        size = os.path.getsize(bin_out)
        print(f"  OK: {bin_out} ({size} bytes)")

    # 2. Initialize clean DOS 3.3 disk from bootable template
    print("Formatting clean DOS 3.3 disk...")
    template_candidates = [
        os.path.join("scratch", "MASTER.DSK"),
        "MASTER.DSK",
        "AI-ASM.DSK"
    ]
    template_path = next((p for p in template_candidates if os.path.exists(p)), None)
    if not template_path:
        print("ERROR: No bootable template DSK found!")
        sys.exit(1)
    with open(template_path, "rb") as f:
        master_disk = bytearray(f.read())

    new_disk = bytearray(bas2dsk.DISK_SIZE)
    # Copy boot sectors and DOS (tracks 0, 1, 2)
    dos_len = 3 * bas2dsk.TRACK_SIZE
    new_disk[:dos_len] = master_disk[:dos_len]

    # Initialize VTOC at Track 17, Sector 0
    vtoc = bytearray(256)
    vtoc[0x01] = 17  # first catalog track
    vtoc[0x02] = 15  # first catalog sector
    vtoc[0x03] = 3   # DOS 3.3
    vtoc[0x27] = 122
    vtoc[0x30] = 35
    vtoc[0x31] = 16
    struct.pack_into("<H", vtoc, 0x32, 256)

    # Mark all tracks 3..34 as completely free (16 bits set)
    for t in range(35):
        off = 0x38 + t * 4
        if t < 3:
            vtoc[off:off+4] = bytes([0x00, 0x00, 0x00, 0x00])
        elif t == 17:
            vtoc[off:off+4] = bytes([0x00, 0x00, 0x00, 0x00])
        else:
            vtoc[off:off+4] = bytes([0xFF, 0xFF, 0x00, 0x00])

    bas2dsk.write_sector(new_disk, bas2dsk.VTOC_TRACK, bas2dsk.VTOC_SECTOR, vtoc)

    # Initialize Catalog sectors on Track 17 (sectors 15 down to 1)
    for s in range(15, 0, -1):
        cat_sec = bytearray(256)
        cat_sec[0x01] = 17 if s > 1 else 0
        cat_sec[0x02] = s - 1 if s > 1 else 0
        bas2dsk.write_sector(new_disk, 17, s, cat_sec)

    # Save initial clean disk
    with open(DSK_NAME, "wb") as f:
        f.write(new_disk)
    print("Clean DOS 3.3 filesystem created.")

    # 3. Create the HELLO Applesoft BASIC menu program
    hello_basic_text = (
        '5 PRINT CHR$(4);"MAXFILES 1"\n'
        '10 TEXT : HOME\n'
        '20 INVERSE : HTAB 11: PRINT " *** DISQUETTE AI-ASM *** "; : NORMAL\n'
        '30 VTAB 3: HTAB 5: PRINT "ANTHOLOGIE DE JEUX EN ASSEMBLEUR"\n'
        '40 VTAB 4: HTAB 5: PRINT "--------------------------------"\n'
        '50 VTAB 6: HTAB 3: PRINT "1. SPACE INVADERS (1978 HGR)"\n'
        '60 VTAB 7: HTAB 3: PRINT "2. FLAPPY BIRD (PARALLAX HGR)"\n'
        '70 VTAB 8: HTAB 3: PRINT "3. HAPPY BIRD (HGR)"\n'
        '80 VTAB 9: HTAB 3: PRINT "4. PONG ARCADE (HGR)"\n'
        '90 VTAB 10: HTAB 3: PRINT "5. ARTILLERIE (HGR)"\n'
        '100 VTAB 11: HTAB 3: PRINT "6. PIPOPIPETTE (HGR)"\n'
        '110 VTAB 12: HTAB 3: PRINT "7. SNAKE HGR (280x192)"\n'
        '120 VTAB 13: HTAB 3: PRINT "8. SNAKE LORES (GR 40x40)"\n'
        '130 VTAB 14: HTAB 3: PRINT "9. SNAKE TEXTE (40x24)"\n'
        '140 VTAB 15: HTAB 3: PRINT "A. SNAKE ACCELERATION (KIMI)"\n'
        '145 VTAB 16: HTAB 3: PRINT "B. 1000 BORNES (MO5 1985)"\n'
        '147 VTAB 17: HTAB 3: PRINT "S. SNAKE 2-LIGNES (BASIC)"\n'
        '150 VTAB 18: HTAB 3: PRINT "P. CALCUL DE PI (4000 DEC.)"\n'
        '155 VTAB 19: HTAB 3: PRINT "M. JUKEBOX 2 VOIX (BACH & BEATLES)"\n'
        '160 VTAB 20: HTAB 3: PRINT "Q. QUITTER VERS LE PROMPT DOS"\n'
        '170 VTAB 21: HTAB 3: PRINT "--------------------------------"\n'
        '180 VTAB 22: HTAB 3: PRINT "VOTRE CHOIX [1-9, A, B, S, P, M, Q] : ";\n'
        '190 GET A$: PRINT A$\n'
        '200 IF A$ = "1" THEN PRINT CHR$(4);"BRUN INVADERS"\n'
        '210 IF A$ = "2" THEN PRINT CHR$(4);"BRUN FLAPPY"\n'
        '220 IF A$ = "3" THEN PRINT CHR$(4);"BRUN HAPPYBIRD"\n'
        '230 IF A$ = "4" THEN PRINT CHR$(4);"BRUN PONG"\n'
        '240 IF A$ = "5" THEN PRINT CHR$(4);"BRUN ARTILLERIE"\n'
        '250 IF A$ = "6" THEN PRINT CHR$(4);"BRUN PIPOPIPETTE"\n'
        '260 IF A$ = "7" THEN PRINT CHR$(4);"BRUN SNAKE-HGR"\n'
        '270 IF A$ = "8" THEN PRINT CHR$(4);"BRUN SNAKE-GR"\n'
        '280 IF A$ = "9" THEN PRINT CHR$(4);"BRUN SNAKE-TXT"\n'
        '290 IF A$ = "A" OR A$ = "a" THEN PRINT CHR$(4);"BRUN SNAKE-KIMI"\n'
        '295 IF A$ = "B" OR A$ = "b" THEN PRINT CHR$(4);"BRUN BORNES"\n'
        '297 IF A$ = "S" OR A$ = "s" THEN PRINT CHR$(4);"RUN SNAKE_2L"\n'
        '300 IF A$ = "P" OR A$ = "p" THEN PRINT CHR$(4);"BRUN PI"\n'
        '305 IF A$ = "M" OR A$ = "m" OR A$ = "F" OR A$ = "f" THEN PRINT CHR$(4);"BRUN BACH"\n'
        '310 IF A$ = "Q" OR A$ = "q" THEN TEXT : HOME : END\n'
        '320 GOTO 180\n'
    )

    print("Writing boot program HELLO...")
    prog_data = bas2dsk.tokenize_program(hello_basic_text)
    file_data = struct.pack("<H", len(prog_data)) + prog_data
    bas2dsk.write_file_to_dsk(DSK_NAME, "HELLO", file_data, 0x02)

    # 4. Write each binary file to the disk
    for src, bin_out, cat_name, addr, desc in GAMES:
        with open(bin_out, "rb") as f:
            raw_data = f.read()

        # Strip 2-byte CBM header if present
        if len(raw_data) >= 2 and raw_data[0] == (addr & 0xFF) and raw_data[1] == (addr >> 8):
            raw_data = raw_data[2:]

        dos_bin_data = struct.pack("<HH", addr, len(raw_data)) + raw_data
        bas2dsk.write_file_to_dsk(DSK_NAME, cat_name, dos_bin_data, 0x04)
        print(f"  Installed '{cat_name}' (Addr: ${addr:04X}, Length: {len(raw_data)} bytes)")

    # Install aliases 'MILLEBORNES' and 'MBORNES' -> BORNES ($4000)
    bornes_bin = os.path.join("1000bornes", "1000bornes.bin")
    if os.path.exists(bornes_bin):
        with open(bornes_bin, "rb") as f:
            b_raw = f.read()
        if len(b_raw) >= 2 and b_raw[0] == 0x00 and b_raw[1] == 0x40:
            b_raw = b_raw[2:]
        b_dos_data = struct.pack("<HH", 0x4000, len(b_raw)) + b_raw
        bas2dsk.write_file_to_dsk(DSK_NAME, "MILLEBORNES", b_dos_data, 0x04)
        bas2dsk.write_file_to_dsk(DSK_NAME, "MBORNES", b_dos_data, 0x04)
        print("  Installed aliases 'MILLEBORNES' and 'MBORNES' -> BORNES ($4000)")

    # Install alias 'SNAKE' -> SNAKE-TXT ($4000)
    snake_txt_bin = os.path.join("snake", "snake-txt.bin")
    if os.path.exists(snake_txt_bin):
        with open(snake_txt_bin, "rb") as f:
            txt_raw = f.read()
        if len(txt_raw) >= 2 and txt_raw[0] == 0x00 and txt_raw[1] == 0x40:
            txt_raw = txt_raw[2:]
        txt_bin_data = struct.pack("<HH", 0x4000, len(txt_raw)) + txt_raw
        bas2dsk.write_file_to_dsk(DSK_NAME, "SNAKE", txt_bin_data, 0x04)
        print("  Installed alias 'SNAKE' -> SNAKE-TXT ($4000)")

    # Install 'SNAKE_2L' (Applesoft BASIC)
    snake_2l_path = os.path.join("snake", "snake_2l.bas")
    if os.path.exists(snake_2l_path):
        with open(snake_2l_path, "r", encoding="utf-8") as f:
            snake_2l_text = f.read()
        snake_2l_tokens = bas2dsk.tokenize_program(snake_2l_text)
        snake_2l_payload = struct.pack("<H", len(snake_2l_tokens)) + snake_2l_tokens
        bas2dsk.write_file_to_dsk(DSK_NAME, "SNAKE_2L", snake_2l_payload, 0x02)
        print("  Installed 'SNAKE_2L' (Applesoft BASIC)")

    # 5. Check free space
    with open(DSK_NAME, "rb") as f:
        disk_check = bytearray(f.read())
    vtoc_check = bas2dsk.read_sector(disk_check, bas2dsk.VTOC_TRACK, bas2dsk.VTOC_SECTOR)
    free_sectors = 0
    for t in range(bas2dsk.TRACK_COUNT):
        for s in range(bas2dsk.SECTORS_PER_TRACK):
            if bas2dsk.is_sector_free(vtoc_check, t, s):
                free_sectors += 1

    print("=" * 45)
    print(f"SUCCESS! {DSK_NAME} successfully created!")
    print(f"Free sectors available for experiments: {free_sectors} sectors (~{free_sectors * 256 // 1024} KB)")

if __name__ == "__main__":
    build_disk()
