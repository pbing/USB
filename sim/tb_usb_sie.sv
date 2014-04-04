/* Testbench USB Serial Interface Controller */

module tb_usb_sie;
   timeunit 1ns;
   timeprecision 1ps;

   const realtime tusb=1s/1.5e6,  // low speed
		  tclk=1s/24.0e6,
		  nbit=tusb/tclk;

   import types::*;

   bit            clk;                 // system clock (24 MHz)
   if_transceiver transceiver();       // USB tranceiver interface
   if_fifo        endpi0(.clock(clk));
   if_fifo        endpo0(.clock(clk));
   if_fifo        endpi1(.clock(clk));

   var   d_port_t d_o;       // USB port D+,D- (output)
   logic d_en;               // USB port D+,D- (enable)


   byte GET_DESCRIPTOR[]='{8'h80,8'h06,8'h00,8'h01,8'h00,8'h00,8'h08,8'h00};
   byte CHECK1_CRC16[]='{8'h00,8'h01,8'h02,8'h03};
   byte CHECK2_CRC16[]='{8'h23,8'h45,8'h67,8'h89};
   byte SHORT_DEVICE_DESCRIPTOR[]='{8'd18,8'h01,8'h10,8'h01,8'h00,8'h00,8'h00,8'h08};
   byte DEVICE_DESCRIPTOR[]='{8'd18,8'h01,8'h10,8'h01,8'h00,8'h00,8'h00,8'h08,
			      8'hd8,8'h04,8'h01,8'h00,8'h00,8'h02,8'h01,8'h02,
			      8'h00,8'h01};

   usb_sie dut(.*);

   fifo8x16 fifo_endpo0(.clock(endpo0.clock),
			.data(endpo0.data),
			.rdreq(endpo0.rdreq),
			.sclr(endpo0.sclr),
			.wrreq(endpo0.wrreq),
			.empty(endpo0.empty),
			.full(endpo0.full),
			.q(endpo0.q),
			.usedw(endpo0.usedw));

   fifo8x16 fifo_endpi0(.clock(endpi0.clock),
			.data(endpi0.data),
			.rdreq(endpi0.rdreq),
			.sclr(endpi0.sclr),
			.wrreq(endpi0.wrreq),
			.empty(endpi0.empty),
			.full(endpi0.full),
			.q(endpi0.q),
			.usedw(endpi0.usedw));

   usb_tx usb_tx(.reset(transceiver.usb_reset),.clk(clk),
		 .d_o(d_o),.d_en(d_en),
		 .data(transceiver.tx_data),.valid(transceiver.tx_valid),.ready(transceiver.tx_ready));

   initial forever #(tclk/2) clk=~clk;

   initial
     begin:main
	$timeformat(-9,2," ns");

	/* Some tests according to http://www.usb.org/developers/whitepapers/crcdes.pdf */
	assert(crc5({4'he,7'h15})==5'b11101) else $error("CRC5");;
	assert(crc5({4'ha,7'h3a})==5'b00111) else $error("CRC5");;
	assert(crc5({4'h4,7'h70})==5'b01110) else $error("CRC5");;

	assert(crc16('{8'h00,8'h01,8'h02,8'h03})==16'h7aef) else $error("CRC16");
	assert(crc16('{8'h23,8'h45,8'h67,8'h89})==16'h1c0e) else $error("CRC16");
	assert(crc16()                          ==16'h0000) else $error("CRC16"); // zero length packet

	/* initial interface state */
	transceiver.rx_active=1'b0;
	transceiver.rx_valid =1'b0;
	transceiver.rx_error =1'b0;
	transceiver.usb_reset=1'b1;

	endpo0.rdreq=1'b0;
	endpi0.wrreq=1'b0;
	endpi0.data =8'b0;

	repeat(3) @(posedge clk);
	transceiver.usb_reset=1'b0;
	#100ns;

	/**********************************************************************
	 * Control Read Transfer
	 **********************************************************************/

	/* Setup Transaction */
	receive_token(SETUP,0,0);
	receive_data(DATA0,GET_DESCRIPTOR);
	send_pid(ACK);

	/* MCU action */
	io_read_endp0();
	//io_write_endp0(CHECK1_CRC16);
	//io_write_endp0(CHECK2_CRC16);
	io_write_endp0(SHORT_DEVICE_DESCRIPTOR);

	/* Data Transaction */
	#10us receive_token(IN,0,0);
	//send_data(CHECK1_CRC16); // CRC16=16'hf75e
	//send_data(CHECK2_CRC16); // CRC16=16'h7038
	send_data(SHORT_DEVICE_DESCRIPTOR);
	#10us receive_pid(ACK);

	/* Status Transaction */
	#10us receive_token(OUT,0,0);
	receive_data(DATA0); // ZLP
	send_pid(ACK);
	io_read_endp0();

	#10us $stop/*$finish*/;
     end:main

   task io_read_endp0();
      do @(posedge clk); while(endpo0.empty);

      while(!endpo0.empty)
	begin
	   endpo0.rdreq<=1'b1;
	   @(posedge clk);
	   endpo0.rdreq<=1'b0;
	   repeat(30-1) @(posedge clk);
	end
   endtask;

   task io_write_endp0(input byte data[]='{});
      do @(posedge clk); while(endpi0.full);

      foreach(data[i])
	begin
	   endpi0.data  <=data[i];
	   endpi0.wrreq<=1'b1;
	   @(posedge clk);
	   endpi0.wrreq<=1'b0;
	   repeat(30-1) @(posedge clk);
	end
   endtask

   task send_pid(input pid_t pid);
      do @(posedge clk); while(!transceiver.tx_valid);
      assert(transceiver.tx_data=={~pid,pid});
      do @(posedge clk); while(!transceiver.tx_ready);
   endtask

   task send_data(input byte data[]);
      send_pid(DATA0);

      foreach (data[i])
	begin
	   @(posedge clk) assert(transceiver.tx_data==data[i]);
	   do @(posedge clk); while(!transceiver.tx_ready);
	end
   endtask

   task receive_token(input pid_t pid,input [6:0] addr,input [3:0] endp);
      repeat(2) @(posedge clk);
      wait(!transceiver.tx_valid);

      /* PID */
      repeat(8*nbit-1) @(posedge clk);
      transceiver.rx_active<=1'b1;
      transceiver.rx_valid <=1'b1;
      transceiver.rx_data  <={~pid,pid};
      @(posedge clk) transceiver.rx_valid<=1'b0;

      /* ADDR and first bit of ENDP */
      repeat(8*nbit-1) @(posedge clk);
      transceiver.rx_valid<=1'b1;
      transceiver.rx_data <={endp[0],addr};
      @(posedge clk) transceiver.rx_valid<=1'b0;

      /* Rest of ENDP and CRC5 */
      repeat(8*nbit-1) @(posedge clk);
      transceiver.rx_valid<=1'b1;
      transceiver.rx_data <={crc5({endp,addr}),endp[3:1]};
      @(posedge clk) transceiver.rx_valid<=1'b0;

      /* EOP */
      repeat(2*nbit) @(posedge clk);
      transceiver.rx_active<=1'b0;
      @(posedge clk);
   endtask

   task receive_data(input pid_t pid,input byte data[]='{});
      /* PID */
      repeat(8*nbit-1) @(posedge clk);
      transceiver.rx_active<=1'b1;
      transceiver.rx_valid <=1'b1;
      transceiver.rx_data  <={~pid,pid};
      @(posedge clk) transceiver.rx_valid<=1'b0;

      foreach(data[i])
	begin
	   repeat(8*nbit-1) @(posedge clk);
	   transceiver.rx_valid<=1'b1;
	   transceiver.rx_data <=data[i];
	   @(posedge clk) transceiver.rx_valid<=1'b0;
	end

      /* CRC16 */
      for(int i=0;i<16;i+=8)
	begin
	   repeat(8*nbit-1) @(posedge clk);
	   transceiver.rx_valid<=1'b1;
	   transceiver.rx_data <=crc16(data)[7+i-:8];
	   @(posedge clk) transceiver.rx_valid<=1'b0;
	end

      /* EOP */
      repeat(2*nbit) @(posedge clk);
      transceiver.rx_active<=1'b0;
      @(posedge clk);
   endtask

   task receive_random_data(input pid_t pid, input int n);
      byte data[];

      data=new[n];
      for(int i=0;i<n;i++) data[i]=$random;
      receive_data(pid,data);
   endtask

   task receive_pid(input pid_t pid);
      /* PID */
      repeat(8*nbit-1) @(posedge clk);
      transceiver.rx_active<=1'b1;
      transceiver.rx_valid <=1'b1;
      transceiver.rx_data  <={~pid,pid};
      @(posedge clk) transceiver.rx_valid<=1'b0;

      /* EOP */
      repeat(2*nbit) @(posedge clk);
      transceiver.rx_active<=1'b0;
      @(posedge clk);
   endtask

   function [4:0] crc5(input [10:0] d);
      const bit [4:0] crc5_poly=5'b10100,
		      crc5_res =5'b00110;

      crc5='1;

      for(int i=$right(d);i<=$left(d);i++)
	if(crc5[$right(crc5)]^d[i])
	  crc5=(crc5>>1)^crc5_poly;
	else
	  crc5=crc5>>1;

      crc5=~crc5;
   endfunction

   function [15:0] crc16(input byte d[]='{});
      const bit [15:0] crc16_poly=16'b1010000000000001,
		       crc16_res =16'b1011000000000001;

      crc16='1;

      foreach(d[j])
	for(int i=$right(d[j]);i<=$left(d[j]);i++)
	  if(crc16[$right(crc16)]^d[j][i])
	    crc16=(crc16>>1)^crc16_poly;
	  else
	    crc16=crc16>>1;

      crc16=~crc16;
   endfunction
endmodule
