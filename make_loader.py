import sys
import os

def main():
    if len(sys.argv) < 2:
        print("Usage: python make_loader.py <fichier.bin> [adresse_hex]")
        print("Exemple: python make_loader.py snake.bin 45F0")
        return

    bin_file = sys.argv[1]
    start_addr_hex = "6000"
    if len(sys.argv) >= 3:
        start_addr_hex = sys.argv[2]
        
    try:
        start_addr = int(start_addr_hex, 16)
    except ValueError:
        print(f"Erreur : L'adresse {start_addr_hex} n'est pas une valeur hexadécimale valide.")
        return

    bas_file = os.path.splitext(bin_file)[0] + "_loader.bas"

    try:
        with open(bin_file, "rb") as f:
            data = f.read()
    except FileNotFoundError:
        print(f"Erreur : Le fichier {bin_file} est introuvable.")
        return

    end_addr = start_addr + len(data) - 1

    lines = [
        "10 REM *** CHARGEUR BASIC ***",
        "20 HOME : VTAB 10 : HTAB 8 : INVERSE : PRINT \" CHARGEMENT DU JEU... \" : NORMAL",
        f"30 SZ = {len(data)} : SA = {start_addr} : EA = {end_addr}",
        "40 ST = INT(SZ / 20) : IF ST = 0 THEN ST = 1",
        "50 VTAB 12 : HTAB 5 : PRINT \"0% [                    ] 100%\"",
        "60 P = 0 : C = 0",
        "70 FOR I = SA TO EA",
        "80 READ B : POKE I, B",
        "90 C = C + 1 : IF C = ST AND P < 20 THEN P = P + 1 : VTAB 12 : HTAB 8 + P : PRINT \"=\"; : C = 0",
        "100 NEXT I",
        "110 VTAB 12 : HTAB 9 : PRINT \"====================\"",
        f"120 CALL {start_addr}",
        "130 END"
    ]

    line_num = 1000
    chunk_size = 12  # Nombre d'octets par ligne DATA (évite les lignes trop longues)
    
    for i in range(0, len(data), chunk_size):
        chunk = data[i:i+chunk_size]
        data_str = ",".join(str(b) for b in chunk)
        lines.append(f"{line_num} DATA {data_str}")
        line_num += 10

    with open(bas_file, "w") as f:
        f.write("\n".join(lines) + "\n")

    print(f"Fichier BASIC généré avec succès : {bas_file}")

if __name__ == "__main__":
    main()