"""
================================================================================
             UNBOUNDED STREAMING SPIGOT FOR PI (GIBBONS LFT ALGORITHM)
      High-Throughput Spigot Engine & Real-Time NVIDIA RTX 5080 GPU Analytics
================================================================================
Algorithme exact : Spigot sans fin de Jeremy Gibbons / Fraction continue de Lambert
LFT Matrix   : M_k = [[k, 4k + 2], [0, 2k + 1]]
State Matrix : S   = [[q, r], [0, t]], initialisé à q=1, r=0, t=1, k=1
Extraction   : Bloc de m chiffres décimaux via U = floor(10^(m-1)*(3q+r)/t) == floor(10^(m-1)*(4q+r)/t)
Update       : q <- 10^m * q,  r <- 10*(10^(m-1)*r - U*t)
Absorption   : S <- S * M_k (optimisé par Binary Splitting divide-and-conquer & simplification GCD)
Analytics    : Moteur d'analyse statistique temps réel sur GPU RTX 5080 (CUDA) :
               Entropie de Shannon, Test Chi2, Matrice de transition 10x10,
               Analyse spectrale CUDA FFT, et Marche aléatoire 2D.
================================================================================
"""

import sys
import os
import time
import math
import threading
import queue
import warnings

warnings.filterwarnings('ignore')

# Set console code page to UTF-8 on Windows
if sys.platform == "win32":
    try:
        os.system("chcp 65001 >nul 2>&1")
    except Exception:
        pass

# Disable integer string conversion limit in Python 3.11+
if hasattr(sys, 'set_int_max_str_digits'):
    sys.set_int_max_str_digits(0)

# Tuned GIL switch interval (5ms is balanced, avoids thread contention)
sys.setswitchinterval(0.005)

# Ensure UTF-8 output on console
if hasattr(sys.stdout, 'reconfigure'):
    try:
        sys.stdout.reconfigure(encoding='utf-8', errors='replace')
        sys.stderr.reconfigure(encoding='utf-8', errors='replace')
    except Exception:
        pass

# Non-blocking keyboard input for Windows
try:
    import msvcrt
    HAS_MSVCRT = True
except ImportError:
    HAS_MSVCRT = False

# High-precision GNU MP / gmpy2 support
try:
    import gmpy2
    mpz = gmpy2.mpz
    gcd = gmpy2.gcd
    HAS_GMPY2 = True
except ImportError:
    import math
    mpz = int
    gcd = math.gcd
    HAS_GMPY2 = False

# PyTorch CUDA GPU support (RTX 5080)
try:
    import torch
    HAS_TORCH = True
    HAS_CUDA = torch.cuda.is_available()
    CUDA_DEVICE = torch.device('cuda:0') if HAS_CUDA else None
    GPU_NAME = torch.cuda.get_device_name(0) if HAS_CUDA else "None"
except ImportError:
    HAS_TORCH = False
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


# ANSI Color Codes for terminal UI
C_RESET   = "\033[0m"
C_BOLD    = "\033[1m"
C_DIM     = "\033[2m"
C_GREEN   = "\033[92m"
C_CYAN    = "\033[96m"
C_YELLOW  = "\033[93m"
C_RED     = "\033[91m"
C_MAGENTA = "\033[95m"
C_WHITE   = "\033[97m"


# ---------------------------------------------------------------------------
# Matrix Operations for LFT Gibbons Continued Fraction
# ---------------------------------------------------------------------------
def leaf_matrix(k):
    """Generate term matrix M_k = [[k, 4k+2], [0, 2k+1]]."""
    return (mpz(k), mpz(4 * k + 2), mpz(2 * k + 1))

def mul_mat(M1, M2):
    """Multiply two upper-triangular 2x2 matrices."""
    a1, b1, d1 = M1
    a2, b2, d2 = M2
    return (a1 * a2, a1 * b2 + b1 * d2, d1 * d2)

def tree_product(k_start, k_end):
    """Divide-and-conquer binary-splitting product of term matrices M_k."""
    count = k_end - k_start
    if count == 1:
        return leaf_matrix(k_start)
    if count == 2:
        s1 = k_start
        s2 = k_start + 1
        return (mpz(s1) * mpz(s2),
                mpz(s1) * mpz(4 * s2 + 2) + mpz(4 * s1 + 2) * mpz(2 * s2 + 1),
                mpz(2 * s1 + 1) * mpz(2 * s2 + 1))
    mid = k_start + (count >> 1)
    return mul_mat(tree_product(k_start, mid), tree_product(mid, k_end))


# ---------------------------------------------------------------------------
# Real-Time GPU Analytics Engine (PyTorch CUDA on RTX 5080)
# ---------------------------------------------------------------------------
class GPUAnalyticsEngine:
    """
    Asynchronous Real-Time GPU Analytics Engine for streaming Pi digits on NVIDIA RTX 5080.
    Executes vectorized tensor bincount, Shannon entropy, Chi-2 uniformity test,
    Markov transition matrix, CUDA FFT spectral analysis, and 2D random walk trajectory.
    Operates on a dedicated background worker without artificial burn loops.
    """
    def __init__(self):
        self.enabled = HAS_CUDA
        self.lock = threading.Lock()
        self.counts = [0] * 10
        self.entropy = 0.0
        self.chi2 = 0.0
        self.walk_x = 0.0
        self.walk_y = 0.0
        self.disp = 0.0
        self.spectral_peak = 0.0
        self.total_analyzed = 0
        self.work_queue = queue.Queue(maxsize=100)
        self.stop_event = threading.Event()
        self.gpu_thread = None

        if self.enabled:
            self._start_gpu_worker()

    def _start_gpu_worker(self):
        def _gpu_loop():
            try:
                torch.cuda.set_device(CUDA_DEVICE)
                stream = torch.cuda.Stream()
                with torch.cuda.stream(stream):
                    while not self.stop_event.is_set():
                        try:
                            batch = self.work_queue.get(timeout=0.05)
                        except queue.Empty:
                            continue

                        if not batch:
                            continue

                        # Drain additional queued batches to process collectively
                        combined = list(batch)
                        while not self.work_queue.empty():
                            try:
                                combined.extend(self.work_queue.get_nowait())
                            except queue.Empty:
                                break

                        try:
                            t_batch = torch.tensor(combined, dtype=torch.int64, device=CUDA_DEVICE)
                            bc = torch.bincount(t_batch, minlength=10).cpu().tolist()

                            # 2D Random Walk step vector
                            angles = t_batch.float() * (2.0 * math.pi / 10.0)
                            dx = torch.sum(torch.cos(angles)).item()
                            dy = torch.sum(torch.sin(angles)).item()

                            # Spectral FFT analysis (look for harmonic peaks in recent window)
                            spec_peak = 0.0
                            if len(combined) >= 128:
                                sig = (t_batch.float() - 4.5)
                                fft_vals = torch.abs(torch.fft.rfft(sig))
                                if len(fft_vals) > 2:
                                    spec_peak = torch.max(fft_vals[1:]).item()

                            with self.lock:
                                for i in range(10):
                                    self.counts[i] += bc[i]
                                self.total_analyzed += len(combined)
                                self.walk_x += dx
                                self.walk_y += dy
                                self.disp = math.sqrt(self.walk_x**2 + self.walk_y**2)
                                if spec_peak > 0:
                                    self.spectral_peak = spec_peak

                                tot = self.total_analyzed
                                if tot > 50:
                                    probs = [c / tot for c in self.counts]
                                    self.entropy = -sum(p * math.log2(p + 1e-15) for p in probs if p > 0)
                                    exp = tot / 10.0
                                    self.chi2 = sum(((c - exp) ** 2) / exp for c in self.counts)
                        except Exception:
                            pass
            except Exception:
                pass

        self.gpu_thread = threading.Thread(target=_gpu_loop, daemon=True)
        self.gpu_thread.start()

    def process_batch(self, digit_batch):
        if not digit_batch:
            return
        if not self.enabled:
            with self.lock:
                for d in digit_batch:
                    self.counts[d] += 1
                self.total_analyzed += len(digit_batch)
                tot = self.total_analyzed
                if tot > 50:
                    probs = [c / tot for c in self.counts]
                    self.entropy = -sum(p * math.log2(p + 1e-15) for p in probs if p > 0)
                    exp = tot / 10.0
                    self.chi2 = sum(((c - exp) ** 2) / exp for c in self.counts)
            return

        try:
            self.work_queue.put_nowait(digit_batch)
        except queue.Full:
            pass

    def stop(self):
        self.stop_event.set()
        if self.gpu_thread:
            self.gpu_thread.join(timeout=0.5)

    def get_stats(self):
        with self.lock:
            return {
                "counts": list(self.counts),
                "total": self.total_analyzed,
                "entropy": self.entropy,
                "chi2": self.chi2,
                "walk": (self.walk_x, self.walk_y),
                "disp": self.disp,
                "spectral_peak": self.spectral_peak
            }


# ---------------------------------------------------------------------------
# Hardware Telemetry (Real CPU & NVIDIA NVML)
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
# Interactive Keyboard Handler
# ---------------------------------------------------------------------------
def check_key():
    """Returns character pressed, or None if no key."""
    if HAS_MSVCRT and msvcrt.kbhit():
        ch = msvcrt.getch()
        if ch == b'\xe0':
            msvcrt.getch()
            return None
        try:
            return ch.decode('utf-8', errors='ignore')
        except Exception:
            if ch == b'\x1b':
                return 'ESC'
    return None


# ---------------------------------------------------------------------------
# Live Terminal HUD Dashboard
# ---------------------------------------------------------------------------
def render_dashboard(decimals_count, speed_curr, speed_peak, elapsed, bit_size, k_terms,
                     telem, gpu_stats, recent_digits, is_paused):
    sys.stdout.write("\033[H")
    
    # Title Bar
    title = (
        f"{C_BOLD}{C_GREEN}╔══════════════════════════════════════════════════════════════════════════════════╗{C_RESET}\033[K\n"
        f"{C_BOLD}{C_GREEN}║     UNBOUNDED PI SPIGOT STREAM - MULTI-CORE CPU (GMP) & RTX 5080 CUDA ACCEL.     ║{C_RESET}\033[K\n"
        f"{C_BOLD}{C_GREEN}╚══════════════════════════════════════════════════════════════════════════════════╝{C_RESET}\033[K\n"
    )

    # Status & Speed
    status_str = f"{C_YELLOW}[EN PAUSE - Appuyez sur ESPACE pour reprendre]{C_RESET}" if is_paused else f"{C_GREEN}[EN COURS - STREAMING ACTIF]{C_RESET}"
    
    metrics = (
        f"  {C_CYAN}Statut          :{C_RESET} {status_str}\033[K\n"
        f"  {C_CYAN}Décimales       :{C_RESET} {C_BOLD}{C_WHITE}{decimals_count:,}{C_RESET} chiffres après la virgule\033[K\n"
        f"  {C_CYAN}Vitesse Actuelle:{C_RESET} {C_BOLD}{C_GREEN}{speed_curr:,.0f}{C_RESET} décimales/sec (Pic: {C_BOLD}{C_YELLOW}{speed_peak:,.0f}{C_RESET} dps)\033[K\n"
        f"  {C_CYAN}Temps Écoulé    :{C_RESET} {elapsed:.2f} s  |  {C_CYAN}Termes LFT (k) :{C_RESET} {k_terms:,}\033[K\n"
        f"  {C_CYAN}Taille Registres:{C_RESET} {bit_size:,} bits (précision q, r, t optimisée GCD)\033[K\n"
    )

    # Hardware Telemetry Bar
    cpu_bar_len = min(20, max(0, int(telem["cpu_pct"] / 5)))
    cpu_bar = "█" * cpu_bar_len + "░" * (20 - cpu_bar_len)
    
    gpu_bar_len = min(20, max(0, int(telem["gpu_util"] / 5)))
    gpu_bar = "█" * gpu_bar_len + "░" * (20 - gpu_bar_len)

    hw_info = (
        f"{C_BOLD}{C_CYAN}─────────────────────────── TÉLÉMÉTRIE MATÉRIELLE ───────────────────────────{C_RESET}\033[K\n"
        f"  {C_BOLD}CPU (Système)   :{C_RESET} [{C_GREEN}{cpu_bar}{C_RESET}] {telem['cpu_pct']:5.1f}%  | RAM Process: {telem['ram_used_mb']} MB\033[K\n"
        f"  {C_BOLD}GPU ({GPU_NAME[:15]}):{C_RESET} [{C_MAGENTA}{gpu_bar}{C_RESET}] {telem['gpu_util']:5.1f}%  | VRAM: {telem['gpu_vram_used']}/{telem['gpu_vram_total']} MB | Temp: {telem['gpu_temp']}°C\033[K\n"
    )

    # GPU Analytics (Shannon entropy, Chi2, Random walk, Spectral, Histogram)
    total_d = gpu_stats["total"]
    dist_str = ""
    if total_d > 0:
        counts = gpu_stats["counts"]
        lines = []
        for d in range(10):
            pct = (counts[d] / total_d) * 100.0
            filled = min(12, max(0, int(round(pct))))
            bar_visual = f"{C_CYAN}{'■' * filled}{C_DIM}{'·' * (12 - filled)}{C_RESET}"
            lines.append(f"  {d}: [{bar_visual}] {pct:4.1f}% ({counts[d]:>7,})")
        col1 = lines[:5]
        col2 = lines[5:]
        dist_str = "\n".join(f"{c1}  │  {c2}\033[K" for c1, c2 in zip(col1, col2))

    entropy_val = gpu_stats["entropy"]
    chi2_val = gpu_stats["chi2"]
    disp_val = gpu_stats.get("disp", 0.0)
    spec_val = gpu_stats.get("spectral_peak", 0.0)
    analytics_info = (
        f"{C_BOLD}{C_CYAN}──────────────────────── ANALYSES GPU EN TEMPS RÉEL ─────────────────────────{C_RESET}\033[K\n"
        f"  Entropie Shannon : {C_BOLD}{entropy_val:.5f}{C_RESET} bits/chiffre (Max théorique: {math.log2(10):.5f})\033[K\n"
        f"  Test Uniformité  : Chi2 = {chi2_val:.2f} (9 DDL)  │  Dispersion 2D : R = {disp_val:.1f}\033[K\n"
        f"  Spectre CUDA FFT : Pic Harmonique = {spec_val:.1f} (bruit blanc attendu)\033[K\n"
        f"{dist_str}\033[K\n"
    )

    # Recent Digits Preview
    recent_formatted = ""
    if recent_digits:
        tail = recent_digits[-100:]
        recent_formatted = "  ... " + " ".join([tail[i:i+10] for i in range(0, len(tail), 10)])

    preview_info = (
        f"{C_BOLD}{C_CYAN}────────────────────── DERNIÈRES DÉCIMALES GÉNÉRÉES ───────────────────────{C_RESET}\033[K\n"
        f"{C_YELLOW}{recent_formatted:<80}{C_RESET}\033[K\n"
        f"{C_BOLD}{C_CYAN}─────────────────────────────────────────────────────────────────────────────{C_RESET}\033[K\n"
        f"  [ESPACE] Pause/Reprise  │  [M] Mode Flux/Dashboard  │  [S] Sauvegarder  │  [ESC/Q] Quitter\033[K\n"
    )

    output = title + metrics + hw_info + analytics_info + preview_info
    sys.stdout.write(output)
    sys.stdout.flush()


# ---------------------------------------------------------------------------
# Main Infinite Streaming Spigot Loop (Ultra-Optimized)
# ---------------------------------------------------------------------------
def run_streaming_spigot(display_mode="waterfall", digit_limit=None):
    """
    Main infinite loop (or bounded if digit_limit is specified).
    display_mode: 'waterfall' (continuous streaming rain) or 'dashboard' (HUD telemetry)
    """
    # Initialize LFT state variables (Gibbons algorithm)
    q = mpz(1)
    r = mpz(0)
    t = mpz(1)
    k = 1

    all_digits = []
    recent_digits_str = ""

    gpu_engine = GPUAnalyticsEngine()

    # Lookahead Pipeline for continuous background matrix generation
    matrix_queue = queue.Queue(maxsize=6)
    stop_producer = False

    def producer_loop():
        cur_k = 1
        cur_bsize = 128
        try:
            while not stop_producer:
                dec_count = max(0, len(all_digits) - 1)
                if dec_count > 100000:
                    cur_bsize = 2048
                elif dec_count > 20000:
                    cur_bsize = 1024
                elif dec_count > 5000:
                    cur_bsize = 512
                elif dec_count > 1000:
                    cur_bsize = 256

                mat = tree_product(cur_k, cur_k + cur_bsize)
                matrix_queue.put((cur_k, cur_bsize, mat))
                cur_k += cur_bsize
        except Exception:
            pass

    prod_thread = threading.Thread(target=producer_loop, daemon=True)
    prod_thread.start()

    # Performance tracking
    t_start = time.perf_counter()
    t_last_metric = t_start
    digits_last_metric = 0
    speed_curr = 0.0
    speed_peak = 0.0
    
    is_paused = False
    mode = display_mode
    step_absorb_count = 0
    
    # Clear console and setup ANSI
    os.system("")
    sys.stdout.write("\033[2J\033[H")
    sys.stdout.flush()

    if mode == "waterfall":
        print(f"{C_BOLD}{C_GREEN}=== GÉNÉRATEUR SANS FIN DE DÉCIMALES DE PI (GIBBONS LFT) ==={C_RESET}")
        print(f"{C_CYAN}Moteur : Multi-Cœur CPU (GMP AVX2/AVX-512) + GPU {GPU_NAME} (CUDA){C_RESET}")
        print(f"{C_YELLOW}[ESPACE] = Pause/Reprise  |  [M] = Mode Dashboard  |  [S] = Sauvegarde  |  [ESC] = Quitter{C_RESET}\n")
        sys.stdout.write("3.")
        sys.stdout.flush()

    waterfall_buf = []
    waterfall_printed = 0
    batch_buffer = []
    
    try:
        while True:
            decimals_count = max(0, len(all_digits) - 1)
            if digit_limit and decimals_count >= digit_limit:
                break

            # 1. Handle user keyboard input
            key = check_key()
            if key:
                if key in ('\x1b', 'ESC', 'q', 'Q'):
                    break
                elif key == ' ':
                    is_paused = not is_paused
                    if is_paused:
                        if mode == "waterfall":
                            sys.stdout.write(f"\n{C_YELLOW}>>> EN PAUSE (Appuyez sur ESPACE pour continuer)<<<{C_RESET}\n")
                            sys.stdout.flush()
                elif key in ('m', 'M'):
                    mode = "dashboard" if mode == "waterfall" else "waterfall"
                    sys.stdout.write("\033[2J\033[H")
                    sys.stdout.flush()
                    if mode == "waterfall":
                        sys.stdout.write(f"\n{C_CYAN}>>> Mode Flux Décimales Actif <<<{C_RESET}\n")
                elif key in ('s', 'S'):
                    filename = "pi_digits.txt"
                    with open(filename, "w") as f:
                        if len(all_digits) > 1:
                            f.write("3." + "".join(map(str, all_digits[1:])))
                    if mode == "waterfall":
                        sys.stdout.write(f"\n{C_GREEN}>>> {decimals_count:,} décimales sauvegardées dans {filename} <<<{C_RESET}\n")
                    sys.stdout.flush()

            if is_paused:
                time.sleep(0.05)
                continue

            # 2. Extract digits (High-Throughput Block & Single Extraction)
            while True:
                ratio = t // q
                if ratio > 1:
                    m = max(1, int((ratio.bit_length() - 4) * 0.301029995))
                    if m > 1:
                        if m > 256:
                            m = 256
                        if digit_limit:
                            cur_dec = max(0, len(all_digits) - 1)
                            if cur_dec + m > digit_limit:
                                m = max(1, digit_limit - cur_dec)

                        p10_prev = mpz(10)**(m - 1)
                        u = (p10_prev * (3 * q + r)) // t
                        v = (p10_prev * (4 * q + r)) // t
                        if u == v:
                            s = str(u)
                            if len(s) < m:
                                s = '0' * (m - len(s)) + s
                            block_digits = [int(c) for c in s]
                            
                            is_first_block = (len(all_digits) == 0)
                            all_digits.extend(block_digits)

                            # First digit ever extracted is the integer unit '3'
                            if is_first_block:
                                decimals_to_emit = block_digits[1:]
                            else:
                                decimals_to_emit = block_digits

                            batch_buffer.extend(decimals_to_emit)

                            p10 = p10_prev * 10
                            r = p10 * r - 10 * u * t
                            q = p10 * q

                            if mode == "waterfall":
                                waterfall_buf.extend(decimals_to_emit)
                                while len(waterfall_buf) >= 50:
                                    chunk = waterfall_buf[:50]
                                    waterfall_buf = waterfall_buf[50:]
                                    waterfall_printed += 50
                                    line_str = "".join(map(str, chunk))
                                    formatted_line = " ".join([line_str[i:i+10] for i in range(0, 50, 10)])
                                    sys.stdout.write(f"\r  {formatted_line}   [{waterfall_printed:>8,}]  ({speed_curr:>8,.0f} dps)\n")
                                    sys.stdout.flush()

                            if digit_limit and max(0, len(all_digits) - 1) >= digit_limit:
                                break
                            continue

                # Fallback to exact single-digit extraction
                u = (3 * q + r) // t
                v = (4 * q + r) // t
                if u == v:
                    d = int(u)
                    is_first_digit = (len(all_digits) == 0)
                    all_digits.append(d)

                    r = 10 * (r - d * t)
                    q = 10 * q

                    if not is_first_digit:
                        batch_buffer.append(d)
                        if mode == "waterfall":
                            waterfall_buf.append(d)
                            while len(waterfall_buf) >= 50:
                                chunk = waterfall_buf[:50]
                                waterfall_buf = waterfall_buf[50:]
                                waterfall_printed += 50
                                line_str = "".join(map(str, chunk))
                                formatted_line = " ".join([line_str[i:i+10] for i in range(0, 50, 10)])
                                sys.stdout.write(f"\r  {formatted_line}   [{waterfall_printed:>8,}]  ({speed_curr:>8,.0f} dps)\n")
                                sys.stdout.flush()

                    if digit_limit and max(0, len(all_digits) - 1) >= digit_limit:
                        break
                else:
                    break

            decimals_count = max(0, len(all_digits) - 1)
            if digit_limit and decimals_count >= digit_limit:
                break

            # 3. Absorb next block from lookahead producer queue
            blk_k, blk_sz, (A, B, D) = matrix_queue.get()
            k = blk_k + blk_sz
            step_absorb_count += 1

            # Multiply LFT state S <- S * M_block
            qA = q * A
            r = q * B + r * D
            q = qA
            t = t * D

            # Periodic GCD reduction to eliminate accumulated common factors
            if step_absorb_count % 16 == 0:
                g = gcd(q, gcd(r, t))
                if g > 1:
                    q //= g
                    r //= g
                    t //= g

            # 4. Periodically feed GPU Analytics & Refresh Dashboard
            now = time.perf_counter()
            dt = now - t_last_metric
            if dt >= 0.10 or len(batch_buffer) >= 2000:
                if batch_buffer:
                    recent_digits_str += "".join(map(str, batch_buffer))
                    if len(recent_digits_str) > 200:
                        recent_digits_str = recent_digits_str[-200:]
                    gpu_engine.process_batch(list(batch_buffer))
                    batch_buffer.clear()

                cur_dec = max(0, len(all_digits) - 1)
                curr_dps = (cur_dec - digits_last_metric) / dt if dt > 0 else 0
                speed_curr = 0.7 * speed_curr + 0.3 * curr_dps if speed_curr > 0 else curr_dps
                if speed_curr > speed_peak:
                    speed_peak = speed_curr

                t_last_metric = now
                digits_last_metric = cur_dec

                if mode == "dashboard":
                    telem = get_hardware_telemetry()
                    gpu_stats = gpu_engine.get_stats()
                    elapsed = now - t_start
                    bit_size = t.bit_length()
                    render_dashboard(
                        decimals_count=cur_dec,
                        speed_curr=speed_curr,
                        speed_peak=speed_peak,
                        elapsed=elapsed,
                        bit_size=bit_size,
                        k_terms=k,
                        telem=telem,
                        gpu_stats=gpu_stats,
                        recent_digits=recent_digits_str,
                        is_paused=is_paused
                    )

    except KeyboardInterrupt:
        pass
    finally:
        stop_producer = True
        gpu_engine.stop()

    # Flush any remaining decimals in waterfall buffer
    if mode == "waterfall" and waterfall_buf:
        chunk = waterfall_buf
        waterfall_printed += len(chunk)
        line_str = "".join(map(str, chunk))
        formatted_line = " ".join([line_str[i:i+10] for i in range(0, len(line_str), 10)])
        sys.stdout.write(f"\r  {formatted_line:<59}   [{waterfall_printed:>8,}]  ({speed_curr:>8,.0f} dps)\n")
        sys.stdout.flush()

    total_decimals = max(0, len(all_digits) - 1)
    t_total = time.perf_counter() - t_start
    avg_speed = total_decimals / t_total if t_total > 0 else 0

    # Auto-save on exit
    if len(all_digits) > 1:
        with open("pi_digits.txt", "w") as f:
            f.write("3." + "".join(map(str, all_digits[1:])))

    print(f"\n\n{C_BOLD}{C_CYAN}═══════════════════════════════════════════════════════════════════{C_RESET}")
    print(f"{C_BOLD}{C_GREEN}              ARRÊT PROPRE - RAPPORT DE PERFORMANCE                {C_RESET}")
    print(f"{C_BOLD}{C_CYAN}═══════════════════════════════════════════════════════════════════{C_RESET}")
    print(f"  Total décimales calculées : {C_BOLD}{total_decimals:,}{C_RESET}")
    print(f"  Temps total d'exécution   : {t_total:.3f} secondes")
    print(f"  Vitesse moyenne globale   : {C_BOLD}{C_YELLOW}{avg_speed:,.0f} décimales/seconde{C_RESET}")
    print(f"  Vitesse de pointe (Peak)  : {C_BOLD}{C_GREEN}{speed_peak:,.0f} décimales/seconde{C_RESET}")
    print(f"  Termes de fractions (k)   : {k:,}")
    print(f"  Fichier de sortie         : {C_WHITE}pi_digits.txt{C_RESET}")
    print(f"{C_BOLD}{C_CYAN}═══════════════════════════════════════════════════════════════════{C_RESET}\n")

    return all_digits


# ---------------------------------------------------------------------------
# CLI Entry Point
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Unbounded Streaming Pi Spigot (Gibbons LFT Algorithm)")
    parser.add_argument("--waterfall", action="store_true", help="Start in waterfall digit stream mode")
    parser.add_argument("--dashboard", action="store_true", help="Start in HUD telemetry dashboard mode")
    parser.add_argument("--digits", type=int, default=None, help="Stop after calculating N decimals")
    args = parser.parse_args()

    mode = "waterfall"
    if args.dashboard:
        mode = "dashboard"

    run_streaming_spigot(display_mode=mode, digit_limit=args.digits)
