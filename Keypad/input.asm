;---------------------------
;
; For Input from Keypad
;
;---------------------------

keypad_buffer		EQU	0xC000

backspace_key_code	EQU 0x00
enter_key_code		EQU 0x08

input_setup:
 EX AF, AF'
 EXX
 
 LD A, pio_bit_ctrl_word
 OUT (pio_a_ctrl), A
 LD A, 0xFF
 OUT (pio_a_ctrl), A
 LD A, LO(interrupts_table)
 OUT (pio_a_ctrl), A
 LD A, pio_mask_enable_int | pio_mask_mask_follows | pio_mask_ctrl_word
 OUT (pio_a_ctrl), A
 LD A, 0x00
 OUT (pio_a_ctrl), A
 
 LD A, pio_bit_ctrl_word
 OUT (pio_b_ctrl), A
 LD A, 0x0F
 OUT (pio_b_ctrl), A
 LD A, LO(interrupts_table)
 OUT (pio_b_ctrl), A
 LD A, pio_mask_enable_int | pio_mask_mask_follows | pio_mask_ctrl_word
 OUT (pio_b_ctrl), A
 LD A, 0xF0
 OUT (pio_b_ctrl), A
 
 LD BC, 0x0000
 LD DE, 0x0000
 LD HL, keypad_buffer
 LD (HL), 0x00
 EXX
 EX AF, AF'
 RET
 
keypad_interrupt:
 EX AF, AF'
 EXX
 IN A, (pio_b_data)
 LD D, A
; B contains previous pressed
; C contains how many presses
 IN A, (pio_a_data)
 CALL print_hex
 CP 0xFF
 JP Z, handle_high_bit
 
 LD D, 0x00
decode_loop_low:
 SLA A
 JP NC, got_decoded_value
 INC D
 JP NZ, decode_loop_low
 
 JP end_of_keyboard_interrupt
 
handle_high_bit:
 LD A, D
 CALL print_hex
 LD D, 0x08
decode_loop_high:
 SRA A
 JP NC, got_decoded_value
 INC D
 JP NZ, decode_loop_high
 
 JP end_of_keyboard_interrupt
 
got_decoded_value:
; D contains decoded value
; HL contains current keyboard location
 LD A, D
 CALL print_hex
; Check for Enter (#)
 CP enter_key_code
 JP NZ, check_backspace_input
; Check if it is a double enter press
/* LD A, 0x00
 CP C
 JP NZ, end_character_input
 ; TODO: ADD Line Break Code
end_character_input:
*/
 LD BC, 0x0000
 INC HL
 LD (HL), 0x00
 
check_backspace_input:
; Check for BackSpace (*)
 CP backspace_key_code
 JP NZ, get_character_input
 LD (HL), 0x00
 LD A, H
 CP HI(keypad_buffer)
 JP NZ, dec_buffer_input
 LD A, L
 CP LO(keypad_buffer)
 JP Z, end_of_keyboard_interrupt
dec_buffer_input:
 DEC HL
 JP end_of_keyboard_interrupt
 
get_character_input:
; Get the character since it was a number that was pressed
; If current number pressed is not the same as previous
; If no previous, skip this part
 LD A, 0x00
 CP B
 LD A, D
 JP Z, increase_input_index
 CP B
 JP Z, increase_input_index
; if not the same, end character, then start next
 LD BC, 0x0000
 INC HL
increase_input_index:
; Add the current character into the HL buffer
; since there are only 12 inputs, it is the higher 4 bits
; the next 3 bits contain the amount of times pressed (0 indexed)
 LD DE, code_to_ascii_table
 SLA A
 SLA A
 SLA A
 OR C
 OR E
 CALL print_hex
 LD E, A
 LD A, (DE)
 LD (HL), A
 INC C
 INC HL
 LD (HL), 0x00
 DEC HL

end_of_keyboard_interrupt:
 EXX
 EX AF, AF'
 EI
 RETI
 
ALIGN 128
code_to_ascii_table:
 DEFB "????????" ;*
 DEFB "PQRS7???" ;7
 DEFB "GHI4????" ;4
 DEFB " 1??????" ;1
 DEFB ".-!0????" ;0
 DEFB "TUV8????" ;8
 DEFB "JKL5????" ;5
 DEFB "ABC2????" ;2
 DEFB "????????" ;#
 DEFB "WXYZ9???" ;9
 DEFB "MNO6????" ;6
 DEFB "DEF3????" ;3