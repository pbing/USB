/* DPLL with 4x oversampling
 *
 * Design a robust USB serial interface engine (SIE)
 * http://www.usb.org/developers/docs/whitepapers/siewp.pdf
 */

module usb_cdr
  import types::*;
   (input  wire     reset, // system reset
    input  wire     clk,   // system clock (slow speed: 6 MHz, full speed: 48 MHz)
    input  d_port_t d,     // data from PHY
    output logic    q,     // retimed data
    output logic    en,    // data enable
    output logic    eop,   // end of packet
    output logic    se0);  // SE0 state

   /******************************
    * Clock and data recover
    ******************************/

   /* synchronizer */
   logic a, b;

   always @(posedge clk)
     a <= (d == K);

   always @(negedge clk)
     b <= (d == K);

   /* CDR FSM */
   logic [3:0] cdr_state, cdr_next;

   always @(posedge clk)
     if (reset)
       cdr_state <= 4'hc;
     else
       cdr_state <= cdr_next;

   always_comb
     case (cdr_state)
       /* Init */
       4'hc:
	 if (!b)
	   cdr_next = 4'hd;
	 else
	   cdr_next = 4'hc;

       4'hd:
	 if (b)
	   cdr_next = 4'h5;
	 else
	   cdr_next = 4'hd;

       /* D = 1 */
       4'h5:
	 cdr_next = 4'h7;

       4'h7:
	 if (a)
	   cdr_next = 4'h6;
	 else
	   cdr_next = 4'hb;

       4'h6:
	 if (b)
	   cdr_next = 4'h4;
	 else
	   cdr_next = 4'h1;

       4'h4:
	 if (b)
	   cdr_next = 4'h5;
	 else
	   cdr_next = 4'h1;

       4'hf:
	 cdr_next = 4'h6;

       /* D = 0 */
       4'h1:
	 cdr_next = 4'h3;

       4'h3:
	 if (!a)
	   cdr_next = 4'h2;
	 else
	   cdr_next = 4'hf;

       4'h2:
	 if (!b)
	   cdr_next = 4'h0;
	 else
	   cdr_next = 4'h5;

       4'h0:
	 if (!b)
	   cdr_next = 4'h1;
	 else
	   cdr_next = 4'h5;

       4'hb:
	 cdr_next = 4'h2;

       default
	 cdr_next = 4'hc;
     endcase

   always_comb q = cdr_state[2];

   always_comb en  = ((cdr_state == 4'h3) || (cdr_state == 4'h7));

   /******************************
    * EOP detection
    ******************************/

   /* synchronizer */
   logic j;

   always @(posedge clk)
     begin
	j   <= (d == J);
	se0 <= (d == SE0);
     end

   /* EOP FSM */
   enum int unsigned {S[5]} eop_state, eop_next;

   always @(posedge clk)
     if (reset)
       eop_state <= S0;
     else
       eop_state <= eop_next;

   always_comb
     begin
	eop = 1'b0;

	case (eop_state)
	  S0:
	    if (se0)
	      eop_next = S1;
	    else
	      eop_next = S0;

	  S1:
	    if (se0)
	      eop_next = S2;
	    else
	      eop_next = S0;

	  S2:
	    if (se0)
	      eop_next = S3;
	    else
	      eop_next = S0;

	  S3:
	    if (se0)
	      eop_next = S3;
	    else if (j)
	      begin
		 eop      = 1'b1;
		 eop_next = S0;
	      end
	    else
	      eop_next = S4;

	  S4:
	    begin
	       if (j)
		 eop = 1'b1;

	       eop_next = S0;
	    end
	endcase
     end
endmodule
