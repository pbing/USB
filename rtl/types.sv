/* Types */

package types;
   parameter [1:0] USB_FULL_SPEED = 0; // 0:Low-Speed  1:Full-Speed

   /* d_port_t = {D+, D-}
    * Symbols J and K have inverse polarity in slow/full speed.
    */
   typedef enum logic [1:0] {SE0 = 2'd0,
			     J   = 2'd1 + USB_FULL_SPEED,
			     K   = 2'd2 - USB_FULL_SPEED,
			     SE1 = 2'd3 } d_port_t;

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

   typedef struct {
      logic [3:0] pidx; // inverted PID
      pid_t       pid;  // PID
      logic [6:0] addr; // address
      logic [3:0] endp; // endpoint
      logic [4:0] crc5; // CRC5
   } token_t;

   typedef struct {
      logic bto;        // bus turnaround time-out
      logic crc16;      // CRC16 error
      logic crc5;       // CRC5 error
      logic pid;        // PID error
      logic usb_reset;  // USB reset
      logic stall;      // a STALL handshake was sent by the SIE
      logic token_done; // token process complete
   } usb_status_t;
endpackage
