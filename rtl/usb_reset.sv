/* USB reset detection.
 * USB-2.0 specification, Table 7-14: TDETRST=2.5 µs ... 10000 µs
 */

module usb_reset
  import types::*;
   (input  wire     reset_i,    // system reset input
    input  wire     clk,        // system clock (24 MHz)
    input  d_port_t line_state, // data from PHY
    output logic    reset_o);   // reset output

   logic [1:12] counter; // 4095/24 MHz = 170.6 µs

   always_ff @(posedge clk)
     if (reset_i)
       counter <= 12'b0;
     else
       if (line_state == SE0)
	 counter <= {^counter[10:12] ^~ counter[4], counter[$left(counter):$right(counter) - 1]};
       else
	 counter <= 12'b0;

   always_comb reset_o = (reset_i || (counter == 12'h001));
endmodule
