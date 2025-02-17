module uart_master (
	input clk,
  input rst,

    // UART
    input ser_rx,
    output ser_tx);

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
  simpleuart uart (
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

reg [7:0] input_char;
reg       input_char_valid;

uart_wishbone_decode decode (
  .clk(clk),
  .rst(rst),
  .data_in(input_char),
  .data_in_valid(input_char_valid)
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
    input_char <= 8'h00;
    input_char_valid <=0 ;
    if (rst) begin
      uart_reg_div_we = 0;
      uart_reg_div_di = 0;
      uart_reg_dat_we = 0; // write uart0_reg_dat_do
      uart_reg_dat_re <= 0; // read reg
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
        UART_READ: begin
          if(uart_reg_dat_do[31:24] == 8'h00) begin
            //$display("Read %c", uart_reg_dat_do[7:0]);
            uart_reg_dat_re <= 1;
            uart_state = UART_READ_DONE;
            //
            input_char <= uart_reg_dat_do[7:0];
            input_char_valid <=1 ;
          end
        end
        UART_READ_DONE: begin 
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

module ascii2hex(
  input logic  [7:0] ascii,
  output logic [3:0] nibble
);
  always_comb begin
    case(ascii)
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
      default:;
    endcase
  end
endmodule

module uart_wishbone_decode (
  input logic clk,
  input logic rst,

  input logic [7:0] data_in,
  input logic data_in_valid);

  logic [7:0] cmd [18:0];
  logic [4:0] cmd_len;

//  typedef enum logic [1:0] {
//     DECODE_FILL  =     2'd0,
//     DECODE_EVAL = 2'd1
//  } decode_state_t ;

 
  wire [31:0] address;
  wire [31:0] data;

  genvar i;
  generate
    for (i=0 ; i < 8 ; i++) begin
      ascii2hex ai0 ( .ascii(cmd[i+1]), .nibble(address[31-i*4-:4]));
      ascii2hex di0 ( .ascii(cmd[i+9]), .nibble(data[31-i*4-:4]));
    end
  endgenerate

  always @(posedge clk) begin
    if (rst) begin
      //cmd = {18{8'hff}};
      cmd_len <= 0;
    end else begin
      if (data_in_valid && cmd_len < 18) begin
        if (data_in >= 8'h20)  begin // accept value with an chat value above space char(' ')
          cmd[cmd_len] <=  data_in;
          cmd_len <= cmd_len +1;
          //$display("Data valid %c cmd_len %d", data_in, cmd_len);
        end else if (data_in == "\n")  begin
            //$display("CMD_LEN=%i %x",cmd_len, cmd[cmd_len-1]);
            case (cmd[0])
              "r": begin
                //$display("READ CMD");
                case(cmd_len)
                  8+1: begin
                    $display("Read address is 0x%08x", address);
                    cmd_len <=0;
                  end
                  default:
                    $display("Invalid length");
                endcase
              end
              "w": begin
                //$display("WRITE CMD");
                case(cmd_len)
                  16+1: begin
                    $display("Write address is 0x%08x value 0x%08x", address,data);
                    cmd_len <=0;
                  end
                  default:
                    $display("Invalid lenght");
                endcase
              end
              default: begin
                $display("unknown command %x -> %c",cmd[0],cmd[0]);
                cmd_len <=0;
              end
            endcase
        end else if (data_in == 8'h00)  begin
            $display("RESET ");
        end
      end
    end
  end

endmodule
