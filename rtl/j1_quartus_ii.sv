/* J1 Forth CPU
 *
 * Quartus II modification
 *     Because unions are not supported by the Quartus II
 *     software we have to work around it.
 *
 * based on
 *     http://excamera.com/sphinx/fpga-j1.html
 *     https://github.com/ros-drivers/wge100_driver
 *     jamesb@willowgarage.com
 */

module j1(input               sys_clk_i, // main clock
	  input               sys_rst_i, // reset
	  input        [15:0] io_din,    // io data in
	  output logic        io_rd,     // io read
	  output logic        io_wr,     // io write
	  output logic [15:0] io_addr,   // io address
	  output logic [15:0] io_dout);  // io data out

   typedef enum logic [2:0] {TAG_UBRANCH,TAG_ZBRANCH,TAG_CALL,TAG_ALU} tag_t;

   typedef enum logic [3:0] {OP_T,OP_N,OP_T_PLUS_N,OP_T_AND_N,
			     OP_T_IOR_N,OP_T_XOR_N,OP_INV_T,OP_N_EQ_T,
			     OP_N_LS_T,OP_N_RSHIFT_T,OP_T_MINUS_1,OP_R,
			     OP_AT,OP_N_LSHIFT_T,OP_DEPTH,OP_N_ULS_T} op_t;

   typedef struct packed {
      logic        tag;
      logic [14:0] immediate;
   } lit_t;

   typedef struct packed {
      tag_t        tag;
      logic [12:0] address;
   } bra_t;

   typedef struct packed {
      tag_t              tag;
      logic              r_to_pc;
      op_t               op;
      logic              t_to_n;
      logic              t_to_r;
      logic              n_to_mem;
      logic              reserved;
      logic signed [1:0] rstack;
      logic signed [1:0] dstack;
   } alu_t;

   logic [15:0] insn;      // instruction
   var   lit_t  insn_lit;  // LIT instruction
   var   bra_t  insn_bra;  // BRANCH instruction
   var   alu_t  insn_alu;  // ALU instruction
   logic [12:0] _pc,pc,    // processor counter
		pc_plus_1; // processor counter + 1
   logic        io_sel;    // I/O select

   /* select instruction types */
   logic is_lit,is_ubranch,is_zbranch,is_call,is_alu;

   /* RAM */
   wire  [15:0] ramrd;  // RAM read data
   logic        _ramWE; // RAM write enable

   /* data stack */
   logic        [15:0] dstack[32]; // data stack memory
   logic        [4:0]  _dsp,dsp;   // data stack pointer
   logic        [15:0] _st0,st0;   // top of data stack
   logic        [15:0] st1;        // next of data stack
   logic               _dstkW;     // data stack write

   /* return stack */
   logic        [15:0] rstack[32]; // return stack memory
   logic        [4:0]  _rsp,rsp;   // return stack pointer
   logic        [15:0]  rst0;      // top of return stack
   logic        [15:0] _rstkD;     // return stack data
   logic               _rstkW;     // return stack write

   dpram8kx16 dpram(.clock(sys_clk_i),

		    .address_a(_pc),
		    .data_a(16'h0),
		    .wren_a(1'b0),
		    .q_a(insn),

		    .address_b(_st0[13:1]),
		    .data_b(st1),
		    .wren_b(_ramWE),
		    .q_b(ramrd));

   /* data and return stack */
   always_ff @(posedge sys_clk_i)
     begin
	if (_dstkW)
	  dstack[_dsp] <= st0;

	if (_rstkW)
	  rstack[_rsp] <= _rstkD;
     end

   always_comb
     begin
	st1  = dstack[dsp];
	rst0 = rstack[rsp];
     end

   /* select instruction types */
   always_comb
     begin
	insn_lit = insn;
	insn_bra = insn;
	insn_alu = insn;

	is_lit     = insn_lit.tag;
	is_ubranch = (insn_bra.tag == TAG_UBRANCH);
	is_zbranch = (insn_bra.tag == TAG_ZBRANCH);
	is_call    = (insn_bra.tag == TAG_CALL);
	is_alu     = (insn_bra.tag == TAG_ALU);
     end

   /* calculate next TOS value */
   always_comb
     if (is_lit)
       _st0  = {1'b0,insn_lit.immediate};
     else
       begin
	  var op_t op;

	  unique case (1'b1)
	    is_ubranch:  op = OP_T;
	    is_zbranch:  op = OP_N;
	    is_call   :  op = OP_T;
	    is_alu    :  op = insn_alu.op;
	    default      op = op_t'('x);
	  endcase

	  case (op)
            OP_T         : _st0 = st0;
            OP_N         : _st0 = st1;
            OP_T_PLUS_N  : _st0 = st0 + st1;
            OP_T_AND_N   : _st0 = st0 & st1;
            OP_T_IOR_N   : _st0 = st0 | st1;
            OP_T_XOR_N   : _st0 = st0 ^ st1;
            OP_INV_T     : _st0 = ~st0;
            OP_N_EQ_T    : _st0 = {16{(st1 == st0)}};
            OP_N_LS_T    : _st0 = {16{($signed(st1) < $signed(st0))}};
            OP_N_RSHIFT_T: _st0 = st1 >> st0[3:0];
            OP_T_MINUS_1 : _st0 = st0 - 16'd1;
            OP_R         : _st0 = rst0;
            OP_AT        : _st0 = (io_sel) ? io_din : ramrd;
            OP_N_LSHIFT_T: _st0 = st1 << st0[3:0];
            OP_DEPTH     : _st0 = {3'b0,rsp,3'b0,dsp};
            OP_N_ULS_T   : _st0 = {16{(st1 < st0)}};
            default        _st0 = 16'hx;
	  endcase
       end

   /* I/O and RAM control */
   always_comb
     begin
	logic wr_en;

	wr_en   = is_alu & insn_alu.n_to_mem;
	io_sel  = (st0[15:14] != 2'b00); // I/O:4000H...FFFFH
	io_rd   = (is_alu && (insn_alu.op == OP_AT) && io_sel);
	io_wr   = wr_en & io_sel;
	io_addr = st0;
	io_dout = st1;
	_ramWE  = wr_en & ~io_sel;       // RAM:0000H...3FFFH
     end

   /* data and return stack control */
   always_comb
     begin
	_dsp   = dsp;
	_dstkW = 1'b0;
	_rsp   = rsp;
	_rstkW = 1'b0;
	_rstkD = 16'hx;

	/* literals */
	if (is_lit)
	  begin
	     _dsp   = dsp + 5'd1;
	     _dstkW = 1'b1;
	  end
	/* ALU operations */
	else if (is_alu)
	  begin
	     logic signed [4:0] dd,rd; // stack delta

	     dd     = insn_alu.dstack;
	     rd     = insn_alu.rstack;
	     _dsp   = dsp + dd;
	     _dstkW = insn_alu.t_to_n;
	     _rsp   = rsp + rd;
	     _rstkW = insn_alu.t_to_r;
	     _rstkD = st0;
	  end
	else
	  /* branch/call */
	  begin
	     if (is_zbranch)
	       /* predicated jump is like DROP */
               _dsp = dsp - 5'd1;

	     if (is_call)
	       begin
		  _rsp   = rsp + 5'd1;
		  _rstkW = 1'b1;
		  _rstkD = pc_plus_1 << 1;
	       end
	  end
     end

   /* control PC */
   always_comb pc_plus_1 = pc + 13'd1;

   always_comb
     if (sys_rst_i)
       _pc = pc;
     else
       if (is_ubranch || (is_zbranch && (st0 == 16'h0)) || is_call)
         _pc = insn_bra.address;
       else if (is_alu && insn_alu.r_to_pc)
         _pc = rst0 >> 1;
       else
         _pc = pc_plus_1;

   /* update PC and stacks */
   always_ff @(posedge sys_clk_i)
     if (sys_rst_i)
       begin
	  pc  <= 13'h0;
	  dsp <=  5'd0;
	  st0 <= 16'h0;
	  rsp <=  5'd0;
       end
     else
       begin
	  pc  <= _pc;
	  dsp <= _dsp;
	  st0 <= _st0;
	  rsp <= _rsp;
       end
endmodule
