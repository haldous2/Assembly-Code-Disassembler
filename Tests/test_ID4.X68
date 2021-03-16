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
		
    LEA     $12,A0
    
    LEA     (A0),A0
    LEA     (A5),A0
    LEA     (A7),A0
    LEA     (A0),A7
    LEA     (A5),A7
    LEA     (A7),A7
    LEA     $12,A0
    LEA     $1234,A0
    LEA     $12345678,A0
    
    NOP
    
    NOT.B     D0
    NOT.W     (A1)
    NOT.W     -(A1)
    NOT.W     (A1)+
    NOT.W     $1234
    NOT.L     $12345678
    
    NOP
    
    MOVEM.W   D1-D7,-(A0)
    MOVEM.W   D1-D7,(A0)    
    MOVEM.W   A1-A7,(A0)
    MOVEM.W   A1-A7,-(A0)
    
    MOVEM.W   D0-D7,(A0)
    MOVEM.W   A0-A7,(A0)
    MOVEM.W   D0/D7,(A0)
    MOVEM.W   A0/A7,(A0)
    MOVEM.L   D0-D7,$3000
    MOVEM.L   D0-D7,$00003000
    MOVEM.L   A0-A7,$A0003000

    MOVEM.W   (A0),D0-D7
    MOVEM.W   (A0),A0-A7
    MOVEM.W   (A0),D0/D7
    MOVEM.W   (A0),A0/A7
    MOVEM.L   $3000,D0-D7
    MOVEM.L   $00003000,D0-D7
    MOVEM.L   $A0003000,D0-D7
    
    MOVEM.W   A1-A7,-(A1)
    MOVEM.L   D1-D7,-(A1)
    MOVEM.W   A1/D7,-(A1)
    MOVEM.L   A1/D7,-(A1)
    MOVEM.W   A1-A7,(A1)
    MOVEM.L   D1-D7,(A1)
    MOVEM.W   A1/D7,(A1)
    MOVEM.L   A1/D7,(A1)
    MOVEM.W   (A1)+,A1-A7
    MOVEM.L   (A1)+,D1-D7
    MOVEM.W   (A1)+,A1/D7
    MOVEM.L   (A1)+,A1/D7
    MOVEM.W   (A1),A1-A7
    MOVEM.L   (A1),D1-D7
    MOVEM.W   (A1),A1/D7
    MOVEM.L   (A1),A1/D7

    MOVEM.W   A1-A7,$12
    MOVEM.L   D1-D7,$12
    MOVEM.W   A1/D7,$12
    MOVEM.L   A1/D7,$12
    MOVEM.W   A1-A7,$1234
    MOVEM.L   D1-D7,$1234
    MOVEM.W   A1/D7,$1234
    MOVEM.L   A1/D7,$1234
    MOVEM.W   A1-A7,$12345678
    MOVEM.L   D1-D7,$12345678
    MOVEM.W   A1/D7,$12345678
    MOVEM.L   A1/D7,$12345678
    MOVEM.W   $12,A1-A7
    MOVEM.L   $12,D1-D7
    MOVEM.W   $12,A1/D7
    MOVEM.L   $12,A1/D7
    MOVEM.W   $1234,A1-A7
    MOVEM.L   $1234,D1-D7
    MOVEM.W   $1234,A1/D7
    MOVEM.L   $1234,A1/D7
    MOVEM.W   $12345678,A1-A7
    MOVEM.L   $12345678,D1-D7
    MOVEM.W   $12345678,A1/D7
    MOVEM.L   $12345678,A1/D7

    NOP

    RTS

    NOP

    JSR       label
    JSR       $1234
    JSR       $12345678

label

    SIMHALT

* Put variables and constants here

    END    START




*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~8~
