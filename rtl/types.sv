/* Types */

package types;
   /* Symbols J and K have inverse polarity in each USB mode */
   typedef enum logic [1:0] {SE0, J, K, SE1} d_port_t; // Low Speed (1.5 MHz)
   //typedef enum logic [1:0] {SE0, K, J, SE1} d_port_t; // Full Speed (12 MHz)

   /* Packets */
   typedef enum logic [3:0] {/* Token */
			     OUT      = 4'b0001,
			     IN       = 4'b1001,
			     SOF      = 4'b0101,
			     SETUP    = 4'b1101,
			     /* Data */
			     DATA0    = 4'b0011,
			     DATA1    = 4'b1011,
			     DATA2    = 4'b0111,
			     MDATA    = 4'b1111,
			     /* Handshake */
			     ACK      = 4'b0010,
			     NAK      = 4'b1010,
			     STALL    = 4'b1110,
			     NYET     = 4'b0110,
			     /* Special */
			     PRE_ERR  = 4'b1100, // PRE and ERR use the same value
			     SPLIT    = 4'b1000,
			     PING     = 4'b0100,
			     RESERVED = 4'b0000
			     } pid_t;

   typedef  struct {
      logic [3:0] pidx; // inverted PID
      pid_t       pid;  // PID
      logic [6:0] addr; // address
      logic [3:0] endp; // endpoint
      logic [4:0] crc5; // CRC5
   } token_t;
endpackage
