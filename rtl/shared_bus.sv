/* Shared Bus implementation */

module shared_bus
  (input               clk,     // clock
   input               reset,   // reset

   /* I/O ports */
   input        [3:0]  key,     // push button
   input        [9:0]  sw,      // toggle switch
   output logic [6:0]  hex0,    // seven segment digit 0
   output logic [6:0]  hex1,    // seven segment digit 1
   output logic [6:0]  hex2,    // seven segment digit 2
   output logic [6:0]  hex3,    // seven segment digit 3
   output logic [7:0]  ledg,    // led green
   output logic [9:0]  ledr,    // led red

   /* Interfaces */
   if_io.slave         io,
   if_fifo.master      endpi0,  // endpoint in 0
   if_fifo.master      endpo0,  // endpoint out 0
   if_fifo.master      endpi1); // endpoint in 1

   import ioaddr::*;

   always_ff @(posedge clk)
     begin:out
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
     end:out

   always_comb
     begin:in
	io.din       = 8'bx;
	endpi0.data  = io.dout[7:0];
	endpi1.data  = io.dout[7:0];
	endpo0.rdreq = 1'b0;
	endpi0.wrreq = 1'b0;
	endpi1.wrreq = 1'b0;

	if (io.rd)
	  case (io.addr)
	    KEY: io.din[3:0] = key;
	    SW : io.din[9:0] = sw;

	    ENDPO0_DATA:
	      begin
		 io.din[7:0]  = endpo0.q;
		 endpo0.rdreq = 1'b1;
	      end

	    ENDPI0_STATUS: io.din[0] = endpi0.full;
	    ENDPO0_STATUS: io.din[0] = endpo0.empty;
	    ENDPI1_STATUS: io.din[0] = endpi1.full;
	  endcase

	if (io.wr)
	  case (io.addr)
	    ENDPI0_DATA: endpi0.wrreq = 1'b1;
	    ENDPI1_DATA: endpi1.wrreq = 1'b1;
	  endcase
     end:in
endmodule
