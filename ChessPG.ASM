.title ChessY2K_PGN_module

;=======================================
;
; CHESS PGN GAMES PART
;
;
;=======================================
;
; ChessMN.ASM calls directly to this address
;
            .org $8000
;
; Defines labels to access chess logic.
; This was genereated by "export" operator of tasm
; in ChessY2K.ASM
; REPLACE THESE AFTER EACH RECOMPILE OF CHESSY2K.COM
;
BOARD            .EQU  $0140
BKSQ             .EQU  $0185
BoardOut         .EQU  $1c69
CASTLES          .EQU  $0182
CaptPiece        .EQU  $1903
CastlMove        .EQU  $1905
DEC_I            .EQU  $2722
DEBUGs           .EQU  $274b
ENPSQ            .EQU  $0183
GenMovesAndString .EQU  $1280
GenMoves         .EQU  $1304
GetFEN           .EQU  $1b68
IsEmpty          .EQU  $18af
IsOccupied       .EQU  $18ba
IsWhite          .EQU  $18c5
IsBlack          .EQU  $18e4
IsCheck          .EQU  $1d2e
LD_Ix            .EQU  $2719
MOVE_CNT         .EQU  $0367
MOVE_HIST        .EQU  $0368
MOVE_str         .EQU  $0768
MOVE_byString    .EQU  $1287
MbyStrMove       .EQU  $12a4
MovesToStr       .EQU  $19ba
MovesOut         .EQU  $1a9b
MakeMove         .EQU  $2167
NEXT_MVCNT       .EQU  $0186
NEXT_MOVES       .EQU  $0187
NEXT_MVSTR       .EQU  $0fa8
PromoPcId        .EQU  $1904
SIDE             .EQU  $0181
SQi              .EQU  $1301
SQt              .EQU  $1302
SetFEN           .EQU  $1aa4
ScanSqC          .EQU  $1cea
SetSqScan        .EQU  $1ceb
ScanSqNxt        .EQU  $1cf4
Swap_Sides       .EQU  $22ca
UndoAllMoves     .EQU  $12f2
UnMakeMove       .EQU  $253e
WKSQ             .EQU  $0184
printBOARD       .EQU  $1cbb
startFEN         .EQU  $0107
                            
                                    
start_PG_Module:

; File selection starts here
FSelSubMenu:         
            push af            
            push de
            push hl
            
            call MoveStrClear      ; clear moves to replay after returning
                                 
            ld a,(FDir_)
            cp 0
            jr nz,FDirOv
                                   ;Read disk directory of pgn-files
            ld de,DirOfPGNs        ; datas will be written here
            ld hl,filesPGN
            call dirload           ; uses DISKs library
FDirOv:
            ld de,DirOfPGNs
            ld a,(de)
            cp '$'
            jr z,noPGNfiles
            ld a,1
            ld (_fileI),a
            ld a,0
            ld (_exitFs),a
            
            call InkeyKeyBy30h      ; keypress detect
            ld (_keymnbf),a         ; saves last key
            
LoopFileSel:            
            call DrawFileSelection           
            
            call InkeyKeyBy30h      ; keypress detect
            call FsKeyPress
            ld a,(_exitFs)
            cp 1
            jr z,FileSelExit
            jr LoopFileSel
FileSelExit:                
            call ClearScreenBy30h
            ld a,(_fileI)
            cp 0
            jr nz,FileSelctd
            jr Fselover        ; It exits all menus anyway after ESC on fast emulator

FileSelctd:  
            call FilePGNtoOpen ; use PGN file           

            jr Fselover
noPGNfiles:
            ld hl,$0112
            call LocatePosBy30h
            ld de,MnNoFiles
            call PrintString   ; print out that no files found
Fselover:   
            pop hl          
            pop de
            pop af            
            ret         

      
_keymnbf:   .byte 0  ; key pressed before

_fileI:     .byte 0      ; file selected
_exitFs:    .byte 0      ; internal to know that exit


          #include "String.ASM"      ; most common string functions
          #include "DISKs.ASM"       ; disk functions
          #include "VDPs.ASM"        ; VDP functions

;------------- draws file selection
DrawFileSelection:
            push af
            push bc
            push de
            push hl
            push ix
            push iy
             
            ld h,1
            ld l,Fs_1Row-1
            call LocatePosBy30h

            ld b,0
            ld iy,DirOfPGNs     
            ld a,(iy)          
Fs_chScan:  
            cp '$'       ; end of file list?
            jr z,Fs_chExit
             
            inc b        ; counter
            push bc
               
            ;---------
            push bc
            push hl
            ld de, Fs_name
            ld bc,11
            push iy      ; hl=iy
            pop hl
            ldir
            push hl
            pop iy       ; iy = iy+11
            ld a,'.'
            ld (Fs_name+7),a
            pop hl
            pop bc
            ;--------
            
            push iy
                                            
            inc l  ; next row
            ld a,l
            cp Fs_1Row+Fs_FperC ; per column
            jr nz,Fs_nxtC
            ld a,h
            add a,16
            ld h,a
            ld l,Fs_1Row
Fs_nxtC:             
            call LocatePosBy30h          
                          
            ld a,(_fileI)
            cp b
            jr nz,Fs_chNotI
            ld de,Fs_Seltr1    ; selector1 char
            ld ix,Fs_Seltr2    ; selector2 char            
            jr Fs_chSelI
Fs_chNotI:  ld de,Fs_Space     ; space
            ld ix,Fs_Space 
Fs_chSelI:  call PrintString   ;print selector1
            
            ld de, Fs_name
            call PrintString   ;print FileName item
            push ix
            pop de    ;de=ix 
            call PrintString   ;print selector2
            
            pop iy
            
            ld a,(iy)
            inc iy
            
            pop bc
             
            jr Fs_chScan    ; next file        
Fs_chExit:  
            ld a,b
            ld (Fs_Items),a
              
            pop iy
            pop ix
            pop hl
            pop de
            pop bc
            pop af
            ret
            
FNAME:     .byte 0
Fs_name:   .byte "???????.??? $",0


Fs_Seltr1: .byte "> $",0
Fs_Seltr2: .byte "< $",0
Fs_Space:  .byte "  $",0

;-------------------------- File selection keypress control
FsKeyPress:
            push af
            push bc
            
            cp 0
            jr z,Fs_noAct
            
            ld b,a
            ld a,(_keymnbf)
            cp b
            jr z, Fs_noAct
            ld a,b
            ld (_keymnbf),a
            
            cp 27
            jr nz,Fs_noESC
            
            ld a,1
            ld (_exitFs),a     ; exit menu with no action
            ld a,0
            ld (_fileI),a      ; no selection         
            jr Fs_noAct 
Fs_noESC:                
            cp 32
            jr nz,Fs_noSpace
Fs_spaceKey:
            ld a,1
            ld (_exitFs),a     ; Item has been selected, exit menu and DO action
            jr Fs_noAct        ; use current selection   
Fs_noSpace: cp 13
            jr nz,Fs_noEnter
            jr Fs_spaceKey
   ;         
   ;--- try check Arrow keys
   ;
Fs_noEnter:            
            push af
            ld a,(_fileI)
            ld b,a
            ld a,(Fs_Items)
            ld c,a
            pop af
            
            cp 29
            jr nz, Fs_noLeft
            
            ld a,b                 ; LEFT pressed
            cp Fs_FperC+1          ; column-1
            jr c, Fs_itgo1
            sub Fs_FperC
            jr c, Fs_itgo1
            jr Fs_itm

Fs_noLeft:  
            cp 28
            jr nz, Fs_noRight                                   
            ld a,b                 ; RIGHT pressed
            add a, Fs_FperC        ; column+1
            cp c
            jr c,Fs_itm
            ld a,b
            inc a
            cp c
            jr c,Fs_itm
            ld a,c   
            jr Fs_itm
                                                                                                              
Fs_noRight:
            cp 30
            jr nz, Fs_noUp                                       
            ld a,b                 ; UP pressed
            cp 1
            jr nz,Fs_itgo1
            dec a                  ; item-1
            jr nc,Fs_itm 
Fs_itgo1:   ld a,1                                 
            jr Fs_itm 
                        
Fs_noUp:
            ;cp 31                 ; if DOWN pressed - the same

            ld a,b                 ; other pressed
            inc a                  ; item+1
            cp c
            jr c,Fs_itm
            ld a,c

Fs_itm:
            ld (_fileI),a
   ;--- arrow keys         
                
Fs_noAct:            
            pop bc
            pop af
            ret

;--------------------------- PGN file has been selected, load it
FilePGNtoOpen:
            
            push af
            call SetMode80      ; set width 80
            call ClearScreenBy30h
            
            push bc
            push de
            push hl
            push iy
            ld iy,DirOfPGNs
            ld b,a             ; fileI selected
FileSelCopyFname:
            push bc            
            ld de, Fs_name
            ld bc,11
            push iy      ; hl=iy
            pop hl
            ldir            
            push hl
            pop iy       ; iy = iy+11
            inc iy
            pop bc
            djnz FileSelCopyFname   ; copies file name to FNAME for file opening

            ;--------
            
            call ClearGameData

            ;Read disk directory of pgn-files
            ld a,0                 ; Selector
            call ChessPGN          ; This calls game selector of PGN file
            
                        
            ld a,(_chMenuI)
            cp 0
            jr z,ChGmDontReadMoves
         
         
            ld a,0
            ld (CommT1),a
            ld (CommT2),a          ; clear comment counters
            
            ld a,0                 ; set default position
            call SetFEN 
            
            ld a,1
            call ChessPGN          ; This processes file again to obtain chess moves
            
            ld a,0                 ; set default position
            call SetFEN
            jr ExitChPGN
            
ChGmDontReadMoves:
            
            
CantPGN:
ExitChPGN:
            pop iy
            pop hl
            pop de
            pop bc
            
            call SetMode40        ; reset to width 40
            call ClearScreenBy30h            
            pop af            
            ret



MnNoFiles:  .byte "NO PGN FILES, OR TOO LARGE "
            .byte 13,10,
            .byte "TRY SHORTEN NAME (7char.PGN) $",0

Fs_1Row:    .equ $10     ; first row
Fs_FperC:   .equ  8      ; fileItems per column
Fs_Items:   .byte 0      ; count of items counted

FDir_:       .byte 0      ; 1-to read list of files just once
DirOfPGNs: .ds 12*40

filesPGN:
        .byte 0,"??????? PGN",0        ; wildcard for pgn-files to search in disk

;
; Can not use diskload for larger files. So, we read 3 times per 255 bytes
;  and store in buffers. Then separate in strings (ends with \n).
;  When reading next 3 buffers, we insert the unprocessed last line before new data.
;

; header datas of a Chess Game
dEvent:     .ds $ff
dWhite:     .ds $a0
dBlack:     .ds $a0
dResult:    .ds $10
dRound:     .ds $10
dDate:      .ds $10
dEco:       .ds $10
dEloWhite:  .ds $10
dEloBlack:  .ds $10


; buffers for file processing
DRff:       .ds $ff       ; read from file here
            .byte 0
DRffpre:    .ds $ff       ; here we put parts from previous buffer
DRff0:      .ds $ff       ; 3 buffers for 255 bytes each -
DRff1:      .ds $ff       ; data are copied here
DRff2:      .ds $ff                                          
DRff3:      .ds $10                                          
            .byte 0,1,0   ; to capture while scanning, chr(1) is indicator of last line
DR1K:       .ds $ff       ; 1024 1Kb to operate with string
            .ds $ff
            .ds $ff
            .ds $ff
DRw2:       .ds $ff       ; 512 bytes additional working space for string
            .ds $ff  
DRdoll:     .byte "$",0

_readinFF_over:
            .byte 0


                        
_pgn_cn    .byte 0     ; count of game keys
                                    
;----------------------------------------------------------------------
;
; READS PGN FILE
; Parameter in A is usage:
;    0-read table of games
;    1-read complete pgn of a game                        
;           
;----------------------------------------------------------------------
            
Usage_pgn:  .byte 0

ChessPGN:
            ld (Usage_pgn),a           

              ; For large pgn-file read one screen, press key, read next... 
            push af
            push bc
            push de
            push hl
            push ix
            
            ld a,0
            ld (GLs_),a      ; first screen
            ld (GLi_),a      ; first I
            ld a,1
            ld (GLy_),a            
            ld a,2
            ld (GLx_),a   ; position y=1,x=2
                   
            ld hl,$0101
            call LocatePosBy30h
            
            ld a,0
            ld (_readinFF_over),a
            ld (GL_fpgn),a
            ld (pgn_st),a
            
            ld a,(Usage_pgn)
            cp 0
            jr z,ChGmNoAhead
            
            ld a,0
            call DispWait          ; display that searching game
            
            call Roll1GameAhead     ; if the first game then set flag before reading
ChGmNoAhead:     
        
            ld de,DRffpre      ; clear pre-buffer
            ld a,$ff
            call Block_Clear_
            
            ld hl,FNAME
            
ChPgnScanNxt3buffers_:                            
            ld b,3              ; scan 3 buffers         

ChPgnScanfile_:

            ld a,$ff
            ld de,DRff        ; constantly for file reading
            call Block_Clear_
            
            ld a,(_readinFF_over)
            cp 1
            jr z,ChPgnSkipFF
            
            call readFF            
            cp 0
            jr nz,ChPgnRdNotOver
            ld a,1
            ld (_readinFF_over),a
ChPgnSkipFF:            
ChPgnRdNotOver:

            push de
            pop ix            ; ix=de
            ld a,b            ; sets buffer to copy to
            cp 3
            jr z,ChPgnB0
            cp 2
            jr z,ChPgnB1
            jr ChPgnB2

ChPgnB0:    ld de,DRff0      ;first buffer
            jr ChPgnBset
ChPgnB1:    ld de,DRff1      ;second buffer
            jr ChPgnBset
ChPgnB2:    ld de,DRff2      ;third buffer
ChPgnBset:  
            ld a,$ff
            call Block_Copy_ ; simply copies 255 bytes
            dec b                ; 3 buffers per one reading
            jr nz,ChPgnScanfile_ ; scan next bufer

;--- scanned all 3 buffers
            ld de,DRff0
ChPgnBprLoop:                  ; previous line part finding
            dec de
            ld a,(de)
            cp 0
            jr nz,ChPgnBprLoop ; finds start of line placed in pre-buffer
            inc de 
ChPgnScanBl:                        
            call Str_Line    ; finds line of string to process as GETS()
                        
            ld a,(ix)
            cp 1             ; if end of last buffer
            jr z,ChPgnPartOfLineMayBe
            
            push ix                ; save next string pointer
            call ProcessGETSLine   ; process the line           
            pop de                 ; de=next string from saved ix            
            
            jr ChPgnScanBl   ; scan all 3-buffers

ChPgnScanContinue:
            jr ChPgnScanNxt3buffers_ ; scan next 3 buffers with pre-buffer
                    
ChPgnPartOfLineMayBe:
                ;Should keep last line and process after
                ; part of line + buffers1,2,3 + chr(1)
            call Str_Len
            ld c,a           ;length of string
            
            ld a,(_readinFF_over)
            cp 0
            jr z,ChPgnNotLastLine
            
            call ProcessGETSLine ; process the line   
            
            jr ChPgnScanFileOver ; if over then exit
            
ChPgnNotLastLine:            
            push ix
            push hl
            push de
            push bc
            ld de,DRffpre    ; clears pre-buffer           
            ld a,$ff
            call Block_Clear_
            ld hl,DRff0
            pop bc
            ld b,0
            scf
            ccf
            sbc hl,bc        ; finds starting address to put whole string part
            push hl
            pop de
            ld a,c
            pop ix
            call Block_Copy_ ; simply copies in length of string
            pop hl
            pop ix
            jr ChPgnScanContinue
            
ChPgnScanFileOver:
            call FinalizePgnReading
            ld a,0
            ld (stop_rdFF),a ; restore stopflag
            
            pop ix
            pop hl
            pop de
            pop bc
            pop af          
            ret
;
; This processes line per line
;
           
ProcessGETSLine:
            ld ix,DR1K
            call Str_Copy    ; copy string to 1K buffer
            ld de,DR1K
            call Str_CharsOnly ; omitts special characters
            call GmTableRow
            ret

; This clears data fields for game header information
ClearGameData:
           push de
           ld de, dEvent
           call Str_Clear
           ld de, dWhite
           call Str_Clear
           ld de, dBlack
           call Str_Clear
           ld de,dResult
           call Str_Clear
           ld de,dEco
           call Str_Clear
           ld de,dDate
           call Str_Clear
           ld de,dEloWhite
           call Str_Clear
           ld de,dEloBlack
           call Str_Clear
           pop de
           ret
           
GL_fpgn:   .byte 0      ;flag that indicates to read chess moves                                                                
pgn_st:    .byte 0      ; status of reading
                        ; 0-next comes header
                        ; 1-now reading header tags
                        ; 2-now reading chess moves

sEvent:    .byte "EVENT ",0   ; name of event 
sWhite:    .byte "WHITE ",0   ; white player's name
sBlack:    .byte "BLACK ",0   ; black player's name
sRound:    .byte "ROUND ",0   ; round info 1 or 1.13
sEco:      .byte "ECO ",0     ; openinc code Axx
sResult:   .byte "RESULT ",0  ; result 1/2-1/2
sDate:     .byte "DATE ",0    ; date when game was played
sEloWhite: .byte "WHITEELO ",0 ; ELO rating of white player 2xxx
sEloBlack: .byte "BLACKELO ",0 ; ELO rating of black player


sTgL:      .byte "[",0
sTgR:      .byte "]",0
sPeka:     .byte 34,0    ; ""
sSpc:      .byte " ",0   ;
sTire:     .byte "-",0   ;
sR_:       .byte "R",0
sEmpty     .byte 0
sPt_:      .byte ".",0

sDspSrch:  .byte 13,10  
           .byte "Searching for moves"
sDspCR:    .byte 13,10
           .byte "$",0
sDspAnlz:  .byte 13,10
           .byte "Analyzing PGN moves"
           .byte 13,10
           .byte "$",0
sDspGRpl:  .byte 13,10
           .byte "Going to replay moves"
           .byte 13,10
           .byte "$",0
sDspMKey:  .byte 13,10
           .byte "Press key M to continue"
           .byte 13,10
           .byte "$",0           
sDspPt_:   .byte ".$",0         

; Draws choices of chess games for selection to replay

GmHdTagGet:  
           ld hl,sTgL
           ld iy,sTgR
           ld de,DRw2        ; place here substring between [..]
           call Str_TagSubstr
           push de
           pop ix            ; ix = DRw2
           ret
           
GmHdItemGet:
           ld hl,sPeka
           ld iy,sPeka
           ld de,DR1K          ; place here data
           call Str_TagSubstr  ; datas between "" are stored in DR1K
           push de
           pop ix            ; ix=DR1K                    
           ret
                                          
GmTableRow:

           ld a,(Usage_pgn)
           cp 0
           jr nz,ChNoUCase
           call Str_Upper   ; to uppercase
ChNoUCase:           
           push de
           push hl
           push ix
           push iy
                             ; de=ix=DR1K
           call GmHdTagGet
           call Str_Len
           cp 0
           jr z,GmNoTags
                   
           ld a,(pgn_st)
           cp 2
           jr nz,noPrevGame
           
           call PutOutGmRow   ; display row of game information
noPrevGame:           
           ld a,1
           ld (pgn_st),a      ; reading header
           ld a,(Usage_pgn)
           cp 0
           jr z,GmHeadersAlz
           jr GmReadLnOver
GmHeadersAlz:   
           call GmTagAnalyse  ; separate information in data fields
           jr GmReadLnOver
           
GmNoTags:
           ld a,(pgn_st)
           cp 0
           jr z, GmReadingSkp ; if reading of any game not started jet
           
           cp 1
           jr nz,GmReadingMoves2
           
           ld a,2
           ld (pgn_st),a   ; should be 1.e4...
           
GmReadingMoves2:           ; if reading moves further
           ld a,(Usage_pgn)
           cp 0
           jr z,GmReadingSkp
           
           call GmReadMoves   ; read chess moves...         
GmReadingSkp:

GmReadLnOver:
           pop iy
           pop ix
           pop hl
           pop de
           ret

; Read chess moves line by line
GmReadMoves:
           ld a,(GL_fpgn)
           cp 0
           jr z,GmNoRdMv       ; if flag set then read

           call AppendWOcomments
GmNoRdMv:           
           ret

; Separates datas for each tag
GmTagAnalyse:
           ld de, sEvent
           call Str_Contains ; Does it contain EVENTS substring?
           jr nz,GmTbNotEv   ; if not this item
           
           call GmHdItemGet  ; Get Item information between ""
           ld ix, dEvent     ; Put in data field
           call Str_Copy
GmTbNotEv:
           ld de, sWhite     ; White 
           call Str_Contains
           jr nz,GmTbNotWh 
           call GmHdItemGet
           ld ix, dWhite
           call Str_Copy
GmTbNotWh:       
           ld de, sBlack     ; Black
           call Str_Contains            
           jr nz,GmTbNotBl 
           call GmHdItemGet
           ld ix, dBlack
           call Str_Copy
GmTbNotBl:            
           ld de, sResult    ; Result 
           call Str_Contains
           jr nz,GmTbNotRs 
           call GmHdItemGet
           call Str_Alltrim
           ld ix, dResult
           call Str_Copy
GmTbNotRs:
           ld de, sEco       ; Eco
           call Str_Contains
           jr nz,GmTbNotEco 
           call GmHdItemGet
           call Str_Alltrim           
           ld ix, dEco
           call Str_Copy
GmTbNotEco:
           ld de, sDate      ; Date 
           call Str_Contains
           jr nz,GmTbNotDt 
           call GmHdItemGet
           call Str_Alltrim           
           ld ix, dDate
           call Str_Copy
GmTbNotDt:
           ld de, sEloWhite     ; WhiteElo 
           call Str_Contains
           jr nz,GmTbNotEloWh 
           call GmHdItemGet
           call Str_Alltrim           
           ld ix, dEloWhite
           call Str_Copy
GmTbNotEloWh:
           ld de, sEloBlack     ; BlackElo
           call Str_Contains            
           jr nz,GmTbNotEloBl 
           call GmHdItemGet
           call Str_Alltrim           
           ld ix, dEloBlack
           call Str_Copy       
GmTbNotEloBl:
           ld de, sRound        ; Round
           call Str_Contains            
           jr nz,GmTbNotRn 
           call GmHdItemGet
           call Str_Alltrim           
           ld ix, dRound
           call Str_Copy 
GmTbNotRn:
           ret
           
; resume last game processed
PutOutGmRow:
           push af           
           ld a,(stop_rdFF)
           cp 0
           jr nz,noChGmOutp

           ld a,(Usage_pgn)
           cp 0
           jr z,ChGmOutp
           
           ld a,8
           call DispWait    ; display activity indicator
           
           ld a,(GL_fpgn)
           cp 0
           jr z,ChGmImNext
           
           ld a,2
           call DispWait    ; display that going to replay moves
           
           call PrintPgnGmMvList   
           
           ld a,1
           ld (stop_rdFF),a        ; stop reading file
           
           ld a,0
           ld (GL_fpgn),a         
                      
ChGmImNext:
                       
           call Roll1GameAhead
           
           jr noChGmOutp
ChGmOutp:                      
           call GmRowReady   ; display row of last game information
           call ClearGameData
noChGmOutp:           
           pop af
           ret

; imitate reading table again (just counting)
Roll1GameAhead:
           push af
           push bc           
           
           ld a,(GLi_)
           inc a
           ld (GLi_),a            ; next item in this screen
           
           ld b,a
           ld a,(_chMenuI)
           cp b
           jr nz,notThisChGame
           
           ld a,(GLs_I)
           ld b,a
           ld a,(GLs_)
           cp b
           jr nz,notThisChGame
           
           ld a,1
           call DispWait    ; display that analyzing moves
            
           ld a,1
           ld (GL_fpgn),a   ;this is the right chess game, will read it
                     
           jr notNextScr2          
notThisChGame:

           ld a,(GLi_)
           cp TB_RW*2
           jr nz,notNextScr2
           
           ld a,(GLs_)
           inc a
           ld (GLs_),a
           ld a,0
           ld (GLi_),a      ; imitate next screen
           
notNextScr2:
           pop bc
           pop af
           ret

; to not forget the last game too after end-of-file reading
FinalizePgnReading:
           ld a,(pgn_st)
           cp 0
           jr z,FnNoChGamesAtAll
           call PutOutGmRow  ; display row of game information
           ld a,(GLi_)
           cp 0
           jr z,FnNoSelChGm  ; if no games to select in current screen                    
           call MenuChGM     ; select game in last screen
           jr FnNoChGm
FnNoChGamesAtAll:
FnNoSelChGm: 
           call ChMessNoGames ; Tell about no games               
FnNoChGm:
           ret

GameRw:    .ds $ff
GLx_:      .byte 0           ; contains x,y of selected item on screen
GLy_:      .byte 0
GLx_M:     .byte 0           ; max. x,y selectable
GLy_M:     .byte 0
GLi_:      .byte 0           ; items in current screen
GLs_:      .byte 0           ; screen of selection
GLs_I:     .byte 0           ; screen for 2nd scan

TB_RW:     .equ 23
TB_CL:     .equ 40            ; constants for positioning

   
; Displays line of game to select after
GmRowReady:
           push af
           push de
           push hl
           push ix
           
           ld de,GameRw
           call Str_Clear
           push de
           pop ix           ; ix=de
           ld de,sSpc       ; space
           call Str_Append           
           ld de,sR_        ; R
           call Str_Append
           ld de,dRound     ; round
           call Str_Append
           ld de,sSpc       ; space
           call Str_Append
            
           ld de,dResult+3  ; cut string at 3rd pos.anyway
           ld a,0
           ld (de),a 
           ld de,dResult    ; 1-0,0-1,1/2
           call Str_Append
           
           ld de,sSpc
           call Str_Append
           
           ld de,dWhite+15   ; white player
           ld a,0
           ld (de),a
           ld de,dWhite
           call Str_Append
           ld de,sTire       ; - vs
           call Str_Append
           ld de,dBlack+15
           ld a,0
           ld (de),a           
           ld de,dBlack      ; black player
           call Str_Append

           ld de,GameRw+TB_CL-2  ; cut string at 38th pos.anyway
           ld a,0
           ld (de),a        
        
           ld de, DRdoll    ; add $
           call Str_Append
           ld de, sSpc
           
           ld a,(GLx_)
           ld h,a
           ld a,(GLy_)
           ld l,a
           xor a
               
           ;ld h,40             ;corner at right
           ;ld l,25             ;          bottom
           call LocatePosBy30h  ; set position for game selection Item
           ld de,GameRw
           call PrintString ; print
           
           ld a,(GLi_)
           inc a
           ld (GLi_),a            ; next item in this screen
           
           ld a,(GLs_)
           ld (GLs_I),a           ; save current screen
                                            
           inc l
           ld a,l
           cp TB_RW+1
           jr nz,GmRowSkpNxtCol
           ld a,h
           cp TB_CL-1
           jr c,GmNextCol
                       
           
           ld a,(GLs_)
           inc a
           ld (GLs_),a             ; next screen
           ld a,0                  ; 1st item will be next 
           ld (GLi_),a
           
           ld a,h
           ld (GLx_),a
           ld a,l
           ld (GLy_),a
           
           push hl
           push de
           ld hl,$3319
           call LocatePosBy30h
           ld de,ChMoreGm          ; hint M-more
           call PrintString
           pop de
           pop hl
                                                       
           call MenuChGM           ; select game
           
           jr GmNextMore
GmNextCol:                       
           ld l,1
           ld a,h
           add a,TB_CL       ; next column
           ld h,a
           
GmRowSkpNxtCol:

           ld a,h
           ld (GLx_),a
           ld a,l
           ld (GLy_),a

GmNextMore:
            
           pop ix
           pop hl
           pop de
           pop af
           ret

ChMoreGm: .byte "M - more $",0

_chMenuI:   .byte 0     ; menu selection for chess games
_exitGmMn:  .byte 0     ; to exit game menu

; Menu for chess game selection 
; in current screen (after printing)
;
MenuChGM:

         ld a,(Usage_pgn)
         cp 0
         jr z,ChGmMenuShow
         
         jr GM_MN_EX_   ; and process next when reading chess game

ChGmMenuShow:
         ld a,0
         ld (_exitGmMn),a
        
         ld a,(GLx_)             ; validator for keyboard controls
         ld (GLx_M),a
         ld a,(GLy_)
         ld (GLy_M),a
         ld a,1
         ld (_chMenuI),a         
         ld (GLy_),a             ; stay on first item on position x=2,y=1
         ld a,2
         ld (GLx_),a
         xor a
         call ChGmPutFirstTimeSelector ; put selector
                                    
         call InkeyKeyBy30h      ; keypress detect
         ld (_keymnbf),a         ; saves last key

GM_SEL_LOOP:
         call ChGmMenu
         ld a,(_exitGmMn)
         cp 0
         jr z, ItemChNo0
         jr GM_SEL_EXIT        
ItemChNo0:
         jr GM_SEL_LOOP
         
GM_SEL_EXIT:
         call ClearScreenBy30h   ; clear the screen after
         ld a,(_chMenuI)
         cp $ff
         jr z,GM_SEL_MORE
         ld a,1
         ld (stop_rdFF),a        ; stop reading file (DISKs.ASM)
GM_SEL_MORE:
GM_MN_EX_:        
         ret


ChGmPutFirstTimeSelector:
        push bc
        ld c,0
        call GmDrawSelector     ; inits selector (for not clearing)
        ld c,2
        call GmDrawSelector     ; draws selector         
        pop bc
        ret

; Select chess game by using cursor 
ChGmMenu:
        push bc
        call InkeyKeyBy30h      ; keypress detect
        
        ld c,1
        call GmDrawSelector     ; clears selector
        
        call GhMnKey            ; choice or cursor
        
        ld c,2
        call GmDrawSelector     ; draws selector
        pop bc
        ret

; parameter: c=0 for init, c=1 clears selector, c=2 draws selector

GmDrawSelector:
            push af
            push hl
        
            ld a,c
            cp 0
            jr nz,GmNoInits
            
            ld a,0              ; inits
            ld (_toCl_x),a
            ld (_toCl_y),a
            jr GmDrawEx
            
GmNoInits:  
            cp 1
            jr nz,GmDrawCrs
            
            ld a,(GLx_)
            ld (_toCl_x),a       ; saves where to clear next time and does nothing
            ld a,(GLy_)  
            ld (_toCl_y),a
            jr GmDrawEx
GmDrawCrs:
            ld a,(GLx_)
            ld h,a
            ld a,(GLy_)
            ld l,a
            ld a,(_toCl_x)       ; other x?
            cp 0
            jr z,GmMovedPos      ; if first draw
            cp h
            jr nz,GmMovedPos
            ld a,(_toCl_y)       ; other y?
            cp l
            jr nz,GmMovedPos
            jr GmDrawEx          ; if nothing changed
GmMovedPos:
            ld a,(_toCl_x)
            cp 0
            jr z,GmNotCursClr
            push hl
            ld h,a
            ld a,(_toCl_y)
            ld l,a
            call LocatePosBy30h  ; set position for cursor to clear game selector
            ld a,' '
            call PutCharBy30h  ; just print space (1 ascii character)
            pop hl
GmNotCursClr:
            call LocatePosBy30h  ; set position for cursor to set game selector
            ld a,'>'
            call PutCharBy30h  ; just print 1 ascii character
GmDrawEx:
            pop hl
            pop af
            ret
            
_toCl_x:    .byte 0    ; to know where to clear
_toCl_y:    .byte 0


; this checks which key as been pressed
GhMnKey:
            push af
            push bc
            
            cp 0
            jr z,GmMNnoAct
            
            cp 'Z'
            jr z, GmCkeyZ
            cp '/'
            jr z, GmCkeyZ
            cp '~'
            jr z, GmCkeyZ
            cp '|'
            jr z, GmCkeyZ     ; bunch of the same keys
         
            ld b,a
            ld a,(_keymnbf)
            cp b
            jr z, GmMNnoAct
            ld a,b
            ld (_keymnbf),a
   
            cp 27
            jr nz,GmMNnoEsc
            
            ld a,0
            ld (_chMenuI),a      ; no item selected
            ld a,1
            ld (_exitGmMn),a     ; exit menu
GmMNnoEsc:
            cp 32
            jr nz,GmMNnoSpace
GmMNspaceKey:

            ld a,1
            ld (_exitGmMn),a     ; Item has been selected, exit menu and DO action
            jr GmMNnoAct             
GmMNnoSpace:
            cp 13
            jr nz,GmMNnoEnter
            jr GmMNspaceKey
GmMNnoEnter:
            call IfGmMoreKeys    ; if MORE action
            call IfGmCursKeys    ; process cursor keys
            jr GmMNnoAct
            
GmCkeyZ:                    ; use the same key that was before
            ld a,(_keymnbf)
            ld c,a
            ld a,0
            ld (_keymnbf),a
            ld a,c
            jr GmMNnoEsc
         
GmMNnoAct:            
            pop bc
            pop af
            ret 

;
; If M-pressed then more games
;                        
IfGmMoreKeys:
           push af
           cp 'm'
           jr z,ChGmMore
           cp 'M'
           jr z,ChGmMore
           jr ChGmMoreEx
ChGmMore:
           ld a,1
           ld (_exitGmMn),a
           ld a,$ff              ;indicate "more" action  
           ld (_chMenuI),a
ChGmMoreEx:
           pop af
           ret
           
;---------------------------------
; If cursor arrow keys pressed
;
IfGmCursKeys:

         push af
         push bc   
         cp 29
         jr nz, CkeyGmIfCurs2
                                   ; LEFT pressed
         ld a,(GLx_)
         cp 2
         jr z,CkeyGmCKex
         sub TB_CL
         ld (GLx_),a
         ld a,(_chMenuI)
         sub TB_RW
         ld (_chMenuI),a          
         jr CkeyGmCKex

CkeyGmIfCurs2:  
         cp 28
         jr nz, CkeyGmIfCurs3                                       
                                   ; RIGHT pressed
         ld a,(GLx_M)
         ld b,a
         ld a,(GLx_) 
         cp b
         jr z,CkeyGmCKex
         
         ld a,(GLy_M)
         ld b,a
         ld a,(GLy_)
         inc a
         cp b
         jr z,CkeyRightOk     ; will be last
         jr nc,CkeyGmCKex     ; no move right by cursor
         jr CkeyRightOk       ; otherwise move right
         
CkeyGmCKex:
         jr CkeyGmCKexit   
         
CkeyRightOk:                                                                                                                              
         ld a,(GLx_)                           
         add a,TB_CL
         ld (GLx_),a
         ld a,(_chMenuI)
         add a,TB_RW
         ld (_chMenuI),a         
         jr CkeyGmCKexit
                                                                                                              
CkeyGmIfCurs3:
         cp 30
         jr nz, CkeyGmIfCurs4                                       
                                   ; UP pressed
         ld a,(GLy_)
         cp 1
         jr z,CkeyGmCKexit
         dec a
         ld (GLy_),a
         ld a,(_chMenuI)
         dec a
         ld (_chMenuI),a
         jr CkeyGmCKex                         
CkeyGmIfCurs4:
         cp 31
         jr nz, CkeyGmCKexit                                      
                                   ; DOWN pressed 
         ld a,(GLy_)
         cp TB_RW
         jr z,CkeyGmCKexit
         
         ld a,(GLx_M)
         ld b,a
         ld a,(GLx_) 
         cp b
         jr nz,GmCNotLast
         
         ld a,(GLy_M)
         ld b,a
         ld a,(GLy_)
         inc a
         cp b
         jr z,CkeyGmCKexit     ; if the last item then do nothing
               
GmCNotLast:
         ld a,(GLy_)
         inc a
         ld (GLy_),a
         ld a,(_chMenuI)
         inc a
         ld (_chMenuI),a         
         jr CkeyGmCKexit 
CkeyGmCKexit:
         pop bc
         pop af         
         ret


; if there is no chess games then output message
ChMessNoGames:
         push af
         ld a,(stop_rdFF)
         cp 0                     ; if selected or Esc (stopped)
         jr nz,ChMessNoGmNoOutp
           
         push hl
         push de
         ld hl, $0101
         call LocatePosBy30h
         ld de,ChNoGm
         call PrintString
         call ClearKeyBy30h
ChMessNoGmLoop:         
         call InkeyKeyBy30h      ; keypress detect
         cp 27
         jr z,ChMessNoGmBrk
         cp 32
         jr z,ChMessNoGmBrk
         cp 13
         jr z,ChMessNoGmBrk
         jr ChMessNoGmLoop
ChMessNoGmBrk:
         ld a,0
         ld (_chMenuI),a      ; no item selected
         ld a,1
         ld (_exitGmMn),a     ; exit menu
         pop de
         pop hl
ChMessNoGmNoOutp:         
         pop af
         ret
            
ChNoGm: .byte "No chess games $",0


CommT1: .byte 0      ; counter for open {}
CommT2: .byte 0      ; counter for open ()

c_1_t1: .byte "{",0
c_2_t1: .byte "}",0
c_1_t2: .byte "(",0
c_2_t2: .byte ")",0

; comments should be ignored before inserting into buffer
AppendWOcomments:
         push bc
         push de
         push ix
         
         ld ix,DR1K
         push ix
ACloopAllstr:
         ld a,(ix)
         cp 0
         jr z, ACover3        
         
         ld a,(CommT1)
         cp 0
         jr nz, ACLook4CommT1

         ld a,(CommT2)
         cp 0
         jr nz, ACLook4CommT2
         
         ld a,(ix)
         cp '{'
         jr nz,ACIfCommt2
         
         ld a,(CommT1)
         inc a
         ld (CommT1),a
         jr ACLoopIX       
                                 
ACIfCommt2:
         ld a,(ix)
         cp '('
         jr nz,ACLoopIX
         ld a,(CommT2)
         inc a
         ld (CommT2),a
         jr ACLoopIX 
         
ACLook4CommT1:
         ld a,(ix)
         cp '}'
         jr nz,ACLoopIX
         ld a,(CommT1)
         dec a
         ld (CommT1),a         
         jr ACrepl0
         
ACLook4CommT2:
         ld a,(ix)
         cp ')'
         jr nz,ACLoopIX
         ld a,(CommT2)
         dec a
         ld (CommT2),a 
         jr ACrepl0        

ACLoopIX:
         ld a,(CommT1)
         cp 0
         jr z, ACmaybeT2
         
ACrepl0: ld a,' '
         ld (ix),a
         jr ACLoop1
         
ACmaybeT2:
         ld a,(CommT2)
         cp 0
         jr nz, ACrepl0
ACLoop1: 
         inc ix
         jr ACloopAllstr
         
ACover3:         
         pop ix              ; =DR1K
         push ix
         ld de,sSpc
         call Str_Append     ; + 1space
         
         ; remove double spaces
         pop de              ; =DR1K
         push de
         ld b,0              ; flag that space was found 
ACLoopCopy:
         ld a,(de)
         ld (ix),a
         inc de
         inc ix
         cp 0
         jr z,ACnowAppend
         cp ' '
         jr nz,ACsetBto0
         ld a,b
         cp 0
         jr z,ACsetBfound
         dec ix
         jr ACLoopCopy
ACsetBfound:         
         ld b,1
         jr ACLoopCopy
ACsetBto0:
         ld b,0
         jr ACLoopCopy
ACnowAppend:
         pop de              ; =DR1K
         
         call ChessNotatedMoves
         
         ;DR1K now contains PGN move sfring from PGN file
         ld ix, DR1K
         ld de, DRdoll    ; add $
         call Str_Append
         push ix
         pop de
         call PrintString 

         pop ix
         pop de
         pop bc
         ret

_mv_str: .byte "           ",0         ; notated move in form: Rad1+

; processes all moves to get MOVE_str
ChessNotatedMoves:
         push af
         push bc
         
CNMskipSpaces:
         ld a,(de)
         inc de
         cp ' '                ; skip leading spaces
         jr z,CNMskipSpaces
         dec de

CNMnextMv:
         ld ix,_mv_str
         ld c,0
CNMloopMv:
         inc c
         ld a,10
         cp c
         jr z,CNMexit_   ;10symbols too long for chess move
                  
         ld a,(de)
         cp 0
         jr z,CNMexit_
         
         ld (ix),a
         inc ix
         cp ' '
         jr z,CNMmoveTry
         inc de         
         jr CNMloopMv
                  
CNMmoveTry:
         
CNMdoSpcer:
         ld a,10
         cp c
         jr z,CNMexitSpcer
         ld a,' '                   ; some clearing stuff (not long)
         ld (ix),a
         inc ix
         inc c
         jr CNMdoSpcer
         
CNMnextMv_:   
         jr CNMnextMv               ; hate far jumps in small procedures
         
CNMexitSpcer:
                                    ; now word is separated
         push de
         ld ix,_mv_str
                  
         ld de,sPt_
         call Str_IndexOf
         cp $ff
         jr z,CNMnoPt
                  
CNMptLoop:
         ld b,a                     ; remove move numbers
         ld a,' '
         ld (ix),a
         inc ix
         ld a,b
         cp 0
         jr z,CNMnoPt1
         dec a
         jr CNMptLoop
CNMnoPt1:
         ld a,(ix)                  ; removes ...
         cp '.'
         jr nz,CNMnoPt
         ld a,' '
         ld (ix),a
         inc ix
         jr CNMnoPt1
         
CNMexit_:
         jr CNMexit

CNMnoPt:
         call CNdontNeedResults
 
         ld de,_mv_str
         ld ix,_mv_str
         call Str_Alltrim        
         call Str_Len
         jr z,CNMnoMove              ; Only moves should remain
           
         call GenMovesAndString     ; generate all valid chess moves
                  
         call CNReplCastles
         jr nz,CN_AlreadyCst
         
         call CNM_Move               ; analyse notated chess move by components
         jr z,CNMnoMove              ; if can't parse then skip and sorry
         
CN_AlreadyCst:

         ld de,_mv_UCI
         call MbyStrMove             ; make one move by using string in DE
         
         ld de,_mv_UCI
         call MoveStrAppend
         
CNMnoMove:      
         pop de
         dec de
CNMloopSpc:
         inc de
         ld a,(de)
         cp ' '                      ; find next move or move nr.         
         jr z,CNMloopSpc
         jr CNMnextMv_
              
CNMexit:
         pop bc
         pop af
         ret

_sRes1:  .byte "1-0",0
_sRes2:  .byte "0-1",0
_sRes3:  .byte "1/2",0
_sPosEv: .byte "$",0          ; sometimes happen that position evaluations are inside PGN

; no need to analyse result string at end of PGN
CNdontNeedResults:
         push de
         push ix
         ld ix,_mv_str
         ld de,_sRes1
         call Str_Contains
         jr z,CNemptyRStr
         ld de,_sRes2
         call Str_Contains
         jr z,CNemptyRStr
         ld de,_sRes3
         call Str_Contains
         jr z,CNemptyRStr
         ld de,_sPosEv 
         call Str_Contains         
         jr nz,CNNoResEx
CNemptyRStr:
         ld a,0
         ld (ix),a
CNNoResEx:
         pop ix
         pop de
         ret

_castlT0001:  .byte "0-0-0",0
_castlT0002:  .byte "O-O-O",0
_castlT001:   .byte "0-0",0
_castlT002:   .byte "O-O",0

; converts move to castling e1g1 or e1c1 or e8g8 or e8c8
; returns Z and A=0 if this was not castling move
; to process as usual move                
CNReplCastles:
         push de
         push ix         
         ld ix,_mv_str
         ld de,_castlT0001
         call Str_Contains
         jr z,CNemptyC000Str
         ld de,_castlT0002
         call Str_Contains
         jr z,CNemptyC000Str
         ld de,_castlT001
         call Str_Contains
         jr z,CNemptyC00Str
         ld de,_castlT002
         call Str_Contains
         jr z,CNemptyC00Str
         ld a,0
         jr CNNoCastlEx
CNemptyC000Str:
         ld a,'c'
         jr CNcstlStore1
CNemptyC00Str:
         ld a,'g'
CNcstlStore1:
         ld (_mv_tA),a
         ld a,'e'
         ld (_mv_fA),a
         
         ld a,(SIDE)
         cp 0
         jr nz,CNcastlBlack
         ld a,'1'
         jr CNcstlStore2
CNcastlBlack:
         ld a,'8'
CNcstlStore2:
         ld (_mv_f8),a
         ld (_mv_t8),a
         ld a,' '
         ld (_mv_pr),a
         ld a,1
CNNoCastlEx:
         pop ix
         pop de
         cp 0         
         ret


_mv_UCI:                      ; UCI move in form: a7a8q
_mv_fA:   .byte 0
_mv_f8:   .byte 0             ; from 
_mv_tA:   .byte 0
_mv_t8:   .byte 0             ; to
_mv_pr:   .byte 0             ; promoted
          .byte ' ',0         ; blank separator

_pc2find: .byte 0,0
_notPawn: .byte "NBRQK",0
_PromPcs: .byte "nrqNRQ",0    ; no bishop, should be = 

; finds position for hl on the separator after the current move  
CNMhlRR: 
       push af
CNMhlRloop:  
       ld a,(hl)    ; separator?
       cp 0
       jr z,CNMhlR0
       cp ','
       jr z,CNMhlR0
       cp '$'
CNMhlR0:       
       ; Z if separator
       jr z,CNMhlRfound  ; then stop on it
       inc hl
       jr CNMhlRloop
CNMhlRfound:
       pop af
       ret
                    
_mv_wrk:  .byte "xxxxx",0

CNMpcIsPawn:             ; sets z if not pawn in A
         ld de,_pc2find
         ld (de),a
         ld ix,_notPawn
         call Str_Contains
         ret
         
CNMpcIsPromo:            ; sets z if promopiece in (HL)
         push de
         push ix
         ld de,_pc2find
         ld a,(hl)
         ld (de),a
         ld ix,_PromPcs
         call Str_Contains
         pop ix
         pop de
         cp 0
         ret
         
; Generates UCI move
; compares move of PGN-file to valid moves in current position
; returns Z flag and A=0 if move not found,
; container contains move otherwise
;
CNM_Move:
         push bc
         push de
         push hl
         push ix
         
         ld a,5
         ld de,_mv_UCI     ; clear container
         call Block_Clear_
         
         ld hl,_mv_str
         call CNMhlRR      ; to analyse backwards
         dec hl
         
         call CNMPrepFrTo  ; prepares mask in _mv_UCI
         
         ld hl,NEXT_MVSTR

         ld ix,_mv_str         
         ld a, (ix)   ; notated piece (from PGN-file)
         ld c,a
         call CNMpcIsPawn ; is pawn in A?
         jr z,CNMnotPawn
         ld c,'P'    ; if seems pawn move
CNMnotPawn:

CNMloopMoves:
         ld a,c
         cp 'P'
         jr nz,CNMnotPiecePawn
         call CNMisAH           ; should be a-h for pawn
         jr c,CNMgoodPiece         
         jr CNMnotThisMv
                           
CNMnotPiecePawn:
   
         ld a,(hl)   ; notated piece for this move
         cp c
         jr nz,CNMnotThisMv   ; if other piece
                  
CNMgoodPiece:        

         ld a,(hl)
         call CNMpcIsPawn ; is pawn in A?
         jr nz,CNMPawnSkip
         inc hl               ; skip piece 
CNMPawnSkip:
         
         call CNMCmpFrTo      ; compare to mask
         jr z,CNMnotThisMv

         ; the same = ok
         ld ix,_mv_wrk
         ld de,_mv_UCI        ; complete move information
         ld a,5
         call Block_Copy_
         
         ld a,1    ; found
         jr CNMCpExit

CNMnotThisMv:
         call CNMhlRR
         cp '$'
         jr z,CNMCpBadExit
         inc hl               ; set position to next move
         jr CNMloopMoves
         
CNMCpBadExit:
         ld a,0    ;not found
CNMCpExit:
         pop ix
         pop hl
         pop de
         pop bc
         cp 0
         ret                  
              

; sets C flag if A in ['1'..'8'] 
CNMis18:
         call CNMskpPlus
         ld a,(hl)         
         cp '1'
         jr c,CNMnot18
         cp '8'+1
         jr nc,CNMnot18
         scf
         jr CMMex18
CNMnot18:
         scf      
         ccf
CMMex18: ret
         
; sets C flag if A in ['a'..'h'] 
CNMisAH:
         call CNMskpPlus
         ld a,(hl)
         cp 'b'
         jr nz,CNM_noPromoCk
         dec hl
         ld a,(hl)
         cp '='
         jr z,CNMnotAH    ; if bishop promotion
         inc hl
         ld a,(hl)         
CNM_noPromoCk:         
         cp 'a'
         jr c,CNMnotAH
         cp 'h'+1
         jr nc,CNMnotAH
         scf
         jr CMMexAH
CNMnotAH:
         scf      
         ccf
CMMexAH: ret

_skipSymb: .byte " =-x*:.+#?!;$",0

; skips non a1-h8  symbols and reads promoted piece
CNMskpPlus:
         push af
         push de
         push ix
CNMskpPlLoop:
         ld a,(hl)
         cp '='
         jr nz,CNM_noPromo
         ;ld a,c
         ;cp 'P'
         ;jr nz,CNM_noPromo
         inc hl
         ld a,(hl)
         dec hl
         cp 'Z'
         jr nc,CNM_prmUpC
         add a,32            ; to lowercase
CNM_prmUpC:         
         ld (_mv_pr),a
         ld a,'='
CNM_noPromo:
         ld de,_pc2find         
         ld (de),a
         ld ix,_skipSymb
         call Str_Contains
         jr nz, CNMskpPlusEx         
         dec hl
         jr CNMskpPlLoop
CNMskpPlusEx:
         pop ix
         pop de
         pop af
         ret

; prepares mask to compare with 00e4 will match e2e4
CNMPrepFrTo:
         call CNMskpPlus
         call CNMpcIsPromo
         jr nz,CNMPrepNoProm
         ld a,(hl)
         dec hl
         cp 'Z'
         jr nc,CNMPrep_prmUpC
         add a,32            ; to lowercase
CNMPrep_prmUpC:         
         ld (_mv_pr),a        
CNMPrepNoProm:
         call CNMis18
         jr c,CNM_to8
         jr CNMbkwt1              
CNM_to8:
         ld (_mv_t8),a       ;to 1..8
         dec hl
CNMbkwt1:

         call CNMisAH
         jr c,CNM_toH
         jr CNMbkwt2              
CNM_toH:
         ld (_mv_tA),a       ;to A..H
         dec hl
CNMbkwt2:

         call CNMis18
         jr c,CNM_fr8
         jr CNMbkwf1              
CNM_fr8:
         ld (_mv_f8),a       ;from 1..8
         dec hl
CNMbkwf1:
                  
         call CNMisAH
         jr c,CNM_frH
         jr CNMbkwf2              
CNM_frH:
         ld (_mv_fA),a       ;from A..H
         dec hl
CNMbkwf2:
        ret
; if piece the same then
; compares container (mask of known) with generatad valid move (like "Ng1-f3") 
CNMCmpFrTo:
         ld ix,_mv_wrk         

         ld a,(_mv_fA)
         cp 0
         jr z,CNMokf1
         ld b,a
         ld a,(hl)
         cp b
         jr nz,CNMPnotThisMv
CNMokf1: 
         ld a,(hl)
         ld (ix),a
         inc ix
         inc hl

         ld a,(_mv_f8)
         cp 0
         jr z,CNMokf2
         ld b,a
         ld a,(hl)
         cp b
         jr nz,CNMPnotThisMv
CNMokf2: 
         ld a,(hl)
         ld (ix),a
         inc ix
         inc hl
         
         inc hl             ; skip symb. "-" or "x"

         ld a,(_mv_tA)
         cp 0
         jr z,CNMokt1
         ld b,a
         ld a,(hl)
         cp b
         jr nz,CNMPnotThisMv
CNMokt1: 
         ld a,(hl)
         ld (ix),a
         inc ix
         inc hl

         ld a,(_mv_t8)
         cp 0
         jr z,CNMokt2
         ld b,a
         ld a,(hl)
         cp b
         jr nz,CNMPnotThisMv
CNMokt2: 
         ld a,(hl)
         ld (ix),a
         inc ix
         inc hl
         
         ld a,' '
         ld (ix),a               ; clear promotion
                           
         ld a,(hl)
         cp '='
         jr nz,CNMokPr
         inc hl
         
         ld a,(_mv_pr)
         cp 0
         jr z,CNMokPr
         sub 32                  ; uppercase
         ld b,a
         ld a,(hl)               ; queen comes first and default
         cp b
         jr nz,CNMPnotThisMv
         ld a,(_mv_pr)
         ld (ix),a
CNMokPr:
         ld a,1
         jr CNCMPexit
CNMPnotThisMv:
         ld a,0
CNCMPexit:
         cp 0
         ret

; clears move string for
; UCI based chess movements MOVE_str
MoveStrClear:                            
         push af                  
         push bc
         push de
         push hl
         ld hl,MOVE_str
         push hl
         pop de
         inc de
         ld a,0
         ld (hl),a 
         ld bc,$0800        ;2Kb scan with set=0
         ldir
         pop hl
         pop de
         pop bc
         pop af
         ret
         
; appends move from DE address to
; UCI based chess movements MOVE_str

MoveStrAppend:
         push af
         push bc                  
         push de
         push hl
         ld de,MOVE_str
MVSTRApLoop:        
         ld a,(de) 
         cp 0
         jr z,MVSTRApDE
         inc de                
         jr MVSTRApLoop
MVSTRApDE:
         ld bc,6
         ld hl,_mv_UCI
         ldir             ; copies UCI move
         dec de
         dec de
         ld a,(de)
         cp ' '
         jr nz,MVSTRApOk
         inc de
         ld a,0
         ld (de),a
MVSTRApOk:         
         pop hl
         pop de
         pop bc
         pop af
         ret

; prints chess moves ready for replaying
PrintPgnGmMvList:
         push af
         push de
         push ix
                       
         ld ix, MOVE_str
         ld de, DRdoll    ; add $
         call Str_Append
         push ix
         pop de
         call PrintString                    
         pop ix
         pop de
         pop af
         
         ld a,6
         call DispWait     ; press M key
         call ClearKeyBy30h
PrMvLsWait:         
         call PressKeyBy30h
         cp 'M'
         jr z,PrMvLsEx
         cp 'm'
         jr z,PrMvLsEx
         cp 27
         jr z,PrMvLsESC         
         jr PrMvLsWait
PrMvLsESC:         
         call MoveStrClear   ; cancel replay and exit to menu again
PrMvLsEx:              
         ret

; displays current processing status
DispWait:
         push de
         cp 0
         jr nz,DspWtNo0
         ld de,sDspSrch      ; Searching
         jr DspWtOutp
DspWtNo0:
         cp 1
         jr nz,DspWtNo1
         ld de,sDspAnlz      ; Analyzing
         jr DspWtOutp
DspWtNo1:
         cp 2     
         jr nz,DspWtNo2
         ld de,sDspGRpl      ; Ready to replay
         jr DspWtOutp
DspWtNo2:         
         cp 6     
         jr nz,DspWtNo6
         ld de,sDspMKey      ; Press M-message
         jr DspWtOutp         
DspWtNo6:
         cp 7     
         jr nz,DspWtNo7
         ld de,sDspCR        ; carriage return
         jr DspWtOutp
DspWtNo7:         
         cp 8
         jr nz,DspWtNo8
         ld de,sDspPt_       ; Put point indicating activity
         jr DspWtOutp
DspWtNo8:                  
         jr DspWtEx
DspWtOutp:
         call PrintString
DspWtEx:
         pop de
         ret
                   
end_PG_Module:          
.end          