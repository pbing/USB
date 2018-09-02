/* USB Serial Interface Engine */

`default_nettype none

module usb_sie
  (if_transceiver.sie transceiver, // USB tranceiver interface
   if_wb.slave        wb);         // J1 I/O

   import types::*, ioaddr::*;

   logic        valid;
   logic        io_ren;
   logic        io_wen;
   wire  [11:0] io_adr;

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

   var token_t      token;
   var usb_status_t usb_status;

   logic [6:0]  device_addr;  // FIXME assigned device address
   logic [15:0] crc16;        // CRC16

   logic        endp_empty, endp_full,
		endp_rdreq, endp_wrreq,
		endp_stall, endp_ack;
   logic [7:0]  endp_q;
   logic        endpi0_stall, endpi1_stall;
   logic        endpi0_ack, endpi1_ack;

   if_fifo endpi0(.rdclk(transceiver.clk), .wrclk(wb.clk), .aclr(transceiver.usb_reset));
   if_fifo endpi1(.rdclk(transceiver.clk), .wrclk(wb.clk), .aclr(transceiver.usb_reset));
   if_fifo endpo0(.wrclk(transceiver.clk), .rdclk(wb.clk), .aclr(transceiver.usb_reset));

   fifo16x8 fifo_endpi0
     (.aclr    (endpi0.aclr),
      .data    (endpi0.data),
      .rdclk   (endpi0.rdclk),
      .rdreq   (endpi0.rdreq),
      .wrclk   (endpi0.wrclk),
      .wrreq   (endpi0.wrreq),
      .q       (endpi0.q),
      .rdempty (endpi0.rdempty),
      .wrfull  (endpi0.wrfull));

   fifo16x8 fifo_endpi1
     (.aclr    (endpi1.aclr),
      .data    (endpi1.data),
      .rdclk   (endpi1.rdclk),
      .rdreq   (endpi1.rdreq),
      .wrclk   (endpi1.wrclk),
      .wrreq   (endpi1.wrreq),
      .q       (endpi1.q),
      .rdempty (endpi1.rdempty),
      .wrfull  (endpi1.wrfull));

   fifo16x8_show_ahead fifo_endpo0
     (.aclr    (endpo0.aclr),
      .data    (endpo0.data),
      .rdclk   (endpo0.rdclk),
      .rdreq   (endpo0.rdreq),
      .wrclk   (endpo0.wrclk),
      .wrreq   (endpo0.wrreq),
      .q       (endpo0.q),
      .rdempty (endpo0.rdempty),
      .wrfull  (endpo0.wrfull)); 

   /************************************************************************
    * packet FSM
    ************************************************************************/
   enum int unsigned {S_TOKEN[3], S_DATA_OUT[2], S_DATA_IN[6], S_ACK, S_NAK, S_STALL, S_LAST_BIT} fsm_packet_state, fsm_packet_next;

   always_ff @(posedge transceiver.clk)
     if (transceiver.usb_reset)
       fsm_packet_state <= S_TOKEN0;
     else
       fsm_packet_state <= fsm_packet_next;

   always_comb
     begin
	var pid_t   pid;
	logic [6:0] addr;

	pid             = pid_t'(transceiver.rx_data[3:0]);
	addr            = transceiver.rx_data[6:0];
	fsm_packet_next = fsm_packet_state;

	case (fsm_packet_state)
	  /* token packet */
	  S_TOKEN0:
	    case (pid)
	      OUT, IN, SETUP:
		if (transceiver.rx_valid) fsm_packet_next = S_TOKEN1;

	      default
		fsm_packet_next = S_TOKEN0;
	    endcase

	  S_TOKEN1:
	    if (transceiver.rx_valid)
	      if (1'b1 /*addr == device_addr*/) // ignore address because only one device
		fsm_packet_next = S_TOKEN2;
	      else
		fsm_packet_next = S_TOKEN0;

	  S_TOKEN2:
	    if (transceiver.rx_valid)
	      case (token.pid)
		SETUP:
		  if (token.endp == 4'd0)
		    fsm_packet_next = S_DATA_OUT0; // Device_do_OUT
		  else
		    fsm_packet_next = S_TOKEN0;

		OUT:
		  fsm_packet_next = S_DATA_OUT0; // Device_do_OUT
	      endcase
	    else
	      if (!transceiver.rx_active)
		case (token.pid)
		  IN:
		    if (endp_stall)
		      fsm_packet_next = S_STALL;
		    else if (!endp_ack)
		      fsm_packet_next = S_NAK;
		    else
		      fsm_packet_next = S_DATA_IN0;  // Device_do_IN

		  default
		    fsm_packet_next = S_TOKEN0;
		endcase

	  /* data packet */
	  S_DATA_OUT0:
	    if (transceiver.rx_valid)
	      if (!endp_full && (pid == DATA0 || (pid == DATA1 && token.pid != SETUP)))
		fsm_packet_next = S_DATA_OUT1;
	      else
		fsm_packet_next = S_TOKEN0;

	  S_DATA_OUT1:
	    begin
	       if (endp_full && transceiver.rx_valid)
		 fsm_packet_next = S_TOKEN0;
	       else
		 if (!transceiver.rx_active)
		   if (valid_crc16(crc16))
		     fsm_packet_next = S_ACK;
		   else
		     fsm_packet_next = S_TOKEN0;
	    end

	  S_DATA_IN0:
	    if (transceiver.tx_ready)
	      if (endp_ack)
		fsm_packet_next = S_DATA_IN1;
	      else
		fsm_packet_next = S_DATA_IN3;

	  S_DATA_IN1:
	    fsm_packet_next = S_DATA_IN2;

	  S_DATA_IN2:
	    if (transceiver.tx_ready)
	      if (!endp_empty)
		fsm_packet_next = S_DATA_IN1;
	      else
		fsm_packet_next = S_DATA_IN3;

	  S_DATA_IN3:
	    if (transceiver.tx_ready)
	      fsm_packet_next = S_DATA_IN4;

	  S_DATA_IN4:
	    if (transceiver.tx_ready)
	      fsm_packet_next = S_DATA_IN5;

	  S_DATA_IN5:
	    if (transceiver.tx_ready)
	      fsm_packet_next = S_TOKEN0;

	  /* handshake packet */
	  S_ACK, S_NAK, S_STALL:
	    if (transceiver.tx_ready)
	      fsm_packet_next = S_LAST_BIT;

	  S_LAST_BIT:
	    if (transceiver.tx_ready)
	      fsm_packet_next = S_TOKEN0;
	endcase
     end

   /************************************************************************
    * Store token
    ************************************************************************/
   always_ff @(posedge transceiver.clk)
     if (transceiver.usb_reset)
       begin
	  token.pidx <= 4'b0;
	  token.pid  <= RESERVED;
	  token.addr <= 7'd0;
	  token.endp <= 4'd0;
	  token.crc5 <= 5'h0;
       end
     else
       case (fsm_packet_state)

	 /* Save values during TOKEN stage. */
	 S_TOKEN0:
	   if (transceiver.rx_valid)
	     begin
		token.pidx <=        transceiver.rx_data[7:4];
		token.pid  <= pid_t'(transceiver.rx_data[3:0]);
	     end

	 S_TOKEN1:
	   if (transceiver.rx_valid)
	     begin
		token.addr    <= transceiver.rx_data[6:0];
		token.endp[0] <= transceiver.rx_data[7];
	     end

	 S_TOKEN2:
	   if (transceiver.rx_valid)
	     begin
		token.endp[3:1] <= transceiver.rx_data[2:0];
		token.crc5      <= transceiver.rx_data[7:3];
	     end
       endcase

   /************************************************************************
    * Calculate CRC16
    ************************************************************************/
   always_ff @(posedge transceiver.clk)
     if (transceiver.usb_reset)
       crc16 <= 16'hffff;
     else
       case (fsm_packet_state)
	 S_DATA_OUT0, S_DATA_IN0:
	   crc16 <= 16'hffff;

	 S_DATA_OUT1:
	   if (transceiver.rx_valid)
	     crc16 <= step_crc16(transceiver.rx_data);

	 S_DATA_IN1:
	   crc16 <= step_crc16(transceiver.tx_data);
       endcase

   /************************************************************************
    * Write data to host
    ************************************************************************/
   always_comb
     begin
	endp_rdreq           = 1'b0;
	transceiver.tx_valid = 1'b0;
	transceiver.tx_data  = 8'b0; // avoid X for NRZI

	case (fsm_packet_state)
	  S_DATA_IN0:
	    begin
	       transceiver.tx_data  = {~DATA1, DATA1};
	       transceiver.tx_valid = 1'b1;

	       if (transceiver.tx_ready && endp_ack)
		 endp_rdreq = 1'b1;
	    end

	  S_DATA_IN1:
	    begin
	       transceiver.tx_data  = endp_q;
	       transceiver.tx_valid = 1'b1;
	    end

	  S_DATA_IN2:
	    begin
	       transceiver.tx_data  = endp_q;
	       transceiver.tx_valid = 1'b1;

	       if (!endp_empty && transceiver.tx_ready)
		 endp_rdreq = 1'b1;
	    end

	  S_DATA_IN3:
	    begin
	       transceiver.tx_data  = ~crc16[7-:8];
	       transceiver.tx_valid = 1'b1;
	    end

	  S_DATA_IN4:
	    begin
	       transceiver.tx_data  = ~crc16[15-:8];
	       transceiver.tx_valid = 1'b1;
	    end

	  S_DATA_IN5:
	    transceiver.tx_valid = 1'b1;

	  S_ACK:
	    begin
	       transceiver.tx_data  = {~ACK, ACK};
	       transceiver.tx_valid = 1'b1;
	    end

	  S_NAK:
	    begin
	       transceiver.tx_data  = {~NAK, NAK};
	       transceiver.tx_valid = 1'b1;
	    end

	  S_STALL:
	    begin
	       transceiver.tx_data  = {~STALL, STALL};
	       transceiver.tx_valid = 1'b1;
	    end

	  S_LAST_BIT:
	    transceiver.tx_valid = 1'b1;
	endcase
     end

   /************************************************************************
    * Write data to device
    ************************************************************************/
   always_comb
     begin
	endp_wrreq = 1'b0;

	case (fsm_packet_state)
	  S_DATA_OUT1:
	    if (transceiver.rx_valid)
	      endp_wrreq = 1'b1;
	endcase
     end

   /************************************************************************
    * Endpoint interface
    ************************************************************************/
   assign io_adr = wb.adr[10:0] << 1;

   always_comb endpo0.rdreq = io_adr == ENDPO0_DATA && io_ren;

   always_comb
     begin
	endp_empty = 1'bx;
	endp_full  = 1'bx;
	endp_q     = 8'bx;
	endp_stall = 1'bx;
	endp_ack   = 1'bx;

	case (token.endp)
	  4'd0:
	    begin
	       endp_empty = endpi0.rdempty;
	       endp_q     = endpi0.q;
	       endp_ack   = endpi0_ack;
	       endp_stall = endpi0_stall;
	       endp_full  = endpo0.wrfull;
	    end

	  4'd1:
	    begin
	       endp_empty = endpi1.rdempty;
	       endp_q     = endpi1.q;
	       endp_ack   = endpi1_ack;
	       endp_stall = endpi1_stall;
	    end
	endcase
     end

   always_ff @(posedge wb.clk)
     if (wb.rst)
       wb_dat_o <= 16'h0;
     else
       if (io_ren)
         begin
            wb_dat_o <= 16'h0;

            case (io_adr)
	      ENDPI0_CONTROL: wb_dat_o[0]   <= endpi0.wrfull;
	      ENDPI1_CONTROL: wb_dat_o[0]   <= endpi1.wrfull;
	      ENDPO0_CONTROL: wb_dat_o[0]   <= endpo0.rdempty;
	      ENDPO0_DATA   : wb_dat_o[7:0] <= endpo0.q;
	      USB_ADDRESS   : wb_dat_o[6:0] <= device_addr;

	      USB_TOKEN:
	        begin
	           case (token.pid)
		     OUT  : wb_dat_o[5:4] <= 2'b01;
		     IN   : wb_dat_o[5:4] <= 2'b10;
		     SETUP: wb_dat_o[5:4] <= 2'b11;
	           endcase

	           wb_dat_o[3:0] <= token.endp;
	        end

	      USB_STATUS: 
	        begin
	           wb_dat_o[6] <= usb_status.bto;
	           wb_dat_o[5] <= usb_status.crc16;
	           wb_dat_o[4] <= usb_status.crc5;
	           wb_dat_o[3] <= usb_status.pid;
	           wb_dat_o[2] <= usb_status.usb_reset;
	           wb_dat_o[1] <= usb_status.stall;
	           wb_dat_o[0] <= usb_status.token_done;
	        end
            endcase
         end

   always_comb
     begin
	endpi0.data  = wb_dat_i;
	endpi0.rdreq = 1'b0;
	endpi0.wrreq = 1'b0;

	endpi1.data  = wb_dat_i;
	endpi1.wrreq = 1'b0;
	endpi1.rdreq = 1'b0;

	endpo0.data  = transceiver.rx_data;
	endpo0.wrreq = 1'b0;

	case (token.endp)
	  4'd0:
	    begin
	       endpi0.rdreq = endp_rdreq;
	       endpo0.wrreq = endp_wrreq;
	    end

	  4'd1:
	    endpi1.rdreq = endp_rdreq;
	endcase

	if (io_wen)
	  case (io_adr)
	    ENDPI0_DATA: endpi0.wrreq = 1'b1;
	    ENDPI1_DATA: endpi1.wrreq = 1'b1;
	  endcase
     end

   always_ff @(posedge transceiver.clk)
     if (transceiver.usb_reset)
       begin
	  endpi0_stall <= 1'b0;
	  endpi0_ack   <= 1'b0;
       end
     else
       begin
	  if (io_wen && io_adr == ENDPI0_CONTROL)
	    begin
	       endpi0_stall <= wb_dat_i[2];
	       endpi0_ack   <= wb_dat_i[1];
	    end

	  if (token.endp == 4'd0)
	    begin
	       if ((fsm_packet_state == S_TOKEN2) && (token.pid == SETUP))
		 endpi0_stall <= 1'b0;

	       if (fsm_packet_state == S_DATA_IN3)
		 endpi0_ack <= 1'b0;
	    end
       end

   always_ff @(posedge transceiver.clk)
     if (transceiver.usb_reset)
       begin
	  endpi1_stall <= 1'b0;
	  endpi1_ack   <= 1'b0;
       end
     else
       begin
	  if (io_wen && io_adr == ENDPI1_CONTROL)
	    begin
	       endpi1_stall <= wb_dat_i[2];
	       endpi1_ack   <= wb_dat_i[1];
	    end

	  if (token.endp == 4'd1)
	    begin
	       if (fsm_packet_state == S_STALL)
		 endpi1_stall <= 1'b0;

	       if (fsm_packet_state == S_DATA_IN3)
		 endpi1_ack <= 1'b0;
	    end
       end

   /************************************************************************
    * USB_ADDRESS register
    ************************************************************************/
   always_ff @(posedge wb.clk)
     if (wb.rst)
       device_addr <= 7'h0;
     else
       if (io_wen && io_adr == USB_ADDRESS)
	 device_addr <= wb_dat_i[6:0];

   /************************************************************************
    * USB_STATUS register
    ************************************************************************/
   always_ff @(posedge transceiver.clk)
     if (transceiver.usb_reset)
       begin
	  usb_status.bto        <= 1'b0;
	  usb_status.crc16      <= 1'b0;
	  usb_status.crc5       <= 1'b0;
	  usb_status.pid        <= 1'b0;
	  usb_status.usb_reset  <= 1'b0;
	  usb_status.stall      <= 1'b0;
	  usb_status.token_done <= 1'b0;
       end
     else
       begin
	  if (io_wen && io_adr == USB_STATUS)
	    begin
	       var usb_status_t clear;

	       clear = usb_status_t'(wb_dat_i[6:0]);

	       if (clear.bto)        usb_status.bto        <= 1'b0;
	       if (clear.crc16)      usb_status.crc16      <= 1'b0;
	       if (clear.crc5)       usb_status.crc5       <= 1'b0;
	       if (clear.pid)        usb_status.pid        <= 1'b0;
	       if (clear.usb_reset)  usb_status.usb_reset  <= 1'b0;
	       if (clear.stall)      usb_status.stall      <= 1'b0;
	       if (clear.token_done) usb_status.token_done <= 1'b0;
	    end

	  case (fsm_packet_state)
	    S_DATA_OUT0, S_DATA_IN0:
	      begin
		 usb_status.crc5 <= !valid_crc5();
		 usb_status.pid  <= !valid_pid();
	      end

	    S_ACK, S_NAK, S_STALL,             // SETUP, OUT
	      S_DATA_IN5:                      // IN (FIXME Wait for ACK of host.)
		usb_status.token_done <= 1'b1;
	  endcase
       end

   /************************************************************************
    * Wishbone control
    * Classic pipelined bus cycles
    ************************************************************************/

   always_comb io_ren = valid & ~wb.we;
   always_comb io_wen = valid &  wb.we;

   always_comb valid = wb.cyc & wb.stb;

   always_ff @(posedge wb.clk)
     if (wb.rst)
       wb.ack <= 1'b0;
     else
       wb.ack <= valid;

   assign wb.stall = 1'b0;

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
endmodule

`resetall
