/*
 *  ECP5 PicoRV32 demo
 *
 *  Copyright (C) 2017  Clifford Wolf <clifford@clifford.at>
 *  Copyright (C) 2018  David Shah <dave@ds0.me>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

`ifdef PICORV32_V
`error "attosoc.v must be read before picorv32.v!"
`endif

`define PICORV32_REGS picosoc_regs

module attosoc (
	input clk,
	output reg [7:0] led,
	output reg user_led,
	output uart_tx,
	input uart_rx
);


	reg [5:0] reset_cnt = 0;
	wire resetn = &reset_cnt;

  blink b(
    .clk(clk),
    .rstn(resetn),
    .out(user_led)
  );

	always @(posedge clk) begin
		reset_cnt <= reset_cnt + !resetn;
	end

	parameter integer MEM_WORDS = 8192;
	parameter [31:0] STACKADDR = 32'h 0000_0000 + (4*MEM_WORDS);       // end of memory
	parameter [31:0] PROGADDR_RESET = 32'h 0000_0000;       // start of memory

	reg [31:0] ram [0:MEM_WORDS-1];
	initial $readmemh("console/firmware.hex", ram);
	reg [31:0] ram_rdata;
	reg ram_ready;

	wire mem_valid;
	wire mem_instr;
	wire mem_ready;
	wire [31:0] mem_addr;
	wire [31:0] mem_wdata;
	wire [3:0] mem_wstrb;
	wire [31:0] mem_rdata;

	always @(posedge clk)
        begin
		ram_ready <= 1'b0;
		if (mem_addr[31:24] == 8'h00 && mem_valid) begin
			if (mem_wstrb[0]) ram[mem_addr[23:2]][7:0] <= mem_wdata[7:0];
			if (mem_wstrb[1]) ram[mem_addr[23:2]][15:8] <= mem_wdata[15:8];
			if (mem_wstrb[2]) ram[mem_addr[23:2]][23:16] <= mem_wdata[23:16];
			if (mem_wstrb[3]) ram[mem_addr[23:2]][31:24] <= mem_wdata[31:24];

			ram_rdata <= ram[mem_addr[23:2]];
			ram_ready <= 1'b1;
		end
        end

	wire iomem_valid;
	reg iomem_ready;
	wire [31:0] iomem_addr;
	wire [31:0] iomem_wdata;
	wire [3:0] iomem_wstrb;
	wire [31:0] iomem_rdata;

	assign iomem_valid = mem_valid && (mem_addr[31:24] > 8'h 01);
	assign iomem_wstrb = mem_wstrb;
	assign iomem_addr = mem_addr;
	assign iomem_wdata = mem_wdata;

	wire        simpleuart_reg_div_sel = mem_valid && (mem_addr == 32'h 0200_0004);
	wire [31:0] simpleuart_reg_div_do;

	wire        simpleuart_reg_dat_sel = mem_valid && (mem_addr == 32'h 0200_0008);
	wire [31:0] simpleuart_reg_dat_do;
	wire simpleuart_reg_dat_wait;

	always @(posedge clk) begin
		iomem_ready <= 1'b0;
	  if (iomem_valid && iomem_wstrb[0] && mem_addr == 32'h 02000000) begin
	    led <= iomem_wdata[7:0];
			iomem_ready <= 1'b1;
		end
	end


	assign mem_ready = (iomem_valid && iomem_ready) ||
	                   simpleuart_reg_div_sel || (simpleuart_reg_dat_sel && !simpleuart_reg_dat_wait) ||
										 ram_ready;

	assign mem_rdata = simpleuart_reg_div_sel ? simpleuart_reg_div_do :
										 simpleuart_reg_dat_sel ? simpleuart_reg_dat_do :
 											ram_rdata;

	picorv32 #(
		.STACKADDR(STACKADDR),
		.PROGADDR_RESET(PROGADDR_RESET),
		.PROGADDR_IRQ(32'h 0000_0000),
		.BARREL_SHIFTER(0),
		.COMPRESSED_ISA(1),
		.ENABLE_MUL(0),
		.ENABLE_DIV(0),
		.ENABLE_IRQ(0),
		.ENABLE_IRQ_QREGS(0)
	) cpu (
		.clk         (clk        ),
		.resetn      (resetn     ),
		.mem_valid   (mem_valid  ),
		.mem_instr   (mem_instr  ),
		.mem_ready   (mem_ready  ),
		.mem_addr    (mem_addr   ),
		.mem_wdata   (mem_wdata  ),
		.mem_wstrb   (mem_wstrb  ),
		.mem_rdata   (mem_rdata  )
	);

	simpleuart simpleuart (
		.clk         (clk         ),
		.resetn      (resetn      ),

		.ser_tx      (uart_tx     ),
		.ser_rx      (uart_rx     ),

		.reg_div_we  (simpleuart_reg_div_sel ? mem_wstrb : 4'b 0000),
		.reg_div_di  (mem_wdata),
		.reg_div_do  (simpleuart_reg_div_do),

		.reg_dat_we  (simpleuart_reg_dat_sel ? mem_wstrb[0] : 1'b 0),//mem_wstrb -> write data
		.reg_dat_re  (simpleuart_reg_dat_sel && !mem_wstrb),         //when accessing the memory and not writing (read operation)
		.reg_dat_di  (mem_wdata),                                    //data to uart
		.reg_dat_do  (simpleuart_reg_dat_do),                        //data read from UART ip block
		.reg_dat_wait(simpleuart_reg_dat_wait)                       //busy flag
);

endmodule

// Implementation note:
// Replace the following two modules with wrappers for your SRAM cells.

module picosoc_regs (
	input clk, wen,
	input [5:0] waddr,
	input [5:0] raddr1,
	input [5:0] raddr2,
	input [31:0] wdata,
	output [31:0] rdata1,
	output [31:0] rdata2
);
	reg [31:0] regs [0:31];

	always @(posedge clk)
		if (wen) regs[waddr[4:0]] <= wdata;

	assign rdata1 = regs[raddr1[4:0]];
	assign rdata2 = regs[raddr2[4:0]];
endmodule

module blink(
  input clk,
  input rstn,
  output reg out);

  //localparam FREQ  = 25_000_000;
  localparam FREQ  = 12_500_000;
  localparam MAX   = FREQ/1;
  localparam WIDTH = $clog2(FREQ);

  reg [WIDTH-1:0] cnt;

  wire toggle = cnt == MAX[WIDTH-1:0] - 1;

  always @(posedge clk) begin
    if (!rstn) begin
        cnt <= 0;
        out = 1'b0;
    end else begin
        cnt <= cnt +1;
        if (toggle) begin
          cnt <= 0;
          out = !out;
        end
    end
  end

endmodule
