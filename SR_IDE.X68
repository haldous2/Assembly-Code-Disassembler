
** ********************************************************************************
** Subroutine: IDE (14)
**             Covers ID's 1,2,3. ASL, ASR, LSL, LSR, ROL, ROR
**
** Input Parameters
**  opWord      OpCode (4 bits) set in main
**
** Subroutine registers
**  D3          Subroutine shifting
**  D4          Subroutine shifting
**  A3          Temp storage space for text
**
** Output Parameters
**  opErr       error flag set to 0 if instruction is valid
**              note: opErr set to 1 (error) in main to display as DATA
**                    if instruction is valid, resetting it allow display
**                    of valid instruction information
**
**  opPtrNam - instruction name pointer to string name for display
**
**  opValSiz - size of instruction: $ff default = not set, 0=Byte, 1=Word, 2=Long
**
**  opSrcMod - source mode (if it has one)
**  opSrcReg - source register (if it has one)
**  opDstMod - destination mode (if it has one)
**  opDstReg - destination register (if it has one)
**
**  opDta1   - source; extra data after instruction
**  opDta1T  - source; extra data type: $FF=not set, 0=Byte, 1=Word, 2=Long
**  opDta2   - destination; extra data after instruction
**  opDta2T  - destination; extra data type: $FF=not set, 0=Byte, 1=Word, 2=Long
**
**  opMask   - MOVEM: mask
**  opRotate - IDE:   Rotation
**  opSizdir - IDE:   Direction and size
**  opIR     - IDE:   Immediate/Rotate
**
** ********************************************************************************

SR_IDE
                    *MOVEM.L    D0-D7/A0-A6,-(SP)       * Save registers

** ********************************************************************************
** edit below
** ********************************************************************************

                    ** ***************************************
                    ** Already know first 4 bits
                    **
                    ** Note: most instructions will be in this format 3,3,3,3 (bits)
                    **
                    ** ***************************************
                    MOVE.W  opWord, D3                  * store opWord in D3 so it doesn't get modified
                    MOVE.B  #12,D4
                    LSR.W   D4,D3                       * Shift right 12 to get first 4 bits
                    MOVE.B  D3, opID

                    ** Read next 3 bits
                    **
                    MOVE.W  opWord, D3                  * store opWord in D3 so it doesn't get modified
                    MOVE.B  #4, D4
                    LSL.W   D4, D3                      * Shift left 4 to get rid of first 4 bits
                    MOVE.B  #13,D4
                    LSR.W   D4,D3                       * Shift right 13 to get next 3 bits
                    MOVE.B  D3, opRotate

                    ** Read next 3 bits
                    **
                    MOVE.W  opWord, D3                  * store opWord in D3 so it doesn't get modified
                    MOVE.B  #7, D4
                    LSL.W   D4, D3                      * Shift left 7 to get rid of first 7 bits
                    MOVE.B  #13,D4
                    LSR.W   D4,D3                       * Shift right 13 to get next 3 bits
                    MOVE.B  D3, opSizDir

                    ** Read next 3 bits
                    **
                    MOVE.W  opWord, D3                  * store opWord in D3 so it doesn't get modified
                    MOVE.B  #10, D4
                    LSL.W   D4, D3                      * Shift left 10 to get rid of first 10 bits
                    MOVE.B  #13,D4
                    LSR.W   D4,D3                       * Shift right 13 to get next 3 bits
                    MOVE.B  D3, opIR

                    ** Read next 3 bits
                    **
                    MOVE.W  opWord, D3                  * store opWord in D3 so it doesn't get modified
                    MOVE.B  #13, D4
                    LSL.W   D4, D3                      * Shift left 10 to get rid of first 10 bits
                    MOVE.B  #13,D4
                    LSR.W   D4,D3                       * Shift right 13 to get next 3 bits
                    MOVE.B  D3, opDstReg

                    ** ***************************************
                    ** Verify this is ASd, LSd, ROd
                    **
                    ** opID     = ID (Should already be @ E(14) if we made it this far)
                    ** opRotate = Rotation
                    ** opSizDir = Size/Direction
                    ** opIR     = Immediate/Rotate
                    ** opDstReg = Destination Register
                    **
                    ** ASd: Size = 0,1,2,4,5,6 & Mode = 0,4 -> ASd Register to Dy
                    ** ASd: Size = 3,7 & Rotation = 0       -> ASd Register to -(An)+
                    ** LSd: Size = 0,1,2,4,5,6 & Mode = 1,5 -> LSd Register to Dy
                    ** LSd: Size = 3,7 & Rotation = 1       -> LSd Register to -(An)+
                    ** ROd: Size = 0,1,2,4,5,6 & Mode = 3,7 -> ROd Register to Dy
                    ** ROd: Size = 3,7 & Rotation = 3       -> ROd Register to -(An)+
                    **
                    ** ***************************************

                    ** Is size 3 or 7?
                    CMP.B   #3,opSizDir
                    BEQ     Fn_IDE_Mem                  * If 3 then using memory mode to An
                    CMP.B   #7,opSizDir
                    BEQ     Fn_IDE_Mem                  * If 7 then using memory mode to An
                    BRA     Fn_IDE_Reg                  * Not 3 or 7, using register mode to Dy

Fn_IDE_Mem          ** ***************************************
                    ** Shift memory (An)
                    ** Rotation 0,1 or 3
                    ** ***************************************

                    CMP.B   #0,opRotate                 * Rotation is 0
                    BEQ     Fn_IDE_MemASd               * Found a match for ASd
                    CMP.B   #1,opRotate                 * Rotation is 1
                    BEQ     Fn_IDE_MemLSd               * Found a match for LSd
                    CMP.B   #3,opRotate                 * Rotation is 3
                    BEQ     Fn_IDE_MemROd               * Found a match for ROd
                    BRA     Fn_IDE_Error                * No matching rotation - error out

Fn_IDE_MemASd       ** Memory shift ASd - set name
                    CMP.B   #3,opSizDir                 * Direction is Right
                    BEQ     Fn_IDE_MemASR               * Size is 3 - direction is right
                    BRA     Fn_IDE_MemASL               * Size must be 7 - direction is left

Fn_IDE_MemASR       LEA     opNam_ASR,A3
                    MOVE.L  A3,opPtrNam                 * Display name points to name
                    BRA     Fn_IDE_MemChk
Fn_IDE_MemASL       LEA     opNam_ASL,A3
                    MOVE.L  A3,opPtrNam                 * Display name points to name
                    BRA     Fn_IDE_MemChk

Fn_IDE_MemLSd       ** Memory shift LSd - set name
                    CMP.B   #3,opSizDir                 * Direction is Right
                    BEQ     Fn_IDE_MemLSR               * Size is 3 - direction is right
                    BRA     Fn_IDE_MemLSL               * Size must be 7 - direction is left

Fn_IDE_MemLSR       LEA     opNam_LSR,A3
                    MOVE.L  A3,opPtrNam                 * Display name points to name
                    BRA     Fn_IDE_MemChk
Fn_IDE_MemLSL       LEA     opNam_LSL,A3
                    MOVE.L  A3,opPtrNam                 * Display name points to name
                    BRA     Fn_IDE_MemChk

Fn_IDE_MemROd       ** Memory shift ROd - set name
                    CMP.B   #3,opSizDir                 * Direction is Right
                    BEQ     Fn_IDE_MemROR               * Size is 3 - direction is right
                    BRA     Fn_IDE_MemROL               * Size must be 7 - direction is left

Fn_IDE_MemROR       LEA     opNam_ROR,A3
                    MOVE.L  A3,opPtrNam                 * Display name points to name
                    BRA     Fn_IDE_MemChk
Fn_IDE_MemROL       LEA     opNam_ROL,A3
                    MOVE.L  A3,opPtrNam                 * Display name points to name
                    BRA     Fn_IDE_MemChk

Fn_IDE_MemChk       ** ***************************************
                    ** Verify other instruction parameters are correct
                    **
                    **    opIR   = 2 to 7
                    **    DstReg = 0 to 7
                    **
                    ** ***************************************
                    CMP.B   #2, opIR                    * Destination mode is >= 2
                    BLT     Fn_IDE_Error
                    CMP.B   #7, opIR                    * Destination mode is <= 7
                    BGT     Fn_IDE_Error
                    CMP.B   #0, opDstReg                * Destination register >= 0
                    BLT     Fn_IDE_Error
                    CMP.B   #7, opDstReg                * Destination register <= 7
                    BGT     Fn_IDE_Error

                    ** Destination Mode is opIR for memory shift
                    MOVE.B  opIR,opDstMod

                    ** ***************************************
                    ** Memory shift restricted to size Word
                    ** ***************************************
                    MOVE.B  #1,opValSiz                 * Set size to 1=Word

                    ** ***************************************
                    ** Grab extra DATA if needed
                    **
                    **    If opIR = 7
                    **       opIR = 0 (get Word)
                    **       opIR = 1 (get Long)
                    **
                    ** ***************************************
                    CMP.B   #7, opIR                    * Check if destination mode is 7
                    BEQ     Fn_IDE_ChkDstReg            * Check destination register
                    BRA     Fn_IDE_Done                 * Destination not 7, done with data
Fn_IDE_ChkDstReg    CMP.B   #0, opDstReg                * Check if destination register is 0
                    BEQ     Fn_IDE_DtaDstWrd            * Load next word
                    CMP.B   #1, opDstReg                * Check if destination register is 1
                    BEQ     Fn_IDE_DtaDstLng            * Load next long
                    BRA     fn_IDE_Error                * Invalid registration Mode

Fn_IDE_DtaDstWrd    CLR.L   D3
                    MOVE.W  (A2)+,D3                    * Load word and increment address count
                    MOVE.L  D3,opDta2
                    MOVE.B  #1, opDta2T                 * Set Data2 type as 1=Word
                    BRA     Fn_IDE_Done
Fn_IDE_DtaDstLng    CLR.L   D3
                    MOVE.L  (A2)+,D3                    * Load word and increment address count
                    MOVE.L  D3,opDta2
                    MOVE.B  #2, opDta2T                 * Set Data2 type as 2=Long
                    BRA     Fn_IDE_Done

Fn_IDE_Reg          ** ***************************************
                    ** Shift register Dy
                    **
                    ** opIR 0,4 or 1,5 or 3,7
                    **
                    ** Source mode and register
                    **    if opIR = 0,1,3 - use Dn value
                    **       SrcMod = 1, SrcReg = opRotate
                    **
                    **    if opIR = 4,5,7 - use immediate value
                    **       SrcMod = 7, SrcReg = 4, opDta1 = opRotate
                    **
                    ** Destination mode and register
                    **    DstMod = 1, DstReg = DstReg
                    **
                    ** ***************************************

                    ** Set the name of the instruction
                    CMP.B   #0,opIR
                    BEQ     Fn_IDE_RegASd               * Found a match for ASd
                    CMP.B   #4,opIR
                    BEQ     Fn_IDE_RegASd               * Found a match for ASd
                    CMP.B   #1,opIR
                    BEQ     Fn_IDE_RegLSd               * Found a match for LSd
                    CMP.B   #5,opIR
                    BEQ     Fn_IDE_RegLSd               * Found a match for LSd
                    CMP.B   #3,opIR
                    BEQ     Fn_IDE_RegROd               * Found a match for ROd
                    CMP.B   #7,opIR
                    BEQ     Fn_IDE_RegROd               * Found a match for ROd
                    BRA     Fn_IDE_Error                * No matching rotation - error out

                    ** Register shift ASd - set name, source
                    **
Fn_IDE_RegASd       CMP.B   #0,opSizDir
                    BEQ     Fn_IDE_RegASR               * Size is 1 - direction is right
                    CMP.B   #1,opSizDir
                    BEQ     Fn_IDE_RegASR               * Size is 2 - direction is right
                    CMP.B   #2,opSizDir
                    BEQ     Fn_IDE_RegASR               * Size is 3 - direction is right
                    BRA     Fn_IDE_RegASL               * Size must be 4,5,6 - direction is left
Fn_IDE_RegASR       LEA     opNam_ASR,A3
                    MOVE.L  A3,opPtrNam                 * Display name points to name
                    BRA     Fn_IDE_RegChk
Fn_IDE_RegASL       LEA     opNam_ASL,A3
                    MOVE.L  A3,opPtrNam                 * Display name points to name
                    BRA     Fn_IDE_RegChk

                    ** Register shift LSd - set name
                    **
Fn_IDE_RegLSd       CMP.B   #0,opSizDir
                    BEQ     Fn_IDE_RegLSR               * Size is 1 - direction is right
                    CMP.B   #1,opSizDir
                    BEQ     Fn_IDE_RegLSR               * Size is 2 - direction is right
                    CMP.B   #2,opSizDir
                    BEQ     Fn_IDE_RegLSR               * Size is 3 - direction is right
                    BRA     Fn_IDE_RegLSL               * Size must be 4,5,6 - direction is left
Fn_IDE_RegLSR       LEA     opNam_LSR,A3
                    MOVE.L  A3,opPtrNam                 * Display name points to name
                    BRA     Fn_IDE_RegChk
Fn_IDE_RegLSL       LEA     opNam_LSL,A3
                    MOVE.L  A3,opPtrNam                 * Display name points to name
                    BRA     Fn_IDE_RegChk

                    ** Register shift ROd - set name
                    **
Fn_IDE_RegROd       CMP.B   #0,opSizDir
                    BEQ     Fn_IDE_RegROR               * Size is 1 - direction is right
                    CMP.B   #1,opSizDir
                    BEQ     Fn_IDE_RegROR               * Size is 2 - direction is right
                    CMP.B   #2,opSizDir
                    BEQ     Fn_IDE_RegROR               * Size is 3 - direction is right
                    BRA     Fn_IDE_RegROL               * Size must be 4,5,6 - direction is left
Fn_IDE_RegROR       LEA     opNam_ROR,A3
                    MOVE.L  A3,opPtrNam                 * Display name points to name
                    BRA     Fn_IDE_RegChk
Fn_IDE_RegROL       LEA     opNam_ROL,A3
                    MOVE.L  A3,opPtrNam                 * Display name points to name
                    BRA     Fn_IDE_RegChk

Fn_IDE_RegChk       ** ***************************************
                    ** Verify other instruction parameters are correct
                    **
                    **    SrcReg = 0 to 7 (Destination Register)
                    **
                    ** ***************************************
                    CMP.B   #0, opDstReg                * Destination register >= 0
                    BLT     Fn_IDE_Error
                    CMP.B   #7, opDstReg                * Destination register <= 7
                    BGT     Fn_IDE_Error

                    ** Destination Mode default for register shift
                    MOVE.B  #0,opDstMod

                    ** Source is dynamically assigned
                    CMP.B   #0,opIR
                    BEQ     Fn_IDE_RegImd
                    CMP.B   #1,opIR
                    BEQ     Fn_IDE_RegImd
                    CMP.B   #3,opIR
                    BEQ     Fn_IDE_RegImd
                    BRA     Fn_IDE_Error
                    CMP.B   #4,opIR
                    BEQ     Fn_IDE_RegDn
                    CMP.B   #5,opIR
                    BEQ     Fn_IDE_RegDn
                    CMP.B   #7,opIR
                    BEQ     Fn_IDE_RegDn

Fn_IDE_RegDn        ** Dn Register value as source
                    MOVE.B  #1,opSrcMod                 * Source is Dn
                    MOVE.B  opRotate,opSrcReg           * Dn register #
                    BRA     Fn_IDE_RegSiz

Fn_IDE_RegImd       ** Immediate value as source
                    MOVE.B  #7,opSrcMod                 * Source is immediate data
                    MOVE.B  #4,opSrcReg                 * immediate data
                    CLR.L   D3
                    MOVE.B  opRotate,D3
                    MOVE.L  D3,opDta1                   * e.g. move 1 opDta1 -> 00000001
                    MOVE.B  #3,opDta1T                  * opdta1 type is immediate
                    BRA     Fn_IDE_RegSiz

Fn_IDE_RegSiz          ** ***************************************
                    ** Register shift (size)
                    ** 0,4 = Byte
                    ** 1,5 = Word
                    ** 2,6 = Long
                    ** ***************************************
                    CMP.B   #0,opSizDir
                    BEQ     Fn_IDE_RegSizB
                    CMP.B   #4,opSizDir
                    BEQ     Fn_IDE_RegSizB
                    CMP.B   #1,opSizDir
                    BEQ     Fn_IDE_RegSizW
                    CMP.B   #5,opSizDir
                    BEQ     Fn_IDE_RegSizW
                    CMP.B   #2,opSizDir
                    BEQ     Fn_IDE_RegSizL
                    CMP.B   #6,opSizDir
                    BEQ     Fn_IDE_RegSizL
                    BRA     Fn_IDE_Error
Fn_IDE_RegSizB      MOVE.B  #0,opValSiz                 * Set size to 0=Byte
                    BRA     Fn_IDE_Done
Fn_IDE_RegSizW      MOVE.B  #1,opValSiz                 * Set size to 1=Word
                    BRA     Fn_IDE_Done
Fn_IDE_RegSizL      MOVE.B  #2,opValSiz                 * Set size to 2=Long
                    BRA     Fn_IDE_Done

** -----------------------------------------------------------------------------------------------
** End of program
** -----------------------------------------------------------------------------------------------
Fn_IDE_Error        *MOVEM.L (SP)+,D0-D7/A0-A6          * Restore registers
                    MOVE.B  #2, opErr                   * Error 0 = A-OK; 1 = DATA; 2 = Invalid EA
                    RTS

Fn_IDE_Done         *MOVEM.L (SP)+,D0-D7/A0-A6          * Restore registers
                    MOVE.B  #0, opErr                   * Clear error flag so this will display instruction info
                    RTS

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
