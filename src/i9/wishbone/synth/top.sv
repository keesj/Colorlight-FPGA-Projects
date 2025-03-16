module top (
    input  clk,

    //serial
    input  ser_rx,
    output reg ser_tx,

    //led and gpio
    output reg user_led, // on board led
    output reg [3:0] gpio // GPIO to module

);
  //tx buf
  reg  [  7:0] tx_buf     [0:50];
  reg  [  7:0] tx_buf_len;

  reg          rst;
  rst_gen rst_inst (.clk_i(clk), .rst_i(1'b0), .rst_o(rst));
  //wiring

  assign user_led = gpio[0];
  // wishbone master
  reg          wb_cyc;
  reg          wb_stb;
  reg          wb_we;
  reg  [ 31:0] wb_addr;
  reg  [ 31:0] wb_data_w;
  reg  [4-1:0] wb_sel;
  wire         wb_ack;
  reg  [ 31:0] wb_data_r;
  wire activity ;

  wb_uart_master master (
      .clk(clk),
      .rst(rst),

      .ser_tx(ser_tx),
      .ser_rx(ser_rx),

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

      .gpio(gpio)
  );

//  reg last_activity;
//  always @(posedge clk) begin
//    if (rst) begin
//      last_activity = 0;
//      user_led = 0;
//    end else begin
//      if (~last_activity & activity) begin
//        user_led = ~ user_led;
//      end
//      last_activity = activity;
//    end
//  end
    
endmodule
