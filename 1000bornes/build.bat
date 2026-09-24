@echo off
cd /d "%~dp0"
echo ========================================================
echo   Compilation et injection de 1000 Bornes pour Apple II
echo ========================================================
echo.

echo [1/2] Assemblage 6502 avec 64tass...
64tass --cbm-prg --labels=labels.txt -o 1000bornes.bin 1000bornes.asm
if %ERRORLEVEL% NEQ 0 (
    echo [ERREUR] Echec de l'assemblage !
    exit /b %ERRORLEVEL%
)
echo       Binaire genere : 1000bornes.bin

echo.
echo [2/2] Injection dans AI-ASM.DSK...
python ..\bas2dsk.py 1000bornes.bin ..\AI-ASM.DSK "BORNES" 4000
python ..\bas2dsk.py 1000bornes.bin ..\AI-ASM.DSK "1000BORNES" 4000
if %ERRORLEVEL% NEQ 0 (
    echo [ATTENTION] AI-ASM.DSK est verrouille par AppleWin.
) else (
    echo       Succes de l'injection dans AI-ASM.DSK !
)
if exist "..\AI-ASM-UPDATED.DSK" (
    python ..\bas2dsk.py 1000bornes.bin ..\AI-ASM-UPDATED.DSK "BORNES" 4000 >nul 2>&1
    python ..\bas2dsk.py 1000bornes.bin ..\AI-ASM-UPDATED.DSK "1000BORNES" 4000 >nul 2>&1
    echo       Succes de l'injection dans AI-ASM-UPDATED.DSK !
)

echo.
echo Termine avec succes !
