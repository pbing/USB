/* USB reset detection.
 * USB-2.0 specification, Table 7-14: TDETRST = 2.5 µs ... 10000 µs
 */

module usb_reset
  (input  wire  reset_i,        // system reset input
   input  wire  clk,            // system clock (slow speed: 6 MHz, full speed: 48 MHz)
   input  wire  se0,            // data from PHY
   input  wire  usb_full_speed, // 0: USB low-speed 1:USB full-speed
   output logic reset_o);       // reset output

   logic [1:13] counter;        // 8191 / 48 MHz = 170.6 µs

   always_ff @(posedge clk)
     if (reset_i)
       counter <= 13'b0;
     else
       if (se0)
         if (usb_full_speed)
	   counter[1:13] <= {^counter[11:13] ^~ counter[8], counter[1:12]};
         else
	   counter[1:10] <= {counter[10] ^~ counter[7], counter[1:9]};
       else
	 counter <= 13'b0;

   always_comb
     if (usb_full_speed)
       reset_o = counter == 13'h0001;
     else
       reset_o = counter == 13'h0008;
endmodule
