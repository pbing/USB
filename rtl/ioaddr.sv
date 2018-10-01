/* I/O addresses */

package ioaddr;
   /* RAM */
   parameter [15:0] RAM_BASE_ADDR   = 16'h2000;

   /* BOARD BASE ADDRESS */
   parameter [15:0] BOARD_BASE_ADDR = 16'h5000;
   /* LED */
   parameter [11:0] LEDG            = 12'h000;
   parameter [11:0] LEDR            = 12'h002;
   /* HEX display */
   parameter [11:0] HEX0            = 12'h010;
   parameter [11:0] HEX1            = 12'h012;
   parameter [11:0] HEX2            = 12'h014;
   parameter [11:0] HEX3            = 12'h016;
   /* keys and switches */
   parameter [11:0] KEY             = 12'h020;
   parameter [11:0] SW              = 12'h022;

   /* SIE BASE ADDRESS */
   parameter [15:0] SIE_BASE_ADDR   = 16'h6000;
   /* USB register */
   parameter [11:0] USB_TX_DATA     = 12'h000;
   parameter [11:0] USB_TX_CONTROL  = 12'h002;
   parameter [11:0] USB_RX_DATA     = 12'h004;
   parameter [11:0] USB_RX_CONTROL  = 12'h006;
endpackage
