/* Testbench USB-Transceiver
 * RX is connected with TX.
 */

`default_nettype none

module tb_usb_transceiver;
   timeunit 1ns;
   timeprecision 1ps;

   import types::*;

   const realtime tbit = 1s / ((7 * USB_FULL_SPEED + 1) * 1.5e6),
		  tclk = tbit / 4;

   import types::*;

   bit      reset; // reset
   bit      clk;   // clock

   /* USB Bus */
   d_port_t d;     // USB port D+,D-
   d_port_t d_i;   // USB port D+,D- (input)
   d_port_t d_o;   // USB port D+,D- (output)
   wire     d_en;  // USB port D+,D- (enable)
   bit      nrzi;
   int      num_ones;
   d_port_t d_reg;

   if_transceiver transceiver(.*);
   
   usb_transceiver usb_transceiver(.usb_full_speed(USB_FULL_SPEED), .*);

   assign d_i = d;
   assign d   = d_port_t'{(d_en) ? d_o : d_reg};

   always #(tclk / 2) clk = ~clk;

   always @(posedge clk)
     if(transceiver.tx_ready)
       transceiver.tx_data = $random;

   initial
     begin
	reset = 1'b1;
	repeat(3) @(posedge clk);
	reset = 1'b0;
	repeat (30) @(posedge clk);

        /* RX */
	#(1.234*tbit) sync();
	pid(DATA0);
	repeat (8 + 2) send_byte($random);
	eop();

	#(0.567*tbit) sync();
	pid(DATA1);
	repeat (8 + 2) send_byte($random);
	eop();

	repeat (30) @(posedge clk);

        /* TX */
	transceiver.tx_valid <= 1'b1; 
        transceiver.tx_data  <= 8'hc3;

	repeat(4 * 8 * 100) @(posedge clk);
	transceiver.tx_valid = 1'b0;

	repeat(4 * 8 * 3) @(posedge clk);

	#100ns $finish;
     end

   task nrzi_encode(input x);
      #tbit if (!x) nrzi = ~nrzi;
      d_reg = (nrzi) ? K : J;
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
      d_reg    = J;
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
      #tbit d_reg = SE0;
      #(2*tbit) idle();
   endtask
endmodule

`resetall
