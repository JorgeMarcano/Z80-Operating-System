stack		EQU	0xffff

INCLUDE "resets.asm"

main:
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
 XOR A
;  LD HL, keyboard_buffer
 LD HL, keyboard_buffer
 LD (HL), A

mainloop:
; Print the keyboard buffer when the keyboard must update
 LD A, (keyboard_must_refresh)
 DEC A
 JP NZ, mainloop

; Set A to clear display (0x01)
 INC A
 CALL send_instr_sync
 XOR A
 LD (keyboard_must_refresh), A
 LD A, (keyboard_cursor)
 LD B, A
 CALL print_lcd

 JP mainloop
 
 HALT ; Error Catching Halt
 
INCLUDE "print.asm"
INCLUDE "pio.asm"
INCLUDE "math.asm"
INCLUDE "input.asm"
INCLUDE "string.asm"
INCLUDE "interrupts.asm"
INCLUDE "scancodes.asm"
 

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