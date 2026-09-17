@echo off
echo ===============================================================
echo                   INSTALLATION DE DCMOTO
echo ===============================================================
echo.
echo.Concatenation des deux fichiers .dat pour creer le fichier .exe
echo.
copy /b dcmoto-??_????????_1.dat+dcmoto-??_????????_2.dat dcmoto-??_????????.exe
echo.
echo Apres verification du bon fonctionnement de l'emulateur vous
echo pouvez supprimer les deux fichiers .dat et le fichier .bat 
echo.
echo ===============================================================
echo.
pause
