;---------------------------
;
; For Printing to the LCD
;
;---------------------------

lcd_instr	    EQU 0b00000100
lcd_data	    EQU	0b00000101

lcd_set_ac_mask EQU 0x80

lcd_line_length EQU 0x14

; Initialize LCD
; A is lost
lcd_setup:
 LD	 A, 0b00111000	; Set 8-bit mode; 2-line dsplay; 5x8 font
 CALL send_instr_sync
 
 LD  A, 0b00001111	; Turns on display; Cursor on; Blinking on
 CALL send_instr_sync
 
 LD  A, 0b00000110	; Increment Cursor; Don't Shift view
 CALL send_instr_sync
 
 LD A, 0b00000001	; Clear the display
 CALL send_instr_sync
 
 RET
 
; A has instruction to send
send_instr_sync:
; Wait for busy flag to be reset
 CALL wait_for_busy_flag
; Send instruction
 OUT (lcd_instr), A
 RET

; A has data to send
send_char_sync:
; Wait for busy flag to be reset
 CALL wait_for_busy_flag
; Send char
 OUT (lcd_data), A
 RET

; Simply waits for the busy flag to reset
wait_for_busy_flag:
 PUSH AF

wait_for_busy_flag_loop
 IN A, (lcd_instr)
 AND 0b10000000
 JP NZ, wait_for_busy_flag_loop

 POP AF
 RET
 
; Print null terminated string
; HL points to string beginning
; C contains IO destination
print_null:
 PUSH AF
 PUSH BC
 PUSH HL
 
; Check if empty string
 XOR A
 CP (HL)
 JP Z, end_print_null
 
print_null_loop:
 CALL wait_for_busy_flag
 OUTI
 CP (HL)
 JP NZ, print_null_loop
 
end_print_null:
 POP HL
 POP BC
 POP AF
 RET
 
; Print a Byte in Hex
; A contains Value
print_hex:
 PUSH BC
 
 LD B, A
; Get top nibble
 SRL A
 SRL A
 SRL A
 SRL A
 AND 0x0F
 
; Turn to number ASCII
 ADD '0'
; Check if bigger than 9
 CP '9'+1
 JP M, skip_alpha_hi
 ADD 'A'-'9'-1
 
skip_alpha_hi:
; Print value
 CALL send_char_sync
 
 LD A, B
 AND 0x0F
 
; Turn to number ASCII
 ADD '0'
; Check if bigger than 9
 CP '9'+1
 JP M, skip_alpha_low
 ADD 'A'-'9'-1
 
skip_alpha_low:
; Print value
 CALL send_char_sync
 
 LD A, B
 POP BC
 RET
 
; Prints a null terminated string in a 4 line lcd (20x4)
; HL contains buffer
; B contains cursor
; C contains IO destination
print_lcd:
 PUSH AF
 PUSH DE
 PUSH HL
 PUSH BC

; Send LCD to Home
 LD A, 0b00000010
 CALL send_instr_sync
 
; Check if empty string
 XOR A
 CP (HL)
 JP Z, end_print_lcd

 LD D, A

; load 20 in B, for the line
reset_print_lcd_loop:
 LD B, lcd_line_length
print_lcd_loop:
 CALL wait_for_busy_flag
 OUTI
 JP Z, print_lcd_skip_line
 CP (HL)
 JP NZ, print_lcd_loop
 JP end_print_lcd
 
print_lcd_skip_line:
; Make sure it is not end of string
 CP (HL)
 JP Z, end_print_lcd

 INC D
 CALL cursor_set_line
 JP reset_print_lcd_loop

end_print_lcd:
; Get back the cursor value
 POP BC
 CALL cursor_set
 POP HL
 POP DE
 POP AF
 RET

; Uses text_page_x, text_page_y, text_cursor to print a subset of the text_buffer
; C contains IO destination
print_text_page:
 PUSH AF
 PUSH DE
 PUSH HL
 PUSH BC

; Clear LCD and send to Home
 LD A, 0b00000001
 CALL send_instr_sync

; Get page location in relative to buffer in DE
 LD A, (text_page_x)
 LD C, A
 LD A, (text_page_y)
 LD B, text_buffer_line_size
 CALL linear
 LD E, A
; Get page absolute location
 LD HL, text_buffer
 ADD HL, DE

 XOR A
 LD D, A
; If first character is a null char
 CP (HL)
 JP Z, print_text_page_empty_line
 POP BC
 PUSH BC
print_text_page_start_loop:
 LD B, lcd_line_length
print_text_page_loop:
 CALL wait_for_busy_flag
 OUTI
 JP Z, print_text_page_next_line
 CP (HL)
 JP NZ, print_text_page_loop
; If currently pointing to an empty part of the LCD,
; skip to next line taking into account what is left in B
 LD C, B
 LD B, A
 ADD HL, BC

print_text_page_next_line:
; When at the end of a line, jump by exactly 64-20
 LD BC, text_buffer_line_size-lcd_line_length
 ADD HL, BC
 INC D
; If D == 4, then done
 LD A, 0x04
 CP D
 JP Z, end_print_text_page
; Make sure it is not empty line, if so, skip the line
 XOR A
 CP (HL)
 JP NZ, print_text_page_next_line_cursor
; if Empty line, add 20 and then recall next line
print_text_page_empty_line:
 LD BC, 0x14
 ADD HL, BC
 JP print_text_page_next_line

print_text_page_next_line_cursor:
; Must also jump cursor to next line
 CALL cursor_set_line
 XOR A
 POP BC
 PUSH BC
 JP print_text_page_start_loop 

end_print_text_page:
 LD A, (text_cursor)
 LD B, A
 CALL cursor_set
 POP BC
 POP HL
 POP DE
 POP AF
 RET

; Sets the cursor to the next line of a 4x20 LCD
; D contains new line
cursor_set_line:
 PUSH AF
 PUSH BC
; if D is 1 -> Set AC to 0x40
; if D is 2 -> Set AC to 0x14
; if D is 3 -> Set AC to 0x54

 LD A, 0x02
 AND D
 JP Z, cursor_set_line_check_line_2
 LD B, 0x14
cursor_set_line_check_line_2:
 LD A, 0x01
 AND D
 JP Z, cursor_set_line_set_ac
 LD A, 0x40
 ADD B
 LD B, A
 
cursor_set_line_set_ac:
 LD A, B
 OR lcd_set_ac_mask
 CALL send_instr_sync
 POP BC
 POP AF
 RET

; Sets the cursor location based on cursor implementation of 0bLL0CCCCC
; B contains cursor
cursor_set:
 PUSH AF
 PUSH BC
 PUSH DE

 LD E, 0x00
; Seperate cursor line (A) and offset (C)
 LD A, 0b00011111
 AND B
 LD C, A
 LD A, 0b11100000
 AND B

 JP Z, end_cursor_set
 LD D, 0b01000000
 LD E, 0x40
 SUB D
 JP Z, end_cursor_set
 LD E, 0x14
 SUB D
 JP Z, end_cursor_set
 LD E, 0x54

end_cursor_set:
 LD A, E
 ADD C
 OR lcd_set_ac_mask
 CALL send_instr_sync
 POP DE
 POP BC
 POP AF
 RET