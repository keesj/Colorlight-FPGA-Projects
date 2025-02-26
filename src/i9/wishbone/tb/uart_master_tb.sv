`timescale 1ns / 1ps 
`default_nettype none

module uart_master_tb ();

  //clock generation
  reg clk;
  initial clk = 0;
  always #10 clk = ~clk;

  //tx buf
  reg  [ 7:0] tx_buf                                       [0:50];
  reg  [ 7:0] tx_buf_len;

  reg         rst;
  //wiring

  wire        ser_tx;
  reg         ser_rx;

  reg  [ 3:0] uart0_reg_div_we;
  reg  [31:0] uart0_reg_div_di;
  wire [31:0] uart0_reg_div_do;

  reg         uart0_reg_dat_we;  // write reg_dat_do
  reg         uart0_reg_dat_re;  // read reg
  reg  [31:0] uart0_reg_dat_di;
  wire [31:0] uart0_reg_dat_do;
  wire        uart0_reg_dat_wait;  // busy do not send data


  //creation of uart instances
  simpleuart uart0 (
      .clk(clk),
      .resetn(!rst),

      .ser_tx(ser_tx),
      .ser_rx(ser_rx),

      .reg_div_we(uart0_reg_div_we),
      .reg_div_di(uart0_reg_div_di),
      .reg_div_do(uart0_reg_div_do),

      .reg_dat_we  (uart0_reg_dat_we),   // write reg_dat_do
      .reg_dat_re  (uart0_reg_dat_re),   //
      .reg_dat_di  (uart0_reg_dat_di),
      .reg_dat_do  (uart0_reg_dat_do),
      .reg_dat_wait(uart0_reg_dat_wait)  // busy do not send data
  );

  // wishbone master
  reg wb_cyc;
  reg wb_stb;
  reg wb_we;
  reg [31:0] wb_addr;
  reg [31:0] wb_data_w;
  reg [4-1:0] wb_sel;
  wire wb_ack;
  reg [31:0] wb_data_r;

  uart_master master (
      .clk(clk),
      .rst(rst),

      .ser_tx(ser_rx),
      .ser_rx(ser_tx),

      .wb_cyc_i (wb_cyc),
      .wb_stb_i (wb_stb),
      .wb_we_i  (wb_we),
      .wb_addr_i(wb_addr),
      .wb_data_i(wb_data_w),
      .wb_sel_i (wb_sel),
      .wb_ack_o (wb_ack),
      .wb_data_o(wb_data_r)
  );

  //wb slave
  wb_slave slave (
      .clk_i(clk),
      .rst_i(rst),

      //wishbone
      .wb_cyc_i (wb_cyc),
      .wb_stb_i (wb_stb),
      .wb_we_i  (wb_we),
      .wb_addr_i(wb_addr),
      .wb_data_i(wb_data_w),
      .wb_sel_i (wb_sel),

      .wb_ack_o (wb_ack),
      .wb_data_o(wb_data_r)
  );


  integer i;

  //test loop
  initial begin
    $dumpfile("waves.vcd");
    $dumpvars(0, uart_master_tb);

    //write data
    tx_buf[0] = "w";
    tx_buf[1] = "0";
    tx_buf[2] = "0";
    tx_buf[3] = "0";
    tx_buf[4] = "0";
    tx_buf[5] = "0";
    tx_buf[6] = "0";
    tx_buf[7] = "0";
    tx_buf[8] = "1";

    tx_buf[9] = "8";
    tx_buf[10] = "7";
    tx_buf[11] = "6";
    tx_buf[12] = "5";
    tx_buf[13] = "4";
    tx_buf[14] = "3";
    tx_buf[15] = "2";
    tx_buf[16] = "1";
    tx_buf[17] = "\n";
    //read command
    tx_buf[18] = "r";
    tx_buf[19] = "0";
    tx_buf[20] = "0";
    tx_buf[21] = "0";
    tx_buf[22] = "0";
    tx_buf[23] = "0";
    tx_buf[24] = "0";
    tx_buf[25] = "0";
    tx_buf[26] = "1";
    tx_buf[27] = "\n";
    tx_buf_len = 28;

    // initial values
    uart0_reg_div_we = 0;
    uart0_reg_div_di = 0;
    uart0_reg_dat_we = 0;  // write uart0_reg_dat_do
    uart0_reg_dat_re = 0;  // read reg
    uart0_reg_dat_di = 32'h0;

    rst = 0;
    @(posedge clk);
    rst = 1;
    @(posedge clk);
    rst = 0;
    @(posedge clk);

    //write divider and wait 
    uart0_reg_div_di = 32'h00_00_00_08;
    uart0_reg_div_we = 4'b1111;

    do begin
      @(posedge clk);  // wait for output buffer to be ready
      uart0_reg_div_we = 4'b0;
    end while (uart0_reg_dat_wait);

    // send tx buffer to uart
    while (tx_buf_len > 0) begin
      uart0_reg_dat_di = {24'h00_00_00, {tx_buf[0]}};
      uart0_reg_dat_we = 1;
      do begin
        @(posedge clk);  // wait for output buffer to be ready
        @(posedge clk);  // wait for output buffer to be ready
        uart0_reg_dat_we = 0;
      end while (uart0_reg_dat_wait);

      repeat (10) @(posedge clk);


      tx_buf_len = tx_buf_len - 1;
      for (int i = 0; i < 50; i++) begin
        tx_buf[i] = tx_buf[i+1];
      end
    end
    repeat (1000) @(posedge clk);
    $finish();
  end

  initial begin
    $display("Listen to uart");
    while (1) begin
      while (uart0_reg_dat_do[31:24] == 8'hff) begin
        @(posedge clk);  // wait for output buffer to be ready
      end
      uart0_reg_dat_re = 1;
      $display("Read %c", uart0_reg_dat_do[7:0]);
      @(posedge clk);
      uart0_reg_dat_re = 0;
    end
  end
endmodule
