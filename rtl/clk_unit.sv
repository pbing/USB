/* Clock Unit */

module clk_unit
  (input  wire clk_i,    // 24 MHz
   output wire clk_cpu,  // slow speed: 12 MHz, full speed: 96 MHz (min. 2·clk_usb)
   output wire clk_usb); // slow speed:  6 MHz, full speed: 48 MHz

   import types::*;

   wire pll_clk_96m, pll_clk_48m, pll_clk_12m;

   pll pll
     (.inclk0(clk_i),
      .c0(pll_clk_96m),
      .c1(pll_clk_48m),
      .c2(pll_clk_12m));

   generate
      if (USB_FULL_SPEED)
	begin:full_speed
	   assign clk_cpu = pll_clk_96m;
	   assign clk_usb = pll_clk_48m;
	end:full_speed
      else
	begin:low_speed
	   bit pll_clk_6m;

	   assign clk_cpu = pll_clk_48m;

	   /* 1:2 clock divider */
	   always @(posedge pll_clk_12m)
	     pll_clk_6m <= ~pll_clk_6m;

	   /* add clock buffer for Altera CYCLONE II */
	   clkctrl clkctrl
	     (.inclk(pll_clk_6m),
	      .outclk(clk_usb));
	end:low_speed
   endgenerate
endmodule
