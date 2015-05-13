/* Testbench USB-RX */

module tb_usb_rx;
   timeunit 1ns;
   timeprecision 1ps;

   const realtime tbit = 1s/1.5e6, // low speed
		  tclk = 1s/24.0e6;

   import types::*;

   bit          reset = 1;
   bit          clk;
   wire         clk_en;
   var d_port_t d, rx_d, line_state;
   wire [7:0]   data;
   wire         active, valid, error;

   bit          nrzi;
   int          num_ones;
   integer      seed;

   usb_cdr usb_cdr(.*, .q(rx_d), .strobe(clk_en));
   usb_rx dut(.*, .d_i(rx_d));

   always #(tclk/2) clk = ~clk;

   initial
     begin
	repeat (3) @(posedge clk);
	reset = 0;

	#1.234us sync();
	pid(DATA0);
	repeat (8+2) send_byte($random);
	eop();

	#0.345us sync();
	pid(DATA1);
	repeat (8+2) send_byte($random);
	eop();

	repeat (30) @(posedge clk);
	#100ns $stop;
     end

   task nrzi_encode(input x);
      #tbit if (!x) nrzi = ~nrzi;
      d = (nrzi) ? K : J;
   endtask

   task send_bit(input x);
      if (x)
	begin
	   nrzi_encode(1);
	   if (++num_ones == 6)
	     begin
		nrzi_encode(0);
		num_ones = 0;
	     end
	end
      else
	begin
	   nrzi_encode(0);
	   num_ones = 0;
	end
   endtask

   task send_byte(input [7:0] x);
      for (int i = 0; i < 8; i++) send_bit(x[i]);
   endtask

   task idle();
      nrzi     = 0;
      d        = J;
      num_ones = 0;
   endtask

   task sync();
      repeat (7) send_bit(0);
      send_bit(1);
   endtask

   task pid(pid_t x);
      for (int i = 0; i < 4; i++) send_bit(x[i]);
      for (int i = 0; i < 4; i++) send_bit(~x[i]);
   endtask

   task eop();
      #tbit d = SE0;
      #(2*tbit) idle();
   endtask
endmodule
