/* USB Serial Interface Controller */

module usb_sie(input              clk,         // 24 MHz system clock
	       if_transceiver.sie transceiver, // USB tranceiver interface
	       if_fifo.master     endpi0,      // endpoint in 0
	       if_fifo.master     endpo0,      // endpoint out 0
	       if_fifo.master     endpi1);     // endpoint in 1

   import types::*;

   var token_t token;

   logic [6:0]  device_addr;  // FIXME assigned device address
   logic        packet_ready; // FIXME fsm_packet_state != S_TOKEN0 && transceiver.eop?
   logic [15:0] crc16;        // CRC16

   logic        fifo_empty,fifo_full,
		fifo_rdreq,fifo_wrreq;
   logic [7:0]  fifo_q;

   /************************************************************************
    * Packet FSM
    ************************************************************************/
   enum int unsigned {S_TOKEN[3],S_DATA_OUT[3],S_DATA_IN[5],S_ACK,S_NAK,S_STALL} fsm_packet_state,fsm_packet_next;

   always_ff @(posedge clk)
     if (transceiver.usb_reset)
       fsm_packet_state <= S_TOKEN0;
     else
       fsm_packet_state <= fsm_packet_next;

   always_comb
     begin
	var pid_t pid;

	pid             = pid_t'(transceiver.rx_data[3:0]);
	fsm_packet_next = fsm_packet_state;

	case (fsm_packet_state)
	  /* token packet */
	  S_TOKEN0:
	    case (pid)
	      OUT,IN,SETUP:
		if (transceiver.rx_valid) fsm_packet_next = S_TOKEN1;

	      default
		fsm_packet_next = S_TOKEN0;
	    endcase

	  S_TOKEN1:
	    if (transceiver.rx_valid) fsm_packet_next = S_TOKEN2;

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
		if (token.pid == IN)
		  fsm_packet_next=S_DATA_IN0;  // Device_do_IN
		else
		  fsm_packet_next=S_TOKEN0;

	  /* data packet */
	  S_DATA_OUT0:
	    if (transceiver.rx_valid)
	      if (!fifo_full && (pid == DATA0 || (pid == DATA1 && token.pid != SETUP)))
		fsm_packet_next = S_DATA_OUT1;
	      else
		fsm_packet_next = S_TOKEN0;

	  S_DATA_OUT1:
	    begin
	       if (fifo_full && transceiver.rx_valid)
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
	      fsm_packet_next = S_DATA_IN1;

	  S_DATA_IN1:
	    fsm_packet_next = S_DATA_IN2;

	  S_DATA_IN2:
	    if (transceiver.tx_ready)
	      if (!fifo_empty)
		fsm_packet_next = S_DATA_IN1;
	      else
		fsm_packet_next = S_DATA_IN3;

	  S_DATA_IN3:
	    if (transceiver.tx_ready)
	      fsm_packet_next = S_DATA_IN4;

	  S_DATA_IN4:
	    if (transceiver.tx_ready)
	      fsm_packet_next = S_TOKEN0;

	  /* handshake packet */
	  S_ACK,S_NAK,S_STALL:
	    if (transceiver.tx_ready)
	      fsm_packet_next = S_TOKEN0;
	endcase
     end

   /************************************************************************
    * Store token
    ************************************************************************/
   always_ff @(posedge clk)
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
   always_ff @(posedge clk)
     if (transceiver.usb_reset)
       crc16 <= 16'hffff;
     else
       case (fsm_packet_state)
	 S_DATA_OUT0,S_DATA_IN0:
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
	fifo_rdreq           = 1'b0;
	transceiver.tx_valid = 1'b0;
	transceiver.tx_data  = 8'bx;

	case (fsm_packet_state)
	  S_DATA_IN0:
	    begin
	       transceiver.tx_data  = {~DATA0,DATA0};
	       transceiver.tx_valid = 1'b1;

	       if (transceiver.tx_ready)
		 fifo_rdreq = 1'b1;
	    end

	  S_DATA_IN1:
	    begin
	       transceiver.tx_data  = fifo_q;
	       transceiver.tx_valid = 1'b1;
	    end

	  S_DATA_IN2:
	    begin
	       transceiver.tx_data  = fifo_q;
	       transceiver.tx_valid = 1'b1;

	       if (!fifo_empty && transceiver.tx_ready)
		 fifo_rdreq = 1'b1;
	    end

	  S_DATA_IN3:
	    begin
	       for (int i=0;i<8;i++)
		 transceiver.tx_data[i] = ~crc16[7-i];

	       transceiver.tx_valid = 1'b1;
	    end

	  S_DATA_IN4:
	    begin
	       for (int i=0;i<8;i++)
		 transceiver.tx_data[i] = ~crc16[15-i];

	       transceiver.tx_valid = 1'b1;
	    end

	  S_ACK:
	    begin
	       transceiver.tx_data  = {~ACK,ACK};
	       transceiver.tx_valid = 1'b1;
	    end

	  S_NAK:
	    begin
	       transceiver.tx_data  = {~NAK,NAK};
	       transceiver.tx_valid = 1'b1;
	    end

	  S_STALL:
	    begin
	       transceiver.tx_data  = {~STALL,STALL};
	       transceiver.tx_valid = 1'b1;
	    end
	endcase
     end

   /************************************************************************
    * Write data to device
    ************************************************************************/
   always_comb
     begin
	fifo_wrreq = 1'b0;

	case (fsm_packet_state)
	  S_DATA_OUT1,S_DATA_OUT2:
	    if (transceiver.rx_valid)
	      fifo_wrreq = 1'b1;
	endcase
     end

   /************************************************************************
    * Endpoint interface
    ************************************************************************/
   always_comb
     begin
	endpi0.sclr = transceiver.usb_reset;
	endpo0.sclr = transceiver.usb_reset;
	endpi1.sclr = transceiver.usb_reset;
     end

   always_comb
     endpo0.data = transceiver.rx_data;

   always_comb
     begin
	fifo_full  = 1'bx;
	fifo_empty = 1'bx;
	fifo_q     = 8'bx;

	case (token.endp)
	  4'd0:
	    begin
	       fifo_full  = endpo0.full;
	       fifo_empty = endpi0.empty;
	       fifo_q     = endpi0.q;
	    end

	  4'd1:
	    begin
	       fifo_empty = endpi1.empty;
	       fifo_q     = endpi1.q;
	    end
	endcase
     end

   always_comb
     begin
	endpi0.rdreq = 1'b0;
	endpi1.rdreq = 1'b0;
	endpo0.wrreq = 1'b0;

	case (token.endp)
	  4'd0:
	    begin
	       endpi0.rdreq = fifo_rdreq;
	       endpo0.wrreq = fifo_wrreq;
	    end

	  4'd1:
	    endpi1.rdreq = fifo_rdreq;
	endcase
     end

   /************************************************************************
    * Validy checks
    ************************************************************************/
   /* DEBUG */
   wire dbg_valid_token = valid_token(token);
   wire dbg_valid_data  = valid_crc16(crc16);


   /************************************************************************
    * Functions
    ************************************************************************/
   function valid_token(input token_t token);
      valid_token = (token.pid == ~token.pidx) && valid_crc5({token.crc5,token.endp,token.addr});
   endfunction

   /*
    * CRC5 = x^5 + x^2 + 1
    *
    * If all token bits are received without error the residual will
    * be 5'b01100.
    *
    * Note, that the LSB is sent first hence the polynom and the
    * residual are reversed.
    */
   function valid_crc5(input [15:0] d);
      const bit [4:0] crc5_poly = 5'b10100,
		      crc5_res  = 5'b00110;
      logic [4:0] crc5;

      crc5 = '1;

      for (int i=$right(d);i<=$left(d);i++)
	if (crc5[$right(crc5)]^d[i])
	  crc5 = (crc5>>1)^crc5_poly;
	else
	  crc5 = crc5>>1;

      valid_crc5 = (crc5_res == crc5);
   endfunction

   /*
    * CRC16 = x^16 + x^15 + x^2 + 1
    *
    * If all token bits are received without error the residual will
    * be 16'b1000000000001101.
    *
    * Note, that the LSB is sent first hence the polynom and the
    * residual are reversed.
    */
   function [15:0] step_crc16(input [7:0] d);
      const bit [15:0] crc16_poly = 16'b1010000000000001;

      step_crc16 = crc16;

      for (int i=$right(d);i<=$left(d);i++)
	if (step_crc16[$right(step_crc16)]^d[i])
	  step_crc16 = (step_crc16>>1)^crc16_poly;
	else
	  step_crc16 = step_crc16>>1;
   endfunction

   function valid_crc16(input [15:0] crc16);
      const bit [15:0] crc16_res = 16'b1011000000000001;

      valid_crc16 = (crc16_res == crc16);
   endfunction
endmodule
