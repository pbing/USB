module tb_top;
   timeunit 1ns;
   timeprecision 1ps;

   import types::*;

   const realtime tclk24 = 1s/24e6,
                  tusb   = 1s/1.5e6;  // low speed
   const int      nbit   = tusb/tclk24;

   bit  [1:0]   CLOCK_24;                               //      24 MHz
   bit  [1:0]   CLOCK_27;                               //      27 MHz
   bit          CLOCK_50;                               //      50 MHz
   bit          EXT_CLOCK;                              //      External Clock
   ////////////////////////     Push Button             ////////////////////////
   bit  [3:0]   KEY='1;                                 //      Pushbutton[3:0]
   ////////////////////////     DPDT Switch             ////////////////////////
   bit  [9:0]   SW;                                     //      Toggle Switch[9:0]
   ////////////////////////     7-SEG Dispaly   ////////////////////////
   wire [6:0]   HEX0;                                   //      Seven Segment Digit 0
   wire [6:0]   HEX1;                                   //      Seven Segment Digit 1
   wire [6:0]   HEX2;                                   //      Seven Segment Digit 2
   wire [6:0]   HEX3;                                   //      Seven Segment Digit 3
   //////////////////////////// LED             ////////////////////////////
   wire [7:0]   LEDG;                                   //      LED Green[7:0]
   wire [9:0]   LEDR;                                   //      LED Red[9:0]
   //////////////////////////// UART    ////////////////////////////
   wire         UART_TXD;                               //      UART Transmitter
   bit          UART_RXD;                               //      UART Receiver
   ///////////////////////              SDRAM Interface ////////////////////////
   wire [15:0]  DRAM_DQ;                                //      SDRAM Data bus 16 Bits
   wire [11:0]  DRAM_ADDR;                              //      SDRAM Address bus 12 Bits
   wire         DRAM_LDQM;                              //      SDRAM Low-byte Data Mask
   wire         DRAM_UDQM;                              //      SDRAM High-byte Data Mask
   wire         DRAM_WE_N;                              //      SDRAM Write Enable
   wire         DRAM_CAS_N;                             //      SDRAM Column Address Strobe
   wire         DRAM_RAS_N;                             //      SDRAM Row Address Strobe
   wire         DRAM_CS_N;                              //      SDRAM Chip Select
   wire         DRAM_BA_0;                              //      SDRAM Bank Address 0
   wire         DRAM_BA_1;                              //      SDRAM Bank Address 0
   wire         DRAM_CLK;                               //      SDRAM Clock
   wire         DRAM_CKE;                               //      SDRAM Clock Enable
   ////////////////////////     Flash Interface ////////////////////////
   wire [7:0]   FL_DQ;                                  //      FLASH Data bus 8 Bits
   wire [21:0]  FL_ADDR;                                //      FLASH Address bus 22 Bits
   wire         FL_WE_N;                                //      FLASH Write Enable
   wire         FL_RST_N;                               //      FLASH Reset
   wire         FL_OE_N;                                //      FLASH Wire Enable
   wire         FL_CE_N;                                //      FLASH Chip Enable
   ////////////////////////     SRAM Interface  ////////////////////////
   wire [15:0]  SRAM_DQ;                                //      SRAM Data bus 16 Bits
   wire [17:0]  SRAM_ADDR;                              //      SRAM Address bus 18 Bits
   wire         SRAM_UB_N;                              //      SRAM High-byte Data Mask
   wire         SRAM_LB_N;                              //      SRAM Low-byte Data Mask
   wire         SRAM_WE_N;                              //      SRAM Write Enable
   wire         SRAM_CE_N;                              //      SRAM Chip Enable
   wire         SRAM_OE_N;                              //      SRAM Wire Enable
   //////////////////// SD Card Interface       ////////////////////////
   wire         SD_DAT;                                 //      SD Card Data
   wire         SD_DAT3;                                //      SD Card Data 3
   wire         SD_CMD;                                 //      SD Card Command Signal
   wire         SD_CLK;                                 //      SD Card Clock
   ////////////////////////     I2C             ////////////////////////////////
   wire         I2C_SDAT;                               //      I2C Data
   wire         I2C_SCLK;                               //      I2C Clock
   ////////////////////////     PS2             ////////////////////////////////
   bit          PS2_DAT;                                //      PS2 Data
   bit          PS2_CLK;                                //      PS2 Clock
   //////////////////// USB JTAG link   ////////////////////////////
   bit          TDI;                                    // CPLD -> FPGA (data in)
   bit          TCK;                                    // CPLD -> FPGA (clk)
   bit          TCS;                                    // CPLD -> FPGA (CS)
   wire         TDO;                                    // FPGA -> CPLD (data out)
   ////////////////////////     VGA                     ////////////////////////////
   wire         VGA_HS;                                 //      VGA H_SYNC
   wire         VGA_VS;                                 //      VGA V_SYNC
   wire [3:0]   VGA_R;                                  //      VGA Red[3:0]
   wire [3:0]   VGA_G;                                  //      VGA Green[3:0]
   wire [3:0]   VGA_B;                                  //      VGA Blue[3:0]
   //////////////////// Audio CODEC             ////////////////////////////
   wire         AUD_ADCLRCK;                            //      Audio CODEC ADC LR Clock
   bit          AUD_ADCDAT;                             //      Audio CODEC ADC Data
   wire         AUD_DACLRCK;                            //      Audio CODEC DAC LR Clock
   wire         AUD_DACDAT;                             //      Audio CODEC DAC Data
   wire         AUD_BCLK;                               //      Audio CODEC Bit-Stream Clock
   wire         AUD_XCK;                                //      Audio CODEC Chip Clock
   ////////////////////////     GPIO    ////////////////////////////////
   wire [35:0]  GPIO_0;                                 //      GPIO Connection 0
   wire [35:0]  GPIO_1;                                 //      GPIO Connection 1

   logic        reset;      // resetr
   logic        clk;        // system clock (24 MHz)
   var d_port_t d_i;        // USB port D+,D- (input)
   var d_port_t tx_d_o;     // USB port D+,D- (output)
   wire         tx_d_en;    // USB port D+,D- (enable)
   bit   [7:0]  tx_data;    // data from SIE
   bit          tx_valid;   // rise:SYNC,1:send data,fall:EOP
   wire         tx_ready;   // data has been sent

   d_port_t     usb_d_i;
   wire         rx_clk_en;  // RX clock enable
   var d_port_t rx_d_i;     // RX data from CDR
   var d_port_t line_state; // synchronized D+,D-
   wire [7:0]   rx_data;    // recieved data
   wire         rx_active;  // active between SYNC und EOP
   wire         rx_valid;   // data valid pulse
   wire         rx_error;   // error detected

   const byte GET_DESCRIPTOR[]          = '{8'h80, 8'h06, 8'h00, 8'h01, 8'h00, 8'h00, 8'h12, 8'h00};

   const byte SHORT_DEVICE_DESCRIPTOR[] = '{8'd18, 8'h01, 8'h10, 8'h01, 8'h00, 8'h00, 8'h00, 8'h08};

   const byte DEVICE_DESCRIPTOR[]       = '{8'd18, 8'h01, 8'h10, 8'h01, 8'h00, 8'h00, 8'h00, 8'h08,
					    8'hd8, 8'h04, 8'h01, 8'h00, 8'h00, 8'h02, 8'h01, 8'h02,
					    8'h00, 8'h01};

   const byte SET_ADDRESS[]             = '{8'h00, 8'h05, 8'hx, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};

   const byte SET_CONFIGURATION[]       = '{8'h00, 8'h09, 8'h01, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};

   byte get_descriptor[] = GET_DESCRIPTOR;
   byte set_address[]    = SET_ADDRESS;
   byte addr;

   int rpt  = $fopen("end_points.rpt"); // report file ID

   CII_Starter_TOP dut
     (.*);

   usb_tx tb_tx
     (.reset(reset),
      .clk(clk),
      .d_o(tx_d_o),
      .d_en(tx_d_en),
      .data(tx_data),
      .valid(tx_valid),
      .ready(tx_ready));

   usb_cdr tb_cdr
     (.reset(reset),
      .clk(clk),
      .d(usb_d_i),
      .q(rx_d_i),
      .line_state(line_state),
      .strobe(rx_clk_en));

   usb_rx tb_rx
     (.reset(tx_valid),
      .clk(clk),
      .clk_en(rx_clk_en),
      .d_i(rx_d_i),
      .data(rx_data),
      .active(rx_active),
      .valid(rx_valid),
      .error());

   always #(tclk24/2) CLOCK_24 = ~CLOCK_24;

   always_comb reset = ~KEY[0];
   always_comb clk   = CLOCK_24;

   assign {GPIO_1[34], GPIO_1[32]} = (tx_d_en) ? tx_d_o : 2'bz;
   assign usb_d_i                  = d_port_t'({GPIO_1[34], GPIO_1[32]});

   /* observe endpoints */
   always @(posedge clk)
     begin:monitor_endp
	if (dut.usb_device_controller.usb_sie.endpi0.wrreq) $fdisplay(rpt, "%t endpi0(device.w): 0x%h", $realtime, dut.usb_device_controller.usb_sie.endpi0.data);
	if (dut.usb_device_controller.usb_sie.endpi0.rdreq) $fstrobe (rpt, "%t endpi0(  host.r): 0x%h", $realtime, dut.usb_device_controller.usb_sie.endpi0.q);
	if (dut.usb_device_controller.usb_sie.endpi1.wrreq) $fdisplay(rpt, "%t endpi1(device.w): 0x%h", $realtime, dut.usb_device_controller.usb_sie.endpi1.data);
	if (dut.usb_device_controller.usb_sie.endpi1.rdreq) $fstrobe (rpt, "%t endpi1(  host.r): 0x%h", $realtime, dut.usb_device_controller.usb_sie.endpi1.q);
	if (dut.usb_device_controller.usb_sie.endpo0.wrreq) $fdisplay(rpt, "%t endpo0(  host.w): 0x%h", $realtime, dut.usb_device_controller.usb_sie.endpo0.data);
	if (dut.usb_device_controller.usb_sie.endpo0.rdreq) $fstrobe (rpt, "%t endpo0(device.r): 0x%h", $realtime, dut.usb_device_controller.usb_sie.endpo0.q);
     end:monitor_endp

   initial
     begin:main
	$timeformat(-9, 3, " ns");

	/* reset */
	KEY[0] = 1'b0;
        #100ns KEY[0] = 1'b1;

	get_descriptor[6] = 8'd08;
	get_descriptor[7] = 8'd00;
	$display("GET_DESCRIPTOR (short)");
	#30us control_read_transfer(get_descriptor, SHORT_DEVICE_DESCRIPTOR, 0, 0);

	addr = {$random % 8'h80};
	set_address[2] = addr;
	$display("SET_ADDRESS('h%h)", addr);
	#30us control_write_transfer(set_address, '{}, 0, 0);

	$display("SET_CONFIGURATION");
	#30us control_write_transfer(SET_CONFIGURATION, '{}, addr, 0);

	$display("GET_DESCRIPTOR (full)");
	#30us control_read_transfer(GET_DESCRIPTOR, DEVICE_DESCRIPTOR, addr, 0);

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
      #10us send_token(IN, addr, endp);
      receive_data(DATA0, result);
      #20us send_pid(ACK);

      /* Status Transaction */
      #10us send_token(OUT, addr, endp);
      send_data(DATA0); // ZLP
      receive_pid(ACK);
   endtask

   task control_write_transfer(input byte command[], data[], input [6:0] addr, input [3:0] endp);

      /* Setup Transaction */
      send_token(SETUP, addr, endp);
      send_data(DATA0, command);
      receive_pid(ACK);

      /* Data Transaction */
      #10us send_token(OUT, addr, endp);
      send_data(DATA0, data);
      receive_pid(ACK);

      /* Status Transaction */
      #10us send_token(IN, addr, endp);
      receive_data(DATA0); // ZLP
      #20us send_pid(ACK);
   endtask

   task send_pid(input pid_t pid);
      /* PID */
      @(posedge clk);
      $display("%t %M(%p)", $realtime, pid);
      tx_valid <= 1'b1;
      tx_data  <= {~pid, pid};
      do @(posedge clk); while (!tx_ready);

      /* wait for last byte */
      do @(posedge clk); while (!tx_ready);
      tx_valid = 1'b0;

      /* wait for EOP */
      do @(posedge clk); while (tx_d_en);
   endtask

   task send_token(input pid_t pid, input [6:0] addr, input [3:0] endp);
      /* PID */
      @(posedge clk);
      $display("%t %M(pid=%p, addr='h%h, endp=%d)", $realtime, pid, addr, endp);
      tx_valid <= 1'b1;
      tx_data  <= {~pid, pid};
      do @(posedge clk); while (!tx_ready);

      /* ADDR and first bit of ENDP */
      tx_data = {endp[0], addr};
      do @(posedge clk); while (!tx_ready);

      /* Rest of ENDP and CRC5 */
      tx_data = {crc5({endp, addr}), endp[3:1]};
      do @(posedge clk); while (!tx_ready);

      /* wait for last byte */
      do @(posedge clk); while (!tx_ready);
      tx_valid = 1'b0;

      /* wait for EOP */
      do @(posedge clk); while (tx_d_en);
   endtask

   task send_data(input pid_t pid, input byte data[]='{});
      /* PID */
      @(posedge clk);
      tx_valid <= 1'b1;
      tx_data  <= {~pid, pid};
      do @(posedge clk); while (!tx_ready);

      foreach (data[i])
	begin
	   tx_data = data[i];
	   $display("%t %M(%h)", $realtime, tx_data);
	   do @(posedge clk); while (!tx_ready);
	end

      /* CRC16 */
      for (int i = 0; i < 16; i += 8)
	begin
	   tx_data = crc16(data)[7+i-:8];
	   $display("%t %M(%h) CRC", $realtime, tx_data);
	   do @(posedge clk); while (!tx_ready);
	end

      /* wait for last byte */
      do @(posedge clk); while (!tx_ready);
      tx_valid = 1'b0;

      /* wait for EOP */
      do @(posedge clk); while (tx_d_en);
   endtask

   task receive_data(input pid_t expected_pid, input byte expected_data[]='{});
      receive_pid (expected_pid);

      foreach (expected_data[i])
	begin
	   do @(posedge clk); while (!rx_valid);
	   $display("%t %M(%h)", $realtime, rx_data);

	   if (rx_data != expected_data[i])
	     $display ("Error: %t %M (expected = %h, received = %h)", $realtime, expected_data[i], rx_data);
	end

      /* CRC */
      repeat (2)
	begin
	   do @(posedge clk); while (!rx_valid);
	end
   endtask

   task receive_pid(input pid_t expected_pid);
      pid_t received_pid;

      /* PID */
      do @(posedge clk); while (!rx_valid);
      received_pid = pid_t'(rx_data);

      if (received_pid == ACK || received_pid == NAK || received_pid == STALL)
	$display("%t %M(%p)", $realtime, received_pid);

      if (received_pid != expected_pid)
	$display ("Error: %t %M (expected = %p, received = %p)", $realtime, expected_pid, received_pid);
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
