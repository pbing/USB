/* Synchronize reset from external key. */

module sync_reset(input        clk,    // system clock (24 MHz)
		  input        key,    // push button
		  output logic reset); // syncronized reset (high active)

   logic [1:2] reset_s; // syncronization registers

   always_ff @(posedge clk or negedge key)
     if (!key)
       {reset_s,reset} <= '1;
     else
       {reset_s,reset} <= {1'b0,reset_s};
endmodule
