
** -----------------------------------------------------------
** Subroutine: ID8
**             Covers OR
**
**   This will run after the initial jump instruction
**
** -----------------------------------------------------------

SR_ID8              * This is to grab the first four that are already set, ID4
                    MOVE.W  opWord, D3                  * store opWord in D3 so it doesn't get modified
                    MOVE.B  #12,D4
                    LSR.W   D4,D3                       * Shift right 12 to get first 4 bits
                    MOVE.B  D3, opID        
                    
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
					
					** Find out if its Dn, ea or ea, Dn
					** Dn->ea - 0,1,2
					** ea->Dn - 4,5,6
					LEA     opNam_OR,A3
                    MOVE.L  A3, opPtrNam
					CMP.B	#3,opDstMod
					BLT		Fn_ID8D_Case1
					CMP.B   #7,opDstMod
					BLT     Fn_ID8D_Case2
					BRA     Fn_ID8_Error

** ea -> Dn
Fn_ID8D_Case1		MOVE.B  opDstMod,opID
					MOVE.B  #0,opDstMod
					CMP.B   #0,opID
					BEQ		Fn_ID8D_Src_SetB
					CMP.B   #1,opID
					BEQ		Fn_ID8D_Src_SetW
					CMP.B   #2,opID
					BEQ		Fn_ID8D_Src_SetL

** Dn -> ea
Fn_ID8D_Case2		MOVE.B  opDstMod,opID
					SUB.B   #4,opID
					**
					MOVE.B  opSrcMod,opDstMod
					MOVE.B  opDstReg,D6
					MOVE.B  opSrcReg,opDstReg
					MOVE.B  D6,opSrcReg
					MOVE.B  #0,opSrcMod
					**
					CMP.B   #0,opID
					BEQ		Fn_ID8D_Dst_SetB
					CMP.B   #1,opID
					BEQ		Fn_ID8D_Dst_SetW
					CMP.B   #2,opID
					BEQ		Fn_ID8D_Dst_SetL
					
Fn_ID8D_Dst_SetB     MOVE.B  #0,opValSiz
					** Immediate data?
					CMP.B   #7, opDstMod
                    BEQ     Fn_ID8D_DataDst
                    BRA     Fn_ID8_Done

Fn_ID8D_Dst_SetW     MOVE.B  #1,opValSiz
					** Immediate data?
					CMP.B   #7, opDstMod
                    BEQ     Fn_ID8D_DataDst
                    BRA     Fn_ID8_Done
					
Fn_ID8D_Dst_SetL     MOVE.B  #2,opValSiz
					** Immediate data?
					CMP.B   #7, opDstMod
                    BEQ     Fn_ID8D_DataDst
                    BRA     Fn_ID8_Done
					
Fn_ID8D_Src_SetB     MOVE.B  #0,opValSiz
					** Immediate data?
					CMP.B   #7, opSrcMod
                    BEQ     Fn_ID8D_DataSrc
                    BRA     Fn_ID8_Done

Fn_ID8D_Src_SetW     MOVE.B  #1,opValSiz
					** Immediate data?
					CMP.B   #7, opSrcMod
                    BEQ     Fn_ID8D_DataSrc
                    BRA     Fn_ID8_Done
					
Fn_ID8D_Src_SetL     MOVE.B  #2,opValSiz
					** Immediate data?
					CMP.B   #7, opSrcMod
                    BEQ     Fn_ID8D_DataSrc
                    BRA     Fn_ID8_Done
					
Fn_ID8D_DataDst     CMP.B   #0, opDstReg                * Check is source register is 0
                    BEQ     Fn_ID8D_SetDstWrd            * Load next word
                    CMP.B   #1, opDstReg                * Check if source register is 1
                    BEQ     Fn_ID8D_SetDstLng            * Load next long
                    CMP.B   #4, opDstReg                * Check if source register is 4 (immediate value)
                    BEQ     Fn_ID8D_DtaDstImd            * Load first word into word one
                    BRA     Fn_ID8_Error                * Invalid register value
                    
Fn_ID8D_DtaDstImd   MOVE.B  #3, opDta2T
					CMP.B   #0, opID
					BEQ     Fn_ID8D_DtaDstByt
					CMP.B   #1, opID                    * opID = 0 - size is byte
                    BEQ     Fn_ID8D_DtaDstByt            * Load next byte
                    CMP.B   #3, opID                    * opID = 3 - size is word
                    BEQ     Fn_ID8D_DtaDstWrd            * Load next word
                    CMP.B   #2, opID                    * opID = 0 - size is long
                    BEQ     Fn_ID8D_DtaDstLng            * Load next
                    BRA     Fn_ID8_Error                * Invalid opID (this should never happen) long

Fn_ID8D_DtaDstByt   CLR.L   D3
					MOVE.W  (A2)+, D3               * Load byte and increment address count (note .W for byte)
					MOVE.L  D3,opDta2
                    BRA     Fn_ID8_Done
Fn_ID8D_SetDstWrd   MOVE.B  #1, opDta2T                 * Set Data 1 type as 1=Word
Fn_ID8D_DtaDstWrd   CLR.L   D3
					MOVE.W  (A2)+, D3               * Load word and increment address count
					MOVE.W  D3,opDta2
                    BRA     Fn_ID8_Done
Fn_ID8D_SetDstLng   MOVE.B  #2, opDta2T                 * Set Data 1 type as 2=Long
Fn_ID8D_DtaDstLng   CLR.L   D3
					MOVE.L  (A2)+, D3               * Load long and increment address count
					MOVE.L  D3,opDta2
                    BRA     Fn_ID8_Done
					
Fn_ID8D_DataSrc     CMP.B   #0, opSrcReg                * Check is source register is 0
                    BEQ     Fn_ID8D_SetSrcWrd            * Load next word
                    CMP.B   #1, opSrcReg                * Check if source register is 1
                    BEQ     Fn_ID8D_SetSrcLng            * Load next long
                    CMP.B   #4, opSrcReg                * Check if source register is 4 (immediate value)
                    BEQ     Fn_ID8D_DtaSrcImd            * Load first word into word one
                    BRA     Fn_ID8_Error                * Invalid register value
                    
Fn_ID8D_DtaSrcImd   MOVE.B  #3, opDta1T
					CMP.B   #0, opID
					BEQ     Fn_ID8D_DtaSrcByt
					CMP.B   #1, opID                    * opID = 0 - size is byte
                    BEQ     Fn_ID8D_DtaSrcByt            * Load next byte
                    CMP.B   #3, opID                    * opID = 3 - size is word
                    BEQ     Fn_ID8D_DtaSrcWrd            * Load next word
                    CMP.B   #2, opID                    * opID = 0 - size is long
                    BEQ     Fn_ID8D_DtaSrcLng            * Load next
                    BRA     Fn_ID8_Error                * Invalid opID (this should never happen) long

Fn_ID8D_DtaSrcByt   CLR.L   D3
					MOVE.W  (A2)+, D3               * Load byte and increment address count (note .W for byte)
					MOVE.L  D3,opDta1
                    BRA     Fn_ID8_Done
Fn_ID8D_SetSrcWrd   MOVE.B  #1, opDta1T                 * Set Data 1 type as 1=Word
Fn_ID8D_DtaSrcWrd   CLR.L   D3
					MOVE.W  (A2)+, D3               * Load word and increment address count
					MOVE.W  D3,opDta1
                    BRA     Fn_ID8_Done
Fn_ID8D_SetSrcLng   MOVE.B  #2, opDta1T                 * Set Data 1 type as 2=Long
Fn_ID8D_DtaSrcLng   CLR.L   D3
					MOVE.L  (A2)+, D3               * Load long and increment address count
					MOVE.L  D3,opDta1
                    BRA     Fn_ID8_Done

** -----------------------------------------------------------------------------------------------
** End of program
** -----------------------------------------------------------------------------------------------
Fn_ID8_Error        *MOVEM.L (SP)+,D0-D7/A0-A6          * Restore registers
                    MOVE.B  #2, opErr                   * Error 0 = A-OK; 1 = DATA; 2 = Invalid EA
                    RTS

Fn_ID8_Done         *MOVEM.L (SP)+,D0-D7/A0-A6          * Restore registers
                    MOVE.B  #0, opErr                   * Clear error flag so this will display instruction info
                    RTS



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
