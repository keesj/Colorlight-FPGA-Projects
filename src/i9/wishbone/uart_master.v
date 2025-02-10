module uart_master (
	input clk,
  input rst,

    // UART
    input ser_rx,
    input ser_tx);

    // UART
	reg   [3:0] uart_reg_div_we;
	reg  [31:0] uart_reg_div_di;
	wire [31:0] uart_reg_div_do;

	reg         uart_reg_dat_we;
	reg         uart_reg_dat_re;
	reg  [31:0] uart_reg_dat_di;
	wire [31:0] uart_reg_dat_do;
	wire        uart_reg_dat_wait;
    

  // uart instance
  simpleuart uart0 (
	.clk(clk),
	.resetn(!rst),

	.ser_tx(ser_tx),
	.ser_rx(ser_rx),

	.reg_div_we(uart_reg_div_we),
	.reg_div_di(uart_reg_div_di),
	.reg_div_do(uart_reg_div_do),

	.reg_dat_we(uart_reg_dat_we), // write reg_dat_do
	.reg_dat_re(uart_reg_dat_re), //
	.reg_dat_di(uart_reg_dat_di),
	.reg_dat_do(uart_reg_dat_do),
	.reg_dat_wait(uart_reg_dat_wait) // busy do not send data
);

typedef enum logic [1:0] {
   UART_INIT  =     2'd0,
   UART_SET_DIV  = 2'd1,
   UART_READ  =  2'd2,
   UART_READ_DONE  =  2'd3
} uart_state_t ;

uart_state_t uart_state;

always @(posedge clk) begin
    uart_reg_dat_re <= 0;
    if (rst) begin
      uart_reg_div_we = 0;
      uart_reg_div_di = 0;
      uart_reg_dat_we = 0; // write uart0_reg_dat_do
      uart_reg_dat_re = 0; // read reg
      uart_reg_dat_di = 32'h0;
      uart_state = UART_INIT;
    end else begin
      case (uart_state)
        UART_INIT: begin
          uart_reg_div_di = 32'h00_00_00_08;
          uart_reg_div_we = 4'b1111;
          uart_state = UART_SET_DIV;
        end
        UART_SET_DIV: begin
           uart_state = UART_READ;
           uart_reg_div_we = 4'h0; // clear we 
           uart_reg_dat_re <= 1;   // clear read buffer
        end
        UART_READ: begin // 
          if(uart_reg_dat_do[31:24] == 8'h00) begin
            $display("Read %c", uart_reg_dat_do[7:0]);
            uart_reg_dat_re <= 1;
            uart_state = UART_READ_DONE;
          end
        end
        UART_READ_DONE: begin // 
            uart_state = UART_READ;
        end
        default: begin
        end
      endcase
    end
  end

    //Wishbone
    /*
  reg wb_cyc;
  reg wb_stb;
  reg wb_we;
  reg [31:0]  wb_addr;
  reg [31:0]  wb_data_w;
  reg [4-1:0] wb_sel;
  wire wb_ack;
  reg [31:0] wb_data_r;
  */

    //UART  -> BUFFER
    //ASCII DECODER->END
    //CMD_WRITE_ADDR|ADDRESS
    //CMD_WRITE|ADDRESS
    //CMD_READ|ADDRESS
    //PROTOCOL DECOVER
    //CMD_RESET
    //WISHBONE MASTER
endmodule
