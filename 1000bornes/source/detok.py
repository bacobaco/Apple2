import sys

basicTokensMap = {
    'END': 0x80, 'FOR': 0x81, 'NEXT': 0x82, 'DATA': 0x83, 'DIM': 0x84, 'READ': 0x85,
    'GO': 0x87, 'RUN': 0x88, 'IF': 0x89, 'RESTORE': 0x8A, 'RETURN': 0x8B, 'REM': 0x8C,
    "'": 0x8D, 'STOP': 0x8E, 'ELSE': 0x8F, 'TRON': 0x90, 'TROFF': 0x91, 'DEFSTR': 0x92,
    'DEFINT': 0x93, 'DEFSNG': 0x94, 'ON': 0x96, 'TUNE': 0x97, 'ERROR': 0x98, 'RESUME': 0x99,
    'AUTO': 0x9A, 'DELETE': 0x9B, 'LOCATE': 0x9C, 'CLS': 0x9D, 'CONSOLE': 0x9E, 'PSET': 0x9F,
    'MOTOR': 0xA0, 'SKIPF': 0xA1, 'EXEC': 0xA2, 'BEEP': 0xA3, 'COLOR': 0xA4, 'LINE': 0xA5,
    'BOX': 0xA6, 'ATTRB': 0xA8, 'DEF': 0xA9, 'POKE': 0xAA, 'PRINT': 0xAB, 'CONT': 0xAC,
    'LIST': 0xAD, 'CLEAR': 0xAE, 'DOS': 0xAF, 'NEW': 0xB1, 'SAVE': 0xB2, 'LOAD': 0xB3,
    'MERGE': 0xB4, 'OPEN': 0xB5, 'CLOSE': 0xB6, 'INPEN': 0xB7, 'PEN': 0xB8, 'PLAY': 0xB9,
    'TAB': 0xBA, 'TO': 0xBB, 'SUB': 0xBC, 'FNC': 0xBD, 'SPC': 0xBE, 'USING': 0xBF,
    'USR': 0xC0, 'ERL': 0xC1, 'ERR': 0xC2, 'OFF': 0xC3, 'THEN': 0xC4, 'NOT': 0xC5,
    'STEP': 0xC6, '+': 0xC7, '-': 0xC8, '*': 0xC9, '/': 0xCA, '^': 0xCB,
    'AND': 0xCC, 'OR': 0xCD, 'XOR': 0xCE, 'EQV': 0xCF, 'IMP': 0xD0, 'MOD': 0xD1,
    '>': 0xD3, '=': 0xD4, '<': 0xD5, 'DSKIN': 0xD6, 'DSKO$': 0xD7, 'KILL': 0xD8,
    'NAME': 0xD9, 'FIELD': 0xDA, 'LSET': 0xDB, 'RSET': 0xDC, 'PUT': 0xDD, 'GET': 0xDE,
    'VERIFY': 0xDF, 'DEVICE': 0xE0, 'DIR': 0xE1, 'FILES': 0xE2, 'WRITE': 0xE3, 'UNLOAD': 0xE4,
    'BACKUP': 0xE5, 'COPY': 0xE6, 'CIRCLE': 0xE7, 'PAINT': 0xE8, 'DRAW': 0xE9, 'RENUM': 0xEA,
    'SWAP': 0xEB,
    'SGN': 0xFF80, 'INT': 0xFF81, 'ABS': 0xFF82, 'FRE': 0xFF83, 'SQR': 0xFF84, 'LOG': 0xFF85,
    'EXP': 0xFF86, 'COS': 0xFF87, 'SIN': 0xFF88, 'TAN': 0xFF89, 'PEEK': 0xFF8A, 'LEN': 0xFF8B,
    'STR$': 0xFF8C, 'VAL': 0xFF8D, 'ASC': 0xFF8E, 'CHR$': 0xFF8F, 'EOF': 0xFF90, 'CINT': 0xFF91,
    'CSNG': 0xFF92, 'CDBL': 0xFF93, 'FIX': 0xFF94, 'HEX$': 0xFF95, 'OCT$': 0xFF96, 'STICK': 0xFF97,
    'STRIG': 0xFF98, 'GR$': 0xFF99, 'LEFT$': 0xFF9A, 'RIGHT$': 0xFF9B, 'MID$': 0xFF9C, 'INSTR': 0xFF9D,
    'VARPTR': 0xFF9E, 'RND': 0xFF9F, 'INKEY$': 0xFFA0, 'INPUT': 0xFFA1, 'CSRLIN': 0xFFA2, 'POINT': 0xFFA3,
    'SCREEN': 0xFFA4, 'POS': 0xFFA5, 'PTRIG': 0xFFA6, 'DSKF': 0xFFA7, 'CVI': 0xFFA8, 'CVS': 0xFFA9,
    'MKI$': 0xFFAB, 'MKS$': 0xFFAC, 'LOC': 0xFFAE, 'LOF': 0xFFAF, 'SPACE$': 0xFFB0, 'STRING$': 0xFFB1,
    'DSKI$': 0xFFB2
}

tokenToWord = {v: k for k, v in basicTokensMap.items()}

with open(r'd:\Documents\Antigravity\Apple2\1000bornes\source\MBORNE.BAS', 'rb') as f:
    data = f.read()

# Header: byte 0 = 0xFF, bytes 1..2 = length. Line 1 starts at index 3.
p = 3
lines = []
while p < len(data) - 4:
    next_ptr = int.from_bytes(data[p:p+2], 'big')
    if next_ptr == 0:
        break
    lineno = int.from_bytes(data[p+2:p+4], 'big')
    p += 4
    
    out = []
    in_quote = False
    while p < len(data):
        b = data[p]
        p += 1
        if b == 0:
            break
        if b == 0x22:
            in_quote = not in_quote
            out.append(chr(b))
        elif in_quote:
            out.append(chr(b) if 32 <= b < 127 or b in (10, 13) else '[{:02X}]'.format(b))
        elif b == 0xFF:
            if p < len(data):
                b2 = data[p]
                p += 1
                token_val = 0xFF00 | b2
                out.append(tokenToWord.get(token_val, '[FF{:02X}]'.format(b2)))
        elif b >= 0x80:
            token_str = tokenToWord.get(b, '[{:02X}]'.format(b))
            out.append(token_str)
        else:
            out.append(chr(b))
    lines.append('{:d} '.format(lineno) + ''.join(out))

listing_text = '\n'.join(lines)
with open(r'd:\Documents\Antigravity\Apple2\1000bornes\source\mbornes_listing.bas', 'w', encoding='utf-8') as out:
    out.write(listing_text)

print('Successfully detokenized {:d} lines!'.format(len(lines)))
