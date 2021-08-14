; BASIC loader
* = $0801
                BYTE $0E, $08, $0A, $00, $9E, $20, $28,  $34, $30, $39, $36, $29, $00, $00, $00

; Program starts at $1000
* = $1000

; KERNAL functions
NUMOUT = $bdcd
CHROUT = $ffd2
POSCURS = $fff0
SETLFS = $ffba
SETNAM = $ffbd
OPEN = $ffc0
CLOSE = $ffc3
CHKOUT = $ffc9
CLRCHN = $ffcc

MAPNUM = 0

FILENUM = 3

                ; Call SETLFS
                lda #FILENUM  ; Logical File number
                ldx #8        ; Device 8
                ldy #FILENUM  ; Device command
                jsr SETLFS

                ; Dynamic filename based on MAPNUM
                lda #MAPNUM
                clc
                adc #35
                sta filename+6

                ; Call SETNAM
                lda #filename_end-filename ; Length of filename
                ldx #<filename
                ldy #>filename
                jsr SETNAM

                ; Call OPEN
                jsr OPEN

                ; Call CHKOUT
                ldx #FILENUM
                jsr CHKOUT

                ; Write to file
                lda #0
                jsr CHROUT
                lda #0
                jsr CHROUT

                ; Write to file
                ldx #0
@loop           cpx #250
                beq @done
                inx
                txa
                pha
                lda #"a"
                jsr CHROUT
                lda #"b"
                jsr CHROUT
                lda #"c"
                jsr CHROUT
                pla
                tax
                jmp @loop
@done

                ; Close file
                lda #FILENUM
                jsr CLOSE
                jsr CLRCHN

filename        TEXT "@0:map ,s,w"
filename_end

