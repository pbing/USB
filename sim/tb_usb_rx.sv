/* Testbench USB-RX */

module tb_usb_rx;
   timeunit 1ns;
   timeprecision 1ps;

   import types::*;

   const realtime tbit = 1s / ((7 * USB_FULL_SPEED + 1) * 1.5e6),
		  tclk = tbit / 4;

   import types::*;

   var d_port_t d;
   wire         cdr_eop, se0;

   bit          reset;
   bit          clk;
   wire         clk_en;
   wire         d_f;
   wire         d_i;
   wire [7:0]   data;
   wire         active, valid, error;
   bit          nrzi;
   int          num_ones;

   integer      seed;

   usb_filter usb_filter(.q(d_f), .*);

   usb_cdr usb_cdr (.usb_full_speed(USB_FULL_SPEED), 
                    .d(d_f), .q(d_i), .en(clk_en),
                    .eop(cdr_eop), .*);

   usb_rx dut(.eop(cdr_eop), .*);

   always #(tclk/2) clk = ~clk;

   initial
     begin
	reset = 1'b1;
	repeat (3) @(posedge clk);
	reset = 1'b0;

	#(1.234*tbit) sync();
	pid(DATA0);
	repeat (8 + 2) send_byte($random);
	eop();

	#(0.567*tbit) sync();
	pid(DATA1);
	repeat (8 + 2) send_byte($random);
	eop();

	repeat (30) @(posedge clk);
	#100ns $finish;
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
