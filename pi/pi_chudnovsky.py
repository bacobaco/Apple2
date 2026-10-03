"""
================================================================================
           MOTEUR ULTRA-RAPIDE DE PI (ALGORITHME DES FRÈRES CHUDNOVSKY)
       Cockpit Temps Réel, Binary Splitting (GMP AVX-512) & Analyses GPU RTX 5080
================================================================================
Formule exacte :
                 426880 * sqrt(10005) * Q(0, N)
         pi  =  ────────────────────────────────
                            T(0, N)

Convergence : ~14.18164746 décimales exactes par terme k.
Arithmétique : C natif GNU MP (GMP) avec Karatsuba, Toom-Cook et FFT.
Cockpit : Télémétrie matérielle et progression multi-étapes en temps réel.
================================================================================
"""

import sys
import os
import time
import math
import threading
import argparse
import warnings

warnings.filterwarnings('ignore')

# ---------------------------------------------------------------------------
# Redirection automatique vers Python 3.11 (avec gmpy2 + CUDA torch) si besoin
# ---------------------------------------------------------------------------
def _ensure_correct_python():
    try:
        import gmpy2
        import torch
    except ImportError:
        py311 = r"C:\Users\baco\AppData\Local\Programs\Python\Python311\python.exe"
        if os.path.exists(py311) and os.path.normcase(sys.executable) != os.path.normcase(py311):
            import subprocess
            cmd = [py311, os.path.abspath(__file__)] + sys.argv[1:]
            sys.exit(subprocess.call(cmd))

_ensure_correct_python()

# Set console code page to UTF-8 on Windows
if sys.platform == "win32":
    try:
        os.system("chcp 65001 >nul 2>&1")
    except Exception:
        pass

# Disable integer string conversion limit in Python 3.11+
if hasattr(sys, 'set_int_max_str_digits'):
    sys.set_int_max_str_digits(0)

# Ensure UTF-8 output on console
if hasattr(sys.stdout, 'reconfigure'):
    try:
        sys.stdout.reconfigure(encoding='utf-8', errors='replace')
        sys.stderr.reconfigure(encoding='utf-8', errors='replace')
    except Exception:
        pass

# High-precision GNU MP / gmpy2 support
try:
    import gmpy2
    mpz = gmpy2.mpz
    isqrt = gmpy2.isqrt
    HAS_GMPY2 = True
except ImportError:
    import math
    mpz = int
    isqrt = math.isqrt
    HAS_GMPY2 = False

# PyTorch CUDA GPU support (RTX 5080)
try:
    import torch
    HAS_CUDA = torch.cuda.is_available()
    CUDA_DEVICE = torch.device('cuda:0') if HAS_CUDA else None
    GPU_NAME = torch.cuda.get_device_name(0) if HAS_CUDA else "None"
except ImportError:
    HAS_CUDA = False
    CUDA_DEVICE = None
    GPU_NAME = "None"

# System and NVML Hardware Telemetry
try:
    import psutil
    HAS_PSUTIL = True
    psutil.cpu_percent(interval=None)
except ImportError:
    HAS_PSUTIL = False

try:
    import pynvml
    pynvml.nvmlInit()
    NVML_HANDLE = pynvml.nvmlDeviceGetHandleByIndex(0)
    HAS_NVML = True
except Exception:
    HAS_NVML = False
    NVML_HANDLE = None

# ANSI Colors & Styles
C_RESET   = "\033[0m"
C_BOLD    = "\033[1m"
C_DIM     = "\033[2m"
C_GREEN   = "\033[92m"
C_CYAN    = "\033[96m"
C_YELLOW  = "\033[93m"
C_RED     = "\033[91m"
C_MAGENTA = "\033[95m"
C_WHITE   = "\033[97m"

SPINNERS = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]

# Chudnovsky Algorithm Constants
C = 640320
C3_OVER_24 = mpz(C**3 // 24)
DIGITS_PER_TERM = 14.181647462725477


# ---------------------------------------------------------------------------
# Hardware Telemetry Helper
# ---------------------------------------------------------------------------
def get_hardware_telemetry():
    telemetry = {
        "cpu_pct": 0.0,
        "ram_used_mb": 0,
        "gpu_util": 0,
        "gpu_temp": 0,
        "gpu_vram_used": 0,
        "gpu_vram_total": 0,
    }
    if HAS_PSUTIL:
        try:
            telemetry["cpu_pct"] = psutil.cpu_percent(interval=None)
            telemetry["ram_used_mb"] = psutil.Process().memory_info().rss // (1024 * 1024)
        except Exception:
            pass

    if HAS_NVML and NVML_HANDLE:
        try:
            util = pynvml.nvmlDeviceGetUtilizationRates(NVML_HANDLE)
            temp = pynvml.nvmlDeviceGetTemperature(NVML_HANDLE, pynvml.NVML_TEMPERATURE_GPU)
            mem = pynvml.nvmlDeviceGetMemoryInfo(NVML_HANDLE)
            telemetry["gpu_util"] = util.gpu
            telemetry["gpu_temp"] = temp
            telemetry["gpu_vram_used"] = mem.used // (1024 * 1024)
            telemetry["gpu_vram_total"] = mem.total // (1024 * 1024)
        except Exception:
            pass
    return telemetry


# ---------------------------------------------------------------------------
# Real-Time Live Cockpit HUD
# ---------------------------------------------------------------------------
class ChudnovskyCockpit:
    """
    Live ANSI Cockpit dashboard rendering real-time computation stages and hardware telemetry.
    """
    def __init__(self, digits, num_terms):
        self.digits = digits
        self.millions = digits / 1_000_000.0
        self.num_terms = num_terms
        self.t_start = time.perf_counter()
        
        # Stages: 1: BS Tree, 2: Sqrt, 3: Div, 4: GPU, 5: Done
        self.stage = 1
        self.stage_names = [
            "",
            "Binary Splitting (Arbre de produit géant)",
            "Racine Carrée Entière C (Newton isqrt)",
            "Division Bignum Finale Q / T",
            "Analyses Statistiques GPU RTX 5080",
            "Finalisation & Sauvegarde"
        ]
        self.stage_times = [0.0] * 6
        self.stage_status = ["", "En cours...", "En attente", "En attente", "En attente", "En attente"]
        
        self.bs_completed_terms = 0
        self.bs_pct = 0.0
        self.q_bits = 0
        self.t_bits = 0
        
        self.stop_event = threading.Event()
        self.thread = None
        self.telem = get_hardware_telemetry()

    def start(self):
        os.system("")
        # Clear screen and hide cursor
        sys.stdout.write("\033[2J\033[H\033[?25l")
        sys.stdout.flush()
        self.thread = threading.Thread(target=self._render_loop, daemon=True)
        self.thread.start()

    def update_bs(self, count):
        self.bs_completed_terms += count
        if self.num_terms > 0:
            self.bs_pct = min(100.0, (self.bs_completed_terms / float(self.num_terms)) * 100.0)

    def set_stage(self, stage_idx, duration=None):
        prev_idx = self.stage
        if duration is not None and prev_idx < len(self.stage_times):
            self.stage_times[prev_idx] = duration
            self.stage_status[prev_idx] = f"✔ Terminé ({duration:.3f} s)"
        self.stage = stage_idx
        if stage_idx < len(self.stage_status):
            self.stage_status[stage_idx] = "En cours..."

    def _render_loop(self):
        last_telem_t = 0
        while not self.stop_event.is_set():
            now = time.perf_counter()
            if now - last_telem_t >= 0.5:
                self.telem = get_hardware_telemetry()
                last_telem_t = now

            self._draw(now)
            time.sleep(0.06)

    def _draw(self, now):
        elapsed = now - self.t_start
        est_dps = self.digits / elapsed if elapsed > 0 else 0
        spinner_char = SPINNERS[int(now * 10) % len(SPINNERS)]

        # Estimate remaining time
        if self.stage == 1 and self.bs_pct > 2.0:
            total_est_bs = elapsed / (self.bs_pct / 100.0)
            rem = max(0.0, (total_est_bs * 1.35) - elapsed)
            eta_str = f"~{rem:.1f} s"
        elif self.stage in (2, 3, 4):
            eta_str = "Finalisation..."
        elif self.stage >= 5:
            eta_str = "0.0 s"
        else:
            eta_str = "Calcul en cours..."

        sys.stdout.write("\033[H")
        
        # Title Bar
        header = (
            f"{C_BOLD}{C_CYAN}╔═════════════════════════════════════════════════════════════════════════════════╗{C_RESET}\033[K\n"
            f"{C_BOLD}{C_CYAN}║     COCKPIT HAUTE PERFORMANCE DE PI - ALGORITHME DES FRÈRES CHUDNOVSKY         ║{C_RESET}\033[K\n"
            f"{C_BOLD}{C_CYAN}║           Moteur 32 Cœurs CPU (GMP AVX-512) + GPU NVIDIA RTX 5080 (CUDA)        ║{C_RESET}\033[K\n"
            f"{C_BOLD}{C_CYAN}╚═════════════════════════════════════════════════════════════════════════════════╝{C_RESET}\033[K\n"
        )

        # Overview
        mil_str = f"{self.millions:.2f} Million{'s' if self.millions >= 2 else ''}" if self.millions >= 1 else f"{self.digits:,} décimales"
        overview = (
            f"  {C_YELLOW}Cible demandée   :{C_RESET} {C_BOLD}{C_WHITE}{self.digits:,}{C_RESET} décimales ({C_GREEN}{mil_str}{C_RESET})\033[K\n"
            f"  {C_YELLOW}Série Chudnovsky :{C_RESET} {C_BOLD}{self.num_terms:,}{C_RESET} termes (~14.18 décimales/terme)\033[K\n"
            f"  {C_YELLOW}Temps Écoulé     :{C_RESET} {C_BOLD}{elapsed:.2f} s{C_RESET}   │   {C_YELLOW}ETA :{C_RESET} {C_CYAN}{eta_str}{C_RESET}   │   {C_YELLOW}Débit :{C_RESET} {C_GREEN}{est_dps:,.0f}{C_RESET} dps\033[K\n"
        )

        # Stages Progress Bars Helper
        def make_bar(pct, width=28):
            filled = min(width, max(0, int(round((pct / 100.0) * width))))
            return "█" * filled + "░" * (width - filled)

        # Stage 1: BS Tree
        s1_pct = 100.0 if self.stage > 1 else self.bs_pct
        s1_bar = make_bar(s1_pct)
        s1_color = C_GREEN if self.stage > 1 else C_YELLOW
        s1_icon = "✔" if self.stage > 1 else spinner_char
        s1_extra = f"{self.bs_completed_terms:,} / {self.num_terms:,} termes" if self.stage == 1 else self.stage_status[1]

        # Stage 2: Sqrt
        s2_pct = 100.0 if self.stage > 2 else (50.0 if self.stage == 2 else 0.0)
        s2_bar = make_bar(s2_pct)
        s2_color = C_GREEN if self.stage > 2 else (C_YELLOW if self.stage == 2 else C_DIM)
        s2_icon = "✔" if self.stage > 2 else (spinner_char if self.stage == 2 else "·")

        # Stage 3: Div
        s3_pct = 100.0 if self.stage > 3 else (50.0 if self.stage == 3 else 0.0)
        s3_bar = make_bar(s3_pct)
        s3_color = C_GREEN if self.stage > 3 else (C_YELLOW if self.stage == 3 else C_DIM)
        s3_icon = "✔" if self.stage > 3 else (spinner_char if self.stage == 3 else "·")

        # Stage 4: GPU
        s4_pct = 100.0 if self.stage > 4 else (50.0 if self.stage == 4 else 0.0)
        s4_bar = make_bar(s4_pct)
        s4_color = C_GREEN if self.stage > 4 else (C_MAGENTA if self.stage == 4 else C_DIM)
        s4_icon = "✔" if self.stage > 4 else (spinner_char if self.stage == 4 else "·")

        stages_ui = (
            f"{C_BOLD}{C_CYAN}────────────────────────────── ÉTAPES DE CALCUL ───────────────────────────────{C_RESET}\033[K\n"
            f"  {s1_icon} [1] Arbre Binaire (BS)  : [{s1_color}{s1_bar}{C_RESET}] {s1_pct:5.1f}%  {s1_extra}\033[K\n"
            f"  {s2_icon} [2] Racine Carrée C     : [{s2_color}{s2_bar}{C_RESET}] {s2_pct:5.1f}%  {self.stage_status[2]}\033[K\n"
            f"  {s3_icon} [3] Division Bignum     : [{s3_color}{s3_bar}{C_RESET}] {s3_pct:5.1f}%  {self.stage_status[3]}\033[K\n"
            f"  {s4_icon} [4] Analyses GPU CUDA   : [{s4_color}{s4_bar}{C_RESET}] {s4_pct:5.1f}%  {self.stage_status[4]}\033[K\n"
        )

        # Hardware Telemetry
        cpu_bar_len = min(20, max(0, int(self.telem["cpu_pct"] / 5)))
        cpu_bar = "█" * cpu_bar_len + "░" * (20 - cpu_bar_len)

        gpu_bar_len = min(20, max(0, int(self.telem["gpu_util"] / 5)))
        gpu_bar = "█" * gpu_bar_len + "░" * (20 - gpu_bar_len)

        reg_str = f"Q/T: ~{self.q_bits:,} bits" if self.q_bits > 0 else "En construction..."
        hw_ui = (
            f"{C_BOLD}{C_CYAN}─────────────────────────── TÉLÉMÉTRIE MATÉRIELLE ───────────────────────────{C_RESET}\033[K\n"
            f"  CPU (32 Cœurs)   : [{C_GREEN}{cpu_bar}{C_RESET}] {self.telem['cpu_pct']:5.1f}%   │  RAM Process : {self.telem['ram_used_mb']:,} MB\033[K\n"
            f"  GPU (RTX 5080)   : [{C_MAGENTA}{gpu_bar}{C_RESET}] {self.telem['gpu_util']:5.1f}%   │  VRAM : {self.telem['gpu_vram_used']}/{self.telem['gpu_vram_total']} MB │ Temp: {self.telem['gpu_temp']}°C\033[K\n"
            f"  Taille Registres : {C_WHITE}{reg_str}{C_RESET}\033[K\n"
            f"{C_BOLD}{C_CYAN}─────────────────────────────────────────────────────────────────────────────{C_RESET}\033[K\n"
        )

        sys.stdout.write(header + overview + stages_ui + hw_ui)
        sys.stdout.flush()

    def finish(self, duration_total):
        self.stop_event.set()
        if self.thread:
            self.thread.join(timeout=0.5)
        # Restore cursor
        sys.stdout.write("\033[?25h")
        self._draw(time.perf_counter())


# ---------------------------------------------------------------------------
# Binary Splitting with Real-Time Progress Tracking
# ---------------------------------------------------------------------------
def chudnovsky_bs_cockpit(a, b, cockpit=None):
    """
    Computes P(a, b), Q(a, b), T(a, b) with granular chunked progress tracking.
    """
    count = b - a
    if count <= 64:
        # Base tree computation
        def _base_tree(x, y):
            if y - x == 1:
                if x == 0:
                    return mpz(1), mpz(1), mpz(13591409)
                six_x = 6 * x
                P = mpz((six_x - 5) * (2 * x - 1) * (six_x - 1))
                Q = mpz(x**3 * C3_OVER_24)
                T = P * (545140134 * x + 13591409)
                if x & 1:
                    T = -T
                return P, Q, T
            mid = (x + y) >> 1
            P1, Q1, T1 = _base_tree(x, mid)
            P2, Q2, T2 = _base_tree(mid, y)
            return P1 * P2, Q1 * Q2, Q2 * T1 + P1 * T2

        res = _base_tree(a, b)
        if cockpit:
            cockpit.update_bs(count)
        return res

    m = (a + b) >> 1
    P1, Q1, T1 = chudnovsky_bs_cockpit(a, m, cockpit)
    P2, Q2, T2 = chudnovsky_bs_cockpit(m, b, cockpit)
    return P1 * P2, Q1 * Q2, Q2 * T1 + P1 * T2


# ---------------------------------------------------------------------------
# GPU Analytics (RTX 5080 CUDA Tensor Suite)
# ---------------------------------------------------------------------------
def run_gpu_analytics(pi_str):
    if not HAS_CUDA:
        return None

    decimals = pi_str[2:]
    if len(decimals) < 100:
        return None

    t0 = time.perf_counter()
    max_sample = min(10000000, len(decimals))
    digit_bytes = decimals[:max_sample].encode('ascii')
    
    tensor_bytes = torch.frombuffer(bytearray(digit_bytes), dtype=torch.uint8)
    cuda_tensor = (tensor_bytes.to(device=CUDA_DEVICE, non_blocking=True).long() - 48).clamp(0, 9)

    bc = torch.bincount(cuda_tensor, minlength=10)
    counts = bc.cpu().tolist()
    total = len(cuda_tensor)

    probs = bc.float() / float(total)
    entropy = -torch.sum(probs * torch.log2(probs + 1e-15)).item()

    expected = total / 10.0
    chi2 = torch.sum(((bc.float() - expected)**2) / expected).item()

    d1 = cuda_tensor[:-1]
    d2 = cuda_tensor[1:]
    pairs = d1 * 10 + d2
    trans = torch.bincount(pairs, minlength=100).reshape(10, 10).cpu().tolist()

    t_gpu = time.perf_counter() - t0

    return {
        "counts": counts,
        "total": total,
        "entropy": entropy,
        "chi2": chi2,
        "trans": trans,
        "t_gpu": t_gpu
    }


# ---------------------------------------------------------------------------
# Main Engine
# ---------------------------------------------------------------------------
def compute_pi_with_cockpit(digits, use_cockpit=True, use_gpu_stats=True):
    num_terms = int(math.ceil(digits / DIGITS_PER_TERM)) + 1
    guard_digits = 24
    total_prec = digits + guard_digits

    cockpit = ChudnovskyCockpit(digits, num_terms) if use_cockpit else None
    if cockpit:
        cockpit.start()

    t_start = time.perf_counter()

    try:
        # Stage 1: Binary Splitting
        t0 = time.perf_counter()
        P, Q, T = chudnovsky_bs_cockpit(0, num_terms, cockpit=cockpit)
        t_bs = time.perf_counter() - t0
        
        if cockpit:
            cockpit.q_bits = Q.bit_length()
            cockpit.t_bits = T.bit_length()
            cockpit.set_stage(2, duration=t_bs)

        # Stage 2: Square Root
        t1 = time.perf_counter()
        one = mpz(10)**(total_prec * 2)
        sqrt_10005 = isqrt(10005 * one)
        t_sqrt = time.perf_counter() - t1

        if cockpit:
            cockpit.set_stage(3, duration=t_sqrt)

        # Stage 3: Final Division
        t2 = time.perf_counter()
        numerator = mpz(426880) * sqrt_10005 * Q
        pi_int = numerator // T
        pi_int //= mpz(10)**guard_digits
        t_div = time.perf_counter() - t2

        # String conversion
        t3 = time.perf_counter()
        s = str(pi_int)
        pi_str = s[0] + "." + s[1:]
        t_str = time.perf_counter() - t3

        if cockpit:
            cockpit.set_stage(4, duration=t_div)

        # Stage 4: GPU Analytics
        gpu_stats = None
        t_gpu = 0.0
        if use_gpu_stats and HAS_CUDA:
            gpu_stats = run_gpu_analytics(pi_str)
            if gpu_stats:
                t_gpu = gpu_stats["t_gpu"]

        t_total = time.perf_counter() - t_start
        if cockpit:
            cockpit.set_stage(5, duration=t_gpu)
            cockpit.finish(t_total)

    finally:
        # Ensure cursor is restored even on error or interrupt
        sys.stdout.write("\033[?25h")
        sys.stdout.flush()

    stats = {
        "digits": digits,
        "terms": num_terms,
        "t_bs": t_bs,
        "t_sqrt": t_sqrt,
        "t_div": t_div,
        "t_str": t_str,
        "t_gpu": t_gpu,
        "t_total": t_total,
        "dps": digits / t_total if t_total > 0 else 0,
        "q_bits": Q.bit_length(),
        "t_bits": T.bit_length()
    }

    return pi_str, stats, gpu_stats


# ---------------------------------------------------------------------------
# Report & Benchmark
# ---------------------------------------------------------------------------
def print_final_report(stats, pi_str, gpu_stats=None):
    digits = stats["digits"]
    t_total = stats["t_total"]
    dps = stats["dps"]

    print(f"\n{C_BOLD}{C_CYAN}═══════════════════════════════════════════════════════════════════{C_RESET}")
    print(f"{C_BOLD}{C_GREEN}              ARRÊT PROPRE - RAPPORT DE PERFORMANCE                {C_RESET}")
    print(f"{C_BOLD}{C_CYAN}═══════════════════════════════════════════════════════════════════{C_RESET}")
    print(f"  Total décimales calculées : {C_BOLD}{C_WHITE}{digits:,}{C_RESET}")
    print(f"  Temps total d'exécution   : {C_BOLD}{C_GREEN}{t_total:.4f} s{C_RESET}")
    print(f"  Vitesse moyenne globale   : {C_BOLD}{C_YELLOW}{dps:,.0f} décimales/seconde{C_RESET}\n")
    print(f"  {C_CYAN}Chronométrie détaillée :{C_RESET}")
    print(f"    • [1] Binary Splitting      : {stats['t_bs']:.4f} s  ({stats['t_bs']/t_total*100:5.1f}%)")
    print(f"    • [2] Racine Carrée Newton  : {stats['t_sqrt']:.4f} s  ({stats['t_sqrt']/t_total*100:5.1f}%)")
    print(f"    • [3] Division Bignum       : {stats['t_div']:.4f} s  ({stats['t_div']/t_total*100:5.1f}%)")
    print(f"    • [4] Conversion Texte      : {stats['t_str']:.4f} s  ({stats['t_str']/t_total*100:5.1f}%)")
    if stats["t_gpu"] > 0:
        print(f"    • [5] Analyses GPU CUDA     : {stats['t_gpu']:.4f} s")
    print(f"  Taille des registres Q et T   : {stats['q_bits']:,} bits")

    if gpu_stats:
        print(f"\n  {C_BOLD}{C_CYAN}Télémétrie Statistique GPU ({GPU_NAME}) :{C_RESET}")
        print(f"    • Entropie de Shannon       : {C_BOLD}{gpu_stats['entropy']:.6f}{C_RESET} bits/chiffre (Théorique: {math.log2(10):.6f})")
        print(f"    • Test Uniformité Chi2      : {gpu_stats['chi2']:.2f} (9 DDL)")
        counts = gpu_stats["counts"]
        tot = gpu_stats["total"]
        h_lines = []
        for d in range(10):
            pct = (counts[d] / tot) * 100.0
            filled = min(8, max(0, int(round(pct / 1.5))))
            bar = f"{C_CYAN}{'■'*filled}{C_DIM}{'·'*(8-filled)}{C_RESET}"
            h_lines.append(f" {d}:[{bar}]{pct:4.1f}%")
        print(f"    • Distribution : " + "  ".join(h_lines[:5]))
        print(f"                     " + "  ".join(h_lines[5:]))

    print(f"\n  {C_BOLD}{C_CYAN}Aperçu des décimales générées :{C_RESET}")
    decimals = pi_str[2:]
    head = " ".join([decimals[:50][i:i+10] for i in range(0, min(50, len(decimals)), 10)])
    tail = " ".join([decimals[-50:][i:i+10] for i in range(0, min(50, len(decimals)), 10)])
    print(f"    3. {C_YELLOW}{head}{C_RESET}")
    if len(decimals) > 100:
        print(f"       ... [{len(decimals):,} décimales au total] ...")
        print(f"       {C_YELLOW}{tail}{C_RESET}")
    print(f"{C_BOLD}{C_CYAN}═══════════════════════════════════════════════════════════════════{C_RESET}\n")


def run_chudnovsky_benchmark():
    """
    Exécute un banc d'essai comparatif sur plusieurs ordres de grandeur.
    """
    benchmarks = [10_000, 100_000, 1_000_000, 5_000_000]
    print(f"\n{C_BOLD}{C_CYAN}═══════════════════════════════════════════════════════════════════════{C_RESET}")
    print(f"{C_BOLD}{C_GREEN}         BANC D'ESSAI COMPARATIF - ALGORITHME DE CHUDNOVSKY            {C_RESET}")
    print(f"{C_BOLD}{C_CYAN}═══════════════════════════════════════════════════════════════════════{C_RESET}\n")

    results = []
    for d in benchmarks:
        mil_label = f"{d / 1_000_000:.1f}M" if d >= 1_000_000 else f"{d // 1000}k"
        print(f"  ▶ Exécution pour {C_BOLD}{d:,}{C_RESET} décimales ({mil_label})...", end="", flush=True)
        _, stats, _ = compute_pi_with_cockpit(digits=d, use_cockpit=False, use_gpu_stats=False)
        results.append(stats)
        print(f" {C_GREEN}Terminé en {stats['t_total']:.4f} s{C_RESET} ({stats['dps']:,.0f} dps)")

    print(f"\n{C_BOLD}{C_CYAN}┌──────────────┬──────────────┬──────────────┬──────────────┬──────────────────┐{C_RESET}")
    print(f"{C_BOLD}{C_CYAN}│  Décimales   │   BS (s)     │   Sqrt (s)   │   Div (s)    │    Débit (dps)   │{C_RESET}")
    print(f"{C_BOLD}{C_CYAN}├──────────────┼──────────────┼──────────────┼──────────────┼──────────────────┤{C_RESET}")
    for s in results:
        d_str = f"{s['digits']:,}"
        print(f"│ {d_str:>12} │ {s['t_bs']:>10.4f} s │ {s['t_sqrt']:>10.4f} s │ {s['t_div']:>10.4f} s │ {s['dps']:>14,.0f} dps │")
    print(f"{C_BOLD}{C_CYAN}└──────────────┴──────────────┴──────────────┴──────────────┴──────────────────┘{C_RESET}\n")


# ---------------------------------------------------------------------------
# Invite Interactive Millions
# ---------------------------------------------------------------------------
def prompt_interactive_millions():
    print(f"\n{C_BOLD}{C_CYAN}╔═════════════════════════════════════════════════════════════════════════════════╗{C_RESET}")
    print(f"{C_BOLD}{C_CYAN}║     COCKPIT HAUTE PERFORMANCE DE PI - ALGORITHME DES FRÈRES CHUDNOVSKY         ║{C_RESET}")
    print(f"{C_BOLD}{C_CYAN}║           Moteur 32 Cœurs CPU (GMP AVX-512) + GPU NVIDIA RTX 5080 (CUDA)        ║{C_RESET}")
    print(f"{C_BOLD}{C_CYAN}╚═════════════════════════════════════════════════════════════════════════════════╝{C_RESET}\n")
    print(f"  {C_BOLD}Combien de millions de décimales de π souhaitez-vous calculer ?{C_RESET}\n")
    print(f"    • {C_CYAN}0.5{C_RESET}  ->    500 000 décimales  {C_DIM}(~0.15 seconde){C_RESET}")
    print(f"    • {C_GREEN}1{C_RESET}    ->  1 000 000 décimales  {C_DIM}(~0.35 seconde){C_RESET}  [Recommandé]")
    print(f"    • {C_YELLOW}2{C_RESET}    ->  2 000 000 décimales  {C_DIM}(~0.75 seconde){C_RESET}")
    print(f"    • {C_YELLOW}5{C_RESET}    ->  5 000 000 décimales  {C_DIM}(~2.10 secondes){C_RESET}")
    print(f"    • {C_MAGENTA}10{C_RESET}   -> 10 000 000 décimales  {C_DIM}(~4.80 secondes){C_RESET}")
    print(f"    • {C_RED}20{C_RESET}   -> 20 000 000 décimales  {C_DIM}(~11.0 secondes){C_RESET}")
    print(f"    • {C_RED}50{C_RESET}   -> 50 000 000 décimales  {C_DIM}(~30.0 secondes){C_RESET}\n")
    
    while True:
        try:
            val = input(f"  {C_BOLD}{C_WHITE}▶ Entrez le nombre de millions (ex: 1, 2, 5, 10) [défaut: 1] : {C_RESET}").strip()
            if not val:
                return 1.0
            val_float = float(val.replace(',', '.'))
            if val_float <= 0:
                print(f"  {C_RED}Veuillez entrer un nombre supérieur à 0.{C_RESET}")
                continue
            return val_float
        except (ValueError, EOFError, KeyboardInterrupt):
            print()
            return 1.0


# ---------------------------------------------------------------------------
# CLI Entry Point
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Moteur Chudnovsky avec Cockpit Temps Réel (GMP AVX-512 & CUDA)")
    parser.add_argument("--millions", type=float, default=None, help="Nombre de millions de décimales (ex: 1, 2.5, 5, 10)")
    parser.add_argument("--digits", type=int, default=None, help="Nombre exact de décimales")
    parser.add_argument("--benchmark", action="store_true", help="Lancer le banc d'essai comparatif")
    parser.add_argument("--cockpit", action="store_true", help="Activer le cockpit HUD interactif en direct")
    parser.add_argument("--no-cockpit", action="store_true", help="Désactiver le cockpit HUD")
    parser.add_argument("--gpu-stats", action="store_true", default=True, help="Activer les analyses statistiques sur RTX 5080")
    parser.add_argument("--output", type=str, default="pi_digits.txt", help="Fichier de sortie")
    parser.add_argument("--no-save", action="store_true", help="Ne pas sauvegarder le fichier de sortie")
    args = parser.parse_args()

    if args.benchmark:
        run_chudnovsky_benchmark()
        sys.exit(0)

    # Determine requested digits count
    if args.millions is None and args.digits is None:
        chosen_millions = prompt_interactive_millions()
        target_digits = max(100, int(chosen_millions * 1_000_000))
        show_cockpit = not args.no_cockpit
    else:
        if args.millions is not None:
            target_digits = max(100, int(args.millions * 1_000_000))
        else:
            target_digits = max(100, args.digits)
        show_cockpit = args.cockpit or (target_digits >= 500000 and not args.no_cockpit)

    pi_str, stats, gpu_stats = compute_pi_with_cockpit(
        digits=target_digits,
        use_cockpit=show_cockpit,
        use_gpu_stats=args.gpu_stats
    )

    print_final_report(stats, pi_str, gpu_stats=gpu_stats)

    if not args.no_save and args.output:
        with open(args.output, "w") as f:
            f.write(pi_str)
        print(f"  {C_GREEN}✔ {stats['digits']:,} décimales sauvegardées avec succès dans {args.output}{C_RESET}\n")
