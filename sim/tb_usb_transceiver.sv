/* Testbench USB-Transceiver
 * RX is connected with TX.
 */

module tb_usb_transceiver;
   timeunit 1ns;
   timeprecision 1ps;

   const realtime tusb=1s/1.5e6, // low speed
		  tclk=1s/24.0e6;

   import types::*;

   bit           reset=1'b1; // reset
   bit           clk;        // system clock (24 MHz)

   /* USB Bus */
   d_port_t      d;          // USB port D+,D-
   var d_port_t  d_i;        // USB port D+,D- (input)
   d_port_t      d_o;        // USB port D+,D- (output)
   wire          d_en;       // USB port D+,D- (enable)
   wire          usb_reset;  // USB reset due to SE0 for 10 ms

   if_transceiver transceiver();
   
   usb_transceiver usb_transceiver(.*);

   assign d_i=d;
   assign d  =d_port_t'{(d_en)?d_o:2'bz};

   initial forever #(tclk/2) clk=~clk;

   always @(posedge clk)
     if(transceiver.tx_ready)
       transceiver.tx_data=$random;

   initial
     begin
	repeat(3) @(posedge clk);
	reset=1'b0;

	repeat(10) @(posedge clk);
	transceiver.tx_valid<=1'b1; transceiver.tx_data<=8'hc3;
	repeat(16*8*100) @(posedge clk);
	transceiver.tx_valid=1'b0;

	repeat(16*8*3) @(posedge clk);
	$stop;
     end
endmodule
