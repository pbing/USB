/* FPGA top level
 *
 * KEY[0]       external reset
 *
 * GPIO_1[26]   3.3 V at 1.5 kOhm for USB low-speed detection. Low during external reset for starting new communication.
 * GPIO_1[32]   USB-D-
 * GPIO_1[34]   USB-D+
 *
 */

module CII_Starter_TOP
  (/* Clock Input */
   input  wire [1:0]  CLOCK_24,    // 24 MHz
   input  wire [1:0]  CLOCK_27,    // 27 MHz
   input  wire        CLOCK_50,    // 50 MHz
   input  wire        EXT_CLOCK,   // External Clock

   /* Push Button */
   input  wire [3:0]  KEY,         // Pushbutton[3:0]

   /* DPDT Switch */
   input wire  [9:0]  SW,          // Toggle Switch[9:0]

   /* 7-SEG Display */
   output wire [6:0]  HEX0,        // Seven Segment Digit 0
   output wire [6:0]  HEX1,        // Seven Segment Digit 1
   output wire [6:0]  HEX2,        // Seven Segment Digit 2
   output wire [6:0]  HEX3,        // Seven Segment Digit 3

   /* LED */
   output wire [7:0]  LEDG,        // LED Green[7:0]
   output wire [9:0]  LEDR,        // LED Red[9:0]

   /* UART */
   output wire        UART_TXD,    // UART Transmitter
   input  wire        UART_RXD,    // UART Receiver

   /* SDRAM Interface */
   inout  wire [15:0] DRAM_DQ,     // SDRAM Data bus 16 Bits
   output wire [11:0] DRAM_ADDR,   // SDRAM Address bus 12 Bits
   output wire        DRAM_LDQM,   // SDRAM Low-byte Data Mask
   output wire        DRAM_UDQM,   // SDRAM High-byte Data Mask
   output wire        DRAM_WE_N,   // SDRAM Write Enable
   output wire        DRAM_CAS_N,  // SDRAM Column Address Strobe
   output wire        DRAM_RAS_N,  // SDRAM Row Address Strobe
   output wire        DRAM_CS_N,   // SDRAM Chip Select
   output wire        DRAM_BA_0,   // SDRAM Bank Address 0
   output wire        DRAM_BA_1,   // SDRAM Bank Address 0
   output wire        DRAM_CLK,    // SDRAM Clock
   output wire        DRAM_CKE,    // SDRAM Clock Enable

   /* Flash Interface */
   inout  wire [7:0]  FL_DQ,       // FLASH Data bus 8 Bits
   output wire [21:0] FL_ADDR,     // FLASH Address bus 22 Bits
   output wire        FL_WE_N,     // FLASH Write Enable
   output wire        FL_RST_N,    // FLASH Reset
   output wire        FL_OE_N,     // FLASH Output Enable
   output wire        FL_CE_N,     // FLASH Chip Enable

   /* SRAMwire  Interface */
   inout  wire [15:0] SRAM_DQ,     // SRAM Data bus 16 Bits
   output wire [17:0] SRAM_ADDR,   // SRAM Address bus 18 Bits
   output wire        SRAM_UB_N,   // SRAM High-byte Data Mask
   output wire        SRAM_LB_N,   // SRAM Low-byte Data Mask
   output wire        SRAM_WE_N,   // SRAM Write Enable
   output wire        SRAM_CE_N,   // SRAM Chip Enable
   output wire        SRAM_OE_N,   // SRAM Output Enable

   /* SD Card Interface */
   inout  wire        SD_DAT,      // SD Card Data
   inout  wire        SD_DAT3,     // SD Card Data 3
   inout  wire        SD_CMD,      // SD Card Command Signal
   output wire        SD_CLK,      // SD Card Clock

   /* I2C */
   inout  wire        I2C_SDAT,    // I2C Data
   output wire        I2C_SCLK,    // I2C Clock

   /* PS2 */
   input  wire        PS2_DAT,     // PS2 Data
   input  wire        PS2_CLK,     // PS2 Clock

   /* USB JTAG link */
   input  wire        TDI,         // CPLD -> FPGA (data in)
   input  wire        TCK,         // CPLD -> FPGA (clk)
   input  wire        TCS,         // CPLD -> FPGA (CS)
   output wire        TDO,         // FPGA -> CPLD (data out)

   /* VGA */
   output wire        VGA_HS,      // VGA H_SYNC
   output wire        VGA_VS,      // VGA V_SYNC
   output wire [3:0]  VGA_R,       // VGA Red[3:0]
   output wire [3:0]  VGA_G,       // VGA Green[3:0]
   output wire [3:0]  VGA_B,       // VGA Blue[3:0]

   /* Audio CODEC */
   inout  wire        AUD_ADCLRCK, // Audio CODEC ADC LR Clock
   input  wire        AUD_ADCDAT,  // Audio CODEC ADC Data
   inout  wire        AUD_DACLRCK, // Audio CODEC DAC LR Clock
   output wire        AUD_DACDAT,  // Audio CODEC DAC Data
   inout  wire        AUD_BCLK,    // Audio CODEC Bit-Stream Clock
   output wire        AUD_XCK,     // Audio CODEC Chip Clock

   /* GPIO */
   inout  wire [35:0] GPIO_0,      // GPIO Connection 0
   inout  wire [35:0] GPIO_1);     // GPIO Connection 1

   import types::*;

   /* common signals */
   wire reset;
   wire clk;

   /* USB */
   d_port_t   usb_d_i;        // USB port D+, D- (input)
   d_port_t   usb_d_o;        // USB port D+, D- (output)
   wire       usb_d_en;       // USB port D+, D- (enable)

   /* external ports */
   assign usb_d_i                  = d_port_t'({GPIO_1[34], GPIO_1[32]});
   assign {GPIO_1[34], GPIO_1[32]} = (usb_d_en) ? usb_d_o : 2'bz;
   assign GPIO_1[26]               = ~reset;
   assign GPIO_0[35]               = usb_d_en;

   if_io io_cpu();
   if_io io_sie();
   if_io io_board();

   clk_unit clk_unit
     (.clk_i(CLOCK_24[0]),
      .clk_o(clk));

   sync_reset sync_reset
     (.clk(clk),
      .key(KEY[0]),
      .reset(reset));

   j1 j1
     (.sys_clk_i(clk),
      .sys_rst_i(reset),
      .io_din(io_cpu.din),
      .io_rd(io_cpu.rd),
      .io_wr(io_cpu.wr),
      .io_addr(io_cpu.addr),
      .io_dout(io_cpu.dout));

   io_bus io_bus
     (.cpu(io_cpu),
      .sie(io_sie),
      .board(io_board));

   usb_device_controller usb_device_controller
     (.reset(reset),
      .clk(clk),
      .d_i(usb_d_i),
      .d_o(usb_d_o),
      .d_en(usb_d_en),
      .io(io_sie));

   board_io board_io
     (.clk(clk),
      .reset(reset),
      .key(KEY),
      .sw(SW),
      .hex({HEX0, HEX1, HEX2, HEX3}),
      .ledg(LEDG),
      .ledr(LEDR),
      .io(io_board));
endmodule
