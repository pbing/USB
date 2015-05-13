module tb_usb_cdr;
   timeunit 1ns;
   timeprecision 1ps;

   import types::*;

   const realtime tclk = 1s/24.0e6,
		  tbit = 1s/1.5e6;

   bit          reset = 1'b1;
   bit          clk;
   var d_port_t d;
   d_port_t     q;
   d_port_t     line_state;
   wire         strobe;

   usb_cdr dut(.*);

   always #(tclk/2) clk = ~clk;

   initial
     begin
	reset <= #(2*tclk) 1'b0;
	d = J;

	if($test$plusargs("neg_phase"))
	  #0.94us $display("phase < 0");
	else if($test$plusargs("pos_phase"))
	  #1.60us $display("phase > 0");
	else
	  #1.23us $display("phase = 0");

	/* SYNC */
	repeat(7) #tbit d = (d == J) ? K : J;
	#(2*tbit);

	repeat(64) #tbit d = ({$random}%2) ? K : J;

	#100ns $stop;
     end
endmodule
