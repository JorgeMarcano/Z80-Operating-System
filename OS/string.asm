/*
; Copies a null terminated string,
; but if source string is empty, does nothing
; HL contains beginning of source string
; DE contains beginning of dest string
string_copy_nonempty_null:
 PUSH AF
 PUSH HL
 XOR A
 CP (HL)
 JP Z, end_string_copy_nonempty_null_empty
 PUSH BC
 PUSH DE
string_copy_nonempty_null_loop:
 CP (HL)
 JP Z, string_copy_nonempty_null_loop_end
 LDI
 JP string_copy_nonempty_null_loop
string_copy_nonempty_null_loop_end:
 LD HL, DE
 LD (HL), A
end_string_copy_nonempty_null:
 POP DE
 POP BC
end_string_copy_nonempty_null_empty:
 POP HL
 POP AF
 RET
*/

; Copies a null terminated string
; HL contains beginning of source string
; DE contains beginning of dest string
string_copy_null:
 PUSH AF
 PUSH HL
 XOR A
 CP (HL)
 JP NZ, string_copy_null_not_empty
 LD HL, DE
 LD (HL), A
 JP end_string_copy_null_empty
string_copy_null_not_empty:
 PUSH BC
 PUSH DE
string_copy_null_loop:
 CP (HL)
 JP Z, string_copy_null_loop_end
 LDI
 JP string_copy_null_loop
string_copy_null_loop_end:
 LD HL, DE
 LD (HL), A
end_string_copy_null:
 POP DE
 POP BC
end_string_copy_null_empty:
 POP HL
 POP AF
 RET