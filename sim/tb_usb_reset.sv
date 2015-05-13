/* Testbench USB reset detection */

module tb_usb_reset;
   timeunit 1ns;
   timeprecision 1ps;

   const realtime tusb = 1s/1.5e6, // low speed
		  tclk = 1s/24.0e6;

   import types::*;

   bit           reset_i = 1'b1; // system reset bit
   bit           clk;            // system clock (24 MHz)
   var  d_port_t line_state = J; // data from PHY
   wire          reset_o;        // reset output

   usb_reset dut(.*);

   always #(tclk/2) clk = ~clk;

   initial
     begin:main
	repeat (3) @(posedge clk);
	reset_i = 1'b0;

	#10us line_state = SE0;
	#2.4us line_state = J;

	#10us line_state = SE0;
	#10ms line_state = J;

	#10us $stop;
     end:main
endmodule
