/* USB Transceiver */

module usb_transceiver
  import types::*;
   (input              reset,     // reset
    input              clk,       // system clock (24 MHz)

    /* USB Bus */
    input  d_port_t    d_i,       // USB port D+,D- (input)
    output d_port_t    d_o,       // USB port D+,D- (output)
    output             d_en,      // USB port D+,D- (enable)

    if_transceiver.phy transceiver);

   wire     rx_clk_en;  // RX clock enable
   d_port_t rx_d_i;     // RX data from CDR
   d_port_t line_state; // synchronized D+,D-
   logic    rx_reset;

   usb_reset ubs_reset(.reset_i(reset),.clk(clk),
		       .line_state(line_state),.reset_o(transceiver.usb_reset));

   usb_cdr usb_cdr(.reset(reset),.clk(clk),
		   .d(d_i),.q(rx_d_i),
 		   .line_state(line_state),.strobe(rx_clk_en));

   usb_rx usb_rx(.reset(rx_reset),.clk(clk),.clk_en(rx_clk_en),
		 .d_i(rx_d_i),
		 .data(transceiver.rx_data),.active(transceiver.rx_active),
		 .valid(transceiver.rx_valid),.error(transceiver.rx_error));

   usb_tx usb_tx(.reset(transceiver.usb_reset),.clk(clk),
		 .d_o(d_o),.d_en(d_en),
		 .data(transceiver.tx_data),.valid(transceiver.tx_valid),.ready(transceiver.tx_ready));

   assign rx_reset = transceiver.usb_reset | transceiver.tx_valid;
endmodule
