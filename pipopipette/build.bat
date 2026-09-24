@echo off
cd /d "%~dp0"
echo ========================================================
echo   Compilation et injection de Pipopipette pour Apple II
echo ========================================================
echo.

echo [1/2] Assemblage 6502 avec 64tass...
64tass -b pipopipette.asm -o pipopipette.bin
if %ERRORLEVEL% NEQ 0 (
    echo [ERREUR] Echec de l'assemblage !
    exit /b %ERRORLEVEL%
)
echo       Binaire genere : pipopipette.bin

echo.
echo [2/2] Injection dans AI-ASM.DSK...
python ..\bas2dsk.py pipopipette.bin ..\AI-ASM.DSK "PIPOPIPETTE" 6000
if %ERRORLEVEL% NEQ 0 (
    echo [ATTENTION] Impossible d'injecter dans AI-ASM.DSK
) else (
    echo       Succes de l'injection dans AI-ASM.DSK !
)

echo.
echo Termine avec succes !
