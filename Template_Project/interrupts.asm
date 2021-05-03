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