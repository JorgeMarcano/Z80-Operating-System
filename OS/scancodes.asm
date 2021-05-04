ALIGN 256

code_addr_high      EQU HI(code_to_ascii_table)

; These 256 bytes contains the basic unmodified ScanCodes
code_to_ascii_table:
 DEFB "?9?5312C??864\t`?" ;0x
 DEFB "?AS?Cq1???zsaw2?" ;1x
 DEFB "?cxde43?? vftr5?" ;2x
 DEFB "?nbhgy6???mju78?" ;3x
 DEFB "?,kio09????l;p-?" ;4x
 DEFB "??'?[=???S\n]?\\??" ;5x
 DEFB "??????\b?????????" ;6x
 DEFB "??????E?B???????" ;7x
 DEFB "???7????????????" ;8x
 DEFB "????????????????" ;9x
 DEFB "????????????????" ;Ax
 DEFB "????????????????" ;Bx
 DEFB "????????????????" ;Cx
 DEFB "????????????????" ;Dx
 DEFB "X???????????????" ;Ex
 DEFB "R???????????????" ;Fx


 ; These 256 bytes contains the uppercase ScanCodes
 code_to_upper_ascii_tables:
 DEFB "?9?5312C??864\t~?" ;0x
 DEFB "?AS?CQ!???ZSAW@?" ;1x
 DEFB "?CXDE$#?? VFTR%?" ;2x
 DEFB "?NBHGY^???MJU&*?" ;3x
 DEFB "?<KIO)(????L:P_?" ;4x
 DEFB '??"?{+???S\n}?|??' ;5x"
 DEFB "??????\b?????????" ;6x
 DEFB "??????E?B???????" ;7x
 DEFB "???7????????????" ;8x
 DEFB "????????????????" ;9x
 DEFB "????????????????" ;Ax
 DEFB "????????????????" ;Bx
 DEFB "????????????????" ;Cx
 DEFB "????????????????" ;Dx
 DEFB "X???????????????" ;Ex
 DEFB "R???????????????" ;Fx
/*
 ; These 256 bytes contains the extended ScanCodes
 code_to_extended_ascii_tables:
 */