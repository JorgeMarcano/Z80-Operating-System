;---------------------------
;
; For Input from keyboard
;
;---------------------------

keyboard_status         EQU 0xBFF0

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
 PUSH AF
 PUSH BC
 PUSH HL

 XOR A
 LD (keyboard_status), A
 
 LD A, pio_input_word
 OUT (pio_b_ctrl), A
 LD A, LO(interrupts_table)
 OUT (pio_b_ctrl), A
 LD A, pio_enable_int
 OUT (pio_b_ctrl), A
 
 POP HL
 POP BC
 POP AF
 RET

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

; Move cursor to the right
; If cursor points at null, revert and do nothing
; If cursor points at '\n', reset pageX and increase cursorY
; If the cursor overflows from the LCD, move page to the right
cursor_move_right:
 PUSH AF
 PUSH BC
 PUSH HL

 CALL cursor_get_location
 XOR A
 CP (HL)
 JP Z, end_cursor_move_right
 INC HL
 CP (HL)
 JP Z, end_cursor_move_right
 LD A, '\n'
 CP (HL)
 JP NZ, cursor_move_right_set
; Increase pointer again
; If non-null: reset pageX and cursorX to 0,
; increase cursorY by 1 (unless overflow, in which case leave cursorY at 3 and increase pageY)
 INC HL
 XOR A
 CP (HL)
 JP Z, end_cursor_move_right
 LD (display_page_x), A

 LD A, (text_cursor)
 AND 0b11000000
 ADD 0b01000000
 LD (text_cursor), A
 JP NZ, end_cursor_move_right
 LD A, 0b11000000
 LD (text_cursor), A
 LD HL, display_page_y
 INC (HL)
 JP NZ, end_cursor_move_right
 DEC (HL)
 JP end_cursor_move_right

cursor_move_right_set:
 LD A, (text_cursor)
 LD B, A
 AND 0b11000000
 LD C, A
 LD A, B
 AND 0b00011111
 INC A
 CP 0x14
 JP Z, cursor_move_right_next_line
 OR C
 LD (text_cursor), A

cursor_move_right_next_line:
 LD A, (display_page_x)
 INC A
 JP Z, end_cursor_move_right
 LD (display_page_x), A
 
end_cursor_move_right
 POP HL
 POP BC
 POP AF
 RET

; Move cursor to the left
; If cursor points at beginning, revert and do nothing
; If cursor points at '\n', reset pageX and increase cursorY
; If the cursor overflows from the LCD, move page to the right
cursor_move_left:
 PUSH AF
 PUSH BC
 PUSH DE
 PUSH HL

 CALL cursor_get_location
 LD A, (display_pointer_hi)
 CP H
 JP NZ, cursor_move_left_good
 LD A, (display_pointer_lo)
 CP L
 JP Z, end_cursor_move_left

cursor_move_left_good:
 DEC HL
 LD A, '\n'
 CP (HL)
 JP NZ, cursor_move_left_set
 
; If pageY+cursorY == 0, do nothing, else
; Must set cursorX to 19 or max of line
; Must decrement cursorY (if 0, then decrement pageY)
; Must set pageX to line length - 19
 LD A, (text_cursor)
 SRL A
 SRL A
 SRL A
 SRL A
 SRL A
 SRL A
 LD B, A
 LD A, (display_page_y)
 ADD B
 CP 0x00
 JP Z, end_cursor_move_left
 LD BC, HL
 LD A, (display_pointer_hi)
 LD D, A
 LD A, (display_pointer_lo)
 LD E, A
 CALL string_prev_line
 LD DE, HL
 LD HL, BC
 SCF
 CCF
 SBC HL, DE
; L contains size of line
; if L is less that 20, cursorX = L
; else cursorX = 19, pageX = L - 20
 LD A, L
 CP 0x20
 JP NC, cursor_move_left_greater_20
 LD A, (text_cursor)
 AND 0b11000000
 OR L
 JP cursor_move_left_dec_y

cursor_move_left_greater_20:
 LD A, (text_cursor)
 AND 0b11000000
 OR 0x14

cursor_move_left_dec_y:
; Decrement cursorY (if 0, then decrement pageY)
 SUB 0b01000000
 LD (text_cursor), A
 JP NC, end_cursor_move_left
; Decrement pageY
 LD HL, display_page_y
 DEC (HL)
 ADD 0b01000000
 LD (text_cursor), A
 JP end_cursor_move_left

cursor_move_left_set:
; decrement the cursor X
; If cursorX is 0, decrement pageX
 LD A, (text_cursor)
 LD B, A
 AND 0b11000000
 LD C, A
 LD A, B
 AND 0b00011111
 LD B, 0x00
 CP B
 JP Z, cursor_move_left_set_underflow
 DEC A
 OR C
 LD (text_cursor), A
 JP end_cursor_move_left

cursor_move_left_set_underflow:
; Must decrement page X
 LD HL, display_page_x
 XOR A
 CP (HL)
 JP Z, end_cursor_move_left
 DEC (HL)
 JP end_cursor_move_left

end_cursor_move_left:
 POP HL
 POP DE
 POP BC
 POP AF
 RET

; TODO: Rewrite this
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
 LD A, (display_page_y)
 INC A
 CP text_page_y_max
 JP Z, cursor_move_down_skip_page_save
 LD (display_page_y), A
cursor_move_down_skip_page_save:
 LD A, 0b11000000
end_cursor_move_down:
 OR B
 LD (text_cursor), A

 POP HL
 POP BC
 POP AF
 RET

; TODO: Rewrite this
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
 LD A, (display_page_y)
 CP 0x00
 JP Z, cursor_move_up_reset_cursor
 DEC A
 LD (display_page_y), A
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
