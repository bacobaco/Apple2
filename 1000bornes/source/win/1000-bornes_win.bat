copy /b 1000-bornes_win_1.dat+1000-bornes_win_2.dat 1000-bornes_win.exe
del 1000-bornes_win_1.dat
del 1000-bornes_win_2.dat
start 1000-bornes_win.exe
start cmd /c del 1000-bornes_win.bat
