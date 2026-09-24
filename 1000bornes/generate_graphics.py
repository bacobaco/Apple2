#!/usr/bin/env python3
"""
generate_graphics.py
Extracts the 117 Thomson MO5 DEFGR$ tiles and 20 D$ card matrices from
1000bornes/source/mbornes_listing.bas and generates cards_gfx.asm for 64tass.
Cards are generated in 5 bytes x 40 lines (200 bytes per card, 35x40 pixels)
giving 1:1 exact, crisp rendering of J.Y. Boucrot's original MO5 graphics.

Refinements:
- Milestones (Cards 0, 11..15): shifted right by 3 pixels to be perfectly centered!
- Milestones dome: bright RED/ORANGE fill on lines 8..15 for all milestone cards!
- Traffic lights (Cards 5, 10): shifted right by 2 pixels to be perfectly centered!
- Feu Rouge: top circle colored bright RED/ORANGE (palette bit 7 = 1)
- Feu Vert: bottom circle colored bright GREEN (palette bit 7 = 0)
- Top-left corner letters: descended by 2 pixels (lines 1 and 2 white, letter on lines 3..9)
- Bottom-right corner letters: moved UP by 1 pixel (lines 31..37 instead of 32..38), shifted 1 px left
- Card 02 (Accident): closed top bar on 'A' (.XXX.)
"""

import os
import sys

def main():
    bas_path = os.path.join(os.path.dirname(__file__), 'source', 'mbornes_listing.bas')
    with open(bas_path, 'r', encoding='latin1') as f:
        text = f.read()

    pos = text.find('274 DATA')
    if pos == -1:
        print("Error: line 274 DATA not found")
        sys.exit(1)

    tokens = [t.strip() for t in text[pos+8:].replace('\n', ',').split(',') if t.strip()]

    # Decode 117 DEFGR$ characters
    chars = []
    idx = 0
    for i in range(117):
        c = [int(tokens[idx + j]) for j in range(8)]
        chars.append(c)
        idx += 8

    # Standard ASCII font for card letters (A..Z, *, etc.)
    ascii_font = {
        32: [0]*8,
        42: [0, 0x14, 0x08, 0x3E, 0x08, 0x14, 0, 0], # '*'
        65: [0x1C, 0x22, 0x22, 0x3E, 0x22, 0x22, 0x22, 0], # 'A'
        67: [0x1E, 0x20, 0x20, 0x20, 0x20, 0x20, 0x1E, 0], # 'C'
        69: [0x3E, 0x20, 0x20, 0x3C, 0x20, 0x20, 0x3E, 0], # 'E'
        70: [0x3E, 0x20, 0x20, 0x3C, 0x20, 0x20, 0x20, 0], # 'F'
        73: [0x1C, 0x08, 0x08, 0x08, 0x08, 0x08, 0x1C, 0], # 'I'
        76: [0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x3E, 0], # 'L'
        78: [0x22, 0x32, 0x2A, 0x26, 0x22, 0x22, 0x22, 0], # 'N'
        80: [0x3C, 0x22, 0x22, 0x3C, 0x20, 0x20, 0x20, 0], # 'P'
        82: [0x3C, 0x22, 0x22, 0x3C, 0x28, 0x24, 0x22, 0], # 'R'
        83: [0x1E, 0x20, 0x1C, 0x02, 0x02, 0x22, 0x1C, 0], # 'S'
        86: [0x22, 0x22, 0x22, 0x22, 0x14, 0x14, 0x08, 0], # 'V'
    }

    # Decode 20 cards
    cards = []
    for i in range(20):
        lines = []
        for j in range(5):
            row = []
            while idx < len(tokens):
                k = int(tokens[idx])
                idx += 1
                if k == 0:
                    break
                elif k > 0:
                    if k == 1322:
                        k = 132  # Typo fix in Boucrot's listing
                    row.append(k)
            lines.append(row)
        cards.append(lines)

    # Function to render card to 35x40 Apple II HGR (5 bytes x 40 lines = 200 bytes)
    def render_card_hgr(c_idx):
        lines = cards[c_idx]
        px32 = [[0]*32 for _ in range(40)]
        for r in range(5):
            row_chars = lines[r]
            for col in range(min(4, len(row_chars))):
                ch = row_chars[col]
                if ch >= 128:
                    bitmap = chars[ch - 128]
                else:
                    bitmap = ascii_font.get(ch, [0]*8)
                for y in range(8):
                    b = bitmap[y]
                    for x in range(8):
                        if b & (1 << (7 - x)):
                            px32[r*8 + y][col*8 + x] = 1

        # Determine horizontal shift to center illustrations:
        # Milestones: +3 pixels right
        # Traffic lights: +2 pixels right
        shift_x = 0
        if c_idx in (11, 12, 13, 14, 15):
            shift_x = 3
        elif c_idx in (0, 5, 10):
            shift_x = 2

        # Apple II HGR grid: 35 wide, 40 high
        # 0 = black pixel (off), 1 = white pixel (on)
        grid = [[1]*35 for _ in range(40)]

        # Black border top and bottom
        for x in range(35):
            grid[0][x] = 0
            grid[39][x] = 0

        # Black border left and right
        for y in range(40):
            grid[y][0] = 0
            grid[y][33] = 0
            grid[y][34] = 0

        # Copy interior MO5 pixels:
        for y in range(1, 39):
            # For cards 1..10, row 0 (y < 8) is corner letter, don't shift
            s = shift_x if (y >= 8 or c_idx not in range(1, 11)) else 0
            for x in range(32):
                if px32[y][x]:
                    target_x = x + 1 + s
                    if target_x < 33:
                        grid[y][target_x] = 0 # Black ink

        # Corner letter adjustments for cards 1..10:
        if 1 <= c_idx <= 10:
            ch_tl = lines[0][0]
            bm_tl = list(ascii_font.get(ch_tl, [0]*8))
            if c_idx == 2:
                bm_tl = [0x1C, 0x22, 0x22, 0x3E, 0x22, 0x22, 0x22, 0] # Closed 'A'

            # Clear top-left corner area: lines 1..9, x in 1..9
            for y in range(1, 10):
                for x in range(1, 10):
                    if y < 8 or (c_idx not in (5, 10)):
                        grid[y][x] = 1 # White background

            # Descend top-left letter by 2 pixels, shifted 1 pixel right (x=2+bit) to decouple from border:
            # Lines 1 and 2 remain 1 (white)!
            # Lines 3..9 get the letter (rows 0..6):
            for row in range(7):
                b = bm_tl[row]
                for bit in range(8):
                    if b & (1 << (7 - bit)):
                        if 2 + bit < 33:
                            grid[3 + row][2 + bit] = 0 # Black ink for letter

            # Bottom-right corner:
            # Move UP by 1 pixel (lines 31..37 instead of 32..38), shift left 1 pixel (x in 24..31)
            ch_br = lines[4][3] if len(lines[4]) > 3 else lines[4][-1]
            bm_br = list(ascii_font.get(ch_br, [0]*8))
            if c_idx == 2:
                bm_br = [0x1C, 0x22, 0x22, 0x3E, 0x22, 0x22, 0x22, 0]

            for y in range(31, 39):
                for x in range(24, 33):
                    grid[y][x] = 1 # White

            for row in range(7):
                b = bm_br[row]
                for bit in range(8):
                    if b & (1 << (7 - bit)):
                        if 24 + bit < 33:
                            grid[31 + row][24 + bit] = 0 # Black ink

        # Dedicated typography & spacing for the 4 Bottes (Cards 16..19)
        if 16 <= c_idx <= 19:
            font_6x5 = {
                '*': [0b01010, 0b00100, 0b11111, 0b00100, 0b01010, 0b00000],
                'C': [0b01110, 0b10001, 0b10000, 0b10000, 0b10001, 0b01110],
                'I': [0b11111, 0b00100, 0b00100, 0b00100, 0b00100, 0b11111],
                'A': [0b01110, 0b10001, 0b10001, 0b11111, 0b10001, 0b10001],
                'V': [0b10001, 0b10001, 0b10001, 0b10001, 0b01010, 0b00100],
                'N': [0b10001, 0b11001, 0b10101, 0b10011, 0b10001, 0b10001],
                'P': [0b11110, 0b10001, 0b10001, 0b11110, 0b10000, 0b10000]
            }
            # Clear top area (lines 1..8) and bottom area (lines 31..38)
            for y in range(1, 9):
                for x in range(1, 33):
                    grid[y][x] = 1
            for y in range(31, 39):
                for x in range(1, 33):
                    grid[y][x] = 1

            # Clear and re-copy central illustration cleanly (lines 8..30)
            for y in range(8, 31):
                for x in range(1, 33):
                    grid[y][x] = 1

            y_offset = -1 if c_idx in (17, 19) else 0
            for y in range(8, 32):
                target_y = y + y_offset
                if 7 <= target_y <= 30:
                    for x in range(32):
                        if px32[y][x]:
                            if x + 1 < 33:
                                grid[target_y][x + 1] = 0

            botte_chars = {
                16: ('C', 'I'),
                17: ('A', 'V'),
                18: ('I', 'N'),
                19: ('V', 'P')
            }
            c1, c2 = botte_chars[c_idx]
            botte_text_chars = ['*', c1, c2, '*']
            xs = [3, 11, 19, 27]

            # Top text: lines 2..7 (leaving line 1 as white margin!)
            for r in range(6):
                for ch, start_x in zip(botte_text_chars, xs):
                    pat = font_6x5[ch][r]
                    for bit in range(5):
                        if pat & (1 << (4 - bit)):
                            grid[2 + r][start_x + bit] = 0

            # Bottom text: lines 32..37 (leaving line 38 as white margin!)
            for r in range(6):
                for ch, start_x in zip(botte_text_chars, xs):
                    pat = font_6x5[ch][r]
                    for bit in range(5):
                        if pat & (1 << (4 - bit)):
                            grid[32 + r][start_x + bit] = 0

        # Convert 35 pixels to 5 bytes per row
        raw_bytes = []
        for y in range(40):
            if y == 0 or y == 39:
                raw_bytes.extend([0x00] * 5)
                continue

            for b in range(5):
                val = 0
                for bit in range(7):
                    if grid[y][b * 7 + bit]:
                        val |= (1 << bit)
                raw_bytes.append(val)

        # Red/Orange dome on ALL bornes (0, 11..15) for lines 8..15 (Even column pattern)
        if c_idx in (0, 11, 12, 13, 14, 15):
            even_dome = [
                [0x7E, 0xD7, 0xAA, 0xFD, 0x1F],
                [0x7E, 0xD7, 0xAA, 0xF5, 0x1F],
                [0x7E, 0xD5, 0xAA, 0xF5, 0x1F],
                [0x7E, 0xD5, 0xAA, 0xD5, 0x1F],
                [0xBE, 0xD5, 0xAA, 0xD5, 0x1F],
                [0xBE, 0xD5, 0xAA, 0xD5, 0x1F],
                [0xBE, 0xD5, 0xAA, 0xD5, 0x9E],
                [0xBE, 0xD5, 0xAA, 0xD5, 0x9E]
            ]
            for idx_y, y in enumerate(range(8, 16)):
                for b in range(5):
                    raw_bytes[y * 5 + b] = even_dome[idx_y][b]

        # Red circle on Feu Rouge (Carte 5, shifted by 2, lines 10..13)
        if c_idx == 5:
            for y in [10, 11, 12, 13]:
                raw_bytes[y * 5 + 1] = (raw_bytes[y * 5 + 1] | 0x80) & ~0x70 | 0x40
                raw_bytes[y * 5 + 2] = (raw_bytes[y * 5 + 2] | 0x80) & ~0x07 | 0x2A

        # Green circle on Feu Vert (Carte 10, shifted by 2, lines 26..29)
        if c_idx == 10:
            for y in [26, 27, 28, 29]:
                raw_bytes[y * 5 + 1] = (raw_bytes[y * 5 + 1] & ~0x80) & ~0x70 | 0x40
                raw_bytes[y * 5 + 2] = (raw_bytes[y * 5 + 2] & ~0x80) & ~0x07 | 0x2A

        assert len(raw_bytes) == 200, f"Card {c_idx} wrong length {len(raw_bytes)}"
        return raw_bytes

    # Generate 20 cards
    all_cards = []
    for i in range(20):
        all_cards.append(render_card_hgr(i))

    # Also build empty slot border (Slot Empty: just border + empty interior)
    empty_card = []
    for y in range(40):
        if y == 0 or y == 39:
            empty_card.extend([0x7F, 0x7F, 0x7F, 0x7F, 0x7F])
        else:
            empty_card.extend([0x01, 0x00, 0x00, 0x00, 0x40])

    # 7x8 ASCII font (0..127)
    font_bytes = generate_font()

    # Precompute 192 lines of HGR Row Low and High addresses
    hgr_row_lo = []
    hgr_row_hi = []
    for y in range(192):
        addr = 0x2000 + (y % 8) * 0x400 + ((y // 8) % 8) * 0x80 + (y // 64) * 0x28
        hgr_row_lo.append(addr & 0xFF)
        hgr_row_hi.append((addr >> 8) & 0xFF)

    # Output assembly file
    out_path = os.path.join(os.path.dirname(__file__), 'cards_gfx.asm')
    with open(out_path, 'w', encoding='utf-8') as out:
        out.write('; =============================================================================\n')
        out.write('; CARDS_GFX.ASM - DONNEES GRAPHIQUES HGR POUR 1000 BORNES APPLE II\n')
        out.write('; Genere automatiquement a partir des DEFGR$ du Thomson MO5 (J.Y. Boucrot 1985)\n')
        out.write('; Format : 5 octets x 40 lignes (200 octets par carte, 35x40 pixels, 1:1 exact)\n')
        out.write('; =============================================================================\n\n')

        # HGR row lookup tables
        out.write("; --- TABLES D'ADRESSES DES 192 LIGNES HGR ($2000-$3FFF) ---\n")
        out.write('HGR_ROW_LO\n')
        for i in range(0, 192, 16):
            out.write('    .byte ' + ', '.join('$%02X' % v for v in hgr_row_lo[i:i+16]) + '\n')
        out.write('\nHGR_ROW_HI\n')
        for i in range(0, 192, 16):
            out.write('    .byte ' + ', '.join('$%02X' % v for v in hgr_row_hi[i:i+16]) + '\n')

        # Card pointers table (21 cards: 0 = Empty/Borne, 1..19 = Game cards, 20 = Empty frame)
        out.write('\n; --- TABLES DE POINTEURS VERS LES BITMAPS DES CARTES (200 octets par carte) ---\n')
        out.write('CARD_PTR_LO\n')
        out.write('    .byte ' + ', '.join('<CARD_GFX_%02d' % i for i in range(21)) + '\n')
        out.write('CARD_PTR_HI\n')
        out.write('    .byte ' + ', '.join('>CARD_GFX_%02d' % i for i in range(21)) + '\n\n')

        # 21 card bitmaps
        card_names = [
            "00_BORNE_TITRE",
            "01_PANNE_ESSENCE",
            "02_ACCIDENT",
            "03_CREVAISON",
            "04_LIMITATION_50",
            "05_FEU_ROUGE",
            "06_ESSENCE",
            "07_REPARATIONS",
            "08_ROUE_SECOURS",
            "09_FIN_LIMITATION",
            "10_FEU_VERT",
            "11_ETAPE_200KM",
            "12_ETAPE_100KM",
            "13_ETAPE_75KM",
            "14_ETAPE_50KM",
            "15_ETAPE_25KM",
            "16_CITERNE_ESSENCE",
            "17_AS_DU_VOLANT",
            "18_INCREVABLE",
            "19_VEHICULE_PRIORITAIRE",
            "20_SLOT_EMPTY"
        ]

        for i in range(20):
            out.write('; Carte %02d : %s (200 octets, 5 octets x 40 lignes)\n' % (i, card_names[i]))
            out.write('CARD_GFX_%02d\n' % i)
            cb = all_cards[i]
            for y in range(40):
                row = cb[y*5 : (y+1)*5]
                out.write('    .byte ' + ', '.join('$%02X' % v for v in row) + '\n')
            out.write('\n')

        out.write('; Carte 20 : %s (Cadre vide, 200 octets)\n' % card_names[20])
        out.write('CARD_GFX_20\n')
        for y in range(40):
            row = empty_card[y*5 : (y+1)*5]
            out.write('    .byte ' + ', '.join('$%02X' % v for v in row) + '\n')
        out.write('\n')

        # Font table
        out.write('; --- POLICE DE CARACTERES HGR 7x8 (128 caracteres x 8 octets = 1024 octets) ---\n')
        out.write('FONT_7X8\n')
        for ch in range(128):
            glyph = font_bytes[ch*8 : (ch+1)*8]
            ascii_repr = repr(chr(ch)) if 32 <= ch < 127 else str(ch)
            out.write('    ; Ch %d (%s)\n' % (ch, ascii_repr))
            out.write('    .byte ' + ', '.join('$%02X' % v for v in glyph) + '\n')

    print(f"Generated {out_path} successfully!")


def generate_font():
    # Build complete standard 7x8 ASCII font
    font = [0] * (128 * 8)
    
    digits = {
        '0': [0x1C, 0x22, 0x22, 0x22, 0x22, 0x22, 0x1C, 0],
        '1': [0x08, 0x18, 0x28, 0x08, 0x08, 0x08, 0x3E, 0],
        '2': [0x1C, 0x22, 0x02, 0x04, 0x08, 0x10, 0x3E, 0],
        '3': [0x3E, 0x02, 0x04, 0x1C, 0x02, 0x22, 0x1C, 0],
        '4': [0x04, 0x0C, 0x14, 0x24, 0x3E, 0x04, 0x04, 0],
        '5': [0x3E, 0x20, 0x3C, 0x02, 0x02, 0x22, 0x1C, 0],
        '6': [0x1C, 0x20, 0x20, 0x3C, 0x22, 0x22, 0x1C, 0],
        '7': [0x3E, 0x02, 0x04, 0x08, 0x10, 0x10, 0x10, 0],
        '8': [0x1C, 0x22, 0x22, 0x1C, 0x22, 0x22, 0x1C, 0],
        '9': [0x1C, 0x22, 0x22, 0x1E, 0x02, 0x02, 0x1C, 0],
    }
    
    upper = {
        'A': [0x1C, 0x22, 0x22, 0x3E, 0x22, 0x22, 0x22, 0],
        'B': [0x3C, 0x22, 0x22, 0x3C, 0x22, 0x22, 0x3C, 0],
        'C': [0x1E, 0x20, 0x20, 0x20, 0x20, 0x20, 0x1E, 0],
        'D': [0x38, 0x24, 0x22, 0x22, 0x22, 0x24, 0x38, 0],
        'E': [0x3E, 0x20, 0x20, 0x3C, 0x20, 0x20, 0x3E, 0],
        'F': [0x3E, 0x20, 0x20, 0x3C, 0x20, 0x20, 0x20, 0],
        'G': [0x1E, 0x20, 0x20, 0x2E, 0x22, 0x22, 0x1E, 0],
        'H': [0x22, 0x22, 0x22, 0x3E, 0x22, 0x22, 0x22, 0],
        'I': [0x1C, 0x08, 0x08, 0x08, 0x08, 0x08, 0x1C, 0],
        'J': [0x06, 0x02, 0x02, 0x02, 0x02, 0x22, 0x1C, 0],
        'K': [0x22, 0x24, 0x28, 0x30, 0x28, 0x24, 0x22, 0],
        'L': [0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x3E, 0],
        'M': [0x22, 0x36, 0x2A, 0x22, 0x22, 0x22, 0x22, 0],
        'N': [0x22, 0x32, 0x2A, 0x26, 0x22, 0x22, 0x22, 0],
        'O': [0x1C, 0x22, 0x22, 0x22, 0x22, 0x22, 0x1C, 0],
        'P': [0x3C, 0x22, 0x22, 0x3C, 0x20, 0x20, 0x20, 0],
        'Q': [0x1C, 0x22, 0x22, 0x22, 0x26, 0x22, 0x1D, 0],
        'R': [0x3C, 0x22, 0x22, 0x3C, 0x28, 0x24, 0x22, 0],
        'S': [0x1E, 0x20, 0x20, 0x1C, 0x02, 0x22, 0x1C, 0],
        'T': [0x3E, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0],
        'U': [0x22, 0x22, 0x22, 0x22, 0x22, 0x22, 0x1C, 0],
        'V': [0x22, 0x22, 0x22, 0x22, 0x14, 0x14, 0x08, 0],
        'W': [0x22, 0x22, 0x22, 0x2A, 0x2A, 0x36, 0x22, 0],
        'X': [0x22, 0x22, 0x14, 0x08, 0x14, 0x22, 0x22, 0],
        'Y': [0x22, 0x22, 0x14, 0x08, 0x08, 0x08, 0x08, 0],
        'Z': [0x3E, 0x02, 0x04, 0x08, 0x10, 0x20, 0x3E, 0],
    }

    symbols = {
        ' ': [0, 0, 0, 0, 0, 0, 0, 0],
        '!': [0x08, 0x08, 0x08, 0x08, 0x08, 0x00, 0x08, 0],
        '"': [0x14, 0x14, 0x14, 0x00, 0x00, 0x00, 0x00, 0],
        '#': [0x14, 0x14, 0x3E, 0x14, 0x3E, 0x14, 0x14, 0],
        '$': [0x08, 0x1E, 0x28, 0x1C, 0x0A, 0x3C, 0x08, 0],
        '%': [0x22, 0x24, 0x08, 0x10, 0x20, 0x12, 0x22, 0],
        '&': [0x18, 0x24, 0x28, 0x10, 0x2A, 0x24, 0x1A, 0],
        '\'': [0x08, 0x08, 0x10, 0x00, 0x00, 0x00, 0x00, 0],
        '(': [0x04, 0x08, 0x10, 0x10, 0x10, 0x08, 0x04, 0],
        ')': [0x10, 0x08, 0x04, 0x04, 0x04, 0x08, 0x10, 0],
        '*': [0x00, 0x14, 0x08, 0x3E, 0x08, 0x14, 0x00, 0],
        '+': [0x00, 0x08, 0x08, 0x3E, 0x08, 0x08, 0x00, 0],
        ',': [0x00, 0x00, 0x00, 0x00, 0x08, 0x08, 0x10, 0],
        '-': [0x00, 0x00, 0x00, 0x3E, 0x00, 0x00, 0x00, 0],
        '.': [0x00, 0x00, 0x00, 0x00, 0x00, 0x0C, 0x0C, 0],
        '/': [0x02, 0x04, 0x08, 0x10, 0x20, 0x00, 0x00, 0],
        ':': [0x00, 0x0C, 0x0C, 0x00, 0x0C, 0x0C, 0x00, 0],
        ';': [0x00, 0x0C, 0x0C, 0x00, 0x08, 0x08, 0x10, 0],
        '<': [0x02, 0x04, 0x08, 0x10, 0x08, 0x04, 0x02, 0],
        '=': [0x00, 0x3E, 0x00, 0x3E, 0x00, 0x00, 0x00, 0],
        '>': [0x20, 0x10, 0x08, 0x04, 0x08, 0x10, 0x20, 0],
        '?': [0x1C, 0x22, 0x04, 0x08, 0x08, 0x00, 0x08, 0],
        '@': [0x1C, 0x22, 0x2E, 0x2A, 0x2E, 0x20, 0x1E, 0],
        '[': [0x1C, 0x10, 0x10, 0x10, 0x10, 0x10, 0x1C, 0],
        '\\': [0x20, 0x10, 0x08, 0x04, 0x02, 0x00, 0x00, 0],
        ']': [0x1C, 0x04, 0x04, 0x04, 0x04, 0x04, 0x1C, 0],
        '^': [0x08, 0x14, 0x22, 0x00, 0x00, 0x00, 0x00, 0],
        '_': [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x3E, 0],
    }

    lower = {
        'a': [0x00, 0x00, 0x1C, 0x02, 0x1E, 0x22, 0x1E, 0],
        'b': [0x20, 0x20, 0x3C, 0x22, 0x22, 0x22, 0x3C, 0],
        'c': [0x00, 0x00, 0x1E, 0x20, 0x20, 0x20, 0x1E, 0],
        'd': [0x02, 0x02, 0x1E, 0x22, 0x22, 0x22, 0x1E, 0],
        'e': [0x00, 0x00, 0x1C, 0x22, 0x3E, 0x20, 0x1E, 0],
        'f': [0x0C, 0x12, 0x10, 0x38, 0x10, 0x10, 0x10, 0],
        'g': [0x00, 0x00, 0x1E, 0x22, 0x22, 0x1E, 0x02, 0x1C],
        'h': [0x20, 0x20, 0x3C, 0x22, 0x22, 0x22, 0x22, 0],
        'i': [0x08, 0x00, 0x18, 0x08, 0x08, 0x08, 0x1C, 0],
        'j': [0x04, 0x00, 0x0C, 0x04, 0x04, 0x24, 0x18, 0],
        'k': [0x20, 0x20, 0x24, 0x28, 0x30, 0x28, 0x24, 0],
        'l': [0x18, 0x08, 0x08, 0x08, 0x08, 0x08, 0x1C, 0],
        'm': [0x00, 0x00, 0x36, 0x2A, 0x2A, 0x22, 0x22, 0],
        'n': [0x00, 0x00, 0x3C, 0x22, 0x22, 0x22, 0x22, 0],
        'o': [0x00, 0x00, 0x1C, 0x22, 0x22, 0x22, 0x1C, 0],
        'p': [0x00, 0x00, 0x3C, 0x22, 0x22, 0x3C, 0x20, 0x20],
        'q': [0x00, 0x00, 0x1E, 0x22, 0x22, 0x1E, 0x02, 0x02],
        'r': [0x00, 0x00, 0x2E, 0x32, 0x20, 0x20, 0x20, 0],
        's': [0x00, 0x00, 0x1E, 0x20, 0x1C, 0x02, 0x3C, 0],
        't': [0x10, 0x10, 0x38, 0x10, 0x10, 0x12, 0x0C, 0],
        'u': [0x00, 0x00, 0x22, 0x22, 0x22, 0x26, 0x1A, 0],
        'v': [0x00, 0x00, 0x22, 0x22, 0x14, 0x14, 0x08, 0],
        'w': [0x00, 0x00, 0x22, 0x22, 0x2A, 0x2A, 0x14, 0],
        'x': [0x00, 0x00, 0x22, 0x14, 0x08, 0x14, 0x22, 0],
        'y': [0x00, 0x00, 0x22, 0x22, 0x1E, 0x02, 0x1C, 0],
        'z': [0x00, 0x00, 0x3E, 0x04, 0x08, 0x10, 0x3E, 0],
    }

    all_defs = {}
    all_defs.update(symbols)
    all_defs.update(digits)
    all_defs.update(upper)
    all_defs.update(lower)

    for ch_str, glyph in all_defs.items():
        code = ord(ch_str)
        if code < 128:
            for row in range(8):
                v = glyph[row] & 0x7F
                r = 0
                for bit in range(7):
                    if v & (1 << (6 - bit)):
                        r |= (1 << bit)
                font[code * 8 + row] = r

    return font

if __name__ == '__main__':
    main()
