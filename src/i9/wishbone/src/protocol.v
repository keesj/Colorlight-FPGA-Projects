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

module uart_cmd_encode (
    input logic clk,
    input logic rst
);
endmodule

module uart_cmd_decode (
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
    // sigaling back
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
