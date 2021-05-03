;---------------------------
;
; For Communication with the PIO
;
;---------------------------

; PIO mode words
pio_output_word			EQU	0x0F
pio_input_word			EQU	0x4F
pio_bidirectional_word	EQU	0x8F
pio_bit_ctrl_word		EQU	0xCF

; PIO interrupt control words
pio_enable_int			EQU	0x83
pio_disable_int			EQU	0x03

; PIO bit mask control words
pio_mask_enable_int		EQU 0b10000000
pio_mask_and			EQU 0b01000000
pio_mask_active_high	EQU 0b00100000
pio_mask_mask_follows	EQU 0b00010000
pio_mask_ctrl_word		EQU 0b00000111

; PIO I/O Address Ports
pio_a_data	EQU 0b00001000
pio_b_data	EQU 0b00001001
pio_a_ctrl	EQU 0b00001010
pio_b_ctrl	EQU 0b00001011

setup_pio:
; Set port B for output
 LD A, pio_output_word
 OUT (pio_b_ctrl), A
; Disable interrupts for port B
 LD A, pio_disable_int
 OUT (pio_b_ctrl), A
 
; Set A to input mode
 LD A, pio_input_word
 OUT (pio_a_ctrl), A
; Set interrupt vector
 LD A, LO(interrupts_table)
 OUT (pio_a_ctrl), A
; Enable interrupts for port A
 LD A, pio_enable_int
 OUT (pio_a_ctrl), A
 
 RET

; Handle interrupt
pio_interrupt:
 ; Set LCD to Home
 LD A, 0b00000010
 CALL send_instr_sync
 
 ; LD C, lcd_data
 ; LD HL, string
 ; CALL print_null
 
 IN A, (pio_a_data)
 CALL print_hex
 EI
 RETI
