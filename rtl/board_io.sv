/* Evaluation Bord I/O */

`default_nettype none

module board_io
  (input  wire             reset, // reset
   input  wire  [3:0]      key,   // push buttons
   input  wire  [9:0]      sw,    // toggle switches
   output logic [0:3][6:0] hex,   // seven segment display
   output logic [7:0]      ledg,  // led green
   output logic [9:0]      ledr,  // led red
   if_wb.slave             wb);   // Wishbone

   import ioaddr::*;

   logic        valid;
   logic        io_ren;
   logic        io_wen;
   wire  [15:0] wb_dat_i;
   logic [15:0] wb_dat_o;
   logic [11:0] io_adr;

`ifdef NO_MODPORT_EXPRESSIONS
   assign wb_dat_i = wb.dat_m;
   assign wb.dat_s = wb_dat_o;
`else
   assign wb_dat_i = wb.dat_i;
   assign wb.dat_o = wb_dat_o;
`endif

   always_ff @(posedge wb.clk)
     begin
	if (reset)
	  begin
	     ledg <= '0;
	     ledr <= '0;
	     hex  <= '1;
	  end
	else
	  if (io_wen)
	    case (io_adr)
	      LEDG: ledg   <=  wb_dat_i[7:0];
	      LEDR: ledr   <=  wb_dat_i[9:0];
	      HEX0: hex[0] <= ~wb_dat_i[6:0];
	      HEX1: hex[1] <= ~wb_dat_i[6:0];
	      HEX2: hex[2] <= ~wb_dat_i[6:0];
	      HEX3: hex[3] <= ~wb_dat_i[6:0];
	    endcase
     end

   always_comb
     begin
	wb_dat_o = 16'b0;

	if (io_ren)
	  case (io_adr)
	    KEY: wb_dat_o[3:0] = key;
	    SW : wb_dat_o[9:0] = sw;
	  endcase
     end

   always_comb io_ren = valid & ~wb.we;
   always_comb io_wen = valid &  wb.we;
   always_comb io_adr = wb.adr[10:0] << 1;

   /* Wishbone control
    * Classic pipelined bus cycles
    */
   always_comb valid = wb.cyc & wb.stb;

   always_ff @(posedge wb.clk)
     if (wb.rst)
       wb.ack <= 1'b0;
     else
       wb.ack <= valid;

   assign wb.stall = 1'b0;
endmodule

 `resetall
