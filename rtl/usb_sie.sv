/* USB Serial Interface Engine */

`default_nettype none

module usb_sie
  (if_transceiver.sie transceiver, // USB tranceiver interface
   if_wb.slave        wb);         // J1 I/O

   import types::*, ioaddr::*;

   logic        valid;
   logic        io_ren, io_ren_r;
   logic        io_wen;
   logic [11:0] io_adr, io_adr_r;
   logic [15:0] usb_tx_control;
   logic [15:0] usb_rx_control;

   enum int unsigned {IDLE, RX, TX[2]} state, next_state;

   /* work around missing modport expressions */
   wire  [15:0] wb_dat_i;
   logic [15:0] wb_dat_o;

`ifdef NO_MODPORT_EXPRESSIONS
   assign wb_dat_i = wb.dat_m;
   assign wb.dat_s = wb_dat_o;
`else
   assign wb_dat_i = wb.dat_i;
   assign wb.dat_o = wb_dat_o;
`endif

   if_fifo txbuf(.rdclk(transceiver.clk), .wrclk(wb.clk), .aclr(transceiver.usb_reset));
   if_fifo rxbuf(.wrclk(transceiver.clk), .rdclk(wb.clk), .aclr(transceiver.usb_reset));

   fifo16x8_show_ahead fifo_txbuf
     (.aclr    (txbuf.aclr),
      .data    (txbuf.data),
      .rdclk   (txbuf.rdclk),
      .rdreq   (txbuf.rdreq),
      .wrclk   (txbuf.wrclk),
      .wrreq   (txbuf.wrreq),
      .q       (txbuf.q),
      .rdempty (txbuf.rdempty),
      .wrfull  (txbuf.wrfull));

   fifo16x8 fifo_rxbuf
     (.aclr    (rxbuf.aclr),
      .data    (rxbuf.data),
      .rdclk   (rxbuf.rdclk),
      .rdreq   (rxbuf.rdreq),
      .wrclk   (rxbuf.wrclk),
      .wrreq   (rxbuf.wrreq),
      .q       (rxbuf.q),
      .rdempty (rxbuf.rdempty),
      .wrfull  (rxbuf.wrfull));

   always_comb txbuf.data           = wb_dat_i;
   always_comb txbuf.wrreq          = io_wen && io_adr == USB_TX_DATA;
   always_comb txbuf.rdreq          = transceiver.tx_ready;
   always_comb transceiver.tx_data  = txbuf.q;
   always_comb transceiver.tx_valid = state == TX0 || state == TX1;

   always_comb rxbuf.data           = transceiver.rx_data;
   always_comb rxbuf.wrreq          = state == RX && transceiver.rx_valid;
   always_comb rxbuf.rdreq          = io_ren && io_adr == USB_RX_DATA;

   always_ff @(posedge wb.clk)
     begin
        io_adr_r <= io_adr;
        io_ren_r <= io_ren;
     end

   always_ff @(posedge wb.clk)
     if (wb.rst)
       usb_tx_control <= '0;
     else
       if (io_ren && io_adr == USB_TX_CONTROL)
         usb_tx_control <= {14'b0, txbuf.wrfull, txbuf.rdempty};

   always_ff @(posedge wb.clk)
     if (wb.rst)
       usb_rx_control <= '0;
     else 
       if (io_ren && io_adr == USB_RX_CONTROL)
       usb_rx_control <= {14'b0, rxbuf.wrfull, rxbuf.rdempty};

   always_comb
     begin
        wb_dat_o = 16'h0;

        if (io_ren_r)
          case(io_adr_r)
            USB_RX_DATA    : wb_dat_o = rxbuf.q;
            USB_TX_CONTROL : wb_dat_o = usb_tx_control;
            USB_RX_CONTROL : wb_dat_o = usb_rx_control;
            default          wb_dat_o = 16'h0;
          endcase
     end

   /************************************************************************
    * FSM
    ************************************************************************/

   always_ff @(posedge transceiver.clk or posedge transceiver.usb_reset)
     if (transceiver.usb_reset)
       state <= IDLE;
     else
       state <= next_state;

   always_comb
     begin
        next_state = state;

        case(state)
          IDLE: 
            if (transceiver.rx_active)
              next_state = RX;
            else if (!txbuf.rdempty)
              next_state = TX0;

          RX: 
            if (!transceiver.rx_active)
              next_state = IDLE;

          TX0:
            if (txbuf.rdempty)
              next_state = TX1;

          TX1:
            if (transceiver.tx_ready) // wait until SE0 has finished
              next_state = IDLE;

          default next_state = IDLE;
        endcase
     end

   /************************************************************************
    * Wishbone control
    * Classic pipelined bus cycles
    ************************************************************************/
   always_comb valid  = wb.cyc & wb.stb;
   always_comb io_ren = valid & ~wb.we;
   always_comb io_wen = valid &  wb.we;
   always_comb io_adr = wb.adr[10:0] << 1;

   always_ff @(posedge wb.clk)
     if (wb.rst)
       wb.ack <= 1'b0;
     else
       wb.ack <= valid;

   assign wb.stall = 1'b0;

`ifdef NOTUSED
   /************************************************************************
    * Validy checks
    ************************************************************************/

   function valid_pid();
      valid_pid = (token.pid == ~token.pidx);
   endfunction

   /*
    * CRC5 = x⁵ + x² + 1
    *
    * If all token bits are received without error the residual will
    * be 5'b01100.
    *
    * Note, that the LSB is sent first hence the polynomial and the
    * residual are reversed.
    */
   function valid_crc5();
      const bit [4:0] crc5_poly = 5'b10100,
		      crc5_res  = 5'b00110;
      logic [15:0] d;
      logic [4:0]  crc5;

      d    = {token.crc5, token.endp, token.addr};
      crc5 = '1;

      for (int i = $right(d); i <= $left(d); i++)
	if (crc5[$right(crc5)] ^ d[i])
	  crc5 = (crc5 >> 1) ^ crc5_poly;
	else
	  crc5 = crc5 >> 1;

      valid_crc5 = (crc5_res == crc5);
   endfunction

   /*
    * CRC16 = x¹⁶ + x¹⁵ + x² + 1
    *
    * If all token bits are received without error the residual will
    * be 16'b1000000000001101.
    *
    * Note, that the LSB is sent first hence the polynomial and the
    * residual are reversed.
    */
   function [15:0] step_crc16(input [7:0] d);
      const bit [15:0] crc16_poly = 16'b1010000000000001;

      step_crc16 = crc16;

      for (int i = $right(d); i <= $left(d); i++)
	if (step_crc16[$right(step_crc16)] ^ d[i])
	  step_crc16 = (step_crc16 >> 1) ^ crc16_poly;
	else
	  step_crc16 = step_crc16 >> 1;
   endfunction

   function valid_crc16(input [15:0] crc16);
      const bit [15:0] crc16_res = 16'b1011000000000001;

      valid_crc16 = (crc16_res == crc16);
   endfunction
`endif
endmodule

`resetall
