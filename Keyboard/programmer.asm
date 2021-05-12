programmer_int_table    EQU 0x8000
programmer_curr_mode    EQU 0x8100
programmer_curr_step    EQU 0x8101
programmer_addr_hi      EQU 0x8102
programmer_addr_lo      EQU 0x8103
programmer_ram_dest     EQU 0x9000

programmer_copy_len     EQU programmer_copy_end - programmer_copy_start

programmer_copy_start:
ORG programmer_ram_dest, $
; This will be the main program in programming mode
programmer_main:
 JP programmer_main

; This will be the interrupt logic for programming mode
programmer_int:
 EX AF, AF'
 EXX

 IN A, (pio_a_data)
 LD C, A
 CALL print_hex

 LD A, (programmer_curr_mode)
 LD B, 0x00
 CP B
 JP NZ, programmer_int_check_write
 LD A, C
 LD (programmer_curr_mode), A

; FIXME: debugging print statement
; Clear Screen
;  LD A, 0b00000001
;  CALL send_instr_sync
;  LD A, C
;  CALL print_hex

; FIXME: Change to jump to check Reset, since if reset, does not expect another byte
 JP end_programmer_int

programmer_int_check_write:
 INC B
 CP B
 JP NZ, programmer_int_check_read

 ; TODO: implement write logic
; FIXME: For now, simply print that you are in WRITE MODE, then clear mode byte
 LD A, 0b00000001
 CALL send_instr_sync
 LD C, lcd_data
 LD HL, test_string_write
 CALL print_null

 XOR A
 LD (programmer_curr_mode), A

 JP end_programmer_int

programmer_int_check_read:
 INC B
 CP B
 JP NZ, programmer_int_check_reset

 ;TODO: implement read logic
; FIXME: For now, simply print that you are in READ MODE
 LD A, 0b00000001
 CALL send_instr_sync
 LD C, lcd_data
 LD HL, test_string_read
 CALL print_null

 XOR A
 LD (programmer_curr_mode), A
 
 JP end_programmer_int

programmer_int_check_reset:

 ; TODO: implement reset logic
; Must do RETI, thus will push to stack a fake return address
 LD HL, programmer_reset
 PUSH HL

end_programmer_int:

 EXX
 EX AF, AF'
 EI
 RETI

programmer_reset:
; "A" contains reset ctrl byte
; 0b11000XXX, where XXX determines which reset
 SLA A
 SLA A
 SLA A
; B contains 0b00XXX000
 LD B, A
; A contains 0b11000111 (RST 0 opcode)
 LD A, (programmer_reset_code)
 OR B
; A now contains new opcode for any RST from 0 (0b11000111) to 7 (0b11111111)
 LD (programmer_reset_code), A

programmer_reset_code:
 RST 0

test_string_write:
DEFB    "In Write Mode", 0x00
test_string_read:
DEFB    "In Read Mode", 0x00

ORG $
programmer_copy_end:

programmer_init:
 PUSH AF
 
 LD A, pio_input_word
 OUT (pio_a_ctrl), A
 LD A, 0xF7
 OUT (pio_a_ctrl), A
 XOR A
 OUT (pio_a_ctrl), A
 LD A, LO(prog_int_table)
 OUT (pio_a_ctrl), A
;  LD A, pio_enable_int
;  LD A, pio_disable_int
;  OUT (pio_a_ctrl), A

 POP AF
 RET

; This is the first interrupt
; The program must copy the entire contents
; Of the interrupt logic to RAM
; Then it will repoint the pio a interrupt to that destination
programmer_interrupt:
 LD HL, programmer_copy_start
 LD DE, programmer_ram_dest
 LD BC, programmer_copy_len

; Repeatedly output HL to DE,
; Increase both
; And decrease BC until BC == 0
 LDIR

; FIXME: debugging print statement
; Clear Screen
 LD A, 0b00000001
 CALL send_instr_sync
 LD C, lcd_data
 LD HL, programmer_string
 CALL print_null

; Change interrupt destination
; Copy Interrupt Vector
 LD HL, interrupts_table
 LD DE, programmer_int_table
 LD BC, end_of_interrupt_table - interrupts_table
 LDIR

; Change PIO A vector
 LD H, HI(programmer_int_table)
 LD L, LO(prog_int_table)
 LD (HL), LO(programmer_int)
 INC HL
 LD (HL), HI(programmer_int)
; Setup High Address Interupt Vector
 LD A, HI(programmer_int_table)
 LD I, A

 XOR A
 LD (programmer_curr_mode), A
 LD (programmer_curr_step), A
; Reset the Stack pointer to prevent any stack overflow
 LD SP, stack
; Fool the CPU into returning to another location
 LD HL, programmer_ram_dest
 PUSH HL
 LD HL, programmer_int
 PUSH HL
; We don't do RETI since programmer_int will handle the interrupt
 RET

programmer_string:
DEFB    "In Prog Mode", 0x00