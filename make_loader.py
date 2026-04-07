import sys
import os

def main():
    if len(sys.argv) < 2:
        print("Usage: python make_loader.py <fichier.bin>")
        return

    bin_file = sys.argv[1]
    bas_file = os.path.splitext(bin_file)[0] + "_loader.bas"

    try:
        with open(bin_file, "rb") as f:
            data = f.read()
    except FileNotFoundError:
        print(f"Erreur : Le fichier {bin_file} est introuvable.")
        return

    # L'adresse de chargement pour le jeu HGR est $6000 (24576 en décimal)
    start_addr = 24576
    end_addr = start_addr + len(data) - 1

    lines = [
        "10 REM *** CHARGEUR BASIC PONG ***",
        "20 HOME : VTAB 10 : HTAB 6 : INVERSE : PRINT \" CHARGEMENT DE SNAKE... \" : NORMAL",
        "30 HTAB 5 : PRINT \"(CELA PREND ENVIRON 30 SECONDES)\"",
        f"40 FOR I = {start_addr} TO {end_addr}",
        "50 READ B : POKE I, B",
        "60 NEXT I",
        f"70 CALL {start_addr}",
        "80 END"
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