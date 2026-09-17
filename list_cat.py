import struct
import sys

def read_sector(disk, track, sector):
    offset = (track * 16 + sector) * 256
    return disk[offset:offset + 256]

def list_catalog(dsk_path):
    with open(dsk_path, 'rb') as f:
        disk = f.read()
    
    vtoc = read_sector(disk, 17, 0)
    cat_track = vtoc[1]
    cat_sector = vtoc[2]
    
    print(f"{'Name':<32} {'Type':<5} {'Sectors':<5}")
    print("-" * 45)
    
    while cat_track != 0:
        cat = read_sector(disk, cat_track, cat_sector)
        for i in range(7):
            off = 0x0B + i * 35
            if cat[off] == 0 or cat[off] == 0xFF:
                continue
            
            type_byte = cat[off + 2]
            locked = " "
            if type_byte & 0x80:
                locked = "*"
            
            t = type_byte & 0x7F
            type_str = {0x00: 'T', 0x01: 'I', 0x02: 'A', 0x04: 'B', 0x08: 'S', 0x10: 'R', 0x20: 'A', 0x40: 'B'}.get(t, '?')
            
            name = "".join(chr(b & 0x7F) for b in cat[off+3 : off+33]).strip()
            sectors = struct.unpack('<H', cat[off+33 : off+35])[0]
            
            print(f"{locked}{name:<30} {type_str:<5} {sectors:<5}")
            
        cat_track = cat[1]
        cat_sector = cat[2]

if __name__ == "__main__":
    list_catalog(sys.argv[1])
