stack		EQU	0xffff

ORG 0x0000
setup:
; Initialize Stack Pointer
 LD SP, stack
 
 CALL lcd_setup
 
; Setup High Address Interupt Vector
 LD A, HI(interrupts_table)
 LD I, A
; Setup interrupt mode
 IM 2
 EI
 CALL pio_setup

;***************************************;
; Insert Here Your Code!				;
;***************************************;
 
 HALT ; Error Catching Halt
 
INCLUDE "interrupts.asm"
INCLUDE "print.asm"
INCLUDE "pio.asm"
INCLUDE "math.asm"
 
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