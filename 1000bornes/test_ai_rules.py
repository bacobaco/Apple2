import os
import sys

# Import emulator from test_emulator
from test_emulator import MPU, Apple2Memory

def test_ai_scenarios():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    bin_path = os.path.join(script_dir, "1000bornes.bin")
    with open(bin_path, "rb") as f:
        code = f.read()

    load_addr = 0x4000
    if len(code) >= 2 and code[0] == 0x00 and code[1] == 0x40:
        code = code[2:]

    mem = Apple2Memory()
    for i, b in enumerate(code):
        mem.mem[load_addr + i] = b

    mpu = MPU(memory=mem)
    mpu.pc = load_addr
    mpu.sp = 0xFF

    # Let game initialize up to main menu/round start
    # Let's read labels.txt to find exact routine addresses
    labels = {}
    with open(os.path.join(script_dir, "labels.txt")) as f:
        for line in f:
            line = line.strip()
            if "=" in line:
                parts = line.split("=")
                lbl = parts[0].strip()
                val = parts[1].strip().replace("$", "0x")
                try:
                    labels[lbl] = int(val, 16)
                except ValueError:
                    pass

    print(f"Labels loaded: {len(labels)}")
    print(f"ThomsonSmartDiscard = ${labels.get('ThomsonSmartDiscard', 0):04X}")
    print(f"ThomsonTurnAction   = ${labels.get('ThomsonTurnAction', 0):04X}")
    print(f"CanThomsonAddDist   = ${labels.get('CanThomsonAddDist', 0):04X}")

    # TEST 1: ThomsonSmartDiscard when Thomson is limited to 50 km/h (T_LIMIT = 4)
    # Give Thomson a Fin de Limite (9) and some distances (100km, 50km, 25km)
    # Expected: Thomson must NEVER discard Fin de Limite (score 0), he should discard a distance card.
    t_hand_addr = labels['T_HAND']
    t_limit_addr = labels['T_LIMIT']
    t_battle_addr = labels['T_BATTLE']
    t_bottes_addr = labels['T_BOTTES']
    best_disc_idx_addr = labels['BEST_DISC_IDX']

    # Set up scenario:
    mem.mem[t_limit_addr] = 4     # CARD_LIMITATION
    mem.mem[t_battle_addr] = 5    # CARD_FEUROUGE (Thomson is also stopped by red light)
    for b in range(4):
        mem.mem[t_bottes_addr + b] = 0

    # Hand: [FINLIMITE(9), 100KM(12), 75KM(13), 50KM(14), 25KM(15), 0, 0]
    mem.mem[t_hand_addr + 0] = 9   # Fin de limite
    mem.mem[t_hand_addr + 1] = 12  # 100 km
    mem.mem[t_hand_addr + 2] = 13  # 75 km
    mem.mem[t_hand_addr + 3] = 14  # 50 km
    mem.mem[t_hand_addr + 4] = 15  # 25 km
    mem.mem[t_hand_addr + 5] = 0
    mem.mem[t_hand_addr + 6] = 0

    # Call ThomsonSmartDiscard directly
    # Set stack and push return address ($3FFF)
    mpu.sp = 0xFD
    mem.mem[0x01FE] = 0x3F
    mem.mem[0x01FF] = 0xFE # RTS to $3FFF
    mpu.pc = labels['ThomsonSmartDiscard']

    # Patch jsr DisplayThomsonDisc and WaitThomsonActionPause to RTS so test runs instantly without graphic delays
    # Save original bytes
    orig_disp = [mem.mem[labels['DisplayThomsonDisc']]]
    mem.mem[labels['DisplayThomsonDisc']] = 0x60 # RTS
    mem.mem[labels['DrawCardInSlot']] = 0x60     # RTS
    mem.mem[labels['WaitThomsonActionPause']] = 0x60 # RTS

    steps = 0
    while mpu.pc != 0x3FFF and steps < 20000:
        mpu.step()
        steps += 1

    chosen_idx = mem.mem[best_disc_idx_addr]
    chosen_card = mem.mem[t_hand_addr + chosen_idx]
    print(f"Test 1 - Discard choice while limited: chosen index {chosen_idx} (card {chosen_card})")
    assert chosen_card != 9, "ERROR: Thomson discarded Fin de Limite while limited!"
    print("PASS: Thomson DID NOT discard Fin de Limite while limited! (He discarded index " + str(chosen_idx) + " card " + str(chosen_card) + ")")

    # TEST 2: Thomson play choice when stopped by hazard AND limited:
    # Hand: [FINLIMITE(9), 100KM(12), 50KM(14), 0, 0, 0, 0]
    # Thomson has FEUROUGE (5) on battle pile, so cannot roll or play distance.
    # But he has LIMITATION (4) on limit pile and FINLIMITE (9) in hand.
    # Expected: Thomson MUST play FINLIMITE (curing his limitation) instead of discarding!
    mem.mem[t_limit_addr] = 4     # CARD_LIMITATION
    mem.mem[t_battle_addr] = 5    # CARD_FEUROUGE
    mem.mem[t_hand_addr + 0] = 9  # Fin de limite
    mem.mem[t_hand_addr + 1] = 12 # 100 km
    mem.mem[t_hand_addr + 2] = 14 # 50 km
    mem.mem[t_hand_addr + 3] = 0
    mem.mem[t_hand_addr + 4] = 0
    mem.mem[t_hand_addr + 5] = 0
    mem.mem[t_hand_addr + 6] = 0

    play_card_addr = labels['PLAY_CARD']
    draw_menu_addr = labels['DrawMenuThomson']
    mem.mem[draw_menu_addr] = 0x60 # RTS
    mem.mem[labels['DisplayThomsonPlay']] = 0x60 # RTS
    mem.mem[labels['DrawCardInSlot']] = 0x60 # RTS
    mem.mem[labels['EraseSlot']] = 0x60 # RTS

    mpu.sp = 0xFD
    mem.mem[0x01FE] = 0x3F
    mem.mem[0x01FF] = 0xFE
    mpu.pc = labels['ThomsonTurnAction']

    steps = 0
    while mpu.pc != 0x3FFF and steps < 20000:
        mpu.step()
        steps += 1

    played_card = mem.mem[play_card_addr]
    new_t_limit = mem.mem[t_limit_addr]
    print(f"Test 2 - Play choice while stopped and limited: played card {played_card}, new T_LIMIT = {new_t_limit}")
    assert played_card == 9, f"ERROR: Thomson should have played FINLIMITE (9) but played {played_card}"
    assert new_t_limit == 0, f"ERROR: T_LIMIT should be cleared to 0, but is {new_t_limit}"
    print("PASS: Thomson successfully played Fin de Limite while stopped by red light!")

    # TEST 3: Thomson never plays Feu Vert on Feu Vert!
    # Hand: [FEUVERT(10), 100KM(12), 0, 0, 0, 0, 0]
    # Thomson already rolling: T_BATTLE = 10 (FEUVERT).
    # Expected: Thomson MUST play 100KM (12), NOT Feu Vert (10)!
    mem.mem[t_limit_addr] = 0
    mem.mem[t_battle_addr] = 10   # FEUVERT
    mem.mem[labels['T_KMS']] = 0
    mem.mem[labels['T_KMS']+1] = 0
    mem.mem[t_hand_addr + 0] = 10 # Feu Vert
    mem.mem[t_hand_addr + 1] = 12 # 100 km
    mem.mem[t_hand_addr + 2] = 0
    mem.mem[t_hand_addr + 3] = 0
    mem.mem[t_hand_addr + 4] = 0
    mem.mem[t_hand_addr + 5] = 0
    mem.mem[t_hand_addr + 6] = 0

    mpu.sp = 0xFD
    mem.mem[0x01FE] = 0x3F
    mem.mem[0x01FF] = 0xFE
    mpu.pc = labels['ThomsonTurnAction']

    steps = 0
    while mpu.pc != 0x3FFF and steps < 20000:
        mpu.step()
        steps += 1

    played_card = mem.mem[play_card_addr]
    print(f"Test 3 - Play choice while already having Feu Vert: played card {played_card}")
    assert played_card == 12, f"ERROR: Thomson played {played_card} instead of distance card 12 (100km)!"
    print("PASS: Thomson rolled with 100 KM and DID NOT replay Feu Vert!")

    # TEST 4: Thomson plays Feu Rouge on player!
    # Player is at 500 kms, rolling with Feu Vert (P_BATTLE = 10, P_STARTED = 1, P_BOTTES+3 = 0).
    # Thomson has FEUROUGE (5) in hand.
    # Expected: Thomson MUST attack player with FEUROUGE (5), and P_BATTLE must become 5!
    p_battle_addr = labels['P_BATTLE']
    p_started_addr = labels['P_STARTED']
    p_bottes_addr = labels['P_BOTTES']
    p_kms_addr = labels['P_KMS']
    mem.mem[p_battle_addr] = 10     # Player has Feu Vert
    mem.mem[p_started_addr] = 1    # Player has started
    mem.mem[p_bottes_addr + 3] = 0 # Player does not have VP
    mem.mem[p_kms_addr] = 0        # 500 kms ($01F4)
    mem.mem[p_kms_addr + 1] = 0x02 # >500 kms
    mem.mem[t_battle_addr] = 0     # Thomson has not started yet
    mem.mem[t_hand_addr + 0] = 5   # FEUROUGE
    mem.mem[t_hand_addr + 1] = 1   # Panne
    mem.mem[t_hand_addr + 2] = 2   # Accident
    mem.mem[t_hand_addr + 3] = 0
    mem.mem[t_hand_addr + 4] = 0
    mem.mem[t_hand_addr + 5] = 0
    mem.mem[t_hand_addr + 6] = 0

    mpu.sp = 0xFD
    mem.mem[0x01FE] = 0x3F
    mem.mem[0x01FF] = 0xFE
    mpu.pc = labels['ThomsonTurnAction']

    steps = 0
    while mpu.pc != 0x3FFF and steps < 20000:
        mpu.step()
        steps += 1

    played_card = mem.mem[play_card_addr]
    new_p_battle = mem.mem[p_battle_addr]
    print(f"Test 4 - Thomson attack with Feu Rouge: played card {played_card}, new P_BATTLE = {new_p_battle}")
    assert played_card == 5, f"ERROR: Thomson should have played FEUROUGE (5) but played {played_card}"
    assert new_p_battle == 5, f"ERROR: P_BATTLE should be 5 (FEUROUGE), but is {new_p_battle}"
    print("PASS: Thomson successfully attacked player with Feu Rouge, and P_BATTLE is now 5!")

    print("\nALL AI RULE TESTS PASSED PERFECTLY!")

if __name__ == '__main__':
    test_ai_scenarios()
