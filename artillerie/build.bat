@echo off
cd /d "%~dp0"
echo ========================================================
echo   Compilation et injection de Duel d'Artillerie pour Apple II
echo ========================================================
echo.

echo [1/2] Assemblage 6502 avec 64tass...
64tass -b artillerie.asm -o artillerie.bin
if %ERRORLEVEL% NEQ 0 (
    echo [ERREUR] Echec de l'assemblage de artillerie.asm !
    exit /b %ERRORLEVEL%
)
echo       Binaire genere : artillerie.bin

echo.
echo [2/2] Injection dans AI-ASM.DSK...
python ..\bas2dsk.py artillerie.bin ..\AI-ASM.DSK "ARTILLERIE" 4000
if %ERRORLEVEL% NEQ 0 (
    echo [ATTENTION] Impossible d'injecter dans AI-ASM.DSK
) else (
    echo       Succes de l'injection dans AI-ASM.DSK !
)

echo.
echo Termine avec succes !
