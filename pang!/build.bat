@echo off
cd /d "%~dp0"
echo ========================================================
echo   Compilation et injection de Pang! dans AI-ASM.DSK
echo ========================================================
echo.

if not exist pang.asm (
    echo [INFO] Aucun fichier pang.asm detecte.
    exit /b 1
)

echo [1/2] Assemblage 6502 avec 64tass...
64tass -b pang.asm -o pang.bin
if %ERRORLEVEL% NEQ 0 (
    echo [ERREUR] Echec de l'assemblage de pang.asm !
    exit /b %ERRORLEVEL%
)
echo       Binaire genere : pang.bin

echo.
echo [2/2] Injection dans ..\AI-ASM.DSK...
python ..\bas2dsk.py pang.bin ..\AI-ASM.DSK "PANG" 6000
if %ERRORLEVEL% NEQ 0 (
    echo [ATTENTION] Impossible d'injecter dans ..\AI-ASM.DSK !
    echo             Verifiez qu'AppleWin ne verrouille pas la disquette.
    exit /b %ERRORLEVEL%
) else (
    echo       Succes de l'injection dans AI-ASM.DSK !
)

echo.
echo Termine avec succes !
