res_lo = []
res_hi = []
for i in range(192):
    addr = 0x2000 + (i & 7) * 0x400 + (i & 0x38) * 0x10 + (i & 0xC0) * 1 + (i & 0xC0) // 4
    res_lo.append(f"${addr&0xFF:02x}")
    res_hi.append(f"${addr>>8:02x}")

print("HGR_LO_TAB:")
for i in range(0, 192, 16):
    print("    .byte " + ",".join(res_lo[i:i+16]))
print("HGR_HI_TAB:")
for i in range(0, 192, 16):
    print("    .byte " + ",".join(res_hi[i:i+16]))
