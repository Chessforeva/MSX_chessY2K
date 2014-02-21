;=======================================
;
; Disk functions (working)
;
;     diskload - to load small file into memory knowing that it works
;     readFF - buffered reading of 255 bytes of file into memory
;                (safe diskload for larger file)
;     dirload - to load directory structure into memory as string

;=======================================
;
; Usage1:
;        ld hl,filename_
;        ld de,$2000
;        call diskload
;filename_:
;        .byte 0,"myfile  com",0  
;
; (use exact file name space!)
;
;
; Usage2:
;        ld hl,filename_
;scanfile_:
;        call readFF
;        cp 0
;        jr z,scanover_
;        ld b,a
;        push de
;scanrecord_:
;        ld a,(de)   ;byte is here
;        inc de
;        djnz scanrecord_
;        pop de
;        jr scanfile_
;scanover_: 
;
;
; Usage3:
;        ld hl,willcard_
;        ld de,$2000
;        call dirload 
;willcard_:
;        .byte 0,"??????? COM",0  ;
;     
;    
f_setdma:     .equ     26
f_read:       .equ     39
f_open:       .equ     15
f_close:      .equ     16

f_search1     .equ     $11
f_search2     .equ     $12

f_bdos:       .equ     $F37D   ; Call $5


; load file in address de
diskload:
        push af
        push bc
        push de
        push hl
        push ix
        push iy
        
        ld a,1
        ld (loadflag),a
        
        push de
        call f_setfcb
        call f_openf
        ld hl,(f_bleng)
        pop de
        call f_loadf
        call f_closef
        
        pop iy
        pop ix
        pop hl
        pop de
        pop bc
        pop af
        ret
        
loadflag: .byte   1   ; should be 0 on return if loaded

stop_rdFF .byte   0   ; set 1 to stop reading
; scan file, buffer in address de
readFF:
        push bc
        push de
        push hl
        push ix
        push iy
        
        ld a,(rd_opn)
        cp 0
        jr nz,rd_overOpnFile
        
        push de
        call f_setfcb
        call f_openf
        pop de
    
rd_overOpnFile:

        ld a,0
        ld (f_groot+1),a
        ld h,a
        ld a,$1   ; read 255 bytes only
        ld (f_groot),a
        ld l,$ff
        
        ld a,(rd_opn)
        cp 0
        jr nz,rd_over2
        ld (stop_rdFF),a                        
        call f_loadf
        jr rd_over3
rd_over2:
        ld a,(stop_rdFF)
        cp 0
        jr nz,rd_StopRd
        ld de,f_fcb
        call f_rdit
rd_over3:
        ld a,1
        ld (rd_opn),a
        
        ld a,l
        cp 0
        jr nz,rd_outExit
rd_StopRd:
        call f_closef
        ld a,0
        ld (rd_opn),a
        cp 0
              
rd_outExit:        
        pop iy
        pop ix
        pop hl
        pop de
        pop bc
        ret

rd_opn: .byte 0
     
;
; searches directory files
;   that match hl willcard
;   and stores result in address de
;
; separator ","
; ends with "$"
;
;  So, print the directory structure after by simple:
;         ld c, 9
;         call 5
;
f_found .byte 0   ; counter of files found

dirload:
        push af
        push bc
        push de
        push hl
        push ix
        push iy
        
        ld      a,0
        ld      (f_found),a
        
        call    f_sv_save ; save de
        
        call    f_setfcb
        ld      hl,(f_bleng)

        push    hl
        ld      de,f_dma                                                                                                                                                                                          
        ld      c,f_setdma
        call    f_bdos
        ld      de,f_fcb
        pop     hl                
        
        ld      c,f_search1  ; first search
        call    f_bdos
        
f_loopDirList:

        cp 0
        jr nz,  f_errDirList
        
        ;----- save in list --|
        push    af
        push    bc
        push    de
        push    hl
        
        ld      a,(f_found)
        inc     a
        ld      (f_found),a
                
        call    f_sv_rest ; restore de
                
        push    iy
        pop     hl   ; where file name is in DMA
        ld      bc,11
        ldir         ; write 11 chars of filename
        
        ld      a,','    ; separator
        ld      (de),a
        inc     de

        call    f_sv_save ; save new de
        
        pop     hl
        pop     de
        pop     bc
        pop     af
        ;---------------------|
        
        ld      c,f_search2  ; continue searching
        call    f_bdos
        
        jr      f_loopDirList
        
f_errDirList:

        call    f_sv_rest ; restore de

        ld      a,(f_found)
        cp      0
        jr      z, f_fxqx
        dec     de
f_fxqx: ld      a,'$'     ; it's over, put $
        ld      (de),a
        
        pop iy
        pop ix
        pop hl
        pop de
        pop bc
        pop af
        ret

f_dma:  .ds 40      ; to store searching results (a copy of fcb)

; need this crap because it uses all registers
f_sv_save:
        push af
        ld a,d
        ld (f_sv_w+0),a        
        ld a,e
        ld (f_sv_w+1),a
        pop af
        ret
f_sv_rest:
        push af
        ld a,(f_sv_w+0)
        ld d,a        
        ld a,(f_sv_w+1)
        ld e,a        
        pop af
        ret

f_sv_w: .word 0
                   
f_setfcb:
          push hl
          ld hl,f_fcb+0
          ld de,f_fcb+1
          ld bc,36
          ld (hl),b
          ldir
          pop hl
          ld de,f_fcb
          ld bc,12
          ldir
          ret

f_openf:  ld      de,f_fcb
          ld      c,f_open
          call    f_bdos
          ld      hl,1
          ld      (f_groot),hl
          dec     hl
          ld      (f_blok),hl
          ld      (f_blok+2),hl
          ret
                    
f_loadf:  push    hl
          ld      c,f_setdma
          call    f_bdos
          ld      de,f_fcb
          pop     hl
f_rdit:   ld      c,f_read
          call    f_bdos    
          ld      (loadflag),a  ;sets 0 if ok, 1 if can not load
          ret
f_closef: ld      de,f_fcb
          ld      c,f_close
          call    f_bdos
          ret


; Good tutorial on MSX files at
; http://fms.komkon.org/MSX/Handbook/th-3.txt

f_fcb:    .byte    0
          .byte    "???????????"   ;11 chars          
          .word    0
f_groot:  .word    0
f_bleng:  .word    0
          .byte    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
f_blok:   .word    0
          .word    0

                        