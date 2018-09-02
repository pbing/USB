/* USB device controller */

// Quartus doesn't like 'input  wire d_port_t d_i'
//`default_nettype none

module usb_device_controller
  import types::*;
   (input  wire     reset,          // reset
    input  wire     clk,            // USB clock
    input  wire     usb_full_speed, // 0: USB low-speed 1:USB full-speed
    input  d_port_t d_i,            // USB port D+,D- (input)
    output d_port_t d_o,            // USB port D+,D- (output)
    output wire     d_en,           // USB port D+,D- (enable)
    if_wb.slave     wb);            // Wishbone interface

   if_transceiver transceiver
     (.clk);

   usb_transceiver usb_transceiver
     (.reset,
      .usb_full_speed,
      .d_i,
      .d_o,
      .d_en,
      .transceiver);

   usb_sie usb_sie
     (.transceiver,
      .wb);
endmodule

//`resetall
