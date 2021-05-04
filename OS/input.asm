;---------------------------
;
; For Input from keyboard
;
;---------------------------

keyboard_cursor         EQU 0xBFFD
keyboard_status         EQU 0xBFFE
keyboard_must_refresh	EQU 0xBFFF
keyboard_buffer			EQU	0xC000

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
 LD (keyboard_must_refresh), A
 LD (keyboard_status), A
 LD (keyboard_cursor), A
 
 LD A, pio_input_word
 OUT (pio_b_ctrl), A
 LD A, LO(interrupts_table)
 OUT (pio_b_ctrl), A
 LD A, pio_enable_int
 OUT (pio_b_ctrl), A
 
 LD B, code_addr_high
 LD HL, keyboard_buffer
 LD (HL), 0x00
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
; Check to see if it already at the beggining
 LD A, (keyboard_cursor)
 LD D, 0x00
 CP D
 JP Z, end_keyboard_int
 
; If not at beginning, shift everything over
 DEC A
 LD (keyboard_cursor), A
 LD E, A
 LD HL, keyboard_buffer
 ADD HL, DE
 CP (HL)
 JP Z, end_keyboard_int
 LD DE, HL
 INC HL
 CALL string_copy_null
 JP end_keyboard_int

; Check for delete
keyboard_int_delete:
 CP keyboard_code_delete
 JP NZ, keyboard_int_left
; Shift everything over
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
 CALL string_copy_null
 JP end_keyboard_int
 
; Check left arrow
keyboard_int_left:
 CP keyboard_code_left
 JP NZ, keyboard_int_right
; Check to see if it already at the beggining
 LD A, (keyboard_cursor)
 CP 0x00
 JP Z, end_keyboard_int
; If not at beginning, move cursor back by one
 DEC A
 LD (keyboard_cursor), A
 JP end_keyboard_int

; Check right arrow
keyboard_int_right:
 CP keyboard_code_right
 JP NZ, keyboard_int_capslock
; Set current string position with cursor
 LD A, (keyboard_cursor)
 LD E, A
 LD D, 0x00
 LD HL, keyboard_buffer
 ADD HL, DE
; Check to see if already at the end of the buffer
 XOR A
 CP (HL)
 JP Z, end_keyboard_int
 ; If not at end, increase cursor by one
 LD A, E
 INC A
 LD (keyboard_cursor), A
 JP end_keyboard_int
 
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

; Set current string position with cursor
 LD A, (keyboard_cursor)
 LD E, A
 INC A
 LD (keyboard_cursor), A
 XOR A
 LD D, A
 LD HL, keyboard_buffer
 ADD HL, DE
 
; Check to see if cursor is at the end of the string,
; if so, re-null terminate the string
 CP (HL)
 JP Z, keyboard_int_char_terminate
 LD A, (BC)
 LD (HL), A
 INC HL
 JP end_keyboard_int
keyboard_int_char_terminate:
 LD A, (BC)
 LD (HL), A
 INC HL
 LD (HL), D
 
end_keyboard_int:
 LD A, (keyboard_status)
 AND keyboard_status_release ^ 0xff
 LD (keyboard_status), A
 LD A, 0x01
 LD (keyboard_must_refresh), A
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