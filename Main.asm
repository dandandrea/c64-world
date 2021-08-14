; BASIC loader
* = $0801
                BYTE $0E, $08, $0A, $00, $9E, $20, $28,  $34, $30, $39, $36, $29, $00, $00, $00

; Check for key press
defm            check_key
                lda $cb  ; Current key pressed
                cmp #/1
                bne @not_pressed
                lda #1
                jmp @check_key_done
@not_pressed    lda #0
@check_key_done nop
endm

; Compare a 16 bit number for equality to another 16 bit number
; 0 = equal, 1 = greater than, 2 = less-than
defm            compare_numbers
                ; Check MSBs first
                lda /2
                cmp /4
                bcs @eq_gt1
                ; MSB 1 < MSB 2
                lda #2
                jmp @check_done
@eq_gt1         bne @gt
                ; MSBs are equal, now compare LSBs
                lda /1
                cmp /3
                bcs @eq_gt2
                ; MSB 1 = MSB 2, LSB 1 < LSB 2
                lda #2
                jmp @check_done
@eq_gt2         bne @gt
                ; MSBs and LSBs are equal
                lda #0
                jmp @check_done
@gt             lda #1
@check_done     nop
endm

; Decrement a 16 bit number
defm            decrement_number
                lda /1
                bne @skip
                dec /1 + 1
@skip           dec /1
endm

; Increment a 16 bit number
defm            increment_number
                lda /1
                cmp #255
                bne @skip
                inc /1 + 1
@skip           inc /1
endm

; Program starts at $1000
* = $1000

; KERNAL functions
NUMOUT = $bdcd
CHROUT = $ffd2
POSCURS = $fff0

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

; Process key presses
; Move up?
check_w         check_key 9
                cmp #1
                bne check_s
                compare_numbers player_y, #0, #0, #0
                cmp #0
                beq check_s
                dec player_y
                ; Don't move into non-blank position
                ldx player_y
                ldy player_x
                jsr get_char
                cmp #32
                beq @go_w
                inc player_y
                jmp mainloop
@go_w           lda #1
                jsr draw_player
                jsr delay
                jmp mainloop

; Move down?
check_s         check_key 13
                cmp #1
                bne check_a
                compare_numbers player_y, #0, #24, #0
                cmp #0
                beq check_a
                inc player_y
                ; Don't move into non-blank position
                ldx player_y
                ldy player_x
                jsr get_char
                cmp #32
                beq @go_s
                dec player_y
                jmp mainloop
@go_s           lda #1
                jsr draw_player
                jsr delay
                jmp mainloop

; Move left?
check_a         check_key 10
                cmp #1
                bne check_d
                compare_numbers player_x, #0, #0, #0
                cmp #0
                beq check_d
                dec player_x
                ; Don't move into non-blank position
                ldx player_y
                ldy player_x
                jsr get_char
                cmp #32
                beq @go_a
                inc player_x
                jmp mainloop
@go_a           lda #1
                jsr draw_player
                jsr delay
                jmp mainloop

; Move right?
check_d         check_key 18
                cmp #1
                bne mainloop_end
                compare_numbers player_x, #0, #39, #0
                cmp #0
                beq mainloop_end
                inc player_x
                ; Don't move into non-blank position
                ldx player_y
                ldy player_x
                jsr get_char
                cmp #32
                beq @go_d
                dec player_x
                jmp mainloop
@go_d           lda #1
                jsr draw_player
                jsr delay

; Bottom of main loop
mainloop_end    jmp mainloop

player_x        BYTE 20
player_y        BYTE 4

player_x_prev   BYTE 0
player_y_prev   BYTE 0

map_data_start  BYTE 0, 0

temp            BYTE 0, 0, 0, 0, 0, 0

; Map data
map_data
                ; Screen 1 - 0,0 City Screen data
                BYTE    $55,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$49
                BYTE    $42,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$42
                BYTE    $42,$20,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$A0,$E6,$20,$42
                BYTE    $42,$20,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$A0,$E6,$20,$42
                BYTE    $42,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$42
                BYTE    $42,$20,$A0,$A0,$A0,$A0,$E6,$A0,$A0,$20,$E6,$E6,$E6,$E6,$E6,$20,$A0,$A0,$A0,$A0,$A0,$E6,$A0,$A0,$A0,$20,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$20,$E6,$E6,$E6,$20,$42
                BYTE    $42,$20,$A0,$A0,$A0,$A0,$E6,$A0,$A0,$20,$E6,$E6,$E6,$E6,$E6,$20,$A0,$A0,$A0,$A0,$A0,$E6,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$E6,$E6,$E6,$E6,$20,$A0,$A0,$A0,$20,$42
                BYTE    $42,$20,$A0,$A0,$A0,$A0,$E6,$A0,$A0,$20,$A0,$A0,$E6,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$E6,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$E6,$A0,$A0,$A0,$20,$A0,$A0,$A0,$20,$42
                BYTE    $42,$20,$20,$20,$20,$20,$20,$20,$20,$20,$A0,$A0,$E6,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$E6,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$E6,$A0,$A0,$A0,$20,$A0,$A0,$A0,$20,$42
                BYTE    $42,$20,$E6,$A0,$A0,$A0,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$42
                BYTE    $42,$20,$E6,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$E6,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$E6,$A0,$A0,$A0,$E6,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$42
                BYTE    $42,$20,$E6,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$E6,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$E6,$A0,$A0,$A0,$E6,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$42
                BYTE    $42,$20,$E6,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$E6,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$E6,$E6,$E6,$E6,$E6,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$42
                BYTE    $42,$20,$E6,$A0,$A0,$A0,$A0,$A0,$A0,$20,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$20,$A0,$20,$A0,$A0,$A0,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$20,$42
                BYTE    $42,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$42
                BYTE    $42,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$E6,$A0,$A0,$20,$A0,$A0,$A0,$E6,$20,$42
                BYTE    $42,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$E6,$A0,$A0,$20,$A0,$A0,$A0,$E6,$20,$42
                BYTE    $42,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$E6,$E6,$E6,$E6,$E6,$E6,$20,$A0,$A0,$A0,$A0,$A0,$E6,$E6,$E6,$20,$A0,$A0,$A0,$E6,$20,$42
                BYTE    $42,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$A0,$A0,$A0,$A0,$A0,$E6,$E6,$E6,$20,$E6,$E6,$E6,$E6,$20,$42
                BYTE    $42,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$20,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$E6,$E6,$E6,$20,$A0,$A0,$A0,$A0,$20,$42
                BYTE    $42,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$20,$42
                BYTE    $42,$20,$E6,$E6,$E6,$E6,$E6,$E6,$E6,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$20,$42
                BYTE    $42,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$42
                BYTE    $42,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
                BYTE    $4A,$43,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$20,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$4B

                ; Screen 1 - 0,0 City Colour data
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
                BYTE    $01,$01,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$0F,$0F,$0F,$01,$01,$01,$01,$01,$01,$01,$01,$01,$07,$07,$07,$07,$07,$07,$05,$01,$01
                BYTE    $01,$01,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$0F,$0F,$0F,$01,$01,$01,$01,$01,$01,$01,$01,$01,$07,$07,$07,$07,$07,$07,$05,$01,$01
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
                BYTE    $01,$01,$07,$07,$07,$07,$05,$01,$01,$01,$05,$05,$05,$05,$05,$01,$0F,$0F,$0F,$01,$01,$05,$0F,$0F,$0F,$01,$05,$05,$05,$05,$05,$05,$05,$05,$01,$05,$05,$05,$01,$01
                BYTE    $01,$01,$07,$07,$07,$07,$05,$01,$01,$01,$05,$05,$05,$05,$05,$01,$0F,$0F,$0F,$01,$01,$05,$0F,$0F,$0F,$01,$0C,$0C,$0C,$0C,$05,$05,$05,$05,$01,$08,$08,$08,$01,$01
                BYTE    $01,$01,$07,$07,$07,$07,$05,$01,$01,$01,$0C,$0C,$05,$08,$08,$01,$0F,$0F,$0F,$01,$01,$05,$0F,$0F,$0F,$01,$0C,$0C,$0C,$0C,$05,$07,$07,$07,$01,$08,$08,$08,$01,$01
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$0C,$0C,$05,$08,$08,$01,$0F,$0F,$0F,$01,$01,$05,$0F,$0F,$0F,$01,$0C,$0C,$0C,$0C,$05,$07,$07,$07,$01,$08,$08,$08,$01,$01
                BYTE    $01,$01,$05,$08,$08,$08,$08,$08,$08,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
                BYTE    $01,$01,$05,$08,$08,$08,$08,$08,$08,$01,$02,$02,$02,$02,$05,$07,$07,$07,$01,$08,$08,$08,$08,$08,$05,$07,$07,$07,$05,$02,$02,$02,$02,$02,$02,$02,$02,$02,$01,$01
                BYTE    $01,$01,$05,$08,$08,$08,$08,$08,$08,$01,$02,$02,$02,$02,$05,$07,$07,$07,$01,$08,$08,$08,$08,$08,$05,$07,$07,$07,$05,$02,$02,$02,$02,$02,$02,$02,$02,$02,$01,$01
                BYTE    $01,$01,$05,$08,$08,$08,$08,$08,$08,$01,$02,$02,$02,$02,$05,$07,$07,$07,$01,$08,$08,$08,$08,$08,$05,$05,$05,$05,$05,$02,$02,$02,$02,$02,$02,$02,$02,$02,$01,$01
                BYTE    $01,$01,$05,$08,$08,$08,$08,$08,$08,$01,$05,$05,$05,$05,$05,$05,$05,$05,$01,$08,$01,$08,$08,$08,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$01,$01
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
                BYTE    $01,$01,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$01,$02,$02,$02,$02,$02,$02,$02,$01,$0C,$0C,$0C,$0C,$0C,$0C,$01,$02,$02,$02,$02,$02,$05,$01,$01,$01,$0F,$0F,$0F,$05,$01,$01
                BYTE    $01,$01,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$01,$02,$02,$02,$02,$02,$02,$02,$01,$0C,$0C,$0C,$0C,$0C,$0C,$01,$02,$02,$02,$02,$02,$05,$01,$01,$01,$0F,$0F,$0F,$05,$01,$01
                BYTE    $01,$01,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$01,$02,$02,$02,$02,$02,$02,$02,$01,$05,$05,$05,$05,$05,$05,$01,$02,$02,$02,$02,$02,$05,$05,$05,$01,$0F,$0F,$0F,$05,$01,$01
                BYTE    $01,$01,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$02,$02,$02,$02,$02,$05,$05,$05,$01,$05,$05,$05,$05,$01,$01
                BYTE    $01,$01,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$01,$05,$05,$05,$05,$05,$05,$05,$01,$02,$02,$02,$02,$02,$02,$01,$02,$02,$02,$02,$02,$05,$05,$05,$01,$07,$07,$07,$07,$01,$01
                BYTE    $01,$01,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$01,$07,$07,$07,$07,$07,$07,$07,$01,$02,$02,$02,$02,$02,$02,$01,$02,$02,$02,$02,$02,$08,$08,$08,$01,$07,$07,$07,$07,$01,$01
                BYTE    $01,$01,$05,$05,$05,$05,$05,$05,$05,$01,$07,$07,$07,$07,$07,$07,$07,$01,$02,$02,$02,$02,$02,$02,$01,$02,$02,$02,$02,$02,$08,$08,$08,$01,$07,$07,$07,$07,$01,$01
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
                BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01

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