*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $9000
START:                  ; first instruction of program

* Put program code here

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


* Put variables and constants here

    END    START        ; last line of source

*~Font name~Courier New~
*~Font size~10~
*~Tab type~0~
*~Tab size~4~
