stack		EQU	0xffff

ORG 0x0000

; Initialize Stack Pointer
 LD SP, stack

 CALL lcd_setup
 LD B, 0
 LD C, 0
 
mainloop:
 ; LD HL, hello_string
 ; LD C, lcd_data
 ; CALL print_null
 
 LD A, B
 CALL print_hex
 
 LD A, C
 CALL print_hex
 INC BC
 
 ; Set LCD to Home
 LD A, 0b00000010
 CALL send_instr_sync
 
 JP mainloop

; A contains how many loops
; delay:
 ; DEC A
 ; JP NZ, delay
 ; RET

INCLUDE "print.asm"
 
; hello_string:
; DEFB "Hello World!"
; DEFS 28, ' '
; DEFB "This is line 2!", 0x00
 
ALIGN 64

LIMIT 0x7fff