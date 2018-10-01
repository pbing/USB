/* FPGA Toplevel
 *
 * KEY[0]       external reset
 * SW[0]        0: USB low-speed 1:USB full-speed
 *
 * GPIO_1[26]   Pull-up to 3.3 V via 1.5 kOhm at GPIO_1[32] for USB speed detection.
 *              Low during external reset for starting new communication.
 * GPIO_1[32]   slow speed: USB-D-, full speed: USB-D+
 * GPIO_1[34]   slow speed: USB-D+, full speed: USB-D-
 *
 */

//`define ENABLE_DDR2LP
//`define ENABLE_HSMC_XCVR
//`define ENABLE_SMA
//`define ENABLE_REFCLK
`define ENABLE_GPIO

`default_nettype none

module top_c5gx
  (/* ADC (1.2 V) */
   output wire        ADC_CONVST,
   output wire        ADC_SCK,
   output wire        ADC_SDI,
   input  wire        ADC_SDO,
   /* AUD (2.5 V) */
   input  wire        AUD_ADCDAT,
   inout  wire        AUD_ADCLRCK,
   inout  wire        AUD_BCLK,
   output wire        AUD_DACDAT,
   inout  wire        AUD_DACLRCK,
   output wire        AUD_XCK,
   /* CLOCK */
   input  wire        CLOCK_125_p,    // LVDS
   input  wire        CLOCK_50_B5B,   // 3.3-V LVTTL
   input  wire        CLOCK_50_B6A,   // 3.3-V LVTTL
   input  wire        CLOCK_50_B7A,   // 2.5 V
   input  wire        CLOCK_50_B8A,   // 2.5 V
   /* CPU */
   input  wire        CPU_RESET_n,    // 3.3V LVTTL
`ifdef ENABLE_DDR2LP
   /* DDR2LP (1.2-V HSUL) */
   output wire [9:0]  DDR2LP_CA,
   output wire [1:0]  DDR2LP_CKE,
   output wire        DDR2LP_CK_n,    // DIFFERENTIAL 1.2-V HSUL
   output wire        DDR2LP_CK_p,    // DIFFERENTIAL 1.2-V HSUL
   output wire [1:0]  DDR2LP_CS_n,
   output wire [3:0]  DDR2LP_DM,
   inout  wire [31:0] DDR2LP_DQ,
   inout  wire [3:0]  DDR2LP_DQS_n,   // DIFFERENTIAL 1.2-V HSUL
   inout  wire [3:0]  DDR2LP_DQS_p,   // DIFFERENTIAL 1.2-V HSUL
   input  wire        DDR2LP_OCT_RZQ, // 1.2 V
`endif
`ifdef ENABLE_GPIO
   /* GPIO (3.3-V LVTTL) */
   inout  wire [35:0] GPIO,
`else
   /* GPIO (3.3-V LVTTL) */
   inout  wire [21:0] GPIO,
   /* HEX2 (1.2 V) */
   output wire [6:0]  HEX2,
   /* HEX3 (1.2 V) */
   output wire [6:0]  HEX3,
`endif
   /* HDMI */
   output wire        HDMI_TX_CLK,
   output wire [23:0] HDMI_TX_D,
   output wire        HDMI_TX_DE,
   output wire        HDMI_TX_HS,
   input  wire        HDMI_TX_INT,
   output wire        HDMI_TX_VS,
   /* HEX0 */
   output wire [6:0]  HEX0,
   /* HEX1 */
   output wire [6:0]  HEX1,
   /* HSMC (2.5 V) */
   input  wire        HSMC_CLKIN0,
   input  wire [2:1]  HSMC_CLKIN_n,
   input  wire [2:1]  HSMC_CLKIN_p,
   output wire        HSMC_CLKOUT0,
   output wire [2:1]  HSMC_CLKOUT_n,
   output wire [2:1]  HSMC_CLKOUT_p,
   inout  wire [3:0]  HSMC_D,
`ifdef ENABLE_HSMC_XCVR
   input  wire [3:0]  HSMC_GXB_RX_p,  //  1.5-V PCML
   output wire [3:0]  HSMC_GXB_TX_p,  //  1.5-V PCML
`endif
   inout  wire [16:0] HSMC_RX_n,
   inout  wire [16:0] HSMC_RX_p,
   inout  wire [16:0] HSMC_TX_n,
   inout  wire [16:0] HSMC_TX_p,
   /* I2C (2.5 V) */
   output wire        I2C_SCL,
   inout  wire        I2C_SDA,
   /* KEY (1.2 V) */
   input  wire [3:0]  KEY,
   /* LEDG (2.5 V) */
   output wire [7:0]  LEDG,
   /* LEDR (2.5 V) */
   output wire [9:0]  LEDR,
`ifdef ENABLE_REFCLK
   /* REFCLK (1.5-V PCML) */
   input  wire        REFCLK_p0,
   input  wire        REFCLK_p1,
`endif
   /* SD (3.3-V LVTTL) */
   output wire        SD_CLK,
   inout  wire        SD_CMD,
   inout  wire [3:0]  SD_DAT,
`ifdef ENABLE_SMA
   /* SMA (1.5-V PCML) */
   input  wire        SMA_GXB_RX_p,
   output wire        SMA_GXB_TX_p,
`endif
   /* SRAM (3.3-V LVTTL) */
   output wire [17:0] SRAM_A,
   output wire        SRAM_CE_n,
   inout  wire [15:0] SRAM_D,
   output wire        SRAM_LB_n,
   output wire        SRAM_OE_n,
   output wire        SRAM_UB_n,
   output wire        SRAM_WE_n,
   /* SW (1.2 V) */
   input  wire [9:0]  SW,
   /* UART (2.5 V) */
   input  wire        UART_RX,
   output wire        UART_TX);

   import types::*;

   logic      GPIO32_reg, GPIO34_reg;

   /* USB */
   d_port_t   usb_d_i;                               // USB port D+, D- (input)
   d_port_t   usb_d_o;                               // USB port D+, D- (output)
   wire       usb_d_en;                              // USB port D+, D- (enable)

   wire       pll_reset, reset_in_n, reset;          // reset
   wire       pll_locked;                            // PLL lock
   wire       clk;                                   // CPU clock
   wire       usb_full_speed_clk, usb_low_speed_clk; // USB clock
   logic      usb_clk;                               // USB clock
   wire [6:0] HEX2, HEX3;                            // not used

   /* external ports */
   assign GPIO[26] = ~reset;
   assign GPIO[32] = GPIO32_reg;
   assign GPIO[34] = GPIO34_reg;

   wire usb_full_speed = SW[0];

   always_comb
     if (usb_full_speed)
       begin
          usb_d_i                  = d_port_t'({GPIO[32], GPIO[34]});
          {GPIO32_reg, GPIO34_reg} = (usb_d_en) ? usb_d_o : 2'bz;
       end
     else
       begin
	  usb_d_i                  = d_port_t'({GPIO[34], GPIO[32]});
	  {GPIO34_reg, GPIO32_reg} = (usb_d_en) ? usb_d_o : 2'bz;
       end

   assign pll_reset  = ~CPU_RESET_n;
   assign reset_in_n = CPU_RESET_n & pll_locked;

   if_wb wbm (.rst(reset), .clk);
   if_wb wbs1(.rst(reset), .clk);
   if_wb wbs2(.rst(reset), .clk);
   if_wb wbs3(.rst(reset), .clk);
   if_wb wbs4(.rst(reset), .clk);

   pll pll
     (.refclk   (CLOCK_50_B5B),
      .rst      (pll_reset),
      .outclk_0 (clk),
      .outclk_1 (usb_full_speed_clk),
      .outclk_2 (usb_low_speed_clk),
      .locked   (pll_locked));

   /* PLL clocks must be connected to inclk2x or inclk3x.
    * Because the unused inputs are static zero no glitch-free
    * clock selector can be used.
    */
   clkctrl clkctrl
     (.inclk0x   (1'b0),
      .inclk1x   (1'b0),
      .inclk2x   (usb_low_speed_clk),
      .inclk3x   (usb_full_speed_clk),
      .clkselect ({1'b1, usb_full_speed}),
      .outclk    (usb_clk));	

   sync_reset sync_reset
     (.clk,
      .reset_in_n,
      .reset);

   j1_wb cpu(.wb(wbm), .*);

   wb_intercon wb_intercon (.*);

   wb_rom wb_rom(.wb(wbs1));

   wb_ram wb_ram(.wb(wbs2));

   board_io board_io
     (.reset,
      .key  (KEY),
      .sw   (SW),
      .hex  ({HEX0, HEX1, HEX2, HEX3}),
      .ledg (LEDG),
      .ledr (LEDR),
      .wb   (wbs3));

   usb_device_controller usb_device_controller
     (.reset,
      .clk  (usb_clk),
      .usb_full_speed,
      .d_i  (usb_d_i),
      .d_o  (usb_d_o),
      .d_en (usb_d_en),
      .wb   (wbs4));
endmodule

`resetall
