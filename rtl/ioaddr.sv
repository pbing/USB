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
     ENDPI0_DATA    = 16'h5000,
     ENDPI0_STATUS  = 16'h5002,
     ENDPO0_DATA    = 16'h5004,
     ENDPO0_STATUS  = 16'h5006,
     ENDPI1_DATA    = 16'h5008,
     ENDPI1_STATUS  = 16'h500a;
endpackage
