#!/usr/bin/env python3
"""
build_pang_assets.py
Generates Apple II HGR pre-shifted sprite tables, lookup tables, and complete ASCII font
for the Pang! arcade port.

Sprites generated:
  - Buster (Player): 14x20 (Stand, Walk1, Walk2, Shoot, Hit)
  - Harpoon tip: 7x8
  - Pop explosion: 8x8
  - Bubbles: 8x8 (size 0), 14x14 (size 1), 20x20 (size 2), 26x26 (size 3)
  - Full ASCII Font: 8x8 for ASCII 32 (' ') through 90 ('Z')
"""

import math

def generate_hgr_tables():
    """
    Computes Apple II HGR line base addresses for lines 0..191.
    HGR Page 1 base: $2000.
    Formula: Base = $2000 + ((Y % 8) * $400) + ((Y // 64) * $28) + (((Y % 64) // 8) * $80)
    """
    hgr_lo = []
    hgr_hi = []
    for y in range(192):
        addr = 0x2000 + ((y % 8) * 0x400) + ((y // 64) * 0x28) + (((y % 64) // 8) * 0x80)
        hgr_lo.append(addr & 0xFF)
        hgr_hi.append((addr >> 8) & 0xFF)
    return hgr_lo, hgr_hi

def parse_ascii_art(art_lines, color_palette_bit=1):
    """
    Parses ASCII art lines or bit arrays.
    """
    rows = []
    if isinstance(art_lines[0], list):
        # Already bit arrays
        for r in art_lines:
            row_int = sum((bit << x) for x, bit in enumerate(r))
            rows.append(row_int)
        return rows, len(art_lines[0]), len(art_lines)

    width = len(art_lines[0].strip())
    for y, line in enumerate(art_lines):
        s = line.strip()
        if not s:
            continue
        row_bits = 0
        for x, ch in enumerate(s):
            if ch != '.' and ch != ' ':
                row_bits |= (1 << x)
        rows.append(row_bits)
    return rows, width, len(rows)

def make_shifted_sprite(rows, width, height, bytes_per_line, palette_bit=0x80):
    """
    Shifts bitmap across 0..6 bits.
    In Apple II HGR, bit 7 is the palette selection bit.
    palette_bit = 0x80 (Blue/Orange) or 0x00 (Violet/Green)
    """
    shifts = []
    for shift in range(7):
        shift_data = []
        for row in rows:
            shifted = row << shift
            for b in range(bytes_per_line):
                byte_val = (shifted >> (b * 7)) & 0x7F
                if byte_val != 0 and palette_bit != 0:
                    byte_val |= palette_bit
                shift_data.append(byte_val)
        shifts.append(shift_data)
    return shifts

# ===================================================================
# HIGH-FIDELITY BUSTER (PLAYER) - 14 pixels wide x 20 scanlines tall
# Hand-tuned for Apple II HGR NTSC Color Artifacting:
# Even bits isolated (0, 2, 4, 6, 8, 10, 12) + palette bit 1 = BLUE
# Odd bits isolated (1, 3, 5, 7, 9, 11, 13) + palette bit 1 = ORANGE
# Adjacent 11 bits = SOLID WHITE
# 0 bits = BLACK outlines, pupils, suspenders, separations
# ===================================================================

ART_PLAYER_STAND = [
    # 0: Cap dome (Orange)
    [0,0,0,1,0,1,0,1,0,1,0,0,0,0],
    # 1: Cap body (Orange)
    [0,0,1,1,0,1,0,1,0,1,1,0,0,0],
    # 2: Cap visor pointing right (Visor is solid/orange)
    [0,0,0,1,0,1,0,1,0,1,1,1,0,0],
    # 3: Dark hair fringe under cap + forehead
    [0,0,1,0,0,1,1,1,1,0,0,1,0,0],
    # 4: Eyes: White sclera with dark pupils + nose
    [0,0,1,1,0,1,0,0,1,0,1,1,0,0],
    # 5: Cheeks + Mouth (smile)
    [0,0,0,1,1,1,0,0,1,1,1,0,0,0],
    # 6: Chin / neck
    [0,0,0,0,1,1,1,1,1,0,0,0,0,0],
    # 7: Shirt collar (Orange) + Suspenders top (Blue)
    [0,0,1,0,0,1,0,1,0,0,1,0,0,0],
    # 8: Chest: Blue straps (even=2,10), Orange shirt center (odd=5,7)
    [0,1,1,0,0,1,0,1,0,0,1,1,0,0],
    # 9: Torso: Blue straps + Orange shirt + arms on sides
    [1,0,1,0,0,1,0,1,0,0,1,0,1,0],
    # 10: Hands + Belt (Blue dungarees waist with buckle)
    [1,0,1,0,1,1,1,1,0,1,0,1,0,0],
    # 11: Dungarees waist (Blue: 2, 4, 8, 10)
    [0,0,1,0,1,0,0,1,0,1,0,0,0,0],
    # 12: Shorts pelvic section (Blue)
    [0,0,1,0,1,1,0,1,1,0,1,0,0,0],
    # 13: Shorts legs (Blue cuffs: left 2..4, right 8..10)
    [0,0,1,0,1,0,0,0,1,0,1,0,0,0],
    # 14: Shorts bottom cuffs
    [0,0,1,0,1,0,0,0,1,0,1,0,0,0],
    # 15: Bare knees / legs (Skin: 3, 9)
    [0,0,0,1,0,0,0,0,0,1,0,0,0,0],
    # 16: White socks (11 at 3..4 and 8..9)
    [0,0,0,1,1,0,0,0,1,1,0,0,0,0],
    # 17: Boots tops (Orange: 3, 5, 7, 9)
    [0,0,1,1,0,0,0,0,0,1,1,0,0,0],
    # 18: Boots feet (Orange shoes pointing out)
    [0,1,1,1,0,0,0,0,0,1,1,1,0,0],
    # 19: Boot soles (Treads)
    [0,1,0,1,0,0,0,0,0,1,0,1,0,0]
]

ART_PLAYER_WALK1 = [
    # 0: Cap dome (Orange)
    [0,0,0,1,0,1,0,1,0,1,0,0,0,0],
    # 1: Cap body (Orange)
    [0,0,1,1,0,1,0,1,0,1,1,0,0,0],
    # 2: Cap visor pointing right
    [0,0,0,1,0,1,0,1,0,1,1,1,0,0],
    # 3: Forehead & hair
    [0,0,1,0,0,1,1,1,1,0,0,1,0,0],
    # 4: Eyes: Looking right
    [0,0,0,1,1,0,1,0,1,1,0,0,0,0],
    # 5: Smile / cheeks
    [0,0,0,0,1,1,1,1,1,0,0,0,0,0],
    # 6: Neck
    [0,0,0,0,1,1,1,1,0,0,0,0,0,0],
    # 7: Shoulders / Orange shirt + Blue suspenders
    [0,0,1,0,0,1,0,1,0,0,1,0,0,0],
    # 8: Arm forward (left), arm back (right)
    [0,1,1,0,0,1,0,1,0,0,0,1,1,0],
    # 9: Torso / Orange shirt
    [1,0,1,0,0,1,0,1,0,0,1,0,1,0],
    # 10: Belt / Overalls waist
    [0,0,1,0,1,1,1,1,0,1,0,0,0,0],
    # 11: Dungarees (stride: left leg forward, right leg back)
    [0,0,1,0,1,1,0,1,1,0,0,0,0,0],
    # 12: Shorts cuffs (spread out)
    [0,1,0,1,0,0,0,0,1,0,1,0,0,0],
    # 13: Shorts bottom
    [0,1,0,1,0,0,0,0,0,1,0,1,0,0],
    # 14: Legs (left forward at x=1..3, right back at x=9..11)
    [0,0,1,0,0,0,0,0,0,0,1,0,0,0],
    # 15: Socks
    [0,1,1,0,0,0,0,0,0,1,1,0,0,0],
    # 16: Left boot forward
    [1,1,1,0,0,0,0,0,0,1,1,0,0,0],
    # 17: Left boot toe
    [1,0,1,0,0,0,0,0,0,0,1,1,1,0],
    # 18: Right boot back
    [0,0,0,0,0,0,0,0,0,0,1,1,1,0],
    # 19: Soles
    [1,0,1,0,0,0,0,0,0,0,1,0,1,0]
]

ART_PLAYER_WALK2 = [
    # 0: Cap dome (Orange)
    [0,0,0,1,0,1,0,1,0,1,0,0,0,0],
    # 1: Cap body (Orange)
    [0,0,1,1,0,1,0,1,0,1,1,0,0,0],
    # 2: Cap visor pointing right
    [0,0,0,1,0,1,0,1,0,1,1,1,0,0],
    # 3: Forehead & hair
    [0,0,1,0,0,1,1,1,1,0,0,1,0,0],
    # 4: Eyes: Looking right
    [0,0,0,0,1,1,0,1,0,1,1,0,0,0],
    # 5: Smile / cheeks
    [0,0,0,0,1,1,1,1,1,0,0,0,0,0],
    # 6: Neck
    [0,0,0,0,0,1,1,1,1,0,0,0,0,0],
    # 7: Shoulders / Orange shirt + Blue suspenders
    [0,0,0,1,0,0,1,0,1,0,0,1,0,0],
    # 8: Arm back (left), arm forward (right)
    [0,1,1,0,0,0,1,0,1,0,0,1,1,0],
    # 9: Torso / Orange shirt
    [0,1,0,1,0,0,1,0,1,0,0,1,0,1],
    # 10: Belt / Overalls waist
    [0,0,0,0,1,0,1,1,1,1,0,1,0,0],
    # 11: Dungarees (stride: right leg forward, left leg back)
    [0,0,0,0,0,1,1,0,1,1,0,1,0,0],
    # 12: Shorts cuffs (spread out)
    [0,0,0,1,0,1,0,0,0,0,1,0,1,0],
    # 13: Shorts bottom
    [0,0,1,0,1,0,0,0,0,0,1,0,1,0],
    # 14: Legs (left back at x=1..3, right forward at x=9..12)
    [0,0,0,1,0,0,0,0,0,0,0,1,0,0],
    # 15: Socks
    [0,0,0,1,1,0,0,0,0,0,0,1,1,0],
    # 16: Right boot forward
    [0,0,0,1,1,0,0,0,0,0,0,1,1,1],
    # 17: Right boot toe
    [0,1,1,1,0,0,0,0,0,0,0,1,0,1],
    # 18: Left boot back
    [0,1,1,1,0,0,0,0,0,0,0,0,0,0],
    # 19: Soles
    [0,1,0,1,0,0,0,0,0,0,0,1,0,1]
]

ART_PLAYER_SHOOT = [
    # 0: Harpoon spear tip / muzzle (Center x=6..7)
    [0,0,0,0,0,0,1,1,0,0,0,0,0,0],
    # 1: Harpoon barrel
    [0,0,0,0,0,0,1,1,0,0,0,0,0,0],
    # 2: Harpoon stock / trigger
    [0,0,0,0,0,1,1,1,1,0,0,0,0,0],
    # 3: Cap pushed back (Orange: 2..10)
    [0,0,0,1,0,1,0,1,0,1,0,0,0,0],
    # 4: Cap brim & looking UP
    [0,0,1,1,0,1,0,1,0,1,1,0,0,0],
    # 5: Face looking up: eyes at top of face!
    [0,0,0,1,1,0,0,0,1,1,0,0,0,0],
    # 6: Nose / open mouth shouting
    [0,0,0,0,1,1,0,1,1,0,0,0,0,0],
    # 7: Raised hands holding gun!
    [0,0,1,1,0,1,1,1,1,0,1,1,0,0],
    # 8: Arms raised high (sleeves)
    [0,1,0,1,0,0,1,1,0,0,1,0,1,0],
    # 9: Orange shirt chest
    [0,0,1,0,0,1,0,1,0,0,1,0,0,0],
    # 10: Torso & Blue overalls
    [0,0,1,0,0,1,0,1,0,0,1,0,0,0],
    # 11: Dungarees waist (Blue)
    [0,0,1,0,1,1,1,1,0,1,0,0,0,0],
    # 12: Shorts pelvic
    [0,0,1,0,1,1,0,1,1,0,1,0,0,0],
    # 13: Shorts leg cuffs (braced stance)
    [0,1,0,1,0,0,0,0,1,0,1,0,0,0],
    # 14: Shorts bottom
    [0,1,0,1,0,0,0,0,0,1,0,1,0,0],
    # 15: Bare legs
    [0,0,1,0,0,0,0,0,0,0,1,0,0,0],
    # 16: Socks
    [0,1,1,0,0,0,0,0,0,1,1,0,0,0],
    # 17: Boots tops
    [0,1,1,1,0,0,0,0,0,1,1,1,0,0],
    # 18: Boots firmly planted
    [1,1,1,1,0,0,0,0,0,1,1,1,1,0],
    # 19: Boot soles
    [1,0,1,0,0,0,0,0,0,0,1,0,1,0]
]

ART_PLAYER_HIT = [
    # 0: Stars / dazed effects
    [0,1,0,0,0,1,1,0,0,0,0,1,0,0],
    # 1: Cap flying back!
    [0,0,1,1,0,1,0,1,0,1,1,0,0,0],
    # 2: Cap visor tilted
    [0,0,0,1,0,1,0,1,1,1,0,0,0,0],
    # 3: Hair messy
    [0,1,0,0,1,1,1,1,1,0,0,1,0,0],
    # 4: X_X eyes! (criss-cross)
    [0,0,1,0,1,0,0,0,1,0,1,0,0,0],
    # 5: X_X eyes center
    [0,0,0,1,0,0,0,0,0,1,0,0,0,0],
    # 6: Open mouth surprised 'O'
    [0,0,0,1,1,0,0,0,1,1,0,0,0,0],
    # 7: Open mouth hole
    [0,0,0,0,1,0,0,0,1,0,0,0,0,0],
    # 8: Head tilted back, arms flailing out
    [1,1,0,0,1,1,1,1,1,0,0,1,1,0],
    # 9: Arms flailing
    [1,0,1,0,0,1,0,1,0,0,1,0,1,0],
    # 10: Shirt twisted
    [0,0,1,1,0,1,0,1,0,1,1,0,0,0],
    # 11: Belt askew
    [0,0,1,0,1,1,1,1,0,1,0,0,0,0],
    # 12: Shorts tumbling
    [0,0,1,0,1,1,0,1,1,0,1,0,0,0],
    # 13: Legs flailing up / falling back
    [0,1,1,0,0,0,0,0,0,0,1,1,0,0],
    # 14: Legs spread
    [1,1,0,0,0,0,0,0,0,0,0,1,1,0],
    # 15: Bare legs kicked
    [1,0,1,0,0,0,0,0,0,0,1,0,1,0],
    # 16: Socks
    [0,1,1,0,0,0,0,0,0,0,1,1,0,0],
    # 17: Boots tumbling
    [1,1,1,0,0,0,0,0,0,0,1,1,1,0],
    # 18: Boot soles up
    [1,0,1,0,0,0,0,0,0,0,1,0,1,0],
    # 19: Impact dust puff
    [0,1,1,0,1,1,0,0,1,1,0,1,1,0]
]

ART_PLAYER_CLIMB1 = [
    # 0: Cap dome from back
    [0,0,0,1,0,1,0,1,0,1,0,0,0,0],
    # 1: Cap crown
    [0,0,1,1,0,1,0,1,0,1,1,0,0,0],
    # 2: Cap brim back
    [0,0,1,1,0,1,0,1,0,1,1,0,0,0],
    # 3: Hair nape
    [0,0,0,1,1,1,1,1,1,1,0,0,0,0],
    # 4: Neck & collar
    [0,0,0,0,1,0,1,0,1,0,0,0,0,0],
    # 5: Left hand reaching HIGH on ladder rail
    [0,1,1,0,1,0,1,0,1,0,0,0,0,0],
    # 6: Left arm up / Right arm gripping lower rung
    [0,1,0,0,1,0,0,0,1,0,0,1,1,0],
    # 7: Shoulders (Orange)
    [0,0,1,0,1,0,1,0,1,0,1,0,0,0],
    # 8: Back of shirt with Suspenders crossing (Blue: 3, 9)
    [0,0,0,1,0,1,0,1,0,1,0,0,0,0],
    # 9: Suspenders 'X' cross center
    [0,0,0,0,1,1,0,1,1,0,0,0,0,0],
    # 10: Lower back suspenders
    [0,0,0,1,0,1,0,1,0,1,0,0,0,0],
    # 11: Belt / waist (Blue)
    [0,0,1,1,1,1,1,1,1,1,1,0,0,0],
    # 12: Shorts back
    [0,0,1,0,1,0,1,0,1,0,1,0,0,0],
    # 13: Shorts cuffs
    [0,0,1,1,0,0,0,0,0,1,1,0,0,0],
    # 14: Left leg raised on rung / Right leg extended
    [0,0,1,0,0,0,0,0,0,0,1,0,0,0],
    # 15: Left knee high
    [0,1,1,0,0,0,0,0,0,1,0,0,0,0],
    # 16: Left boot on upper rung
    [1,1,1,0,0,0,0,0,0,1,1,0,0,0],
    # 17: Left boot heel
    [1,0,1,0,0,0,0,0,0,1,1,1,0,0],
    # 18: Right boot on lower rung
    [0,0,0,0,0,0,0,0,1,1,1,1,0,0],
    # 19: Right sole
    [0,0,0,0,0,0,0,0,1,0,1,0,0,0]
]

ART_PLAYER_CLIMB2 = [
    # 0: Cap dome from back
    [0,0,0,1,0,1,0,1,0,1,0,0,0,0],
    # 1: Cap crown
    [0,0,1,1,0,1,0,1,0,1,1,0,0,0],
    # 2: Cap brim back
    [0,0,1,1,0,1,0,1,0,1,1,0,0,0],
    # 3: Hair nape
    [0,0,0,1,1,1,1,1,1,1,0,0,0,0],
    # 4: Neck & collar
    [0,0,0,0,1,0,1,0,1,0,0,0,0,0],
    # 5: Right hand reaching HIGH on ladder rail
    [0,0,0,0,1,0,1,0,1,0,0,1,1,0],
    # 6: Right arm up / Left arm gripping lower rung
    [0,1,1,0,0,1,0,0,0,1,0,0,1,0],
    # 7: Shoulders (Orange)
    [0,0,0,1,0,1,0,1,0,1,0,1,0,0],
    # 8: Back of shirt with Suspenders crossing
    [0,0,0,1,0,1,0,1,0,1,0,0,0,0],
    # 9: Suspenders 'X' cross center
    [0,0,0,0,1,1,0,1,1,0,0,0,0,0],
    # 10: Lower back suspenders
    [0,0,0,1,0,1,0,1,0,1,0,0,0,0],
    # 11: Belt / waist (Blue)
    [0,0,1,1,1,1,1,1,1,1,1,0,0,0],
    # 12: Shorts back
    [0,0,1,0,1,0,1,0,1,0,1,0,0,0],
    # 13: Shorts cuffs
    [0,0,1,1,0,0,0,0,0,1,1,0,0,0],
    # 14: Right leg raised on rung / Left leg extended
    [0,0,0,1,0,0,0,0,0,0,0,1,0,0],
    # 15: Right knee high
    [0,0,0,0,1,0,0,0,0,0,1,1,0,0],
    # 16: Right boot on upper rung
    [0,0,0,1,1,0,0,0,0,0,1,1,1,0],
    # 17: Right boot heel
    [0,0,1,1,1,0,0,0,0,0,1,0,1,0],
    # 18: Left boot on lower rung
    [0,1,1,1,1,0,0,0,0,0,0,0,0,0],
    # 19: Left sole
    [0,1,0,1,0,0,0,0,0,0,0,0,0,0]
]


# Harpoon tip - 7 pixels wide, 8 lines high (2 bytes/line shifted)
ART_HARPOON_TIP = [
    "...#...",
    "..###..",
    ".#####.",
    "#######",
    "##.#.##",
    "#..#..#",
    "...#...",
    "...#..."
]

# Pop explosion - 8 pixels wide, 8 lines high (2 bytes/line shifted)
ART_POP_SPLASH = [
    "#..##..#",
    ".#.##.#.",
    "..####..",
    "########",
    "########",
    "..####..",
    ".#.##.#.",
    "#..##..#"
]

def make_circle_art(diameter):
    """
    Generates authentic Pang bubble with smooth circular border
    and distinct top-left specular highlight.
    """
    r = diameter / 2.0
    lines = []
    for y in range(diameter):
        row = ""
        dy = y - r + 0.5
        for x in range(diameter):
            dx = x - r + 0.5
            dist = math.sqrt(dx*dx + dy*dy)
            if dist <= r:
                # Inside circle
                # Highlight center at (r*0.4, r*0.4)
                hl_x = r * 0.45
                hl_y = r * 0.45
                hl_dist = math.sqrt((x - hl_x)**2 + (y - hl_y)**2)
                # Outer border
                if dist >= r - 1.1:
                    row += "#"  # Crisp outer rim
                elif hl_dist <= max(1.1, r * 0.25):
                    row += "#"  # Bright white specular reflection
                elif hl_dist <= max(1.8, r * 0.42):
                    row += "."  # Dark gap contouring the highlight
                else:
                    # Alternating dither pattern for rich Apple II HGR Orange color!
                    if (x + y) % 2 == 0:
                        row += "#"
                    else:
                        row += "."
            else:
                row += "."
        lines.append(row)
    return lines

# ===================================================================
# FULL CONTIGUOUS 8x8 ASCII FONT (ASCII 32 ' ' TO 90 'Z')
# ===================================================================
FONT_RAW = {
    32: ["........","........","........","........","........","........","........","........"], # Space
    33: ["...##...","...##...","...##...","...##...","...##...","........","...##...","........"], # !
    34: [".##..##.",".##..##.",".##..##.","........","........","........","........","........"], # "
    35: [".##..##.","########",".##..##.",".##..##.","########",".##..##.",".##..##.","........"], # #
    36: ["...##...","..####..","#.##..#.","..####..","...##.#.","..####..","...##...","........"], # $
    37: ["##...##.","##..##..","...##...","..##....",".##...##","##....##","........","........"], # %
    38: [".####...",".##..##.",".##..##.",".####...",".##..##.","##..###.",".####.##","........"], # &
    39: ["...##...","...##...","...##...","........","........","........","........","........"], # '
    40: ["....##..","...##...","..##....","..##....","..##....","...##...","....##..","........"], # (
    41: ["..##....","...##...","....##..","....##..","....##..","...##...","..##....","........"], # )
    42: ["........",".##..##.","..####..","########","..####..",".##..##.","........","........"], # *
    43: ["........","...##...","...##...","########","...##...","...##...","........","........"], # +
    44: ["........","........","........","........","........","...##...","...##...","..##...."], # ,
    45: ["........","........","........","########","........","........","........","........"], # -
    46: ["........","........","........","........","........","...##...","...##...","........"], # .
    47: ["......##",".....##.","....##..","...##...","..##....",".##.....","##......","........"], # /
    48: [".######.","##....##","##..#.##","##.##.##","##.#..##","##....##",".######.","........"], # 0
    49: ["...##...","..###...","...##...","...##...","...##...","...##...","..####..","........"], # 1
    50: [".######.","##....##","......##","..#####.","##......","##......","########","........"], # 2
    51: [".######.","##....##","......##","...####.","......##","##....##",".######.","........"], # 3
    52: ["...##...","..###...",".##.##..","##..##..","########","....##..","....##..","........"], # 4
    53: ["########","##......","######..","......##","......##","##....##",".######.","........"], # 5
    54: [".######.","##....##","##......","######..","##....##","##....##",".######.","........"], # 6
    55: ["########","......##",".....##.","....##..","...##...","...##...","...##...","........"], # 7
    56: [".######.","##....##","##....##",".######.","##....##","##....##",".######.","........"], # 8
    57: [".######.","##....##","##....##",".#######","......##","##....##",".######.","........"], # 9
    58: ["........","...##...","...##...","........","...##...","...##...","........","........"], # :
    59: ["........","...##...","...##...","........","...##...","...##...","..##....","........"], # ;
    60: ["....##..","...##...","..##....",".##.....","..##....","...##...","....##..","........"], # <
    61: ["........","........","########","........","########","........","........","........"], # =
    62: ["..##....","...##...","....##..",".....##.","....##..","...##...","..##....","........"], # >
    63: [".######.","##....##","......##","...####.","...##...","........","...##...","........"], # ?
    64: [".######.","##....##","##.####.","##.##.##","##.####.","##......",".######.","........"], # @
    65: [".######.","##....##","##....##","########","##....##","##....##","##....##","........"], # A
    66: ["#######.","##....##","##....##","#######.","##....##","##....##","#######.","........"], # B
    67: [".######.","##....##","##......","##......","##......","##....##",".######.","........"], # C
    68: ["######..","##...###","##....##","##....##","##....##","##...###","######..","........"], # D
    69: ["########","##......","##......","######..","##......","##......","########","........"], # E
    70: ["########","##......","##......","######..","##......","##......","##......","........"], # F
    71: [".######.","##....##","##......","##..####","##....##","##....##",".######.","........"], # G
    72: ["##....##","##....##","##....##","########","##....##","##....##","##....##","........"], # H
    73: [".######.","...##...","...##...","...##...","...##...","...##...",".######.","........"], # I
    74: ["....####","......##","......##","......##","##....##","##....##",".######.","........"], # J
    75: ["##....##","##...##.","##..##..","#####...","##..##..","##...##.","##....##","........"], # K
    76: ["##......","##......","##......","##......","##......","##......","########","........"], # L
    77: ["##....##","###..###","########","##.##.##","##....##","##....##","##....##","........"], # M
    78: ["##....##","###...##","####..##","##.##.##","##..####","##...###","##....##","........"], # N
    79: [".######.","##....##","##....##","##....##","##....##","##....##",".######.","........"], # O
    80: ["#######.","##....##","##....##","#######.","##......","##......","##......","........"], # P
    81: [".######.","##....##","##....##","##....##","##..####","##....##",".######.",".....###"], # Q
    82: ["#######.","##....##","##....##","#######.","##..##..","##...##.","##....##","........"], # R
    83: [".######.","##....##","##......",".######.","......##","##....##",".######.","........"], # S
    84: ["########","...##...","...##...","...##...","...##...","...##...","...##...","........"], # T
    85: ["##....##","##....##","##....##","##....##","##....##","##....##",".######.","........"], # U
    86: ["##....##","##....##","##....##","##....##",".##..##.",".##..##.","...##...","........"], # V
    87: ["##....##","##....##","##....##","##.##.##","########","###..###","##....##","........"], # W
    88: ["##....##",".##..##.","..####..","...##...","..####..",".##..##.","##....##","........"], # X
    89: ["##....##","##....##",".##..##.","...##...","...##...","...##...","...##...","........"], # Y
    90: ["########","......##",".....##.","....##..","...##...","..##....","########","........"]  # Z
}

def main():
    hgr_lo, hgr_hi = generate_hgr_tables()

    out_file = "pang_data.asm"
    with open(out_file, "w") as f:
        f.write("; ===================================================================\n")
        f.write("; PANG_DATA.ASM - Full color sprites, HGR tables & ASCII font for Pang!\n")
        f.write("; Generated by build_pang_assets.py\n")
        f.write("; ===================================================================\n\n")

        # HGR Table
        f.write("; HGR Scanline Base Addresses (0..191) for Page 1 ($2000)\n")
        f.write("hgr_lo:\n")
        for i in range(0, 192, 16):
            f.write("    .byte " + ", ".join(f"${b:02X}" for b in hgr_lo[i:i+16]) + "\n")
        f.write("\nhgr_hi:\n")
        for i in range(0, 192, 16):
            f.write("    .byte " + ", ".join(f"${b:02X}" for b in hgr_hi[i:i+16]) + "\n")
        f.write("\n")

        # Multiplication tables for up to 32 scanlines
        f.write("; Precalculated scanline multiplication tables\n")
        f.write("mult2_table:\n    .byte " + ", ".join(str(i * 2) for i in range(32)) + "\n")
        f.write("mult3_table:\n    .byte " + ", ".join(str(i * 3) for i in range(32)) + "\n")
        f.write("mult4_table:\n    .byte " + ", ".join(str(i * 4) for i in range(32)) + "\n")
        f.write("mult5_table:\n    .byte " + ", ".join(str(i * 5) for i in range(32)) + "\n\n")

        # Shift offsets tables (LO and HI bytes for 16-bit safety)
        def write_offset_table(name, bytes_per_shift):
            offsets = [s * bytes_per_shift for s in range(7)]
            f.write(f"{name}_offset_lo:\n    .byte " + ", ".join(f"${(o & 0xFF):02X}" for o in offsets) + "\n")
            f.write(f"{name}_offset_hi:\n    .byte " + ", ".join(f"${((o >> 8) & 0xFF):02X}" for o in offsets) + "\n\n")

        write_offset_table("shift_player", 20 * 3)   # 60
        write_offset_table("shift_harpoon", 8 * 2)   # 16
        write_offset_table("shift_pop", 8 * 2)       # 16
        write_offset_table("shift_ball0", 8 * 2)     # 16
        write_offset_table("shift_ball1", 14 * 3)    # 42
        write_offset_table("shift_ball2", 20 * 4)    # 80
        write_offset_table("shift_ball3", 26 * 5)    # 130

        # Sprite generation helper
        def write_sprite(name, art, bytes_per_line, palette=0x80):
            rows, w, h = parse_ascii_art(art)
            shifts = make_shifted_sprite(rows, w, h, bytes_per_line, palette)
            f.write(f"; Sprite: {name} ({h} lines x {bytes_per_line} bytes x 7 shifts)\n")
            f.write(f"{name}:\n")
            for shift_idx, sdata in enumerate(shifts):
                f.write(f"; Shift {shift_idx}\n")
                for line_idx in range(h):
                    line_bytes = sdata[line_idx * bytes_per_line : (line_idx + 1) * bytes_per_line]
                    f.write("    .byte " + ", ".join(f"${b:02X}" for b in line_bytes) + "\n")
            f.write("\n")

        # Write Player Sprites (20 scanlines x 3 bytes)
        write_sprite("spr_player_stand", ART_PLAYER_STAND, 3, palette=0x80)
        write_sprite("spr_player_walk1", ART_PLAYER_WALK1, 3, palette=0x80)
        write_sprite("spr_player_walk2", ART_PLAYER_WALK2, 3, palette=0x80)
        write_sprite("spr_player_shoot", ART_PLAYER_SHOOT, 3, palette=0x80)
        write_sprite("spr_player_hit", ART_PLAYER_HIT, 3, palette=0x80)
        write_sprite("spr_player_climb1", ART_PLAYER_CLIMB1, 3, palette=0x80)
        write_sprite("spr_player_climb2", ART_PLAYER_CLIMB2, 3, palette=0x80)

        # Write Tile Patterns (1 byte wide x 8 scanlines tall)
        f.write("; ===================================================================\n")
        f.write("; TILE GRAPHICS (1 BYTE x 8 SCANLINES)\n")
        f.write("; ===================================================================\n")
        f.write("tile_solid_gfx:\n    .byte $AA, $D5, $D5, $FF, $D5, $D5, $D5, $80\n\n")
        f.write("tile_breakable_gfx:\n    .byte $FF, $BE, $AA, $AA, $BE, $AA, $AA, $80\n\n")
        f.write("tile_ladder_gfx:\n    .byte $A2, $BE, $A2, $A2, $BE, $A2, $A2, $BE\n\n")

        # Write Harpoon Tip Sprite
        write_sprite("spr_harpoon_tip", ART_HARPOON_TIP, 2, palette=0x00)

        # Write Pop Explosion Sprite
        write_sprite("spr_pop_splash", ART_POP_SPLASH, 2, palette=0x80)

        # Write Bubble Sprites (4 sizes with palette 0x80 for bright arcade color)
        write_sprite("spr_ball_size0", make_circle_art(8), 2, palette=0x80)   # 8x8, 2 bytes
        write_sprite("spr_ball_size1", make_circle_art(14), 3, palette=0x80)  # 14x14, 3 bytes
        write_sprite("spr_ball_size2", make_circle_art(20), 4, palette=0x80)  # 20x20, 4 bytes
        write_sprite("spr_ball_size3", make_circle_art(26), 5, palette=0x80)  # 26x26, 5 bytes

        # Write Complete Contiguous 8x8 ASCII Font (ASCII 32 to 90)
        f.write("; ===================================================================\n")
        f.write("; CONTIGUOUS 8x8 FONT TABLE (ASCII 32 ' ' TO 90 'Z')\n")
        f.write("; Exact 8 bytes per character, 100% contiguous\n")
        f.write("; ===================================================================\n")
        f.write("font_base_32:\n")
        for code in range(32, 91):
            char_rep = chr(code)
            bitrows = FONT_RAW.get(code, ["........"] * 8)
            f.write(f"; Char '{char_rep}' (ASCII {code})\n")
            hgr_bytes = []
            for row_str in bitrows:
                val = 0
                for bidx, ch in enumerate(row_str[:7]):
                    if ch == '#':
                        val |= (1 << bidx)
                hgr_bytes.append(val)
            f.write("    .byte " + ", ".join(f"${b:02X}" for b in hgr_bytes) + "\n")
        f.write("\n")

    print(f"Successfully generated {out_file}!")

if __name__ == "__main__":
    main()
