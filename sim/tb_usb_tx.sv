/* Testbench USB-TX */

module tb_usb_tx;
   timeunit 1ns;
   timeprecision 1ps;

   const realtime tusb = 1s/1.5e6,  // low speed
		  tclk = 1s/24.0e6;

   import types::*;

   bit       reset = 1'b1;
   bit       clk;
   d_port_t  d,d_o;
   wire      d_en;
   bit [7:0] data;
   bit       valid;
   wire      ready;

   integer seed;

   usb_tx dut(.*);

   assign d = d_port_t'{(d_en) ? d_o : 2'bz};

   always #(tclk/2) clk = ~clk;

   always @(posedge clk)
     if (ready)
       data = $random;

   initial
     begin:main
	repeat (3) @(posedge clk);
	reset = 1'b0;

	repeat (10) @(posedge clk);
	valid <= 1'b1; pid(DATA0);
	repeat (16*8*30) @(posedge clk);
	valid = 1'b0;

	repeat (16*8) @(posedge clk);
	$stop;
     end:main

   task pid(pid_t x);
      data <= {x,~x};
   endtask
endmodule
