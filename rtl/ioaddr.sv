/* I/O addresses */

package ioaddr;
   parameter [15:0]
     /* RAM */
     RAM_BASE_ADDR = 16'h2000,



     /* BOARD BASE ADDRESS */
     BOARD_BASE_ADDR = 16'h5000,

     /* LED */
     LEDG            = 12'h000,
     LEDR            = 12'h002,

     /* HEX display */
     HEX0            = 12'h010,
     HEX1            = 12'h012,
     HEX2            = 12'h014,
     HEX3            = 12'h016,

     /* keys and switches */
     KEY             = 12'h020,
     SW              = 12'h022,



     /* SIE BASE ADDRESS */
     SIE_BASE_ADDR  = 16'h6000,
    
     /* USB register */
     ENDPI0_CONTROL = 12'h000,
     ENDPI0_DATA    = 12'h002,

     ENDPI1_CONTROL = 12'h004,
     ENDPI1_DATA    = 12'h006,

     ENDPO0_CONTROL = 12'h040,
     ENDPO0_DATA    = 12'h042,

     USB_ADDRESS    = 12'h100,
     USB_TOKEN      = 12'h102,
     USB_STATUS     = 12'h104;
endpackage
