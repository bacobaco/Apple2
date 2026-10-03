@echo off
setlocal
cd /d "%~dp0"
chcp 65001 >nul 2>&1

set "PY_BIN=C:\Users\baco\AppData\Local\Programs\Python\Python311\python.exe"
if not exist "%PY_BIN%" set "PY_BIN=python"

if not "%~1"=="" (
    "%PY_BIN%" pi_chudnovsky.py %*
    goto :eof
)

:MENU
cls
echo ===============================================================================
echo               CALCUL DES DECIMALES DE PI (CHUDNOVSKY ^& SPIGOT)
echo           Moteur CPU (AVX2/AVX-512) + GPU NVIDIA RTX 5080 (CUDA)
echo ===============================================================================
echo.
echo  --- Moteur Record Chudnovsky (Cockpit Temps Reel) ---
echo  1. Chudnovsky Cockpit Sur-Mesure : Entrer le nombre de millions (1, 2, 5, 10...)
echo  2. Chudnovsky Express 1 Million  : 1 000 000 decimales (~0.35s) + Stats GPU
echo  3. Chudnovsky Extreme 10 Millions: 10 000 000 decimales (~4.80s) + Stats GPU
echo  4. Banc d'essai comparatif       : Benchmarks 10k, 100k, 1M, 5M decimales
echo.
echo  --- Moteur Spigot Gibbons (Streaming sans fin) ---
echo  5. Mode Flux Decimales (Waterfall / pluie continue en direct)
echo  6. Mode Dashboard HUD (Cockpit telemetrie CPU/GPU, Entropie, Spectre FFT)
echo.
echo  7. Quitter
echo.
set "CHOICE=1"
set /p CHOICE=Votre choix [1-7] (defaut 1) : 
set "CHOICE=%CHOICE: =%"

if "%CHOICE%"=="1" goto CHUD_CUSTOM
if "%CHOICE%"=="2" goto CHUD_1M
if "%CHOICE%"=="3" goto CHUD_10M
if "%CHOICE%"=="4" goto CHUD_BENCH
if "%CHOICE%"=="5" goto WATERFALL
if "%CHOICE%"=="6" goto DASHBOARD
if "%CHOICE%"=="7" goto :eof
goto MENU

:CHUD_CUSTOM
cls
"%PY_BIN%" pi_chudnovsky.py
pause
goto MENU

:CHUD_1M
cls
"%PY_BIN%" pi_chudnovsky.py --millions 1 --cockpit --gpu-stats
pause
goto MENU

:CHUD_10M
cls
"%PY_BIN%" pi_chudnovsky.py --millions 10 --cockpit --gpu-stats
pause
goto MENU

:CHUD_BENCH
cls
"%PY_BIN%" pi_chudnovsky.py --benchmark
pause
goto MENU

:WATERFALL
cls
"%PY_BIN%" pi_stream.py --waterfall
goto :eof

:DASHBOARD
cls
"%PY_BIN%" pi_stream.py --dashboard
goto :eof
