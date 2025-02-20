module uart_master (
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
    input wire [31:0] wb_data_o
);

  // UART
  reg  [ 3:0] uart_reg_div_we;
  reg  [31:0] uart_reg_div_di;
  wire [31:0] uart_reg_div_do;

  reg         uart_reg_dat_we;
  reg         uart_reg_dat_re;
  reg  [31:0] uart_reg_dat_di;
  wire [31:0] uart_reg_dat_do;
  wire        uart_reg_dat_wait;

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

  uart_wishbone_decode decode (
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

  wishone_rw rw (
      .clk(clk),
      .rst(rst),

      //read and write commands
      .rw_address(rw_address),
      .rw_data(rw_data),
      .rw_data_out(rw_data_out),
      .rw_write(rw_write),
      .rw_valid(rw_valid),
      .rw_ready(rw_ready),

      //wishbone
      .wb_cyc_o (wb_cyc_i),
      .wb_stb_o (wb_stb_i),
      .wb_we_o  (wb_we_i),
      .wb_addr_o(wb_addr_i),
      .wb_data_o(wb_data_i),
      .wb_sel_o (wb_sel_i),

      .wb_ack_i (wb_ack_o),
      .wb_data_i(wb_data_o)
  );

  typedef enum logic [1:0] {
    UART_IN_INIT      = 2'd0,
    UART_IN_SET_DIV   = 2'd1,
    UART_IN_READ      = 2'd2,
    UART_IN_READ_DONE = 2'd3
  } uart_in_state_t;

  uart_in_state_t uart_in_state;

  //UART RECIEVE
  always @(posedge clk) begin
    uart_reg_dat_re <= 0;
    input_char <= 8'h00;
    input_char_valid <= 0;
    if (rst) begin
      uart_reg_div_we = 0;
      uart_reg_div_di = 0;
      uart_reg_dat_we = 0;  // write uart0_reg_dat_do
      uart_reg_dat_re <= 0;  // read reg
      uart_reg_dat_di = 32'h0;
      uart_in_state = UART_IN_INIT;
    end else begin
      case (uart_in_state)
        UART_IN_INIT: begin
          uart_reg_div_di = 32'h00_00_00_08;
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

endmodule

module ascii2hex (
    input  logic [7:0] ascii,
    output logic [3:0] nibble
);
  always_comb begin
    case (ascii)
      "0": nibble = 4'h0;
      "1": nibble = 4'h1;
      "2": nibble = 4'h2;
      "3": nibble = 4'h3;
      "4": nibble = 4'h4;
      "5": nibble = 4'h5;
      "6": nibble = 4'h6;
      "7": nibble = 4'h7;
      "8": nibble = 4'h8;
      "9": nibble = 4'h9;
      "a": nibble = 4'ha;
      "b": nibble = 4'hb;
      "c": nibble = 4'hc;
      "d": nibble = 4'hd;
      "e": nibble = 4'he;
      "f": nibble = 4'hf;
      "A": nibble = 4'ha;
      "B": nibble = 4'hb;
      "C": nibble = 4'hc;
      "D": nibble = 4'hd;
      "E": nibble = 4'he;
      "F": nibble = 4'hf;
      default: nibble = 4'h0;
    endcase
  end
endmodule

module uart_wishbone_encode (
    input logic clk,
    input logic rst
);
endmodule

module wishone_rw (
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
    input wire [31:0] wb_data_i
);

  typedef enum logic [1:0] {
    WB_INIT              = 2'd0,
    WB_WAIT_FOR_CMD      = 2'd1,
    WB_READ              = 2'd2,
    WB_WAIT_FOR_WB_READY = 2'd3
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
            state <= WB_WAIT_FOR_CMD;
            if (wb_we_o) begin
              rw_data_out <= wb_data_i;
            end
          end
        end
        default: $display("WB invalid state ");
      endcase
    end
  end
endmodule

module uart_wishbone_decode (
    input logic clk,
    input logic rst,

    //input
    input logic [7:0] data_in,
    input logic data_in_valid,

    //output
    output [31:0] rw_address,
    output [31:0] rw_data,
    output reg rw_write,
    output reg rw_valid,
    input rw_ready,
    input [31:0] rw_data_in
);

  logic [7:0] cmd[18:0];
  logic [4:0] cmd_len;

  wire [31:0] address;
  wire [31:0] data;

  assign rw_address = address;
  assign rw_data = data;
  genvar i;
  generate
    for (i = 0; i < 8; i++) begin
      ascii2hex address_decode0 (
          .ascii (cmd[i+1]),
          .nibble(address[31-i*4-:4])
      );
      ascii2hex data_decode0 (
          .ascii (cmd[i+9]),
          .nibble(data[31-i*4-:4])
      );
    end
  endgenerate

  always @(posedge clk) begin
    rw_write <= 0;
    rw_valid <= 0;
    if (rst) begin
      //cmd = {18{8'hff}};
      cmd_len <= 0;
    end else begin
      if (data_in_valid && cmd_len < 18) begin
        if (data_in >= 8'h20) begin  // accept value with an chat value above space char(' ')
          cmd[cmd_len] <= data_in;
          cmd_len <= cmd_len + 1;
        end else if (data_in == "\n") begin
          case (cmd[0])
            "r": begin
              //$display("READ CMD");
              case (cmd_len)
                8 + 1: begin
                  $display("Read address is 0x%08x", address);
                  cmd_len <= 0;
                  if (rw_ready) begin
                    rw_write <= 0;
                    rw_valid <= 1;
                  end else begin
                    $display("Skip read (RW BUSY)");
                  end
                end
                default: $display("Invalid length");
              endcase
            end
            "w": begin
              //$display("WRITE CMD");
              case (cmd_len)
                16 + 1: begin
                  $display("Write address is 0x%08x value 0x%08x", address, data);
                  cmd_len <= 0;
                  if (rw_ready) begin
                    rw_write <= 1;
                    rw_valid <= 1;
                  end else begin
                    $display("Skip write (RW BUSY)");
                  end
                end
                default: $display("Invalid length");
              endcase
            end
            default: begin
              $display("unknown command %x -> %c", cmd[0], cmd[0]);
              cmd_len <= 0;
            end
          endcase
        end else if (data_in == 8'h00) begin
          $display("RESET ");
        end
      end
    end
  end
endmodule
