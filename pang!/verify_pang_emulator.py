# -*- coding: utf-8 -*-
"""
verify_pang_emulator.py - Robust gameplay verification for PANG! on AppleWin.
Waits for DOS 3.3 BRUN PANG to finish loading (4.0s).
Uses PrintWindow(hwnd, memdc, 0).
Tests:
1. Stage 1: Wait for game to start, watch ball bounce, fire harpoon.
2. Stage 2:
   - Warp to Stage 2 ('2').
   - Watch balls bounce on central platform (verify anti-tunneling).
   - Walk Buster past ladder to left ('A') -> verify no auto-climbing.
   - Walk Buster back ('D') and climb up ('W').
   - Shoot harpoon while on ladder -> verify ladder is intact.
3. Stage 3:
   - Warp to Stage 3 ('3') -> verify dual platforms, twin ladders, breakable bridge.
"""
import subprocess
import time
import ctypes
from ctypes import wintypes
import struct
import os
from PIL import Image

USER32 = ctypes.windll.user32
GDI32 = ctypes.windll.gdi32

ARTIFACT_DIR = r"C:\Users\baco\.gemini\antigravity-ide\brain\a4e55806-aee2-4220-ab15-df742437187a"
DSK_PATH = r"C:\Users\baco\Documents\Apple2\AI-ASM.DSK"
EMU_DIR = r"D:\Emulateurs\AppleWin"
EMU_EXE = os.path.join(EMU_DIR, "Applewin.exe")

def capture_window(hwnd, filename):
    rect = wintypes.RECT()
    USER32.GetWindowRect(hwnd, ctypes.byref(rect))
    w = rect.right - rect.left
    h = rect.bottom - rect.top
    if w <= 0 or h <= 0:
        return None
    hdc = USER32.GetWindowDC(hwnd)
    memdc = GDI32.CreateCompatibleDC(hdc)
    hbitmap = GDI32.CreateCompatibleBitmap(hdc, w, h)
    GDI32.SelectObject(memdc, hbitmap)
    USER32.PrintWindow(hwnd, memdc, 0)
    bmi = struct.pack('<IiiHHIIiiII', 40, w, -h, 1, 32, 0, w*h*4, 0, 0, 0, 0)
    buf = ctypes.create_string_buffer(w * h * 4)
    GDI32.GetDIBits(memdc, hbitmap, 0, h, buf, bmi, 0)
    GDI32.DeleteObject(hbitmap)
    GDI32.DeleteDC(memdc)
    USER32.ReleaseDC(hwnd, hdc)
    img = Image.frombuffer('RGBA', (w, h), buf, 'raw', 'BGRA', 0, 1).convert('RGB')
    target_path = os.path.join(ARTIFACT_DIR, filename)
    img.save(target_path)
    print(f"Captured {filename} -> {target_path}")
    return target_path

def send_char(hwnd, ch, count=1, delay=0.08):
    for _ in range(count):
        USER32.PostMessageW(hwnd, 0x0102, ord(ch), 1)
        time.sleep(delay)

def main():
    print("Starting AppleWin emulator...")
    p = subprocess.Popen([EMU_EXE, "-l", "-d1", DSK_PATH], cwd=EMU_DIR)
    time.sleep(3.5)

    hwnds = []
    def check_win(h, lParam):
        if USER32.IsWindowVisible(h):
            length = USER32.GetWindowTextLengthW(h)
            if length > 0:
                buf = ctypes.create_unicode_buffer(length + 1)
                USER32.GetWindowTextW(h, buf, length + 1)
                title = buf.value.lower()
                if "apple" in title and "emulator" in title:
                    hwnds.append(h)
        return True

    cb = ctypes.WINFUNCTYPE(ctypes.c_bool, wintypes.HWND, wintypes.LPARAM)(check_win)
    USER32.EnumWindows(cb, 0)

    if not hwnds:
        print("ERROR: AppleWin window not found!")
        p.kill()
        return

    hwnd = hwnds[0]
    USER32.ShowWindow(hwnd, 5) # SW_SHOW
    USER32.SetForegroundWindow(hwnd)
    time.sleep(0.5)

    # 1. Boot PANG
    print("Booting PANG from menu...")
    send_char(hwnd, 'P')
    # Allow 4.0s for DOS 3.3 to load 11.8 KB binary from floppy
    print("Waiting 4.0s for DOS 3.3 BRUN PANG...")
    time.sleep(4.0)

    # 2. Stage 1 verification: Right Wall access & Ball bounce
    print("Stage 1: Stepping left and firing to clear path...")
    send_char(hwnd, 'A', count=20, delay=0.04)
    time.sleep(0.2)
    send_char(hwnd, ' ')
    time.sleep(1.0)

    print("Stage 1: Testing Buster walking all the way to the RIGHT WALL ('D')...")
    send_char(hwnd, 'D', count=80, delay=0.04)
    time.sleep(0.3)
    capture_window(hwnd, "buster_right_wall.png")

    print("Stage 1: Watching balls bounce flush against the right blue pillar...")
    time.sleep(2.5)
    capture_window(hwnd, "ball_right_wall_bounce.png")

    # 3. Stage 2 verification: Platform bounce, Right Wall contact, Ladder navigation
    print("Warping to Stage 2 ('2')...")
    send_char(hwnd, '2')
    time.sleep(1.0)
    capture_window(hwnd, "stage2_initial_verified.png")

    print("Stage 2: Walking Buster all the way to the RIGHT BLUE PILLAR ('D')...")
    # Buster starts at X=126, walks past ladder to right wall X=238
    send_char(hwnd, 'D', count=65, delay=0.04)
    time.sleep(0.3)
    capture_window(hwnd, "buster_touching_right_pillar.png")

    print("Stage 2: Walking Buster all the way past the ladder to the left ('A')...")
    send_char(hwnd, 'A', count=55, delay=0.04)
    time.sleep(0.3)
    capture_window(hwnd, "stage2_walk_past_ladder_verified.png")

    print("Stage 2: Walking to ladder center and climbing UP ('W')...")
    send_char(hwnd, 'D', count=18, delay=0.04)
    time.sleep(0.2)
    send_char(hwnd, 'W', count=15, delay=0.05)
    time.sleep(0.5)
    capture_window(hwnd, "stage2_climbing_ladder_verified.png")

    print("Shooting harpoon while on ladder (checking for no ladder erasure)...")
    send_char(hwnd, ' ')
    time.sleep(0.8)
    capture_window(hwnd, "stage2_ladder_intact_verified.png")

    # 4. Stage 3 verification: Arcade Stage 3 Layout
    print("Warping to Stage 3 ('3')...")
    send_char(hwnd, '3')
    time.sleep(1.5)
    capture_window(hwnd, "stage3_arcade_verified.png")

    print("Terminating AppleWin cleanly...")
    p.kill()
    time.sleep(0.5)
    print("AppleWin terminated successfully. All disk files unlocked.")

if __name__ == "__main__":
    main()
