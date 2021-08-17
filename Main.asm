; BASIC loader
* = $0801
                BYTE $0E, $08, $0A, $00, $9E, $20, $28,  $34, $30, $39, $36, $29, $00, $00, $00

; Check for key press
defm            check_key
                lda $cb  ; Current key pressed
                cmp #/1
                bne @not_pressed
                lda #1
                sta player_moved
                jmp @check_key_done
@not_pressed    lda #0
@check_key_done nop
endm

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
CHKIN = $ffc6
CHRIN = $ffcf

; For map files
MAP_MAX_X = 1
MAP_MAX_Y = 1
FILENUM = 3

; Generate map files and then load first map
                jsr gen_map_files
                lda #0
                sta map_num
                jsr load_map_data

; Configure screen colors and clear screen, display initial values
                lda #11
                sta $d020
                lda #0
                sta $d021
                lda #$01
                sta $286
                lda #$93
                jsr CHROUT
                jsr draw_screen
                jsr color_screen
                lda #0
                jsr draw_player

; Main loop
mainloop        ; Make a copy of the current position
                lda player_x
                sta player_x_prev
                lda player_y
                sta player_y_prev

                ; Reset player_moved
                lda #0
                sta player_moved

                ; Check for "w" key press
                jsr check_w_key
                lda player_moved
                bne mainloop

                ; Check for "s" key press
                jsr check_s_key
                lda player_moved
                bne mainloop

                ; Check for "a" key press
                jsr check_a_key
                lda player_moved
                bne mainloop

                ; Check for "d" key press
                jsr check_d_key

                ; Bottom of main loop
                jmp mainloop

; Returns A: 0 = no overflow/underflow, 1 = overflow/underflow
; temp + 6: Return address
move_player_up  lda player_y
                cmp #0
                beq @underflow
                dec player_y
                lda #0
                jmp (temp + 6)
@underflow      lda #24
                sta player_y
                lda #1
                jmp (temp + 6)

; Returns A: 0 = no overflow/underflow, 1 = overflow/underflow
; temp + 6: Return address
move_player_dn  lda player_y
                cmp #24
                beq @overflow
                inc player_y
                lda #0
                jmp (temp + 6)
@overflow       lda #0
                sta player_y
                lda #1
                jmp (temp + 6)

; Returns A: 0 = no overflow/underflow, 1 = overflow/underflow
; temp + 6: Return address
move_player_lt  lda player_x
                cmp #0
                beq @underflow
                dec player_x
                lda #0
                jmp (temp + 6)
@underflow      lda #39
                sta player_x
                lda #1
                jmp (temp + 6)

; Returns A: 0 = no overflow/underflow, 1 = overflow/underflow
; temp + 6: Return address
move_player_rt  lda player_x
                cmp #39
                beq @overflow
                inc player_x
                lda #0
                jmp (temp + 6)
@overflow       lda #0
                sta player_x
                lda #1
                jmp (temp + 6)

; Calculate map_num based on map_x and map_y
calc_map_num    lda map_x
                sta map_num
                ldy map_y
@loop           cpy #0
                beq @done
                dey
                lda #MAP_MAX_X+1
                clc
                adc map_num
                sta map_num
                lda #0
                adc map_num + 1
                sta map_num + 1
                jmp @loop
@done           rts

; Returns A: 0 = invalid move, 1 = valid move
; temp + 6: Return address
try_map_up      lda map_y
                cmp #0
                beq @invalid_move
                dec map_y
                jsr calc_map_num
                jsr load_map_data
                jsr draw_screen
                jsr color_screen
                lda #0
                jsr draw_player
                lda #1
                jmp (temp + 6)
@invalid_move   lda #0
                jmp (temp + 6)

; Returns A: 0 = invalid move, 1 = valid move
; temp + 6: Return address
try_map_dn      lda map_y
                cmp #MAP_MAX_Y
                beq @invalid_move
                inc map_y
                jsr calc_map_num
                jsr load_map_data
                jsr draw_screen
                jsr color_screen
                lda #0
                jsr draw_player
                lda #1
                jmp (temp + 6)
@invalid_move   lda #0
                jmp (temp + 6)

; Returns A: 0 = invalid move, 1 = valid move
; temp + 6: Return address
try_map_lt      lda map_x
                cmp #0
                beq @invalid_move
                dec map_x
                jsr calc_map_num
                jsr load_map_data
                jsr draw_screen
                jsr color_screen
                lda #0
                jsr draw_player
                lda #1
                jmp (temp + 6)
@invalid_move   lda #0
                jmp (temp + 6)

; Returns A: 0 = invalid move, 1 = valid move
; temp + 6: Return address
try_map_rt      lda map_x
                cmp #MAP_MAX_X
                beq @invalid_move
                inc map_x
                jsr calc_map_num
                jsr load_map_data
                jsr draw_screen
                jsr color_screen
                lda #0
                jsr draw_player
                lda #1
                jmp (temp + 6)
@invalid_move   lda #0
                jmp (temp + 6)

; Determine if current position is a valid space or not
; Returns A: 1 = valid, 0 = invalid
valid_space     ldx player_y
                ldy player_x
                jsr get_char
                cmp #32
                beq @valid_move
                lda #0
                rts
@valid_move     lda #1
                rts

; Input:
;   temp + 0: "Move player in direction" function pointer
;   temp + 2: "Undo move player in direction" function pointer
;   temp + 4: "Move map in direction" function pointer
move_player     ; Jump to move player in direction function pointer
                lda #<@r1
                sta temp + 6
                lda #>@r1
                sta temp + 7
                jmp (temp + 0)

@r1             ; Did the move result in an underflow/overflow?
                cmp #1
                bne @no_un_ov_flow

                ; Underflow/overflow, try map move
                lda #<@r2
                sta temp + 6
                lda #>@r2
                sta temp + 7
                jmp (temp + 4)

@r2             ; Map move okay?
                cmp #0
                beq @invalid_move
                rts

                ; Valid map move
                rts

@no_un_ov_flow  ; No underflow/overflow, check for valid space
                jsr valid_space
                cmp #0
                beq @invalid_move

                ; Valid move
                lda #1
                jsr draw_player
                rts

@invalid_move    ; Undo move
                lda #<@r3
                sta temp + 6
                lda #>@r3
                sta temp + 7
                jmp (temp + 2)
@r3             rts

; Detect "w" key press and optionally process movement in "up" direction
check_w_key     check_key 9
                cmp #1
                bne @no_key
                lda #<move_player_up
                sta temp + 0
                lda #>move_player_up
                sta temp + 1
                lda #<move_player_dn
                sta temp + 2
                lda #>move_player_dn
                sta temp + 3
                lda #<try_map_up
                sta temp + 4
                lda #>try_map_up
                sta temp + 5
                jsr move_player
                jsr delay
@no_key         rts

; Detect "s" key press and optionally process movement in "down" direction
check_s_key     check_key 13
                cmp #1
                bne @no_key
                lda #<move_player_dn
                sta temp + 0
                lda #>move_player_dn
                sta temp + 1
                lda #<move_player_up
                sta temp + 2
                lda #>move_player_up
                sta temp + 3
                lda #<try_map_dn
                sta temp + 4
                lda #>try_map_dn
                sta temp + 5
                jsr move_player
                jsr delay
@no_key         rts

; Detect "a" key press and optionally process movement in "left" direction
check_a_key     check_key 10
                cmp #1
                bne @no_key
                lda #<move_player_lt
                sta temp + 0
                lda #>move_player_lt
                sta temp + 1
                lda #<move_player_rt
                sta temp + 2
                lda #>move_player_rt
                sta temp + 3
                lda #<try_map_lt
                sta temp + 4
                lda #>try_map_lt
                sta temp + 5
                jsr move_player
                jsr delay
@no_key         rts

; Detect "d" key press and optionally process movement in "right" direction
check_d_key     check_key 18
                cmp #1
                bne @no_key
                lda #<move_player_rt
                sta temp + 0
                lda #>move_player_rt
                sta temp + 1
                lda #<move_player_lt
                sta temp + 2
                lda #>move_player_lt
                sta temp + 3
                lda #<try_map_rt
                sta temp + 4
                lda #>try_map_rt
                sta temp + 5
                jsr move_player
                jsr delay
@no_key         rts

; Put character at location (X = row, Y = col, A = character)
put_char        sta temp

                lda #$00
                sta $fb
                lda #$04
                sta $fc

@rows           cpx #0
                beq @cols
                lda #40
                clc
                adc $fb
                sta $fb
                lda $fc
                adc #0
                sta $fc
                dex
                jmp @rows

@cols           tya
                clc
                adc $fb
                sta $fb
                lda #0
                adc $fc
                sta $fc

                ldy #0
                lda temp
                sta ($fb),Y

                rts

; Get character at location (X = row, Y = col, returns character in A)
get_char        lda #$00
                sta $fb
                lda #$04
                sta $fc

@rows           cpx #0
                beq @cols
                lda #40
                clc
                adc $fb
                sta $fb
                lda $fc
                adc #0
                sta $fc
                dex
                jmp @rows

@cols           tya
                clc
                adc $fb
                sta $fb
                lda #0
                adc $fc
                sta $fc

                ldy #0
                lda ($fb),Y

                rts

; Draw screen
draw_screen     ; Store pointer to map data in $fb/$fc for use in indirect addressing
                lda #<map_data
                sta map_data_start
                sta $fb
                lda #>map_data
                sta map_data_start + 1
                sta $fc

                ; Initial screen pointer to $0400 for use in indirect addressing
                lda #$00
                sta $fd
                lda #$04
                sta $fe

                ; For 25 rows
                ;   jsr draw_screen_row
                ;   Add 40 to map_data pointer
                ;   Add 40 to screen pointer

                ldx #0
@loop           jsr draw_screen_row
                cpx #24
                beq @done
                inx

                ; Add 40 to screen pointer (advance to start of next row)
                lda #40
                clc
                adc $fd
                sta $fd
                lda #0
                adc $fe
                sta $fe

                ; Add 40 to map_data pointer
                lda #40
                clc
                adc $fb
                sta $fb
                lda #0
                adc $fc
                sta $fc

                jmp @loop
@done           rts

; Color screen
color_screen    ; Store pointer to color data in $fb/$fc for use in indirect addressing
                lda #<map_data
                sta map_data_start
                lda #>map_data
                sta map_data_start + 1

                ; Add 25x40 to map_data_start
                lda map_data_start
                clc
                adc #250
                sta map_data_start
                lda map_data_start + 1
                adc #0
                sta map_data_start + 1

                lda map_data_start
                clc
                adc #250
                sta map_data_start
                lda map_data_start + 1
                adc #0
                sta map_data_start + 1

                lda map_data_start
                clc
                adc #250
                sta map_data_start
                lda map_data_start + 1
                adc #0
                sta map_data_start + 1

                lda map_data_start
                clc
                adc #250
                sta map_data_start
                sta $fb
                lda map_data_start + 1
                adc #0
                sta map_data_start + 1
                sta $fc

                ; Initial screen pointer to $d800 for use in indirect addressing
                lda #$00
                sta $fd
                lda #$d8
                sta $fe

                ; For 25 rows
                ;   jsr colr_screen_row
                ;   Add 40 to map_data pointer
                ;   Add 40 to screen pointer

                ldx #0
@loop           jsr colr_screen_row
                cpx #24
                beq @done
                inx

                ; Add 40 to screen pointer (advance to start of next row)
                lda #40
                clc
                adc $fd
                sta $fd
                lda #0
                adc $fe
                sta $fe

                ; Add 40 to map_data pointer
                lda #40
                clc
                adc $fb
                sta $fb
                lda #0
                adc $fc
                sta $fc

                jmp @loop
@done           rts

; Draw screen row based on current map_data and screen pointers
draw_screen_row ldy #0
@loop           lda ($fb),Y
                sta ($fd),Y
                cpy #39
                beq @done
                iny
                jmp @loop
@done           rts

; Color screen row based on current map_data and screen pointers
colr_screen_row ldy #0
@loop           lda ($fb),Y
                sta ($fd),Y
                cpy #39
                beq @done
                iny
                jmp @loop
@done           rts

; Draw player (A: 0 = do not erase previous space, 1 = erase previous space)
draw_player     ; Optionally erase previous player position based on A
                cmp #0
                beq @draw

                ; Erase previous character
                ldx player_y_prev
                ldy player_x_prev
                lda #32
                jsr put_char

@draw           ; Draw current player position
                lda #88
                ldx player_y   ; row
                ldy player_x   ; column
                jsr put_char

                ; Done
                rts

; Delay
delay           ldx #0
                ldy #0
@l1             cpx #250
                beq @next
                inx
                jmp @l1
@next           cpy #250
                beq @done
                iny
                ldx #0
                jmp @l1
@done           rts

; Load map data based on map_num
load_map_data  ; Call SETLFS
                lda #FILENUM  ; Logical File number
                ldx #8        ; Device 8
                ldy #FILENUM  ; Device command
                jsr SETLFS

                ; Dynamic filename based on MAPNUM
                lda map_num
                clc
                adc #35
                sta filename+3

                ; Call SETNAM
                lda #filename_end-filename ; Length of filename
                ldx #<filename
                ldy #>filename
                jsr SETNAM

                ; Call OPEN
                jsr OPEN

                ; Call CHKIN
                ldx #FILENUM
                jsr CHKIN

                ; Read 2,000 bytes of data into map_data (8 x 250 bytes)
                lda #<map_data
                sta $fb
                lda #>map_data
                sta $fc
                lda #0
                sta temp
@loop           jsr read_map_data
                inc temp
                lda temp
                cmp #8
                beq @done
                lda $fb
                clc
                adc #250
                sta $fb
                lda $fc
                adc #0
                sta $fc
                jmp @loop

@done           ; Close file
                lda #FILENUM
                jsr CLOSE
                jsr CLRCHN

                ; Done
                rts

; Read 250 bytes of data starting at $fb/$fc
read_map_data   ldy #0
@loop           sty temp+1
                jsr CHRIN
                ldy temp+1
                sta ($fb),Y
                iny
                cpy #250
                beq @done
                jmp @loop
@done           rts

; Generate map files
gen_map_files   ; Call SETLFS
                lda #FILENUM  ; Logical File number
                ldx #8        ; Device 8
                ldy #FILENUM  ; Device command
                jsr SETLFS

                ; Dynamic filename based on map_num
                lda map_num
                clc
                adc #35
                sta filename_new+6

                ; Call SETNAM
                lda #filename_new_end-filename_new ; Length of filename
                ldx #<filename_new
                ldy #>filename_new
                jsr SETNAM

                ; Call OPEN
                jsr OPEN

                ; Call CHKOUT
                ldx #FILENUM
                jsr CHKOUT

                ; Write to file (32 loops of 250 iterations = 8,000 bytes)
                lda #<map_data_input
                sta $fb
                lda #>map_data_input
                sta $fc
                ldx #0
                stx temp
@loop           jsr write_map_data
                inx
                cpx #32
                beq @done
                inc temp
                lda temp
                cmp #8
                bne @nonewmapyet
                lda #0
                sta temp
                txa
                pha
                jsr next_file
                pla
                tax
@nonewmapyet    lda $fb
                clc
                adc #250
                sta $fb
                lda $fc
                adc #0
                sta $fc
                jmp @loop
@done

                ; Close file
                lda #FILENUM
                jsr CLOSE
                jsr CLRCHN

                ; Done
                rts

; Switch to next file for writing
next_file       ; Close file
                lda #FILENUM
                jsr CLOSE
                jsr CLRCHN

                ; Call SETLFS
                lda #FILENUM  ; Logical File number
                ldx #8        ; Device 8
                ldy #FILENUM  ; Device command
                jsr SETLFS

                ; Dynamic filename based on map_num
                inc map_num
                lda map_num
                clc
                adc #35
                sta filename_new+6

                ; Call SETNAM
                lda #filename_new_end-filename_new ; Length of filename
                ldx #<filename_new
                ldy #>filename_new
                jsr SETNAM

                ; Call OPEN
                jsr OPEN

                ; Call CHKOUT
                ldx #FILENUM
                jsr CHKOUT

                ; Done
                rts

; Write 250 bytes of data starting at $fb/$fc
write_map_data  ldy #0
@loop           lda ($fb),Y
                jsr CHROUT
                iny
                cpy #250
                beq @done
                jmp @loop
@done           rts

player_x        BYTE 20
player_y        BYTE 4

player_x_prev   BYTE 0
player_y_prev   BYTE 0

player_moved    BYTE 0

map_x           BYTE 0
map_y           BYTE 0

map_num         BYTE 0, 0

map_data_start  BYTE 0, 0

temp            BYTE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

; Map data
map_data        BYTE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                BYTE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                BYTE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                BYTE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                BYTE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                BYTE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                BYTE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                BYTE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                BYTE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                BYTE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                BYTE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                BYTE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                BYTE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                BYTE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                BYTE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                BYTE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                BYTE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                BYTE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                BYTE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                BYTE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                BYTE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                BYTE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                BYTE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                BYTE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                BYTE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                BYTE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                BYTE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                BYTE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                BYTE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                BYTE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                BYTE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                BYTE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                BYTE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                BYTE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                BYTE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                BYTE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                BYTE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                BYTE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                BYTE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                BYTE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

filename        TEXT "mapX,s,r"
filename_end

filename_new    TEXT "@0:mapX,s,w"
filename_new_end

map_data_input
                ; Screen 1 - 0,0 City Screen data
                BYTE    $66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66
                BYTE    $66,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
                BYTE    $66,$20,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$A0,$E6,$66,$20
                BYTE    $66,$20,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$A0,$E6,$66,$20
                BYTE    $66,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
                BYTE    $66,$20,$A0,$A0,$A0,$A0,$E6,$A0,$A0,$20,$E6,$E6,$E6,$E6,$E6,$20,$A0,$A0,$A0,$A0,$A0,$E6,$A0,$A0,$A0,$20,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$20,$E6,$E6,$E6,$66,$20
                BYTE    $66,$20,$A0,$A0,$A0,$A0,$E6,$A0,$A0,$20,$E6,$E6,$E6,$E6,$E6,$20,$A0,$A0,$A0,$A0,$A0,$E6,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$E6,$E6,$E6,$E6,$20,$A0,$A0,$A0,$A0,$20
                BYTE    $66,$20,$A0,$A0,$A0,$A0,$E6,$A0,$A0,$20,$A0,$A0,$E6,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$E6,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$E6,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$20
                BYTE    $66,$20,$20,$20,$20,$20,$20,$20,$20,$20,$A0,$A0,$E6,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$E6,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$E6,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$20
                BYTE    $66,$20,$E6,$A0,$A0,$A0,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
                BYTE    $66,$20,$E6,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$E6,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$E6,$A0,$A0,$A0,$E6,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20
                BYTE    $66,$20,$E6,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$E6,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$E6,$A0,$A0,$A0,$E6,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20
                BYTE    $66,$20,$E6,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$E6,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$E6,$E6,$E6,$E6,$E6,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20
                BYTE    $66,$20,$E6,$A0,$A0,$A0,$A0,$A0,$A0,$20,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$20,$A0,$20,$A0,$A0,$A0,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$66,$20
                BYTE    $66,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
                BYTE    $66,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$E6,$A0,$A0,$20,$A0,$A0,$A0,$E6,$66,$20
                BYTE    $66,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$E6,$A0,$A0,$20,$A0,$A0,$A0,$E6,$66,$20
                BYTE    $66,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$E6,$E6,$E6,$E6,$E6,$E6,$20,$A0,$A0,$A0,$A0,$A0,$E6,$E6,$E6,$20,$A0,$A0,$A0,$E6,$66,$20
                BYTE    $66,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$A0,$A0,$A0,$A0,$A0,$E6,$E6,$E6,$20,$E6,$E6,$E6,$E6,$66,$20
                BYTE    $66,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$20,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$E6,$E6,$E6,$20,$A0,$A0,$A0,$A0,$A0,$20
                BYTE    $66,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$20
                BYTE    $66,$20,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$20
                BYTE    $66,$20,$66,$66,$66,$66,$66,$66,$66,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$20
                BYTE    $66,$20,$66,$66,$66,$66,$66,$66,$66,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$20
                BYTE    $66,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20

                ; Screen 1 - 0,0 City Colour data
                BYTE    $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
                BYTE    $05,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
                BYTE    $05,$01,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$0F,$0F,$0F,$01,$01,$01,$01,$01,$01,$01,$01,$01,$07,$07,$07,$07,$07,$07,$05,$05,$01
                BYTE    $05,$01,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$0F,$0F,$0F,$01,$01,$01,$01,$01,$01,$01,$01,$01,$07,$07,$07,$07,$07,$07,$05,$05,$01
                BYTE    $05,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
                BYTE    $05,$01,$07,$07,$07,$07,$05,$01,$01,$01,$05,$05,$05,$05,$05,$01,$0F,$0F,$0F,$01,$01,$05,$0F,$0F,$0F,$01,$05,$05,$05,$05,$05,$05,$05,$05,$01,$05,$05,$05,$05,$01
                BYTE    $05,$01,$07,$07,$07,$07,$05,$01,$01,$01,$05,$05,$05,$05,$05,$01,$0F,$0F,$0F,$01,$01,$05,$0F,$0F,$0F,$01,$0C,$0C,$0C,$0C,$05,$05,$05,$05,$01,$08,$08,$08,$08,$01
                BYTE    $05,$01,$07,$07,$07,$07,$05,$01,$01,$01,$0C,$0C,$05,$08,$08,$01,$0F,$0F,$0F,$01,$01,$05,$0F,$0F,$0F,$01,$0C,$0C,$0C,$0C,$05,$07,$07,$07,$01,$08,$08,$08,$08,$01
                BYTE    $05,$01,$01,$01,$01,$01,$01,$01,$01,$01,$0C,$0C,$05,$08,$08,$01,$0F,$0F,$0F,$01,$01,$05,$0F,$0F,$0F,$01,$0C,$0C,$0C,$0C,$05,$07,$07,$07,$01,$08,$08,$08,$08,$01
                BYTE    $05,$01,$05,$08,$08,$08,$08,$08,$08,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
                BYTE    $05,$01,$05,$08,$08,$08,$08,$08,$08,$01,$02,$02,$02,$02,$05,$07,$07,$07,$01,$08,$08,$08,$08,$08,$05,$07,$07,$07,$05,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$01
                BYTE    $05,$01,$05,$08,$08,$08,$08,$08,$08,$01,$02,$02,$02,$02,$05,$07,$07,$07,$01,$08,$08,$08,$08,$08,$05,$07,$07,$07,$05,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$01
                BYTE    $05,$01,$05,$08,$08,$08,$08,$08,$08,$01,$02,$02,$02,$02,$05,$07,$07,$07,$01,$08,$08,$08,$08,$08,$05,$05,$05,$05,$05,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$01
                BYTE    $05,$01,$05,$08,$08,$08,$08,$08,$08,$01,$05,$05,$05,$05,$05,$05,$05,$05,$01,$08,$01,$08,$08,$08,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$01
                BYTE    $05,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
                BYTE    $05,$01,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$01,$02,$02,$02,$02,$02,$02,$02,$01,$0C,$0C,$0C,$0C,$0C,$0C,$01,$02,$02,$02,$02,$02,$05,$01,$01,$01,$0F,$0F,$0F,$05,$05,$01
                BYTE    $05,$01,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$01,$02,$02,$02,$02,$02,$02,$02,$01,$0C,$0C,$0C,$0C,$0C,$0C,$01,$02,$02,$02,$02,$02,$05,$01,$01,$01,$0F,$0F,$0F,$05,$05,$01
                BYTE    $05,$01,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$01,$02,$02,$02,$02,$02,$02,$02,$01,$05,$05,$05,$05,$05,$05,$01,$02,$02,$02,$02,$02,$05,$05,$05,$01,$0F,$0F,$0F,$05,$05,$01
                BYTE    $05,$01,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$02,$02,$02,$02,$02,$05,$05,$05,$01,$05,$05,$05,$05,$05,$01
                BYTE    $05,$01,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$01,$05,$05,$05,$05,$05,$05,$05,$01,$02,$02,$02,$02,$02,$02,$01,$02,$02,$02,$02,$02,$05,$05,$05,$01,$07,$07,$07,$07,$07,$01
                BYTE    $05,$01,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$01,$07,$07,$07,$07,$07,$07,$07,$01,$02,$02,$02,$02,$02,$02,$01,$02,$02,$02,$02,$02,$08,$08,$08,$01,$07,$07,$07,$07,$07,$01
                BYTE    $05,$01,$05,$05,$05,$05,$05,$05,$05,$01,$07,$07,$07,$07,$07,$07,$07,$01,$02,$02,$02,$02,$02,$02,$01,$02,$02,$02,$02,$02,$08,$08,$08,$01,$07,$07,$07,$07,$07,$01
                BYTE    $05,$01,$05,$05,$05,$05,$05,$05,$05,$01,$07,$07,$07,$07,$07,$07,$07,$01,$02,$02,$02,$02,$02,$02,$01,$08,$08,$08,$08,$08,$08,$08,$08,$01,$0F,$0F,$0F,$0F,$0F,$01
                BYTE    $05,$01,$05,$05,$05,$05,$05,$05,$05,$01,$07,$07,$07,$07,$07,$07,$07,$01,$02,$02,$02,$02,$02,$02,$01,$08,$08,$08,$08,$08,$08,$08,$08,$01,$0F,$0F,$0F,$0F,$0F,$01
                BYTE    $05,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01

                ; Screen 2 - 1,0 City Screen data
                BYTE    $66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$A0,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$A0,$A0,$A0,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$A0,$A0,$A0,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66

                ; Screen 2 - 1,0 City Colour data
                BYTE    $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$0F,$01,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$0F,$0F,$0F,$0F,$0F,$0F,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$0F,$0F,$0F,$0F,$0F,$0F,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05

                ; Screen 3 - 0,1 City Screen data
                BYTE    $66,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
                BYTE    $66,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
                BYTE    $66,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
                BYTE    $66,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
                BYTE    $66,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
                BYTE    $66,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
                BYTE    $66,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
                BYTE    $66,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$A0,$A0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
                BYTE    $66,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$A0,$A0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
                BYTE    $66,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$A0,$A0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
                BYTE    $66,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
                BYTE    $66,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
                BYTE    $66,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
                BYTE    $66,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
                BYTE    $66,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
                BYTE    $66,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
                BYTE    $66,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
                BYTE    $66,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
                BYTE    $66,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
                BYTE    $66,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
                BYTE    $66,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
                BYTE    $66,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
                BYTE    $66,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
                BYTE    $66,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
                BYTE    $66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66

                ; Screen 3 - 0,1 City Colour data
                BYTE    $05,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
                BYTE    $05,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
                BYTE    $05,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
                BYTE    $05,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
                BYTE    $05,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
                BYTE    $05,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
                BYTE    $05,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
                BYTE    $05,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$08,$08,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
                BYTE    $05,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$08,$08,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
                BYTE    $05,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$08,$08,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
                BYTE    $05,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$08,$08,$08,$08,$08,$08,$08,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
                BYTE    $05,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$08,$08,$08,$08,$08,$08,$08,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
                BYTE    $05,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
                BYTE    $05,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
                BYTE    $05,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
                BYTE    $05,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
                BYTE    $05,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
                BYTE    $05,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
                BYTE    $05,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
                BYTE    $05,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
                BYTE    $05,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
                BYTE    $05,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
                BYTE    $05,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
                BYTE    $05,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
                BYTE    $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05

                ; Screen 4 - 1,1 City Screen data
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$A0,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$A0,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$A0,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$A0,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$A0,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$A0,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$A0,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$A0,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$A0,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66
                BYTE    $66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66,$66

                ; Screen 4 - 1,1 City Colour data
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$0F,$0F,$0F,$0F,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$0F,$0F,$0F,$0F,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$0F,$0F,$0F,$0F,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$0F,$0F,$0F,$0F,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$0F,$0F,$0F,$0F,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$0F,$0F,$0F,$0F,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$0F,$0F,$0F,$0F,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$02,$02,$02,$02,$02,$02,$02,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$0F,$0F,$0F,$0F,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$02,$02,$02,$02,$02,$02,$02,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$0F,$0F,$0F,$0F,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$02,$02,$02,$02,$02,$02,$02,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$05
                BYTE    $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
