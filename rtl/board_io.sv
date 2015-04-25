/* Evaluation Bord I/O */

module board_io
  (input  wire             clk,   // clocka
   input  wire             reset, // reset
   input  wire  [3:0]      key,   // push buttons
   input  wire  [9:0]      sw,    // toggle switches
   output logic [0:3][6:0] hex,   // seven segment display
   output logic [7:0]      ledg,  // led green
   output logic [9:0]      ledr,  // led red
   if_io.slave             io);   // J1 I/O

   import ioaddr::*;

   always_ff @(posedge clk)
     begin
	if (reset)
	  begin
	     ledg <= '0;
	     ledr <= '0;
	     hex  <= '1;
	  end
	else
	  if (io.wr)
	    case (io.addr)
	      LEDG: ledg   <=  io.dout[7:0];
	      LEDR: ledr   <=  io.dout[9:0];
	      HEX0: hex[0] <= ~io.dout[6:0];
	      HEX1: hex[1] <= ~io.dout[6:0];
	      HEX2: hex[2] <= ~io.dout[6:0];
	      HEX3: hex[3] <= ~io.dout[6:0];
	    endcase
     end

   always_comb
     begin
	io.din = 16'b0; // Unused bits must be '0' because of OR bus connection.

	if (io.rd)
	  case (io.addr)
	    KEY: io.din[3:0] = key;
	    SW : io.din[9:0] = sw;
	  endcase
     end
endmodule
