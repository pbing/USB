/* Wishbone interconnection */

`default_nettype none

module wb_intercon
  (if_wb.slave  wbm,   // CPU
   if_wb.master wbs1,  // ROM
   if_wb.master wbs2,  // RAM
   if_wb.master wbs3,  // I/O
   if_wb.master wbs4); // I/O

   import ioaddr::*;

   wire        valid;
   wire        sel1, sel2, sel3, sel4;
   logic       sel1_r, sel2_r, sel3_r, sel4_r;
   wire [15:0] wbm_dat_i, wbm_dat_o,
               wbs1_dat_i, wbs1_dat_o,
               wbs2_dat_i, wbs2_dat_o,
               wbs3_dat_i, wbs3_dat_o,
               wbs4_dat_i, wbs4_dat_o;

`ifdef NO_MODPORT_EXPRESSIONS
   assign wbm_dat_i  = wbm.dat_m;
   assign wbm.dat_s  = wbm_dat_o;
   assign wbs1_dat_i = wbs1.dat_s;
   assign wbs2_dat_i = wbs2.dat_s;
   assign wbs3_dat_i = wbs3.dat_s;
   assign wbs4_dat_i = wbs4.dat_s;
   assign wbs1.dat_m = wbs1_dat_o;
   assign wbs2.dat_m = wbs2_dat_o;
   assign wbs3.dat_m = wbs3_dat_o;
   assign wbs4.dat_m = wbs4_dat_o;
`else
   assign wbm_dat_i  = wbm.dat_i;
   assign wbm.dat_o  = wbm_dat_o;
   assign wbs1_dat_i = wbs1.dat_i;
   assign wbs2_dat_i = wbs2.dat_i;
   assign wbs3_dat_i = wbs3.dat_i;
   assign wbs4_dat_i = wbs4.dat_i;
   assign wbs1.dat_o = wbs1_dat_o;
   assign wbs2.dat_o = wbs2_dat_o;
   assign wbs3.dat_o = wbs3_dat_o;
   assign wbs4.dat_o = wbs4_dat_o;
`endif

   assign valid = wbm.cyc & wbm.stb;
   assign sel1  = valid && (wbm.adr[15:12] == 4'b0000);                        // ROM 0000H...1FFFH
   assign sel2  = valid && (wbm.adr[15:12] == {1'b0, RAM_BASE_ADDR[15:13]});   // RAM 2000H...3FFFH
   assign sel3  = valid && (wbm.adr[15:11] == {1'b0, BOARD_BASE_ADDR[15:12]}); // I/O BOARD
   assign sel4  = valid && (wbm.adr[15:11] == {1'b0, SIE_BASE_ADDR[15:12]});   // I/O SIE

   always_ff @(posedge wbm.clk)
     if (wbm.rst)
       begin
          sel1_r <= 1'b0;
          sel2_r <= 1'b0;
          sel3_r <= 1'b0;
          sel4_r <= 1'b0;
       end
     else
       begin
          sel1_r <= sel1;
          sel2_r <= sel2;
          sel3_r <= sel3;
          sel4_r <= sel4;
       end

   assign wbs1.adr   = wbm.adr;
   assign wbs1.cyc   = wbm.cyc & (sel1 | sel1_r);
   assign wbs1.stb   = wbm.stb & sel1;
   assign wbs1.we    = wbm.we;
   assign wbs1_dat_o = wbm_dat_i;

   assign wbs2.adr   = wbm.adr;
   assign wbs2.cyc   = wbm.cyc & (sel2 | sel2_r);
   assign wbs2.stb   = wbm.stb & sel2;
   assign wbs2.we    = wbm.we;
   assign wbs2_dat_o = wbm_dat_i;

   assign wbs3.adr   = wbm.adr;
   assign wbs3.cyc   = wbm.cyc & (sel3 | sel3_r);
   assign wbs3.stb   = wbm.stb & sel3;
   assign wbs3.we    = wbm.we;
   assign wbs3_dat_o = wbm_dat_i;

   assign wbs4.adr   = wbm.adr;
   assign wbs4.cyc   = wbm.cyc & (sel4 | sel4_r);
   assign wbs4.stb   = wbm.stb & sel4;
   assign wbs4.we    = wbm.we;
   assign wbs4_dat_o = wbm_dat_i;

   assign wbm.stall  = (wbs1.stall & sel1) |
                       (wbs2.stall & sel2) |
                       (wbs3.stall & sel3) |
                       (wbs4.stall & sel4);

   assign wbm.ack    = (wbs1.ack & sel1_r) |
                       (wbs2.ack & sel2_r) |
                       (wbs3.ack & sel3_r) |
                       (wbs4.ack & sel4_r);

   assign wbm_dat_o  = (wbs1_dat_i & {16{sel1_r}}) |
                       (wbs2_dat_i & {16{sel2_r}}) |
                       (wbs3_dat_i & {16{sel3_r}}) |
                       (wbs4_dat_i & {16{sel4_r}});
endmodule

`resetall
