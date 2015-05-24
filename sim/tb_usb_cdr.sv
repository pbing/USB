module tb_usb_cdr;
   timeunit 1ns;
   timeprecision 1ps;

   import types::*;

   const realtime tclk = 1s/((7 * USB_FULL_SPEED + 1) * 6.0e6),
		  tbit = 4 * tclk;

   var real k;

   bit          reset = 1'b1;
   bit          clk;
   var d_port_t d;
   wire         q;
   wire         en;
   wire         eop;
   wire         se0;

   usb_cdr dut(.*);

   always #(tclk/2) clk = ~clk;

   initial
     begin
	reset <= #(2*tclk) 1'b0;
	d = J;

	if($test$plusargs("slow"))
	  k = 1.01;
	else if($test$plusargs("fast"))
	  k = 0.99;
	else
	  k = 1.0;

	$display("k = %f", k);


	/* SYNC */
	#(10.3*tclk);
	repeat (7) #(k*tbit) d = (d == J) ? K : J;
	#(2*k*tbit);

	/* data */
	repeat (64) #(k*tbit) d = ({$random}%2) ? K : J;

	/* EOP */
	#(k*tbit)   d = SE0;
	#(2*k*tbit) d = J;

	#(10*tclk) $stop;
     end
endmodule
