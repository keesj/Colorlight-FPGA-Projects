//Copyright
`timescale 1ns / 1ps
//Copyright
`default_nettype none

module wb_uart_master_tb ();

  localparam CLK_FREQ = 25_000_000;
`ifdef SIMULATION
  localparam UART_DIVIDER = 10;
`else
  localparam UART_DIVIDER = CLK_FREQ / 115200;
`endif
  //clock generation
  reg clk;
  initial clk = 0;
  always #10 clk = ~clk;

  //tx buf
  reg    [40*8-1:0] tx_buf;
  //string        tx_buf;
  string            rx_buf;

  wire   [     3:0] gpio;
  wire              led;

  reg               rst;
  //wiring

  wire              ser_tx;
  reg               ser_rx;

  reg    [     3:0] uart0_reg_div_we;
  reg    [    31:0] uart0_reg_div_di;
  wire   [    31:0] uart0_reg_div_do;

  reg               uart0_reg_dat_we;  // write reg_dat_do
  reg               uart0_reg_dat_re;  // read reg
  reg    [    31:0] uart0_reg_dat_di;
  wire   [    31:0] uart0_reg_dat_do;
  wire              uart0_reg_dat_wait;  // busy do not send data

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
      .activity (activity)
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


  reg done;

  task read_line(output string line);
    //$display("READ LINE");
    line = "";
    done = 1'h0;

    while (~done) begin
      while (uart0_reg_dat_do[31:24] == 8'hff) begin
        @(posedge clk);  // wait for output buffer to be empty
      end
      if (uart0_reg_dat_do[7:0] == "\n") begin
        //$display("REALLY %08d Read String '%s' ", $time(), line);
        done = 1'h1;
      end else begin
        $sformat(line, "%s%c", line, uart0_reg_dat_do[7:0]);
      end

      uart0_reg_dat_re = 1;
      do begin
        @(posedge clk);  // wait for output buffer to be empty
      end while (uart0_reg_dat_do[31:24] == 8'h00);
      uart0_reg_dat_re = 0;
      @(posedge clk);
    end
    //$display("DONE READ STRING");
  endtask

  task write(reg [40*8-1:0] cmd, integer len);
    // send tx buffer to uart
    integer i;
    //$display("Send string (%s) of length(%d)",  cmd , len);
    for (i = 0; i < len; i = i + 1) begin

      uart0_reg_dat_di = {24'h00_00_00, cmd[40*8-1-:8]};
      uart0_reg_dat_we = 1;
      do begin
        @(posedge clk);  // wait for output buffer to be ready
        @(posedge clk);  // wait for output buffer to be ready
        uart0_reg_dat_we = 0;
      end while (uart0_reg_dat_wait);
      cmd = {cmd[39*8-1:0], 8'h00};

      repeat (1) @(posedge clk);
    end
  endtask

  string response;

  //test loop
  initial begin
    $dumpfile("waves.vcd");
    $dumpvars(0, wb_uart_master_tb);

    //write data
    //tx_buf = "w0000000000000010\n";
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
    uart0_reg_div_di = UART_DIVIDER;
    uart0_reg_div_we = 4'b1111;

    do begin
      @(posedge clk);  // wait for output buffer to be yready
      uart0_reg_div_we = 4'b0;
    end while (uart0_reg_dat_wait);


    //tx_buf = {{"w0000000000000010\n"}, 8'h00, {21{8'h41}}};
    //write({{"w0000000000000018\n"}, {22{8'h41}}}, 18);
    //write(tx_buf, 19);

    //$finish();
    write({{"w0000000100000010\n"}, {22{8'h41}}}, 18);
    write({{"w0000000000000000\n"}, {22{8'h41}}}, 18);

    write({{"r00000001\n"}, {30{8'h41}}}, 10);
    read_line(response);
    assert (response == "x00000010");

    write({{"r00000001\n"}, {30{8'h41}}}, 10);
    read_line(response);
    //$display("Respone: %s", response);
    assert (response == "x00000010");

    write({{"w00000001000000aa\n"}, {22{8'h41}}}, 18);
    write({{"w0000000000000000\n"}, {22{8'h41}}}, 18);
    write({{"r00000001\n"}, {30{8'h41}}}, 10);
    read_line(response);
    //$display("Respone: %s", response);
    assert (response == "x000000aa");

    repeat (1000) @(posedge clk);
    write({{"r00000001\n"}, {30{8'h41}}}, 10);
    read_line(response);
    assert (response == "x000000aa");

    //end
    $finish();
  end


`ifdef SKIP
  initial begin
    $display("Listen to uart");
    @(posedge clk);  // 
    do begin
      $display("RESET SEQ");
      @(posedge clk);  // 
    end while (rst);

    rx_buf = "";
    while (1) begin
      while (uart0_reg_dat_do[31:24] == 8'hff) begin
        @(posedge clk);  // wait for output buffer to be ready
      end
      if (uart0_reg_dat_do[7:0] == "\n") begin
        $display("%08d Read String '%s' ", $time(), rx_buf);
        rx_buf = "";
      end else begin
        $sformat(rx_buf, "%s%c", rx_buf, uart0_reg_dat_do[7:0]);
        //$display("%08d Read %02x ", $time(), uart0_reg_dat_do[7:0]);
      end

      uart0_reg_dat_re = 1;
      do begin
        @(posedge clk);  // wait for output buffer to be empty
      end while (uart0_reg_dat_do[31:24] == 8'h00);
      uart0_reg_dat_re = 0;
      @(posedge clk);
    end
  end
`endif

  reg last_activity;
  always @(posedge clk) begin
    if (rst) begin
      last_activity = 0;
    end else begin
      if (~last_activity & activity) begin
        //$display("BLINK");
      end
      last_activity = activity;
    end
  end
endmodule
