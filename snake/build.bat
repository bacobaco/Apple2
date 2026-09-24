@echo off
cd /d "%~dp0"
echo ========================================================
echo   Compilation et injection des 4 Snakes pour Apple II
echo ========================================================
echo.

echo [1/5] Assemblage Snake HGR (280x192)...
64tass -b snake-hgr.asm -o snake-hgr.bin
if %ERRORLEVEL% NEQ 0 (
    echo [ERREUR] Echec de l'assemblage de snake-hgr.asm !
    exit /b %ERRORLEVEL%
)

echo [2/5] Assemblage Snake GR (40x40)...
64tass -b snake-gr.asm -o snake-gr.bin
if %ERRORLEVEL% NEQ 0 (
    echo [ERREUR] Echec de l'assemblage de snake-gr.asm !
    exit /b %ERRORLEVEL%
)

echo [3/5] Assemblage Snake Texte (40x24)...
64tass -b snake-txt.asm -o snake-txt.bin
if %ERRORLEVEL% NEQ 0 (
    echo [ERREUR] Echec de l'assemblage de snake-txt.asm !
    exit /b %ERRORLEVEL%
)

echo [4/5] Assemblage Snake Accel (KIMI)...
64tass -b snake_kimi.asm -o snake_kimi.bin
if %ERRORLEVEL% NEQ 0 (
    echo [ERREUR] Echec de l'assemblage de snake_kimi.asm !
    exit /b %ERRORLEVEL%
)

echo.
echo [5/5] Generation et injection disquette SNAKE.dsk ^& AI-ASM.DSK...
python build_disk.py
if %ERRORLEVEL% NEQ 0 (
    echo [ERREUR] Echec de la generation disquette !
    exit /b %ERRORLEVEL%
)

echo.
echo ========================================================
echo   Termine avec succes !
echo ========================================================
