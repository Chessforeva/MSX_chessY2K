;=======================================
;
; Graphics part of chess program ChessY2K
;
;=======================================
;
; USER INTERFACE
; screen, vdp, keyboard controls
;
; Uses VRAM even too much for chess needs.
; Will be good for presentation recording.
;
;---------------------------------------

;
; Defines labels to access datas after loading.

; global labels, genereated by "export"
; operator of tasm in ChessPI.ASM

#include "ChessPI.EXP"


Stylo:    .byte 0   ; set as configuration flags:
                    ; 0-bit to use cursor 
                    ; 1-bit allow drag and move pieces
                    ; 2-bit set up pieces mode

CursorSq: .byte 12         ; square of cursor, on init=E2
DragSq:   .byte $ff        ; drag at square
RplyMs:   .byte 0          ; position in MOVE_str for replayer

Grph_Exit: .byte 0        ; 1 on ESC exit 

PiecesIX:
        .word dtSQW+6, dtSQB+6
        .word dtWPW+6, dtWPB+6, dtWNW+6, dtWNB+6, dtWBW+6, dtWBB+6
        .word dtWRW+6, dtWRB+6, dtWQW+6, dtWQB+6, dtWKW+6, dtWKB+6
        .word dtBPW+6, dtBPB+6, dtBNW+6, dtBNB+6, dtBBW+6, dtBBB+6
        .word dtBRW+6, dtBRB+6, dtBQW+6, dtBQB+6, dtBKW+6, dtBKB+6         



VRAMcopy:       ; for each piece, to know that was copied to VRAM
        .word 0,0,0,0,0,0,0,0,0,0,0,0,0
VRAMcpXY:       ; for each piece, holds HL (X,Y coord.)
        .word 0,0,0,0,0,0,0,0,0,0,0,0,0 
        .word 0,0,0,0,0,0,0,0,0,0,0,0,0

VRAMcirc: .byte 0 ; to know that sign copied to VRAM

                ; the same for masks of black and white pieces
                ; Masks are used when piece is moving.
                ; Simple square redraw is used after animation is over.
PiecesMskIX:
        .word dtWP+6, dtWN+6, dtWB+6, dtWR+6, dtWQ+6, dtWK+6
        .word dtBP+6, dtBN+6, dtBB+6, dtBR+6, dtBQ+6, dtBK+6
VRAMcpMsk:    .word 0,0,0,0,0,0
VRAMcpMskXY:  .word 0,0,0,0,0,0,0,0,0,0,0,0  

CircIX: .word dtWhiteToMove+6, dtBlackNotToMove+6, dtWhiteNotToMove+6, dtBlackToMove+6
                                                                                                                                                                                                       
GraphicsS:
         ld a,0
         ld (Loaded2VRAM),a                ; should load to VRAM 

         
         ; loads datas of graphics in memory from file
         call ChessY2K_GraphDatas_load
            
         ld a,12
         ld (CursorSq),a           ; cursor on E2
         ld a,$ff
         ld (DragSq),a             ; no drag
         ld a,0
         ld (Grph_Exit),a          ; starting...
         ld (RplyMs),a            ; set replayer position to 0



         call ClearLastFEN         ; for setup position clear previous one
         call SetScreen5By30h      ; set Screen 5 by using BIOS
         call DisableScreenBy30h   ; do not display
         ld hl, tbPalettes         ;
         call SetPaletteByTable    ; defines 16colors
         call VDPfaster            ; optimize VDP, sprites off         
         call SetGraphics0         ; most graphics inits
         call PutMSXlogo           ; put MSX lable on screen
         call PutToMove            ; draws and saves rounded-sign which side to move
                                   ;  (and saves to VRAM too)
            
         ;1.draw just squares
         call PutFrame             ; puts frame for board
         call Draw0Board           ; just draw empty board without pieces
         
         ;2 create copy of pictures in VRAM      
         call SetPMapFEN           ; sets special board for saving at XY in VRAM to know later
         call DrawBoard            ; draws complete board with pieces and saves bitmaps
         call Draw0Board           ; just draw empty board to overwrite glitches
         call PutFrame             ; redraw frame - with no defects

         ;3 set chess position to play from
         call SetFENbyMode         ; set position according mode
         call DrawBoard            ; now uses saved pieces
         call PutToMove            ; redraw using saved
         
         ld a,0
         call SetPage              ; Page to display
         call EnableScreenBy30h    ; display on
         
         call DrawCursor           ; Draws a rectangle of cursor on square
         call GenMoves             ; And generate first moves too.
         
         call InkeyKeyBy30h      ; keypress detect
         ld (PreKeyWas),a         ; saves last key

LOOP_GRAPHICS:
         call InkeyKeyBy30h        ; keypress detect
         cp 0
         jr z, no_key_pressed

         call Cursor_Key_Controls  ; keyboard, cursor by arrow-keys
no_key_pressed:
                
         call ANIMATION            ; process animations, if there should be

         ld a,(Grph_Exit)
         cp 0                      ; Exit on ESC 
         jr z,LOOP_GRAPHICS                                                                    
                                            
         call RestoreColors
         call SetScreen0By30h      ; set Screen 0
         
         ret
         
; set page 0, color 0, vdp for drawing

SetGraphics0:
         push af
         push hl
         
         ld a,0
         call SetBorderColor       ; sets color by number
         ld a,0
         call SetPage              ; Page to display
                  
         ld a,0
         ld hl,0
         call Set_Vdp_Write        ; gona send to vdp
         
         pop hl
         pop af
         ret 

emptyFEN:    .byte "8/8/8/8/8/8/8/8 w - - 0 1",0
piecemapFEN: .byte "8/PPpp4/NNnn4/BBbb4/RRrr4/QQqq4/KKkk4/8 w - - 0 1",0
wasSetUpFEN: .byte "$"
             .ds 90

SetPMapFEN:                        ; set special FEN for piece bitmaps
         push af
         push ix
         ld a,1
         ld ix, piecemapFEN
         call SetFEN
         pop ix
         pop af
         ret
        
Draw0Board:                        ; draws an empty board without pieces 
         push af
         push ix               
         call SetEmptyFEN         ; set empty board      
         ld a,1
         ld (DrItFl),a
         call DrawBoard            ; just draw empty board without pieces
         ld a,0
         ld (DrItFl),a
         pop ix
         pop af 
         ret
         
SetEmptyFEN:                 ; this sets an empty board position
         ld a,1
         ld ix, emptyFEN
         call SetFEN         
         ret
         
SetFENbyMode:                ; sets position by mode
         push af 
         ld a,(Stylo)    
                  
         bit 2,a
         jr z, SetStartFEN

         call SetEmptyFEN    ; set empty board
         jr SetFByMover

SetStartFEN:         
         ld a,0              ; set default position
         call SetFEN
SetFByMover:
         pop af
         ret
         
ClearLastFEN:
         push af
         push de
         ld de,wasSetUpFEN
         ld a,'$'
         ld (de),a
         pop de
         pop af
         ret

         
;-----------------------------------------------------
;
; Chess move by cursor and space
;
; Validates move, moves piece on board and screen.
; SQi - from square
; SQt - to square
; PromoPcId - id of piece to promote = 4-queen,3-rook,2-bishop,1-knight, 0-no promotion

Chess_Move_Cursor:
         push af
         ld a,(Move_sq_f)
         ld (SQi),a
         ld a,(Move_sq_t)
         ld (SQt),a
         ld a,0
         ld (PromoPcId),a
         ld a,0
         ld (AnimUnMk),a
         call setAnimation        ; animate it and make move
NotValidChMv:         
         pop af
         ret
         
Chess_Move_Real:
         call MakeMove            ; Goes when animation is over
         call AfterChessMovement
         ret

;--------------------------------------------------------
;
; Undo chess animated chess move
;
Chess_UnMake_Move_U:
         push af
         push bc
         push de
         push hl
                                                                                               
         ld hl, MOVE_CNT
         ld c,(hl)
         ld hl, MOVE_HIST
         ld a, c
         cp 0
         jr z, Unmake_end_action
         ld b,0

         dec c
         add hl,bc
         add hl,bc
         add hl,bc
         add hl,bc
         
         ld a,(hl)        ; from
         ld (Move_sq_t),a ; move backward animation
         ld d,a
         inc hl
         ld a,(hl)        ; to    
         ld (Move_sq_f),a
         ld e,a
         inc hl
         ld a,(hl)        ; flags
         
         ld c,0         
         bit 5,a      ; if en-passant capture
         jr z,NoEnPassUnmakeMove
         
         ld a,e
         and 7
         ld c,a          ;X of en-passant square
         ld a,d
         and %11111000   ;Y of en-passant square
         or c
         ld c,a
NoEnPassUnmakeMove:
         ld a,c
         ld (Move_Enp),a ; save en-p.square for animation    
                           
         ld a, (hl)   ; flags                
         bit 4,a      ; if castling
         jr z,UnmakeNoCastling
         
         ld c,1
         ex de,hl
         call SetCastlesForLater
         ex de,hl             
                  
UnmakeNoCastling:
         ld a,1
         ld (AnimUnMk),a
         call setAnimation        ; animate it and unmake move
         
Unmake_end_action:
         pop hl
         pop de
         pop bc
         pop af
         ret

; Does actual unmake on chess board
Chess_Unmake_Move_Real:
         call UnMakeMove            ; Goes when animation is over
         call AfterChessMovement
         ret                                                                       

;
; Action right after chess make/unmake move
; Redraws 2 squares after movement
; Regenerates next moves
;
AfterChessMovement:
         push af
         push bc
         ld a,(Move_sq_f)
         ld c,a             
         call DrawSquare
         ld a,(Move_sq_t)
         ld c,a             
         call DrawSquare
         call DrawCursor
         pop bc
         pop af
         call GenMoves  ; And generate next moves too
         call PutToMove ; redraws which side to move
         ret
         
;--------------------------------------------------------
;
; Drag and move validation
; Parameter: reg-a  0 - for drag, 1 - for move
;
IsValidDragMove:

         push bc
         push de
         push hl
         push ix
         
         ld d,a   ;save usage
         ld e,0   ; flag that found
                                                                      
         ld ix, NEXT_MVCNT
         ld b,(ix)
         ld ix, NEXT_MOVES
         ld a, b
         cp 0
         jr z, ValidLookExit

         ld a,(DragSq)
         ld h,a
         ld a,(CursorSq)
         ld l,a

isValidLoop:

         ld a, (ix)   ; notated piece
         inc ix
         ld a, (ix)   ; from square
         ld (SQi),a        
         inc ix               
         ld a, (ix)   ; to square
         ld (SQt),a
         inc ix   
         ld a, (ix)   ; flags and promoted piece
         ld c,0
         bit 1,a      ; if promotion
         jr z,ValidNoPromo
         ld c,4       ; then queen
ValidNoPromo:
         ld a,c
         ld (PromoPcId),a
                
         ld a,d
         cp 0
         jr z,isValidDrag
         
         ld a,(SQi)      ; verify movement
         cp h
         jr nz, ValidNotThisMove
                 
         ld a,(SQt)
         cp l
         jr nz, ValidNotThisMove

         ld a, (ix)   ; flags                
         ld c,0         
         bit 5,a      ; if en-passant capture
         jr z,ValidNoEnPassMove
         
         ld a,l
         and 7
         ld c,a          ;X of en-passant square
         ld a,h
         and %11111000   ;Y of en-passant square
         or c 
         ld c,a
ValidNoEnPassMove:
         ld a,c
         ld (Move_Enp),a ; save en-p.square for animation    
                           
         ld a, (ix)   ; flags                
         bit 4,a      ; if castling
         jr z,ValidNoCastling
         
         ld c,0
         call SetCastlesForLater
                  
ValidNoCastling:
         jr ValidIsThis
         
isValidDrag:             ; verify drag
         ld a,(SQi)
         cp l
         jr nz, ValidNotThisMove
         
ValidIsThis:       ; ok, this move        
         ld e,1
         jr ValidLookExit
         
ValidNotThisMove:
         inc ix        
         djnz isValidLoop
                  
ValidLookExit:
         ld a,e
         pop ix
         pop hl
         pop de
         pop bc
         ret

; save castling rook info for animation later
; set before reg-c  = 0 for makemove, 1 for unmake move               
SetCastlesForLater:
         ld a,l       ; square to
         cp 6
         jr z,thisValidE1G1 ; e1g1
         cp 2
         jr z,thisValidE1C1 ; e1c1
         cp 62
         jr z,thisValidE8G8 ; e8g8
         cp 58
         jr z,thisValidE8C8 ; e8c8
         jr ValidCstlNot
thisValidE1G1:
         ld hl,$0507      ; h1f1
         jr ValidSetCastles         
thisValidE1C1:
         ld hl,$0300      ; a1c1
         jr ValidSetCastles         
thisValidE8G8:
         ld hl,$3D3F      ; h8f8
         jr ValidSetCastles         
thisValidE8C8:
         ld hl,$3B38      ; a8c8
ValidSetCastles:
         ld a,c
         cp 0
         jr nz, unMakeCastlesCase
         ld a,l
         ld (MvC_sq_f2),a
         ld a,h
         ld (MvC_sq_t2),a
         jr ValidSaveCstl
unMakeCastlesCase:
         ld a,h
         ld (MvC_sq_f2),a
         ld a,l
         ld (MvC_sq_t2),a
ValidSaveCstl:         
         ld a,1
         ld (Move_Cstl),a ; save for animation    
ValidCstlNot:
         ret
         
;----------------------------------------------------|
;
;  This draws moving piece.
;  Should be on timer interrupt.
;  Anyway doesnt matter on emulators.  
;  Uses lots of VRAM (video memory), just because
;  it is best MSX has and can manage fast.
;

Move_sq_f: .byte 0   ; from square
Move_sq_t: .byte 0   ; to square
Move_X_f:  .byte 0   ; from X on screen
Move_Y_f:  .byte 0   ; Y
Move_X_t:  .byte 0   ; to X
Move_Y_t:  .byte 0   ; to Y
Move_X:    .byte 0   ; current X 
Move_Y:    .byte 0   ; current Y
Move_DX:   .byte 0   ; dx in dots (kinda y=a*x+c in asm)
Move_DXn:  .byte 0   ; to 0-right, 1-left
Move_DY:   .byte 0   ; dy in dots
Move_DYn:  .byte 0   ; to 0-down, 1-up

MovePc_f:  .byte 0   ; holds piece on square from (as we remove while animating)
MovePc_t:  .byte 0   ; holds piece on square to

Move_Enp:  .byte 0   ; square if en-passant capturing

Move_Cstl: .byte 0   ; 1 if castling king (to start for rook after)
MvC_sq_f2: .byte 0   ; for rook movement squares from->to
MvC_sq_t2: .byte 0   ;
AnimI:     .byte 0   ; counter 0..25
AnimUnMk:  .byte 0   ; 1 if UnMake case

setAnimation:           ; provide square numbers
             push af
             push bc
             push de
             push hl
             
             xor b    ; b=0
             ld a,(Move_sq_f)            
             call ObtainHLboardBySq
             ld d,(hl)
             ld (hl),b
             ld c,a
             call DrawSquare          ; now empty while moving
             call GetHLbySquare       ; set X,Y
             ld a,d
             ld (MovePc_f),a
             ld a,h
             ld (Move_X_f),a          ; from
             ld (Move_X),a            ; now X
             ld a,l
             ld (Move_Y_f),a
             ld (Move_Y),a            ; now Y
             
             xor b
             ld a,(Move_sq_t)
             call ObtainHLboardBySq
             ld d,(hl)
             ld (hl),b
             ld c,a
             call DrawSquare          ; now empty while moving                         
             call GetHLbySquare       ; set X,Y
             ld a,d
             ld (MovePc_t),a
             ld a,h
             ld (Move_X_t),a          ; to
             ld a,l
             ld (Move_Y_t),a
             
             ld a,25                  ;25ticks
             ld (AnimI),a             ;counter
             
             call AnimGetDXDY         ; calculate dx,dy
                         
             call Save26squaresVRAM   ; saving path of piece to draw without defects
             
             pop hl
             pop de
             pop bc
             pop af
             ret            

ANIMATION:
             push af
             ld a,(AnimI)
             cp 0
             jr z, AnimNONE ;if No animation
             
             push bc
             push de
             push hl
             
             call RestoreIsquareFromVRAM ;prepares and draws animation square
             call GetNewAnimXY ; next X,Y
                          
             ld a,(AnimI)
             dec a
             ld (AnimI),a
             cp 0
             jr nz, AnimTickOver  ;On counter=0 animation is over
             
             call RestoreIsquareFromVRAM ;restore last
             
             ld a,(MovePc_f)
             ld c,a
             ld a,(Move_sq_f)
             call ObtainHLboardBySq
             ld (hl),c
             
             ld a,(MovePc_t)
             ld c,a
             ld a,(Move_sq_t)
             call ObtainHLboardBySq
             ld (hl),c

             ld a,(Move_Cstl)
             
             cp 2
             jr z,wasCastleAnim
                         
             ld a,(AnimUnMk)
             cp 0
             jr nz,AnimUnMakeCase
                                                    
             call Chess_Move_Real          ; does actual chess movements
             jr Anim_enp_too
             
wasCastleAnim:
             ld a,0
             ld (Move_Cstl),a              ; after castling rook has made its move
             jr AnimTickOver
AnimUnMakeCase:
             call Chess_Unmake_Move_Real   ; does actual chess undo movements
Anim_enp_too:          
             ld a,(Move_Enp)
             cp 0
             jr z,AnimNoEnpRedraw
             push bc
             ld c,a
             call DrawSquare      ; remove en-passant piece visually
             pop bc             
AnimNoEnpRedraw:

setCastleAnim:
             ld a,(Move_Cstl)
             cp 0
             jr z,AnimTickOver
             inc a            
             ld (Move_Cstl),a
             ld a,(MvC_sq_f2)
             ld (Move_sq_f),a
             ld a,(MvC_sq_t2)
             ld (Move_sq_t),a
             call setAnimation  ; set new animation for rook now
             
        
AnimTickOver:
             pop hl             
             pop de
             pop bc
AnimNONE:    pop af
             ret                              
             
;---------------------------------------------
;determine HL by square number in a-reg
ObtainHLboardBySq:           
             push af
             push bc
             ld hl,BOARD
             ld c,a
             ld b,0
             add hl,bc
             pop bc
             pop af
             ret
             
;---------------------------------------------
; determine DX,DY step for animated piece                                                                     
AnimGetDXDY:

             ld a,(Move_X_f)
             ld b,a             
             ld a,(Move_X_t)
             cp b
             jr z,AnimDX0
             jr c,decAnimDX ;if toX<fromX
                                                                
             ld a,(Move_sq_f)
             and 7
             ld c,a
             ld a,(Move_sq_t)
             and 7
             sub c            ; a = dx
             ld (Move_DX),a
             ld a,0
             ld (Move_DXn),a
             jr AnimGetDY
decAnimDX:               
             ld a,(Move_sq_t)
             and 7
             ld c,a
             ld a,(Move_sq_f)
             and 7
             sub c            ; a = -dx
             ld (Move_DX),a
             ld a,1
             ld (Move_DXn),a
             jr AnimGetDY           
AnimDX0:
             ld a,0
             ld (Move_DX),a
             ld (Move_DXn),a
AnimGetDY:             
             ld a,(Move_Y_f)
             ld b,a             
             ld a,(Move_Y_t)
             cp b
             jr z,AnimDY0
             jr c,decAnimDY ;if toY<fromY
             
             ld a,(Move_sq_f)
             srl a
             srl a
             srl a
             ld c,a
             ld a,(Move_sq_t)
             srl a
             srl a
             srl a
             sub c            ; a = -dy
             ld (Move_DY),a
             ld a,1
             ld (Move_DYn),a
             jr AnimGetDXover            
             
decAnimDY:
             ld a,(Move_sq_t)
             srl a
             srl a
             srl a
             ld c,a
             ld a,(Move_sq_f)
             srl a
             srl a
             srl a
             sub c            ; a = dy
             ld (Move_DY),a
             ld a,0
             ld (Move_DYn),a
             jr AnimGetDXover
AnimDY0:
             ld a,0
             ld (Move_DY),a
             ld (Move_DYn),a
             
AnimGetDXover:
             ret


;---------------------------------------------
;
; Sets new X,Y on animation tick
;
GetNewAnimXY:
             push af
             push bc
             push de
             
             ld a,(Move_X)
             ld d,a
             ld a,(Move_Y)
             ld e,a
                              ; determine new X
             ld a,(Move_DX)
             ld b,a           ; save dx
             ld a,(Move_DXn)
             cp 1
             jr z,decAnimXmv
             ld a,d
             add a,b          ; new X=X+dx
             jr newXforAnim
decAnimXmv:               
             ld a,d
             sub b            ; new X=X-dx            
newXforAnim:             
             ld (Move_X),a
                              ; determine new Y
                              
             ld a,(Move_DY)
             ld b,a           ; save dy
             ld a,(Move_DYn)
             cp 1
             jr z,decAnimYmv
             ld a,e
             add a,b          ; new Y=Y+dy
             jr newYforAnim                              
decAnimYmv:               
             ld a,e
             sub b            ; new Y=Y-dy 
newYforAnim:
             ld (Move_Y),a
             pop de
             pop bc
             pop af
             ret
            
;----------------------------------------------------|
;
;  Draws board on screen.
;  
;
DrawBoard:
         push af
         push bc
         call SetSqScan          ; draw order A8,...,H8,A7...,A1,...,H1
         ld b,64
DrawBoScan:
         call ScanSqNxt
         call GetScanSQ
         ld c,a                  ; current square
         call DrawSquare
         djnz DrawBoScan        ; scan all squares
         pop bc
         pop af
         ret

;
;  Draws piece or just empty square by 
;       square in C-reg [0..63]
;
DrItFl: .byte 0     ;should draw anyway flag

DrawSquare:
         push af
         push bc
         push de
         push hl
         push ix
         ld b,0
         ld hl,BOARD
         add hl,bc
         ld a,(hl)
         cp 0
         jr nz, notE0_
         ld a,' '
notE0_:  call GetHLbySquare       ; set X,Y
         call GetWhiteSqFlagInE   ; and determine E flag     
         call GetPieceIdx    ; convert to index from pn..QK
         ld c,a              ; c=index
         ex de,hl            ; de = hl
                 
         ld a,(DrItFl)
         cp 1
         jr z,pc2VRAM1       ; should draw anyway     
         
         ld hl,VRAMcopy
         ld b,0
         add hl,bc         
         ld a,(hl)       
         cp 1
         jr z,pc2VRAM2       ; if saved before, just copy
                             ; else create bitmap
pc2VRAM1:                                       
         ;DRAW and SAVE a copy                
         ld a,1
         ld (hl),a           ; bitmap saved flag
         ex de,hl            ; hl = X,Y
         ld a,c              ; index of piece or square
         call GetPieceIX     ; get ix-address
         ld de,$1A1A         ;26x26
         call HMMC           ;copy RAM -> VRAM
         
         call SaveMaskToo    ; save MASK on first init
         
         ld a,(DrItFl)
         cp 1
         jr z,overDrawSqPc   ; if draws empty board 
         
         ex de,hl            ; de = hl
         
         ld hl,VRAMcpXY      ; save X,Y for piece index
         ld b,0
         add hl,bc
         add hl,bc         
         ld (hl),d           ;save X
         inc hl
         ld (hl),e           ;save Y
         
         call COPY2VRAMoutside
          
         jr overDrawSqPc
             
pc2VRAM2:         
         ;COPY piece back to square
         
         ld hl,VRAMcpXY      ; get X,Y by piece index
         ld b,0
         add hl,bc
         add hl,bc         
         ld a,(hl)           ;saved X
         ld (HC_p+0),a       ;X
         inc hl
         ld a,(hl)           ;saved Y
         ld (HC_p+2),a       ;Y

         ld a,d
         ld (HC_p+4),a       ;to X   
         ld a,e
         ld (HC_p+6),a       ;to Y
         ld a,$19
         ld (HC_p+8),a       ;25
         ld (HC_p+10),a      ;25
         xor a
         ld (HC_p+1),a        
         ld (HC_p+5),a       ;X
         ld (HC_p+7),a       ;Y
         ld (HC_p+9),a       ;dots
         ld (HC_p+11),a      ;dots
         ld (HC_p+12),a      ;DIX/DIY
         ld a,%00000001
         ld (HC_p+3),a       ;256+Y
         call HMMMf          ;copy VRAM -> VRAM to visible area        

overDrawSqPc:         
         pop ix
         pop hl
         pop de
         pop bc
         pop af
         ret
         
;-------------------------------------------------
;
;
; Saving 26 squares in VRAM as background for
;      moving piece all way long
;
Save26squaresVRAM:
         push af
         push bc
         push de
         
         ld a,(Move_X)
         ld d,a
         ld a,(Move_Y)
         ld e,a
         push de             ; save X,Y                            
         
         ld b,26
         ld de,0
Loop26squares:
         di                 
         ld a,(Move_X)       ;X
         sub 4               ;X-4   reserve
         ld (HC_p+0),a
         ld a,(Move_Y)       ;Y
         sub 4               ;Y-4
         ld (HC_p+2),a
         
         call GetNewAnimXY   ; new X,Y
                  
         ld a,d
         ld (HC_p+4),a       ;to X
         ld a,e
         ld (HC_p+6),a       ;to Y (+next byte)   put in columns
         ld a,$20
         ld (HC_p+8),a       ;32
         ld (HC_p+10),a      ;32
         xor a         
         ld (HC_p+1),a       ;X
         ld (HC_p+3),a       ;Y
         ld (HC_p+5),a       ;
         ld (HC_p+9),a       ;dots
         ld (HC_p+11),a      ;dots
         ld (HC_p+12),a      ;DIX/DIY
         ld a,%00000011
         ld (HC_p+7),a       ; 512+Y down
         call HMMMf          ;copy VRAM -> VRAM outside visible screen
         
         ld a,$20
         add a,e
         ld e,a
         cp $20*6
         jr nz,L26clmnNxt
         ld e,0             ; next column
         ld a,$20
         add a,d
         ld d,a
         ei
L26clmnNxt:
         djnz Loop26squares     
         
         pop de             ; restore X,Y
         ld a,d
         ld (Move_X),a
         ld a,e
         ld (Move_Y),a
        
         pop de
         pop bc
         pop af
         ret

;
; This: 1) copies background (1..26 saved before) to VRAM-holder
;       2) copies mask of piece logically to VRAM-holder
;       3) copies holder to board on display
;


RestoreIsquareFromVRAM:
         push af
         push bc
         push de
         
         ld a,(AnimI)
         ld b,a
         ld a,25
         sub b
         
         ld b,a              ; counter I = 0..25
         ld de,0  
         cp 0
         jr z,L2_26theSq
Loop26SqToFindXY:

         ld a,$20
         add a,e
         ld e,a
         cp $20*6
         jr nz,L2_26clmnNxt
         ld e,0             ; next column
         ld a,$20
         add a,d
         ld d,a
L2_26clmnNxt:
         djnz Loop26SqToFindXY
L2_26theSq:                             
         call Back2Holder     ; put backgroound in holder
         
         call DrawAnimPiece   ; draws animation piece to holder (mask with transp.)
         
         call Holder2Screen   ; put holder on board in right place

         pop de
         pop bc
         pop af
         ret

;----------------------------------
; Puts background in holder

Back2Holder:
         di
         ld a,d
         ld (HC_p+0),a
         ld a,e
         ld (HC_p+2),a
         ld a,255-$20
         ld (HC_p+4),a       ;to X
         ld a,209-$20
         ld (HC_p+6),a       ;to Y (+next byte) in column
         ld a,$20
         ld (HC_p+8),a       ;32
         ld (HC_p+10),a      ;32
         xor a         
         ld (HC_p+1),a       ;X
         ld (HC_p+5),a       ;
         ld (HC_p+9),a       ;dots
         ld (HC_p+11),a      ;dots
         ld (HC_p+12),a      ;DIX/DIY
         ld a,%00000001
         ld (HC_p+7),a       ; 256+Y down
         ld a,%00000011
         ld (HC_p+3),a       ; 512+Y down
         call HMMMf          ;copy VRAM -> VRAM outside visible screen
         ei
         ret
                  
;------------------------------------------------------
;
; Prepares mask of piece in VRAM holder on background
;
;                  
DrawAnimPiece:
                          
             ;COPY mask of piece (logical VRAM->VRAM)
             di        
             ld a,(MovePc_f)
             cp 0
             jr nz,DrawAnimNormPiece
             ld a,(MovePc_t)        ;castling rook moving
DrawAnimNormPiece:             
             ld e,0
             call GetPieceIdx       ;get index of piece
             srl a
             dec a
             ld c,a
             ld hl,VRAMcpMskXY      ; get X,Y by piece index             
             ld b,0
             add hl,bc              ; offset
             add hl,bc
                                   
             ld a,(hl)           ;saved X
             ld (LM_p+0),a       ;X
             inc hl
             ld a,(hl)           ;saved Y        
             ld (LM_p+2),a       ;Y

             ;ld a,(Move_X)
             ld a,255-$20+4
             ld (LM_p+4),a       ;to X   
             ;ld a,(Move_Y)
             ld a,209-$20+4
             ld (LM_p+6),a       ;to Y
             ld a,$19
             ld (LM_p+8),a       ;25
             ld (LM_p+10),a      ;25
             xor a
             ld (LM_p+1),a
             ;ld (LM_p+7),a       
             ld (LM_p+5),a       ;Y
             ld (LM_p+9),a       ;dots
             ld (LM_p+11),a      ;dots
             ld (LM_p+12),a      ;DIX/DIY
             ld a,%00000001
             ld (LM_p+3),a       ;256+Y
             ld a,%00000001
             ld (LM_p+7),a       ;256+Y
             ld a,%00001000      ;TIMP copy
             ld (LM_p+13),a      ;logical
             call LMMMf          ;copy VRAM -> VRAM without transparent color
                                 ;to visible area
             ei                                 
             ret

;----------------------------------
; Puts holder on board

Holder2Screen:                             ; draw holder to screen with piece
         di
         ld a,255-$20                
         ld (HC_p+0),a
         ld a,209-$20
         ld (HC_p+2),a
         ld a,(Move_X)
         sub 4               ;X-4
         ld (HC_p+4),a       ;to X
         ld a,(Move_Y)
         sub 4               ;Y-4
         ld (HC_p+6),a       ;to Y (+next byte)
         ld a,$20
         ld (HC_p+8),a       ;32
         ld (HC_p+10),a      ;32
         xor a         
         ld (HC_p+1),a       ;X
         ld (HC_p+5),a       ;
         ld (HC_p+7),a       ;         
         ld (HC_p+9),a       ;dots
         ld (HC_p+11),a      ;dots
         ld (HC_p+12),a      ;DIX/DIY
         ld a,%00000001
         ld (HC_p+3),a       ;from holder 256+Y down
         call HMMMf          ;copy VRAM -> VRAM
         ei
         ret
                                   
;-------------------------------------------------
;
;BOARD copying to third screen
; Fast but takes much VRAM.
; Not used but working. It is sick to use VRAM like this.
;-------------------------------------------------
COPY2VRAMoutside:
         ld a,d              ;X
         ld (HC_p+0),a
         ld (HC_p+4),a       ;to X
         ld a,e              ;Y
         ld (HC_p+2),a
         ld (HC_p+6),a       ;to Y (+next byte)
         ld a,$19
         ld (HC_p+8),a       ;25
         ld (HC_p+10),a      ;25
         xor a         
         ld (HC_p+1),a       ;X
         ld (HC_p+3),a       ;Y
         ld (HC_p+5),a       ;
         ld (HC_p+9),a       ;dots
         ld (HC_p+11),a      ;dots
         ld (HC_p+12),a      ;DIX/DIY
         ld a,%00000001
         ld (HC_p+7),a       ; 256+Y down
         call HMMMf          ;copy VRAM -> VRAM outside visible screen
         ret
          
; calculates HL screen coordinates X,Y by square number
; provide square in c-reg
GetHLbySquare:
         push af
         push bc
         push de
         ld hl,$05D2-$0005-$0019
         ld a,c
         and 7
              ; X- a..h of table
         ;cp 2
         ;jp c,GetHLx_
         ;push bc
         ;ld bc,$0100
         ;add hl,bc      ; one pixel visal correction to the right
         ;pop bc
GetHLx_:         
         ld de,$1900
GetHLbySqX:
         cp 0
         jr z,GetHLokSqX
         add hl,de
         dec a
         jr GetHLbySqX        
GetHLokSqX:
         ld a,c
         srl a
         srl a
         srl a
              ; Y- 1..8 of table
         ld de,$0019
GetHLbySqY:
         cp 0
         jr z,GetHLokSqY
         scf
         ccf
         sbc hl,de
         dec a
         jr GetHLbySqY        
GetHLokSqY:
         pop de
         pop bc
         pop af
         ret
         
; calculates white square in e-reg flag by square number (a-reg)
GetWhiteSqFlagInE:
         push af
         ld a,c
         and 7
         ld e,a    ; X- a..h of table
         
         ld a,c
         srl a
         srl a
         srl a
                   ; Y- 1..8 of table
         add a,e
         and 1     ;mod2
         ld e,a    ; contains flag
         pop af
         ret
                  
;----------------------------------------------------|
         ; locates index in array of pieces datas
         ; a-piece char of p..K
         ; e - square is white flag
         ; on return a contains index
                                
GetPieceIdx:
         push bc
         push de
         push hl
         ld hl,pieceL
         ld b,13
         ld d,0
GetPcIxLoop:
         cp (hl)
         jr z,GetPcIx1
         inc hl
         inc d
         djnz GetPcIxLoop               
GetPcIx1:
         sla d  ; x2
         ld a,e ;black or white square?; 
         add a,d
         pop hl
         pop de
         pop bc
         ret        

pieceL:  .byte " PNBRQKpnbrqk"

         ;and position IX after
GetPieceIX:
         push bc
         push hl
         ld b,0
         ld c,a
         sla c    ; offset
         ld ix, PiecesIX
         add ix,bc
         ld l,(ix)
         inc ix
         ld h,(ix)
         push hl
         pop ix   ;now IX contains address
         pop hl
         pop bc
         ret

         ;to determine IX for mask
GetPieceMskIX:
         push bc
         push hl
         ld b,0
         ld c,a
         sla c
         ld ix, PiecesMskIX     ; offset of masks
         add ix,bc
         ld l,(ix)
         inc ix
         ld h,(ix)
         push hl
         pop ix   ;now IX contains address
         pop hl
         pop bc
         ret

; This copie mask of piece to VRAM
SaveMaskToo:
         push af         ; and save the mask of piece too - to see it moving after
         push bc
         push de
         push hl
         push ix
         ld a,c
         cp 2
         jr c, pcMsk2VRAMno
         srl a
         dec a           ; a = index PpNn....Kk      
         ld c,a
         ld b,0
         ld hl,VRAMcpMsk
         add hl,bc       ; hl contains flag if piece has been saved to VRAM
         ld a,(hl)
         cp 1
         jr z,pcMsk2VRAMno
         ld a,1
         ld (hl),a       ; now will be saved
         ld a,c
         call GetPieceMskIX  ; get ix-address for mask
         ld de,$1A1A         ;26x26
         ld h,$10 + $19*3
         ld l,$10
         ld a,c
         cp 6                ;for PNBRQK 0..5
         jr c,pcMskSetY
         ld a,h
         add a,$19           ; set next column for black pieces
         ld h,a
         ld a,c
         sub 6
pcMskSetY:         
         cp 0
         jr z,pcMskGoodY
         dec a
         push af
         ld a,l
         add a,$19
         ld l,a
         pop af
         jr pcMskSetY
pcMskGoodY:
         call HMMC           ;copy mask RAM -> VRAM                  

         ex de,hl            ; de = hl
         ld hl,VRAMcpMskXY   ; save X,Y for mask of piece index
         ld b,0
         add hl,bc
         add hl,bc         
         ld (hl),d           ;save X
         inc hl
         ld (hl),e           ;save Y
         
         call COPY2VRAMoutside
         
pcMsk2VRAMno:        
         pop ix
         pop hl
         pop de
         pop bc
         pop af
         ret

VRAM_msx .byte 0  ; flag that VRAM contains it

; Puts MSX logo on screen
PutMSXlogo:
         push af
         push bc
         push de
         push hl
         push ix
         
         ld a,(VRAM_msx)
         cp 0
         jr nz,PutMSXlog_Copy
                 
         ld h,255-$22
         ld l,209-$22
         ld de,$1E0C
         ld ix, dtMSXlogo+6     ; top
         call HMMC              ;copy RAM -> VRAM
         ld c,0
         call COPY_frames2VRAM_outside ;the same as for frame  
         
         ld a,1
         ld (VRAM_msx),a
         jr PutMSXex
                  
PutMSXlog_Copy:
         ld h,255-$22
         ld l,209-$22
         ld de,$1E0C            ; copy from VRAM outside > VRAM on screen
         ld c,0
         call COPY_frames_fromVRAM
         
PutMSXex:                                                                                                                                                        
         pop ix
         pop hl
         pop de
         pop bc        
         pop af
         ret                  

         
; Puts frame for chess board
PutFrame:
         push af
         push bc
         push de
         push hl
         push ix
         ld a,(VRAM_frame)
         cp 0
         jr nz,CopyFramesFromVRAM
                   ; DRAW and SAVE
         ld hl,0
         ld de,$D208
         ld ix, dtFRUP+6     ; top
         call HMMC           ;copy RAM -> VRAM
         ld c,1
         call COPY_frames2VRAM_outside

         ld hl,0
         ld de,$08D2
         ld ix, dtFRLF+6     ; left
         call HMMC           ;copy RAM -> VRAM
         ld c,2
         call COPY_frames2VRAM_outside

         ld hl,$D200-$0800
         ld de,$08D2
         ld ix, dtFRRT+6     ; right
         call HMMC           ;copy RAM -> VRAM
         ld c,0
         call COPY_frames2VRAM_outside
         
         ld hl,$00D2-$0008
         ld de,$D208
         ld ix, dtFRDN+6     ; bottom
         call HMMC           ;copy RAM -> VRAM
         ld c,0
         call COPY_frames2VRAM_outside
         
         ld a,1
         ld (VRAM_frame),a
         
         jr PutFramesEx
         
CopyFramesFromVRAM:
         ld hl,0
         ld de,$D208         ; top
         ld c,1         
         call COPY_frames_fromVRAM

         ld hl,0
         ld de,$08D2         ; left 
         ld c,2           
         call COPY_frames_fromVRAM

         ld hl,$D200-$0800
         ld de,$08D2         ; right
         ld c,0         
         call COPY_frames_fromVRAM
         
         ld hl,$00D2-$0008
         ld de,$D208         ; bottom
         ld c,0         
         call COPY_frames_fromVRAM

PutFramesEx:
         pop ix
         pop hl
         pop de
         pop bc
         pop af
         ret

VRAM_frame:  .byte 0         ; 1 if frame saved to VRAM

; if c=0 then use XY of HL as it is
; if c=1 then upper border of frame
; if c=2 then left border of frame
COPY_frames2VRAM_outside:     ;SAVES FRAME
         push af
         push hl
         ld a,h
         ld (HC_p+0),a       ;X = H
         ld a,l            
         ld (HC_p+2),a       ;Y = L
         ld a,d
         ld (HC_p+8),a       ;D width
         ld a,e
         ld (HC_p+10),a      ;E height
         xor a        
         ld (HC_p+1),a       ;X
         ld (HC_p+3),a       ;Y
         ld (HC_p+5),a       ;
         ld (HC_p+9),a       ;dots
         ld (HC_p+11),a      ;dots
         ld (HC_p+12),a      ;DIX/DIY
         ld a,%00000011
         ld (HC_p+7),a       ; 512+Y down
         
         ld a,c
         cp 1
         jr z,CPYfrUP
         cp 2
         jr z,CPYfrLF
         jr CPY_asItIs        
CPYfrUP:
         ld hl,$00D2+$0002
         jr CPY_asItIs
CPYfrLF:
         ld hl,$D200+$0200

CPY_asItIs:
         ld a,h
         ld (HC_p+4),a       ;to X
         ld a,l
         ld (HC_p+6),a       ;to Y (+next 2 bits)
         pop hl
         call HMMMf          ;copy VRAM -> VRAM outside visible screen
         pop af
         ret
         
COPY_frames_fromVRAM:        ;Copies back FRAME from VRAM
         push af
         push hl
         ld a,h
         ld (HC_p+4),a       ;to X
         ld a,l            
         ld (HC_p+6),a       ;to Y (+next 2 bits)
         ld a,d
         ld (HC_p+8),a       ;D width
         ld a,e
         ld (HC_p+10),a      ;E height
         xor a        
         ld (HC_p+1),a       ;X
         ld (HC_p+7),a       ;to Y
         ld (HC_p+5),a       ;
         ld (HC_p+9),a       ;dots
         ld (HC_p+11),a      ;dots
         ld (HC_p+12),a      ;DIX/DIY
         ld a,%00000011
         ld (HC_p+3),a       ; 512+Y down
         
         ld a,c
         cp 1
         jr z,BCPYfrUP
         cp 2
         jr z,BCPYfrLF
         jr BCPY_asItIs        
BCPYfrUP:
         ld hl,$00D2+$0002
         jr BCPY_asItIs
BCPYfrLF:
         ld hl,$D200+$0200

BCPY_asItIs:
         ld a,h
         ld (HC_p+0),a       ;X = H
         ld a,l
         ld (HC_p+2),a       ;Y = L
         pop hl
         call HMMMf          ;copy VRAM outside visible screen -> VRAM
         pop af
         ret

                
         
; Puts rounded identification about side to move

PutToMove:
         push af
         push bc
         push de
         push hl
         push ix
         
         ld ix,CircIX
                  
         ld a,(VRAMcirc)
         cp 0
         jr nz,circ2VRAM2
                                     
         ;DRAW and SAVE a copy                
         ld a,1
         ld (VRAMcirc),a     ; bitmap saved flag
         
         ld b,0       ; loop 4 bitmaps
         ld h,0       ; X
Save2VRAMsgnLoop:
         push bc
         
         push ix            ; table of bitmaps
         call GetIXfrom4tb  ; ix - address in VRAM for current bitmap
         
         ld l,209-$E    ; hl = X,Y
         
         ex de,hl       ; de = hl
         call COPY2VRAMoutside  ; copy blank to put sign on it with transp.logical                 
         ex de,hl                          
                                             
         ld de,$0E0E    ; 14x14
         call HMMC      ;copy RAM -> VRAM
    
         call SgCopy2VRAMtrsp  ;copies 13x13 (w/o transparent)
         
         pop ix
         inc ix
         inc ix
         
         ld a,h
         add a,$E       ; X=X+14
         ld h,a
         
         pop bc
         inc b
         ld a,b
         cp 4
         jr nz,Save2VRAMsgnLoop       
           
circ2VRAM2:         
         ;COPY sign from VRAM which side to move
         
         ld h,0                  ;from X for case "white to move" (bitmaps are placed horizontally)
         ld l,209-$E             ;from Y
         
         ld a,(SIDE)
         cp 0
         jr z,SgWhite2Move
         inc ix
         inc ix
         inc ix
         inc ix   ;will use two bitmaps at addr+4 
         ld h,$E+$E              ;from X for case "black to move"            
SgWhite2Move:
         
         push ix                 ; table of bitmaps
         call GetIXfrom4tb       ; ix - address in VRAM for current bitmap of white side
         
         ld d,204+6
         ld e,204-10
         
         call SgCopy2Board  ;white sign
         
         pop ix ; restore table of bitmaps
         inc ix
         inc ix ; to next bitmap pointer

         call GetIXfrom4tb  ; ix - address in VRAM for current bitmap of black side
         
         ld a,h
         add a,$E       ; X=X+14
         ld h,a
         
         ld e,8
         call SgCopy2Board  ;black sign
         
         pop ix
         pop hl
         pop de
         pop bc
         pop af
         ret

GetIXfrom4tb:
         push de
         ld e,(ix)
         inc ix
         ld d,(ix)
                  
         push de
         pop ix         ; ix - address in VRAM
         pop de
         ret

;Copy with logical transparent
SgCopy2VRAMtrsp: 
         
         ld a,h              ;X
         ld (LM_p+0),a       ;
         ld (LM_p+4),a       ;to X          
         ld a,l              ;Y
         ld (LM_p+2),a       ;
         ld (LM_p+6),a       ;to Y         
         ld a,$E
         ld (LM_p+8),a       ;14
         ld (LM_p+10),a      ;14
         xor a
         ld (LM_p+1),a
         ld (LM_p+5),a       ;
         ld (LM_p+3),a       ;            
         ld (LM_p+9),a       ;dots
         ld (LM_p+11),a      ;dots
         ld (LM_p+12),a      ;DIX/DIY
         ld a,%00000001
         ld (LM_p+7),a       ;256+Y
         ld a,%00001000      ;TIMP copy
         ld (LM_p+13),a      ;logical
         call LMMMf          ;copy VRAM -> VRAM without transparent color
         ret                 ;to invisible area          
         
SgCopy2Board:

         ld a,h              ;saved X
         ld (HC_p+0),a       ;X
         ld a,l              ;saved Y                      
         ld (HC_p+2),a       ;Y
         ld a,d         
         ld (HC_p+4),a       ;to X
         ld a,e         
         ld (HC_p+6),a       ;to Y (+next 2 bits)
         ld a,$E
         ld (HC_p+8),a       ;14
         ld (HC_p+10),a      ;14
         xor a        
         ld (HC_p+1),a       ;X
         ld (HC_p+7),a       ;to Y
         ld (HC_p+5),a       ;
         ld (HC_p+9),a       ;dots
         ld (HC_p+11),a      ;dots
         ld (HC_p+12),a      ;DIX/DIY
         ld a,%00000001
         ld (HC_p+3),a       ; 256+Y
         call HMMMf          ;copy VRAM outside visible screen -> VRAM on board                         
         ret


;----------------------------------------------------|
DrawCursor:              ; Draws cursor (UserControl)
         push af
         ld a,(Stylo)
         bit 0,a
         jr z,noCursors

         push bc
         push de
         push hl
         
         ld a,(DragSq)
         cp $ff
         jr z,DrawCursorOnly

         ld c,a             ; Draw DragSquare too
         call GetHLbySquare ; Get X,Y
              
         ld b,$E            ; color
         ld c,$16           ; length of lines
         call CursRectDraw  ; line
         
         ld bc,$0101
         add hl,bc          ; shift 1 dot right down

         ld b,$E            ; color
         ld c,$14           ; double-line
         call CursRectDraw
         
DrawCursorOnly:         
         ld a,(CursorSq)
         ld c,a
         call GetHLbySquare ; Get X,Y
              
         ld b,$F            ; color
         ld c,$16           ; length of lines
         call CursRectDraw  ; line
         
         ld bc,$0101
         add hl,bc          ; shift 1 dot right down

         ld b,$F            ; color
         ld c,$14           ; double-line
         call CursRectDraw
         
         pop hl         
         pop de
         pop bc
noCursors:         
         pop af
         ret

CursRectDraw:               ; rectangle with length provided in c, color in b        
         ld a,h
         add a,c
         ld d,a             ; X+25
         ld e,l             ; Y
         ld a,0             ; just overwrite
         call LINE          ; Line 1
         ld h,d
         ld a,e
         add a,c
         inc a
         inc a
         ld e,a
         ld a,0             ; just overwrite
         call LINE          ; Line 2
         ld l,e
         ld a,d
         sub c
         ld d,a
         ld a,0             ; just overwrite
         call LINE          ; Line 3
         ld h,d
         ld a,e
         sub c
         dec a
         dec a
         ld e,a
         ld a,0             ; just overwrite
         call LINE          ; Line 4
         ld l,e             ; hl now the same        
         ret

;------------------------------------------------------
; KEY & CURSOR CONTROLLER
;
; a-reg contains ASCII code of last key pressed
; Arrows controls for cursor.
; Can't go outside board,
; Can't go twice (avoid fast emulator speed)
;

    .byte "KEYDEBUG"

PreKeyWas:  .byte 0

Cursor_Key_Controls:

         push af
         push bc
         
         cp 'z'             ; If Z was pressed, double action
         jr nz, CkeyIf_z
CkeyZ:         
                            ; use the same key that was before
         ld a,(PreKeyWas)
         ld c,a
         ld a,0
         ld (PreKeyWas),a
         ld a,c
         jr CkeyWhatKeyCode         
CkeyIf_z:
         cp 'Z'
         jr z, CkeyZ
         cp '/'
         jr z, CkeyZ
         cp '~'
         jr z, CkeyZ
         cp '|'
         jr z, CkeyZ     ; bunch of the same keys
CkeyNormal:
    
         ld c,a
         ld a,(PreKeyWas)
         cp c
         jr z,CkeyNo       ; the same, emulator may be too fast
         ld a,c
         ld (PreKeyWas),a  ; key now
         
CkeyWhatKeyCode:
         cp 27
         jr nz, CkeyIf_space      
         
         ld a,1                     ; Exit on ESC
         ld (Grph_Exit),a
     
         jr CkeyNo
                  
CkeyIf_space:                  
         cp 32
         jr nz, CkeyIfEnter
CkeySpace:                         ; SPACE pressed
         call CKeySpacePressed
         jr CkeyNo
         
CkeyIfEnter:
         cp 13
         jr z, CkeySpace           ; the same as space
          ;and process other key controls
                                  
         call IfCursorKeys       ; process if cursor key has been pressed

CKeyPsetup:

#ifdef PGN_COMPILE

         nop
         nop
         nop
#else
         
         call IfPieceSetupKeys   ; process if setup of pieces key has been pressed
#endif
 
         cp 'u'             ; If U was pressed, try undomove
         jr nz, CkeyIf_u
CkeyU:         
                            ; use the same key that was before

#ifdef PGN_COMPILE

         call DO_Replay_UnmakeMove   ; unmake last move in replay
#else
         ld a,(Stylo)
         bit 0,a
         jr z,CkeyNo        ; if cursor allowed
         call Chess_UnMake_Move_U    ; unmake last move
#endif
         jr CkeyNo
CkeyIf_u:
         cp 'U'
         jr z, CkeyU
         
CkeyIfNoU:

CkeyNo:
         pop bc
         pop af
         ret 

        
;-------------------- If space key pressed -the long one
CKeySpacePressed:         
         push af
         ld a,(Stylo)
         
#ifdef PGN_COMPILE 
         
         call DO_Replay_Move            ; if REPLAY mode

#else         
         
         bit 0,a                   ; if cursor is not allowed 
         jr z,CSpcOver
                  
         bit 2,a                   ; if setup of pieces then empty square
         jr z,CSpcNPS
         ld a,' '
         call IfPieceSetupKeys     ; process if setup of pieces key has been pressed
         jr CSpcOver
CSpcNPS:         
         bit 1,a                   ; if can not drag and move pieces 
         jr z,CSpcOver

         ld a,(AnimI)
         cp 0
         jr nz,CSpcOver            ; animation process right now
         ld a,(DragSq)
         cp $ff
         jr nz, CDragWas
CSpcDragz:         
         ld a,0
         call IsValidDragMove
         cp 0
         jr z, CSpcOver           ; if drag not valid
                  
         ld a,(CursorSq)
         ld (DragSq),a
         jr CSpcOver
         
CSpcTryDrag:
         call DrawBoard       ; redraw all
         jr CSpcDragz        
         
CDragWas:
         ld (Move_sq_f),a
         ld a,1
         call IsValidDragMove
         push af
         ld a,$ff
         ld (DragSq),a
         pop af
         cp 0
         jr z, CSpcTryDrag      ; if move not valid

         ld a,(CursorSq)
         ld (Move_sq_t),a
         
         call Chess_Move_Cursor          ; this will set animation and do the move
CSpcOver:
         call DrawCursor
         
#endif         
         pop af
         ret         
         
;---------------------------------
; If cursor arrow keys pressed
;
IfCursorKeys:

         push af     
         cp 29
         jr nz, CkeyIfCurs2
                                   ; LEFT pressed                                 
         ld a,(CursorSq)
         ld c,a                                   
         and 7
         cp 0
         jr z,CkeyCKexit
         ld a,c
         call DrawSquare
         dec a
         
CKeyCursMv:
         ld (CursorSq),a
         call DrawCursor
         jr CkeyCKexit

CkeyIfCurs2:  
         cp 28
         jr nz, CkeyIfCurs3                                       
                                   ; RIGHT pressed                                      
         ld a,(CursorSq)
         ld c,a         
         and 7
         cp 7
         jr z,CkeyCKexit
         ld a,c
         call DrawSquare
         inc a         
         jr CKeyCursMv

                                                                                                              
CkeyIfCurs3:
         cp 30
         jr nz, CkeyIfCurs4                                       
                                   ; UP pressed                                   
         ld a,(CursorSq)
         ld c,a                                           
         srl a
         srl a
         srl a
         cp 7
         jr z,CkeyCKexit
         ld a,c
         call DrawSquare
         add a,8                 
         jr CKeyCursMv
                                    
CkeyIfCurs4:
         cp 31
         jr nz, CkeyCKexit                                      
                                   ; DOWN pressed                                   
         ld a,(CursorSq)
         ld c,a                                           
         srl a
         srl a
         srl a
         cp 0
         jr z,CkeyCKexit
         ld a,c
         call DrawSquare
         sub 8        
         jr CKeyCursMv
         
CkeyCKexit:
         pop af         
         ret

;---------------------------------
; If piece keys PNBRQK pressed
;
IfPieceSetupKeys:
         push af
         push bc
         push de
         push hl
         ld b,a   ;save code
         cp 'C'
         jr z,CHideCurs
         cp 'c'
         jr z,CHideCurs
         jr CskpCursRmv
CHideCurs:
         call DrawBoard
         jr CsetupDoNothing
CskpCursRmv:   
         cp 'P'
         jr z,CsetupWP
         cp 'N'
         jr z,CsetupWN
         cp 'B'
         jr z,CsetupWB
         cp 'R'
         jr z,CsetupWR
         cp 'Q'
         jr z,CsetupWQ
         cp 'K'
         jr z,CsetupWK
         cp 'p'
         jr z,CsetupBP
         cp 'n'
         jr z,CsetupBN
         cp 'b'
         jr z,CsetupBB
         cp 'r'
         jr z,CsetupBR
         cp 'q'
         jr z,CsetupBQ
         cp 'k'
         jr z,CsetupBK
         cp ' '
         jr z,CsetupBlank
         jr CsetupDoNothing
CsetupWP:
CsetupBP:
         ld a,(CursorSq)
         cp 8
         jr c,CsetupKexit
         cp 56
         jr nc,CsetupKexit
         jr Csetup2        
CsetupWN:
CsetupWB:
CsetupWR:
CsetupWQ:
CsetupBN:
CsetupBB:
CsetupBR:
CsetupBQ:
         jr Csetup2
CsetupWK:
         ld a,(WKSQ)
         cp $ff
         jr z,Csu2WK
         call CsuKRmv    ; White king not here anymore
Csu2WK:  jr Csetup2


CsetupBK:
         ld a,(BKSQ)
         cp $ff
         jr z,Csu2BK
         call CsuKRmv    ; Black king not here anymore
Csu2BK:  jr Csetup2
         
CsetupDoNothing:
         jr CsetupKexit  ; exit

CsetupBlank: ld b,0 ; will be empty square

Csetup2:               ;puts new piece on board or clears square
         ld a,(CursorSq)
         call ObtainHLboardBySq
         ld c,a
         ld a,(WKSQ)
         cp c
         jr nz,CsuNoOverWK
         ld a,$ff
         ld (WKSQ),a
         jr CsuOverK       
CsuNoOverWK:       
         ld a,(BKSQ)
         cp c
         jr nz,CsuOverK
         ld a,$ff
         ld (BKSQ),a

CsuOverK:     
         ld a,b
         cp 'K'
         jr nz, CsuNoWKnwpos
         ld a,c
         ld (WKSQ),a
         jr CsuOverK2
CsuNoWKnwpos:
         cp 'k'
         jr nz, CsuOverK2
         ld a,c
         ld (BKSQ),a
CsuOverK2:
         ld a,b
         ld (hl),b          ; new piece or empty square here
         cp 0
         jr z,CsuNSd
         cp 'Z'
         jr nc,CsetupBlackPc
         ld a,0
         jr CsuSDm
CsetupBlackPc:         
         ld a,1
CsuSDm:  ld (SIDE),a
CsuNSd:  call PutToMove
         ld a,c        
         call DrawSquare
         call RecalcCastles ;what castlings are possible?
         call DrawCursor
         ld de,wasSetUpFEN
         call GetFEN        ;keeps actual FEN for position
CsetupKexit:
         pop hl         
         pop de
         pop bc
         pop af
         ret

; this is used for kings to remove them from board
CsuKRmv: push af
         push bc
         push hl
         ld c,a
         call ObtainHLboardBySq
         ld a,0
         ld (hl),a
         ld a,c
         call DrawSquare ; empty square now         
         pop hl
         pop bc
         pop af
         ret
;
; this calculates maximum possible castling and sets flags
; otherwise movements may not work normally
; 
RecalcCastles:
         push af
         push af
         push hl
         ld b,0         ; new flags for castlings
         ld a,(WKSQ)
         cp 4
         jr nz,RclcBlack
         ld a,7
         call ObtainHLboardBySq
         ld a,(hl)
         cp 'R'
         jr nz,RclnWr1
         set 0,b
RclnWr1: ld a,0
         call ObtainHLboardBySq
         ld a,(hl)
         cp 'R'
         jr nz,RclcBlack
         set 1,b
RclcBlack:
         ld a,(BKSQ)
         cp 60
         jr nz,RclcOver
         ld a,63
         call ObtainHLboardBySq
         ld a,(hl)
         cp 'r'
         jr nz,RclnBr1
         set 2,b
RclnBr1: ld a,56
         call ObtainHLboardBySq
         ld a,(hl)
         cp 'r'
         jr nz,RclcOver
         set 3,b
RclcOver:
         ld a,b
         ld (CASTLES),a
         pop hl
         pop bc
         pop af
         ret                                                                                                                                                      


;---------------------------------
; Redraw squares around.
; Intended for large cursor
; Not used, as DrawCursor does the same.
;---------------------------------
_AsqDirc: .byte '-',9,'-',8,'-',7,'-',1,'=',0,'+',1,'+',7,'+',8,'+',9

RedrawSquaresAround:

         push af
         push bc
         push de
         push hl
         ld hl,_AsqDirc
         ld b,9
         ld c,a
ArndSqScan
         ld a,(hl)
         inc hl
         cp '-'
         jr z,ArndSqDec
         ld a,(hl)
         add a,c
         cp 63
         jr c,ArndSqNo
         jr ArndSqYes                 
ArndSqDec:         
         ld d,(hl)
         ld a,c
         sub d
         jr c,ArndSqNo
ArndSqYes:         
         call DrawSquare   ; if square on board then redraw
ArndSqNo:
         ld a,c
         inc hl
         djnz ArndSqScan
         pop hl
         pop de
         pop bc
         pop af
         ret

         
;-----------------------------------------------------------
;
; Process replay of one move
;
;-----------------------------------------------------------
DO_Replay_Move:
         push af
         push bc
         push de
         push hl
                  
         ld de, MOVE_str
         ld a,(RplyMs)
         ld b,a
         cp 0
         jr z,RplyTo0
RplyLoopMv:
         inc de
         inc de
         inc de
         inc de
         ld a,(de)
         cp 32
         jr z,RplyNskp1
         inc de          ;skip promotion
RplyNskp1:
         inc de         
         ld a,(de)
         cp 32
         jr z,RplyNoMv
         cp 0
         jr z,RplyNoMv
         cp '$'
         jr z,RplyNoMv

         djnz RplyLoopMv
RplyTo0:
         call MbyStrMove           ; move
         call DrawBoard            ; no animation, sorry
         call PutToMove
         call GenMoves             ; use GenMovesAndString to see
         
         ld a,(RplyMs)
         inc a
         ld (RplyMs),a
RplyNoMv:
         pop hl       
         pop de
         pop bc
         pop af
         ret

        
DO_Replay_UnmakeMove:
         push af
         ld a,(RplyMs)
         cp 0
         jr z,RplyUMKret
         call UnMakeMove
         call DrawBoard            ; no animation, sorry
         call PutToMove
         call GenMoves
         ld a,(RplyMs)
         dec a
         ld (RplyMs),a
RplyUMKret:
         pop af
         ret
                  

Loaded2VRAM: .byte 0       ; pre-loading of datas from file just once,
                           ; after the VRAM memory could be used only.
                           
Chess_GraphDatas_address:   .equ $8000         ; address where to load module

Chess_GraphDatas_filename:
           .byte 0, "CHESSPI CO2",0            ; name of file

ChessY2K_GraphDatas_load:
            push af
            ld a,(Loaded2VRAM)
            
            cp 0
            jr nz,GraphDatas_ok

            push hl
            push de
            ld hl,Chess_GraphDatas_filename
            ld de,Chess_GraphDatas_address
            call diskload                     ; loads datas
            pop de
            pop hl
            
            ld a,1
            ld (Loaded2VRAM),a                ; VRAM ok
GraphDatas_ok:
            pop af
            ret

            ;                                                                               
            ; Data files for pieces Colour of piece (B or W) 
            ;   + Name of piece ("KQRBNP" or empty square)
            ;   + colour of square under (read black bishop on black square)

tbPalettes:
            ;table of colours Nr,R,G,B
            ;  thanks to bmp2msx software (http://www.imasy.or.jp/~hra/)
        .byte $0,6,6,5
        .byte $1,5,3,2
        .byte $2,0,0,0
        .byte $3,7,7,6
        .byte $4,5,4,3
        .byte $5,5,5,5
        .byte $6,6,6,6
        .byte $7,3,2,2
        .byte $8,3,3,3
        .byte $9,6,5,4
        .byte $A,4,4,3
        .byte $B,1,1,1
        .byte $C,2,1,1
        .byte $D,6,5,6
        .byte $E,1,1,2
        .byte $F,1,2,1

ChessUI_end_addr:

         .export tbPalettes
         .export ChessUI_end_addr
         .export GraphicsS
         .export ANIMATION
         .export DrawBoard
         .export DrawSquare
         .export Cursor_Key_Controls