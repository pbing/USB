/* USB averaging filter */

module usb_filter
  import types::*;
   (input  wire     clk,  // USB clock
    input  d_port_t d,    // data from PHY
    output logic    q,    // filtered data
    output logic    se0); // filtered SE0

   logic [0:5] dp, dn;         // 0:1 synchronizer; 1:5 filter
   logic [2:0] dp_sum, dn_sum; // sum of five samples
   logic       dp_cmp, dn_cmp; // comparators

   always_ff @(posedge clk)
     begin
        {dp[0], dn[0]} <= d;
        dp[1:5]        <= dp[0:4];
        dn[1:5]        <= dn[0:4];
     end

   always_comb
     begin
        dp_sum = dp[1] + dp[2] + dp[3] + dp[4] + dp[5];
        dn_sum = dn[1] + dn[2] + dn[3] + dn[4] + dn[5];

        dp_cmp = dp_sum > 3'd2;
        dn_cmp = dn_sum > 3'd2;

        q      = dp_cmp;
        se0    = ~dp_cmp & ~dn_cmp;
     end
endmodule
