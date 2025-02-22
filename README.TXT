This project is a tribute to the MSX personal computer.
Assembler provides some chess functionality:

1) Can replay chess games from PGN files
2) User can move pieces from starting position
3) User can set up chess position (composer to save screen)

Sometimes bugs happen but it's ok for such an extreme.

Notes:
Attach DSK folder to emulator (blueMsx 999% emul.speed) as Disk.
Put PGN files in DSK folder (file name 7chars).
Modify DSK/autoexec.bat to start other module ChessPZ.COM to
set positions.

Assembler source is for TASM (Z80 8-bit). 
Z80 processor has alternate registers inside (EX AF,AF') almost unused here.
Too much stack push-pop usage, I know.

Heavy MSX VRAM usage.
No chess playing AI, because it's too weak for chess computing.

The video recording of blueMSX can't manage this chess code correctly.
It makes large and sometimes empty media files.

Chessforeva
http://chessforeva.blogspot.com/2012/10/msx-chess-project.html
2012
Have fixed some bugs in 02.2016.
http://github.com/Chessforeva/MSX_chessY2K


Keyboard controls:
ESC - return back
2 x one keypress is disabled, use "/" key to repeat last keyboard action.
(this gives speed performance on emulators)

PGN replay mode.
  Use Enter or Space. "U" is undo-move.

Chess position setup mode.
  Move cursor with  Left,Right,Up,Down.
  Put pieces with  K,k,Q,q,R,r,B,b,N,n,P,p. Space key clears the square.
  Press "C" to remove cursor when ready to take screenshot.

Other:
MSX SDCC (SOLIDC) libraries
https://chessforeva.bitbucket.io/SDCC_msx/index.htm
https://bitbucket.org/chessforeva/chessforeva.bitbucket.io/src/master/SDCC_msx/

