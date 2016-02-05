rem ****
rem **** Compiles CHESSY2K.COM
rem ****  Chess games replays from PGN files
rem ****

echo #define PGN_COMPILE 1 >options.asm

TASM -80 -b ChessPI.ASM DSK\ChessPI.CO2 ChessPI.EXP
texp ChessPI.EXP
TASM -80 -b ChessY2K.ASM DSK\ChessY2K.COM ChessY2K.EXP
texp ChessY2K.EXP
TASM -80 -b ChessPG.ASM DSK\ChessPG.CO2 ChessPG.EXP
texp ChessPG.EXP

rem ****
rem **** Compiles CHESSPZ.COM
rem ****  Chess movements and position setup
rem ****

echo.>options.asm
TASM -80 -b ChessY2K.ASM DSK\ChessPZ.COM ChessPZ.EXP
texp ChessPZ.EXP
PAUSE

