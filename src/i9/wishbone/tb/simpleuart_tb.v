`timescale 1ns / 1ps
//`default_netype none

module simpleuart_tb ();

  //clock generation
  reg clk;
  initial clk = 0;
  always #10 clk = ~clk;

  //tx buf
  reg  [ 7:0] tx_buf                                 [0:50];
  reg  [ 7:0] tx_buf_len;

  reg         rst;
  //wiring

  wire        ser_tx;
  reg         ser_rx;

  reg  [ 3:0] reg_div_we;
  reg  [31:0] reg_div_di;
  wire [31:0] reg_div_do;

  reg         reg_dat_we;  // write reg_dat_do
  reg         reg_dat_re;  // read reg
  reg  [31:0] reg_dat_di;
  wire [31:0] reg_dat_do;
  wire        reg_dat_wait;  // busy do not send data

  //creation of uart instances
  simpleuart uart_0 (
      .clk(clk),
      .resetn(!rst),

      .ser_tx(ser_tx),
      .ser_rx(ser_rx),

      .reg_div_we(reg_div_we),
      .reg_div_di(reg_div_di),
      .reg_div_do(reg_div_do),

      .reg_dat_we  (reg_dat_we),   // write reg_dat_do
      .reg_dat_re  (reg_dat_re),   //
      .reg_dat_di  (reg_dat_di),
      .reg_dat_do  (reg_dat_do),
      .reg_dat_wait(reg_dat_wait)  // busy do not send data
  );
  //
  //test loop
  initial begin
    $dumpfile("waves.vcd");
    $dumpvars(0, simpleuart_tb);

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


    // uart init
    ser_rx = 0;
    reg_div_we = 0;
    reg_div_di = 0;
    reg_dat_we = 0;  // write reg_dat_do
    reg_dat_re = 0;  // read reg
    reg_dat_di = 32'h0;
    rst = 0;
    @(posedge clk);
    rst = 1;
    @(posedge clk);
    rst = 0;
    @(posedge clk);

    //write divider
    reg_div_di = 32'h00_00_00_10;
    reg_div_we = ~0;
    do begin
      @(posedge clk);  // wait for output buffer to be ready
      reg_div_we = 0;
    end while (reg_dat_wait);

    @(posedge clk);

    //read divider
    @(posedge clk);
    $display("Divider value is %08x", reg_div_do);

    // send tx buffer to uart
    while (tx_buf_len > 0) begin
      $display("Buf %d", tx_buf_len);

      do begin
        @(posedge clk);  // wait for output buffer to be ready
      end while (reg_dat_wait);

      reg_dat_di = {24'h00_00_00, {tx_buf[tx_buf_len-1]}};
      reg_dat_we = 1;

      do begin
        @(posedge clk);
        @(posedge clk);
        reg_dat_we = 0;
      end while (!reg_dat_wait);

      tx_buf_len = tx_buf_len - 1;
    end

    repeat (10) @(posedge clk);
    $finish();
  end

endmodule
