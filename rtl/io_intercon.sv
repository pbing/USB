/* Shared Bus implementation */

module io_intercon
  (if_io.slave  cpu,    // J1 I/O
   if_io.master sie,    // USB SIE
   if_io.master board); // evaluation board I/O

   import ioaddr::*;

   wire sie_sel   = (cpu.addr[15:12] == SIE_BASE_ADDR[15:12]);
   wire board_sel = (cpu.addr[15:12] == BOARD_BASE_ADDR[15:12]);

   always_comb
     begin
	sie.dout   = cpu.dout;
	sie.addr   = cpu.addr;
	sie.rd     = cpu.rd & sie_sel ;
	sie.wr     = cpu.wr & sie_sel;

	board.dout = cpu.dout;
	board.addr = cpu.addr;
	board.rd   = cpu.rd & board_sel;
	board.wr   = cpu.wr & board_sel;

	case (1'b1)
	  sie_sel  : cpu.din = sie.din;
	  board_sel: cpu.din = board.din;
	  default    cpu.din = 16'h0;
	endcase
     end
endmodule
