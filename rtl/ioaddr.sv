/* I/O addresses */

package ioaddr;
   parameter [15:0]
     /* BOARD BASE ADDRESS */
     BOARD_BASE_ADDR = 16'h4000,
     
     /* LED */
     LEDG            = 16'h4000,
     LEDR            = 16'h4002,

     /* HEX display */
     HEX0            = 16'h4010,
     HEX1            = 16'h4012,
     HEX2            = 16'h4014,
     HEX3            = 16'h4016,

     /* keys and switches */
     KEY             = 16'h4020,
     SW              = 16'h4022,

     /* SIE BASE ADDRESS */
     SIE_BASE_ADDR   = 16'h5000,
    
     /* USB register */
     ENDPI0_CONTROL  = 16'h5000,
     ENDPI0_DATA     = 16'h5002,

     ENDPI1_CONTROL = 16'h5004,
     ENDPI1_DATA    = 16'h5006,

     ENDPO0_CONTROL = 16'h5040,
     ENDPO0_DATA    = 16'h5042,

     USB_ADDRESS    = 16'h5100,
     USB_TOKEN      = 16'h5102,
     USB_STATUS     = 16'h5104;
endpackage
