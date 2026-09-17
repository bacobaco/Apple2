@echo off
echo ========================================================
echo   Compilation et injection de Space Invaders pour Apple II
echo ========================================================
echo.

echo [1/2] Assemblage 6502 avec 64tass...
64tass -b invaders.asm -o invaders.bin
if %ERRORLEVEL% NEQ 0 (
    echo [ERREUR] Echec de l'assemblage de invaders.asm !
    exit /b %ERRORLEVEL%
)
echo       Binaire genere : invaders.bin

echo.
echo [2/2] Injection dans AI-ASM.DSK...
python ..\bas2dsk.py invaders.bin ..\AI-ASM.DSK "INVADERS" 6000
if %ERRORLEVEL% NEQ 0 (
    echo [ATTENTION] Impossible d'injecter dans AI-ASM.DSK
) else (
    echo       Succes de l'injection dans AI-ASM.DSK !
)

echo.
echo Termine avec succes !
