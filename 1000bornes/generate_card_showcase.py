import sys, os
from PIL import Image, ImageDraw, ImageFont
from py65.devices.mpu6502 import MPU

sys.path.insert(0, r'd:\Documents\Antigravity\Apple2\1000bornes')
from test_emulator import Apple2Memory, render_hgr_to_image

with open('1000bornes.bin', 'rb') as f:
    code = f.read()
if code[:2] == b'\x00\x40':
    code = code[2:]

mem = Apple2Memory()
load_addr = 0x4000
for i, b in enumerate(code):
    mem.mem[load_addr + i] = b

labels = {}
with open('labels.txt', 'r') as f:
    for line in f:
        parts = line.strip().split('=')
        if len(parts) == 2:
            name = parts[0].strip()
            val_str = parts[1].strip().replace('$', '')
            try:
                labels[name] = int(val_str, 16)
            except:
                pass

mpu = MPU(memory=mem)

# Render each card (0..19)
card_images = {}
for cid in range(20):
    for addr in range(0x2000, 0x4000):
        mem.mem[addr] = 0x00
    mem.mem[0xE4] = 2   # col 2 (even)
    mem.mem[0xE5] = 20  # scan 20
    mem.mem[0xE6] = cid
    mpu.pc = labels['DrawCardAt']
    mpu.sp = 0xFD
    mem.mem[0x01FE] = 0x00
    mem.mem[0x01FF] = 0x00
    while mpu.pc != 0x0001:
        mpu.step()
    img = render_hgr_to_image(mem.mem)
    card_crop = img.crop((14, 20, 49, 60))
    card_images[cid] = card_crop

art_dir = r'C:\Users\baco\.gemini\antigravity-ide\brain\8fcb20d5-ef2d-4e7f-abf4-8a2bbf1bb98d'

# -------------------------------------------------------------
# 1. SHOWCASE DES 4 BOTTES
# -------------------------------------------------------------
bottes_info = [
    (16, "CITERNE", "* CIT *", "Immunite Panne", "Parade permanente essence"),
    (17, "AS DU VOLANT", "* AS VL *", "Immunite Accident", "Parade permanente collision"),
    (18, "INCREVABLE", "* INC *", "Immunite Crevaison", "Parade permanente crevaison"),
    (19, "PRIORITAIRE", "* PRIO *", "Feu Rouge & 50 km/h", "Insensible aux feux & limites")
]

scale = 4
cw, ch = 35 * scale, 40 * scale
pad_x = 35
margin = 40
bw = margin * 2 + 4 * cw + 3 * pad_x
bh = 340

img_bottes = Image.new('RGB', (bw, bh), (22, 28, 36))
draw = ImageDraw.Draw(img_bottes)

font_title = ImageFont.truetype('arial.ttf', 24)
font_card = ImageFont.truetype('arial.ttf', 16)
font_sub = ImageFont.truetype('arial.ttf', 12)
font_desc = ImageFont.truetype('arial.ttf', 11)

draw.text((bw // 2, 28), "LES 4 BOTTES DU 1000 BORNES (APPLE II HGR 280x192)", fill=(255, 215, 0), font=font_title, anchor='mm')
draw.text((bw // 2, 54), "Rendu graphique 1:1 original avec la nouvelle ligne d'espacement sur l'As du Volant", fill=(180, 195, 210), font=font_desc, anchor='mm')

for idx, (cid, name, code_txt, immun, desc) in enumerate(bottes_info):
    x = margin + idx * (cw + pad_x)
    y = 75
    draw.rectangle([x - 3, y - 3, x + cw + 3, y + ch + 3], fill=(10, 14, 18), outline=(60, 75, 95), width=1)
    card_resized = card_images[cid].resize((cw, ch), Image.NEAREST)
    img_bottes.paste(card_resized, (x, y))
    
    draw.text((x + cw // 2, y + ch + 16), name, fill=(255, 255, 255), font=font_card, anchor='mm')
    draw.text((x + cw // 2, y + ch + 34), code_txt, fill=(100, 220, 255), font=font_sub, anchor='mm')
    draw.text((x + cw // 2, y + ch + 52), immun, fill=(120, 255, 140), font=font_desc, anchor='mm')
    draw.text((x + cw // 2, y + ch + 68), desc, fill=(160, 175, 190), font=font_desc, anchor='mm')

img_bottes.save('bottes_showcase.png')
img_bottes.save(os.path.join(art_dir, 'bottes_showcase.png'))
print('Saved bottes_showcase.png')

# -------------------------------------------------------------
# 2. PLANCHE COMPLETE DES 20 CARTES
# -------------------------------------------------------------
groups = [
    ("LES 4 BOTTES (IMMUNITES)", [(16, "Citerne"), (17, "As du Volant"), (18, "Increvable"), (19, "Vehicule Prio")]),
    ("LES 5 ATTAQUES", [(5, "Feu Rouge"), (4, "Limite 50"), (1, "Panne Essence"), (2, "Accident"), (3, "Crevaison")]),
    ("LES 5 PARADES", [(10, "Feu Vert"), (9, "Fin Limite"), (6, "Essence"), (7, "Reparations"), (8, "Roue Secours")]),
    ("LES 5 BORNES KILOMETRIQUES + TITRE", [(15, "25 KM"), (14, "50 KM"), (13, "75 KM"), (12, "100 KM"), (11, "200 KM"), (0, "1000 Bornes")])
]

card_scale = 3
scw, sch = 35 * card_scale, 40 * card_scale
grid_w = 950
grid_h = 820

img_all = Image.new('RGB', (grid_w, grid_h), (20, 24, 30))
d_all = ImageDraw.Draw(img_all)

f_main_title = ImageFont.truetype('arial.ttf', 24)
f_group_title = ImageFont.truetype('arial.ttf', 15)
f_cname = ImageFont.truetype('arial.ttf', 12)

d_all.text((grid_w // 2, 28), "CATALOGUE COMPLET DES 20 CARTES - 1000 BORNES (APPLE II)", fill=(255, 215, 0), font=f_main_title, anchor='mm')

curr_y = 65
for g_title, items in groups:
    d_all.text((40, curr_y), g_title, fill=(100, 200, 255), font=f_group_title, anchor='lm')
    d_all.line([(40, curr_y + 12), (grid_w - 40, curr_y + 12)], fill=(50, 65, 80), width=1)
    curr_y += 24
    
    num_items = len(items)
    spacing = (grid_w - 80 - (num_items * scw)) // (num_items - 1) if num_items > 1 else 0
    start_x = 40
    
    for idx, (cid, cname) in enumerate(items):
        cx = start_x + idx * (scw + spacing)
        cy = curr_y
        
        d_all.rectangle([cx - 2, cy - 2, cx + scw + 2, cy + sch + 2], fill=(12, 15, 20), outline=(50, 65, 85), width=1)
        cr_img = card_images[cid].resize((scw, sch), Image.NEAREST)
        img_all.paste(cr_img, (cx, cy))
        
        d_all.text((cx + scw // 2, cy + sch + 12), cname, fill=(230, 235, 240), font=f_cname, anchor='mm')
        
    curr_y += sch + 36

img_all.save('all_cards_showcase.png')
img_all.save(os.path.join(art_dir, 'all_cards_showcase.png'))
print('Saved all_cards_showcase.png successfully!')
