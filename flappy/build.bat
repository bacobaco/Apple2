@echo off
cd /d "%~dp0"
echo ========================================================
echo   Compilation et injection des Flappy Birds pour Apple II
echo ========================================================
echo.

echo [1/3] Assemblage Flappy Bird (Parallax HGR)...
64tass -b flappy.asm -o flappy.bin
if %ERRORLEVEL% NEQ 0 (
    echo [ERREUR] Echec de l'assemblage de flappy.asm !
    exit /b %ERRORLEVEL%
)
echo       Binaire genere : flappy.bin

echo [2/3] Assemblage Happy Bird (HGR Double Buffering)...
64tass -b happybird.asm -o happybird.bin
if %ERRORLEVEL% NEQ 0 (
    echo [ERREUR] Echec de l'assemblage de happybird.asm !
    exit /b %ERRORLEVEL%
)
echo       Binaire genere : happybird.bin

echo.
echo [3/3] Injection dans AI-ASM.DSK...
python ..\bas2dsk.py flappy.bin ..\AI-ASM.DSK "FLAPPY" 0803
if %ERRORLEVEL% NEQ 0 (
    echo [ATTENTION] Impossible d'injecter FLAPPY dans AI-ASM.DSK
)
python ..\bas2dsk.py happybird.bin ..\AI-ASM.DSK "HAPPYBIRD" 6000
if %ERRORLEVEL% NEQ 0 (
    echo [ATTENTION] Impossible d'injecter HAPPYBIRD dans AI-ASM.DSK
)

echo.
echo Termine avec succes !
