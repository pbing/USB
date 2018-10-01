/* Testbench of usb_sie */

`default_nettype none

module tb_usb_sie;
   timeunit 1ns;
   timeprecision 1ps;

   import types::*;
   import ioaddr::*;

   const realtime tclk   = 1s / 50e6,
		  tbit     = 1s / ((7 * USB_FULL_SPEED + 1) * 1.5e6),
		  tusb_clk = tbit / 4;

   bit usb_clk;
   bit clk;
   bit rst;

   const byte DEVICE_DESCRIPTOR[]       = '{8'd18, 8'h01, 8'h10, 8'h01, 8'h00, 8'h00, 8'h00, 8'h08,
					    8'hd8, 8'h04, 8'h01, 8'h00, 8'h00, 8'h02, 8'h01, 8'h02,
					    8'h00, 8'h01};

   const byte GET_DESCRIPTOR[]          = '{8'h80, 8'h06, 8'h00, 8'h01, 8'h00, 8'h00, 8'h12, 8'h00};
   const byte SET_ADDRESS[]             = '{8'h00, 8'h05, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};
   const byte SET_CONFIGURATION[]       = '{8'h00, 8'h09, 8'h01, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};

   byte get_descriptor[] = GET_DESCRIPTOR;
   byte set_address[]    = SET_ADDRESS;
   byte addr;
   byte dat_i, dat_o;

   if_transceiver transceiver(.clk(usb_clk));
   if_wb          wb(.rst,.clk);

   usb_sie dut(.*);

   always #(tclk / 2)     clk     = ~clk;
   always #(tusb_clk / 2) usb_clk = ~usb_clk;

   initial
     begin:main
        rst                   = 1'b1;
        transceiver.usb_reset = 1'b1;
        transceiver.tx_ready  = 1'b0;
        transceiver.rx_data   = $random;
        transceiver.rx_active = 1'b0;
        transceiver.rx_valid  = 1'b0;
        transceiver.rx_error  = 1'b0;
        wb.cyc                = 1'b0;
        wb.stb                = 1'b0;
        wb.adr                = $random;
        wb.dat_m              = $random;
        wb.we                 = 1'b0;

        repeat (3) @(posedge clk);
        rst = 1'b0;

        repeat (3) @(posedge usb_clk);
        transceiver.usb_reset = 1'b0;

        #1us;
	$display("SET_ADDRESS");
        send_token(SETUP, 0, 0);
        repeat (1 + 2) wb_read(USB_RX_DATA, dat_i);
        send_data(DATA0, SET_ADDRESS);
        repeat (1 + 8 + 2) wb_read(USB_RX_DATA, dat_i);
        wb_write(USB_TX_DATA, {~ACK, ACK});
        receive_pid(ACK);

        repeat (30) @(posedge clk);
        $finish;
     end:main

   /**********************************************************************
    * Tasks
    **********************************************************************/

   task control_read_transfer(input byte command[], result[], input [6:0] addr, input [3:0] endp);
      /* Setup Transaction */
      send_token(SETUP, addr, endp);
      send_data(DATA0, command);
      receive_pid(ACK);

//      fork
//         /* reply from CPU */
//         #(1000 * tclk) endpi0_write(result);
//
//         /* Data Transaction */
//         //repeat (5)
//         //  begin
//         //     send_token(IN, addr, endp);
//         //     receive_pid(NAK, 1);
//         //  end
//      join

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
      transceiver.rx_active <= 1'b1;

      /* PID */
      @(posedge transceiver.clk);
      $display("%t %M(%p)", $realtime, pid);
      transceiver.rx_data  <= {~pid, pid};
      transceiver.rx_valid <= 1'b1;
      @(posedge transceiver.clk);
      transceiver.rx_valid <= 1'b0;
      repeat (7) @(posedge transceiver.clk);
      
      transceiver.rx_active <= 1'b0;
      @(posedge transceiver.clk);
   endtask

   task send_token(input pid_t pid, input [6:0] addr, input [3:0] endp);
      transceiver.rx_active <= 1'b1;

      /* PID */
      @(posedge transceiver.clk);
      $display("%t %M(pid=%p, addr='h%h, endp=%d)", $realtime, pid, addr, endp);
      transceiver.rx_data  <= {~pid, pid};
      transceiver.rx_valid <= 1'b1;
      @(posedge transceiver.clk);
      transceiver.rx_valid <= 1'b0;
      repeat (7) @(posedge transceiver.clk);

      /* ADDR and first bit of ENDP */
      transceiver.rx_data  <= {endp[0], addr};
      transceiver.rx_valid <= 1'b1;
      @(posedge transceiver.clk);
      transceiver.rx_valid <= 1'b0;
      repeat (7) @(posedge transceiver.clk);

      /* Rest of ENDP and CRC5 */
      transceiver.rx_data  <= {crc5({endp, addr}), endp[3:1]};
      transceiver.rx_valid <= 1'b1;
      @(posedge transceiver.clk);
      transceiver.rx_valid <= 1'b0;
      repeat (7) @(posedge transceiver.clk);
      
      transceiver.rx_active <= 1'b0;
      @(posedge transceiver.clk);
   endtask

   task send_data(input pid_t pid, input byte data[] = '{});
      transceiver.rx_active <= 1'b1;

      /* PID */
      @(posedge transceiver.clk);
      $display("%t %M(pid=%p)", $realtime, pid);
      transceiver.rx_data  <= {~pid, pid};
      transceiver.rx_valid <= 1'b1;
      @(posedge transceiver.clk);
      transceiver.rx_valid <= 1'b0;
      repeat (7) @(posedge transceiver.clk);

      foreach (data[i])
	begin
	   $display("%t %M(%h)", $realtime, data[i]);
	   transceiver.rx_data  <= data[i];
           transceiver.rx_valid <= 1'b1;
           @(posedge transceiver.clk);
           transceiver.rx_valid <= 1'b0;
           repeat (7) @(posedge transceiver.clk);
	end

      /* CRC16 */
      for (int i = 0; i < 16; i += 8)
	begin
	   $display("%t %M(%h) CRC", $realtime, crc16(data)[7 + i -: 8]);
	   transceiver.rx_data  <= crc16(data)[7 + i -: 8];
           transceiver.rx_valid <= 1'b1;
           @(posedge transceiver.clk);
           transceiver.rx_valid <= 1'b0;
           repeat (7) @(posedge transceiver.clk);
	end

      transceiver.rx_active <= 1'b0;
      @(posedge transceiver.clk);
   endtask

   task receive_data(input pid_t expected_pid, input byte expected_data[] = '{});
      byte received_data;

      receive_pid (expected_pid);

      foreach (expected_data[i])
	begin
           do @(posedge transceiver.clk); while (!transceiver.tx_valid);
           received_data = transceiver.tx_data;
           transceiver.tx_ready = 1'b1;
           @(posedge transceiver.clk);
           transceiver.tx_ready = 1'b0;
           $display("%t %M(%h)", $realtime, received_data);
           repeat (7) @(posedge transceiver.clk);
        end

      /* CRC */
      repeat (2)
        begin
           do @(posedge transceiver.clk); while (!transceiver.tx_valid);
           received_data = transceiver.tx_data;
           transceiver.tx_ready = 1'b1;
           @(posedge transceiver.clk);
           transceiver.tx_ready = 1'b0;
           $display("%t %M(%h) CRC", $realtime, received_data);
           repeat (7) @(posedge transceiver.clk);
        end

      transceiver.tx_ready = 1'b1;
      @(posedge transceiver.clk);
      transceiver.tx_ready = 1'b0;
   endtask

   task receive_pid(input pid_t expected_pid, bit ignore = 1'b0);
      pid_t received_pid;

      do @(posedge transceiver.clk); while (!transceiver.tx_valid);
      received_pid = pid_t'(transceiver.tx_data);
      transceiver.tx_ready = 1'b1;
      @(posedge transceiver.clk);
      transceiver.tx_ready = 1'b0;

      if (received_pid == ACK || received_pid == NAK || received_pid == STALL)
	$display("%t %M(%p)", $realtime, received_pid);

      assert (received_pid == expected_pid || ignore)
	else $error("expected = %p, received = %p", expected_pid, received_pid);

      repeat (7) @(posedge transceiver.clk);
      transceiver.tx_ready = 1'b1;
      @(posedge transceiver.clk);
      transceiver.tx_ready = 1'b0;
   endtask

   task wb_write(input [15:0] adr, dat_o);
      @(posedge wb.clk);
      wb.cyc   <= 1'b1;
      wb.stb   <= 1'b1;
      wb.adr   <= adr >> 1;
      wb.dat_m <= dat_o;
      wb.we    <= 1'b1;
      @(posedge wb.clk);
      wb.stb   <= 1'b0;
      wb.adr   <= 16'h0;
      wb.dat_m <= 16'h0;
      wb.we    <= 1'b0;
      @(posedge wb.clk);
      wb.cyc   <= 1'b0;
   endtask

   task wb_read(input [15:0] adr, output [15:0] dat_i);
      @(posedge wb.clk);
      wb.cyc   <= 1'b1;
      wb.stb   <= 1'b1;
      wb.adr   <= adr >> 1;
      wb.we    <= 1'b0;
      @(posedge wb.clk);
      wb.stb   <= 1'b0;
      wb.adr   <= 16'h0;
      wb.we    <= 1'b0;
      @(posedge wb.clk);
      wb.cyc   <= 1'b0;
      dat_i    <= wb.dat_s;
   endtask

//   task endpi0_write(input byte data[]);
//      byte control;
//
//      foreach (data[i])
//        begin
//           wb_read(ENDPI0_CONTROL, control);   // read FULL
//           wb_write(ENDPI0_DATA, data[i]);     // write to FIFO
//           wb_write(ENDPI0_CONTROL, 16'h0002); // set ACK
//        end
//   endtask

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
