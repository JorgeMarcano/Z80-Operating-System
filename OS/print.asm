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
 JP print_lcd_set_cursor
 
print_lcd_skip_line:
; Make sure it is not end of string
 CP (HL)
 JP Z, print_lcd_set_cursor

 INC D
; Move LCD pointer to another line
; if D is 1 -> Set AC to 0x40
; if D is 2 -> Set AC to 0x14
; if D is 3 -> Set AC to 0x54

 LD A, 0x02
 AND D
 JP Z, print_lcd_check_line_2
 LD B, 0x14
print_lcd_check_line_2:
 LD A, 0x01
 AND D
 JP Z, print_lcd_set_ac
 LD A, 0x40
 ADD B
 LD B, A
 
print_lcd_set_ac:
 LD A, B
 OR lcd_set_ac_mask
 CALL send_instr_sync
 XOR A
 JP reset_print_lcd_loop

print_lcd_set_cursor:
; Get back the cursor value
 POP BC
 PUSH BC
 LD E, lcd_line_length
 LD D, (0x00 + lcd_line_length)
 LD A, B
 SUB E
 JP C, print_lcd_set_cursor_perform
 LD D, (0x40 + lcd_line_length)
 SUB E
 JP C, print_lcd_set_cursor_perform
 LD D, (lcd_line_length + lcd_line_length)
 SUB E
 JP C, print_lcd_set_cursor_perform
 LD D, (0x54 + lcd_line_length)

print_lcd_set_cursor_perform:
 ADD D
 OR lcd_set_ac_mask
 CALL send_instr_sync
 
end_print_lcd:
 POP BC
 POP HL
 POP DE
 POP AF
 RET