stack		EQU	0xffff

ORG 0x0000
setup:
; Initialize Stack Pointer
 LD SP, stack
 
 CALL lcd_setup
 
; Setup High Address Interupt Vector
 LD A, HI(interrupts_table)
 LD I, A
 
 CALL input_setup
; Setup interrupt mode
 IM 2
 EI

 LD C, lcd_data
 LD HL, keypad_buffer
 LD (HL), 0x00
mainloop:
; Constantly print the keyboard buffer
 ; LD A, 0b00000010
 ; CALL send_instr_sync
 
 LD HL, keypad_buffer
 CALL print_null
 JP mainloop
 
 HALT ; Error Catching Halt
 
INCLUDE "interrupts.asm"
INCLUDE "print.asm"
INCLUDE "pio.asm"
;INCLUDE "math.asm"
INCLUDE "input.asm"
 
;---------------------------------------;
;										;
; The following code aligns the binary	;
; file for easy programming with the	;
; Python EEPROM Uploader				;
;										;
;---------------------------------------;
ALIGN 64
LIMIT 0x7fff
;---------------------------------------;
; End of Alignment Processing			;
;---------------------------------------;