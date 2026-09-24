@echo off
cd /d "%~dp0"
echo ========================================================
echo   Compilation et injection de Pong pour Apple II
echo ========================================================
echo.

echo [1/2] Assemblage 6502 avec 64tass...
64tass -b pong.asm -o pong.bin
if %ERRORLEVEL% NEQ 0 (
    echo [ERREUR] Echec de l'assemblage de pong.asm !
    exit /b %ERRORLEVEL%
)
echo       Binaire genere : pong.bin

echo.
echo [2/2] Injection dans AI-ASM.DSK...
python ..\bas2dsk.py pong.bin ..\AI-ASM.DSK "PONG" 6000
if %ERRORLEVEL% NEQ 0 (
    echo [ATTENTION] Impossible d'injecter dans AI-ASM.DSK
) else (
    echo       Succes de l'injection dans AI-ASM.DSK !
)

echo.
echo Termine avec succes !
