; This file is in charge of the interrupt handling for the command prompt

curr_command_running    EQU 0xBFE0  ; uses the following mask 0b000000ic where 'i' means awaiting input and 'c' is awaiting command
curr_command_line       EQU 0xBFE1
command_text_buffer 	EQU	0xC000

curr_command_mask_input EQU 0b00000010
curr_command_mask_comm  EQU 0b00000001

text_buffer_line_size   EQU 64
text_buffer_line_count  EQU 64
text_page_x_max         EQU text_buffer_line_size - lcd_line_length - 1
text_page_y_max         EQU text_buffer_line_count - 4 - 1
text_buffer_size        EQU text_buffer_line_size * text_buffer_line_count

command_init:
 PUSH AF
 PUSH BC
 PUSH HL

 XOR A
 LD (text_cursor), A
 LD (display_page_x), A
 LD (display_page_y), A
 LD (curr_command_line), A
 INC A
 LD (curr_command_running), A
 LD (display_must_refresh), A

; Empty the command_text_buffer
 LD HL, command_text_buffer
 LD BC, text_buffer_size
 CALL string_clear

 LD A, HI(command_text_buffer)
 LD (display_pointer_hi), A
 LD A, LO(command_text_buffer)
 LD (display_pointer_lo), A

 CALL command_create_header

 POP HL
 POP BC
 POP AF
 RET

; TODO: FIXME
command_interrupt:
 EX AF, AF'
 EXX
 
 IN A, (pio_b_data)

;  CALL print_hex

; Check for Extended Prefix
command_int_extended:
 CP keyboard_code_extended
 JP NZ, command_int_release
 JP end_command_int_bypass_release
;  JP command_int_add_char

; Check for Release Prefix
command_int_release:
 CP keyboard_code_release
 JP NZ, command_int_shift
 LD A, (keyboard_status)
 OR keyboard_status_release
 LD (keyboard_status), A
 JP end_command_int_bypass_release
;  JP command_int_add_char

; Check shift (both left and right)
command_int_shift:
 CP keyboard_code_shift_l
 JP Z, command_int_shift_good
 CP keyboard_code_shift_r
 JP NZ, command_int_ctrl
command_int_shift_good:
 LD D, keyboard_status_shift
 CALL keyboard_set_status_cond
 JP end_command_int

; Check ctrl
command_int_ctrl:
 CP keyboard_code_ctrl
 JP NZ, command_int_alt
 LD D, keyboard_status_ctrl
 CALL keyboard_set_status_cond
 JP end_command_int

; Check alt
command_int_alt:
 CP keyboard_code_alt
 JP NZ, command_int_not_ctrl_word
 LD D, keyboard_status_alt
 CALL keyboard_set_status_cond
 JP end_command_int

command_int_not_ctrl_word:
; Skip if it is a release word
 LD C, A
 LD A, (keyboard_status)
 BIT keyboard_status_rel_bit, A
 JP NZ, end_command_int
 LD A, C

; Check for backspace
command_int_backspace:
 CP keyboard_code_backspace
 JP NZ, command_int_delete
; Check to see if it already at the beginning, if so, do nothing
 LD A, (text_cursor)
 LD D, 0x00
 CP D
 JP NZ, command_int_backspace_good
 LD A, (display_page_x)
 CP D
 JP NZ, command_int_backspace_good
 LD A, (display_page_y)
 CP D
 JP Z, end_command_int
command_int_backspace_good:
; TODO: perform backspace
    ; CASES: regular mid-line -> move cursor left and simply shift line over to the left
    ; beginning of line, shift entire buffer after previous line over until you find previous line's '\n'
; If not at beginning, shift everything over
 CALL command_jump_to_curr
 CALL cursor_move_left
 LD A, (text_cursor)
 AND 0b00011111
 CP 0x02
 JP C, end_command_int
 CALL cursor_get_location
 LD HL, command_text_buffer
 ADD HL, DE
 CP (HL)
 JP Z, end_command_int
 LD DE, HL
 INC HL
 CALL string_copy_null
 JP end_command_int

; Check for delete
command_int_delete:
 CP keyboard_code_delete
 JP NZ, command_int_left
; TODO: perform delete
; If line attempting to delete is not current command line, jump to current command line
; If it is, make sure it is not the first 2 characters
; If it is not, shift everything over
 CALL command_jump_to_curr
 LD A, (text_cursor)
 AND 0b00011111
 CP 0x02
 JP C, end_command_int
 CALL cursor_get_location
 LD HL, command_text_buffer
 ADD HL, DE
 CP (HL)
 JP Z, end_command_int
 LD DE, HL
 INC HL
 CALL string_copy_null
 JP end_command_int
 
; Check left arrow
command_int_left:
 CP keyboard_code_left
 JP NZ, command_int_right
 CALL cursor_move_left
 JP end_command_int

; Check right arrow
command_int_right:
 CP keyboard_code_right
 JP NZ, command_int_down
 CALL cursor_move_right
 JP end_command_int

; Check down arrow
command_int_down:
 CP keyboard_code_down
 JP NZ, command_int_up
 CALL cursor_move_down
 JP end_command_int

; Check up arrow
command_int_up:
 CP keyboard_code_up
 JP NZ, command_int_enter
 CALL cursor_move_up
 JP end_command_int

; Check for enter
command_int_enter:
 CP keyboard_code_enter
 JP NZ, command_int_capslock
; TODO: Implement enter, move over to next line and execute command
; For now, only creates new command
 CALL command_jump_to_curr
 CALL cursor_move_down
 CALL command_create_header
 JP end_command_int
 
; Check capslock
command_int_capslock:
 CP keyboard_code_capslock
 JP NZ, command_int_add_char
 LD D, keyboard_status_caps
 LD A, (keyboard_status)
 XOR D
 LD (keyboard_status), A
 JP end_command_int

; Regular Alphanumeric Input
command_int_add_char:
 LD A, (curr_command_running)
 CP 0x00
 JP Z, end_command_int

; Jump to current command, end of line
 LD A, (text_cursor)
 SRL A
 SRL A
 SRL A
 SRL A
 SRL A
 SRL A
 LD HL, display_page_y
 ADD (HL)
 LD HL, curr_command_line
 CP (HL)
 JP Z, command_int_add_char_skip_relocation
 CALL command_jump_to_curr
 CALL command_jump_to_end

command_int_add_char_skip_relocation:
 LD A, (keyboard_status)
 LD D, A
; Check for caps lock
 XOR A
 BIT keyboard_status_cap_bit, D
 JP Z, command_int_char_skip_caps
 INC A
command_int_char_skip_caps:
; Check for shift
 BIT keyboard_status_shi_bit, D
 JP Z, command_int_char_skip_shift
 XOR 0x01
command_int_char_skip_shift:
 ADD code_addr_high
 LD B, A

; Set current buffer position
 CALL cursor_get_location
 LD HL, command_text_buffer
 ADD HL, DE
; Save character
 LD A, (BC)
 LD (HL), A
; Increment cursor to the right
 CALL cursor_move_right
; If cursor X at 0 (just overflowed), increment current command line
 LD A, (text_cursor)
 AND 0b00011111
 JP NZ, end_command_int
 LD HL, curr_command_line
 INC (HL)
 
end_command_int:
 LD A, (keyboard_status)
 AND keyboard_status_release ^ 0xff
 LD (keyboard_status), A
 LD A, 0x01
 LD (display_must_refresh), A
end_command_int_bypass_release:
 EXX
 EX AF, AF'
 EI
 RETI

; Jumps cursor to end of current command line, if one present
command_jump_to_curr:
 PUSH AF
 PUSH BC

; Check to see if awaiting input or command
 LD A, (curr_command_running)
 CP 0x00
 JP Z, end_command_jump_to_curr

; If command less than 3, set pageY to 0 and cursor to current line
 LD A, (curr_command_line)
 SUB 0x04
 JP NC, command_jump_to_curr_more_than_3
 ADD 0x04
 SLA A
 SLA A
 SLA A
 SLA A
 SLA A
 SLA A
 LD B, A
 XOR A
 LD (display_page_y), A
 LD A, (text_cursor)
 AND 0b00011111
 OR B
 LD (text_cursor), A
 JP end_command_jump_to_curr

command_jump_to_curr_more_than_3:
; If command more than 3, set cursor to max line, send pageY to command - 4
; Current line - 4 in A
 LD (display_page_y), A
 LD B, 0b11000000
 LD A, (text_cursor)
 AND 0b00011111
 OR B
 LD (text_cursor), A

end_command_jump_to_curr:
 POP BC
 POP AF
 RET

; Send cursor to the end of the current line
; Will not wrap to next line
command_jump_to_end:
 PUSH AF
 PUSH DE
 PUSH HL

 CALL cursor_get_location
 LD HL, command_text_buffer
 ADD HL, DE

; If currently past or at the end, go left
 XOR A
 CP (HL)
 JP Z, command_jump_to_end_left
; Else, go to the right
command_jump_to_end_right:
; If at end of line, do nothing more
 LD A, (text_cursor)
 AND 0b00011111
 CP text_buffer_line_size - 1
 JP Z, end_command_jump_to_end
; Otherwise, move to right and check if zero, done
 INC HL
 CALL cursor_move_right
 CP (HL)
 JP NZ, command_jump_to_end_right
 JP end_command_jump_to_end

command_jump_to_end_left:
; If at beginning of line, do nothing more
 LD A, (text_cursor)
 AND 0b00011111
 JP Z, end_command_jump_to_end
; Peek at previous char, if not zero, done
 XOR A
 DEC HL
 CP (HL)
 JP NZ, end_command_jump_to_end
; If zero, move to the left and try again
 CALL cursor_move_left
 JP command_jump_to_end_left

end_command_jump_to_end:
 POP HL
 POP DE
 POP AF
 RET

; Creates "> " input
command_create_header:
 PUSH AF
 PUSH DE
 PUSH HL

 LD A, (text_cursor)
 AND 0b11100000
 LD (text_cursor), A
 XOR A
 LD (display_page_x), A
 CALL cursor_get_location
 LD HL, command_text_buffer
 ADD HL, DE
 LD (HL), '>'
 INC HL
 LD (HL), ' '
 LD A, (text_cursor)
 INC A
 INC A
 LD (text_cursor), A
 
 POP HL
 POP DE
 POP AF
 RET