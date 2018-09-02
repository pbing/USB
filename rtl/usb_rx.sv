/* USB receiver */

`default_nettype none

module usb_rx
  import types::*;
   (input  wire        reset,  // system reset
    input  wire        clk,    // clock
    input  wire        clk_en, // clock enable
    input  wire        d_i,    // data from CDR
    input  wire        eop,    // EOP from CDR
    output logic [7:0] data,   // data to SIE
    output logic       active, // active between SYNC und EOP
    output logic       valid,  // data valid pulse
    output logic       error); // error detected

   logic j, k;

   always_comb j = ~d_i;
   always_comb k =  d_i;

   /*************************************************************
    * RX FSM
    *
    * Use explicite state assings instead of rx_next = rx_state.next()
    * because automatic FSM detection of Synplify does not work
    * in this case.
    *************************************************************/
   enum int unsigned {RESET, SYNC[4], RX_DATA_WAIT[8], RX_DATA, STRIP_EOP, ERROR, ABORT[1:2], TERMINATE} rx_state, rx_next;
   logic             rcv_bit, rcv_data;

   always_ff @(posedge clk)
     if (reset)
       rx_state <= RESET;
     else
       rx_state <= rx_next;

   always_comb
     begin
	rx_next = rx_state;

	if (eop)
	  rx_next = STRIP_EOP;

	else if (clk_en)
	  case (rx_state)

	    /* search ...KJKK */
	    RESET:
	      if (k) rx_next = SYNC0;

	    SYNC0:
	      if (j) rx_next = SYNC1;

	    SYNC1:
	      if (k) rx_next = SYNC2;
	      else   rx_next = RESET;

	    SYNC2:
	      if (k) rx_next = SYNC3;
	      else   rx_next = SYNC1;

	    SYNC3:
	      rx_next = RX_DATA_WAIT0;

	    RX_DATA_WAIT0:
	      if (rcv_bit) rx_next = RX_DATA_WAIT1;

	    RX_DATA_WAIT1:
	      if (rcv_bit) rx_next = RX_DATA_WAIT2;

	    RX_DATA_WAIT2:
	      if (rcv_bit) rx_next = RX_DATA_WAIT3;

	    RX_DATA_WAIT3:
	      if (rcv_bit) rx_next = RX_DATA_WAIT4;

	    RX_DATA_WAIT4:
	      if (rcv_bit) rx_next = RX_DATA_WAIT5;

	    RX_DATA_WAIT5:
	      if (rcv_bit) rx_next = RX_DATA_WAIT6;

	    RX_DATA_WAIT6:
	      if (rcv_bit) rx_next = RX_DATA_WAIT7;

	    RX_DATA_WAIT7:
	      if (rcv_bit) rx_next = RX_DATA;

	    RX_DATA:
	      if (rcv_bit) rx_next = RX_DATA_WAIT1;

	    STRIP_EOP:
	      rx_next = RESET;

	    ERROR:
	      rx_next = ABORT1; // choose ABORT1 or ABORT2

	    ABORT1:
	      rx_next = RESET;

	    ABORT2:
	      if (j) // IDLE
		rx_next = TERMINATE;

	    TERMINATE:
	      rx_next = RESET;

	    default
	      rx_next = RESET;
	  endcase
     end

   always_comb
     begin
	active   = 1'b0;
	rcv_data = 1'b0;
	error    = 1'b0;

	case (rx_state)
	  RX_DATA_WAIT0, RX_DATA_WAIT1, RX_DATA_WAIT2,
	  RX_DATA_WAIT3, RX_DATA_WAIT4, RX_DATA_WAIT5,
	  RX_DATA_WAIT6, RX_DATA, STRIP_EOP:
	    active = 1'b1;

	  RX_DATA_WAIT7:
	    begin
	       active   = 1'b1;
	       rcv_data = 1'b1;
	    end

	  ERROR:
	    error = 1'b1;
	endcase
     end

   /*************************************************************
    * NRZI decoding
    *************************************************************/
   logic nrzi, d0;

   always_ff @(posedge clk)
     if (reset)
       nrzi <= 1'b0;
     else if (clk_en)
       nrzi <= j;

   always_comb d0 = j ~^ nrzi;

   /* bit unstuffing */
   logic [2:0] num_ones;

   always_ff @(posedge clk)
     if (reset)
       num_ones <= 3'd0;
     else if (clk_en)
       if (d0)
	 if (num_ones == 3'd6)
	   num_ones <= 3'd0;
	 else
	   num_ones <= num_ones + 3'd1;
       else
	 num_ones <= 3'd0;

   /* zero when bit unstuffing */
   always_comb rcv_bit = (d0 || num_ones != 3'd6);

   /* RX shift/hold register */
   always_ff @(posedge clk)
     begin:rx_shift_hold
	logic [7:0] rx_shift;

	if (reset)
	  begin
	     rx_shift <= 8'h0;
	     data     <= 8'h0;
	  end
	else if (clk_en)
	  begin
	     /* RX shift register */
	     if (rcv_bit) rx_shift <= {d0, rx_shift[7-:7]};

	     /* RX hold register */
	     if (rcv_data) data <= rx_shift;
	  end
     end:rx_shift_hold

   /* valid signal */
   always_ff @(posedge clk)
     if (reset)
       valid <= 1'b0;
     else
       valid <= rcv_data & clk_en;
endmodule

`resetall
