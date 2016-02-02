.title ChessY2K_Graphics_datas

;=======================================
;
; DATAS of bitmaps
;  Graphics data compiled.
;  Of course,could be realised as
;   datafile, anyway this works as well.
;
;=======================================

           .org $8000
           
           ret        ; no options

GraphicsData:
          #include "PicData.ASM"    ; lots of data for graphics
          #include "PicDat0.ASM"    ; MASKS for pieces white and black
                                    ; with transparent background         

zz_ChessPI_End:

; Exporting addresses to include them in main module 
;      (recognises as labels)

; PicDat0           
              .export dtWP
              .export dtBP
              .export dtWN
              .export dtBN     
              .export dtWB
              .export dtBB
              .export dtWR
              .export dtBR
              .export dtWQ
              .export dtBQ
              .export dtWK
              .export dtBK

              .export dtMSXlogo

; PicData

              .export dtBBB
              .export dtBBW
              .export dtBKB
              .export dtBKW
              .export dtBNB
              .export dtBNW
              .export dtBPB
              .export dtBPW
              .export dtBQB
              .export dtBQW
              .export dtBRB 
              .export dtBRW

              .export dtWBB
              .export dtWBW
              .export dtWKB
              .export dtWKW
              .export dtWNB
              .export dtWNW
              .export dtWPB
              .export dtWPW
              .export dtWQB
              .export dtWQW
              .export dtWRB
              .export dtWRW

              .export dtSQB
              .export dtSQW

              .export dtFRDN
              .export dtFRLF
              .export dtFRRT
              .export dtFRUP

              .export dtWhiteToMove
              .export dtWhiteNotToMove
              .export dtBlackToMove
              .export dtBlackNotToMove
              
              .export zz_ChessPI_End
.end