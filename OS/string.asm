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

; Empties a string of a determined size
; HL contains pointer to beginning of string
; BC contains size of string
string_clear:
 PUSH AF
 PUSH BC
 PUSH HL
 XOR A
 CP B
 JP NZ, string_clear_loop
 CP C
 JP Z, end_string_clear
  
string_clear_loop:
 LD (HL), A
 INC HL
 DEC BC
 CP B
 JP NZ, string_clear_loop
 CP C
 JP NZ, string_clear_loop

end_string_clear:
 POP HL
 POP BC
 POP AF
 RET

; Moves forward until it reaches a '\n' character or a null character
; HL contains string
; HL returns newline
string_next_line:
 PUSH AF
 PUSH BC
 PUSH DE

 LD E, '\n'
string_next_line_loop:
; Keep going until end of the line reached or end of string 
 LD A, E
 CP (HL)
 JP Z, end_string_next_line
 XOR A
 CPI
 JP Z, end_string_next_line
 JP string_next_line_loop

end_string_next_line:
 POP DE
 POP BC
 POP AF
 RET

; Moves backwards until it reaches a '\n' character or a null character
; HL contains string
; DE contains beginning of string
; HL returns newline
; Points to beginning of string if none found
string_prev_line:
 PUSH AF
 PUSH BC
 PUSH DE
; Check if already at beg
 LD A, E
 CP L
 JP NZ, string_prev_line_loop
 LD A, D
 CP H
 JP Z, end_string_prev_line
; Dec HL
 DEC HL
; Check if already at beg
string_prev_line_loop:
 LD A, E
 CP L
 JP NZ, string_prev_line_loop_good
 LD A, D
 CP H
 JP Z, end_string_prev_line
string_prev_line_loop_good:
 LD A, '\n'
 CP (HL)
 JP Z, end_string_prev_line
 XOR A
 CPD
 JP NZ, string_prev_line_loop

 LD H, D
 LD L, E
end_string_prev_line:
 POP DE
 POP BC
 POP AF
 RET

; TODO: Implement
; Shifts the string, start from the end of the string