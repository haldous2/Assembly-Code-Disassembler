
** ********************************************************************************
** Subroutine: ID3
**             Covers ID's 1,2,3. MOVE, MOVEA
**
** (This part of the code will need to be duplicated for each opcode)
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
**  opMask   - mask bits for MOVEM
**  perhaps more local vars - trying to keep it compact
**
** ********************************************************************************

SR_ID3

                    *MOVEM.L    D0-D7/A0-A6,-(SP)       * Save registers

** ********************************************************************************
** edit below
** ********************************************************************************

                    ** ***************************************
                    ** Read first 4 bits
                    ** need to know if 0(byte), 1(word), 2(long) - only for MOVE, MOVEA
                    ** Note: most instructions will be in this format 3,3,3,3
                    **    I think there is only one instrction that is 4,8
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
                    MOVE.B  D3, opDstReg

                    ** Read next 3 bits
                    **
                    MOVE.W  opWord, D3                  * store opWord in D3 so it doesn't get modified
                    MOVE.B  #7, D4
                    LSL.W   D4, D3                      * Shift left 7 to get rid of first 7 bits
                    MOVE.B  #13,D4
                    LSR.W   D4,D3                       * Shift right 13 to get next 3 bits
                    MOVE.B  D3, opDstMod

                    ** Read next 3 bits
                    **
                    MOVE.W  opWord, D3                  * store opWord in D3 so it doesn't get modified
                    MOVE.B  #10, D4
                    LSL.W   D4, D3                      * Shift left 10 to get rid of first 10 bits
                    MOVE.B  #13,D4
                    LSR.W   D4,D3                       * Shift right 13 to get next 3 bits
                    MOVE.B  D3, opSrcMod

                    ** Read next 3 bits
                    **
                    MOVE.W  opWord, D3                  * store opWord in D3 so it doesn't get modified
                    MOVE.B  #13, D4
                    LSL.W   D4, D3                      * Shift left 10 to get rid of first 10 bits
                    MOVE.B  #13,D4
                    LSR.W   D4,D3                       * Shift right 13 to get next 3 bits
                    MOVE.B  D3, opSrcReg

                    ** ***************************************
                    ** Verify this is MOVE or MOVEA
                    **
                    ** MOVE:  If opID = 1,2,3 & DstMod = 0,2-7
                    ** MOVEA: If opID =   2,3 & DstMod = 1
                    **
                    ** Size: opID = 1: Byte; opID = 2: Long; opID = 3: Word
                    **
                    ** ***************************************
                    CMP.B   #1, opDstMod                * Destination mode is 1 - must be MOVEA
                    BEQ     Fn_ID3_Ins02                * Set as instruction 0 MOVEA
                    BRA     Fn_ID3_Ins01                * Set as instruction 1 MOVE

Fn_ID3_Ins01        LEA     opNam_MOVE,A3
                    MOVE.L  A3,opPtrNam                 * Display name points to name
                    BRA     Fn_ID3_Verify

Fn_ID3_Ins02        CMP.B   #1, opID
                    BEQ     Fn_ID3_Error               * MOVEA cannot have opID = 1 (byte)
                    LEA     opNam_MOVEA,A3
                    MOVE.L  A3,opPtrNam                 * Display name points to name

                    ** ***************************************
                    ** Verify other instruction parameters are correct
                    **
                    **    DstMod = 0 to 7
                    **    DstReg = 0 to 7
                    **    SrcMod = 0 to 7
                    **    SrcReg = 0 to 7
                    **
                    ** ***************************************
Fn_ID3_Verify       CMP.B   #0, opDstMod                * Destination mode is >= 0
                    BLT     Fn_ID3_Error
                    CMP.B   #7, opDstMod                * Destination mode is <= 7
                    BGT     Fn_ID3_Error
                    CMP.B   #0, opDstReg                * Destination register >= 0
                    BLT     Fn_ID3_Error
                    CMP.B   #7, opDstReg                * Destination register <= 7
                    BGT     Fn_ID3_Error

                    CMP.B   #0, opSrcMod                * Destination mode is 0
                    BLT     Fn_ID3_Error
                    CMP.B   #7, opSrcMod                * Destination mode is <= 7
                    BGT     Fn_ID3_Error
                    CMP.B   #0, opSrcReg                * Destination register >= 0
                    BLT     Fn_ID3_Error
                    CMP.B   #7, opSrcReg                * Destination register <= 7
                    BGT     Fn_ID3_Error

                    ** ***************************************
                    ** Set instruction size - the .B,.W,.L part
                    ** Note: size set by opID only for MOVE, MOVEA
                    **       other instructions use 3 bits for size
                    ** ***************************************
                    CMP.B   #1, opID                    * Instruction size is Byte
                    BEQ     Fn_ID3_SizB
                    CMP.B   #3, opID                    * Instruction size is Word (Note sizes reversed for MOVE)
                    BEQ     Fn_ID3_SizW
                    CMP.B   #2, opID                    * Instruction size is Long
                    BEQ     Fn_ID3_SizL
Fn_ID3_SizB         MOVE.B  #0,opValSiz                 * Set size to 0=Byte
                    BRA     Fn_ID3_SrcMod
Fn_ID3_SizW         MOVE.B  #1,opValSiz                 * Set size to 1=Word
                    BRA     Fn_ID3_SrcMod
Fn_ID3_SizL         MOVE.B  #2,opValSiz                 * Set size to 2=Long
                    BRA     Fn_ID3_SrcMod

                    ** ***************************************
                    ** Grab extra DATA if needed
                    **
                    **    If DstMod = 7
                    **       DstReg = 0 (get Word)
                    **       DstReg = 1 (get Long)
                    **
                    **    If SrcMod = 7
                    **       SrcReg = 0 (get Word)
                    **       SrcReg = 1 (get Long)
                    **       SrcReg = 4
                    **          MOVE.B, MOVE.W (get Word)
                    **          MOVE.L         (get Long)
                    **
                    ** SOURCE
                    **
                    ** ***************************************
Fn_ID3_SrcMod       CMP.B   #7, opSrcMod                * Check if source mode is 7
                    BEQ     Fn_ID3_ChkSrcReg            * Check source register
                    BRA     Fn_ID3_ChkDstMod           * Source not 7, now check destination Mod
Fn_ID3_ChkSrcReg    CMP.B   #0, opSrcReg                 * Check is source register is 0
                    BEQ     Fn_ID3_DtaSrcWrd            * Load next word
                    CMP.B   #1, opSrcReg                * Check if source register is 1
                    BEQ     Fn_ID3_DtaSrcLng            * Load next long
                    CMP.B   #4, opSrcReg                * Check if source register is 4 (immediate value)
                    BEQ     Fn_ID3_DtaSrcImd            * Load first word into word one
                    BRA     FN_ID3_Error                * Invalid register value

                    ** Note: Checking immediate value
                    **       opID as size is specific to MOVE, MOVEA
                    **       other instructions will use 3 bits to set size, not part of ID
                    **
Fn_ID3_DtaSrcImd    CMP.B   #1, opID                    * opID = 0 - size is byte
                    BEQ     Fn_ID3_DtaSrcImdB           * Load next byte
                    CMP.B   #3, opID                    * opID = 3 - size is word
                    BEQ     Fn_ID3_DtaSrcImdW           * Load next word
                    CMP.B   #2, opID                    * opID = 0 - size is long
                    BEQ     Fn_ID3_DtaSrcImdL           * Load next long
                    BRA     Fn_ID3_Error                * Invalid opID (this should never happen)

Fn_ID3_DtaSrcImdB   *MOVE.W  (A2)+, opDta1               * Load byte and increment address count (note .W for byte)
                    CLR.L   D3
                    MOVE.W  (A2)+,D3
                    MOVE.L  D3,opDta1
                    MOVE.B  #3, opDta1T                 * Set Data 1 type as 0=Byte
                    BRA     Fn_ID3_ChkDstMod            * Check destination mode

Fn_ID3_DtaSrcImdW   *MOVE.W  (A2)+, opDta1               * Load word and increment address count
                    CLR.L   D3
                    MOVE.W  (A2)+,D3
                    MOVE.L  D3,opDta1
                    MOVE.B  #3, opDta1T                 * Set Data 1 type as 1=Word
                    BRA     Fn_ID3_ChkDstMod            * Check destination mode

Fn_ID3_DtaSrcImdL   *MOVE.L  (A2)+, opDta1               * Load long and increment address count
                    CLR.L   D3
                    MOVE.L  (A2)+,D3
                    MOVE.L  D3,opDta1
                    MOVE.B  #3, opDta1T                 * Set Data 1 type as 2=Long
                    BRA     Fn_ID3_ChkDstMod            * Check destination mode

Fn_ID3_DtaSrcByt    *MOVE.W  (A2)+, opDta1               * Load byte and increment address count (note .W for byte)
                    CLR.L   D3
                    MOVE.W  (A2)+,D3
                    MOVE.L  D3,opDta1
                    MOVE.B  #0, opDta1T                 * Set Data 1 type as 0=Byte
                    BRA     Fn_ID3_ChkDstMod            * Check destination mode

Fn_ID3_DtaSrcWrd    *MOVE.W  (A2)+, opDta1               * Load word and increment address count
                    CLR.L   D3
                    MOVE.W  (A2)+,D3
                    MOVE.L  D3,opDta1
                    MOVE.B  #1, opDta1T                 * Set Data 1 type as 1=Word
                    BRA     Fn_ID3_ChkDstMod            * Check destination mode

Fn_ID3_DtaSrcLng    *MOVE.L  (A2)+, opDta1               * Load long and increment address count
                    CLR.L   D3
                    MOVE.L  (A2)+,D3
                    MOVE.L  D3,opDta1
                    MOVE.B  #2, opDta1T                 * Set Data 1 type as 2=Long
                    BRA     Fn_ID3_ChkDstMod            * Check destination mode

                    ** DESTINATION
                    **
Fn_ID3_ChkDstMod    CMP.B   #7, opDstMod                * Check if destination mode is 7
                    BEQ     Fn_ID3_ChkDstReg            * Check destination register
                    BRA     Fn_ID3_Done                 * Destination not 7, done with data
Fn_ID3_ChkDstReg    CMP.B   #0, opDstReg                * Check if destination register is 0
                    BEQ     Fn_ID3_DtaDstWrd            * Load next word
                    CMP.B   #1, opDstReg                * Check if destination register is 1
                    BEQ     Fn_ID3_DtaDstLng            * Load next long
                    BRA     fn_ID3_Error                * Invalid registration Mode

Fn_ID3_DtaDstWrd    *MOVE.W  (A2)+, opDta2               * Load word and increment address count
                    CLR.L   D3
                    MOVE.W  (A2)+,D3
                    MOVE.L  D3,opDta2
                    MOVE.B  #1, opDta2T                 * Set Data2 type as 1=Word
                    BRA     Fn_ID3_Done
Fn_ID3_DtaDstLng    *MOVE.L  (A2)+, opDta2               * Load long and increment address count
                    CLR.L   D3
                    MOVE.L  (A2)+,D3
                    MOVE.L  D3,opDta2
                    MOVE.B  #2, opDta2T                 * Set Data2 type as 2=Long
                    BRA     Fn_ID3_Done

** -----------------------------------------------------------------------------------------------
** End of program
** -----------------------------------------------------------------------------------------------
Fn_ID3_Error        *MOVEM.L (SP)+,D0-D7/A0-A6          * Restore registers
                    MOVE.B  #2, opErr                   * Error 0 = A-OK; 1 = DATA; 2 = Invalid EA
                    RTS

Fn_ID3_Done         *MOVEM.L (SP)+,D0-D7/A0-A6          * Restore registers
                    MOVE.B  #0, opErr                   * Clear error flag so this will display instruction info
                    RTS


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
