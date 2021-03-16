** -----------------------------------------------------------
* Title      : Disassembler
* Written by : 3 Cores
* Date       : Winter 2021
* Description: CSS 422 machine code disassembler
** -----------------------------------------------------------

                    ORG    $1000

** -----------------------------------------------------------
** MAIN LOGIC
**
** Program data (do not overwrite)
**   D0 - Reserved for Trap
**   D1 - Reserved for Trap
**   D2 - Reserved for Trap
**   D7 - Line Counter (do not overwrite)

**   A0 - Jump Table
**   A1 - Reserved for Trap
**   A2 - Pointer to Instruction space (the contents being disassembled)
**   A3 - Pointer to Output buffer
**   A7 - Stack pointer
**
** Other data (ok to overwrite)
**   D3 - misc
**   D4 - misc
**   D5 - misc
**   D6 - misc
**   A4 - misc
**   A5 - misc
**   A6 - misc
**
** -----------------------------------------------------------
MAIN
                    MOVEA.L #$00100000,SP           * Initialize stack pointer
Fn_MAIN_Start

                    ** Test addresses if SR_UI_INPUT is turned off
                    **
                    MOVE.L  #$00009000, adrValStart
                    MOVE.L  #$000093D0, adrValEnd

                    ** Address input interface
                    ** Note: comment out to run tests
                    **
                    JSR     SR_UI_INPUT             * Initiate user input for addresses

                    ** Load address strings for display
                    **
                    LEA     adrValStart,A4
                    LEA     adrStrStart,A5
                    JSR     SR_HEX_STR              * Copy address value to string for display
                    LEA     adrValEnd,A4
                    LEA     adrStrEnd,A5
                    JSR     SR_HEX_STR              * Copy address value to string for display

                    ** Main program variable setup
                    ** Note: Don't change this!
                    **
                    CLR.B   D7                      * Reset line counter to zero
                    LEA     SR_JUMP,A0              * Mem space for jump table
                    MOVE.L  adrValStart,A2          * Mem space for disassembly

                    ** Clear screen
                    MOVE.B  #11,D0                  * Trap task 2 does the following:
                    MOVE.W  #$FF00,D1               * Clear the screen
                    TRAP    #15

                    ** Display header
                    JSR     SR_DSP_HEADER
fn_MAIN_Loop
                    ** Prepare loop variables
                    **
                    MOVE.L  A2,opValAdr             * Set output address as current - need for display
                    MOVE.W  (A2)+,opWord            * load first 16 bit OpCode Word, increment A2
                    MOVE.L  A2,opNxtAdr             * Save next valid word address for invalid instruction

                    ** Reset local variables
                    **

                    MOVE.B  #$00,opID               * Reset opID (first 4 bits of opcode word)
                    MOVE.B  #$01,opErr              * Reset error $01 - assume DATA until instruction found
                    MOVE.b  #$FF,opValSiz

                    MOVE.B  #$FF, opDstReg
                    MOVE.B  #$FF, opDstMod
                    MOVE.B  #$FF, opSrcReg
                    MOVE.B  #$FF, opSrcMod

                    MOVE.L  #$0000, opDta1
                    MOVE.B  #$FF, opDta1T
                    MOVE.L  #$0000, opDta2
                    MOVE.B  #$FF, opDta2T

                    MOVE.L  #$0000,opSrcMsk
                    MOVE.B  #$00,opSrcMskD
                    MOVE.L  #$0000,opDstMsk
                    MOVE.B  #$00,opRotate
                    MOVE.B  #$00,opSizDir
                    MOVE.B  #$00,opIR

                    ** Jump table
                    **
                    MOVE.W  opWord,D5               * opWord to D5 for multiplication
                    MOVE.B  #12,D6
                    LSR.W   D6,D5                   * Shift 12 bits to the right (to get first 4 bits)
                    MULU    #8,D5                   * offset is multiple of 8
                    JSR     0(A0,D5)                * Jump indirect with index

                    ** Invalid instruction
                    **
                    CMP.B   #1,opErr
                    BEQ     Fn_MAIN_ErrIns          * Instruction error, reset A2
                    CMP.B   #2,opErr
                    BEQ     Fn_MAIN_ErrIns
                    BRA     Fn_MAIN_Dsp             * Instruction valid, display
Fn_MAIN_ErrIns      MOVE.L  opNxtAdr,A2             * Resetting A2 to next valid word

                    ** Display result
                    **
Fn_MAIN_Dsp         JSR     SR_DSP_DISPLAY

                    ** Max lines display stop, wait for enter
                    **
Fn_MAIN_ChkLin      ADDI.B  #1,D7                   * Increment line counter

                    MOVE.L  D7,D6                   * Line counter to D6 for division
                    DIVU.W  #maxLines,D6            * Divide unsigned -> [remainder|quotient]
                    SWAP    D6                      * Swap for remainder (modulo)
                    CMP.B   #0,D6                   * Check remainder for zero
                    BEQ     Fn_MAIN_ChkPag          * Reached the maximum number of lines per page
                    BRA     Fn_MAIN_ChkEnd          * Continue to Check if at End of address space

                    ** Logic to check ENTER key to show next page
                    **
Fn_MAIN_ChkPag      LEA     msgPage,A1              * Loads MESSAGE into A1
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15                     * Display to screen
                    MOVE.B  #5,D0                   * Trap task 2 does the following:
                    TRAP    #15                     * Read single char into D1.B - repurposed for ENTER key

                    ** Clear screen
                    MOVE.B  #11,D0                  * Trap task 2 does the following:
                    MOVE.W  #$FF00,D1               * Clear the screen
                    TRAP    #15

                    ** Display header
                    JSR     SR_DSP_HEADER

                    ** Reached end of memory @ A2 - stop main logic, ask to do it again
                    **
Fn_MAIN_ChkEnd      CMP.L   adrValEnd, A2
                    BGE     Fn_MAIN_ChkAgn          * Reached end of memory region
                    BRA     Fn_MAIN_Continue        * Continue to next loop iteration

                    ** Logic to check for for Y or N to check another region of memory
                    **
Fn_MAIN_ChkAgn      LEA     msgEndMem01,A1          * Loads MESSAGE into A1
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15                     * Display to screen
                    LEA     msgEndMem02,A1          * Loads MESSAGE into A1
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15                     * Display to screen

                    LEA     msgInTemp,A1            * Load placeholder for input string
                    MOVE.B  #2,D0                   * Trap task 2 does the following:
                    TRAP    #15                     * Read string to (A1), length in D1.W
                    CMP.B   #$59,(A1)               * Checking for 'Y' - otherwise Nope
                    BEQ     Fn_MAIN_Start           * Restart program
                    CMP.B   #$79,(A1)               * Checking for 'y' - otherwise Nope
                    BEQ     Fn_MAIN_Start           * Restart program
                    BRA     Fn_Main_Done            * Exit program

Fn_MAIN_Continue    BRA     Fn_MAIN_Loop            * Loop around and check another Word

Fn_MAIN_Done        ** That's all folks
                    MOVE.B  #11,D0                  * Trap task 2 does the following:
                    MOVE.W  #$FF00,D1               * Clear the screen
                    TRAP    #15

                    ** Thank you message
                    LEA     msgDone,A1              * Loads MESSAGE into A1
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15                     * Display to screen

                    SIMHALT
                    *STOP   #$2700                   * Stop execution

** -----------------------------------------------------------
** JUMP TABLE: First 4 bits of instruction
**
** Jump instruction: pointing to label (xxx).L
**  |4    E    |F    9     |00 |00 |04 |80 - Offset 6 bytes
**                          label address (Long)
**
** RTS instruction:
**  |4    E    |7    5     |               - Offset 2 bytes
**
** e.g. If looking for code0010 - 8 bytes (offset) * 4 bit code (0 to 15)
**
** Note: should find a value since 4 bits is 0 to F
** Note: There aren't any instructions that start with F
**
** -----------------------------------------------------------
SR_JUMP             JSR     SR_IDX                  * No instructions @ ID=0
                    RTS
                    JSR     SR_ID3
                    RTS
                    JSR     SR_ID3
                    RTS
                    JSR     SR_ID3                  * Instructions @ ID=1,2,3 MOVE, MOVEA
                    RTS
                    JSR     SR_ID4
                    RTS
                    JSR     SR_ID5
                    RTS
                    JSR     SR_ID6
                    RTS
                    JSR     SR_ID7
                    RTS
                    JSR     SR_ID8
                    RTS
                    JSR     SR_ID9
                    RTS
                    JSR     SR_IDA
                    RTS
                    JSR     SR_IDB
                    RTS
                    JSR     SR_IDC
                    RTS
                    JSR     SR_IDD
                    RTS
                    JSR     SR_IDE
                    RTS
                    JSR     SR_IDX                   * No instructions @ ID=15
                    RTS

** -----------------------------------------------------------
** UI: User mem input
** -----------------------------------------------------------
SR_UI_INPUT
                    MOVE.B  $FF,adrStsStart         * Reset starting address status
                    MOVE.B  $FF,adrStsEnd           * Reset ending address status

Fn_UI_Loop          ** Clear screen
                    MOVE.B  #11,D0                  * Trap task 2 does the following:
                    MOVE.W  #$FF00,D1               * Clear the screen
                    TRAP    #15

                    ** Header
                    ** ***************************************

                    LEA     msgLine,A1              * '********************'
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15                     * Display to screen

                    LEA     msgHdr01,A1             * '3 Cores disassembler'
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15                     * Display to screen

                    CMP.B   #0,adrStsStart          * Starting address is set
                    BEQ     Fn_UI_DspStart          * Display starting address
                    BRA     Fn_UI_HdrNext           * Display the rest of the header

Fn_UI_DspStart      LEA     msgStrAdr1Scc,A1        * 'Starting address: '
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15                     * Display to screen

                    LEA     adrStrStart,A1          * '89ABCDEF' (string address)
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15                     * Display to screen

                    LEA     msgNewLine,A1           * CR,LF
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15                     * Display to screen

Fn_UI_HdrNext       LEA     msgLine,A1              * '********************'
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15                     * Display to screen

                    LEA     msgStrIntro,A1          * ' - All addresses must be 32 bit hexadecimal.'
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15                     * Display to screen

                    LEA     msgStrRange,A1          * ' - Valid address range is 00000000 to 00FFFFFF.'
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15                     * Display to screen

                    LEA     msgStrSize,A1           * ' - Starting address should start on a word boundry'
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15                     * Display to screen

                    LEA     msgStrSizeExmpl,A1      * '   @ XXXXXXX(0,2,4,8,A,C,E).'
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15                     * Display to screen

                    LEA     msgStrNote,A1           * ' - Addresses will be adjusted if out of order or out of range.'
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15                     * Display to screen

                    LEA     msgStrNoteMore,A1       * '   (automagically)'
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15                     * Display to screen

                    LEA     msgNewLine,A1           * CR,LF
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15                     * Display to screen

                    ** Input check
                    ** ***************************************

                    CMP.B #0,adrStsStart            * Check status of address 0 = success
                    BNE   Fn_UI_Start               * Input starting address

                    CMP.B #0,adrStsEnd              * Check status of address 0 = success
                    BNE   Fn_UI_End                 * Input ending address

                    *BRA   Fn_UI_Done                * Both addresses set, bail out of UI
                    BRA   Fn_UI_ChkVal              * Check address values (range, order)

Fn_UI_Start         ** Input Start Address
                    ** ***************************************

                    ** Check errors
                    CMP.B   #1,adrStsStart
                    BEQ     Fn_UI_StartE1           * Error: length
                    CMP.B   #2,adrStsStart
                    BEQ     Fn_UI_StartE2           * Error: hex value
                    BRA     Fn_UI_Start_In          * No error: ask for input

Fn_UI_StartE1       LEA     msgStrAdr1Err1,A1       * 'Invalid starting address length'
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15
                    BRA     Fn_UI_Start_In          * User input

Fn_UI_StartE2       LEA     msgStrAdr1Err2,A1       * 'Invalid starting address hexadecimal value'
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15
                    BRA     Fn_UI_Start_In          * User input

Fn_UI_Start_In      LEA     msgStrAdr1,A1           * 'Please enter a starting address'
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15                     * Display to screen

                    LEA     msgInTemp,A1            * Load placeholder for input string
                    MOVE.B  #2,D0                   * Trap task 2 does the following:
                    TRAP    #15                     * Read string to (A1), length in D1.W

                    BRA     Fn_UI_ChkLen            * Check addresses (length, hex validation)

Fn_UI_End           ** Input End Address
                    ** ***************************************

                    ** Check errors
                    CMP.B   #1,adrStsEnd
                    BEQ     Fn_UI_EndE1             * Error: length
                    CMP.B   #2,adrStsEnd
                    BEQ     Fn_UI_EndE2             * Error: hex value
                    BRA     Fn_UI_End_In            * No error: ask for input

Fn_UI_EndE1         LEA     msgStrAdr2Err1,A1       * 'Invalid ending address length'
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15
                    BRA     Fn_UI_End_In            * User input

Fn_UI_EndE2         LEA     msgStrAdr2Err2,A1       * 'Invalid ending address hexadecimal value'
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15
                    BRA     Fn_UI_End_In            * User input

Fn_UI_End_In        LEA     msgStrAdr2,A1           * 'Please enter a ending address'
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15                     * Display to screen

                    LEA     msgInTemp,A1            * Load placeholder for input string
                    MOVE.B  #2,D0                   * Trap task 2 does the following:
                    TRAP    #15                     * Read string to (A1), length in D1.W

                    BRA     Fn_UI_ChkLen            * Check addresses (length, hex validation)

Fn_UI_ChkLen        ** Check length
                    **   length should be 8 ascii characters
                    **   value stored in D1.W from input
                    ** ***************************************

                    CMP.W   #8,D1                   * Address should be 8 chars long
                    BNE     Fn_UI_SetELen           * Invalid address length
                    BRA     Fn_UI_ChkHex            * Length ok, now check hex values

Fn_UI_SetELen       ** Error: length
                    CMP.B #0,adrStsStart
                    BNE     Fn_UI_SetELenI1         * Error must be with first input
                    BRA     Fn_UI_SetELenI2         * Error must be with second input
Fn_UI_SetELenI1     ** Set error on input 1
                    MOVE.B  #1,adrStsStart          * Set error code 1 (invalid length)
                    BRA     Fn_UI_Loop
Fn_UI_SetELenI2     ** Set error on input 2         * Set error code 1 (invalid length)
                    MOVE.B  #1,adrStsEnd
                    BRA     Fn_UI_Loop

Fn_UI_ChkHex        ** Check hex values
                    **   30 - 39 (0-9)
                    **   41 - 46 (A-F), 61 - 66 (a - f)
                    ** ***************************************

                    MOVE.B  #0,D3                   * Loop counter
                    CLR.L   D6                      * Temporary address storage

Fn_UI_ChkHexLoop    ** Check hex values one at a time
                    MOVE.B  (A1)+,D4                * Unload byte and increment input

                    CMP.B   #$30,D4
                    BLT     Fn_UI_SetEHex           * Error - invalid hex character

                    CMP.B   #$39,D4
                    BLE     Fn_UI_ChkHexDone        * Loop around to check next value

                    CMP.B   #$41,D4
                    BLT     Fn_UI_SetEHex           * Error - invalid hex character

                    CMP.B   #$46,D4
                    BLE     Fn_UI_ChkHexDone        * Loop around to check next value

                    CMP.B   #$61,D4
                    BLT     Fn_UI_SetEHex           * Error - invalid hex character

                    CMP.B   #$66,D4
                    BLE     Fn_UI_ChkHexDone        * Loop around to check next value

                    BRA     Fn_UI_SetEHex           * Error - invalid hex character

Fn_UI_ChkHexDone    ** Check if at end of loop

                    ADDI.B  #1,D3                   * Increment loop counter

                    ** Insert ascii value into temp address
                    MOVE.B  D4,D5                   * Load current value into D5 for conversion
                    JSR     SR_ASCII_HEX            * Convert ascii to hex, return in D5
                    ADD.B   D5,D6                   * Insert hex value into temp storage
                    CMP.B   #8,D3                   * To shift or not to shift
                    BLT     Fn_UI_ChkHexASL         * Shift D6 left when loop < 8
                    BRA     Fn_UI_ChkHexRdr         * No shift to D6 when loop >= 8
Fn_UI_ChkHexASL     ASL.L   #4,D6                   * Left shift 4 to make room for next hex value

Fn_UI_ChkHexRdr     ** Check counter and redirect accordingly
                    CMP.B   #8,D3                   * Loop 8 times
                    BNE     Fn_UI_ChkHexLoop        * Back to Hex Loop
                    BRA     Fn_UI_SetVHex           * Set address as valid (done checking hex)

Fn_UI_SetVHex       ** Valid: hex values
                    CMP.B   #0,adrStsStart          * Value of 0 means it is a valid address
                    BNE     Fn_UI_SetVHexI1         * Error must be with first input
                    BRA     Fn_UI_SetVHexI2         * Error must be with second input

Fn_UI_SetVHexI1     ** Set valid on input 1
                    MOVE.B  #0,adrStsStart          * Set valid code 0 (address is valid)
                    MOVE.L  D6,adrValStart          * Copy input address to adrValEnd
                    LEA     adrValStart,A4
                    LEA     adrStrStart,A5
                    JSR     SR_HEX_STR              * Copy address value to string for display
                    BRA     Fn_UI_Loop              * Loop back to make sure both addresses set

Fn_UI_SetVHexI2     ** Set valid on input 2
                    MOVE.B  #0,adrStsEnd            * Set valid code 0 (address is valid)
                    MOVE.L  D6,adrValEnd            * Copy input address to adrValEnd
                    LEA     adrValEnd,A4
                    LEA     adrStrEnd,A5
                    JSR     SR_HEX_STR              * Copy address value to string for display
                    BRA     Fn_UI_Loop              * Loop back to make sure both addresses set

Fn_UI_SetEHex       ** Error: hex values
                    CMP.B   #0,adrStsStart
                    BNE     Fn_UI_SetEHexI1         * Error must be with first input
                    BRA     Fn_UI_SetEHexI2         * Error must be with second input

Fn_UI_SetEHexI1     ** Set error on input 1
                    MOVE.B  #2,adrStsStart          * Set error code 2 (invalid hex values)
                    BRA     Fn_UI_Loop              * Loop around to see if we are done

Fn_UI_SetEHexI2     ** Set error on input 2
                    MOVE.B  #2,adrStsEnd            * Set error code 2 (invalid hex values)
                    BRA     Fn_UI_Loop              * Loop around to see if we are done

Fn_UI_ChkVal        ** Check address range, order
                    **   Address automagic - will fix addresses if invalid input
                    ** Note: addresses are unsigned; should not be less than zero
                    ** Note: use BHI instead of BGT to compare unsigned addresses
                    ** Note: subtracting one from Start address if not even
                    **       doesn't really matter if end address is even or odd
                    ** ***************************************

                    MOVE.L  adrValStart,D5
                    MOVE.L  adrValEnd,D6

Fn_UI_ChkValSMax    CMP.L   #$00FFFFEC,D5            * Start should be <= (max - 1)
                    BHI     Fn_UI_ChkValSBig         * Start is > (max - 1); Set start to (max - 1)
                    BRA     Fn_UI_ChkValEMax         * Start is <= (max - 1); Check if End < 0

Fn_UI_ChkValSBig    MOVE.L  #$00FFFFEC,D5            * Set Start to (max - 1)

Fn_UI_ChkValEMax    CMP.L   #$00FFFFED,D6            * End should be <= max
                    BHI     Fn_UI_ChkValEBig         * End is > max; Set End to max
                    BRA     Fn_UI_ChkValCmp          * End is <= max; Check if Start > End

Fn_UI_ChkValEBig    MOVE.L  #$00FFFFED,D6            * Set End to max

Fn_UI_ChkValCmp     CMP.L   D6,D5                    * Start should be <= End
                    BHI     Fn_UI_ChkValSwp          * Start < End; Swap start and end
                    BRA     FN_UI_ChkValSWrd         * Start >= End; Check Start word boundry

Fn_UI_ChkValSwp     MOVE.L  D5,D4
                    MOVE.L  D6,D5
                    MOVE.L  D4,D6

FN_UI_ChkValSWrd    ** Check start for word boundry
                    MOVE.B  D5,D3                    * Move low order byte to D3 for division
                    MOVE.B  #2,D4                    * Setup even/odd comparison
                    DIVU.W  D4,D3                    * Divide unsigned D3/D4
                    SWAP    D3                       * Swap for remainder (the modulo part)
                    CMP.B   #0,D3                    * If zero, then even
                    BNE     Fn_UI_ChkValSOne         * Start is not even; Subtract one from address
                    BRA     Fn_UI_Done               * Start is even; finally, we're done

Fn_UI_ChkValSOne    SUBI.L  #1,D5

Fn_UI_Done          ** All done with input, time to go
                    ** ***************************************

                    MOVE.L  D5,adrValStart          * Move final address to Start
                    MOVE.L  D6,adrValEnd            * Move final address to End

                    ** Clear screen
                    MOVE.B  #11,D0                  * Trap task 2 does the following:
                    MOVE.W  #$FF00,D1               * Clear the screen
                    TRAP    #15

                    RTS

** -----------------------------------------------------------
** UI: Display Header
** -----------------------------------------------------------
SR_DSP_HEADER

                    ** Header line 03
                    LEA     msgLine,A1              * Loads MESSAGE into A1
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15                     * Display to screen

                    ** Header line 01
                    LEA     msgHdr01,A1             * Loads MESSAGE into A1
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15                     * Display to screen

                    ** Header line 02
                    LEA     msgHdr02a,A1            * Loads MESSAGE into A1
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15                     * Display to screen

                    LEA     adrStrStart,A1          * Loads MESSAGE into A1
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15                     * Display to screen

                    LEA     msgHdr02b,A1            * Loads MESSAGE into A1
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15

                    LEA     adrStrEnd,A1            * Loads MESSAGE into A1
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15                     * Display to screen

                    LEA     msgNewLine,A1           * Loads MESSAGE into A1
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15                     * Display to screen

                    ** Header line 03
                    LEA     msgLine,A1              * Loads MESSAGE into A1
                    MOVE.B  #14,D0                  * Use (A1) no CR/LF
                    TRAP    #15                     * Display to screen

                    RTS

** -----------------------------------------------------------
** UI: Display item
** -----------------------------------------------------------
SR_DSP_DISPLAY
                    ** Output buffer
                    **   Need buffer for spacing issues
                    **
                    LEA     opOutBuf,A3             * Reset pointer to output buffer
                    MOVE.B  #$00,(A3)               * Insert NULL

                    ** Push opValAdr to opStrAdr
                    LEA     opValAdr,A4               * input hex
                    MOVE.B  #2,D6                   * Set fix size to Word
                    JSR     SR_HEX_Fix              * Hex to ASCII input @A4 to buffer @A3

                    ** Instruction or DATA redirector
                    **
                    CMP.B   #1, opErr               * Check instruction type
                    BEQ     Fn_Dsp_DATA             * Error flag - must be DATA
                    CMP.B   #2, opErr               * Check instruction type
                    BEQ     Fn_Dsp_ErrI             * Error flag - must be Invalid EA Error
                    BRA     Fn_Dsp_Instr            * No error flag - must be instruction

Fn_Dsp_DATA         ** Process non supported instruction (DATA)
                    **

                    ** Space
                    LEA     opSpace,A4
                    JSR     SR_CPY_STR_BUF          * Copy string @A4 to output buffer @A3

                    ** Instruction name
                    LEA     opNam_DATA,A4
                    JSR     SR_CPY_STR_BUF          * Copy string @A4 to output buffer @A3

                    LEA     opSpace,A4
                    JSR     SR_CPY_STR_BUF          * Copy string @A4 to output buffer @A3

                    ** Instruction address
                    LEA     opWord,A4               * input hex
                    MOVE.B  #1,D6                   * Set fix size to Word
                    JSR     SR_HEX_Fix              * Hex to ASCII input @A4 to buffer @A3

                    BRA     Fn_Dsp_Done

Fn_Dsp_ErrI         ** Process invalid EA (ERRI)
                    **

                    ** Space
                    LEA     opSpace,A4
                    JSR     SR_CPY_STR_BUF          * Copy string @A4 to output buffer @A3

                    ** Instruction name
                    LEA     opNam_ERRI,A4
                    JSR     SR_CPY_STR_BUF          * Copy string @A4 to output buffer @A3

                    LEA     opSpace,A4
                    JSR     SR_CPY_STR_BUF          * Copy string @A4 to output buffer @A3

                    ** Instruction address
                    LEA     opWord,A4               * input hex
                    MOVE.B  #1,D6                   * Set fix size to Word
                    JSR     SR_HEX_Fix              * Hex to ASCII input @A4 to buffer @A3

                    BRA     Fn_Dsp_Done

Fn_Dsp_Instr        ** Process instruction
                    **

                    ** Space
                    LEA     opSpace,A4
                    JSR     SR_CPY_STR_BUF          * Copy string @A4 to output buffer @A3

                    ** Instruction name
                    MOVE.L  opPtrNam,A4
                    JSR     SR_CPY_STR_BUF          * Copy string @A4 to output buffer @A3

                    ** Instruciton size
                    **
                    CMP.B   #0,opValSiz
                    BEQ     Fn_DSP_SizB             * Size is Byte
                    CMP.B   #1,opValSiz
                    BEQ     Fn_DSP_SizW             * Size is Word
                    CMP.B   #2,opValSiz
                    BEQ     Fn_DSP_SizL             * Size is Long
                    BRA     Fn_DSP_OPR1             * Size not set

Fn_DSP_SizB         LEA     opSizB,A4               * '.B' string
                    JSR     SR_CPY_STR_BUF          * Copy string @A4 to output buffer @A3
                    BRA     Fn_DSP_OPR1

Fn_DSP_SizW         LEA     opSizW,A4               * '.W' string
                    JSR     SR_CPY_STR_BUF          * Copy string @A4 to output buffer @A3
                    BRA     Fn_DSP_OPR1

Fn_DSP_SizL         LEA     opSizL,A4              * '.L' string
                    JSR     SR_CPY_STR_BUF          * Copy string @A4 to output buffer @A3
                    BRA     Fn_DSP_OPR1

Fn_DSP_OPR1         ** Display First Operand
                    LEA     opTab,A4                * Tab (or calculated spaces)
                    JSR     SR_CPY_STR_BUF          * Copy string @A4 to output buffer @A3

Fn_DSP_SRC          ** Display Source
                    ** **************************************************

                    ** opSrcMsk overrides opSrcMod
                    **    if mask set - print mask
                    **    else        - print source
                    ** Note: mask has to be > 0 to be 'set'
                    ** Note: source will always have a comma at the end - so plan for that
                    **
                    CMP.W   #0,opSrcMsk
                    BHI.W   Fn_Dsp_SrcMsk         * Display the source mask
                    BRA     Fn_Dsp_SrcDta         * Display the source data

Fn_Dsp_SrcMsk       ** Display Source Mask (MOVEA)
                    ** --------------------------------------------------

                    CMP.B   #4,opSrcMskD            * Check mask type
                    BEQ.B   Fn_DspSrcMskPre         * predecrement -(An)
                    BRA     Fn_DspSrcMskPst         * postdecrement
Fn_DspSrcMskPst     MOVE.W  opSrcMsk,D5
                    JSR     SR_DSP_MSKPST
                    BRA     Fn_DSP_OPR2
Fn_DspSrcMskPre     MOVE.W  opSrcMsk,D5
                    JSR     SR_DSP_MSKPRE
                    BRA     Fn_DSP_OPR2

Fn_Dsp_SrcDta       ** Display Source Data
                    ** --------------------------------------------------

                    CMP.B   #$FF,opSrcMod          * Hide Source if Mode is $FF
                    BEQ     Fn_DSP_DST

                    CMP.B   #0,opSrcMod
                    BEQ     Fn_DSP_SRC_00          * Handle Reg Mode 0 Dn
                    CMP.B   #1,opSrcMod
                    BEQ     Fn_DSP_SRC_01          * Handle Reg Mode 1 An
                    CMP.B   #2,opSrcMod
                    BEQ     Fn_DSP_SRC_02          * Handle Reg Mode 2 (An)
                    CMP.B   #3,opSrcMod
                    BEQ     Fn_DSP_SRC_03          * Handle Reg Mode 3 (An)+
                    CMP.B   #4,opSrcMod
                    BEQ     Fn_DSP_SRC_04          * Handle Reg Mode 4 -(An)
                    CMP.B   #7,opSrcMod
                    BEQ     Fn_DSP_SRC_07          * Handle Reg Mode 7 (xxx).W, (xxx).L, #<data>

                    BRA     Fn_DSP_SRCMOD_ERR      * Mode not 1 to 7 - display error

Fn_DSP_SRC_00       ** Handling data mode 0
                    MOVE.B  #$44,(A3)+              * Insert 'D' character
                    MOVE.B  opSrcReg,D3             * Move Register value to D3 for ASCII conversion
                    ADDI.B  #$30,D3                 * Add 30 to convert number to ASCII
                    MOVE.B  D3,(A3)+                * Insert Register value
                    BRA     Fn_DSP_OPR2             * Display data 2

Fn_DSP_SRC_01       ** Handling data mode 1
                    MOVE.B  #$41,(A3)+              * Insert 'A' character
                    MOVE.B  opSrcReg,D3             * Move Register value to D3 for ASCII conversion
                    ADDI.B  #$30,D3                 * Add 30 to convert number to ASCII
                    MOVE.B  D3,(A3)+                * Insert Register value
                    BRA     Fn_DSP_OPR2             * Display data 2

Fn_DSP_SRC_02       ** Handling data mode 2
                    MOVE.B  #$28,(A3)+              * Insert '(' character
                    MOVE.B  #$41,(A3)+              * Insert 'A' character
                    MOVE.B  opSrcReg,D3             * Move Register value to D3 for ASCII conversion
                    ADDI.B  #$30,D3                 * Add 30 to convert number to ASCII
                    MOVE.B  D3,(A3)+                * Insert Register value
                    MOVE.B  #$29,(A3)+              * Insert ')' character
                    BRA     Fn_DSP_OPR2             * Display data 2

Fn_DSP_SRC_03       ** Handling data mode 3
                    MOVE.B  #$28,(A3)+              * Insert '(' character
                    MOVE.B  #$41,(A3)+              * Insert 'A' character
                    MOVE.B  opSrcReg,D3             * Move Register value to D3 for ASCII conversion
                    ADDI.B  #$30,D3                 * Add 30 to convert number to ASCII
                    MOVE.B  D3,(A3)+                * Insert Register value
                    MOVE.B  #$29,(A3)+              * Insert ')' character
                    MOVE.B  #$2B,(A3)+              * Insert '+' character
                    BRA     Fn_DSP_OPR2             * Display data 2

Fn_DSP_SRC_04       ** Handling data mode 4
                    MOVE.B  #$2D,(A3)+              * Insert '-' character
                    MOVE.B  #$28,(A3)+              * Insert '(' character
                    MOVE.B  #$41,(A3)+              * Insert 'A' character
                    MOVE.B  opSrcReg,D3             * Move Register value to D3 for ASCII conversion
                    ADDI.B  #$30,D3                 * Add 30 to convert number to ASCII
                    MOVE.B  D3,(A3)+                * Insert Register value
                    MOVE.B  #$29,(A3)+              * Insert ')' character
                    BRA     Fn_DSP_OPR2             * Display data 2

Fn_DSP_SRC_07       ** Handling data mode 7
                    CMP.B   #0,opDta1T
                    BEQ     Fn_DSP_SRC_BYT         * Display data as byte
                    CMP.B   #1,opDta1T
                    BEQ     Fn_DSP_SRC_WRD         * Display data as word
                    CMP.B   #2,opDta1T
                    BEQ     Fn_DSP_SRC_LNG         * Display data as long
                    CMP.B   #3,opDta1T
                    BEQ     Fn_DSP_SRC_IMD         * Display data as immediate

                    BRA     Fn_DSP_SRCDTT_ERR      * Data type not 0 to 2 - display error

Fn_DSP_SRC_BYT      ** Display data Byte (it's really a word with 00 tacked on)
                    MOVE.B  #$24,(A3)+              * Insert '$' character
                    *MOVE.B  #$42,(A3)+              * Insert 'B' character (debug)
                    LEA     opDta1,A4               * input hex
                    JSR     SR_HEX_VAR              * Hex to ASCII input @A4 to buffer @A3
                    BRA     Fn_DSP_OPR2             * Display operand 2

Fn_DSP_SRC_WRD      ** Display data Word
                    MOVE.B  #$24,(A3)+              * Insert '$' character
                    *MOVE.B  #$57,(A3)+              * Insert 'W' character (debug)
                    LEA     opDta1,A4               * input hex
                    JSR     SR_HEX_VAR              * Hex to ASCII input @A4 to buffer @A3
                    BRA     Fn_DSP_OPR2             * Display operand 2

Fn_DSP_SRC_LNG      ** Display data Long
                    MOVE.B  #$24,(A3)+              * Insert '$' character
                    *MOVE.B  #$4C,(A3)+              * Insert 'L' character (debug)
                    LEA     opDta1,A4               * input hex
                    JSR     SR_HEX_VAR              * Hex to ASCII input @A4 to buffer @A3
                    BRA     Fn_DSP_OPR2             * Display operand 2

Fn_DSP_SRC_IMD      ** Display data immediate
                    MOVE.L  opDta1,D3
                    JSR     SR_HEX_NUM              * convert hex long @ D3 and push to buffer @ A3
                    BRA     Fn_DSP_OPR2             * Display operand 2

Fn_DSP_SRC_ERR      ** Something is messed up
                    LEA     msgErr,A4
                    JSR     SR_CPY_STR_BUF          * Copy string @A4 to output buffer @A3
                    BRA     Fn_DSP_OPR2             * Display data 2

Fn_DSP_SRCMOD_ERR   ** Something is messed up opSrcMod invalid
                    LEA     msgErrSrcMod,A4
                    JSR     SR_CPY_STR_BUF          * Copy string @A4 to output buffer @A3
                    BRA     Fn_DSP_OPR2             * Display data 2

Fn_DSP_SRCDTT_ERR   ** Something is messed up opSrc1T invalid
                    LEA     msgErrSrcDtT,A4
                    JSR     SR_CPY_STR_BUF          * Copy string @A4 to output buffer @A3
                    BRA     Fn_DSP_OPR2             * Display data 2

                    ** ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Fn_DSP_OPR2              ** Comma displays if there is source data or source mask
                    LEA     opComma,A4              * Comma
                    JSR     SR_CPY_STR_BUF          * Copy string @A4 to output buffer @A3

Fn_DSP_DST          ** Display Destination
                    ** **************************************************

                    ** opDstMsk overrides opDstMod
                    **    if mask set - print mask
                    **    else        - print destination
                    ** Note: mask has to be > 0 to be 'set'
                    **
                    CMP.W   #0,opDstMsk
                    BHI.W   Fn_Dsp_DstMsk         * Display the source mask
                    BRA     Fn_Dsp_DstDta         * Display the source data

Fn_Dsp_DstMsk       ** Display Source Mask (MOVEA)
                    ** --------------------------------------------------
                    MOVE.W  opDstMsk,D5
                    JSR     SR_DSP_MSKPST
                    BRA     Fn_DSP_DONE             * Done with mask

Fn_Dsp_DstDta       ** Display Destination Data
                    ** --------------------------------------------------

                    CMP.B   #$FF,opDstMod          * Hide Destination if Mode is $FF
                    BEQ     Fn_DSP_DONE

                    CMP.B   #0,opDstMod
                    BEQ     Fn_DSP_DST_00          * Handle Reg mode 0 (Dn)
                    CMP.B   #1,opDstMod
                    BEQ     Fn_DSP_DST_01          * Handle Reg Mode 1 An
                    CMP.B   #2,opDstMod
                    BEQ     Fn_DSP_DST_02          * Handle Reg Mode 2 (An)
                    CMP.B   #3,opDstMod
                    BEQ     Fn_DSP_DST_03          * Handle Reg Mode 3 (An)+
                    CMP.B   #4,opDstMod
                    BEQ     Fn_DSP_DST_04          * Handle Reg Mode 4 -(An)
                    CMP.B   #7,opDstMod
                    BEQ     Fn_DSP_DST_07          * Handle Reg Mode 7 (xxx).W, (xxx).L, #<data>

                    BRA     Fn_DSP_DSTMOD_ERR      * Mode not 1 to 7 - display error

Fn_DSP_DST_00       ** Handling mode 0
                    MOVE.B  #$44,(A3)+              * Insert 'D' character
                    MOVE.B  opDstReg,D3             * Move Register value to D3 for ASCII conversion
                    ADDI.B  #$30,D3                 * Add 30 to convert number to ASCII
                    MOVE.B  D3,(A3)+                * Insert Register value
                    BRA     Fn_DSP_DONE             * Done with display

Fn_DSP_DST_01       ** Handling mode 1
                    MOVE.B  #$41,(A3)+              * Insert 'A' character
                    MOVE.B  opDstReg,D3             * Move Register value to D3 for ASCII conversion
                    ADDI.B  #$30,D3                 * Add 30 to convert number to ASCII
                    MOVE.B  D3,(A3)+                * Insert Register value
                    BRA     Fn_DSP_DONE             * Done with display

Fn_DSP_DST_02       ** Handling mode 2
                    MOVE.B  #$28,(A3)+              * Insert '(' character
                    MOVE.B  #$41,(A3)+              * Insert 'A' character
                    MOVE.B  opDSTReg,D3             * Move Register value to D3 for ASCII conversion
                    ADDI.B  #$30,D3                 * Add 30 to convert number to ASCII
                    MOVE.B  D3,(A3)+                * Insert Register value
                    MOVE.B  #$29,(A3)+              * Insert ')' character
                    BRA     Fn_DSP_DONE             * Done with display

Fn_DSP_DST_03       ** Handling mode 3
                    MOVE.B  #$28,(A3)+              * Insert '(' character
                    MOVE.B  #$41,(A3)+              * Insert 'A' character
                    MOVE.B  opDstReg,D3             * Move Register value to D3 for ASCII conversion
                    ADDI.B  #$30,D3                 * Add 30 to convert number to ASCII
                    MOVE.B  D3,(A3)+                * Insert Register value
                    MOVE.B  #$29,(A3)+              * Insert ')' character
                    MOVE.B  #$2B,(A3)+              * Insert '+' character
                    BRA     Fn_DSP_DONE             * Done with display

Fn_DSP_DST_04       ** Handling mode 4
                    MOVE.B  #$2D,(A3)+              * Insert '-' character
                    MOVE.B  #$28,(A3)+              * Insert '(' character
                    MOVE.B  #$41,(A3)+              * Insert 'A' character
                    MOVE.B  opDstReg,D3             * Move Register value to D3 for ASCII conversion
                    ADDI.B  #$30,D3                 * Add 30 to convert number to ASCII
                    MOVE.B  D3,(A3)+                * Insert Register value
                    MOVE.B  #$29,(A3)+              * Insert ')' character
                    BRA     Fn_DSP_DONE             * Done with display

Fn_DSP_DST_07       ** Handling mode 8
                    CMP.B   #0,opDta2T
                    BEQ     Fn_DSP_DST_BYT         * Display data as byte
                    CMP.B   #1,opDta2T
                    BEQ     Fn_DSP_DST_WRD         * Display data as word
                    CMP.B   #2,opDta2T
                    BEQ     Fn_DSP_DST_LNG         * Display data as long
                    CMP.B   #3,opDta2T
                    BEQ     Fn_DSP_DST_IMD         * Display data as immediate

                    BRA     Fn_DSP_DSTMOD_ERR      * Data type not 0 to 2 - display error

Fn_DSP_DST_BYT      ** Display data Byte (it's really a word with 00 tacked on)
                    MOVE.B  #$24,(A3)+              * Insert '$' character
                    *MOVE.B  #$42,(A3)+              * Insert 'B' character (debug)
                    LEA     opDta2,A4               * input hex
                    JSR     SR_HEX_VAR              * Hex to ASCII input @A4 to buffer @A3
                    BRA     Fn_DSP_DONE             * Display data 2

Fn_DSP_DST_WRD      ** Display data Word
                    MOVE.B  #$24,(A3)+              * Insert '$' character
                    *MOVE.B  #$57,(A3)+              * Insert 'W' character (debug)
                    LEA     opDta2,A4               * input hex
                    JSR     SR_HEX_VAR              * Hex to ASCII input @A4 to buffer @A3
                    BRA     Fn_DSP_DONE             * Display data 2

Fn_DSP_DST_LNG      ** Display data Long
                    MOVE.B  #$24,(A3)+              * Insert '$' character
                    *MOVE.B  #$4C,(A3)+              * Insert 'L' character (debug)
                    LEA     opDta2,A4               * input hex
                    JSR     SR_HEX_VAR              * Hex to ASCII input @A4 to buffer @A3
                    BRA     Fn_DSP_DONE             * Display data 2

Fn_DSP_DST_IMD      ** Display data immediate
                    MOVE.L  opDta2,D3
                    JSR     SR_HEX_NUM              * convert hex long @ D3 and push to buffer @ A3
                    BRA     Fn_DSP_DONE             * Display data 2

Fn_DSP_DST_ERR      ** Something is messed up
                    LEA     msgErr,A4
                    JSR     SR_CPY_STR_BUF          * Copy string @A4 to output buffer @A3
                    BRA     Fn_DSP_DONE             * Display data 2

Fn_DSP_DSTMOD_ERR   ** Something is messed up opDstMod invalid
                    LEA     msgErrDstMod,A4
                    JSR     SR_CPY_STR_BUF          * Copy string @A4 to output buffer @A3
                    BRA     Fn_DSP_DONE             * Display data 2

Fn_DSP_DSTDTT_ERR   ** Something is messed up opDta2T invalid
                    LEA     msgErrDstDtT,A4
                    JSR     SR_CPY_STR_BUF          * Copy string @A4 to output buffer @A3
                    BRA     Fn_DSP_DONE             * Display data 2

                    ** ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Fn_Dsp_Done         ** Done with instruction display
                    MOVE.B  #$00,(A3)               * Insert NULL to end string
                    LEA     opOutBuf,A1             * Loads MESSAGE into A1
                    MOVE.B  #13,D0                  * Use (A1) with CR/LF
                    TRAP    #15

                    ** We're all done here - time to go
                    **
                    RTS                             * Return back to caller

** -----------------------------------------------------------
** SUBROUTINE: Display Mask "Post Decrement" D0-D7, A0-A7
**
** Parameters
**   D5 - the mask to decode
** -----------------------------------------------------------
SR_DSP_MSKPST
                    ** (DEBUG) Print 'PST:'
                    *MOVE.B  #$50,(A3)+
                    *MOVE.B  #$53,(A3)+
                    *MOVE.B  #$54,(A3)+
                    *MOVE.B  #$3A,(A3)+

Fn_Dsp_MskPstSD0    MOVE.W  D5,D3                           * 16 bit mask
                    MOVE.B  #15,D4
                    LSL.W   D4,D3
                    MOVE.B  #15,D4
                    LSR.W   D4,D3
                    CMP.B   #1,D3
                    BEQ     Fn_Dsp_MskPstWD0
                    BRA     Fn_Dsp_MskPstSD1

Fn_Dsp_MskPstWD0    MOVE.B  #$44,(A3)+               * Insert 'D' character
                    MOVE.B  #$30,(A3)+               * Insert '0' character
                    MOVE.B  #$2F,(A3)+               * Insert '/' character

Fn_Dsp_MskPstSD1    MOVE.W  D5,D3                          * 16 bit mask
                    MOVE.B  #14,D4
                    LSL.W   D4,D3
                    MOVE.B  #15,D4
                    LSR.W   D4,D3
                    CMP.B   #1,D3
                    BEQ     Fn_Dsp_MskPstWD1
                    BRA     Fn_Dsp_MskPstSD2

Fn_Dsp_MskPstWD1    MOVE.B  #$44,(A3)+               * Insert 'D' character
                    MOVE.B  #$31,(A3)+               * Insert '1' character
                    MOVE.B  #$2F,(A3)+               * Insert '/' character

Fn_Dsp_MskPstSD2    MOVE.W  D5,D3                          * 16 bit mask
                    MOVE.B  #13,D4
                    LSL.W   D4,D3
                    MOVE.B  #15,D4
                    LSR.W   D4,D3
                    CMP.B   #1,D3
                    BEQ     Fn_Dsp_MskPstWD2
                    BRA     Fn_Dsp_MskPstSD3

Fn_Dsp_MskPstWD2    MOVE.B  #$44,(A3)+               * Insert 'D' character
                    MOVE.B  #$32,(A3)+               * Insert '2' character
                    MOVE.B  #$2F,(A3)+              * Insert '/' character

Fn_Dsp_MskPstSD3    MOVE.W  D5,D3                          * 16 bit mask
                    MOVE.B  #12,D4
                    LSL.W   D4,D3
                    MOVE.B  #15,D4
                    LSR.W   D4,D3
                    CMP.B   #1,D3
                    BEQ     Fn_Dsp_MskPstWD3
                    BRA     Fn_Dsp_MskPstSD4

Fn_Dsp_MskPstWD3    MOVE.B  #$44,(A3)+              * Insert 'D' character
                    MOVE.B  #$33,(A3)+              * Insert '3' character
                    MOVE.B  #$2F,(A3)+              * Insert '/' character

Fn_Dsp_MskPstSD4    MOVE.W  D5,D3                          * 16 bit mask
                    MOVE.B  #11,D4
                    LSL.W   D4,D3
                    MOVE.B  #15,D4
                    LSR.W   D4,D3
                    CMP.B   #1,D3
                    BEQ     Fn_Dsp_MskPstWD4
                    BRA     Fn_Dsp_MskPstSD5

Fn_Dsp_MskPstWD4    MOVE.B  #$44,(A3)+              * Insert 'D' character
                    MOVE.B  #$34,(A3)+              * Insert '4' character
                    MOVE.B  #$2F,(A3)+              * Insert '/' character

Fn_Dsp_MskPstSD5    MOVE.W  D5,D3                          * 16 bit mask
                    MOVE.B  #10,D4
                    LSL.W   D4,D3
                    MOVE.B  #15,D4
                    LSR.W   D4,D3
                    CMP.B   #1,D3
                    BEQ     Fn_Dsp_MskPstWD5
                    BRA     Fn_Dsp_MskPstSD6

Fn_Dsp_MskPstWD5    MOVE.B  #$44,(A3)+              * Insert 'D' character
                    MOVE.B  #$35,(A3)+              * Insert '5' character
                    MOVE.B  #$2F,(A3)+              * Insert '/' character

Fn_Dsp_MskPstSD6    MOVE.W  D5,D3                          * 16 bit mask
                    MOVE.B  #9,D4
                    LSL.W   D4,D3
                    MOVE.B  #15,D4
                    LSR.W   D4,D3
                    CMP.B   #1,D3
                    BEQ     Fn_Dsp_MskPstWD6
                    BRA     Fn_Dsp_MskPstSD7

Fn_Dsp_MskPstWD6    MOVE.B  #$44,(A3)+              * Insert 'D' character
                    MOVE.B  #$36,(A3)+              * Insert '6' character
                    MOVE.B  #$2F,(A3)+              * Insert '/' character

Fn_Dsp_MskPstSD7    MOVE.W  D5,D3                          * 16 bit mask
                    MOVE.B  #8,D4
                    LSL.W   D4,D3
                    MOVE.B  #15,D4
                    LSR.W   D4,D3
                    CMP.B   #1,D3
                    BEQ     Fn_Dsp_MskPstWD7
                    BRA     Fn_Dsp_MskPstSA0

Fn_Dsp_MskPstWD7    MOVE.B  #$44,(A3)+              * Insert 'D' character
                    MOVE.B  #$37,(A3)+              * Insert '7' character
                    MOVE.B  #$2F,(A3)+              * Insert '/' character

Fn_Dsp_MskPstSA0    MOVE.W  D5,D3                           * 16 bit mask
                    MOVE.B  #7,D4
                    LSL.W   D4,D3
                    MOVE.B  #15,D4
                    LSR.W   D4,D3
                    CMP.B   #1,D3
                    BEQ     Fn_Dsp_MskPstWA0
                    BRA     Fn_Dsp_MskPstSA1

Fn_Dsp_MskPstWA0    MOVE.B  #$41,(A3)+               * Insert 'A' character
                    MOVE.B  #$30,(A3)+               * Insert '0' character
                    MOVE.B  #$2F,(A3)+               * Insert '/' character

Fn_Dsp_MskPstSA1    MOVE.W  D5,D3                          * 16 bit mask
                    MOVE.B  #6,D4
                    LSL.W   D4,D3
                    MOVE.B  #15,D4
                    LSR.W   D4,D3
                    CMP.B   #1,D3
                    BEQ     Fn_Dsp_MskPstWA1
                    BRA     Fn_Dsp_MskPstSA2

Fn_Dsp_MskPstWA1    MOVE.B  #$41,(A3)+               * Insert 'A' character
                    MOVE.B  #$31,(A3)+               * Insert '1' character
                    MOVE.B  #$2F,(A3)+               * Insert '/' character

Fn_Dsp_MskPstSA2    MOVE.W  D5,D3                          * 16 bit mask
                    MOVE.B  #5,D4
                    LSL.W   D4,D3
                    MOVE.B  #15,D4
                    LSR.W   D4,D3
                    CMP.B   #1,D3
                    BEQ     Fn_Dsp_MskPstWA2
                    BRA     Fn_Dsp_MskPstSA3

Fn_Dsp_MskPstWA2    MOVE.B  #$41,(A3)+               * Insert 'A' character
                    MOVE.B  #$32,(A3)+               * Insert '2' character
                    MOVE.B  #$2F,(A3)+               * Insert '/' character

Fn_Dsp_MskPstSA3    MOVE.W  D5,D3                          * 16 bit mask
                    MOVE.B  #4,D4
                    LSL.W   D4,D3
                    MOVE.B  #15,D4
                    LSR.W   D4,D3
                    CMP.B   #1,D3
                    BEQ     Fn_Dsp_MskPstWA3
                    BRA     Fn_Dsp_MskPstSA4

Fn_Dsp_MskPstWA3    MOVE.B  #$41,(A3)+              * Insert 'A' character
                    MOVE.B  #$33,(A3)+              * Insert '3' character
                    MOVE.B  #$2F,(A3)+              * Insert '/' character

Fn_Dsp_MskPstSA4    MOVE.W  D5,D3                          * 16 bit mask
                    MOVE.B  #3,D4
                    LSL.W   D4,D3
                    MOVE.B  #15,D4
                    LSR.W   D4,D3
                    CMP.B   #1,D3
                    BEQ     Fn_Dsp_MskPstWA4
                    BRA     Fn_Dsp_MskPstSA5

Fn_Dsp_MskPstWA4    MOVE.B  #$41,(A3)+              * Insert 'A' character
                    MOVE.B  #$34,(A3)+              * Insert '4' character
                    MOVE.B  #$2F,(A3)+              * Insert '/' character

Fn_Dsp_MskPstSA5    MOVE.W  D5,D3                          * 16 bit mask
                    MOVE.B  #2,D4
                    LSL.W   D4,D3
                    MOVE.B  #15,D4
                    LSR.W   D4,D3
                    CMP.B   #1,D3
                    BEQ     Fn_Dsp_MskPstWA5
                    BRA     Fn_Dsp_MskPstSA6

Fn_Dsp_MskPstWA5    MOVE.B  #$41,(A3)+              * Insert 'A' character
                    MOVE.B  #$35,(A3)+              * Insert '5' character
                    MOVE.B  #$2F,(A3)+              * Insert '/' character

Fn_Dsp_MskPstSA6    MOVE.W  D5,D3                          * 16 bit mask
                    MOVE.B  #1,D4
                    LSL.W   D4,D3
                    MOVE.B  #15,D4
                    LSR.W   D4,D3
                    CMP.B   #1,D3
                    BEQ     Fn_Dsp_MskPstWA6
                    BRA     Fn_Dsp_MskPstSA7

Fn_Dsp_MskPstWA6    MOVE.B  #$41,(A3)+              * Insert 'A' character
                    MOVE.B  #$36,(A3)+              * Insert '6' character
                    MOVE.B  #$2F,(A3)+              * Insert '/' character

Fn_Dsp_MskPstSA7    MOVE.W  D5,D3                          * 16 bit mask
                    MOVE.B  #0,D4
                    LSL.W   D4,D3
                    MOVE.B  #15,D4
                    LSR.W   D4,D3
                    CMP.B   #1,D3
                    BEQ     Fn_Dsp_MskPstWA7
                    BRA     Fn_Dsp_MskPstDone

Fn_Dsp_MskPstWA7    MOVE.B  #$41,(A3)+              * Insert 'A' character
                    MOVE.B  #$37,(A3)+              * Insert '7' character
                    MOVE.B  #$2F,(A3)+              * Insert '/' character

Fn_Dsp_MskPstDone   RTS

** -----------------------------------------------------------
** SUBROUTINE: Display Mask "Pre Decrement" A7-A0, D7-D0
**
** Parameters
**   D5 - the mask to decode
**
** Note: A very specific requirment to display in reverse
**       predecrement when DstMod or SrcMod = 4 -> -(An)
** -----------------------------------------------------------
SR_DSP_MSKPRE
                    ** (DEBUG) Print 'PRE:'
                    *MOVE.B  #$50,(A3)+
                    *MOVE.B  #$52,(A3)+
                    *MOVE.B  #$45,(A3)+
                    *MOVE.B  #$3A,(A3)+

Fn_Dsp_MskPreSD0    MOVE.W  D5,D3                           * 16 bit mask
                    MOVE.B  #0,D4
                    LSL.W   D4,D3
                    MOVE.B  #15,D4
                    LSR.W   D4,D3
                    CMP.B   #1,D3
                    BEQ     Fn_Dsp_MskPreWD0
                    BRA     Fn_Dsp_MskPreSD1

Fn_Dsp_MskPreWD0    MOVE.B  #$44,(A3)+               * Insert 'D' character
                    MOVE.B  #$30,(A3)+               * Insert '0' character
                    MOVE.B  #$2F,(A3)+               * Insert '/' character

Fn_Dsp_MskPreSD1    MOVE.W  D5,D3                          * 16 bit mask
                    MOVE.B  #1,D4
                    LSL.W   D4,D3
                    MOVE.B  #15,D4
                    LSR.W   D4,D3
                    CMP.B   #1,D3
                    BEQ     Fn_Dsp_MskPreWD1
                    BRA     Fn_Dsp_MskPreSD2

Fn_Dsp_MskPreWD1    MOVE.B  #$44,(A3)+               * Insert 'D' character
                    MOVE.B  #$31,(A3)+               * Insert '1' character
                    MOVE.B  #$2F,(A3)+               * Insert '/' character

Fn_Dsp_MskPreSD2    MOVE.W  D5,D3                          * 16 bit mask
                    MOVE.B  #2,D4
                    LSL.W   D4,D3
                    MOVE.B  #15,D4
                    LSR.W   D4,D3
                    CMP.B   #1,D3
                    BEQ     Fn_Dsp_MskPreWD2
                    BRA     Fn_Dsp_MskPreSD3

Fn_Dsp_MskPreWD2    MOVE.B  #$44,(A3)+               * Insert 'D' character
                    MOVE.B  #$32,(A3)+               * Insert '2' character
                    MOVE.B  #$2F,(A3)+              * Insert '/' character

Fn_Dsp_MskPreSD3    MOVE.W  D5,D3                          * 16 bit mask
                    MOVE.B  #3,D4
                    LSL.W   D4,D3
                    MOVE.B  #15,D4
                    LSR.W   D4,D3
                    CMP.B   #1,D3
                    BEQ     Fn_Dsp_MskPreWD3
                    BRA     Fn_Dsp_MskPreSD4

Fn_Dsp_MskPreWD3    MOVE.B  #$44,(A3)+              * Insert 'D' character
                    MOVE.B  #$33,(A3)+              * Insert '3' character
                    MOVE.B  #$2F,(A3)+              * Insert '/' character

Fn_Dsp_MskPreSD4    MOVE.W  D5,D3                          * 16 bit mask
                    MOVE.B  #4,D4
                    LSL.W   D4,D3
                    MOVE.B  #15,D4
                    LSR.W   D4,D3
                    CMP.B   #1,D3
                    BEQ     Fn_Dsp_MskPreWD4
                    BRA     Fn_Dsp_MskPreSD5

Fn_Dsp_MskPreWD4    MOVE.B  #$44,(A3)+              * Insert 'D' character
                    MOVE.B  #$34,(A3)+              * Insert '4' character
                    MOVE.B  #$2F,(A3)+              * Insert '/' character

Fn_Dsp_MskPreSD5    MOVE.W  D5,D3                          * 16 bit mask
                    MOVE.B  #5,D4
                    LSL.W   D4,D3
                    MOVE.B  #15,D4
                    LSR.W   D4,D3
                    CMP.B   #1,D3
                    BEQ     Fn_Dsp_MskPreWD5
                    BRA     Fn_Dsp_MskPreSD6

Fn_Dsp_MskPreWD5    MOVE.B  #$44,(A3)+              * Insert 'D' character
                    MOVE.B  #$35,(A3)+              * Insert '5' character
                    MOVE.B  #$2F,(A3)+              * Insert '/' character

Fn_Dsp_MskPreSD6    MOVE.W  D5,D3                          * 16 bit mask
                    MOVE.B  #6,D4
                    LSL.W   D4,D3
                    MOVE.B  #15,D4
                    LSR.W   D4,D3
                    CMP.B   #1,D3
                    BEQ     Fn_Dsp_MskPreWD6
                    BRA     Fn_Dsp_MskPreSD7

Fn_Dsp_MskPreWD6    MOVE.B  #$44,(A3)+              * Insert 'D' character
                    MOVE.B  #$36,(A3)+              * Insert '6' character
                    MOVE.B  #$2F,(A3)+              * Insert '/' character

Fn_Dsp_MskPreSD7    MOVE.W  D5,D3                          * 16 bit mask
                    MOVE.B  #7,D4
                    LSL.W   D4,D3
                    MOVE.B  #15,D4
                    LSR.W   D4,D3
                    CMP.B   #1,D3
                    BEQ     Fn_Dsp_MskPreWD7
                    BRA     Fn_Dsp_MskPreSA0

Fn_Dsp_MskPreWD7    MOVE.B  #$44,(A3)+              * Insert 'D' character
                    MOVE.B  #$37,(A3)+              * Insert '7' character
                    MOVE.B  #$2F,(A3)+              * Insert '/' character

Fn_Dsp_MskPreSA0    MOVE.W  D5,D3                           * 16 bit mask
                    MOVE.B  #8,D4
                    LSL.W   D4,D3
                    MOVE.B  #15,D4
                    LSR.W   D4,D3
                    CMP.B   #1,D3
                    BEQ     Fn_Dsp_MskPreWA0
                    BRA     Fn_Dsp_MskPreSA1

Fn_Dsp_MskPreWA0    MOVE.B  #$41,(A3)+               * Insert 'A' character
                    MOVE.B  #$30,(A3)+               * Insert '0' character
                    MOVE.B  #$2F,(A3)+               * Insert '/' character

Fn_Dsp_MskPreSA1    MOVE.W  D5,D3                          * 16 bit mask
                    MOVE.B  #9,D4
                    LSL.W   D4,D3
                    MOVE.B  #15,D4
                    LSR.W   D4,D3
                    CMP.B   #1,D3
                    BEQ     Fn_Dsp_MskPreWA1
                    BRA     Fn_Dsp_MskPreSA2

Fn_Dsp_MskPreWA1    MOVE.B  #$41,(A3)+               * Insert 'A' character
                    MOVE.B  #$31,(A3)+               * Insert '1' character
                    MOVE.B  #$2F,(A3)+               * Insert '/' character

Fn_Dsp_MskPreSA2    MOVE.W  D5,D3                          * 16 bit mask
                    MOVE.B  #10,D4
                    LSL.W   D4,D3
                    MOVE.B  #15,D4
                    LSR.W   D4,D3
                    CMP.B   #1,D3
                    BEQ     Fn_Dsp_MskPreWA2
                    BRA     Fn_Dsp_MskPreSA3

Fn_Dsp_MskPreWA2    MOVE.B  #$41,(A3)+               * Insert 'A' character
                    MOVE.B  #$32,(A3)+               * Insert '2' character
                    MOVE.B  #$2F,(A3)+               * Insert '/' character

Fn_Dsp_MskPreSA3    MOVE.W  D5,D3                          * 16 bit mask
                    MOVE.B  #11,D4
                    LSL.W   D4,D3
                    MOVE.B  #15,D4
                    LSR.W   D4,D3
                    CMP.B   #1,D3
                    BEQ     Fn_Dsp_MskPreWA3
                    BRA     Fn_Dsp_MskPreSA4

Fn_Dsp_MskPreWA3    MOVE.B  #$41,(A3)+              * Insert 'A' character
                    MOVE.B  #$33,(A3)+              * Insert '3' character
                    MOVE.B  #$2F,(A3)+              * Insert '/' character

Fn_Dsp_MskPreSA4    MOVE.W  D5,D3                          * 16 bit mask
                    MOVE.B  #12,D4
                    LSL.W   D4,D3
                    MOVE.B  #15,D4
                    LSR.W   D4,D3
                    CMP.B   #1,D3
                    BEQ     Fn_Dsp_MskPreWA4
                    BRA     Fn_Dsp_MskPreSA5

Fn_Dsp_MskPreWA4    MOVE.B  #$41,(A3)+              * Insert 'A' character
                    MOVE.B  #$34,(A3)+              * Insert '4' character
                    MOVE.B  #$2F,(A3)+              * Insert '/' character

Fn_Dsp_MskPreSA5    MOVE.W  D5,D3                          * 16 bit mask
                    MOVE.B  #13,D4
                    LSL.W   D4,D3
                    MOVE.B  #15,D4
                    LSR.W   D4,D3
                    CMP.B   #1,D3
                    BEQ     Fn_Dsp_MskPreWA5
                    BRA     Fn_Dsp_MskPreSA6

Fn_Dsp_MskPreWA5    MOVE.B  #$41,(A3)+              * Insert 'A' character
                    MOVE.B  #$35,(A3)+              * Insert '5' character
                    MOVE.B  #$2F,(A3)+              * Insert '/' character

Fn_Dsp_MskPreSA6    MOVE.W  D5,D3                          * 16 bit mask
                    MOVE.B  #14,D4
                    LSL.W   D4,D3
                    MOVE.B  #15,D4
                    LSR.W   D4,D3
                    CMP.B   #1,D3
                    BEQ     Fn_Dsp_MskPreWA6
                    BRA     Fn_Dsp_MskPreSA7

Fn_Dsp_MskPreWA6    MOVE.B  #$41,(A3)+              * Insert 'A' character
                    MOVE.B  #$36,(A3)+              * Insert '6' character
                    MOVE.B  #$2F,(A3)+              * Insert '/' character

Fn_Dsp_MskPreSA7    MOVE.W  D5,D3                          * 16 bit mask
                    MOVE.B  #15,D4
                    LSL.W   D4,D3
                    MOVE.B  #15,D4
                    LSR.W   D4,D3
                    CMP.B   #1,D3
                    BEQ     Fn_Dsp_MskPreWA7
                    BRA     Fn_Dsp_MskPreDone

Fn_Dsp_MskPreWA7    MOVE.B  #$41,(A3)+              * Insert 'A' character
                    MOVE.B  #$37,(A3)+              * Insert '7' character
                    MOVE.B  #$2F,(A3)+              * Insert '/' character

Fn_Dsp_MskPreDone   RTS

** -----------------------------------------------------------
** Convert single ASCII value to hexadecimal
**    ASCII values should be in range 0-9, A-F
**
** Parameters
**   D5 - Hex value to assess. Converted value returned in D5
**
** Example:
**   $30 -> $0
**   $41 -> $A
**   $61 -> $A
** -----------------------------------------------------------
SR_ASCII_HEX
                    CMP.B   #$39,D5
                    BLE     Fn_ASCII_Num            * ASCII $0-$9
                    CMP.B   #$46,D5
                    BLE     Fn_ASCII_UcLtr          * ASCII $A-$F
                    BRA     Fn_ASCII_LcLtr          * ASCII $a-$f

Fn_ASCII_Num        SUBI.B  #$30, D5                * If Hex is $0-$9, sub $30
                    RTS
Fn_ASCII_UcLtr      SUBI.B  #$37, D5                * If Hex is $A-$F, sub $37
                    RTS
Fn_ASCII_LcLtr      SUBI.B  #$57, D5                * If Hex is $a-$f, sub $57
                    RTS

** -----------------------------------------------------------
** Convert single hexadecimal value to ASCII
**    hexadecimal values should be in range 0-9, A-F
**
** Parameters
**   D5 - Hex value to assess. Converted value returned in D5
**
** Example:
**   $0 -> $30
**   $A -> $41
**   $a -> $41
**
** Note: this function is case insensitive an $a = $A = $41 etc.
** -----------------------------------------------------------
SR_HEX_ASCII
                    CMP.B   #$9,D5
                    BLE     Fn_HEX_Nbr              * Hex $0-$9
                    BRA     Fn_HEX_Ltr              * Hex $A-$F, $a-$f

Fn_HEX_Nbr          ADDI.B  #$30, D5                * If Hex is $0-$9, add $30
                    RTS
Fn_HEX_Ltr          ADDI.B  #$37, D5                * If Hex is $A-$F, add $37
                    RTS

** -----------------------------------------------------------
** Copy hexadecimal value to string
**
** Parameters
**   A4 - Pointer to value copying from
**   A5 - Pointer to defined constant
**
** Data registers
**   D4 - Current byte      (hex value A4)
**   D5 - Temp byte         (hex value or string)
**   D6 - Number to shift
**
** Note: input string @ A5 has to have a null terminator for loop to stop
**
** -----------------------------------------------------------
SR_HEX_STR

Fn_Hex_Str_Loop     MOVE.B  (A4)+,D4

                    MOVE.B  (A5),D5
                    CMP.B   #$00,D5                  * Looking for NULL hex value $00
                    BEQ     Fn_Hex_Str_Done          * NULL value found - exit SR

                    ** First Hex value (high order value)
                    MOVE.B  D4,D5                    * Copy current value to temp byte holder
                    MOVE.B  #4,D6
                    LSR.B   D6,D5                    * Shift right to get high order hex value
                    JSR     SR_HEX_ASCII             * Hex to ASCII conversion
                    MOVE.B  D5,(A5)+                 * Move ASCII value to constant

                    ** Second Hex value (low order value)
                    MOVE.B  D4,D5                    * Copy current vaue to temp byte holder
                    MOVE.B  #4,D6
                    LSL.B   D6,D5
                    LSR.B   D6,D5                    * Shift left, right to get low order hex value
                    JSR     SR_HEX_ASCII             * Hex to ASCII conversion
                    MOVE.B  D5,(A5)+                 * Move ASCII value to constant

                    BRA     Fn_Hex_Str_Loop
Fn_Hex_Str_Done
                    MOVE.B  #$00,(A5)+               * Insert NULL value (required to print string)

                    RTS

** -----------------------------------------------------------
** Copy hexadecimal opDtaX directly to buffer
**    Display in string with VARying size
**
** Input long address opdta, ouput only number parts to buffer
**   example: opDtaX -> string
**   $00000012 -> $12
**   $00001200 -> $1200
**   $12000000 -> $12000000
**
** Note: Only works with opDtaX or other LONG values as input
**
** Parameters
**   A3 - Output buffer
**   A4 - Pointer to value copying from
**
** Data Regisers
**   D3 - Loop counter - reading 4 (bytes)
**   D4 - Current byte      (hex value A4)
**   D5 - Temp byte         (hex value or string)
**   D6 - Flag print to buffer
**
** -----------------------------------------------------------
SR_HEX_VAR
                    MOVE.B  #0,D6                     * Flag print to buffer
                    MOVE.B  #4,D3                     * Loop counter

Fn_Hex_Var_Loop     MOVE.B  (A4)+,D4

Fn_Hex_Var_Val1     ** First Hex value (high order value)
                    ** ---------------------------------------
                    MOVE.B  D4,D5                    * Copy current value to temp byte holder
                    LSR.B   #4,D5                    * Shift right to get high order hex value

                    CMP.B   #0,D5                    * Look for value > 0 to set print flag
                    BGT     Fn_Hex_Var_Flg1
                    BRA     Fn_Hex_Var_Chk1

Fn_Hex_Var_Flg1     MOVE.B  #1,D6                    * Sets flag to print
                    BRA     Fn_Hex_Var_Chk1

Fn_Hex_Var_Chk1     CMP.B   #1,D6                    * Check print flag
                    BEQ     Fn_Hex_Var_Pnt1          * Flag set; print value
                    BRA     Fn_Hex_Var_Val2          * Flag not set; check next value

Fn_Hex_Var_Pnt1     JSR     SR_HEX_ASCII             * Hex to ASCII conversion
                    MOVE.B  D5,(A3)+                 * Move ASCII value to buffer


Fn_Hex_Var_Val2     ** Second Hex value (low order value)
                    ** ---------------------------------------
                    MOVE.B  D4,D5                    * Copy current vaue to temp byte holder
                    LSL.B   #4,D5
                    LSR.B   #4,D5                    * Shift left, right to get low order hex value

                    CMP.B   #0,D5                    * Look for value > 0 to set print flag
                    BGT     Fn_Hex_Var_Flg2
                    BRA     Fn_Hex_Var_Chk2

Fn_Hex_Var_Flg2     MOVE.B  #1,D6                    * Sets flag to print
                    BRA     Fn_Hex_Var_Chk2

Fn_Hex_Var_Chk2     CMP.B   #1,D6                    * Check print flag
                    BEQ     Fn_Hex_Var_Pnt2          * Flag set; print value
                    BRA     Fn_Hex_Var_ChkC          * Flag not set; check next value

Fn_Hex_Var_Pnt2     JSR     SR_HEX_ASCII             * Hex to ASCII conversion
                    MOVE.B  D5,(A3)+                 * Move ASCII value to buffer

Fn_Hex_Var_ChkC     SUBI.B  #1,D3                    * Check the loop counter
                    CMP.B   #0,D3
                    BEQ     Fn_Hex_Var_Final         * Counter = 0; exit
                    BRA     Fn_Hex_Var_Loop          * Counter > 0; loop

Fn_Hex_Var_Final    CMP.B   #0,D6                    * Check if any numbers inserted
                    BEQ     Fn_Hex_Var_Zro
                    BRA     Fn_Hex_Var_Done
Fn_Hex_Var_Zro      MOVE.B  #$30,(A3)+               * Insert zero

Fn_Hex_Var_Done     RTS

** -----------------------------------------------------------
** Copy hexadecimal opDtaX directly to buffer
**    Display in string with fixed size of LONG
**
** Input long address opdta, ouput only number parts to buffer
**   example: opDtaX -> string
**   $00000012 -> $00000012
**   $00001200 -> $00001200
**   $12000000 -> $12000000
**
** Note: Only works with opDtaX or other LONG values as input
**
** Parameters
**   A3 - Output buffer
**   A4 - Pointer to value copying from
**
** Data Regisers
**   D3 - Loop counter - reading 4 (bytes)
**   D4 - Current byte      (hex value A4)
**   D5 - Temp byte         (hex value or string)
**   D6 - Fixed size 0=Byte (default), 1=Word, 2=Long
**
** -----------------------------------------------------------
SR_HEX_FIX
                    CMP.B   #0,D6
                    BEQ     Fn_Hex_Fix_Byt
                    CMP.B   #1,D6
                    BEQ     Fn_Hex_Fix_Wrd
                    CMP.B   #2,D6
                    BEQ     Fn_Hex_Fix_Lng
                    BRA     Fn_Hex_Fix_Byt            * (default size if not set 0,1,2)

Fn_Hex_Fix_Byt      MOVE.B  #1,D3                     * Loop 1 time for byte
                    BRA     Fn_Hex_Fix_Loop
Fn_Hex_Fix_Wrd      MOVE.B  #2,D3                     * Loop 2 times for word
                    BRA     Fn_Hex_Fix_Loop
Fn_Hex_Fix_Lng      MOVE.B  #4,D3                     * Loop 4 times for long
                    BRA     Fn_Hex_Fix_Loop

Fn_Hex_Fix_Loop     MOVE.B  (A4)+,D4

                    ** First Hex value (high order value)
                    ** ---------------------------------------
                    MOVE.B  D4,D5                    * Copy current value to temp byte holder
                    LSR.B   #4,D5                    * Shift right to get high order hex value
                    JSR     SR_HEX_ASCII             * Hex to ASCII conversion
                    MOVE.B  D5,(A3)+                 * Move ASCII value to buffer

                    ** Second Hex value (low order value)
                    ** ---------------------------------------
                    MOVE.B  D4,D5                    * Copy current vaue to temp byte holder
                    LSL.B   #4,D5
                    LSR.B   #4,D5                    * Shift left, right to get low order hex value
                    JSR     SR_HEX_ASCII             * Hex to ASCII conversion
                    MOVE.B  D5,(A3)+                 * Move ASCII value to buffer

                    SUBI.B  #1,D3                    * Check the loop counter
                    CMP.B   #0,D3
                    BEQ     Fn_Hex_Fix_Done          * Counter = 0; exit
                    BRA     Fn_Hex_Fix_Loop          * Counter > 0; loop

Fn_Hex_Fix_Done     RTS

** -----------------------------------------------------------
** Hex to Number converter (For immediate value)
**
** Convert hex number @ D3 and push to buffer @ A3
**
** Parameters
**   A3 - Pointer to output buffer
**
** Registers
**   D2 - Last Zero level
**   D3 - Number to convert
**   D4 - Zeros Tracker
**   D5 - Counter (single hex to convert)
**   D6 - Current Zero level
** -----------------------------------------------------------
SR_HEX_NUM
                    MOVE.B  #0,D2                     * Reset last level $FF = not set
                    MOVE.B  #0,D6                     * Reset current level $FF = not set
                    MOVE.B  #$23,(A3)+                * ASCII value '#' to buffer

                    CMP.B   #0,D3
                    BEQ     FN_Hex_Num_IsZro           * Dealing with zero, write zero and exit

Fn_Hex_Num_Chk      ** Find the next 10's to evaluate
                    ** Note: BHI - unsigned BGT
                    ** ---------------------------------------

                    CLR.L   D5                        * Clear counter

                    MOVE.L  #1000000000,D4
                    move.b  #9,d6                     * Set current zero level
                    CMP.L   D4,D3
                    BCC.L   Fn_Hex_Num_Calc           * 9 zeros (unsigned comparison)

                    MOVE.L  #100000000,D4
                    move.b  #8,d6
                    CMP.L   D4,D3
                    BCC.L   Fn_Hex_Num_Calc           * 8 zeros (unsigned comparison)

                    MOVE.L  #10000000,D4
                    move.b  #7,d6
                    CMP.L   D4,D3
                    BCC.L   Fn_Hex_Num_Calc           * 7 zeros (unsigned comparison)

                    MOVE.L  #1000000,D4
                    move.b  #6,d6
                    CMP.L   D4,D3
                    BCC.L   Fn_Hex_Num_Calc           * 6 zeros (unsigned comparison)

                    MOVE.L  #100000,D4
                    move.b  #5,d6
                    CMP.L   D4,D3
                    BCC.L   Fn_Hex_Num_Calc           * 5 zeros (unsigned comparison)

                    MOVE.L  #10000,D4
                    move.b  #4,d6
                    CMP.L   D4,D3
                    BCC.L   Fn_Hex_Num_Calc           * 4 zeros (unsigned comparison)

                    MOVE.L  #1000,D4
                    move.b  #3,d6
                    CMP.L   D4,D3
                    BCC.L   Fn_Hex_Num_Calc           * 3 zeros (unsigned comparison)

                    MOVE.L  #100,D4
                    move.b  #2,d6
                    CMP.L   D4,D3
                    BCC.L   Fn_Hex_Num_Calc           * 2 zeros (unsigned comparison)

                    MOVE.L  #10,D4
                    move.b  #1,d6
                    CMP.L   D4,D3
                    BCC.L   Fn_Hex_Num_Calc           * 1 zeros (unsigned comparison)

                    MOVE.L  #1,D4
                    move.b  #0,d6
                    CMP.L   D4,D3
                    BCC.L   Fn_Hex_Num_Calc           * 0 zeros (unsigned comparison)

                    BRA     Fn_Hex_Num_Done

Fn_Hex_Num_Calc     ** Calculate new sum from X zeros
                    ** Note: BCC - unsigned BGE
                    ** ---------------------------------------
                    SUB.L   D4,D3                     * Subtract multiple of 10
                    ADDI.B  #1,D5                     * Increment counter
                    CMP.L   D4,D3                     * Loop checker
                    BCC.L   Fn_Hex_Num_Calc           * Subtract another multiple of 10
                    BRA     Fn_Hex_Num_Buff           * Look for next multiple to subtract

Fn_Hex_Num_Buff      ** Add to the buffer - write what is in D5
                    ** ---------------------------------------
                    SUB.B   D6,D2                     * D2-D6 to get skip count result in D2
Fn_Hex_Num_ChkZ      CMP.B   #1,D2                     * Add zeros if skip > 1
                    BGT     Fn_Hex_Num_AddZ            * Skip  > 1; add zeros
                    BRA     Fn_Hex_Num_AddN            * Skip <= 1; Add number

Fn_Hex_Num_AddZ      MOVE.B  #$30,(A3)+                * Push ASCII zero to buffer
                    SUB.B   #1,D2                     * Subtract from skip count
                    BRA     Fn_Hex_Num_ChkZ            * Even more zeroes

Fn_Hex_Num_AddN      MOVE.L  D6,D2                     * Reset skip tracker
                    ADDI.B  #$30,D5                   * ASCII value 0 to 9
                    MOVE.B  D5,(A3)+                  * Push ASCII value to buffer
                    BRA     Fn_Hex_Num_Chk             * Loop around for next value

Fn_Hex_Num_Done      CMP.B   #0,D2                     * Check D2 to see where it exited
                    BGT     Fn_Hex_Num_Zros            * tack on end zeros
                    BRA     Fn_Hex_Num_Exit            * exit out

Fn_Hex_Num_Zros      MOVE.B  #$30,(A3)+                * ASCII value 0 to buffer
                    SUBI.B  #1,D2
                    BRA     Fn_Hex_Num_Done

Fn_Hex_Num_IsZro     MOVE.B  #$30,(A3)+                * ASCII value 0 to buffer

Fn_Hex_Num_Exit      RTS

** -----------------------------------------------------------
** Copy string to output buffer @ A3
**
** Parameters
**   A3 - Pointer to output buffer
**   A4 - Pointer to string copying from
**
** Data registers
**   D5 - Temp byte         (hex value or string)
** -----------------------------------------------------------
SR_CPY_STR_BUF

Fn_CPY_STR_Loop     MOVE.B  (A4),D5
                    CMP.B   #$00,D5                  * Looking for NULL hex value $00
                    BEQ     Fn_CPY_STR_Done          * NULL value found - exit SR

                    MOVE.B  (A4)+,(A3)+
                    BRA     Fn_CPY_STR_Loop

Fn_CPY_STR_Done     RTS

** -----------------------------------------------------------
** Length of string output buffer
** -----------------------------------------------------------
SR_CNT_STR_BUF

                    RTS

** -----------------------------------------------------------
** Includes: Subroutines etc.
** -----------------------------------------------------------
                    INCLUDE 'SR_IDX.X68'
                    INCLUDE 'SR_ID3.X68'
                    INCLUDE 'SR_ID4.X68'
                    INCLUDE 'SR_ID5.X68' * not complete
                    INCLUDE 'SR_ID6.X68'
                    INCLUDE 'SR_ID7.X68' * maybe not complete
                    INCLUDE 'SR_ID8.X68'
                    INCLUDE 'SR_ID9.X68' * maybe not complete
                    INCLUDE 'SR_IDA.X68' * not assigned
                    INCLUDE 'SR_IDB.X68' * not assigned
                    INCLUDE 'SR_IDC.X68' * not complete
                    INCLUDE 'SR_IDD.X68' * not complete
                    INCLUDE 'SR_IDE.X68'

** -----------------------------------------------------------
** Variables and constants
** -----------------------------------------------------------

maxLines            EQU      26                      * Max lines to display

adrValStart         DC.L     $00000000               * Value of starting address - set by user
adrStrStart         DC.B     '89ABCDEF',0            * String hex value display for start address
adrStsStart         DC.B     $FF                     * Status of starting address
                                                     *   FF not set, 00 set, 01 length error, 02 hex error
adrValEnd           DC.L     $00000000               * Value of ending address - set by user
adrStrEnd           DC.B     '89ABCDEF',0            * String hex value display for end address
adrStsEnd           DC.B     $FF                     * Status of ending address
                                                     *   FF not set, 00 set, 01 length error, 02 hex error

opWord              DC.W     $0000                   * 16 bit instruction Word
opID                DC.B     $00                     * First 4 bit value ID
opErr               DC.B     $01                     * Error byte: If set to 1 then is DATA. default is error

opValAdr            DC.L     $00000000               * Instruction address - used for calculation
opStrAdr            DC.B     '89ABCDEF',0            * String address
opNxtAdr            DC.L     $00000000               * Store next valid word in case instruction returns error

opOutBuf            DC.B     'Placeholder 80 cols wide output buffer                                          ',0
opPtrNam            DC.L     $00000000               * Pointer to full text name e.g. 'MOVE'

opValSiz            DC.B     $FF                     * Instruction size value $FF=Not set, 1=Byte, 2=Word, 3=Long

opDstReg            DC.B     $FF                     * Destination Register Value
opDstMod            DC.B     $FF                     * Destination Mode Value
opSrcReg            DC.B     $FF                     * Source Register Value
opSrcMod            DC.B     $FF                     * Source Register Mode

opDta1              DC.L     $00000000               * Data value one (most likely source)
opDta1T             DC.B     $FF                     * Data value one type ($FF not set, 0=byte, 1=word, 2=long)
opDta2              DC.L     $00000000               * Data value two (most likely destination)
opDta2T             DC.B     $FF                     * Data value two type ($FF not set, 0=byte, 1=word, 2=long)
opStrDtaWrd         DC.B     '0000',0                * Data value string placeholder - dynamically built
opStrDtaLng         DC.B     '00000000',0            * Data value string placeholder - dynamically built

** If mask set - override source or destination
** mask type for source can be pre decrement if destination mode is -(An)
opSrcMsk            DC.W     $0000                   * Source mask
opSrcMskD           DC.B     $00                     * Direction: 4=pre decrement; otherwise post decrement
opDstMsk            DC.W     $0000                   * Destination mask - always post decrement

opRotate            DC.B     $00                     * Rotation for IDE(14)
opSizDir            DC.B     $00                     * Size/Direction for IDE(14)
opIR                DC.B     $00                     * Immediate/Rotate for IDE(14)

opNam_DATA          DC.B     'DATA',0                * Non-supported instruction
opNam_ERRI          DC.B     'ERRI',0                * Invalid instruction EA
opNam_MOVE          DC.B     'MOVE',0                * String value for instruction
opNam_MOVEA         DC.B     'MOVEA',0               * String value for instruction
opNam_LEA           DC.B     'LEA',0                 * String value for instruction
opNam_NOT           DC.B     'NOT',0                 * String value for instruction
opNam_MOVEM         DC.B     'MOVEM',0               * String value for instruction
opNam_NOP           DC.B     'NOP',0                 * String value for instruction
opNam_RTS           DC.B     'RTS',0                 * String value for instruction
opNam_JSR           DC.B     'JSR',0                 * String value for instruction
opNam_ADDQ          DC.B     'ADDQ',0                * String value for instruction
opNam_BRA           DC.B     'BRA',0                 * String value for instruction
opNam_BEQ           DC.B     'BEQ',0                 * String value for instruction
opNam_BGT           DC.B     'BGT',0                 * String value for instruction
opNam_BLE           DC.B     'BLE',0                 * String value for instruction
opNam_MOVEQ         DC.B     'MOVEQ',0               * String value for instruction
opNam_OR            DC.B     'OR',0                  * String value for instruction
opNam_SUB           DC.B     'SUB',0                 * String value for instruction
opNam_AND           DC.B     'AND',0                 * String value for instruction
opNam_ADD           DC.B     'ADD',0                 * String value for instruction
opNam_ADDA          DC.B     'ADDA',0                * String value for instruction
opNam_ASL           DC.B     'ASL',0                 * String value for instruction
opNam_ASR           DC.B     'ASR',0                 * String value for instruction
opNam_LSL           DC.B     'LSL',0                 * String value for instruction
opNam_LSR           DC.B     'LSR',0                 * String value for instruction
opNam_ROL           DC.B     'ROL',0                 * String value for instruction
opNam_ROR           DC.B     'ROR',0                 * String value for instruction

opSizB              DC.B     '.B',0                  * String value for instruction size 'B'
opSizW              DC.B     '.W',0                  * String value for instruction size 'W'
opSizL              DC.B     '.L',0                  * String value for instruction size 'L'

msgInTemp           DC.B     'Placeholder for user input. 80 characters long is the max input limit...........',0
msgErr              DC.B     'Error',0               * Debug message
msgErrMask          DC.B     'ErrMsk',0
msgErrSrc           DC.B     'ErrSrc',0
msgErrSrcMod        DC.B     'ErrSrcMod',0
msgErrSrcDtT        DC.B     'ErrSrcDtT',0
msgErrDst           DC.B     'ErrDst',0
msgErrDstMod        DC.B     'ErrDstMod',0
msgErrDstDtT        DC.B     'ErrDstDtT',0

msgHdr01            DC.B     '3 Cores disassembler',CR,LF,0
msgHdr02a           DC.B     'Memory range:',0
msgHdr02b           DC.B     ' to ',0

msgStrIntro         DC.B     ' - All addresses must be 32 bit hexadecimal.',CR,LF,0
msgStrRange         DC.B     ' - Valid address range is 00000000 to 00FFFFED.',CR,LF,0
msgStrSize          DC.B     ' - Starting address should start on a word boundry',CR,LF,0
msgStrSizeExmpl     DC.B     '   @ XXXXXXX(0,2,4,8,A,C,E).',CR,LF,0
msgStrNote          DC.B     ' - Addresses will be adjusted if out of order or out of range.',CR,LF,0
msgStrNoteMore      DC.B     '   (automagically)',CR,LF,0
msgStrAdr1          DC.B     'Please enter a starting address: ',0
msgStrAdr1Err1      DC.B     'Invalid starting address length',CR,LF,0
msgStrAdr1Err2      DC.B     'Invalid starting address hexadecimal value',CR,LF,0
msgStrAdr1Scc       DC.B     'Starting address: ',0
msgStrAdr2          DC.B     'Please enter an ending address: ',0
msgStrAdr2Err1      DC.B     'Invalid ending address length',CR,LF,0
msgStrAdr2Err2      DC.B     'Invalid ending address hexadecimal value',CR,LF,0

msgPage             DC.B     'Hit Enter to go to the next page',CR,LF,0
msgEndMem01         DC.B     'You have reached the end of the memory sequence.',CR,LF,0
msgEndMem02         DC.B     '         Y to continue or any other key to quit: ',0
msgDone             DC.B     'Thank you for using 3 Cores disassembler!',0

msgLine             DC.B     '**************************************************',CR,LF,0
msgNewLine          DC.B     CR,LF,0
opComma             DC.B     ',',0
opPeriod            DC.B     '.',0
opSpace             DC.B     ' ',0
opTab               DC.W     $0900                  * Tab - doesn't work as expected
opBlank             DC.B     '',0
CR                  EQU      $0D                     * ASCII code for Carriage Return
LF                  EQU      $0A                     * ASCII code for Line Feed

                    END      $1000

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
