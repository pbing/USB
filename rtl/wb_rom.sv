/* ROM with Wishbone interface */

`default_nettype none

module wb_rom
  #(parameter size       = 'h1000, // ROM4096x16
    parameter waitcycles = 0)
   (if_wb.slave wb);

   wire        valid;
   wire        rom_rden;

   /* work around missing modport expressions */
   wire [15:0] wb_dat_o;

`ifdef NO_MODPORT_EXPRESSIONS
   assign wb.dat_s = wb_dat_o;
`else
   assign wb.dat_o = wb_dat_o;
`endif

   rom4kx16 rom
     (.clock   (wb.clk),
      .address (wb.adr[$clog2(size) - 1:0]),
      .q       (wb_dat_o),
      .rden    (rom_rden));

   assign rom_rden = valid & !wb.we;

   /* Wishbone control
    * Classic pipelined bus cycles
    */
   assign valid = wb.cyc & wb.stb;

   always_ff @(posedge wb.clk)
     if (wb.rst)
       wb.ack <= 1'b0;
     else
       wb.ack <= valid & ~wb.stall;

   generate
      case (waitcycles)
        0:
          begin:w0
             assign wb.stall = 1'b0;
          end:w0

        1:
          begin:w1
             logic stall;

             always_ff @(posedge wb.clk)
               if (wb.rst)
                 stall <= 1'b1;
               else
                 if (stall == 1'b0)
                   stall <= 1'b1;
                 else
                   if (valid)
                     stall <= 1'b0;

             assign wb.stall = valid & stall;
          end:w1

        default
          begin:wn
             logic [1:waitcycles] stall;

             always_ff @(posedge wb.clk)
               if (wb.rst)
                 stall <= '1;
               else
                 if (stall == '0)
                   stall <= '1;
                 else
                   if (valid)
                     stall <= {1'b0, stall[$left(stall):$right(stall) - 1]};

             assign wb.stall = valid & stall[$right(stall)];
          end:wn
      endcase
   endgenerate
endmodule

`resetall
