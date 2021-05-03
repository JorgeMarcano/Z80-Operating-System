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
 