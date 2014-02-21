rem ****
rem **** Undefine PGN_COMPILE in CHESSY2K.ASM then run this bat
rem **** to compile module for position setup and movement by cursor
rem ****
TASM -80 -b ChessY2K.ASM DSK\ChessPZ.COM ChessPZ.EXP
PAUSE