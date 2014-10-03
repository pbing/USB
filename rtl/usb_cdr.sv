/* Oversampled Hogge clock and data recovery circuit
 * for USB low speed reveiver (1.5 MHz).
 */

module usb_cdr
  import types::*;
   (input           reset,          // system reset
    input           clk,            // system clock (24 MHz)
    input  d_port_t d,              // data from PHY
    output d_port_t q,              // retimed data
    output d_port_t line_state,     // synchronized D+,D-
    output logic    strobe);        // data strobe

   logic [3:0]        phase;        // phase (24 MHz/1.5 MHz = 16)
   logic signed [4:0] dphase;       // delta phase
   var d_port_t       d_shift[1:2]; // shifted data
   logic              up,down;      // phase shift direction

   always_ff @(posedge clk)
     if (reset)
       begin
	  d_shift[1] <= J;
	  d_shift[2] <= J;
	  phase      <= 4'd0;
	  dphase     <= 5'sd0;
	  strobe     <= 1'b0;
       end
     else
       begin
	  strobe <= 1'b0;

	  priority case (1'b1)
	    down  : dphase <= dphase - 5'sd1;
	    up    : dphase <= dphase + 5'sd1;
	    default if (phase == 4'd13) dphase <= 5'sd0;
	  endcase

	  unique case (phase)
	    4'd4:
	      begin
		 d_shift[1] <= d;
		 phase      <= phase + 4'sd1;
	      end

	    4'd12:
	      begin
		 d_shift[2] <= d_shift[1];
		 phase      <= phase + 4'sd1;
		 strobe     <= 1'b1;
	      end

	    4'd13:
	      if (dphase == 5'sd0)
		phase <= phase + 4'sd1;
	      else if (dphase>5'sd0)
		phase <= phase + 4'sd2;
	      else
		/* skip phase increment when dphase is negative */
		phase <= phase;

	    default
	      phase <= phase + 4'sd1;
	  endcase

       end

   always_comb
     begin
	/* Phase discriminators are using only one bit (d_port_t[0]). */
	down = (d_shift[1][0] != d_shift[2][0]);
	up = (d[0] != d_shift[1][0]);

	q = d_shift[2];
     end

   /************************************************************************
    * Line-state
    ************************************************************************/

   /* synchronize to system clock */
   always_ff @(posedge clk)
     begin
	var d_port_t d_s; // synchronized d

	if (reset)
	  begin
	     /* Init to IDLE */
	     d_s        <= J;
	     line_state <= J;
	  end
	else
	  begin
	     d_s        <= d;
	     line_state <= d_s;
	  end
     end
endmodule
