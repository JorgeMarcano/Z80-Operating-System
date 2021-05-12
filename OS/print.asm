;---------------------------
;
; For Printing to the LCD
;
;---------------------------

lcd_instr	        EQU 0b00000100
lcd_data	        EQU	0b00000101

lcd_set_ac_mask     EQU 0x80

lcd_line_length     EQU 0x14

display_must_refresh    EQU 0xBFFF
display_pointer_hi      EQU 0xBFFD
display_pointer_lo      EQU 0xBFFE

display_page_y          EQU 0xBFFC  ; Gives line offset
display_page_x          EQU 0xBFFB  ; Gives offset from beginning of the line
text_cursor             EQU 0xBFFA  ; Cursor follows the pattern 0bLL0CCCCC where L is line nb, and C char nb

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
; No regard to 4 line display
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

; Uses display_pages, text_cursor to print a subset of the buffer pointed by display_pointer
; C contains IO destination
print_text_page:
 PUSH AF
 PUSH DE
 PUSH HL
 PUSH BC

; Clear LCD and send to Home
 LD A, 0b00000001
 CALL send_instr_sync

; Get page location in HL
 CALL page_get_location
 
; FIXME: Fix print logic for new string method
 XOR A
 LD D, A
 LD E, '\n'
; If first character is a null char
 CP (HL)
 JP Z, end_print_text_page
; Get back the C destination
 POP BC
 PUSH BC
print_text_page_start_loop:
; Reset line counter to 20
 LD B, lcd_line_length
print_text_page_loop:
 XOR A
 CALL wait_for_busy_flag
 OUTI
; Check if reached end of the line
 JP Z, print_text_page_jump_next_line
 CP (HL)
; Check if reached null terminator
 JP Z, end_print_text_page
 LD A, E
 CP (HL)
; Check if reached '\n'
 JP NZ, print_text_page_loop
 JP print_text_page_next_line

print_text_page_jump_next_line:
 CALL string_next_line
 XOR A
 CP (HL)
 JP Z, end_print_text_page

print_text_page_next_line:
; When at the end of a line, increase current line counter
 INC D
; If D == 4, then done
 LD A, 0x04
 CP D
 JP Z, end_print_text_page
; Increase HL by one (skip /n)
 INC HL
; Make sure it is not empty line, if so, skip the line
 XOR A
 CP (HL)
 JP NZ, end_print_text_page
 
; Must also jump cursor to next line
 CALL cursor_set_line
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

; Uses page_y and page_x to and the buffer pointed in display_pointer to find the proper location
; Points to the end of the buffer if incorrect
; Returns the RAM location in HL
page_get_location:
 PUSH AF
 PUSH BC
 PUSH DE
 
 LD D, '\n'
 LD A, (display_page_y)
 LD E, A
 LD A, (display_pointer_lo)
 LD L, A
 LD A, (display_pointer_hi)

page_get_location_loop:
 LD A, D
 CP (HL)
 JP Z, page_get_location_decrease
 XOR A
 CPI
 JP NZ, page_get_location_loop
 JP end_page_get_location

page_get_location_decrease:
 DEC E
 JP NZ, page_get_location_loop

; If we have reached the correct line
 LD A, (display_page_x)
 LD C, A
 LD B, E
 ADD HL, BC

end_page_get_location:
 POP DE
 POP BC
 POP AF
 RET

; Gets the buffer location currently pointed to by the cursor
; Stores the location in HL
cursor_get_location:
 CALL page_get_location
 PUSH AF
 PUSH BC

; Make sure page was valid
 XOR A
 CP (HL)
 JP Z, end_cursor_get_location
; Get cursor values
 LD A, (text_cursor)
 LD C, A
 AND 0b00011111
 LD B, A
 LD A, C
 AND 0b11000000
 
cursor_get_location_loop:
 LD C, 0x00
 CP C
 JP Z, cursor_get_location_offset
 CALL string_next_line
 LD C, A
 XOR A
 CP (HL)
 JP Z, end_cursor_get_location
 INC HL
 LD A, C
 SUB 0b01000000
 JP cursor_get_location_loop

cursor_get_location_offset:
; FIXME: Add offset caused by pageX and cursorX
 LD C, B
 LD B, A
 ADD HL, BC
 LD A, (display_page_x)
 LD C, A
 ADD HL, BC

end_cursor_get_location:
 POP BC
 POP AF
 RET

 PUSH AF
 PUSH BC
 PUSH HL
 LD A, (text_cursor)
 LD D, A
; Get character position offset, stored in E
 AND 0b00011111
 LD E, A
 LD A, (display_page_x)
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
 LD HL, display_page_y
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