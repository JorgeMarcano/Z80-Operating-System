;---------------------------
;
; For Input from keyboard
;
;---------------------------

text_page_y             EQU 0xBFFB
text_page_x             EQU 0xBFFC
text_cursor             EQU 0xBFFD  ; Cursor follows the pattern 0bLL0CCCCC where L is line nb, and C char nb
keyboard_status         EQU 0xBFFE
text_must_refresh	EQU 0xBFFF
text_buffer 			EQU	0xC000

text_buffer_line_size   EQU 64
text_buffer_line_count  EQU 64
text_page_x_max         EQU text_buffer_line_size - lcd_line_length - 1
text_page_y_max         EQU text_buffer_line_count - 4 - 1
text_buffer_size        EQU text_buffer_line_size * text_buffer_line_count

keyboard_status_shift   EQU 0b00000001
keyboard_status_ctrl    EQU 0b00000010
keyboard_status_alt     EQU 0b00000100
keyboard_status_caps    EQU 0b00001000
; keyboard_status_winkey  EQU 0b00010000
keyboard_status_release EQU 0b10000000
keyboard_status_rel_bit EQU 7
keyboard_status_cap_bit EQU 3
keyboard_status_shi_bit EQU 0

keyboard_code_backspace	EQU 0x66
keyboard_code_left		EQU	0x6B
keyboard_code_right		EQU	0x74
keyboard_code_down      EQU 0x72
keyboard_code_up        EQU 0x75
keyboard_code_enter     EQU 0x5A
keyboard_code_release   EQU 0XF0
keyboard_code_extended  EQU 0xE0
keyboard_code_shift_l   EQU 0x12
keyboard_code_shift_r   EQU 0x59
keyboard_code_ctrl      EQU 0x14
keyboard_code_alt       EQU 0x11
keyboard_code_capslock  EQU 0x58
keyboard_code_delete    EQU 0x71
; keyboard_code_winkey

input_setup:
 EX AF, AF'
 EXX
 
 XOR A
 LD (text_must_refresh), A
 LD (keyboard_status), A
 LD (text_cursor), A
 LD (text_page_x), A
 LD (text_page_y), A

; Empty the text_buffer
 LD HL, text_buffer
 LD BC, text_buffer_size
 CALL string_clear
 
 LD A, pio_input_word
 OUT (pio_b_ctrl), A
 LD A, LO(interrupts_table)
 OUT (pio_b_ctrl), A
 LD A, pio_enable_int
 OUT (pio_b_ctrl), A
 
 EXX
 EX AF, AF'
 RET

keyboard_interrupt:
 EX AF, AF'
 EXX
 
 IN A, (pio_b_data)

;  CALL print_hex

; Check for Extended Prefix
keyboard_int_extended:
 CP keyboard_code_extended
 JP NZ, keyboard_int_release
 JP end_keyboard_int_bypass_release
;  JP keyboard_int_add_char

; Check for Release Prefix
keyboard_int_release:
 CP keyboard_code_release
 JP NZ, keyboard_int_shift
 LD A, (keyboard_status)
 OR keyboard_status_release
 LD (keyboard_status), A
 JP end_keyboard_int_bypass_release
;  JP keyboard_int_add_char

; Check shift (both left and right)
keyboard_int_shift:
 CP keyboard_code_shift_l
 JP Z, keyboard_int_shift_good
 CP keyboard_code_shift_r
 JP NZ, keyboard_int_ctrl
keyboard_int_shift_good:
 LD D, keyboard_status_shift
 CALL keyboard_set_status_cond
 JP end_keyboard_int

; Check ctrl
keyboard_int_ctrl:
 CP keyboard_code_ctrl
 JP NZ, keyboard_int_alt
 LD D, keyboard_status_ctrl
 CALL keyboard_set_status_cond
 JP end_keyboard_int

; Check alt
keyboard_int_alt:
 CP keyboard_code_alt
 JP NZ, keyboard_int_not_ctrl_word
 LD D, keyboard_status_alt
 CALL keyboard_set_status_cond
 JP end_keyboard_int

keyboard_int_not_ctrl_word:
; Skip if it is a release word
 LD C, A
 LD A, (keyboard_status)
 BIT keyboard_status_rel_bit, A
 JP NZ, end_keyboard_int
 LD A, C

; Check for backspace
keyboard_int_backspace:
 CP keyboard_code_backspace
 JP NZ, keyboard_int_delete
; Check to see if it already at the beginning, if so, do nothing
 LD A, (text_cursor)
 LD D, 0x00
 CP D
 JP NZ, keyboard_int_backspace_good
 LD A, (text_page_x)
 CP D
 JP NZ, keyboard_int_backspace_good
 LD A, (text_page_y)
 CP D
 JP Z, end_keyboard_int
keyboard_int_backspace_good:
; TODO: perform backspace
    ; CASES: regular mid-line -> move cursor left and simply shift line over to the left
    ; beginning of line, shift entire buffer after previous line over until you find previous line's '\n'
; If not at beginning, shift everything over
/* TODO:remove block comment
 DEC A
 LD (keyboard_cursor), A
 LD E, A
 LD HL, keyboard_buffer
 ADD HL, DE
 CP (HL)
 JP Z, end_keyboard_int
 LD DE, HL
 INC HL
 CALL string_copy_null*/
 JP end_keyboard_int

; Check for delete
keyboard_int_delete:
 CP keyboard_code_delete
 JP NZ, keyboard_int_left
; TODO: perform delete
    ; CASES: if regular delete mid-line, simply shift line over to the left
    ; If at the end of line, shift entire buffer by exactly one line worth of characters
; Shift everything over
/* TODO: remove block comment
 LD A, (keyboard_cursor)
 LD E, A
 XOR A
 LD D, A
 LD HL, keyboard_buffer
 ADD HL, DE
 CP (HL)
 JP Z, end_keyboard_int
 LD DE, HL
 INC HL
 CALL string_copy_null */
 JP end_keyboard_int
 
; Check left arrow
keyboard_int_left:
 CP keyboard_code_left
 JP NZ, keyboard_int_right
; FIXME: Keep moving to the left until a non-null value is found
; FIXME: Exception to above is when reach beginning of buffer, stop
 CALL cursor_move_left
 JP end_keyboard_int

; Check right arrow
keyboard_int_right:
 CP keyboard_code_right
 JP NZ, keyboard_int_down
; FIXME: Keep moving to the right until a non-null value is found
; FIXME: Exception to above is when reach end of buffer, stop
 CALL cursor_move_right
 JP end_keyboard_int

; Check down arrow
keyboard_int_down:
 CP keyboard_code_down
 JP NZ, keyboard_int_up
; FIXME: If after going down, arrive at null value, move left until non-null
; FIXME: Exception to above is when reach beginning of buffer, stop
 CALL cursor_move_down
 JP end_keyboard_int

; Check up arrow
keyboard_int_up:
 CP keyboard_code_up
 JP NZ, keyboard_int_enter
; FIXME: If after going up, arrive at null value, move left until non-null
; FIXME: Exception to above is when reach beginning of buffer, stop
 CALL cursor_move_up
 JP end_keyboard_int

; Check for enter
keyboard_int_enter:
 CP keyboard_code_enter
 JP NZ, keyboard_int_capslock
; TODO: Implement enter, adds '\n' and shifts the entire buffer over to the next line
 
; Check capslock
keyboard_int_capslock:
 CP keyboard_code_capslock
 JP NZ, keyboard_int_add_char
 LD D, keyboard_status_caps
 LD A, (keyboard_status)
 XOR D
 LD (keyboard_status), A
 JP end_keyboard_int

; Regular Alphanumeric Input
keyboard_int_add_char:
 LD A, (keyboard_status)
 LD D, A
; Check for caps lock
 XOR A
 BIT keyboard_status_cap_bit, D
 JP Z, keyboard_int_char_skip_caps
 INC A
keyboard_int_char_skip_caps:
; Check for shift
 BIT keyboard_status_shi_bit, D
 JP Z, keyboard_int_char_skip_shift
 XOR 0x01
keyboard_int_char_skip_shift:
 ADD code_addr_high
 LD B, A

; Set current buffer position
 CALL cursor_get_buffer_location
 LD HL, text_buffer
 ADD HL, DE
; Save character
 LD A, (BC)
 LD (HL), A
; Increment cursor to the right
 CALL cursor_move_right
 
end_keyboard_int:
 LD A, (keyboard_status)
 AND keyboard_status_release ^ 0xff
 LD (keyboard_status), A
 LD A, 0x01
 LD (text_must_refresh), A
end_keyboard_int_bypass_release:
 EXX
 EX AF, AF'
 EI
 RETI

; Sets or resets a status bit depending
; if the key is pressed or released
; D contains the status bit
; A is lost
keyboard_set_status_cond:
 LD A, (keyboard_status)
 BIT keyboard_status_rel_bit, A
 JP Z, keyboard_set_status_cond_press
; If here then it is a release
 XOR 0xff
 OR D
 XOR 0xff
 LD (keyboard_status), A
 RET
; If here then it is a press
keyboard_set_status_cond_press:
 OR D
 LD (keyboard_status), A
 RET

; Gets the buffer location currently pointed to by the cursor
; Stores the location in DE
cursor_get_buffer_location:
 PUSH AF
 PUSH BC
 PUSH HL
 LD A, (text_cursor)
 LD D, A
; Get character position offset, stored in E
 AND 0b00011111
 LD E, A
 LD A, (text_page_x)
 ADD E
 LD E, A
; Get line position
 LD A, D
 SRL A
 SRL A
 SRL A
 SRL A
 SRL A
 SRL A
 LD HL, text_page_y
 ADD (HL)

; Perform 64*(y+cursorLine) + x+cursorChar
 LD B, text_buffer_line_size
 LD C, E
 CALL linear
 LD E, A

 POP HL
 POP BC
 POP AF
 RET

; Move cursor to the right
; If the cursor overflows from the LCD, move page to the right
; If the page cursor overflows from the line, reset cursor to 0 on line (and set pageX to 0), and move cursor down
cursor_move_right:
 PUSH AF
 PUSH BC
 PUSH HL
; Get cursor X offset
 LD A, (text_cursor)
 LD C, A
 AND 0b11100000
 LD B, A
 LD A, C
 AND 0b00011111
; Increase, if less than 20, then done
 INC A
 CP lcd_line_length
 JP C, end_cursor_move_right
; If 20 (or over, but should never be over 20)
; Increase the page X
; Set cursor offset back to 19
 LD HL, text_page_x
 INC (HL)
 LD A, text_page_x_max
 CP (HL)
 JP NC, cursor_move_right_skip_newline
; If reached the end of a line
; Must reset the pageX to 0
; Must reset cursor to 0
; Must call a cursor move down
 XOR A
 LD (HL), A
 OR B
 LD (text_cursor), A
 CALL cursor_move_down
 JP end_cursor_move_right_skip_cursor

cursor_move_right_skip_newline:
 LD A, lcd_line_length - 1

end_cursor_move_right:
; Merge X offset (A), with line offset (upper bits of B)
 OR B
 LD (text_cursor), A
end_cursor_move_right_skip_cursor:
 POP HL
 POP BC
 POP AF
 RET

; Move cursor to the left
; If the cursor X offset less than 0, move page to the left
; If the page cursor underflows from the line, reset cursor to max on line (and set pageX to max), and move cursor up, if pageY != 0
cursor_move_left:
 PUSH AF
 PUSH BC
 PUSH HL
; Get cursor X offset
 LD A, (text_cursor)
 LD C, A
 AND 0b11100000
 LD B, A
 LD A, C
 AND 0b00011111
; Decrease, if no borrow, then done
 CP 0x00
 JP Z, cursor_move_left_borrow
 DEC A
 JP end_cursor_move_left
; If borrow, decrease the page X
; Set cursor offset back to 0
cursor_move_left_borrow:
 LD A, (text_page_x)
 CP 0x00
 JP Z, cursor_move_left_newline
 DEC A
 JP cursor_move_left_skip_newline
; If underflowed, if !(pageY == 0 && cursorY == 0)
; Must set the pageX to max
; Must set cursor to max
; Must call a cursor move up
cursor_move_left_newline:
 LD A, (text_page_y)
 CP 0X00
 JP NZ, cursor_move_left_newline_good
 CP B
 JP Z, cursor_move_left_skip_newline
cursor_move_left_newline_good:
 LD A, text_page_x_max
 LD (text_page_x), A
 LD A, lcd_line_length - 1
 OR B
 LD (text_cursor), A
 CALL cursor_move_up
 JP end_cursor_move_left_skip_cursor

cursor_move_left_skip_newline:
 LD (text_page_x), A
 XOR A
end_cursor_move_left:
; Merge X offset (A), with line offset (upper bits of B)
 OR B
 LD (text_cursor), A
end_cursor_move_left_skip_cursor:
 POP HL
 POP BC
 POP AF
 RET

; Move cursor down
; If cursor already on line 4, then increase pageY
; If cursor already on line 4 on pageY 60, then do nothing
cursor_move_down:
 PUSH AF
 PUSH BC
 PUSH HL
 
 LD A, (text_cursor)
 LD C, A
 AND 0b00011111
 LD B, A
 LD A, C
 AND 0b11100000
 ADD 0b01000000
 JP NC, end_cursor_move_down
; If cursor already was on line 4,
; Increase PageY
; Set cursor line back to 4
 LD A, (text_page_y)
 INC A
 CP text_page_y_max
 JP Z, cursor_move_down_skip_page_save
 LD (text_page_y), A
cursor_move_down_skip_page_save:
 LD A, 0b11000000
end_cursor_move_down:
 OR B
 LD (text_cursor), A

 POP HL
 POP BC
 POP AF
 RET

; Move cursor up
; If cursor already on line 0, decrease pageY
; If cursor already on line 0 on pageY 0, then do nothing
cursor_move_up:
 PUSH AF
 PUSH BC
 PUSH HL

 LD A, (text_cursor)
 LD C, A
 AND 0b00011111
 LD B, A
 LD A, C
 AND 0b11100000
 SUB 0b01000000
 JP NC, end_cursor_move_up
; If cursor was already on line 0
; Decrease pageY
; Set cursor line back to 0
 LD A, (text_page_y)
 CP 0x00
 JP Z, cursor_move_up_reset_cursor
 DEC A
 LD (text_page_y), A
 JP cursor_move_up_skip_newline

cursor_move_up_reset_cursor:
 LD B, A
cursor_move_up_skip_newline:
 XOR A
end_cursor_move_up:
 OR B
 LD (text_cursor), A
 POP HL
 POP BC
 POP AF
 RET
