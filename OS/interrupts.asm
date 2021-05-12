;---------------------------------------;
;										;
; The following code sets up the		;
; interrupt vector table along with		;
; some preprocessing alignment tests	;
;										;
;---------------------------------------;
ALIGN 2
interrupts_table:
DEFB LO(command_interrupt)
DEFB HI(command_interrupt)
end_of_interrupt_table:

PRINT "Interrupt table is located at: ", {hex} interrupts_table

ASSERT interrupts_table MOD 2 == 0, "Error with interrupt table alignment!"
ASSERT (HI(interrupts_table) == HI(end_of_interrupt_table)) || LO(end_of_interrupt_table) == 0x00, "Error with interrupt table overflow!"
;---------------------------------------;
; End of Interrupt Vector Table	Code	;
;---------------------------------------;