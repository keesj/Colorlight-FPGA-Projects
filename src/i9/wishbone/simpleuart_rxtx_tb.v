`timescale  1ns/1ps
`default_nettype none

module simpleuart_rxtx_tb();

  //clock generation
  reg clk;
  initial clk = 0;
  always #10 clk = ~clk;

  //tx buf
	reg   [7:0] tx_buf [0:50];
	reg   [7:0] tx_buf_len;

  reg rst;
  //wiring

	wire ser_tx;
	reg  ser_rx;

	reg   [3:0] uart0_reg_div_we;
	reg  [31:0] uart0_reg_div_di;
	wire [31:0] uart0_reg_div_do;

	reg         uart0_reg_dat_we; // write reg_dat_do
	reg         uart0_reg_dat_re; // read reg
	reg  [31:0] uart0_reg_dat_di;
	wire [31:0] uart0_reg_dat_do;
	wire        uart0_reg_dat_wait; // busy do not send data

	reg   [3:0] uart1_reg_div_we;
	reg  [31:0] uart1_reg_div_di;
	wire [31:0] uart1_reg_div_do;

	reg         uart1_reg_dat_we; // write reg_dat_do
	reg         uart1_reg_dat_re; // read reg
	reg  [31:0] uart1_reg_dat_di;
	wire [31:0] uart1_reg_dat_do;
	wire        uart1_reg_dat_wait; // busy do not send data

  //creation of uart instances
  simpleuart uart0 (
	.clk(clk),
	.resetn(!rst),

	.ser_tx(ser_tx),
	.ser_rx(ser_rx),

	.reg_div_we(uart0_reg_div_we),
	.reg_div_di(uart0_reg_div_di),
	.reg_div_do(uart0_reg_div_do),

	.reg_dat_we(uart0_reg_dat_we), // write reg_dat_do
	.reg_dat_re(uart0_reg_dat_re), //
	.reg_dat_di(uart0_reg_dat_di),
	.reg_dat_do(uart0_reg_dat_do),
	.reg_dat_wait(uart0_reg_dat_wait) // busy do not send data
);

  simpleuart uart1 (
	.clk(clk),
	.resetn(!rst),

	.ser_tx(ser_rx),
	.ser_rx(ser_tx),

	.reg_div_we(uart1_reg_div_we),
	.reg_div_di(uart1_reg_div_di),
	.reg_div_do(uart1_reg_div_do),

	.reg_dat_we(uart1_reg_dat_we), // write reg_dat_do
	.reg_dat_re(uart1_reg_dat_re), //
	.reg_dat_di(uart1_reg_dat_di),
	.reg_dat_do(uart1_reg_dat_do),
	.reg_dat_wait(uart1_reg_dat_wait) // busy do not send data
);
  //test loop
  initial begin
    $dumpfile("waves.vcd");
    $dumpvars(0,simpleuart_rxtx_tb);

    tx_buf[11] = "h";
    tx_buf[10] = "e";
    tx_buf[9] = "l";
    tx_buf[8] = "l";
    tx_buf[7] = "o";
    tx_buf[6] = " ";
    tx_buf[5] = "w";
    tx_buf[4] = "o";
    tx_buf[3] = "r";
    tx_buf[2] = "l";
    tx_buf[1] = "d";
    tx_buf[0] = "!";
    tx_buf_len = 12;
    rst =0;
    @(posedge clk);
    rst =1;
    @(posedge clk);
    rst =0;
    @(posedge clk);

    // uart0 init
	uart0_reg_div_we = 0;
	uart0_reg_div_di = 0;
	uart0_reg_dat_we = 0; // write uart0_reg_dat_do
	uart0_reg_dat_re = 0; // read reg
	uart0_reg_dat_di = 32'h0;

  //write divider and wait 
	uart0_reg_div_di = 32'h00_00_00_08;
	uart0_reg_div_we = 4'b1111;

  do begin
     @ (posedge clk); 
	  uart0_reg_div_we = 0;
  end while(uart0_reg_dat_wait);

  // send tx buffer to uart
  while(tx_buf_len > 0) begin
      uart0_reg_dat_di = {24'h00_00_00, {tx_buf[tx_buf_len-1]}};
      uart0_reg_dat_we = 1;

      do begin
        @ (posedge clk); // wait for output buffer to be ready
        uart0_reg_dat_we = 0;
      end while(uart0_reg_dat_wait);

      @ (posedge clk); // why is this clock cycle needeed?
      tx_buf_len = tx_buf_len -1;
  end
  repeat(10) @(posedge clk);
  $finish();
  end

  initial begin
    // uart1 init
	uart1_reg_div_we = 0;
	uart1_reg_div_di = 0;
	uart1_reg_dat_we = 0; // write uart0_reg_dat_do
	uart1_reg_dat_re = 0; // read reg
	uart1_reg_dat_di = 32'h0;

  //write divider
	uart1_reg_div_di = 32'h00_00_00_08;
	uart1_reg_div_we = 4'b1111;
    repeat(10) @(posedge clk);
  @(posedge clk);
	uart1_reg_div_we = 0;


  // 
	uart1_reg_dat_re = 1;
  @(posedge clk);
	uart1_reg_dat_re = 0;

  //read divider
  @(posedge clk);
  $display("Listen to uart");
    while(1) begin
      while(uart1_reg_dat_do[31:24] == 8'hff) begin
        @ (posedge clk); // wait for output buffer to be ready
      end
	    uart1_reg_dat_re = 1;
      $display("Read %c", uart1_reg_dat_do[7:0]);
      @(posedge clk);
	    uart1_reg_dat_re = 0;
    end
  end
  
  
endmodule
