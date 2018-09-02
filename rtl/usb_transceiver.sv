/* USB Transceiver */

module usb_transceiver
  import types::*;
   (input  wire        reset,          // reset
    input  wire        usb_full_speed, // 0: USB low-speed 1:USB full-speed
    /* USB Bus */
    input  d_port_t    d_i,            // USB port D+, D- (input)
    output d_port_t    d_o,            // USB port D+, D- (output)
    output wire        d_en,           // USB port D+, D- (enable)
    if_transceiver.phy transceiver);   // USB tranceiver interface

   wire     cdr_d;      // filtered USB port data
   wire     rx_clk_en;  // RX clock enable
   wire     rx_d_i;     // RX data from CDR
   wire     eop;        // end of packet
   wire     se0;        // SE0 state
   logic    rx_reset;   // RX reset

   usb_reset ubs_reset
     (.reset_i (reset),
      .clk     (transceiver.clk),
      .se0     (se0),
      .reset_o (transceiver.usb_reset));

   usb_filter usb_filter
     (.clk (transceiver.clk),
      .d   (d_i),
      .q   (cdr_d),
      .se0 (se0));

   usb_cdr usb_cdr
     (.reset          (reset),
      .clk            (transceiver.clk),
      .d              (cdr_d),
      .se0            (se0),
      .usb_full_speed (usb_full_speed),
      .q              (rx_d_i),
      .en             (rx_clk_en),
      .eop            (eop));

   usb_rx usb_rx
     (.reset  (rx_reset),
      .clk    (transceiver.clk),
      .clk_en (rx_clk_en),
      .d_i    (rx_d_i),
      .eop    (eop),
      .data   (transceiver.rx_data),
      .active (transceiver.rx_active),
      .valid  (transceiver.rx_valid),
      .error  (transceiver.rx_error));

   usb_tx usb_tx
     (.reset (transceiver.usb_reset),
      .clk   (transceiver.clk),
      .d_o   (d_o),
      .d_en  (d_en),
      .data  (transceiver.tx_data),
      .valid (transceiver.tx_valid),
      .ready (transceiver.tx_ready));

   always_comb rx_reset = transceiver.usb_reset | d_en;
endmodule
