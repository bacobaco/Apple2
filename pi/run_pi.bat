@echo off
setlocal
cd /d "%~dp0"

:: Auto-detect Python 3.11 with CUDA/PyTorch or system python
set "PY_BIN="
if exist "C:\Users\baco\AppData\Local\Programs\Python\Python311\python.exe" (
    set "PY_BIN=C:\Users\baco\AppData\Local\Programs\Python\Python311\python.exe"
) else (
    where py >nul 2>nul
    if %errorlevel% equ 0 (
        set "PY_BIN=py -3.11"
    ) else (
        set "PY_BIN=python"
    )
)

:: If command line arguments were provided, pass directly to pi_stream.py
if not "%~1"=="" (
    "%PY_BIN%" pi_stream.py %*
    goto :eof
)

:MENU
cls
echo ===============================================================================
echo      CALCUL SANS FIN DES DECIMALES DE PI (SPIGOT CONTINUED FRACTION)
echo        Moteur 32-Coeurs CPU (AVX2/AVX-512) + GPU NVIDIA RTX 5080 (CUDA)
echo ===============================================================================
echo.
echo  1. Mode Flux Decimales (Waterfall / chute continue en direct)
echo  2. Mode Dashboard HUD (Cockpit de telemetrie CPU/GPU, Entropie, Stats)
echo  3. Benchmark Express (Calcul et verification de 50 000 decimales)
echo  4. Benchmark Elite (Calcul et verification de 100 000 decimales)
echo  5. Quitter
echo.
set /p CHOICE="Votre choix [1-5] (defaut: 1) : "

if "%CHOICE%"=="2" goto DASHBOARD
if "%CHOICE%"=="3" goto BENCH50K
if "%CHOICE%"=="4" goto BENCH100K
if "%CHOICE%"=="5" goto :eof

:WATERFALL
cls
"%PY_BIN%" pi_stream.py --waterfall
goto :eof

:DASHBOARD
cls
"%PY_BIN%" pi_stream.py --dashboard
goto :eof

:BENCH50K
cls
echo Demarrage du Benchmark 50 000 decimales...
"%PY_BIN%" pi_stream.py --digits 50000 --waterfall
pause
goto :eof

:BENCH100K
cls
echo Demarrage du Benchmark 100 000 decimales...
"%PY_BIN%" pi_stream.py --digits 100000 --waterfall
pause
goto :eof
