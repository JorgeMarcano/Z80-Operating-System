;-------------------
;
; Example of printing a specific size of string
;
;-------------------

; HL points to string beginning
; B contains string size
; C contains IO destination
; HL is lost
 LD HL, hello_string
 LD B, 49
 LD C, lcd_data
 OTIR