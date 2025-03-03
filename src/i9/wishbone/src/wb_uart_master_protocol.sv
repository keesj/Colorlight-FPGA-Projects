module ascii_hex2bin (
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

module bin2ascii_hex (
    input  logic [3:0] nibble,
    output logic [7:0] ascii
);
  always_comb begin
    case (nibble)
      4'h0: ascii = "0";
      4'h1: ascii = "1";
      4'h2: ascii = "2";
      4'h3: ascii = "3";
      4'h4: ascii = "4";
      4'h5: ascii = "5";
      4'h6: ascii = "6";
      4'h7: ascii = "7";
      4'h8: ascii = "8";
      4'h9: ascii = "9";
      4'ha: ascii = "a";
      4'hb: ascii = "b";
      4'hc: ascii = "c";
      4'hd: ascii = "d";
      4'he: ascii = "e";
      4'hf: ascii = "f";
      default: ascii = "x";
    endcase
  end
endmodule

module uart_cmd_encode (
    input logic clk,
    input logic rst,

    //input back from a read command
    input logic [31:0] data_in,
    input logic data_in_valid,

    //output
    output reg [71:0] data_out,
    output reg data_out_valid
);

  // 8x8
  wire [63:0] encoded_data;
  genvar i;
  generate
    for (i = 0; i < 8; i++) begin
      bin2ascii_hex data_encode (
          .nibble(data_in[(i+1)*4-1-:4]),
          .ascii (encoded_data[i*8+:8])
      );
    end
  endgenerate

  always @(posedge clk) begin
    if (rst) begin
      data_out = {9{8'h00}};
      data_out_valid = 0;
    end else begin
      data_out_valid = 0;
      if (data_in_valid) begin
        data_out[71-:8] = "x";
        data_out[63:0]  = encoded_data;
        data_out_valid  = 1;
      end
    end
  end
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
      ascii_hex2bin address_decode0 (
          .ascii (cmd[i+1]),
          .nibble(address[31-i*4-:4])
      );
      ascii_hex2bin data_decode0 (
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
