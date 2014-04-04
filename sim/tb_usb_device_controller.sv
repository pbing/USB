module tb_usb_device_controller;
   timeunit 1ns;
   timeprecision 1ps;

   const realtime tusb=1s/1.5e6, // low speed
		  tclk=1s/24.0e6;

   import types::*;

   bit      reset=1'b1; // reset
   bit      clk;        // system clock (24 MHz)
   d_port_t d_i;        // USB port D+;D- (bit)
   d_port_t d_o;        // USB port D+;D- (wire)
   wire     d_en;       // USB port D+;D- (enable)
   if_io    io();       // I/O interface to J1 processor

   usb_device_controller dut(.*);

   initial forever #(tclk/2) clk=~clk;

   initial
     begin:main
	io.addr=16'h0;
	io.dout=16'h0;
	io.rd  =1'b0;
	io.wr  =1'b0;
	
	repeat(3) @(posedge clk);
	reset=1'b0;

	#3us $stop;
     end:main
endmodule
