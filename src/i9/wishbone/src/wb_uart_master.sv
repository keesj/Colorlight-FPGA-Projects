module wb_uart_master (
    input  clk,
    input  rst,
    // UART
    input  ser_rx,
    output ser_tx,

    //WISHBONE 
    output wire wb_cyc_i,
    output wire wb_stb_i,
    output wire wb_we_i,
    output wire [31:0] wb_addr_i,
    output wire [31:0] wb_data_i,
    output wire [4-1:0] wb_sel_i,

    input wire wb_ack_o,
    input wire [31:0] wb_data_o,
    //debug
    output activity
);

  localparam CLK_FREQ = 25_000_000;
  localparam UART_DIVIDER = CLK_FREQ / 115200;
  localparam ECHO = 1;


  // UART
  reg  [ 3:0] uart_reg_div_we;
  reg  [31:0] uart_reg_div_di;
  wire [31:0] uart_reg_div_do;

  reg         uart_reg_dat_we;
  reg         uart_reg_dat_re;
  reg  [31:0] uart_reg_dat_di;
  wire [31:0] uart_reg_dat_do;
  wire        uart_reg_dat_wait;

  //tx buf
  reg  [71:0] tx_buf;
  reg  [ 7:0] tx_buf_len;

  // uart instance
  simpleuart uart (
      .clk(clk),
      .resetn(!rst),

      .ser_tx(ser_tx),
      .ser_rx(ser_rx),

      .reg_div_we(uart_reg_div_we),
      .reg_div_di(uart_reg_div_di),
      .reg_div_do(uart_reg_div_do),

      .reg_dat_we  (uart_reg_dat_we),   // write reg_dat_do
      .reg_dat_re  (uart_reg_dat_re),   //
      .reg_dat_di  (uart_reg_dat_di),
      .reg_dat_do  (uart_reg_dat_do),
      .reg_dat_wait(uart_reg_dat_wait)  // busy do not send data
  );

  wire [31:0] rw_address;
  wire [31:0] rw_data;
  wire [31:0] rw_data_out;
  wire        rw_write;
  wire        rw_valid;
  wire        rw_ready;

  reg  [ 7:0] input_char;
  reg         input_char_valid;

  uart_cmd_decode cmd_decode (
      .clk(clk),
      .rst(rst),
      //data interface
      .data_in(input_char),
      .data_in_valid(input_char_valid),

      //read and write commands
      .rw_address(rw_address),
      .rw_data(rw_data),
      .rw_data_in(rw_data_out),
      .rw_write(rw_write),
      .rw_valid(rw_valid),
      .rw_ready(rw_ready)
  );

  wire [31:0] response_data;
  wire response_data_valid;
  wire response_data_ready;
  assign response_data_ready = tx_buf_len == 0;

  wire [71:0] encode_data_buf;
  wire encode_data_buf_valid;

  uart_cmd_encode cmd_encode (
      .clk(clk),
      .rst(rst),
      .data_in(response_data),
      .data_in_valid(response_data_valid),
      .data_out(encode_data_buf),
      .data_out_valid(encode_data_buf_valid)
  );
  wishone_request wishbone_request (
      .clk(clk),
      .rst(rst),

      //read and write commands
      .rw_address(rw_address),
      .rw_data(rw_data),
      .rw_data_out(rw_data_out),
      .rw_write(rw_write),
      .rw_valid(rw_valid),
      .rw_ready(rw_ready),


      //wishbone bus interface
      .wb_cyc_o (wb_cyc_i),
      .wb_stb_o (wb_stb_i),
      .wb_we_o  (wb_we_i),
      .wb_addr_o(wb_addr_i),
      .wb_data_o(wb_data_i),
      .wb_sel_o (wb_sel_i),

      .wb_ack_i (wb_ack_o),
      .wb_data_i(wb_data_o),
      .response_data(response_data),
      
      //OUTPUT
      .response_data_valid(response_data_valid),
      .response_data_ready(response_data_ready)
  );

  typedef enum logic [1:0] {
    UART_IN_INIT      = 2'd0,
    UART_IN_SET_DIV   = 2'd1,
    UART_IN_READ      = 2'd2,
    UART_IN_READ_DONE = 2'd3
  } uart_in_state_t;

  uart_in_state_t uart_in_state;

  reg [7:0] uart_echo_char;
  reg uart_echo_valid;
  reg uart_echo_busy;

  //UART RECIEVE
  always @(posedge clk) begin
    uart_reg_dat_re <= 0;
    input_char <= 8'h00;
    input_char_valid <= 0;
    if (rst) begin
      uart_reg_div_we = 0;
      uart_reg_div_di = 0;
      uart_in_state = UART_IN_INIT;
      uart_echo_valid <=0;
      uart_echo_char <= 8'h00;
    end else begin
      if (~uart_echo_busy) begin
        uart_echo_valid <= 0;
        uart_echo_char <= 8'h00;
      end
      case (uart_in_state)
        UART_IN_INIT: begin
          uart_reg_div_di = UART_DIVIDER;
          uart_reg_div_we = 4'b1111;
          uart_in_state = UART_IN_SET_DIV;
        end
        UART_IN_SET_DIV: begin
          uart_in_state = UART_IN_READ;
          uart_reg_div_we = 4'h0;  // clear we 
          uart_reg_dat_re <= 1;  // clear read buffer
        end
        UART_IN_READ: begin
          if (uart_reg_dat_do[31:24] == 8'h00) begin
            //$display("Read %c", uart_reg_dat_do[7:0]);
            uart_reg_dat_re <= 1;
            uart_in_state = UART_IN_READ_DONE;
            //
            input_char <= uart_reg_dat_do[7:0];
            input_char_valid <= 1;

            if (ECHO) begin
              if (~uart_echo_busy) begin
                uart_echo_valid <= 1;
                uart_echo_char <= uart_reg_dat_do[7:0] + 1;
              end else begin
                $display("UART ECHO SKIP (BUSY)");
              end
            end
          end
        end
        UART_IN_READ_DONE: begin
          uart_in_state = UART_IN_READ;
        end
        default: begin
        end
      endcase
    end
  end

  typedef enum logic [1:0] {
    UART_OUT_WAIT      = 2'd0,
    UART_OUT_CLK_OUT      = 2'd1,
    UART_OUT_WAIT_READY      = 2'd2
  } uart_out_state_t;

  uart_out_state_t uart_out_state;

  assign activity = uart_out_state == UART_OUT_WAIT_READY;
  //UART SEND
  always @(posedge clk) begin
    if (rst) begin
      uart_out_state = UART_OUT_WAIT;
      tx_buf_len = 0;
      tx_buf = {9{8'h00}};
      uart_echo_busy <= 0;
      uart_reg_dat_we = 0;  // read reg
      uart_reg_dat_di = 32'h0;
    end else begin
      // only set echo busy low when valid is low
      if (~uart_echo_valid) begin
        uart_echo_busy <= 0;
      end
      case (uart_out_state)
        UART_OUT_WAIT: begin
          if(encode_data_buf_valid) begin
            $display("Set output buffer to %x", encode_data_buf);
            tx_buf[71:0] = encode_data_buf;
            tx_buf_len = 9;
          end else if (uart_echo_valid) begin 
            tx_buf = {uart_echo_char,tx_buf[63:0]};
            tx_buf_len = tx_buf_len +1;
            uart_echo_busy <= 1;
          end
          // if there is data to send 
          if (tx_buf_len >0 && ~uart_reg_dat_wait) begin
            uart_reg_dat_di = {24'h00_00_00, {tx_buf[71-:8]}};
            uart_reg_dat_we = 1;
            uart_out_state = UART_OUT_CLK_OUT;
          end
        end
        UART_OUT_CLK_OUT: begin
            uart_out_state = UART_OUT_WAIT_READY;
        end
        UART_OUT_WAIT_READY: begin
            uart_reg_dat_we = 0;
            if(~ uart_reg_dat_wait) begin
                uart_out_state = UART_OUT_WAIT;
                tx_buf_len = tx_buf_len -1;
                tx_buf = {tx_buf[63:0],8'h00};
            end
        end
        default: begin
        end
      endcase
    end
  end

endmodule

module wishone_request (
    input logic clk,
    input logic rst,
    //commands
    input [31:0] rw_address,
    input [31:0] rw_data,
    input rw_write,
    input rw_valid,
    output reg [31:0] rw_data_out,
    output reg rw_ready,

    //wishbone
    output reg wb_cyc_o,
    output reg wb_stb_o,
    output reg wb_we_o,
    output reg [31:0] wb_addr_o,
    output reg [31:0] wb_data_o,
    output reg [4-1:0] wb_sel_o,

    input wire wb_ack_i,
    input wire [31:0] wb_data_i,

    //response out
    output reg [31:0] response_data,
    output reg        response_data_valid,
    input             response_data_ready
);

  typedef enum logic [2:0] {
    WB_INIT              = 3'd0,
    WB_WAIT_FOR_CMD      = 3'd1,
    WB_READ              = 3'd2,
    WB_WAIT_FOR_WB_READY = 3'd3,
    WB_WAIT_FOR_RESPONE_READY = 3'd4
  } wb_state_t;

  wb_state_t state;

  always @(posedge clk) begin
    if (rst) begin
      rw_ready <= 1;
      state <= WB_INIT;
    end else begin
      case (state)
        WB_INIT: begin
          wb_cyc_o <= 0;
          wb_stb_o <= 0;
          wb_we_o <= 0;
          wb_addr_o <= 0;
          wb_data_o <= 0;
          wb_sel_o <= 0;
          state <= WB_WAIT_FOR_CMD;
          response_data <= 32'h00_00_00_00;
          response_data_valid <= 0;
        end
        WB_WAIT_FOR_CMD: begin
          if (rw_valid) begin  // initiate transaction
            wb_addr_o <= rw_address;
            if (rw_write) begin
              wb_we_o   <= 1;
              wb_data_o <= rw_data;
            end else begin
              wb_we_o <= 0;
            end
            wb_sel_o <= 4'b1111;
            wb_stb_o <= 1;
            wb_cyc_o <= 1;
            state <= WB_WAIT_FOR_WB_READY;
          end
        end
        WB_WAIT_FOR_WB_READY: begin
          if (wb_ack_i) begin
            wb_sel_o <= 0;
            wb_stb_o <= 0;
            wb_cyc_o <= 0;
            wb_we_o <= 0;
            if (wb_we_o) begin
              rw_data_out <= wb_data_i;
              state <= WB_WAIT_FOR_RESPONE_READY;
              if (response_data_ready) begin
                response_data <= wb_data_i;
                response_data_valid <= 1;
              end else begin
                $display("Skip sending response (BUSY) %x",response_data_ready);
              end
            end else begin
              state <= WB_WAIT_FOR_CMD;
            end
          end
        end
        WB_WAIT_FOR_RESPONE_READY: begin
          if (response_data_ready) begin
                response_data <= 32'h00_00_00_00;
                response_data_valid <= 0;
                state <= WB_WAIT_FOR_CMD;
          end
        end
        default: $display("WB invalid state ");
      endcase
    end
  end
endmodule
