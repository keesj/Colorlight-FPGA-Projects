`timescale 1ns / 1ps 
`default_nettype none

module wb_uart_master_tb ();

  //clock generation
  reg clk;
  initial clk = 0;
  always #10 clk = ~clk;

  //tx buf
  //reg  [50*8-1:0] tx_buf;
  string tx_buf;
  reg  [ 7:0] tx_buf_len;

  wire [3:0] gpio;
  wire led;

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

  wire activity;
  wb_uart_master master (
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
      .wb_data_o(wb_data_r),
      .activity(activity)
  );

  //wb slave
  wb_pulse slave (
      .clk(clk),
      .rst(rst),

      //wishbone
      .wb_cyc_i (wb_cyc),
      .wb_stb_i (wb_stb),
      .wb_we_i  (wb_we),
      .wb_addr_i(wb_addr),
      .wb_data_i(wb_data_w),
      .wb_sel_i (wb_sel),

      .wb_ack_o (wb_ack),
      .wb_data_o(wb_data_r),


      // pulse GPIO
      .gpio(gpio)
  );



  task write(string cmd);
    // send tx buffer to uart
    integer i;
    for(i =0 ; i < cmd.len() ; i = i + 1) begin

      $display("%d %c",i, cmd[i]);
      uart0_reg_dat_di = {24'h00_00_00, cmd[i]};
      uart0_reg_dat_we = 1;
      do begin
        @(posedge clk);  // wait for output buffer to be ready
        @(posedge clk);  // wait for output buffer to be ready
        uart0_reg_dat_we = 0;
      end while (uart0_reg_dat_wait);

      repeat (1) @(posedge clk);
    end
  endtask

  //test loop
  initial begin
    $dumpfile("waves.vcd");
    $dumpvars(0, wb_uart_master_tb);

    //write data
    tx_buf = "w0000000000000010\n";
    //read command
    //
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
    uart0_reg_div_di = 217;
    uart0_reg_div_we = 4'b1111;

    do begin
      @(posedge clk);  // wait for output buffer to be ready
      uart0_reg_div_we = 4'b0;
    end while (uart0_reg_dat_wait);

    write("w0000000000000010\n");
    write("r00000000\n");
    repeat (100000) @(posedge clk);
    $finish();
  end

  
  initial begin
    $display("Listen to uart");
    while (1) begin
      while (uart0_reg_dat_do[31:24] == 8'hff) begin
        @(posedge clk);  // wait for output buffer to be ready
      end
      uart0_reg_dat_re = 1;
      $display("%08d Read %c ", $time() , uart0_reg_dat_do[7:0]);
        @(posedge clk);  // wait for output buffer to be ready
        @(posedge clk);  // wait for output buffer to be ready
      uart0_reg_dat_re = 0;
    end
  end

  reg last_activity;
  always @(posedge clk) begin
    if (rst) begin
      last_activity = 0;
    end else begin
      if (~last_activity & activity) begin
        $display("BLINK");
      end
      last_activity = activity;
    end
  end
endmodule
