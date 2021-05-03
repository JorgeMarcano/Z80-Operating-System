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

pio_interrupt:
 PUSH AF
 EI
 
 IN A, (pio_a_data)
 LD (number_to_check), A
 
; Print UI
 LD A, 0b00000001	; Clear the display
 CALL send_instr_sync
 LD C, lcd_data
 LD HL, check_str
 CALL print_null
 LD A, (number_to_check)
 CALL print_hex
 LD HL, spacing_str
 CALL print_null
 
; Check if it is a prime
; Divide number by to for upper search bound
 LD C, A
 SRL C
; Save lowest value
 LD B, 0x02
; Check two as edge case
 LD A, (number_to_check)
 CALL modulo
 CP 0x00
 JP Z, not_prime
 INC B
 LD A, B
 CP C
 JP C, print_prime_msg
 
check_prime_loop:
 LD A, (number_to_check)
 CALL modulo
 CP 0x00
 JP Z, not_prime
 INC B
 INC B
 LD A, B
 CP C
 JP NC, check_prime_loop
 
print_prime_msg:
 LD C, lcd_data
 LD HL, is_prime_str
 CALL print_null
 JP end_int
 
not_prime:
 LD C, lcd_data
 LD HL, is_not_prime_str
 CALL print_null
 
end_int: 
 POP AF
 RETI
 
check_str:
 DEFB "Checking for: ", 0
spacing_str:
 DEFB "                        ", 0
is_prime_str:
 DEFB "It's prime!", 0
is_not_prime_str:
 DEFB "It's not prime!", 0