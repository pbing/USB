\ Compile the firmware

include crossj1.fs
include basewords.fs

target
4 org

module[ eveything"

include nuc.fs
include application.fs

]module

0 org

code 0jump
    main ubranch
end-code

\ **********************************************************************

meta
hex

: create-output-file w/o create-file throw to outfile ;

s" j1.mif" create-output-file
:noname
   s" -- Quartus II generated Memory Initialization File (.mif)" type cr
   s" WIDTH=16;" type cr
   s" DEPTH=8192;" type cr
   s" ADDRESS_RADIX=HEX;" type cr
   s" DATA_RADIX=HEX;" type cr
   s" CONTENT BEGIN" type cr

    4000 0 do
       4 spaces
       i 2/ s>d <# # # # # #> type s"  : " type
       i t@ s>d <# # # # # #> type [char] ; emit cr
    2 +loop

   s" END;" type cr
; execute

s" j1.lst" create-output-file
0 2000 disassemble-block

bye
