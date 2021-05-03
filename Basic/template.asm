pio_a_data	EQU 0b00001000
pio_b_data	EQU 0b00001001
pio_a_ctrl	EQU 0b00001010
pio_b_ctrl	EQU 0b00001011

stack		EQU	0xffff

ORG 0x0000

; Initialize Stack Pointer
 LD SP, stack
 
 CALL lcd_setup
 
; Setup interrupt mode
 CALL setup_pio
 IM 2
 EI
 
; Setup High Address Interupt Vector
 LD A, HI(interrupts_table)
 LD I, A

;***************************************;
; Insert Here Your Code!				;
;***************************************;
 
 HALT ; Error Catching Halt
 
;---------------------------------------;
;										;
; The following code sets up the		;
; interrupt vector table along with		;
; some preprocessing alignment tests	;
;										;
;---------------------------------------;
ALIGN 2
interrupts_table:
DEFB LO(pio_interrupt)
DEFB HI(pio_interrupt)
end_of_interrupt_table:

PRINT "Interrupt table is located at: ", {hex} interrupts_table

ASSERT interrupts_table MOD 2 == 0, "Error with interrupt table alignment!"
ASSERT HI(interrupts_table) == HI(end_of_interrupt_table), "Error with interrupt table overflow!"
;---------------------------------------;
; End of Interrupt Vector Table	Code	;
;---------------------------------------;

INCLUDE "print.asm"
INCLUDE "pio.asm"
 
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