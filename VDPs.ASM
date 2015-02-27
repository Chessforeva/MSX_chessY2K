;=======================================
;
; VDP functions
;
;=======================================

; Provides:
;----------------------------------------------------------------------
; (1) Just working LAME part for Hello World of MSX VDP
;         (put pixels on screen)
;----------------------------------------------------------------------
;
; These functions provide MSX2 drawing from .COM module.
; LAME part can put pixels and that's all.
; Screen is 212 lines x 128 bytes per line of 2-pixels.
;
; In reality, prepare to spend days on MSX-hardcore:
; manuals, forums, not-working samples, no-hello-worlds, etc. 
; .BIN loaded from BASIC is not the same as .COM
; 64kb-s is less then Bios+DOS+BASIC+programs+etc. require -
; so it crashes silently by rewriting in the same memory addresses.
; Lots of functions described by techies just crash the emulator. 
; BASIC is for drawings!, not assembler.
; And video memory should be used as much possible (page 0-3, not LAME!),
; because MSX has lots of video memory compared to programmable RAM.
;
; Hello world .com that puts 2-pixels in left upper and right lower corner.
; 
;   org $100
;   call SetScreen5By30h
;   ld de,0
;   call LocateHL_byXY_inDE
;   ld a,$77
;   call VDPdraw2pixels    
;   ld d,127
;   ld e,211
;   call LocateHL_byXY_inDE
;   ld a,$88
;   call VDPdraw2pixels
;   call PressKeyBy30h
;   call SetScreen0By30h
;   ret
;         


SetScreen5By30h:
         ld    a,$05      ; Screen 5      
         rst   30h
         .byte $80        ; BIOS slot (when nothing is loaded)  
         .word $005f      ; CHGMOD CALL 5Fh
         ret
         
DisableScreenBy30h:       ; Before...
         rst   30h
         .byte $80        
         .word $0041      ; Disables screen display      
         ret
         
EnableScreenBy30h:        ; When drawings are finished... 
         rst   30h
         .byte $80               
         .word $0044      ; Enables screen display  
         ret

LocateHL_byXY_inDE:       ; Procedure calculates hl offset and sets VDP for writing
         di
         push af
         push bc
         push de
         push hl
         push ix
         ld l,d           ; regs d=x[0..127]
         ld a,e           ;      e=y[0..211]
         ld de,0
         bit 0,a
         jr z,no2add128bits
         ld e,$80
no2add128bits:
         rra
         ld h,a
         add hl,de
         xor a 
         call SetVDPwriteBy30h  ; now will write at this position
         pop ix
         pop hl
         pop de
         pop bc
         pop af
         ei
         ret                                          
                          ; This prepares for "pixeling"
SetVDPwriteBy30h:         ; hl,contains initial address
         rst   30h
         .byte $80 
         .word $0171      ; NSTWRT Sets up the VDP for writing wit full VRAM address
         ret         

VDPdraw2pixels:           ; Put 2 pixels by sending one byte with 2 colour Nr. (bits 0-3,4-7)
         out ($98),a      ; send this sequently
         ret
         
                 
SetPaletteByTable:        ; Sets colors by given RGB-table in HL-reg
         push af         
         push bc
         push hl
         ld b,$10             ; 16 colours
SPcoLoop:
         di
         ld   a,(hl)
         inc  hl
         out  ($99),a          ; colour Nr.
         ld   a, 128+16
         out  ($99),a         
         ld   a,(hl)            ; red
         inc  hl
         inc  hl
         sla  a
         sla  a
         sla  a
         sla  a                 ; bits 4-7
         ld   c,a
         ld   a,(hl)            ; blue bits 0-3
         dec  hl
         or   c
         out  ($9A),a 
         ld   a,(hl)            ; green bits 0-3
         inc  hl
         inc  hl
         out  ($9A),a
         ei 
         djnz SPcoLoop
         pop  hl         
         pop  bc
         pop  af 
         ret
         
SetBorderColor:               ; Sets border colour by A=Nr.              
         di
         out  ($99),a        ; a=[0..15]
         ld   a,128+7
         out  ($99),a        
         ei
         ret

VDPfaster:                   ; working with memory only, no sprite collisions and other things slowing down VDP
         push af
         di
         ld   a, %00001010 ; sprites off (bit1), VRAM quantity (bit3)- Affects how VDP performs refresh on DRAM chips   
         out  ($99),a
         ld   a, 128+8     
         out  ($99),a
         ei
         pop af
         ret
                                                                                                         
PressKeyBy30h:               ; wait for keypress
         rst   30h
         .byte $80 
         .word $009f
ClearKeyBy30h:
         rst   30h
         .byte $80 
         .word $0156         ; clear key buffer after             
         ret

InkeyKeyBy30h:               ; detects if there is a keypress
         rst   30h
         .byte $80 
         .word $009c
         jr z,InkeyK_none
         call PressKeyBy30h  ; if is then detects code
         jr InkeyK_ret
InkeyK_none:
         ld a,0
InkeyK_ret:         
         ret
                                    
SetScreen0By30h:             ; set back screen0
         ld    a,0      
         rst   30h
         .byte $80
         .word $005f
         ret
         
SetScreenABy30h:             ; set screen by A-reg
         rst   30h
         .byte $80
         .word $005f
         ret 
         
ClearScreenBy30h:            ; clears screen
         push af
         push bc
         push de
         xor a          
         rst   30h
         .byte $80
         .word $00c3
         pop de
         pop bc
         pop af
         ret
         
LINL40: .equ $F3AE
                
SetMode80:
        push af
        ld a,80
        ld (LINL40),a    ;width 80
        call SetScreen0By30h
        pop af
        ret
SetMode40:
        push af
        ld a,40
        ld (LINL40),a    ;width 40
        call SetScreen0By30h
        pop af
        ret 
                 
LocatePosBy30h:              ; Locate at position H (column) L (row) on screen
         rst   30h
         .byte $80
         .word $00c6
         ret
PutCharBy30h:                ; Put char reg-a = ascii code      
         rst   30h
         .byte $80
         .word $00a2
         ret
PrintLineBy30h:
         rst   30h
         .byte $80
         .word $00a2
         ret

CALL_5:   .equ $F37D         ;output string to screen
; prints string that ends with $
; de-reg points to string in address
; 
PrintString:
         push af
         push bc
         push de
         push hl
         push ix
         push iy
         ld c, 9       ; function for CALL 5
         call CALL_5   ; MSX printing
         pop iy
         pop ix
         pop hl
         pop de
         pop bc
         pop af
         ret
                         
         
FORCLR:  .equ  $F3E9         ; foreground color 
BAKCLR:  .equ  $F3EA         ; background color
BDRCLR:  .equ  $F3EB         ; bordercolor
SetColorBy30h:
         rst   30h           ; set color scheme by using FORCLR,BAKCLR,BDRCLR
         .byte $80
         .word $0062
         ret
         
CSRSW:   .equ $FCA9         ; to set cursor display switch (0-not to show)        
CSTYLE:  .equ $FCAA         ; to set cursor style (0-full,2-underline)
    
                
         
;--------------------------------------
; (2) ADVANCED functions, if You love VDP
;
; Use of pages,
; buffered copy of RAM->VRAM, RAM->RAM
;--------------------------------------
;
;
; Check if a v9958 is available (if so, return nz)
; Initialize address (v9958)
; (MSX+,MSXturboR video chip)
;
v9958:        .byte      0             ;>1 = v9958 present

v9958_Check:  di                       ;Test for v9958
              ld    a,1                ;Set s$1
              out   ($99),a
              ld    a,15+128
              out   ($99),a
              ld    a,(de)             ;Waste some time...
              in    a,($99)
              push  af
              ld    a,0
              out   ($99),a
              ld    a,15+128
              out   ($99),a            ;Set s$0
              ei
              pop   af
              and   %00111100          ;v9938? RET with Z
              ld    (v9958),a
              ret

;-----------------------------------------
;         
; These routines are the know-how scripts
; by VDP profies. In fact, dont use without
; knowing what is all about. Read manuals.
;
;-----------------------------------------

VDP:   .word  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
VDP_0: .word  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

;
;Copy the VDP-registers' settings to array VDP.
;Afterwards, read the VDP-registers with LD A,(VDP + r)
;(this should be placed at the start of a program)
;
Copy_VdpRegs: ld      hl,VDP+0		; doing nothing here
              ld      de,VDP_0+0	; actually should provide other VDP block
              ld      bc,8
              ldir
              ld      hl,VDP+8
              ld      de,VDP_0+8
              ld      bc,17
              ldir
              ret


;
;Restore the VDP-registers' settings.
;(this should be placed at the end of a program)
;
Rest_VdpRegs: ld      bc,$0800
              ld      hl,VDP_0+0
              call    Rest_VdpSub
              ld      bc,$1008
              ld      hl,VDP_0+8
              call    Rest_VdpSub
              ld      bc,$0319
              ld      hl,Vdp3zero    ;a jp Restore_Vdp_Sub is implied
Rest_VdpSub:  ld      a,(hl)
              inc     hl
              di
              out     ($99),a
              ld      a,c
              or      128
              ei
              out     ($99),a
              inc     c
              djnz    Rest_VdpSub
              ret

Vdp3zero:    .byte      0,0,0


;
;Set page = A [0..3] in screen 5.
;
SetPage:
        add     a,a ;x32
        add     a,a
        add     a,a
        add     a,a
        add     a,a
        add     a,31
        ld      (VDP+2),a
        di
        out     ($99),a
        ld      a,2+128
        ei
        out     ($99),a
        ret
        
;
;Set VDP port $98 to start writing at address AHL (17-bit)
;
;
; Left upper corner of each pages:
;   0 -> A=0,HL=$0000
;   1 -> A=0,HL=$8000
;   2 -> A=1,HL=$0000
;   3 -> A=1,HL=$8000
;


Set_Vdp_Write:           ; A(1bit),HL(16bits) input
        
        rlc   h
        rla
        rlc   h
        rla
        srl   h
        srl   h
        di
        out   ($99),a
        ld    a,14+128
        out   ($99),a
        ld    a,l
        nop
        out   ($99),a
        ld    a,h
        or    64
        ei
        out   ($99),a
        ret

;
;Set VDP port $98 to start reading at address AHL (17-bit)
;
SetVdp_Read:
        rlc     h
        rla
        rlc     h
        rla
        srl     h
        srl     h
        di
        out     ($99),a       ;set bits 15-17
        ld      a,128+14
        out     ($99),a
        ld      a,l           ;set bits 0-7
        nop
        out     ($99),a
        ld      a,h           ;set bits 8-14
        ei                    ; + read access
        out     ($99),a
        ret
        
;****************************************************************
; HMMC (High speed move CPU to VRAM)
; Screen size 256x212 dots, each byte is color Nr. for 2-pixels 
;
; Copies data from memory to block in VRAM
; The same as in basic COPY file.pic TO (x,y)-(x+D-1,y+E-1)
;
; RAM [IX] => VRAM (H,L)-(+D,+E)
;
; set ix = memory address of data to write to VRAM
; set h,l,d,e for rectangle to put in
; D,E mod 2 = 0 !
;****************************************************************

HMMC:  
         di
         push af
         push bc
         push hl
         push ix      
         ld a,0         
         call hmmc_wait_VDP
         ld a,36         ;command register R#36
         out ($99),a
         ld a,128+17     ;VDP(17)<=36
         out ($99),a
         xor a           ;ld a,0
         ld c,$9b
         out (c),h       ;X
         out (c),a
         out (c),l       ;Y
         out (c),a
         out (c),d       ;DX in dots
         out (c),a       ;
         out (c),e       ;DY in dots
         out (c),a       ;
            
         ld h,(ix)       ;first byte of data
         out (c),h       

         out (c),a       ;DIX and DIY = 0     
         ld a,%11110000
         out (c),a      ; command to do it
         ld a,128+44
         out ($99),a
         ld a,128+17
         out ($99),a    ; VDP(17)<=44                        
hmmc_Loop:
         ld a,2
         call hmmc_Status
         bit 7,a        ; TR? transferring?
         jr z, hmmc_Loop
         bit 0,a        ; CE? is over?
         jr z, hmmc_exit                       
         inc ix
         ld a,(ix)
         out ($9b),a
         jr hmmc_Loop                                                      
hmmc_exit:
         ld a,0
         call hmmc_Status
         pop ix
         pop hl
         pop bc
         pop af
         ei
         ret                                                                                                                                                                                                                  
                                                                                                                                                                                                                                                                            
hmmc_Status:
         out ($99),a
         ld a,$8f
         out ($99),a
         in a,($99)
         push af
         xor a
         out ($99),a
         ld a,$8f
         out ($99),a
         pop af
         ret
hmmc_wait_VDP:
         ld a,2
         call hmmc_Status
         and 1
         jr nz,hmmc_wait_VDP
         xor a
         call hmmc_Status
         ret

;****************************************************************
;  HMMM (High speed move VRAM to VRAM)
;        to use, set H, L, D, E, B, C and go
;        VRAM (H,L)-(+D,+E) ---> VRAM (B,C)
; DE is difference -not absolute values
; byte DIX,DIY=0, explained:
; The 0 copies the block starting from the upper left, the 1 from right/bottom.
; what's the difference? when copying overlapping source/destination
; (a scroller for example)
; when scrolling from right to left DIX/DIY can both be 0
;  but copying from left to right DIX must be 1. just figure it out...
; Then give coord.positive from right upper corner to left.
;****************************************************************

HMMM:
         di
         push af
         push bc              
         call VDPready
         ld  a,32
         out ($99),a
         ld  a,128+17
         out ($99),a     ;R#17 := 32
         push de
         push bc
         xor a           ;ld a,0
         pop de          ;de = bc now
         ld c,$9b
         out (c),h       ;X from
         out (c),a
         out (c),l       ;Y from
         out (c),a
         out (c),d       ;X to
         out (c),a       ;
         out (c),e       ;Y to
         out (c),a
         pop de          ;de = de now
         out (c),d       ;DX in dots
         out (c),a       ;
         out (c),e       ;DY in dots
         out (c),a       ;
         out (c),a       ;dummy
         out (c),a       ;DIX and DIY = 0
         ld  a,%11010000 ;HMMM command
         out (c),a       ;do it
         call VDPready
         pop bc
         pop af
         ei
         ret
                                
VDPready:
        ld   a,2
        di
        out  ($99),a          ;select status register 2
        ld   a,128+15
        out  ($99),a
        in   a,($99)
	bit  0,a
	jr   nz, VDPready	; wait
        rra
        ld   a,0
        out  ($99),a
        ld   a,128+15
        out  ($99),a
        ei
        jr   c,VDPready    ;wait till previous VDP execution is over (CE)
        ret

;
; Sets display mode to width 80
; Use then SetScreen0By30h to set back width 40
;
VDPsetMode80:        

        di
        ld   a,%00000100
        out  ($99),a
        ld   a,128+0
        out  ($99),a
        ld   a,%01110000
        out  ($99),a
        ld   a,128+1
        out  ($99),a
        xor a
        out  ($99),a
        ld   a,128+8
        out  ($99),a
        xor a
        out  ($99),a
        ld   a,128+9
        out  ($99),a
        ei
        ret
                                        
;        
;Disable the screen.
;
Disable_Scr:
        ld      a,(VDP+1)
        and     %10111111
        ld      (VDP+1),a
        di
        out     ($99),a
        ld      a,128+1
        ei
        out     ($99),a
        ret

;
;Enable the screen.
;
Enable_Scr:
        ld      a,(VDP+1)
        or      %01000000
        ld      (VDP+1),a
        di
        out     ($99),a
        ld      a,128+1
        ei
        out     ($99),a
        ret

;
;Enable the sprites.
;
Sprites_On:   ld      a,(VDP+8)
              and     %11111101
              ld      (VDP+8),a
              di
              out     ($99),a
              ld      a,8+128
              ei
              out     ($99),a
              ret

;
;Disable the sprites.
;
Sprites_Off:  ld      a,(VDP+8)
              or      %00000010
              ld      (VDP+8),a
              di
              out     ($99),a
              ld      a,8+128
              ei
              out     ($99),a
              ret
;
; set 16x16 sprites
;         
VDPsprites16x16:
              ld      a,(VDP+1)
              or      %00000010
              ld      (VDP+1),a
              di
              out     ($99),a
              ld      a,1+128
              ei
              out     ($99),a
              ret

ColPal_:    .word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 

Color16defaultPalettes:
            ;table of colours Nr,R,G,B
        .byte $0,0,0,0
        .byte $1,0,0,0
        .byte $2,1,6,1
        .byte $3,3,7,3
        .byte $4,1,1,7
        .byte $5,2,3,7
        .byte $6,5,1,1
        .byte $7,2,6,7
        .byte $8,7,1,1
        .byte $9,7,3,3
        .byte $A,6,6,1
        .byte $B,6,6,4
        .byte $C,1,4,1
        .byte $D,6,2,5
        .byte $E,5,5,5
        .byte $F,7,7,7
        
;Restores default MSX color palettes
RestoreColors:
             push hl
             ld hl, Color16defaultPalettes 
             call SetPaletteByTable    ; defines 16colors
             pop hl
             ret

;****************************************************************
; draws LINE 
;        to use, set H, L, D, E, B, A and go
;        draw LINE (H,L)-(D,E) with color B, log-op A
; H,L,D,E absolute values
;****************************************************************

LINE:
         di
         push af
         push bc
         push de
         push hl
         
         push af          ;save LOGICAL OPERATION
         push bc          ;save COLOR            
         call VDPready
         ld  a,36
         out ($99),a
         ld  a,128+17
         out ($99),a     ;R#17 := 36
         xor a           ;ld a,0
         ld c,$9b
         out (c),h       ;X from
         out (c),a
         out (c),l       ;Y from
         out (c),a
 
         ld a,h          ;make DX and DIX
         sub d
         ld  d,%00000100
         jr nc,gLINE1
         ld  d,%00000000
         neg
gLINE1:  ld h,a          ;H := DX , D := DIX
         ld a,l          ;make DY and DIY
         sub e
         ld  e,%00001000
         jr nc,gLINE2
         ld  e,%00000000
         neg
gLINE2:  ld l,a          ;L := DY , E := DIY
         cp h            ;make Maj and Min
         jr c,gLINE3
         xor a
         out (c),l           ;long side
         out (c),a
         out (c),h           ;short side
         out (c),a
         ld  a,%00000001     ;MAJ := 1
         jr gLINE4

gLINE3:  xor a
         out (c),h           ;NX
         out (c),a
         out (c),l           ;NY
         out (c),a
         ld  a,%00000000     ;MAJ := 0

gLINE4:  or d
         or e           ;A := DIX , DIY , MAJ
         pop hl         ;H := COLOR
         out (c),h
         out (c),a
         pop af         ;A := LOGICAL OPERATION
         or  %01110000
         out (c),a
         ld  a,$8F
         out (c),a
         
         call VDPready
         pop hl         
         pop de         
         pop bc
         pop af
         ei
         ret
 

;***************************************************************************
;  HMMM with 2byte addressing (far copy), for not simplest case
;  word size parameters for H, L, D, E, B, C, DIX/DIY byte
;***************************************************************************

HC_p     .word 0,0,0,0,0,0
         .byte 0    ;DIX,DIY, just =0

HMMMf:
         di
         push af
         push bc
         push de
         push hl
                 
         call VDPready
         ld  a,32
         out ($99),a
         ld  a,128+17
         out ($99),a     ;R#17 := 32
         ld hl,HC_p
         ld c,$9b
         ld b,12         ;6x2bytes
         otir
         xor a     
         out (c),a       ;dummy
         outi            ;DIX and DIY
         ld  a,%11010000 ;HMMM command
         out (c),a       ;do it
         call VDPready
         pop hl
         pop de
         pop bc
         pop af
         ei
         ret

;***************************************************************************
;  LMMM with 2byte addressing (far copy), for not simplest case
;  VRAM (H,L)-(D,E) ---> VRAM (B,C)  with logical operation 
;  word size parameters for H, L, D, E, B, C, DIX/DIY byte, Logical_A byte
;***************************************************************************

LM_p     .word 0,0,0,0,0,0
         .byte 0    ;DIX,DIY, just =0
         .byte 0    ;LOGICAL IMP=0 (just copy), TIMP bit3=1 copy no transparents
LMMMf:
         di
         push af
         push bc
         push de
         push hl
                 
         call VDPready
         ld  a,32
         out ($99),a
         ld  a,128+17
         out ($99),a     ;R#17 := 32
         ld hl,LM_p
         ld c,$9b
         ld b,12         ;6x2bytes
         otir
         xor a     
         out (c),a       ;dummy
         outi            ;DIX and DIY
         ld a,(hl)       ; +logical
         or %10010000    ;LMMM command
         out (c),a       ;do it
         call VDPready
         pop hl
         pop de
         pop bc
         pop af
         ei
         ret
