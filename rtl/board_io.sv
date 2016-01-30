/* Evaluation Bord I/O */

module board_io
  (input  wire             reset, // reset
   input  wire  [3:0]      key,   // push buttons
   input  wire  [9:0]      sw,    // toggle switches
   output logic [0:3][6:0] hex,   // seven segment display
   output logic [7:0]      ledg,  // led green
   output logic [9:0]      ledr,  // led red
   if_io.slave             io);   // J1 I/O

   import ioaddr::*;

   always_ff @(posedge io.clk)
     begin
	if (reset)
	  begin
	     ledg <= '0;
	     ledr <= '0;
	     hex  <= '1;
	  end
	else
	  if (io.wr)
	    case (io.addr[11:0])
	      LEDG[11:0]: ledg   <=  io.dout[7:0];
	      LEDR[11:0]: ledr   <=  io.dout[9:0];
	      HEX0[11:0]: hex[0] <= ~io.dout[6:0];
	      HEX1[11:0]: hex[1] <= ~io.dout[6:0];
	      HEX2[11:0]: hex[2] <= ~io.dout[6:0];
	      HEX3[11:0]: hex[3] <= ~io.dout[6:0];
	    endcase
     end

   always_comb
     begin
	io.din = 16'b0;

	if (io.rd)
	  case (io.addr[11:0])
	    KEY[11:0]: io.din[3:0] = key;
	    SW [11:0]: io.din[9:0] = sw;
	  endcase
     end
endmodule
