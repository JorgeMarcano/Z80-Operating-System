;---------------------------
;
; For Printing to the LCD
;
;---------------------------

lcd_instr	EQU 0b00000100
lcd_data	EQU	0b00000101

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
; A is lost
send_instr_sync:
; Send instruction
 OUT (lcd_instr), A
 
; Wait for busy flag to be reset
send_instr_wait_loop:
 IN A, (lcd_instr)
 AND 0b10000000
 JP NZ, send_instr_wait_loop
; Return to main code
 RET
 
; Print null terminated string
; HL points to string beginning
; C contains IO destination
; HL is lost
print_null:
 PUSH BC
 PUSH AF
 
print_null_loop:
 LD A, 0x00
 OUTI
 OR (HL)
 JP NZ, print_null_loop
 
 POP AF
 POP BC
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
 OUT (lcd_data), A
 
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
 OUT (lcd_data), A
 
 LD A, B
 POP BC
 RET