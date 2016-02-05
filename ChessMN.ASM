;=======================================
;
; MAIN loop and MENU for ChessY2K
;
;=======================================

_menuI:     .byte 0   ;Current menu item to choose
_exitMn:    .byte 0   ;internal to know that exit
_canExit:   .byte 1   ;if no graphics, then can exit

ChessMN:

MAINLOOP:
         ld a,0
         ld (_menuI),a
         call MainMenu
                  
         ld a,(_menuI)
         cp 0
         jr nz, ItemNo0
         
         ld a,(_canExit)
         cp 0
         jr z,MAINLOOP
         
         jr EXIT_ALL        
ItemNo0:
         cp 1
         jr nz, ItemNo1
         
         ld a,(MOVE_str)
         cp 0
         jr z,LoopM
         
#ifdef PGN_COMPILE 
        
         ld a,%00000000         ; no cursor,can't dragmove, just replaymoves
         ld (Stylo),a 

         call GraphicsS         ; user interface for chess program
         
         ld a,0
         ld (Stylo),a
         ld (_canExit),a
                  
#endif                   
         jr LoopM
ItemNo1:      
         cp 2
         jr nz, ItemNo2

         ld a,%00000011         ; cursor,can dragmove
         ld (Stylo),a 
         
         call GraphicsS         ; user interface for chess program
         
         ld a,0
         ld (Stylo),a 
         ld (_canExit),a
         
         jr LoopM

ItemNo2:
         cp 3
         jr nz, ItemNo3

         ld a,%00000101         ; cursor,can setup pieces
         ld (Stylo),a 
         
         call GraphicsS         ; user interface for chess program
         
         ld a,0
         ld (Stylo),a
         ld (_canExit),a 

         jr LoopM
        
ItemNo3:         
LoopM:   

         call UndoAllMoves   ; good refresh
         
         jr MAINLOOP
              
         
EXIT_ALL:

         ret
         

MainMenu:
            ld hl, tbPalettes         ; in datas of ChessUI  
            call SetPaletteByTable    ; defines 16colors
            call ClearScreenBy30h                         
            call LastFENwasSet        ; to know FEN set up
                                       
            ld a,0
            ld (_exitMn),a
            ld a,1
                                    
#ifdef PGN_COMPILE                       
#else
            inc a                    ; can not access first choice
#endif            
            ld (_menuI),a
            
            ld a,27
            ld (_keymnbf),a         ; saves ESC as last key
                        
MENULOOP:                           ; Loop till ESC pressed
            call DrawChoices
            call InkeyKeyBy30h      ; keypress detect

            cp 27
            jr nz,noESCk
            ld a,(_keymnbf)
            cp 27
            jr nz,EscEXIT           ; Exit to MSXDOS
            ld a,0

noESCk:            
            call MenuKeyPress       ; Selection or other item
            jr Menu2loop

EscEXIT:
            ld a,0            
            ld (_menuI),a           ; nothing selected
            ld a,1            
            ld (_exitMn),a
Menu2loop:            
                                    
            ld a,(_exitMn)
            cp 0
            jr z, MENULOOP
            
            ld hl,$0101             ; locate left upper corner
            call LocatePosBy30h
            ld a,1                  ; display cursor
            ld (CSRSW),a
            call ClearScreenBy30h   ; and clear the screen
            call RestoreColors      ; restores default MSX colors
                                     
            ret

;------------- draws menu items
DrawChoices:
            push af
            push bc
            push de
            push hl
            
            ;ld a,2
            ;ld (FORCLR),a           ; set color black
            ;call SetColorBy30h
        
            ld hl,$0405
            call LocatePosBy30h

            ld de, MNheader
            
            ld a,0                  ; do not display cursor
            ld (CSRSW),a
             
            call PrintString
            
            ld l,7 ; row
            ld b,0 ; 3 choices
            ld de, MNchoices
MNchScan:   
            inc b          
            inc l  ; next row
            ld h,4 ; col

            call LocatePosBy30h
         
            call PrintString
      
            push hl
            ex de,hl    ; hl = de
            push bc
            ld bc,32
            add hl,bc
            pop bc
            ex de,hl    ; de = hl+32 now
            pop hl
            
            push de
            ld h,1 ; col
            call LocatePosBy30h            
            ld a,(_menuI)
            cp b
            jr nz,MNchNotI
            ld de,MnSelector    ; selector char
            jr MNchSelI
MNchNotI:   ld de,MnSpace        ;space
MNchSelI:   call PrintString
            pop de
                                    
            ld a,MNitems
            cp b           
            jr nz,MNchScan          
            
            pop hl
            pop de
            pop bc
            pop af
            ret
            

MNheader:   .byte "MSX chessY2K project          $",0


#ifdef PGN_COMPILE

MNitems:    .equ 1
MNchoices:
            .byte "Replay chess game from PGN    $",0
            
#else

MNitems:    .equ 3
MNchoices:
            .byte "Replay PGN (other module)     $",0
            .byte "Move pieces by using cursor   $",0
            .byte "Set positon for diagram       $",0
#endif

MnSelector: .byte "-> $",0
MnSpace:    .byte "   $",0

_keymnbf:   .byte 0  ; key pressed before

; this checks which key as been pressed
MenuKeyPress:
            push af
            push bc
            
            cp 0
            jr z,MNnoAct
            
            ld b,a
            ld a,(_keymnbf)
            cp b
            jr z, MNnoAct
            ld a,b
            ld (_keymnbf),a
            
            cp 32
            jr nz,MNnoSpace
MNspaceKey:

            ld a,(_menuI)
            cp 1
            jr nz,noPGNsub

            ; submenu of PGN files
            call ChessY2K_pgn_module
            
            ;jr MNnoAct

noPGNsub:   ld a,1
            ld (_exitMn),a     ; Item has been selected, exit menu and DO action
            jr MNnoAct             
MNnoSpace:  cp 13
            jr nz,MNnoEnter
            jr MNspaceKey
MNnoEnter:
            ld a,(_menuI)
            cp MNitems
            jr z, MNitemNxt0
            inc a ; next item                     
            jr MNitemNxt1            
MNitemNxt0: ld a,1 

#ifdef PGN_COMPILE                       
#else
            inc a                    ; can not access first choice
                                     ; (1st reserved for other module)
#endif

MNitemNxt1: ld (_menuI),a
            
MNnoAct:            
            pop bc
            pop af
            ret

;
; This outputs FEN for last position set up
;           
LastFENwasSet:
            ld hl,$0112
            call LocatePosBy30h
            ld de,wasSetUpFEN
            call PrintString   ; print out FEN
            ret

;This module has been separated to avoid 
; internal problems
;              
Chess_PG_module_address:   .equ $8000         ; address where to load module
Chess_PG_module_filename:
           .byte 0, "CHESSPG CO2",0           ; name of module file
      
ChessY2K_pgn_module:
#ifdef PGN_COMPILE
            push de
            push hl
            ld hl,Chess_PG_module_filename
            ld de,Chess_PG_module_address
            call diskload                     ; loads module
            call Chess_PG_module_address      ; starts main sub-procedure
            pop hl
            pop de
#endif             
            ret

ChessMN_end_addr:

         .export MAINLOOP
         .export ChessMN_end_addr