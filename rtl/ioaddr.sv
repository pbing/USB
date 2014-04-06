/* I/O addresses */

package ioaddr;
   parameter [15:0]
     /* LED */
     LEDG           = 16'h4000,
     LEDR           = 16'h4002,

     /* HEX display */
     HEX0           = 16'h4010,
     HEX1           = 16'h4012,
     HEX2           = 16'h4014,
     HEX3           = 16'h4016,

     /* keys and switches */
     KEY            = 16'h4020,
     SW             = 16'h4022,

     /* USB register */
     ENDPI0_CONTROL = 16'h5000,
     ENDPI1_CONTROL = 16'h5002,
     
     ENDPI0_DATA    = 16'h5020,
     ENDPI1_DATA    = 16'h5022,
     
     ENDPO0_CONTROL = 16'h5040,
     
     ENDPO0_DATA    = 16'h5060;
endpackage
