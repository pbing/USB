/* Shared Bus implementation */

module io_bus
  (if_io.slave  cpu,    // J1 I/O
   if_io.master sie,    // USB SIE
   if_io.master board); // evaluation board I/O

   always_comb
     begin
	sie.dout   = cpu.dout;
	sie.addr   = cpu.addr;
	sie.rd     = cpu.rd;
	sie.wr     = cpu.wr;

	board.dout = cpu.dout;
	board.addr = cpu.addr;
	board.rd   = cpu.rd;
	board.wr   = cpu.wr;

	/* Use OR for bus connector. */
	cpu.din = sie.din | board.din;
     end
endmodule
