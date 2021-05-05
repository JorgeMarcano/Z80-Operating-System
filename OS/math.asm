;---------------------------
;
; Basic Math Library
;
;---------------------------

; Performs A = A % B
; Result is saved in A
modulo:
 SUB B
; If value went from positive to negative, borrow occured
 JP NC, modulo
; Undo last operation
 ADD B
 RET
 
; Performs A = A / B,
; and C = A % B
div_mod:
 LD C, 0x00
div_mod_loop:
 SUB B
 INC C
 JP NC, div_mod_loop
 ADD B
 DEC C
 RET
 
; Performs DA = A * B
mult:
 PUSH BC
 LD C, A
 XOR A
 LD D, A
 CP B
 JP Z, end_mult
 CP C
 JP Z, end_mult
mult_loop:
 ADD C
 JP NC, mult_skip_overflow
 INC D
mult_skip_overflow:
 DEC B
 JP NZ, mult_loop
end_mult:
 POP BC
 RET

; Performs DA = A * B + C
linear:
 PUSH BC
 LD D, C
 LD C, A
 XOR A
 CP B
 JP Z, end_linear_zero
 CP C
 JP Z, end_linear_zero
 LD A, D
 LD D, 0x00
linear_loop:
 ADD C
 JP NC, linear_skip_overflow
 INC D
linear_skip_overflow:
 DEC B
 JP NZ, linear_loop
 JP end_linear
end_linear_zero:
 LD A, D
 LD D, 0x00
end_linear:
 POP BC
 RET