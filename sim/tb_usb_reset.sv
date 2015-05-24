/* Testbench USB reset detection */

module tb_usb_reset;
   timeunit 1ns;
   timeprecision 1ps;

   import types::*;

   const realtime tclk = 1s/((7 * USB_FULL_SPEED + 1) * 6.0e6),
		  tbit = 4 * tclk;

   bit  reset_i = 1'b1; // system reset bit
   bit  clk;            // system clock (24 MHz)
   bit  se0;            // data from PHY
   wire reset_o;        // reset output

   usb_reset dut(.*);

   always #(tclk/2) clk = ~clk;

   initial
     begin:main
	repeat (3) @(posedge clk);
	reset_i = 1'b0;

	#10us  se0 = 1'b1;
	#2.4us se0 = 1'b0;

	#10us  se0 = 1'b1;
	#10ms  se0 = 1'b0;

	#10us $stop;
     end:main
endmodule
