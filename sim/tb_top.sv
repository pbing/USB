/* top-level testbench */

//`define ENABLE_DDR2LP
//`define ENABLE_HSMC_XCVR
//`define ENABLE_SMA
//`define ENABLE_REFCLK
`define ENABLE_GPIO

`default_nettype none

module tb_top;
   timeunit 1ns;
   timeprecision 1ps;

   import types::*;

   const realtime tclk50   = 1s / 50e6,
		  tbit     = 1s / ((7 * USB_FULL_SPEED + 1) * 1.5e6),
		  tusb_clk = tbit / 4;

   /* ADC (1.2 V) */
   wire        ADC_CONVST;
   wire        ADC_SCK;
   wire        ADC_SDI;
   bit         ADC_SDO;
   /* AUD (2.5 V) */
   bit         AUD_ADCDAT;
   wire        AUD_ADCLRCK;
   wire        AUD_BCLK;
   wire        AUD_DACDAT;
   wire        AUD_DACLRCK;
   wire        AUD_XCK;
   /* CLOCK */
   bit         CLOCK_125_p;    // LVDS
   bit         CLOCK_50_B5B;   // 3.3-V LVTTL
   bit         CLOCK_50_B6A;
   bit         CLOCK_50_B7A;   // 2.5 V
   bit         CLOCK_50_B8A;
   /* CPU */
   bit         CPU_RESET_n;    // 3.3V LVTTL
`ifdef ENABLE_DDR2LP
   /* DDR2LP (1.2-V HSUL) */
   wire [9:0]  DDR2LP_CA;
   wire [1:0]  DDR2LP_CKE;
   wire        DDR2LP_CK_n;    // DIFFERENTIAL 1.2-V HSUL
   wire        DDR2LP_CK_p;    // DIFFERENTIAL 1.2-V HSUL
   wire [1:0]  DDR2LP_CS_n;
   wire [3:0]  DDR2LP_DM;
   wire [31:0] DDR2LP_DQ;
   wire [3:0]  DDR2LP_DQS_n;   // DIFFERENTIAL 1.2-V HSUL
   wire [3:0]  DDR2LP_DQS_p;   // DIFFERENTIAL 1.2-V HSUL
   bit         DDR2LP_OCT_RZQ; // 1.2 V
`endif
`ifdef ENABLE_GPIO
   /* GPIO (3.3-V LVTTL) */
   wire [35:0] GPIO;
`else
   /* GPIO (3.3-V LVTTL) */
   wire [21:0] GPIO;
   /* HEX2 (1.2 V) */
   wire [6:0]  HEX2;
   /* HEX3 (1.2 V) */
   wire [6:0]  HEX3;
`endif
   /* HDMI */
   wire        HDMI_TX_CLK;
   wire [23:0] HDMI_TX_D;
   wire        HDMI_TX_DE;
   wire        HDMI_TX_HS;
   bit         HDMI_TX_INT;
   wire        HDMI_TX_VS;
   /* HEX0 */
   wire [6:0]  HEX0;
   /* HEX1 */
   wire [6:0]  HEX1;
   /* HSMC (2.5 V) */
   bit         HSMC_CLKIN0;
   bit  [2:1]  HSMC_CLKIN_n;
   bit  [2:1]  HSMC_CLKIN_p;
   wire        HSMC_CLKOUT0;
   wire [2:1]  HSMC_CLKOUT_n;
   wire [2:1]  HSMC_CLKOUT_p;
   wire [3:0]  HSMC_D;
`ifdef ENABLE_HSMC_XCVR
   bit  [3:0]  HSMC_GXB_RX_p;  //  1.5-V PCML
   wire [3:0]  HSMC_GXB_TX_p;  //  1.5-V PCML
`endif
   wire [16:0] HSMC_RX_n;
   wire [16:0] HSMC_RX_p;
   wire [16:0] HSMC_TX_n;
   wire [16:0] HSMC_TX_p;
   /* I2C (2.5 V) */
   wire        I2C_SCL;
   wire        I2C_SDA;
   /* KEY (1.2 V) */
   bit  [3:0]  KEY;
   /* LEDG (2.5 V) */
   wire [7:0]  LEDG;
   /* LEDR (2.5 V) */
   wire [9:0]  LEDR;
`ifdef ENABLE_REFCLK
   /* REFCLK (1.5-V PCML) */
   bit         REFCLK_p0;
   bit         REFCLK_p1;
`endif
   /* SD (3.3-V LVTTL) */
   wire        SD_CLK;
   wire        SD_CMD;
   wire [3:0]  SD_DAT;
`ifdef ENABLE_SMA
   /* SMA (1.5-V PCML) */
   bit         SMA_GXB_RX_p;
   wire        SMA_GXB_TX_p;
`endif
   /* SRAM (3.3-V LVTTL) */
   wire [17:0] SRAM_A;
   wire        SRAM_CE_n;
   wire [15:0] SRAM_D;
   wire        SRAM_LB_n;
   wire        SRAM_OE_n;
   wire        SRAM_UB_n;
   wire        SRAM_WE_n;
   /* SW (1.2 V) */
   bit  [9:0]  SW;
   /* UART (2.5 V) */
   bit         UART_RX;
   wire        UART_TX;

   bit          reset;      // reset
   bit          usb_clk;    // USB clock
   var d_port_t d_i;        // USB port D+,D- (input)
   var d_port_t tx_d_o;     // USB port D+,D- (output)
   wire         tx_d_en;    // USB port D+,D- (enable)
   bit   [7:0]  tx_data;    // data from SIE
   bit          tx_valid;   // rise:SYNC,1:send data,fall:EOP
   wire         tx_ready;   // data has been sent

   d_port_t     usb_d_i;
   wire         rx_filt_d;  // data from filter to CDR
   wire         rx_clk_en;  // RX clock enable
   wire         rx_d_i;     // RX data from CDR
   wire         rx_se0;     // SE0 from CDR
   wire         rx_eop;     // EOP from CDR
   wire [7:0]   rx_data;    // recieved data
   wire         rx_active;  // active between SYNC und EOP
   wire         rx_valid;   // data valid pulse
   wire         rx_error;   // error detected

   const byte GET_DEVICE_DESCRIPTOR[]        = '{8'h80, 8'h06, 8'h00, 8'h01, 8'h00, 8'h00, 8'h12, 8'h00};
   const byte GET_CONFIGURATION_DESCRIPTOR[] = '{8'h80, 8'h06, 8'h00, 8'h02, 8'h00, 8'h00, 8'h22, 8'h00};
   const byte GET_HID_REPORT_DESCRIPTOR[]    = '{8'h81, 8'h06, 8'h00, 8'h22, 8'h00, 8'h00, 8'h72, 8'h00};

   const byte DEVICE_DESCRIPTOR[]            = '{8'd18, 8'h01, 8'h10, 8'h01, 8'h00, 8'h00, 8'h00, 8'h08,
					         8'hd8, 8'h04, 8'h01, 8'h00, 8'h00, 8'h02, 8'h01, 8'h02,
					         8'h00, 8'h01};

   const byte CONFIGURATION_DESCRIPTOR[]     = '{8'd09, 8'h02, 8'h22, 8'h00, 8'h01, 8'h01, 8'h00, 8'ha0, 8'd50,
                                                 8'd09, 8'h04, 8'h00, 8'h00, 8'h01, 8'h03, 8'h01, 8'h02, 8'h00,
                                                 8'd09, 8'h21, 8'h00, 8'h01, 8'h00, 8'h01, 8'h22, 8'h32, 8'h00,
                                                 8'd07, 8'h05, 8'h81, 8'h03, 8'h04, 8'h00, 8'd10};

   const byte HID_REPORT_DESCRIPTOR[]        = '{8'h05, 8'h01, 8'h09, 8'h02, 8'ha1, 8'h01, 8'h09, 8'h01, 8'ha1, 8'h00,
                                                 8'h05, 8'h09, 8'h19, 8'h01, 8'h29, 8'h03, 8'h15, 8'h00, 8'h25, 8'h01,
                                                 8'h95, 8'h03, 8'h75, 8'h01, 8'h81, 8'h02, 8'h95, 8'h01, 8'h75, 8'h05,
                                                 8'h81, 8'h01, 8'h05, 8'h01, 8'h09, 8'h30, 8'h09, 8'h31, 8'h15, 8'h81,
                                                 8'h25, 8'h7f, 8'h75, 8'h08, 8'h95, 8'h03, 8'h81, 8'h06, 8'hc0, 8'hc0};

   const byte SET_ADDRESS[]                  = '{8'h00, 8'h05, 8'h06, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};

   const byte SET_CONFIGURATION[]            = '{8'h00, 8'h09, 8'h01, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};

   byte addr;

   int rpt  = $fopen("fifo.rpt"); // report file ID

   top_c5gx dut(.*);

   usb_tx tb_tx
     (.reset (reset),
      .clk   (usb_clk),
      .d_o   (tx_d_o),
      .d_en  (tx_d_en),
      .data  (tx_data),
      .valid (tx_valid),
      .ready (tx_ready));

   usb_filter tb_usb_filter
     (.clk (usb_clk),
      .d   (usb_d_i),
      .q   (rx_filt_d),
      .se0 (rx_se0));

   usb_cdr tb_cdr
     (.reset (reset),
      .clk   (usb_clk),
      .d     (rx_filt_d),
      .q     (rx_d_i),
      .en    (rx_clk_en),
      .eop   (rx_eop),
      .se0   (rx_se0));

   usb_rx tb_rx
     (.reset  (tx_d_en),
      .clk    (usb_clk),
      .clk_en (rx_clk_en),
      .d_i    (rx_d_i),
      .eop    (rx_eop),
      .data   (rx_data),
      .active (rx_active),
      .valid  (rx_valid),
      .error  ());

   always #(tclk50 / 2)   CLOCK_50_B5B = ~CLOCK_50_B5B;
   always #(tusb_clk / 2) usb_clk      = ~usb_clk;

   always_comb reset = ~CPU_RESET_n;

   generate
      if (USB_FULL_SPEED)
	begin:full_speed
	   assign usb_d_i              = d_port_t'({GPIO[32], GPIO[34]});
	   assign {GPIO[32], GPIO[34]} = tx_d_en ? tx_d_o : 2'bz;
	end:full_speed
      else
	begin:slow_speed
	   assign usb_d_i              = d_port_t'({GPIO[34], GPIO[32]});
	   assign {GPIO[34], GPIO[32]} = tx_d_en ? tx_d_o : 2'bz;
	end:slow_speed
   endgenerate

   /* pull-resistors of host and device */
   pulldown (weak0)       pd1(GPIO[32]);
   pulldown (weak0)       pd2(GPIO[34]);
   bufif1 (pull1, highz0) pu1(GPIO[32], 1'b1, GPIO[26]);

   /* observe endpoints */
   always @(posedge usb_clk)
     begin:monitor_endp
	if (dut.usb_device_controller.usb_sie.txbuf.wrreq) $fdisplay(rpt, "%t txbuf(device.w): 'h%h", $realtime, dut.usb_device_controller.usb_sie.txbuf.data);
	if (dut.usb_device_controller.usb_sie.txbuf.rdreq) $fstrobe (rpt, "%t txbuf(  host.r): 'h%h", $realtime, dut.usb_device_controller.usb_sie.txbuf.q);
	if (dut.usb_device_controller.usb_sie.rxbuf.wrreq) $fdisplay(rpt, "%t rxbuf(  host.w): 'h%h", $realtime, dut.usb_device_controller.usb_sie.rxbuf.data);
	if (dut.usb_device_controller.usb_sie.rxbuf.rdreq) $fstrobe (rpt, "%t rxbuf(device.r): 'h%h", $realtime, dut.usb_device_controller.usb_sie.rxbuf.q);
     end:monitor_endp

   initial
     begin:main
	$timeformat(-9, 3, " ns");
	//$monitor("LEDG='h%h", LEDG);
	//$monitor("LEDR='h%h", LEDR);

	/* reset */
	CPU_RESET_n = 1'b0;
        #100ns CPU_RESET_n = 1'b1;

//	#100us;
//	$display("SET_ADDRESS('h%h)", SET_ADDRESS[2]);
//        // SETUP stage
//        send_token(SETUP, 0, 0);
//        send_data(DATA0, SET_ADDRESS);
//        receive_pid(ACK);
//        // STATUS stage
//        send_token(IN, 0, 0);
//        receive_data(DATA1);
//        send_pid(ACK);

//        #100us;
//	$display("GET_DEVICE_DESCRIPTOR");
//        // SETUP stage
//        send_token(SETUP, 6, 0);
//        send_data(DATA0, GET_DEVICE_DESCRIPTOR);
//        receive_pid(ACK);
//        // DATA stage
//        #10us;
//        send_token(IN, 6, 0);
//        receive_data(DATA1, DEVICE_DESCRIPTOR[0:7]); // 8 bytes
//        send_pid(ACK);
//        #10us;
//        send_token(IN, 6, 0);
//        receive_data(DATA0, DEVICE_DESCRIPTOR[8:15]); // 8 bytes
//        send_pid(ACK);
//        #10us;
//        send_token(IN, 6, 0);
//        receive_data(DATA1, DEVICE_DESCRIPTOR[16:17]); // 2 bytes
//        send_pid(ACK);
//        // STATUS stage
//        #10us;
//        send_token(OUT, 6, 0);
//        send_data(DATA1); // ZLP
//        receive_pid(ACK);

//        #100us;
//	$display("GET_CONFIGURATION_DESCRIPTOR");
//        // SETUP stage
//        send_token(SETUP, 6, 0);
//        send_data(DATA0, GET_CONFIGURATION_DESCRIPTOR);
//        receive_pid(ACK);
//        // DATA stage
//        #10us;
//        send_token(IN, 6, 0);
//        receive_data(DATA1, CONFIGURATION_DESCRIPTOR[0:7]); // 8 bytes
//        send_pid(ACK);
//        #10us;
//        send_token(IN, 6, 0);
//        receive_data(DATA0, CONFIGURATION_DESCRIPTOR[8:15]); // 8 bytes
//        send_pid(ACK);
//        #10us;
//        send_token(IN, 6, 0);
//        receive_data(DATA1, CONFIGURATION_DESCRIPTOR[16:23]); // 8 bytes
//        send_pid(ACK);
//        #10us;
//        send_token(IN, 6, 0);
//        receive_data(DATA0, CONFIGURATION_DESCRIPTOR[24:31]); // 8 bytes
//        send_pid(ACK);
//        #10us;
//        send_token(IN, 6, 0);
//        receive_data(DATA1, CONFIGURATION_DESCRIPTOR[32:33]); // 2 bytes
//        send_pid(ACK);
//        // STATUS stage
//        #10us;
//        send_token(OUT, 6, 0);
//        send_data(DATA1); // ZLP
//        receive_pid(ACK);

//        #100us;
//	$display("GET_HID_REPORT_DESCRIPTOR");
//        // SETUP stage
//        send_token(SETUP, 6, 0);
//        send_data(DATA0, GET_HID_REPORT_DESCRIPTOR);
//        receive_pid(ACK);
//        // DATA stage
//        #10us;
//        send_token(IN, 6, 0);
//        receive_data(DATA1, HID_REPORT_DESCRIPTOR[0:7]); // 8 bytes
//        send_pid(ACK);
//        #10us;
//        send_token(IN, 6, 0);
//        receive_data(DATA0, HID_REPORT_DESCRIPTOR[8:15]); // 8 bytes
//        send_pid(ACK);
//        #10us;
//        send_token(IN, 6, 0);
//        receive_data(DATA1, HID_REPORT_DESCRIPTOR[16:23]); // 8 bytes
//        send_pid(ACK);
//        #10us;
//        send_token(IN, 6, 0);
//        receive_data(DATA0, HID_REPORT_DESCRIPTOR[24:31]); // 8 bytes
//        send_pid(ACK);
//        #10us;
//        send_token(IN, 6, 0);
//        receive_data(DATA1, HID_REPORT_DESCRIPTOR[32:39]); // 8 bytes
//        send_pid(ACK);
//        #10us;
//        send_token(IN, 6, 0);
//        receive_data(DATA0, HID_REPORT_DESCRIPTOR[40:47]); // 8 bytes
//        send_pid(ACK);
//        #10us;
//        send_token(IN, 6, 0);
//        receive_data(DATA1, HID_REPORT_DESCRIPTOR[48:49]); // 2 bytes
//        send_pid(ACK);
//        // STATUS stage
//        #10us;
//        send_token(OUT, 6, 0);
//        send_data(DATA1); // ZLP
//        receive_pid(ACK);

	#100us;
	$display("SET_CONFIGURATION('h%h)", SET_CONFIGURATION[2]);
        // SETUP stage
        send_token(SETUP, 0, 0);
        send_data(DATA0, SET_CONFIGURATION);
        receive_pid(ACK);
        // STATUS stage
        send_token(IN, 0, 0);
        receive_data(DATA1);
        send_pid(ACK);

        #100us;
	$display("Read HID report");
        send_token(IN, 6, 1);
        receive_data(DATA0, '{8'h00, 8'h00, 8'h00, 8'h00}); // 8 bytes
        send_pid(ACK);

        #100us;
	$display("Read HID report");
        send_token(IN, 6, 1);
        receive_data(DATA1, '{8'h00, 8'h00, 8'h00, 8'h00}); // 8 bytes
        send_pid(ACK);

	#100us $stop;
     end:main

   /**********************************************************************
    * Tasks
    **********************************************************************/

   task control_read_transfer(input byte command[], result[], input [6:0] addr, input [3:0] endp);
      /* Setup Transaction */
      send_token(SETUP, addr, endp);
      send_data(DATA0, command);
      receive_pid(ACK);

      /* Data Transaction */
      repeat (2)
	begin
	   send_token(IN, addr, endp);
	   receive_pid(NAK);
	end

      send_token(IN, addr, endp);
      receive_data(DATA1, result);
      send_pid(ACK);

      /* Status Transaction */
      send_token(OUT, addr, endp);
      send_data(DATA1); // ZLP
      receive_pid(ACK);
   endtask

   task control_write_transfer(input byte command[], data[], input [6:0] addr, input [3:0] endp);
      /* Setup Transaction */
      send_token(SETUP, addr, endp);
      send_data(DATA0, command);
      receive_pid(ACK);

      /* Data Transaction */
      if (data.size() > 0)
	begin
	   send_token(OUT, addr, endp);
	   send_data(DATA1, data);
	   receive_pid(ACK);
	end

      /* Status Transaction */
      send_token(IN, addr, endp);
      receive_data(DATA1); // ZLP
      send_pid(ACK);
   endtask

   task send_pid(input pid_t pid);
      /* PID */
      @(posedge usb_clk);
      $display("%t %M(%p)", $realtime, pid);
      tx_valid <= 1'b1;
      tx_data  <= {~pid, pid};
      do @(posedge usb_clk); while (!tx_ready);

      /* wait for last byte */
      do @(posedge usb_clk); while (!tx_ready);
      tx_valid = 1'b0;

      /* wait for EOP */
      do @(posedge usb_clk); while (tx_d_en);
   endtask

   task send_token(input pid_t pid, input [6:0] addr, input [3:0] endp);
      /* PID */
      @(posedge usb_clk);
      $display("%t %M(pid=%p, addr='h%h, endp=%d)", $realtime, pid, addr, endp);
      tx_valid <= 1'b1;
      tx_data  <= {~pid, pid};
      do @(posedge usb_clk); while (!tx_ready);

      /* ADDR and first bit of ENDP */
      tx_data = {endp[0], addr};
      do @(posedge usb_clk); while (!tx_ready);

      /* Rest of ENDP and CRC5 */
      tx_data = {crc5({endp, addr}), endp[3:1]};
      do @(posedge usb_clk); while (!tx_ready);

      /* wait for last byte */
      do @(posedge usb_clk); while (!tx_ready);
      tx_valid = 1'b0;

      /* wait for EOP */
      do @(posedge usb_clk); while (tx_d_en);
   endtask

   task send_data(input pid_t pid, input byte data[] = '{});
      logic [15:0] crc;

      /* PID */
      @(posedge usb_clk);
      $display("%t %M(pid=%p)", $realtime, pid);
      tx_valid <= 1'b1;
      tx_data  <= {~pid, pid};
      do @(posedge usb_clk); while (!tx_ready);

      foreach (data[i])
	begin
	   tx_data = data[i];
	   $display("%t %M('h%h)", $realtime, tx_data);
	   do @(posedge usb_clk); while (!tx_ready);
	end

      /* CRC16 */
      crc = crc16(data);
      $display("%t %M('h%h) CRC", $realtime, crc);
      tx_data = crc[7:0];
      do @(posedge usb_clk); while (!tx_ready);
      tx_data = crc[15:8];
      do @(posedge usb_clk); while (!tx_ready);

      /* wait for last byte */
      do @(posedge usb_clk); while (!tx_ready);
      tx_valid = 1'b0;

      /* wait for EOP */
      do @(posedge usb_clk); while (tx_d_en);
   endtask

   task receive_data(input pid_t expected_pid, input byte expected_data[] = '{});
      logic [15:0] crc, expected_crc;

      receive_pid (expected_pid);

      foreach (expected_data[i])
	begin
	   do @(posedge usb_clk); while (!rx_valid);
	   $display("%t %M('h%h)", $realtime, rx_data);

	   assert (rx_data == expected_data[i])
	     else $error("expected = 'h%h, received = 'h%h", expected_data[i], rx_data);
	end

      /* CRC16 */
      do @(posedge usb_clk); while (!rx_valid);
      crc[7:0] = rx_data;
      do @(posedge usb_clk); while (!rx_valid);
      crc[15:8] = rx_data;
      $display("%t %M('h%h) CRC", $realtime, crc);
      expected_crc = crc16(expected_data);

      assert (crc == expected_crc)
	else $error("expected = 'h%h, received = 'h%h", expected_crc, crc);
   endtask

   task receive_pid(input pid_t expected_pid);
      pid_t received_pid;

      /* PID */
      do @(posedge usb_clk); while (!rx_valid);
      received_pid = pid_t'(rx_data);

      if (received_pid == ACK || received_pid == NAK || received_pid == STALL)
	$display("%t %M(%p)", $realtime, received_pid);

      assert (received_pid == expected_pid)
	else $error("expected = %p, received = %p", expected_pid, received_pid);
   endtask

   /**********************************************************************
    * Functions
    **********************************************************************/

   function [4:0] crc5(input [10:0] d);
      const bit [4:0] crc5_poly = 5'b10100,
		      crc5_res  = 5'b00110;

      crc5 = '1;

      for (int i = $right(d); i <= $left(d); i++)
	if (crc5[$right(crc5)] ^ d[i])
	  crc5 = (crc5 >> 1) ^ crc5_poly;
	else
	  crc5 = crc5 >> 1;

      crc5 = ~crc5;
   endfunction

   function [15:0] crc16(input byte d[] = '{});
      const bit [15:0] crc16_poly = 16'b1010000000000001,
		       crc16_res  = 16'b1011000000000001;

      crc16 = '1;

      foreach (d[j])
	for (int i = $right(d[j]); i <= $left(d[j]); i++)
	  if (crc16[$right(crc16)] ^ d[j][i])
	    crc16 = (crc16 >> 1) ^ crc16_poly;
	  else
	    crc16 = crc16 >> 1;

      crc16 = ~crc16;
   endfunction
endmodule
