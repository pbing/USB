`default_nettype none

module tb_usb_cdr;
   timeunit 1ns;
   timeprecision 1ps;

   import types::*;

   const realtime tbit = 1s / ((7 * USB_FULL_SPEED + 1) * 1.5e6),
		  tclk = tbit / 4;

   var real     k;         // time coefficient
   var d_port_t d;         // USB data
   
   bit     reset;          // system reset
   bit     clk;            // USB clock
   bit     d_f;            // filtered data from PHY
   bit     se0;            // SE0 state
   bit     usb_full_speed; // 0: USB low-speed 1:USB full-speed
   wire    q;              // retimed data
   wire    en;             // data enable
   wire    eop;            // end of packet

   usb_filter usb_filter(.q(d_f), .*);

   usb_cdr usb_cdr(.d(d_f), .*);

   always #(tclk / 2) clk = ~clk;

   initial
     begin
        usb_full_speed = USB_FULL_SPEED;
        reset = 1'b1;
        #(2 * tclk) reset = 1'b0;

	d = J;

	if($test$plusargs("slow"))
	  k = 1.01;
	else if($test$plusargs("fast"))
	  k = 0.99;
	else
	  k = 1.0;

	$display("k = %f", k);


	/* SYNC */
	#(10.3 * tclk);
	repeat (7) #(k * tbit) d = (d == J) ? K : J;
	#(2 * k * tbit);

	/* data */
	repeat (64) #(k * tbit) d = ({$random} % 2) ? K : J;

	/* EOP */
	#(k * tbit)   d = SE0;
	#(2 * k * tbit) d = J;

	#(10 * tclk) $finish;
     end
endmodule

`resetall
