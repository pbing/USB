/* DPLL with 4x oversampling
 *
 * Design a robust USB serial interface engine (SIE)
 * http://www.usb.org/developers/docs/whitepapers/siewp.pdf
 */

`default_nettype none

module usb_cdr
  import types::*;
   (input  wire     reset,          // system reset
    input  wire     clk,            // USB clock
    input  wire     d,              // data from PHY
    input  wire     se0,            // SE0 state
    input  wire     usb_full_speed, // 0: USB low-speed 1:USB full-speed
    output logic    q,              // retimed data
    output logic    en,             // data enable
    output logic    eop);           // end of packet

   /******************************
    * Clock and data recover
    ******************************/

   /* CDR FSM */
   enum int unsigned {S[16]} state, next;

   always_ff @(posedge clk)
     if (reset)
       state <= S12;
     else
       state <= next;

   always_comb
     case (state)
       S12: if (!d) next = S13; else next = S12;

       S13: if (d) next = S5; else next = S13;

       S5: next = S7;

       S7: if (d) next = S6; else next = S11;

       S6: if (d) next = S4; else next = S1;

       S4: if (d) next = S5; else next = S1;

       S1: next = S3;

       S3: if (!d) next = S2; else next = S15;

       S2: if (!d) next = S0; else next = S5;

       S0: if (!d) next = S1; else next = S5;

       S11: next = S2;

       S15: next = S6;

       default next = S12;
     endcase

   always_comb q  = d;
   always_comb en = state == S3 || state == S7;

   /******************************
    * EOP detection
    ******************************/
   logic j;

   always_comb
     if (usb_full_speed)
       j = d & ~se0;
     else
       j = ~d & ~se0;

   /* EOP FSM */
   enum int unsigned {EOP_S[5]} eop_state, eop_next;

   always_ff @(posedge clk)
     if (reset)
       eop_state <= EOP_S0;
     else
       eop_state <= eop_next;

   always_comb
     begin
	eop = 1'b0;

	case (eop_state)
	  EOP_S0:
	    if (se0)
	      eop_next = EOP_S1;
	    else
	      eop_next = EOP_S0;

	  EOP_S1:
	    if (se0)
	      eop_next = EOP_S2;
	    else
	      eop_next = EOP_S0;

	  EOP_S2:
	    if (se0)
	      eop_next = EOP_S3;
	    else
	      eop_next = EOP_S0;

	  EOP_S3:
	    if (se0)
	      eop_next = EOP_S3;
	    else if (j)
	      begin
		 eop      = 1'b1;
		 eop_next = EOP_S0;
	      end
	    else
	      eop_next = EOP_S4;

	  EOP_S4:
	    begin
	       if (j)
		 eop = 1'b1;

	       eop_next = EOP_S0;
	    end
	endcase
     end
endmodule

`resetall
