/* Testbench USB reset detection */

module tb_usb_reset;
   timeunit 1ns;
   timeprecision 1ps;

   import types::*;

   const realtime tbit = 1s / ((7 * USB_FULL_SPEED + 1) * 1.5e6),
		  tclk = tbit / 4;

   bit  reset_i; // system reset bit
   bit  clk;     // system clock
   bit  se0;     // data from PHY
   wire reset_o; // reset output

   usb_reset dut(.usb_full_speed(USB_FULL_SPEED), .*);

   always #(tclk/2) clk = ~clk;

   initial
     begin:main
        reset_i = 1'b1;
	repeat (3) @(posedge clk);
	reset_i = 1'b0;

	#10us  se0 = 1'b1;
	#2.4us se0 = 1'b0;

	#10us  se0 = 1'b1;
	#500us se0 = 1'b0;

	#10us $finish;
     end:main
endmodule
