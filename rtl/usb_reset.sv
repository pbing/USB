/* USB reset detection.
 * USB-2.0 specification, Table 7-14: TDETRST = 2.5 µs ... 10000 µs
 */

module usb_reset
  import types::*;
   (input  wire  reset_i,  // system reset input
    input  wire  clk,      // system clock (slow speed: 6 MHz, full speed: 48 MHz)
    input  wire  se0,      // data from PHY
    output logic reset_o); // reset output

   generate
      if (USB_FULL_SPEED)
	begin:full_speed
	   logic [1:13] counter; // 8191 / 48 MHz = 170.6 µs

	   always_ff @(posedge clk)
	     if (reset_i)
	       counter <= 13'b0;
	     else
	       if (se0)
		 counter <= {^counter[11:13] ^~ counter[8], counter[$left(counter):$right(counter) - 1]};
	       else
		 counter <= 13'b0;

	   always_comb reset_o = (reset_i || (counter == 13'h0001));
	end:full_speed
      else
	begin:slow_speed
	   logic [1:10] counter; // 1023 / 6 MHz = 170.5 µs

	   always_ff @(posedge clk)
	     if (reset_i)
	       counter <= 10'b0;
	     else
	       if (se0)
		 counter <= {counter[10] ^~ counter[7], counter[$left(counter):$right(counter) - 1]};
	       else
		 counter <= 10'b0;

	   always_comb reset_o = (reset_i || (counter == 10'h001));
	end:slow_speed
   endgenerate
endmodule
