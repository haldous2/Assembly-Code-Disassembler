*****************************
*
* test_ALL.X68
*
* Created Feb 21, 2021
*
* Test program for CSS 422 Disassembler Project Demo
*
* Address range: 9000 to 9470(ish)
*
*****************************

start		EQU	$00009000

		ORG	start

** TEST: ID1,2,3
** ++++++++++++++++++++++++++++++++++++++++++++++++++

      MOVE.L      $A0006000,$A0006010
      MOVE.B      #255,$A0006000
      MOVE.W      #255,A0                 * should auto switch to MOVEA
      MOVEA.W     #255,A0

      MOVE.B    D0,D1
      MOVE.B    D0,(A0)
      MOVE.B    D0,(A0)+
      MOVE.B    D0,-(A0)
      MOVE.B    (A0),D0
      MOVE.B    (A0),(A1)
      MOVE.B    (A0),(A1)+
      MOVE.B    (A0),-(A1)
      MOVE.B    (A0)+,D0
      MOVE.B    (A0)+,(A1)
      MOVE.B    (A0)+,(A1)+
      MOVE.B    (A0)+,-(A1)
      MOVE.B    -(A0),D0
      MOVE.B    -(A0),(A1)
      MOVE.B    -(A0),(A1)+
      MOVE.B    -(A0),-(A1)
      
      MOVE.W    D0,D1
      MOVE.W    D0,(A0)
      MOVE.W    D0,(A0)+
      MOVE.W    D0,-(A0)
      MOVE.W    A0,D0
      MOVE.W    A0,(A1)
      MOVE.W    A0,(A1)+
      MOVE.W    A0,-(A1)
      MOVE.W    (A0),D0
      MOVE.W    (A0),(A1)
      MOVE.W    (A0),(A1)+
      MOVE.W    (A0),-(A1)
      MOVE.W    (A0)+,D0
      MOVE.W    (A0)+,(A1)
      MOVE.W    (A0)+,(A1)+
      MOVE.W    (A0)+,-(A1)
      MOVE.W    -(A0),D0
      MOVE.W    -(A0),(A1)
      MOVE.W    -(A0),(A1)+
      MOVE.W    -(A0),-(A1)
      
      MOVE.L    D0,D1
      MOVE.L    D0,(A0)
      MOVE.L    D0,(A0)+
      MOVE.L    D0,-(A0)
      MOVE.L    A0,D0
      MOVE.L    A0,(A1)
      MOVE.L    A0,(A1)+
      MOVE.L    A0,-(A1)
      MOVE.L    (A0),D0
      MOVE.L    (A0),(A1)
      MOVE.L    (A0),(A1)+
      MOVE.L    (A0),-(A1)
      MOVE.L    (A0)+,D0
      MOVE.L    (A0)+,(A1)
      MOVE.L    (A0)+,(A1)+
      MOVE.L    (A0)+,-(A1)
      MOVE.L    -(A0),D0
      MOVE.L    -(A0),(A1)
      MOVE.L    -(A0),(A1)+
      MOVE.L    -(A0),-(A1)

      MOVEA.W    D0,A0
      MOVEA.W    A0,A0
      MOVEA.W    (A0),A0
      MOVEA.W    (A0)+,A0
      MOVEA.W    -(A0),A0
      MOVEA.L    D0,A0
      MOVEA.L    A0,A0
      MOVEA.L    (A0),A0
      MOVEA.L    (A0)+,A0
      MOVEA.L    -(A0),A0

** TEST: ID4
** ++++++++++++++++++++++++++++++++++++++++++++++++++

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

** TEST: ID5
** ++++++++++++++++++++++++++++++++++++++++++++++++++
** Instruction decoder not complete

** TEST: ID6
** ++++++++++++++++++++++++++++++++++++++++++++++++++
** Instruction decoder not complete
    
** TEST: ID7
** ++++++++++++++++++++++++++++++++++++++++++++++++++
** Instruction decoder not complete

** TEST: ID8
** ++++++++++++++++++++++++++++++++++++++++++++++++++

      OR.B     D1,D2
      OR.B     D1,(A1)
      OR.B     D1,(A1)+
      OR.B     D1,-(A1)
      OR.B     (A1),D1
      OR.B     (A1)+,D1
      OR.B     -(A1),D1
      OR.W     D1,D2
      OR.W     D1,(A1)
      OR.W     D1,(A1)+
      OR.W     D1,-(A1)
      OR.W     (A1),D1
      OR.W     (A1)+,D1
      OR.W     -(A1),D1
      OR.L     D1,D2
      OR.L     D1,(A1)
      OR.L     D1,(A1)+
      OR.L     D1,-(A1)
      OR.L     (A1),D1
      OR.L     (A1)+,D1
      OR.L     -(A1),D1
      
** TEST: ID9
** ++++++++++++++++++++++++++++++++++++++++++++++++++
** Instruction decoder not complete

** TEST: IDA
** ++++++++++++++++++++++++++++++++++++++++++++++++++
** Opcodes not assigned

** TEST: IDB
** ++++++++++++++++++++++++++++++++++++++++++++++++++
** Opcodes not assigned

** TEST: IDC
** ++++++++++++++++++++++++++++++++++++++++++++++++++
** Instruction decoder not complete

** TEST: IDD
** ++++++++++++++++++++++++++++++++++++++++++++++++++
** Instruction decoder not complete

** TEST: IDE
** ++++++++++++++++++++++++++++++++++++++++++++++++++

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

      LSL.B     D1,D2
      LSL.W     D1,D2
      LSL.W     (A1)
      LSL.W     (A1)+
      LSL.W     -(A1)
      LSL.L     D1,D2
      LSR.B     D1,D2
      LSR.W     D1,D2
      LSR.W     (A1)
      LSR.W     (A1)+
      LSR.W     -(A1)
      LSR.L     D1,D2
      ASR.B     D1,D2
      ASR.W     D1,D2
      ASR.W     (A1)
      ASR.W     (A1)+
      ASR.W     -(A1)
      ASR.L     D1,D2
      ASL.B     D1,D2
      ASL.W     D1,D2
      ASL.W     (A1)
      ASL.W     (A1)+
      ASL.W     -(A1)
      ASL.L     D1,D2

** TEST: NON SUPPORTED INSTRUCTIONS - SHOULD DISPLAY AS DATA
** ++++++++++++++++++++++++++++++++++++++++++++++++++

      NOP                             * to mark where these start
      NOP
      NOP

** ID6

label1
      BGT.B     label4
      BGT.B     label4
      BGT.B     label4
label2
      BLE.W     label1
      BLE.W     label2
      BLE.W     label3
label3
      BEQ.W     label1
      BEQ.W     label2
      BEQ.W     label3
label4
      BEQ.W     label3

      BGT.B     label4
      BGT.B     label4
      BGT.B     label4
      BLE.W     label1
      BLE.W     label2
      BLE.W     label3
      BEQ.W     label1
      BEQ.W     label2
      BEQ.W     label3

** ID7

      MOVEQ     #$0,D0
      MOVEQ     #$12,D0
      MOVEQ     #$FF,D0

** ID9

      SUB.B     D1,D2
      SUB.B     D1,(A1)
      SUB.B     D1,(A1)+
      SUB.B     D1,-(A1)
      SUB.B     (A1),D1
      SUB.B     (A1)+,D1
      SUB.B     -(A1),D1
      SUB.W     D1,D2
      SUB.W     D1,A1
      SUB.W     D1,(A1)
      SUB.W     D1,(A1)+
      SUB.W     D1,-(A1)
      SUB.W     A1,D1
      SUB.W     (A1),D1
      SUB.W     (A1)+,D1
      SUB.W     -(A1),D1
      SUB.L     D1,D2
      SUB.L     D1,A1
      SUB.L     D1,(A1)
      SUB.L     D1,(A1)+
      SUB.L     D1,-(A1)
      SUB.L     A1,D1
      SUB.L     (A1),D1
      SUB.L     (A1)+,D1
      SUB.L     -(A1),D1

** UNSORTED

      AND.B     D1,D2
      AND.B     D1,(A1)
      AND.B     D1,(A1)+
      AND.B     D1,-(A1)
      AND.B     (A1),D1
      AND.B     (A1)+,D1
      AND.B     -(A1),D1
      AND.W     D1,D2
      AND.W     D1,(A1)
      AND.W     D1,(A1)+
      AND.W     D1,-(A1)
      AND.W     (A1),D1
      AND.W     (A1)+,D1
      AND.W     -(A1),D1
      AND.L     D1,D2
      AND.L     D1,(A1)
      AND.L     D1,(A1)+
      AND.L     D1,-(A1)
      AND.L     (A1),D1
      AND.L     (A1)+,D1
      AND.L     -(A1),D1

      AND.B     D1,$12
      AND.B     D1,$1234
      AND.B     D1,$12345678
      AND.B     $12,D1
      AND.B     $1234,D1
      AND.B     $12345678,D1
      AND.B     #$12,D1
      AND.W     D1,$12
      AND.W     D1,$1234
      AND.W     D1,$12345678
      AND.W     $12,D1
      AND.W     $1234,D1
      AND.W     $12345678,D1
      AND.W     #$1234,D1
      AND.L     D1,$12
      AND.L     D1,$1234
      AND.L     D1,$12345678
      AND.L     $12,D1
      AND.L     $1234,D1
      AND.L     $12345678,D1
      AND.L     #$12345678,D1

      ADD.B     D1,D2
      ADD.B     D1,(A1)
      ADD.B     D1,(A1)+
      ADD.B     D1,-(A1)
      ADD.B     (A1),D1
      ADD.B     (A1)+,D1
      ADD.B     -(A1),D1
      ADD.W     D1,D2
      ADD.W     D1,(A1)
      ADD.W     D1,(A1)+
      ADD.W     D1,-(A1)
      ADD.W     (A1),D1
      ADD.W     (A1)+,D1
      ADD.W     -(A1),D1
      ADD.L     D1,D2
      ADD.L     D1,(A1)
      ADD.L     D1,(A1)+
      ADD.L     D1,-(A1)
      ADD.L     (A1),D1
      ADD.L     (A1)+,D1
      ADD.L     -(A1),D1
      
      ADDA.W        D1,A2
      ADDA.W        (A1),A2
      ADDA.W        (A1)+,A2
      ADDA.W        -(A1),A2
      ADDA.L        D1,A2
      ADDA.L        (A1),A2
      ADDA.L        (A1)+,A2
      ADDA.L        -(A1),A2
      
      ADDA.W    $12,A2
      ADDA.W    $1234,A2
      ADDA.W    $12345678,A2
      ADDA.W    #$1234,A2
      ADDA.L    $12,A2
      ADDA.L    $1234,A2
      ADDA.L    $12345678,A2
      ADDA.L    #$12345678,A2
      MULS.W    $12,D1
      MULS.W    $1234,D1
      MULS.W    $12345678,D1
      MULS.W    #$1234,D1
      DIVU.W    $12,D1
      DIVU.W    $1234,D1
      DIVU.W    $12345678,D1
      DIVU.W    #$1234,D1
      
      MULS.W    D0,D1
      MULS.W    (A0),D1
      MULS.W    -(A0),D1
      MULS.W    (A0)+,D1
      DIVU.W    D0,D1
      DIVU.W    (A0),D1
      DIVU.W    -(A0),D1
      DIVU.W    (A0)+,D1

* Put program code here

    SIMHALT

* Put variables and constants here

    END    START

















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~8~
