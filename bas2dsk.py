#!/usr/bin/env python3
"""
bas2dsk.py - Insert an Applesoft BASIC text file or a binary file
             into a DOS 3.3 .dsk image.

Usage:
    python bas2dsk.py <file.bas|file.bin> <image.dsk> [FILENAME_ON_DISK] [LOAD_ADDR_HEX]

Example:
    python bas2dsk.py bouncing_ball.bas MASTER.DSK "BOUNCING BALL"
    python bas2dsk.py snake.bin MASTER.DSK "SNAKE" 4000

If FILENAME_ON_DISK is not specified, the .bas filename (uppercased,
without extension) is used, truncated to 30 characters.
"""

import sys
import struct
import os
import shutil

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

# Build reverse lookup: keyword -> token byte
KEYWORD_TO_TOKEN = {}
for i, kw in enumerate(APPLESOFT_TOKENS):
    KEYWORD_TO_TOKEN[kw] = 0x80 + i


def tokenize_line(text):
    """Tokenize a single line of Applesoft BASIC (without line number)."""
    result = bytearray()
    i = 0
    in_string = False
    in_rem = False
    in_data = False

    while i < len(text):
        ch = text[i]

        # Inside a REM or DATA statement, everything is literal
        if in_rem:
            result.append(ord(ch))
            i += 1
            continue

        if in_data:
            if ch == ':':
                in_data = False
                result.append(ord(ch))
                i += 1
                continue
            result.append(ord(ch))
            i += 1
            continue

        # Toggle string mode on quotes
        if ch == '"':
            in_string = not in_string
            result.append(ord(ch))
            i += 1
            continue

        # Inside a string, everything is literal
        if in_string:
            result.append(ord(ch))
            i += 1
            continue

        # Try to match a keyword (longest match first)
        upper_rest = text[i:].upper()
        matched = False
        for kw in sorted(KEYWORD_TO_TOKEN.keys(), key=len, reverse=True):
            if upper_rest.startswith(kw):
                token = KEYWORD_TO_TOKEN[kw]
                result.append(token)
                i += len(kw)
                matched = True
                if kw == "REM":
                    in_rem = True
                elif kw == "DATA":
                    in_data = True
                break

        if not matched:
            result.append(ord(ch))
            i += 1

    return bytes(result)


def tokenize_program(text, base_addr=0x0801):
    """Tokenize a full Applesoft BASIC program from text.
    Returns the tokenized binary data (without the 2-byte length prefix)."""
    lines = text.replace('\r\n', '\n').replace('\r', '\n').split('\n')
    program_lines = []

    for line in lines:
        line = line.strip()
        if not line:
            continue

        # Parse line number
        num_str = ""
        idx = 0
        while idx < len(line) and line[idx].isdigit():
            num_str += line[idx]
            idx += 1
        if not num_str:
            continue

        line_num = int(num_str)
        rest = line[idx:].lstrip()
        tokenized = tokenize_line(rest)
        program_lines.append((line_num, tokenized))

    # Build the binary program
    result = bytearray()
    addr = base_addr

    for line_num, tok_data in program_lines:
        # next_addr = addr + 2(next ptr) + 2(line num) + len(data) + 1(zero)
        line_len = 2 + 2 + len(tok_data) + 1
        next_addr = addr + line_len
        result += struct.pack('<H', next_addr)  # pointer to next line
        result += struct.pack('<H', line_num)    # line number
        result += tok_data                       # tokenized content
        result.append(0x00)                      # end of line
        addr = next_addr

    # End of program marker
    result += struct.pack('<H', 0x0000)

    return bytes(result)


# ============================================================
# DOS 3.3 Disk Image Handling
# ============================================================

TRACK_COUNT = 35
SECTORS_PER_TRACK = 16
SECTOR_SIZE = 256
TRACK_SIZE = SECTORS_PER_TRACK * SECTOR_SIZE
DISK_SIZE = TRACK_COUNT * TRACK_SIZE  # 143360

VTOC_TRACK = 17
VTOC_SECTOR = 0


def sector_offset(track, sector):
    """Get byte offset in disk image for a given track/sector."""
    return track * TRACK_SIZE + sector * SECTOR_SIZE


def read_sector(disk, track, sector):
    """Read a 256-byte sector from disk image."""
    offset = sector_offset(track, sector)
    return bytearray(disk[offset:offset + SECTOR_SIZE])


def write_sector(disk, track, sector, data):
    """Write a 256-byte sector to disk image."""
    assert len(data) == SECTOR_SIZE
    offset = sector_offset(track, sector)
    disk[offset:offset + SECTOR_SIZE] = data


def is_sector_free(vtoc, track, sector):
    """Check if a sector is marked as free in VTOC."""
    # Free sector bitmap starts at offset 0x38 in VTOC
    # Each track has 4 bytes (32 bits for 16 sectors)
    bmp_offset = 0x38 + track * 4
    # Sectors are mapped: bit 0 of byte 0 = sector 0, etc.
    # Actually in DOS 3.3: byte 0 bits 7-0 = sectors 7-0
    #                       byte 1 bits 7-0 = sectors F-8
    if sector < 8:
        byte_idx = bmp_offset + 1
        bit = 1 << sector
    else:
        byte_idx = bmp_offset
        bit = 1 << (sector - 8)
    return bool(vtoc[byte_idx] & bit)


def mark_sector_used(vtoc, track, sector):
    """Mark a sector as used in VTOC bitmap."""
    bmp_offset = 0x38 + track * 4
    if sector < 8:
        byte_idx = bmp_offset + 1
        bit = 1 << sector
    else:
        byte_idx = bmp_offset
        bit = 1 << (sector - 8)
    vtoc[byte_idx] &= ~bit


def mark_sector_free(vtoc, track, sector):
    """Mark a sector as free in VTOC bitmap."""
    bmp_offset = 0x38 + track * 4
    if sector < 8:
        byte_idx = bmp_offset + 1
        bit = 1 << sector
    else:
        byte_idx = bmp_offset
        bit = 1 << (sector - 8)
    vtoc[byte_idx] |= bit


def allocate_sector(vtoc):
    """Allocate a free sector from VTOC. Returns (track, sector) or None."""
    # DOS 3.3 allocation: start from last allocated direction
    # For simplicity, search from track 17 outward (alternating above/below)
    search_order = []
    for delta in range(1, TRACK_COUNT):
        if VTOC_TRACK + delta < TRACK_COUNT:
            search_order.append(VTOC_TRACK + delta)
        if VTOC_TRACK - delta >= 0:
            search_order.append(VTOC_TRACK - delta)

    for track in search_order:
        for sector in range(SECTORS_PER_TRACK - 1, -1, -1):
            if is_sector_free(vtoc, track, sector):
                mark_sector_used(vtoc, track, sector)
                return (track, sector)
    return None


def find_catalog_entry(disk, filename):
    """Find a file in the catalog. Returns (cat_track, cat_sector, entry_index) or None."""
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
            name = ''.join(chr(b & 0x7F) for b in name_bytes)
            if name == padded:
                return (cat_track, cat_sector, i)
        cat_track = cat[1]
        cat_sector = cat[2]
    return None


def delete_file(disk, vtoc, filename):
    """Delete a file from the DOS 3.3 disk. Frees its sectors."""
    result = find_catalog_entry(disk, filename)
    if result is None:
        return False

    cat_track, cat_sector, entry_idx = result
    cat = read_sector(disk, cat_track, cat_sector)
    entry_off = 0x0B + entry_idx * 35

    # Get T/S list track/sector
    ts_track = cat[entry_off]
    ts_sector = cat[entry_off + 1]

    # Walk T/S list and free all data sectors
    while ts_track != 0:
        ts_list = read_sector(disk, ts_track, ts_sector)

        # Free data sectors referenced in this T/S list
        for j in range(12, 256, 2):
            dt = ts_list[j]
            ds = ts_list[j + 1]
            if dt != 0:
                mark_sector_free(vtoc, dt, ds)

        # Free the T/S list sector itself
        next_ts_track = ts_list[1]
        next_ts_sector = ts_list[2]
        mark_sector_free(vtoc, ts_track, ts_sector)
        ts_track = next_ts_track
        ts_sector = next_ts_sector

    # Mark catalog entry as deleted (store track in byte 0x20 position, set track to 0xFF)
    cat[entry_off + 0x20] = cat[entry_off]  # save original track
    cat[entry_off] = 0xFF  # mark deleted
    write_sector(disk, cat_track, cat_sector, cat)

    return True


def find_free_catalog_slot(disk):
    """Find an empty slot in the catalog. Returns (cat_track, cat_sector, entry_index) or None."""
    vtoc = read_sector(disk, VTOC_TRACK, VTOC_SECTOR)
    cat_track = vtoc[1]
    cat_sector = vtoc[2]

    while cat_track != 0:
        cat = read_sector(disk, cat_track, cat_sector)
        for i in range(7):
            entry_off = 0x0B + i * 35
            ts_track = cat[entry_off]
            if ts_track == 0 or ts_track == 0xFF:
                return (cat_track, cat_sector, i)
        cat_track = cat[1]
        cat_sector = cat[2]
    return None


def write_file_to_dsk(dsk_path, filename, file_data, file_type):
    """Write a file (Applesoft or Binary) to a DOS 3.3 disk image."""
    # Read disk image
    with open(dsk_path, 'rb') as f:
        disk = bytearray(f.read())

    if len(disk) != DISK_SIZE:
        raise ValueError(f"Not a standard DOS 3.3 disk image ({len(disk)} bytes, expected {DISK_SIZE})")

    vtoc = read_sector(disk, VTOC_TRACK, VTOC_SECTOR)
    filename = filename.upper()[:30]

    # Delete existing file with same name if present
    if find_catalog_entry(disk, filename) is not None:
        print(f"  Deleting existing file '{filename}'...")
        delete_file(disk, vtoc, filename)

    # Calculate how many data sectors we need
    data_sectors_needed = (len(file_data) + SECTOR_SIZE - 1) // SECTOR_SIZE
    # Plus T/S list sectors (1 T/S list can reference 122 data sectors)
    ts_list_count = (data_sectors_needed + 121) // 122
    total_sectors = data_sectors_needed + ts_list_count

    print(f"  File data: {len(file_data)} bytes, {data_sectors_needed} data sectors, {ts_list_count} T/S list(s)")

    # Allocate all sectors
    allocated_ts = []
    allocated_data = []

    for _ in range(ts_list_count):
        ts = allocate_sector(vtoc)
        if ts is None:
            raise RuntimeError("Disk full - not enough free sectors")
        allocated_ts.append(ts)

    for _ in range(data_sectors_needed):
        ds = allocate_sector(vtoc)
        if ds is None:
            raise RuntimeError("Disk full - not enough free sectors")
        allocated_data.append(ds)

    # Write data sectors
    for idx, (track, sector) in enumerate(allocated_data):
        start = idx * SECTOR_SIZE
        chunk = file_data[start:start + SECTOR_SIZE]
        sector_data = bytearray(SECTOR_SIZE)
        sector_data[:len(chunk)] = chunk
        write_sector(disk, track, sector, sector_data)

    # Write T/S list sectors
    data_idx = 0
    for ts_idx, (ts_track, ts_sector) in enumerate(allocated_ts):
        ts_list = bytearray(SECTOR_SIZE)

        # Link to next T/S list
        if ts_idx + 1 < len(allocated_ts):
            ts_list[1] = allocated_ts[ts_idx + 1][0]
            ts_list[2] = allocated_ts[ts_idx + 1][1]

        # Fill in data sector references
        pair_idx = 0
        while data_idx < len(allocated_data) and pair_idx < 122:
            offset = 12 + pair_idx * 2
            ts_list[offset] = allocated_data[data_idx][0]
            ts_list[offset + 1] = allocated_data[data_idx][1]
            data_idx += 1
            pair_idx += 1

        write_sector(disk, ts_track, ts_sector, ts_list)

    # Add catalog entry
    slot = find_free_catalog_slot(disk)
    if slot is None:
        raise RuntimeError("Catalog full - no free entries")

    cat_track, cat_sector, entry_idx = slot
    cat = read_sector(disk, cat_track, cat_sector)
    entry_off = 0x0B + entry_idx * 35

    cat[entry_off] = allocated_ts[0][0]       # T/S list track
    cat[entry_off + 1] = allocated_ts[0][1]   # T/S list sector
    cat[entry_off + 2] = file_type            # File type (0x02=A, 0x04=B)

    # Write filename (high-ASCII, padded with 0xA0)
    padded_name = filename.ljust(30)[:30]
    for j, ch in enumerate(padded_name):
        cat[entry_off + 3 + j] = ord(ch) | 0x80

    # Sector count
    struct.pack_into('<H', cat, entry_off + 33, total_sectors)

    write_sector(disk, cat_track, cat_sector, cat)

    # Write updated VTOC
    write_sector(disk, VTOC_TRACK, VTOC_SECTOR, vtoc)

    # Save disk image
    # Create backup first
    backup_path = dsk_path + ".bak"
    if not os.path.exists(backup_path):
        shutil.copy2(dsk_path, backup_path)
        print(f"  Backup saved: {backup_path}")

    with open(dsk_path, 'wb') as f:
        f.write(disk)

    print(f"  Successfully wrote '{filename}' to disk ({len(file_data)} bytes)")


# ============================================================
# Main
# ============================================================

def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)

    in_path = sys.argv[1]
    dsk_path = sys.argv[2]

    if len(sys.argv) >= 4:
        disk_filename = sys.argv[3]
    else:
        disk_filename = os.path.splitext(os.path.basename(in_path))[0].upper()

    print(f"Inserting '{in_path}' into '{dsk_path}' as '{disk_filename}'...")

    ext = os.path.splitext(in_path)[1].lower()
    
    if ext == '.bin':
        with open(in_path, 'rb') as f:
            raw_data = f.read()
        load_addr = 0x4000
        if len(sys.argv) >= 5:
            load_addr = int(sys.argv[4], 16)
            
        # DOS 3.3 Binary header: Address (2 bytes), Length (2 bytes)
        file_data = struct.pack('<HH', load_addr, len(raw_data)) + raw_data
        file_type = 0x04  # Binary (B)
    else:
        with open(in_path, 'r') as f:
            basic_text = f.read()
        program_data = tokenize_program(basic_text)
        file_data = struct.pack('<H', len(program_data)) + program_data
        file_type = 0x02  # Applesoft (A)

    write_file_to_dsk(dsk_path, disk_filename, file_data, file_type)
    print("Done!")


if __name__ == '__main__':
    main()
