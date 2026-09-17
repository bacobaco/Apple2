# -*- coding: utf-8 -*-
"""
test_emulator.py - Emulates Apple II execution of 1000bornes.bin using py65
and dumps HGR screen states to PNG images for visual verification.
"""
import sys
import os
from PIL import Image
from py65.devices.mpu6502 import MPU

class Apple2Memory:
    def __init__(self):
        self.mem = bytearray(65536)
        self.key_buffer = 0
        self.strobe = False

    def press_key(self, ch):
        self.key_buffer = ord(ch) | 0x80
        self.strobe = True

    def clear_key(self):
        self.strobe = False
        self.key_buffer = 0

    def __getitem__(self, addr):
        addr = addr & 0xFFFF
        if addr == 0xC000:
            return self.key_buffer if self.strobe else 0x00
        elif addr == 0xC010:
            self.strobe = False
            return 0x00
        elif addr == 0xC030:
            return 0x00
        elif 0xC050 <= addr <= 0xC057:
            return 0x00
        return self.mem[addr]

    def __setitem__(self, addr, val):
        addr = addr & 0xFFFF
        val = val & 0xFF
        if addr == 0xC010:
            self.strobe = False
        elif addr == 0xC030:
            pass
        elif 0xC050 <= addr <= 0xC057:
            pass
        else:
            self.mem[addr] = val

def render_hgr_to_image(mem):
    """
    Renders the 280x192 Apple II HGR Page 1 ($2000-$3FFF) into a PIL Image.
    Each scanline has 40 bytes. Each byte contains 7 pixels (bits 0..6).
    Bit 7 is the palette bit.
    """
    img = Image.new("RGB", (280, 192), (0, 0, 0))
    pixels = img.load()

    # Precompute row addresses for 192 lines
    row_addrs = []
    for y in range(192):
        addr = 0x2000 + ((y % 8) * 0x400) + (((y // 8) % 8) * 0x80) + ((y // 64) * 0x28)
        row_addrs.append(addr)

    for y in range(192):
        base = row_addrs[y]
        dots = []
        palettes = []
        for col in range(40):
            b = mem[base + col]
            hi = bool(b & 0x80)
            for bit in range(7):
                dots.append(bool(b & (1 << bit)))
                palettes.append(hi)

        for px in range(280):
            if not dots[px]:
                # Only leave black if not already filled by color carrier
                if pixels[px, y] == (0, 0, 0):
                    pixels[px, y] = (0, 0, 0)
            else:
                left_on = dots[px - 1] if px > 0 else False
                right_on = dots[px + 1] if px < 279 else False
                if left_on or right_on:
                    pixels[px, y] = (255, 255, 255)
                    if px > 0 and left_on:
                        pixels[px - 1, y] = (255, 255, 255)
                    if px < 279 and right_on:
                        pixels[px + 1, y] = (255, 255, 255)
                else:
                    hi = palettes[px]
                    if hi:
                        color = (240, 160, 20) if (px % 2 == 1) else (30, 140, 255)
                    else:
                        color = (34, 177, 76) if (px % 2 == 1) else (220, 30, 180)
                    pixels[px, y] = color
                    if px + 1 < 280 and not dots[px + 1]:
                        pixels[px + 1, y] = color
    return img

def run_test():
    bin_path = os.path.join("1000bornes", "1000bornes.bin")
    with open(bin_path, "rb") as f:
        code = f.read()

    load_addr = 0x4000
    if len(code) >= 2 and code[0] == 0x00 and code[1] == 0x40:
        code = code[2:]
    print(f"Loaded {len(code)} bytes from {bin_path} at ${load_addr:04X}")

    mem = Apple2Memory()
    for i, b in enumerate(code):
        mem.mem[load_addr + i] = b

    # Create MPU
    mpu = MPU(memory=mem)
    mpu.pc = load_addr
    mpu.sp = 0xFF

    print("1. Running initial title screen rendering...")
    cycles = 0
    while cycles < 600000:
        mpu.step()
        cycles += 1

    print(f"Title screen captured at {cycles} cycles. Current PC=${mpu.pc:04X}")
    img_title = render_hgr_to_image(mem.mem)
    img_title.save(os.path.join("1000bornes", "screen_title.png"))
    print("Saved screen_title.png")

    # 2. Press space to exit title screen and enter PromptPlayerName
    print("2. Pressing Space to enter Name Prompt...")
    mem.press_key(' ')
    while cycles < 800000:
        mpu.step()
        cycles += 1
        if mpu.pc == 0x62B8 or not mem.strobe: # key consumed
            break
    
    # Run a bit more to let PromptPlayerName draw
    for _ in range(200000):
        mpu.step()
        cycles += 1

    print(f"Name prompt reached. Current PC=${mpu.pc:04X}")
    img_name = render_hgr_to_image(mem.mem)
    img_name.save(os.path.join("1000bornes", "screen_name.png"))
    print("Saved screen_name.png")

    # 3. Type "JOUEUR\r"
    print("3. Typing name 'JOUEUR'...")
    for ch in "JOUEUR\r":
        mem.press_key(ch)
        for _ in range(100000):
            mpu.step()
            cycles += 1
            if not mem.strobe:
                break

    # Let the game board draw
    print("4. Rendering game board...")
    for _ in range(800000):
        mpu.step()
        cycles += 1

    print(f"Board reached. Current PC=${mpu.pc:04X}")
    img_board = render_hgr_to_image(mem.mem)
    img_board.save(os.path.join("1000bornes", "screen_board.png"))
    print("Saved screen_board.png")

    # 5. Play Phase 1: Press 'T' (or '1' or ' ') to Draw a Card (Tirer une carte)
    print("5. Phase 1: Pressing '1' to draw 7th card from deck...")
    mem.press_key('1')
    for _ in range(200000):
        mpu.step()
        cycles += 1
        if not mem.strobe:
            break

    # Run cycles to let card 7 draw into slot 7
    for _ in range(400000):
        mpu.step()
        cycles += 1

    # Save screen with 7 cards in hand
    img_draw = render_hgr_to_image(mem.mem)
    img_draw.save(os.path.join("1000bornes", "screen_7cards.png"))
    print("Saved screen_7cards.png")

    # 6. Play Phase 2: Press '2' (or 'D') to choose DEFAUSSER
    print("6. Phase 2: Pressing 'D' to choose DEFAUSSER...")
    mem.press_key('D')
    for _ in range(200000):
        mpu.step()
        cycles += 1
        if not mem.strobe:
            break

    for _ in range(200000):
        mpu.step()
        cycles += 1

    # 7. Play Phase 3: Press '3' to select card 3, then Enter/Space to confirm discard
    print("7. Phase 3: Pressing '3' then Enter to discard card 3...")
    mem.press_key('3')
    for _ in range(200000):
        mpu.step()
        cycles += 1
        if not mem.strobe:
            break

    mem.press_key('\r')
    for _ in range(500000):
        mpu.step()
        cycles += 1
        if not mem.strobe:
            break

    # Let Thomson take its turn and animations play
    print("8. Letting Thomson take turn...")
    for _ in range(1200000):
        mpu.step()
        cycles += 1

    print(f"Post-discard state reached. Current PC=${mpu.pc:04X}")
    img_turn = render_hgr_to_image(mem.mem)
    img_turn.save(os.path.join("1000bornes", "screen_turn.png"))
    print("Saved screen_turn.png")

if __name__ == "__main__":
    run_test()
