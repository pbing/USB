/* Interfaces */

`default_nettype none

interface if_transceiver
  (input wire   clk);      // USB clock
   /* control */
   logic        usb_reset; // USB reset due to SE0 for 10 ms

   /* TX */
   logic [7:0] tx_data;   // data from SIE
   logic       tx_valid;  // rise:SYNC, 1:send data, fall:EOP
   logic       tx_ready;  // data has been sent

   /* RX */
   logic [7:0] rx_data;   // data to SIE
   logic       rx_active; // active between SYNC und EOP
   logic       rx_valid;  // data valid pulse
   logic       rx_error;  // error detected

   modport sie(input  clk,
	       input  usb_reset, 
               output tx_data, 
               output tx_valid,
               input  tx_ready,
               input  rx_data, 
               input  rx_active,
               input  rx_valid,
               input  rx_error);

   modport phy(input  clk,
	       output usb_reset,
               input  tx_data,
               input  tx_valid,
               output tx_ready,
               output rx_data,
               output rx_active,
               output rx_valid, 
               output rx_error);
endinterface:if_transceiver

interface if_fifo 
   (input wire rdclk,   // read clock
    input wire wrclk,   // write clock
    input wire aclr);   // asynchronous clear
   logic [7:0] data;    // input data
   logic [7:0] q;       // output data
   logic       rdreq;   // read request
   logic       wrreq;   // write request
   logic       rdempty; // FIFO empty
   logic       wrfull;  // FIFO full
endinterface:if_fifo

`default_nettype none
