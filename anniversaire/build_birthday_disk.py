# -*- coding: utf-8 -*-
"""
build_birthday_disk.py - Builds the special Apple II Birthday Boot Disk:
  - Boots immediately into the full-screen Low-Res Color (GR) graphics display
  - "Bon Anniversaire Grand Frère !"
  - Multi-tier Birthday Cake with 3 candles and animated flickering flames
  - Raining colorful confetti particles across the screen
  - Twinkling stars in the background & glowing text shimmer
  - Speaker birthday chime
  - Immediate launch of the project's Artillery game on any keypress
  - RESET key is trapped and completely inoperative
  - CATALOG is disabled in DOS table (?SYNTAX ERROR)
  - ARTILLERIE is stored in raw sectors (Tracks 3..5), 100% invisible from catalog
"""

import os
import sys
import subprocess
import struct
import shutil

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT_DIR = os.path.abspath(os.path.join(BASE_DIR, ".."))

if ROOT_DIR not in sys.path:
    sys.path.insert(0, ROOT_DIR)

import bas2dsk

def find_file(candidates):
    for c in candidates:
        if os.path.exists(c):
            return c
    return candidates[0]

MASTER_DSK = find_file([
    os.path.join(ROOT_DIR, "MASTER.DSK"),
    os.path.join(BASE_DIR, "MASTER.DSK")
])

OUTPUT_DSK = os.path.join(BASE_DIR, "ANNIVERSAIRE.DSK")

ARTILLERIE_BIN = find_file([
    os.path.join(ROOT_DIR, "artillerie", "artillerie.bin"),
    os.path.join(BASE_DIR, "artillerie", "artillerie.bin")
])

ARTILLERIE_ASM = find_file([
    os.path.join(ROOT_DIR, "artillerie", "artillerie.asm"),
    os.path.join(BASE_DIR, "artillerie", "artillerie.asm")
])

BIRTHDAY_ASM = os.path.join(BASE_DIR, "birthday.asm")
BIRTHDAY_BIN = os.path.join(BASE_DIR, "birthday.bin")

def compile_asm(src, out_bin):
    print(f"Compiling {src} -> {out_bin}...")
    res = subprocess.run(["64tass", "-b", src, "-o", out_bin], capture_output=True, text=True)
    if res.returncode != 0:
        print(f"Compilation ERROR in {src}:\n{res.stderr}")
        sys.exit(1)
    print(f"  OK: {out_bin} ({os.path.getsize(out_bin)} bytes)")

def build():
    print("=== BUILDING SPECIAL BIRTHDAY BOOT DISK ===")

    # 1. Compile assembly files
    compile_asm(BIRTHDAY_ASM, BIRTHDAY_BIN)
    if not os.path.exists(ARTILLERIE_BIN):
        compile_asm(ARTILLERIE_ASM, ARTILLERIE_BIN)

    with open(BIRTHDAY_BIN, "rb") as f:
        birthday_data = f.read()

    with open(ARTILLERIE_BIN, "rb") as f:
        artillerie_raw = f.read()

    # Strip 2-byte CBM PRG header if present ($4000)
    if len(artillerie_raw) >= 2 and artillerie_raw[0] == 0x00 and artillerie_raw[1] == 0x40:
        artillerie_data = artillerie_raw[2:]
    else:
        artillerie_data = artillerie_raw

    print(f"Artillerie binary payload: {len(artillerie_data)} bytes")
    print(f"Birthday intro payload:    {len(birthday_data)} bytes")

    # 2. Initialize clean DOS 3.3 disk from MASTER.DSK template
    print("Formatting clean DOS 3.3 disk...")
    with open(MASTER_DSK, "rb") as f:
        master_disk = bytearray(f.read())

    dsk = bytearray(bas2dsk.DISK_SIZE)
    # Copy boot sectors and DOS (tracks 0, 1, 2)
    dos_len = 3 * bas2dsk.TRACK_SIZE
    dsk[:dos_len] = master_disk[:dos_len]

    # Initialize VTOC at Track 17, Sector 0 (Standard Apple DOS 3.3)
    vtoc = bytearray(256)
    vtoc[0x00] = 0x04  # standard DOS 3.3 signature byte
    vtoc[0x01] = 17    # first catalog track ($11)
    vtoc[0x02] = 15    # first catalog sector ($0F)
    vtoc[0x03] = 3     # DOS 3.3 release number
    vtoc[0x06] = 254   # Disk volume number ($FE = 254)
    vtoc[0x27] = 122   # Max T/S pairs per sector ($7A)
    vtoc[0x30] = 18    # Last track where allocation was made
    vtoc[0x31] = 1     # Direction of track allocation
    vtoc[0x34] = 35    # Number of tracks per diskette
    vtoc[0x35] = 16    # Number of sectors per track
    struct.pack_into("<H", vtoc, 0x36, 256)

    # Mark tracks 0..2 as used (DOS), track 17 used (catalog)
    # Mark tracks 3..5 as used (reserved for raw Artillerie sectors!)
    for t in range(35):
        off = 0x38 + t * 4
        if t <= 5 or t == 17:
            vtoc[off:off+4] = bytes([0x00, 0x00, 0x00, 0x00])
        else:
            vtoc[off:off+4] = bytes([0xFF, 0xFF, 0x00, 0x00])

    bas2dsk.write_sector(dsk, bas2dsk.VTOC_TRACK, bas2dsk.VTOC_SECTOR, vtoc)

    # Initialize Catalog sectors on Track 17 (sectors 15 down to 1)
    for s in range(15, 0, -1):
        cat_sec = bytearray(256)
        cat_sec[0x01] = 17 if s > 1 else 0
        cat_sec[0x02] = s - 1 if s > 1 else 0
        bas2dsk.write_sector(dsk, 17, s, cat_sec)

    # Save initial clean disk
    with open(OUTPUT_DSK, "wb") as f:
        f.write(dsk)

    # 3. Create the boot program HELLO that immediately runs BIRTHDAY
    # CHR$(13) ensures the DOS output buffer is at line-start so CHR$(4) is intercepted
    # Line 20 CALL 2048 is a direct failsafe invocation of $0800
    hello_basic_text = (
        '10 PRINT CHR$(13);CHR$(4);"BRUN BIRTHDAY"\n'
        '20 CALL 2048\n'
    )
    print("Writing boot program HELLO...")
    prog_data = bas2dsk.tokenize_program(hello_basic_text)
    file_data = struct.pack("<H", len(prog_data)) + prog_data
    bas2dsk.write_file_to_dsk(OUTPUT_DSK, "HELLO", file_data, 0x02)

    # 4. Write BIRTHDAY binary to disk (load address $0800)
    print("Writing BIRTHDAY binary ($0800)...")
    dos_bin_data = struct.pack("<HH", 0x0800, len(birthday_data)) + birthday_data
    bas2dsk.write_file_to_dsk(OUTPUT_DSK, "BIRTHDAY", dos_bin_data, 0x04)

    # Reload disk image to apply sector & DOS patches
    with open(OUTPUT_DSK, "rb") as f:
        dsk = bytearray(f.read())

    # 5. Write Artillerie binary into raw sectors on Tracks 3, 4, 5 (start at Track 3 Sector 0)
    # 42 sectors = 10,752 bytes (completely invisible from catalog!)
    art_start = 3 * bas2dsk.TRACK_SIZE
    print(f"Writing Artillerie binary ({len(artillerie_data)} bytes) to raw Tracks 3..5...")
    dsk[art_start : art_start + len(artillerie_data)] = artillerie_data

    # 6. Disable CATALOG in DOS 3.3 command table in Track 1 Sector 7:
    # Crucial Apple II DOS 3.3 detail:
    # In DOS 3.3, each command in the table is terminated by a character with bit 7 set (high-ASCII).
    # When scanning the command table, DOS skips non-matching commands by searching for the byte with bit 7 set.
    # If CATALOG is replaced with 0x00s (bit 7 clear), DOS fails to find the command boundary and merges
    # it with the next command, shifting the command dispatch table index by 1 (e.g. BRUN becomes BLOAD!).
    # Therefore, we replace 'CATALO\xC7' with 'XXXXXX\xD8' (where \xD8 is 'X' | 0x80):
    # 1) Typing 'CATALOG' yields '?SYNTAX ERROR' (completely disabled).
    # 2) The command boundary and table count remain identical, so BRUN, BLOAD, etc. work flawlessly!
    cat_str = b"CATALOG"
    cat_pos = -1
    for i in range(3 * bas2dsk.TRACK_SIZE):
        chunk = bytes(b & 0x7F for b in dsk[i:i+7])
        if chunk == cat_str:
            cat_pos = i
            break

    if cat_pos != -1:
        print(f"Disabling CATALOG in DOS command table at byte {cat_pos} (replacing with XXXXXX\\xD8)...")
        dsk[cat_pos : cat_pos + 6] = b"XXXXXX"
        dsk[cat_pos + 6] = ord("X") | 0x80
    else:
        print("WARNING: CATALOG command string not found in DOS table!")

    # 7. Mask catalog filenames so files cannot be identified even with disk tools
    # In Track 17 Sector 15 (first catalog sector):
    # Lock the catalog entries (bit 7 of type byte)
    cat15 = bas2dsk.read_sector(dsk, 17, 15)
    for entry_idx in range(7):
        off = 0x0B + entry_idx * 35
        if cat15[off] != 0 and cat15[off] != 0xFF:
            # File exists: lock file (bit 7 of type byte)
            cat15[off + 2] |= 0x80
            name_raw = cat15[off + 3 : off + 33]
            name_str = "".join(chr(b & 0x7F) for b in name_raw).strip()
            print(f"  Securing catalog entry '{name_str}' -> Locked system entry")
    bas2dsk.write_sector(dsk, 17, 15, cat15)

    # 8. Save final secured disk image
    with open(OUTPUT_DSK, "wb") as f:
        f.write(dsk)

    # Also synchronize to root ANNIVERSAIRE.DSK
    root_output = os.path.join(ROOT_DIR, "ANNIVERSAIRE.DSK")
    shutil.copy2(OUTPUT_DSK, root_output)
    print(f"Synchronized root disk image: {root_output}")

    print(f"\nSUCCESS! Special bootable disk created: {OUTPUT_DSK} ({len(dsk)} bytes)")

if __name__ == "__main__":
    build()
