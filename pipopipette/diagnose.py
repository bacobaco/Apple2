import random

class Game:
    def __init__(self, size=4):
        self.size = size
        self.lh = [0] * (size * (size + 1))
        self.lv = [0] * ((size + 1) * size)
        self.bx = [0] * (size * size)
        self.p1 = 0
        self.p2 = 0
        self.turn = 0
        
    def copy(self):
        g = Game(self.size)
        g.lh = list(self.lh)
        g.lv = list(self.lv)
        g.bx = list(self.bx)
        g.p1 = self.p1
        g.p2 = self.p2
        g.turn = self.turn
        return g

    def count_sides(self, x, y):
        if x < 0 or x >= self.size or y < 0 or y >= self.size: return 0
        t = 1 if self.lh[y * self.size + x] else 0
        b = 1 if self.lh[(y + 1) * self.size + x] else 0
        l = 1 if self.lv[y * (self.size + 1) + x] else 0
        r = 1 if self.lv[y * (self.size + 1) + x + 1] else 0
        return t + b + l + r

    def is_free(self, m, x, y):
        if m == 0:
            if x < 0 or x >= self.size or y < 0 or y > self.size: return False
            return self.lh[y * self.size + x] == 0
        else:
            if x < 0 or x > self.size or y < 0 or y >= self.size: return False
            return self.lv[y * (self.size + 1) + x] == 0

    def play(self, m, x, y):
        closed = 0
        if m == 0:
            self.lh[y * self.size + x] = 1
            if y > 0 and self.count_sides(x, y - 1) == 4 and self.bx[(y - 1) * self.size + x] == 0:
                self.bx[(y - 1) * self.size + x] = self.turn + 1
                closed += 1
            if y < self.size and self.count_sides(x, y) == 4 and self.bx[y * self.size + x] == 0:
                self.bx[y * self.size + x] = self.turn + 1
                closed += 1
        else:
            self.lv[y * (self.size + 1) + x] = 1
            if x > 0 and self.count_sides(x - 1, y) == 4 and self.bx[y * self.size + x - 1] == 0:
                self.bx[y * self.size + x - 1] = self.turn + 1
                closed += 1
            if x < self.size and self.count_sides(x, y) == 4 and self.bx[y * self.size + x] == 0:
                self.bx[y * self.size + x] = self.turn + 1
                closed += 1
        if self.turn == 0: self.p1 += closed
        else: self.p2 += closed
        if closed == 0: self.turn = 1 - self.turn
        return closed

    def is_safe(self, m, x, y):
        if m == 0:
            if y > 0 and self.count_sides(x, y - 1) == 2: return False
            if y < self.size and self.count_sides(x, y) == 2: return False
        else:
            if x > 0 and self.count_sides(x - 1, y) == 2: return False
            if x < self.size and self.count_sides(x, y) == 2: return False
        return True

    def scan_close(self):
        for y in range(self.size):
            for x in range(self.size):
                if self.count_sides(x, y) == 3:
                    if self.lh[y * self.size + x] == 0: return (0, x, y, x, y)
                    if self.lh[(y + 1) * self.size + x] == 0: return (0, x, y + 1, x, y)
                    if self.lv[y * (self.size + 1) + x] == 0: return (1, x, y, x, y)
                    if self.lv[y * (self.size + 1) + x + 1] == 0: return (1, x + 1, y, x, y)
        return None

    def get_all_free(self):
        f = []
        for y in range(self.size + 1):
            for x in range(self.size):
                if self.is_free(0, x, y): f.append((0, x, y))
        for y in range(self.size):
            for x in range(self.size + 1):
                if self.is_free(1, x, y): f.append((1, x, y))
        return f

    def count_safe_moves(self):
        c = 0
        for m, x, y in self.get_all_free():
            if self.is_safe(m, x, y): c += 1
        return c

def rollout(game):
    sim = game.copy()
    while sim.p1 + sim.p2 < sim.size * sim.size:
        c = sim.scan_close()
        if c:
            sim.play(c[0], c[1], c[2])
        elif sim.count_safe_moves() > 0:
            safes = [m for m in sim.get_all_free() if sim.is_safe(m[0], m[1], m[2])]
            sim.play(safes[0][0], safes[0][1], safes[0][2])
        else:
            mv = find_shortest_chain_sacrifice(sim)
            if not mv:
                frees = sim.get_all_free()
                if not frees: break
                mv = frees[0]
            sim.play(mv[0], mv[1], mv[2])
    return sim.p2

# AI Level 3 implementation (Rollout-Guided Handouts)
def ai_l3_move(game):
    close_info = game.scan_close()
    if close_info:
        if game.count_safe_moves() > 0:
            return (close_info[0], close_info[1], close_info[2])
        remaining = (game.size * game.size) - game.p1 - game.p2
        if remaining <= 4:
            return (close_info[0], close_info[1], close_info[2])
            
        # Check greedy rollout score
        simA = game.copy()
        simA.play(close_info[0], close_info[1], close_info[2])
        best_score = rollout(simA)
        best_move = (close_info[0], close_info[1], close_info[2])
        
        # Search candidate handouts
        for m, x, y in game.get_all_free():
            simB = game.copy()
            cl = simB.play(m, x, y)
            if cl != 0: continue
            
            s0 = simB.p1 + simB.p2
            while True:
                cc = simB.scan_close()
                if not cc: break
                simB.play(cc[0], cc[1], cc[2])
            opp_b = (simB.p1 + simB.p2) - s0
            
            if opp_b in (2, 4) and opp_b < remaining:
                simB_play = game.copy()
                simB_play.play(m, x, y)
                sc = rollout(simB_play)
                if sc > best_score:
                    best_score = sc
                    best_move = (m, x, y)
        return best_move

    if game.count_safe_moves() > 0:
        return expert_best_safe_move(game)
    return find_shortest_chain_sacrifice(game)

def expert_best_safe_move(game):
    best_score = -9999
    best_moves = []
    for m, x, y in game.get_all_free():
        if not game.is_safe(m, x, y): continue
        score = 100
        is_p = (m == 0 and (y == 0 or y == game.size)) or (m == 1 and (x == 0 or x == game.size))
        if is_p: score += 25
        if m == 0:
            if y > 0:
                s = game.count_sides(x, y - 1)
                if s == 0: score += 15
                elif s == 1: score -= 25
            if y < game.size:
                s = game.count_sides(x, y)
                if s == 0: score += 15
                elif s == 1: score -= 25
        else:
            if x > 0:
                s = game.count_sides(x - 1, y)
                if s == 0: score += 15
                elif s == 1: score -= 25
            if x < game.size:
                s = game.count_sides(x, y)
                if s == 0: score += 15
                elif s == 1: score -= 25
                
        # Lookahead
        sim = game.copy()
        sim.play(m, x, y)
        opp_safes = sim.count_safe_moves()
        if opp_safes == 0: score += 80
        elif (opp_safes % 2) == 0: score += 30
        else: score -= 20
        
        score += random.randint(0, 1)
        if score > best_score:
            best_score = score
            best_moves = [(m, x, y)]
        elif score == best_score:
            best_moves.append((m, x, y))
    return random.choice(best_moves)

def find_shortest_chain_sacrifice(game):
    best_sc = 9999
    best_m = None
    for m, x, y in game.get_all_free():
        sim = game.copy()
        sim.play(m, x, y)
        s0 = sim.p1 + sim.p2
        while True:
            c = sim.scan_close()
            if not c: break
            sim.play(c[0], c[1], c[2])
        casc = (sim.p1 + sim.p2) - s0
        sc = casc * 4
        is_p = (m == 0 and (y == 0 or y == game.size)) or (m == 1 and (x == 0 or x == game.size))
        if is_p: sc -= 1
        if sc < best_sc:
            best_sc = sc
            best_m = (m, x, y)
    return best_m

print('Diagnosis script loaded')
