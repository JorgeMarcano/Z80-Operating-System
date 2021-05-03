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
 
 LD A, 0x00
 
 CALL print_hex
mainloop:
 HALT
 JP mainloop
 
;---------------------------------------;
;										;
; The following code sets up the		;
; interrupt vector table along with		;
; some preprocessing alignement tests	;
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
; End of Interrupt Vector Table			;
;---------------------------------------;

INCLUDE "print.asm"
INCLUDE "pio.asm"
 
ALIGN 64
LIMIT 0x7fff