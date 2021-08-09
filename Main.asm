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
KERNAL_ISR = $ea31

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
                lda #0
                jsr draw_player

; Setup raster line-based interrupt structure
                lda #$7f
                sta $dc0d
                lda $dc0d
                sei
                lda #1
                sta $d01a
                lda #60
                sta $d012
                lda $d011
                and #$7f
                sta $d011
                lda #<mainloop
                sta $0314
                lda #>mainloop
                sta $0315
                cli
setup_done      jmp setup_done

; Main loop (raster line-based interrupt handler)
mainloop
                inc $d019 ; ACK interrupt
                lda int_counter
                cmp #14
                beq our_isr
                inc int_counter
                jmp KERNAL_ISR

our_isr         inc int_counter
                lda #0 ; Reset int_counter
                sta int_counter

; Make a copy of the current position
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
                jmp mainloop_end
@go_w           lda #1
                jsr draw_player
                jmp mainloop_end

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
                jmp mainloop_end
@go_s           lda #1
                jsr draw_player
                jmp mainloop_end

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
                jmp mainloop_end
@go_a           lda #1
                jsr draw_player
                jmp mainloop_end

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
                jmp mainloop_end
@go_d           lda #1
                jsr draw_player

                ; Bottom of main loop
mainloop_end    jmp KERNAL_ISR ; Regular interrupt handling

player_x        BYTE 20
player_y        BYTE 5

player_x_prev   BYTE 0
player_y_prev   BYTE 0

map_data_start  BYTE 0, 0

temp            BYTE 0, 0, 0, 0, 0, 0

int_counter     BYTE 0

; Map data
map_data
                BYTE    $18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18
                BYTE    $18,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$18
                BYTE    $18,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$18
                BYTE    $18,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$18
                BYTE    $18,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$18
                BYTE    $18,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$18
                BYTE    $18,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$18
                BYTE    $18,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$18
                BYTE    $18,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$18
                BYTE    $18,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$18
                BYTE    $18,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$A0,$A0,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$18
                BYTE    $18,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$A0,$A0,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$18
                BYTE    $18,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$A0,$A0,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$18
                BYTE    $18,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$A0,$20,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$18
                BYTE    $18,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$18
                BYTE    $18,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$18
                BYTE    $18,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$18
                BYTE    $18,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$18
                BYTE    $18,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$18
                BYTE    $18,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$18
                BYTE    $18,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$18
                BYTE    $18,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$18
                BYTE    $18,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$18
                BYTE    $18,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
                BYTE    $18,$20,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18

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
                ;   jsr redraw_vp_row
                ;   Add 40 to map_data pointer
                ;   Add 40 to screen pointer

                ldx #0
@loop           jsr draw_screen_row
                cpx #25
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
                cpy #40
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
                lda #00
                ldx player_y   ; row
                ldy player_x   ; column
                jsr put_char

                ; Display new position (X)
                ldx #2 ; Row
                ldy #2 ; Column
                clc    ; Set cursor position
                jsr POSCURS
                ldx player_x
                lda #0
                jsr NUMOUT

                ; Display new position (Y)
                ldx #3 ; Row
                ldy #2 ; Column
                clc    ; Set cursor position
                jsr POSCURS
                ldx player_y
                lda #0
                jsr NUMOUT

                ; Done
                rts