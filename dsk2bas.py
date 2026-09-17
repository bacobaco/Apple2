#!/usr/bin/env python3
"""
dsk2bas.py - Extract an Applesoft BASIC file from a DOS 3.3 .dsk image
             and convert it to text format.

Usage:
    python dsk2bas.py <image.dsk> <filename_on_disk> [output.bas]

Example:
    python dsk2bas.py MASTER.DSK "HELLO WORLD" hello.bas
"""

import sys
import struct
import os

# ============================================================
# Applesoft BASIC Token Table (0x80 - 0xEA)
# ============================================================
APPLESOFT_TOKENS = [
    "END", "FOR", "NEXT", "DATA", "INPUT", "DEL", "DIM", "READ",
    "GR", "TEXT", "PR#", "IN#", "CALL", "PLOT", "HLIN", "VLIN",
    "HGR2", "HGR", "HCOLOR=", "HPLOT", "DRAW", "XDRAW", "HTAB",
    "HOME", "ROT=", "SCALE=", "SHLOAD", "TRACE", "NOTRACE",
    "NORMAL", "INVERSE", "FLASH", "COLOR=", "POP", "VTAB",
    "HIMEM:", "LOMEM:", "ONERR", "RESUME", "RECALL", "STORE",
    "SPEED=", "LET", "GOTO", "RUN", "IF", "RESTORE", "&", "GOSUB",
    "RETURN", "REM", "STOP", "ON", "WAIT", "LOAD", "SAVE", "DEF",
    "POKE", "PRINT", "CONT", "LIST", "CLEAR", "GET", "NEW",
    "TAB(", "TO", "FN", "SPC(", "THEN", "AT", "NOT", "STEP",
    "+", "-", "*", "/", "^", "AND", "OR", ">", "=", "<",
    "SGN", "INT", "ABS", "USR", "FRE", "SCRN(", "PDL", "POS",
    "SQR", "RND", "LOG", "EXP", "COS", "SIN", "TAN", "ATN",
    "PEEK", "LEN", "STR$", "VAL", "ASC", "CHR$", "LEFT$",
    "RIGHT$", "MID$"
]

TOKEN_TO_KEYWORD = {0x80 + i: kw for i, kw in enumerate(APPLESOFT_TOKENS)}

def detokenize_line(data):
    """Convert tokenized program data for a single line back to text."""
    result = []
    i = 0
    in_string = False
    
    while i < len(data):
        b = data[i]
        
        # Strings are literal, but tokens are not processed inside them
        if b == ord('"'):
            in_string = not in_string
            result.append('"')
        elif in_string:
            result.append(chr(b & 0x7F))
        elif b >= 0x80:
            if b in TOKEN_TO_KEYWORD:
                result.append(TOKEN_TO_KEYWORD[b])
                # REM token special handling: everything after is literal
                if TOKEN_TO_KEYWORD[b] == "REM":
                    # The rest of the line is handled as literal ASCII (high bits stripped)
                    i += 1
                    while i < len(data):
                        result.append(chr(data[i] & 0x7F))
                        i += 1
                    break
            else:
                result.append(f"<{b:02X}>")
        else:
            result.append(chr(b & 0x7F))
        i += 1
    return "".join(result)

def detokenize_program(data):
    """Untokenize full Applesoft BASIC binary data."""
    output = []
    ptr = 0
    
    while ptr + 4 <= len(data):
        next_line_ptr = struct.unpack('<H', data[ptr:ptr+2])[0]
        if next_line_ptr == 0:
            break
            
        line_num = struct.unpack('<H', data[ptr+2:ptr+4])[0]
        
        # Find end of line (0x00)
        line_end = ptr + 4
        while line_end < len(data) and data[line_end] != 0x00:
            line_end += 1
            
        line_content = data[ptr+4:line_end]
        text_line = detokenize_line(line_content)
        output.append(f"{line_num} {text_line}")
        
        # Move to next line based on pointer
        # The pointer is absolute memory address, usually starting at 0x0801.
        # We need to calculate the offset relative to the start.
        # However, it's safer to just follow the 0x00 markers and use the pointer as a size indicator if needed.
        # Typically: offset_for_next = next_line_ptr - current_line_start_addr
        # But Applesoft lines are: [next_ptr_low, next_ptr_high, line_num_low, line_num_high, ... tokens ..., 00]
        ptr = line_end + 1
        
    return "\n".join(output)

# ============================================================
# DOS 3.3 Disk Image Handling
# ============================================================

TRACK_COUNT = 35
SECTORS_PER_TRACK = 16
SECTOR_SIZE = 256
TRACK_SIZE = SECTORS_PER_TRACK * SECTOR_SIZE
DISK_SIZE = TRACK_COUNT * TRACK_SIZE

VTOC_TRACK = 17
VTOC_SECTOR = 0

def sector_offset(track, sector):
    return track * TRACK_SIZE + sector * SECTOR_SIZE

def read_sector(disk, track, sector):
    offset = sector_offset(track, sector)
    return disk[offset:offset + SECTOR_SIZE]

def find_catalog_entry(disk, filename):
    vtoc = read_sector(disk, VTOC_TRACK, VTOC_SECTOR)
    cat_track = vtoc[1]
    cat_sector = vtoc[2]

    padded = filename.upper().ljust(30)[:30]

    while cat_track != 0:
        cat = read_sector(disk, cat_track, cat_sector)
        for i in range(7):
            entry_off = 0x0B + i * 35
            ts_track = cat[entry_off]
            if ts_track == 0 or ts_track == 0xFF:
                continue
            name_bytes = cat[entry_off + 3:entry_off + 33]
            # Strip high bit and convert to char
            name = ''.join(chr(b & 0x7F) for b in name_bytes).strip()
            if name.upper() == filename.upper().strip():
                return {
                    'ts_track': cat[entry_off],
                    'ts_sector': cat[entry_off + 1],
                    'file_type': cat[entry_off + 2],
                    'name': name
                }
        cat_track = cat[1]
        cat_sector = cat[2]
    return None

def list_catalog(disk):
    vtoc = read_sector(disk, VTOC_TRACK, VTOC_SECTOR)
    cat_track = vtoc[1]
    cat_sector = vtoc[2]
    files = []
    while cat_track != 0:
        cat = read_sector(disk, cat_track, cat_sector)
        for i in range(7):
            off = 0x0B + i * 35
            if cat[off] == 0 or cat[off] == 0xFF:
                continue
            name = "".join(chr(b & 0x7F) for b in cat[off+3 : off+33]).strip()
            files.append(name)
        cat_track = cat[1]
        cat_sector = cat[2]
    return files

def read_file_from_dsk(disk, entry):
    ts_track = entry['ts_track']
    ts_sector = entry['ts_sector']
    
    file_data = bytearray()
    
    while ts_track != 0:
        ts_list = read_sector(disk, ts_track, ts_sector)
        
        # Data sectors start at offset 12 in the T/S list
        for i in range(12, 256, 2):
            dt = ts_list[i]
            ds = ts_list[i + 1]
            if dt == 0 and ds == 0:
                # End of data references in this list (or hole)
                # However, DOS files can have holes. But for Applesoft we expect contiguous data.
                continue
            if dt != 0:
                file_data += read_sector(disk, dt, ds)
                
        ts_track = ts_list[1]
        ts_sector = ts_list[2]
        
    return file_data

def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)

    dsk_path = sys.argv[1]
    filename = sys.argv[2]
    
    if not os.path.exists(dsk_path):
        print(f"Error: Disk image '{dsk_path}' not found.")
        sys.exit(1)

    with open(dsk_path, 'rb') as f:
        disk = f.read()

    if len(disk) != DISK_SIZE:
        print(f"Error: Not a standard 140K DOS 3.3 disk image.")
        sys.exit(1)

    entry = find_catalog_entry(disk, filename)
    if not entry:
        print(f"Error: File '{filename}' not found in catalog.")
        available = list_catalog(disk)
        if available:
            print("\nAvailable files on disk:")
            for f in sorted(available):
                print(f"  - {f}")
        sys.exit(1)

    print(f"Found file '{entry['name']}' (Type: {entry['file_type']:02X})")
    
    raw_data = read_file_from_dsk(disk, entry)
    
    if entry['file_type'] & 0x7F != 0x02:
        print(f"Warning: File is not marked as Applesoft BASIC (Type 0x02).")
        # We can still try to detokenize if it's potentially BASIC
        
    # Applesoft files on DOS 3.3 have a 2-byte length header
    file_len = struct.unpack('<H', raw_data[0:2])[0]
    program_data = raw_data[2:2+file_len]
    
    print(f"Program size: {file_len} bytes")
    
    basic_text = detokenize_program(program_data)
    
    if len(sys.argv) >= 4:
        out_path = sys.argv[3]
    else:
        out_path = entry['name'].strip().replace(" ", "_").lower() + ".bas"
        
    with open(out_path, 'w', encoding='ascii', errors='replace') as f:
        f.write(basic_text)
        f.write("\n")
        
    print(f"Successfully detokenized to '{out_path}'")

if __name__ == '__main__':
    main()
