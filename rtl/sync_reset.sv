/* Synchronize reset */

`default_nettype none

module sync_reset
  #(parameter n = 3)
   (input  wire clk,
    input  wire reset_in_n,
    output wire reset);

   logic [1:n] sync;

   always_ff @(posedge clk or negedge reset_in_n)
     if (!reset_in_n)
       sync <= '1;
     else
       sync <= {1'b0, sync[$left(sync):$right(sync) - 1]};

   assign reset = sync[$right(sync)];
endmodule

`resetall
