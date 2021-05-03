stack		EQU	0xffff

number_to_check	EQU	0x8000

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
 
 LD A, pio_input_word
 OUT (pio_a_ctrl), A
 LD A, LO(interrupts_table)
 OUT (pio_a_ctrl), A
 LD A, pio_enable_int
 OUT (pio_a_ctrl), A
 
 LD A, pio_output_word
 OUT (pio_b_ctrl), A
 LD A, pio_disable_int
 OUT (pio_b_ctrl), A

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