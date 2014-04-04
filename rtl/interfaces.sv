/* Interfaces */

interface if_transceiver;
   /* control */
   logic        usb_reset; // USB reset due to SE0 for 10 ms

   /* TX */
   logic [7:0] tx_data;   // data from SIE
   logic       tx_valid;  // rise:SYNC,1:send data,fall:EOP
   logic       tx_ready;  // data has been sent

   /* RX */
   logic [7:0] rx_data;   // data to SIE
   logic       rx_active; // active between SYNC und EOP
   logic       rx_valid;  // data valid pulse
   logic       rx_error;  // error detected

   modport sie(input usb_reset,output tx_data,output tx_valid,input tx_ready,
               input rx_data,input rx_active,input rx_valid,input rx_error);

   modport phy(input usb_reset,input tx_data,input tx_valid,output tx_ready,
               output rx_data,output rx_active,output rx_valid,output rx_error);
endinterface:if_transceiver

interface if_fifo #(parameter addr_width=4,data_width=8);
   logic [data_width-1:0] data;   // input data
   logic [data_width-1:0] q;      // output data
   logic [addr_width-1:0] usedw;  // used words
   logic                  sclr;   // synchronous clear (flush FIFO)
   logic                  rdreq;  // read request
   logic                  wrreq;  // write request
   logic                  empty;  // FIFO empty
   logic                  full;   // FIFO full

   modport master(output data,input q,input usedw,output sclr,output rdreq,output wrreq,input empty,input full);

   modport slave(input data,output q,output usedw,input sclr,input rdreq,input wrreq,output empty,output full);
endinterface:if_fifo

interface if_io;
   logic [15:0] din;  // io data in
   logic        rd;   // io read
   logic        wr;   // io write
   logic [15:0] addr; // io address
   logic [15:0] dout; // io data out

   modport master(input din,output rd,output wr,output addr,output dout);

   modport slave(output din,input rd,input wr,input addr,input dout);
endinterface:if_io
