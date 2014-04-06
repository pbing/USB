/* Shared Bus implementation */

module shared_bus(input [3:0]    key,     // push button
                  input [9:0]    sw,      // toggle switch
		  if_io.slave    io,      // J1 I/O
		  if_fifo.master endpi0,  // endpoint in 0
		  if_fifo.master endpo0,  // endpoint out 0
		  if_fifo.master endpi1); // endpoint in 1

   import ioaddr::*;

   always_comb
     begin
	io.din       = 16'b0; // avoid X on data stack
	endpi0.data  = io.dout[7:0];
	endpi1.data  = io.dout[7:0];
	endpo0.rdreq = 1'b0;
	endpi0.wrreq = 1'b0;
	endpi1.wrreq = 1'b0;

	if (io.rd)
	  case (io.addr)
	    KEY           : io.din[3:0] = key;
	    SW            : io.din[9:0] = sw;
	    ENDPO0_DATA   : io.din[7:0] = endpo0.q;
	    ENDPI0_CONTROL: io.din[0]   = endpi0.full;
	    ENDPO0_CONTROL: io.din[0]   = endpo0.empty;
	    ENDPI1_CONTROL: io.din[0]   = endpi1.full;
	  endcase

	if (io.wr)
	  case (io.addr)
	    ENDPO0_CONTROL: endpo0.rdreq = io.dout[0];
	    ENDPI0_DATA   : endpi0.wrreq = 1'b1;
	    ENDPI1_DATA   : endpi1.wrreq = 1'b1;
	  endcase
     end
endmodule
