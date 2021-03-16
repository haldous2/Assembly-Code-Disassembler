** -----------------------------------------------------------
** Subroutine: ID4
**             Covers JSR, LEA, MOVEM, NOP, NOT, RTS
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
**  opSrcMsk   - source mask bits for MOVEM
**  opSrcMskD  - 4 for pre decrement -(An); any other value post decrement (default)
**  opDstMsk   - destination mask bits for MOVEM
**
**   This will run after the initial jump instruction
**
** -----------------------------------------------------------

SR_ID4              ** Get some bits

                    * Read next 3 bits into D3
                    MOVE.W  opWord, D3                  * store opWord in D3 so it doesn't get modified
                    MOVE.B  #4, D4
                    LSL.W   D4,D3                       * Shift left 4 to get rid of first 4 bits
                    MOVE.B  #13,D4
                    LSR.W   D4,D3                       * Shift right 13 to get next 3 bits
                    MOVE.B  D3, opDstReg

                    * Read next 3 bits into D3
                    MOVE.W  opWord, D3                  * store opWord in D3 so it doesn't get modified
                    MOVE.B  #7, D4
                    LSL.W   D4,D3                       * Shift left 7 to get rid of first 7 bits
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
                    ** Verify instruction
                    **
                    ** JSR: If DstReg=7, DstMod=2
                    ** LEA: If DstReg=0-7, DstMod=7
                    ** MOVEM:
                    **    RegToMem: DestReg=4, DestMod=2,3
                    **    MemToReg: DestReg=6, DestMod=2,3
                    ** NOP: If DestReg=7, DstMod=1, SrcMod=6, SrcReg=1
                    ** NOT: If DstReg=3, DstMod=0-2
                    ** RTS: If DstReg=7, DstMod=1, SrcMod=6, SrcReg=5
                    **
                    ** ***************************************
                    CMP.B   #0, opDstMod
                    BEQ     Fn_ID4_NOT
                    CMP.B   #1, opDstMod
                    BEQ     Fn_ID4_CheckD1
                    CMP.B   #2, opDstMod
                    BEQ     Fn_ID4_CheckD2
                    CMP.B   #3, opDstMod
                    BEQ     Fn_ID4_CheckD3
                    CMP.B   #7, opDstMod
                    BEQ     Fn_ID4_LEA
                    BRA     Fn_ID4_Error

Fn_ID4_CheckD1
** ***************************************
** Possibilites of DestMod=1
**
** NOT (DstMod=0-2) - If DstReg=3
** NOP (DstMod=1) - SrcReg=1
** RTS (DstMod=1) - SrcReg=5
**
** ***************************************
                    CMP.B   #3, opDstReg
                    BEQ     Fn_ID4_NOT
                    CMP.B   #1, opSrcReg
                    BEQ     Fn_ID4_NOP
                    CMP.B   #5, opSrcReg
                    BEQ     Fn_ID4_RTS

Fn_ID4_CheckD2
** ***************************************
** Possibilites of DestMod=2
**
** NOT (DstMod=0-2) - If DstReg=3
** JSR (DstMod=2) - If DstReg=7
** MOVEM(RtoM) (DstMod=2,3) - If DstReg=4
** MOVEM(MtoR) (DstMod=2,3) - If DstReg=6
**
** ***************************************
                    CMP.B   #3, opDstReg
                    BEQ     Fn_ID4_NOT
                    CMP.B   #4, opDstReg
                    BEQ     Fn_ID4_MOVEMRTOM
                    CMP.B   #6, opDstReg
                    BEQ     Fn_ID4_MOVEMMTOR
                    CMP.B   #7, opDstReg
                    BEQ     Fn_ID4_JSR
Fn_ID4_CheckD3
** ***************************************
** Possibilites of DestMod=3
**
** MOVEM(RtoM) (DstMod=2,3) - If DstReg=4
** MOVEM(MtoR) (DstMod=2,3) - If DstReg=6
**
** ***************************************
                    CMP.B   #4, opDstReg
                    BEQ     Fn_ID4_MOVEMRTOM
                    CMP.B   #6, opDstReg
                    BEQ     Fn_ID4_MOVEMMTOR

** ***************************************
** JSR
** ***************************************
Fn_ID4_JSR          LEA     opNam_JSR,A3
                    MOVE.L  A3, opPtrNam

                    CMP.B   #7, opDstReg
                    BNE     Fn_ID4_Error
                    CMP.B   #2, opDstMod
                    BNE     Fn_ID4_Error

                    * Make sure src mode is only 2,5,6,7 (not 0,1,3,4)
                    CMP.B   #0, opSrcMod
                    BEQ     Fn_ID4_Error
                    CMP.B   #1, opSrcMod
                    BEQ     Fn_ID4_Error
                    CMP.B   #3, opSrcMod
                    BEQ     Fn_ID4_Error
                    CMP.B   #4, opSrcMod
                    BEQ     Fn_ID4_Error

                    * Make sure src reg is between 0-7
                    CMP.B   #0, opSrcReg                * Destination register >= 0
                    BLT     Fn_ID4_Error
                    CMP.B   #7, opSrcReg                * Destination register <= 7
                    BGT     Fn_ID4_Error

          					CMP.B   #7, opSrcMod
                    BEQ     Fn_ID4_JSR_DtaS
                    BRA     Fn_ID4_JSR_Final

Fn_ID4_JSR_DtaS     CMP.B   #0, opSrcReg                * Check is source register is 0
                    BEQ     Fn_ID4_JSR_DtaSW            * Load next word
                    CMP.B   #1, opSrcReg                * Check if source register is 1
                    BEQ     Fn_ID4_JSR_DtaSL            * Load next long

Fn_ID4_JSR_DtaSW    MOVE.B  #1, opDta2T                 * Set Data 1 type as 1=Word
                    CLR.L   D3
                    MOVE.W  (A2)+, D3                   * Load word and increment address count
					          MOVE.L  D3,opDta2
                    BRA     Fn_ID4_JSR_Final
Fn_ID4_JSR_DtaSL    MOVE.B  #2, opDta2T                 * Set Data 1 type as 2=Long
                    CLR.L   D3
                    MOVE.L  (A2)+, D3                   * Load long and increment address count
					          MOVE.L  D3,opDta2
                    BRA     Fn_ID4_JSR_Final

Fn_ID4_JSR_Final    MOVE.B  opSrcMod,opDstMod
          					MOVE.B  opSrcReg,opDstReg
          					MOVE.B	#$FF,opSrcMod

                    BRA     Fn_ID4_Done

** ***************************************
** LEA
** ***************************************
Fn_ID4_LEA          LEA     opNam_LEA,A3
                    MOVE.L  A3, opPtrNam

                    CMP.B   #7, opDstMod
                    BNE     Fn_ID4_Error

                    * Make sure src mode is only 2,5,6,7 (not 0,1,3,4)
                    CMP.B   #0, opSrcMod
                    BEQ     Fn_ID4_Error
                    CMP.B   #1, opSrcMod
                    BEQ     Fn_ID4_Error
                    CMP.B   #3, opSrcMod
                    BEQ     Fn_ID4_Error
                    CMP.B   #4, opSrcMod
                    BEQ     Fn_ID4_Error

                    * Make sure src reg is between 0-7
                    CMP.B   #0, opSrcReg                * Destination register >= 0
                    BLT     Fn_ID4_Error
                    CMP.B   #7, opSrcReg                * Destination register <= 7
                    BGT     Fn_ID4_Error

					          MOVE.B  #1,opDstMod

                    CMP.B   #7, opSrcMod
                    BEQ     Fn_ID4_LEA_DtaS
                    BRA     Fn_ID4_Done

Fn_ID4_LEA_DtaS     CMP.B   #0, opSrcReg                * Check is source register is 0
                    BEQ     Fn_ID4_LEA_DtaSW            * Load next word
                    CMP.B   #1, opSrcReg                * Check if source register is 1
                    BEQ     Fn_ID4_LEA_DtaSL            * Load next long
                    BRA     Fn_ID4_Error

Fn_ID4_LEA_DtaSW    MOVE.B  #1,opDta1T                  * Set Data 1 type as 1=Word
                    CLR.L   D3
                    MOVE.W  (A2)+, D3                   * Load word and increment address count
					          MOVE.L  D3,opDta1
                    BRA     Fn_ID4_Done
Fn_ID4_LEA_DtaSL    MOVE.B  #2,opDta1T                  * Set Data 1 type as 1=Long
                    CLR.L   D3
                    MOVE.L  (A2)+, D3                   * Load long and increment address count
					          MOVE.L  D3,opDta1
                    BRA     Fn_ID4_Done

** ***************************************
** MOVEM RTOM
**
** 48D0 00FF           MOVEM.L DO-D7,(A0)
** 48F8 00FF 3000      MOVEM.L DO-D7,$3000
** 48F8 00FF 3000      MOVEM.L DO-D7,$00003000 (display will output $3000)
** 48F9 00FF A0003000  MOVEM.L DO-D7,$A0003000
** (op)(msk)(addr)
** ***************************************
Fn_ID4_MOVEMRtoM    LEA     opNam_MOVEM,A3
                    MOVE.L  A3, opPtrNam

                    * Make sure src mode is only 2,4,5,6,7 (not 0,1,3)
                    CMP.B   #0, opSrcMod
                    BEQ     Fn_ID4_Error
                    CMP.B   #1, opSrcMod
                    BEQ     Fn_ID4_Error
                    CMP.B   #3, opSrcMod
                    BEQ     Fn_ID4_Error

                    * Make sure src reg is between 0-7
                    CMP.B   #0, opSrcReg                * Destination register >= 0
                    BLT     Fn_ID4_Error
                    CMP.B   #7, opSrcReg                * Destination register <= 7
                    BGT     Fn_ID4_Error

                    ** At this point
                    ** DstMod is size
                    ** SrcMod is memory register mode
                    ** SrcReg is memory register type
                    ** Need to fill opDta2
                    ** Need to hide source to display mask

          					MOVE.B  opDstMod,opValSiz            * Set size of instruction W or L
          					SUB.B   #1,opValSiz                  * Adjust size for display

                    ** Added this - always get the mask
                    CLR.L   D3
                    MOVE.W  (A2)+,D3
                    MOVE.W  D3,opSrcMsk                  * Set mask word value
                    MOVE.B  opSrcMod,D3
                    MOVE.B  D3,opSrcMskD                 * Set mask direction flag

                    CMP.B   #7, opSrcMod
                    BEQ     Fn_ID4_MvRMDta
                    BRA     Fn_ID4_MvRMFinal

** Added this - the data needs to be set for opDta1 for RM, opDta2 for MR
** Note: removed immediate data - there isn't immediate data
Fn_ID4_MvRMDta      CMP.B   #0, opSrcReg                * Check is source register is 0
                    BEQ     Fn_ID4_MvRMDtaEW            * Load next word
                    CMP.B   #1, opSrcReg                * Check if source register is 1
                    BEQ     Fn_ID4_MvRMDtaEL            * Load next long
                    BRA     Fn_ID4_Error                * Invalid Reg code - bloop

Fn_ID4_MvRMDtaEW    MOVE.B  #1, opDta2T                 * Set Data 1 type as 1=Word
                    CLR.L   D3
                    MOVE.W  (A2)+, D3                   * Load word and increment address count
					          MOVE.L  D3,opDta2
                    BRA     Fn_ID4_MvRMFinal

Fn_ID4_MvRMDtaEL    MOVE.B  #2, opDta2T                 * Set Data 1 type as 2=Long
                    CLR.L   D3
                    MOVE.L  (A2)+, D3               * Load long and increment address count
					          MOVE.L  D3,opDta2
                    BRA     Fn_ID4_MvRMFinal

Fn_ID4_MvRMFinal    MOVE.B  opSrcMod,opDstMod            * Swap Dst with Src for display
          					MOVE.B  opSrcReg,opDstReg            * Swap Dst with Src for display
          					MOVE.B  #$FF,opSrcMod                * Hide source from display

                    BRA     Fn_ID4_Done

** ***************************************
** MOVEM MTOR
**
** 4CD0 00FF           MOVEM.L (A0),DO-D7
** 4CF8 00FF 3000      MOVEM.L $3000,DO-D7
** 4CF8 00FF 3000      MOVEM.L $00003000,DO-D7 (display will output $3000)
** 4CF9 00FF A0003000  MOVEM.L $A0003000,DO-D7
** (op)(msk)(addr)
** ***************************************
FN_ID4_MOVEMMtoR    LEA     opNam_MOVEM,A3
                    MOVE.L  A3, opPtrNam

                    * already checked this to get here
                    *CMP.B   #6, opDstReg
                    *BNE     Fn_ID4_Error

                    * already checked this to get here
                    * Make sure dest mode is only 2 or 3
                    * Make sure dest mode is only 2 or 3
                    *CMP.B   #2, opDstMod                * Destination register > 2
                    *BLT     Fn_ID4_Error
                    *CMP.B   #3, opDstMod                * Destination register < 3
                    *BGT     Fn_ID4_Error

                    * Make sure src mode is only 2,3,5,6,7 (not 0,1,4)
                    CMP.B   #0, opSrcMod
                    BEQ     Fn_ID4_Error
                    CMP.B   #1, opSrcMod
                    BEQ     Fn_ID4_Error
                    CMP.B   #4, opSrcMod
                    BEQ     Fn_ID4_Error

                    * Make sure src reg is between 0-7
                    CMP.B   #0, opSrcReg                * Destination register >= 0
                    BLT     Fn_ID4_Error
                    CMP.B   #7, opSrcReg                * Destination register <= 7
                    BGT     Fn_ID4_Error

                    ** At this point
                    ** DstMod is size
                    ** SrcMod is memory register mode
                    ** SrcReg is memory register type
                    ** Need to fill opDta1
                    ** Need to hide destination to display mask

          					MOVE.B  opDstMod,opValSiz            * Set size of instruction W or L
          					SUB.B   #1,opValSiz                  * Adjust size for display

                    ** Added this - always get the mask
                    CLR.L   D3
                    MOVE.W  (A2)+, D3
                    MOVE.W  D3,opDstMsk                  * Set mask word value

                    CMP.B   #7, opSrcMod
                    BEQ     Fn_ID4_MvMRDta
                    BRA     Fn_ID4_MvMRFinal

** Added this - the data needs to be set for opDta1 for RM, opDta2 for MR
Fn_ID4_MvMRDta      CMP.B   #0, opSrcReg                * Check is source register is 0
                    BEQ     Fn_ID4_MvMRDtaEW            * Load next word
                    CMP.B   #1, opSrcReg                * Check if source register is 1
                    BEQ     Fn_ID4_MvMRDtaEL            * Load next long
                    BRA     Fn_ID4_Error                * Invalid Reg code - bloop

Fn_ID4_MvMRDtaEW    MOVE.B  #1, opDta1T                 * Set Data 1 type as 1=Word
                    CLR.L   D3
                    MOVE.W  (A2)+, D3               * Load word and increment address count
					          MOVE.L  D3,opDta1
                    BRA     Fn_ID4_MvMRFinal

Fn_ID4_MvMRDtaEL    MOVE.B  #2, opDta1T                 * Set Data 1 type as 2=Long
                    CLR.L   D3
                    MOVE.L  (A2)+, D3               * Load long and increment address count
					          MOVE.L  D3,opDta1
                    BRA     Fn_ID4_MvMRFinal

                    ** Added this to hide destination
Fn_ID4_MvMRFinal    MOVE.B	#$FF,opDstMod

                    BRA     Fn_ID4_Done

** ***************************************
** NOP
** ***************************************
Fn_ID4_NOP          LEA     opNam_NOP,A3
                    MOVE.L  A3, opPtrNam

Fn_ID4_VERIFY_NOP   CMP.B   #7,opDstReg
                    BNE     Fn_ID4_Error
                    CMP.B   #1, opDstMod
                    BNE     Fn_ID4_Error
                    CMP.B   #6, opSrcMod
                    BNE     Fn_ID4_Error
                    CMP.B   #1, opSrcReg
                    BNE     Fn_ID4_Error
					MOVE.B  #$FF, opDstMod
					MOVE.B	#$FF,opSrcMod
                    BRA     Fn_ID4_Done


** ***************************************
** NOT
** ***************************************
Fn_ID4_NOT          LEA     opNam_NOT,A3
                    MOVE.L  A3, opPtrNam

                    CMP.B   #3, opDstReg
                    BNE     Fn_ID4_Error

                    * Make sure src mode is not 1
                    CMP.B   #1, opSrcMod
                    BEQ     Fn_ID4_Error

                    * Make sure src reg is between 0-7
                    CMP.B   #0, opSrcReg                * Destination register >= 0
                    BLT     Fn_ID4_Error
                    CMP.B   #7, opSrcReg                * Destination register <= 7
                    BGT     Fn_ID4_Error

                    MOVE.W  opDstMod,opValSiz           * Dest mod holds the size (move it)
                    CMP.B   #7, opSrcMod
                    BEQ     Fn_ID4_NOT_DtaS
                    BRA     Fn_ID4_NOT_Final

Fn_ID4_NOT_DtaS     CMP.B   #0, opSrcReg                * Check is source register is 0
                    BEQ     Fn_ID4_NOT_DtaSW            * Load next word
                    CMP.B   #1, opSrcReg                * Check if source register is 1
                    BEQ     Fn_ID4_NOT_DtaSL            * Load next long

Fn_ID4_NOT_DtaSW    MOVE.B  #1, opDta2T                 * Set Data 1 type as 1=Word
                    CLR.L   D3
                    MOVE.W  (A2)+, D3                   * Load word and increment address count
					          MOVE.L  D3,opDta2
                    BRA     Fn_ID4_NOT_Final
Fn_ID4_NOT_DtaSL    MOVE.B  #2, opDta2T                 * Set Data 1 type as 1=Word
                    CLR.L   D3
                    MOVE.L  (A2)+, D3                   * Load long and increment address count
					          MOVE.L  D3,opDta2
                    BRA     Fn_ID4_NOT_Final

Fn_ID4_NOT_Final    MOVE.B  opSrcMod,opDstMod            * Swap Dst with Src for display
          					MOVE.B  opSrcReg,opDstReg            * Swap Dst with Src for display
          					MOVE.B  #$FF,opSrcMod                * Hide source from display

                    BRA     Fn_ID4_Done

** ***************************************
** RTS
** ***************************************
Fn_ID4_RTS          LEA    opNam_RTS,A3
                    MOVE.L A3, opPtrNam

Fn_ID4_VERIFY_RTS   CMP.B   #7,opDstReg
                    BNE     Fn_ID4_Error
                    CMP.B   #1, opDstMod
                    BNE     Fn_ID4_Error
                    CMP.B   #6, opSrcMod
                    BNE     Fn_ID4_Error
                    CMP.B   #5, opSrcReg
                    BNE     Fn_ID4_Error
          					MOVE.B  #$FF, opDstMod
          					MOVE.B	#$FF,opSrcMod
                    BRA     Fn_ID4_Done

** -----------------------------------------------------------------------------------------------
** End of program
** -----------------------------------------------------------------------------------------------
Fn_ID4_Error        *MOVEM.L (SP)+,D0-D7/A0-A6          * Restore registers
                    MOVE.B  #2, opErr                   * Error 0 = A-OK; 1 = DATA; 2 = Invalid EA
                    RTS

Fn_ID4_Done         *MOVEM.L (SP)+,D0-D7/A0-A6          * Restore registers
                    MOVE.B  #0, opErr                   * Clear error flag so this will display instruction info
                    RTS

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
