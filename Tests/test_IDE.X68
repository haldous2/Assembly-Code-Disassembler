*****************************
*
* test_ALL.X68
*
* Created Feb 21, 2021
*
* Test program for CSS 422 Disassembler Project Demo
*
*****************************

start		EQU	$00009000

		ORG	start

    ROL.B     #$1,D2
    ROL.W     #$2,D2
    ROL.L     #$3,D2
    ROL.W     $12               * memory shift
    ROL.W     $123
    ROL.W     $1234
    ROL.W     $12345678
    
    ROR.B     #$1,D2
    ROR.W     #$2,D2
    ROR.L     #$3,D2
    ROR.W     $12
    ROR.W     $1234
    ROR.W     $12345678
    
    LSL.B     #$1,D2
    LSL.W     #$2,D2
    LSL.L     #$3,D2
    LSL.W     $12
    LSL.W     $1234
    LSL.W     $12345678
    
    ASR.B     #$1,D2
    ASR.W     #$2,D2
    ASR.L     #$3,D2
    ASR.W     $12
    ASR.W     $1234
    ASR.W     $12345678

* Put program code here

    SIMHALT

* Put variables and constants here

    END    START

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~8~
