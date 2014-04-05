/* Evaluation Bord I/O */

module display(input               clk,   // clocka
	       input               reset, // reset
	       output logic [6:0]  hex0,  // seven segment digit 0
	       output logic [6:0]  hex1,  // seven segment digit 1
	       output logic [6:0]  hex2,  // seven segment digit 2
	       output logic [6:0]  hex3,  // seven segment digit 3
	       output logic [7:0]  ledg,  // led green
	       output logic [9:0]  ledr,  // led red
	       if_io.slave         io);   // J1 I/O

   import ioaddr::*;

   always_ff @(posedge clk)
     begin
	if (reset)
	  begin
	     ledg <= '0;
	     ledr <= '0;
	     hex0 <= '1;
	     hex1 <= '1;
	     hex2 <= '1;
	     hex3 <= '1;
	  end
	else
	  if (io.wr)
	    case (io.addr)
	      LEDG: ledg <=  io.dout[7:0];
	      LEDR: ledr <=  io.dout[9:0];
	      HEX0: hex0 <= ~io.dout[6:0];
	      HEX1: hex1 <= ~io.dout[6:0];
	      HEX2: hex2 <= ~io.dout[6:0];
	      HEX3: hex3 <= ~io.dout[6:0];
	    endcase
     end
endmodule
