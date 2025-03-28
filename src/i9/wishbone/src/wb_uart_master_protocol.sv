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
    output reg [79:0] data_out,
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
      data_out = {10{8'h00}};
      data_out_valid = 0;
    end else begin
      data_out_valid = 0;
      if (data_in_valid) begin
        data_out[79-:8] = "x";
        data_out[71:8]  = encoded_data;
        data_out[7:0]   = "\n";
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
    output reg [31:0] rw_address,
    output reg [31:0] rw_data,
    output reg rw_write,
    output reg rw_valid,
    // sigaling back
    input rw_ready,
    input [31:0] rw_data_in
);

  logic [18*8-1:0] cmd;


  wire [31:0] r0;
  wire [31:0] r1;
  //assign rw_address = address;
  //assign rw_data = data;
  genvar i;
  generate
    for (i = 1; i <= 8; i++) begin
      ascii_hex2bin r0_decode (
          .ascii (cmd[i*8-1-:8]),
          .nibble(r0[i*4-1-:4])
      );
      ascii_hex2bin r1_decode (
          .ascii (cmd[i*8+63-:8]),
          .nibble(r1[i*4-1-:4])
      );
    end
  endgenerate

  always @(posedge clk) begin
    if (rw_valid) begin
      cmd = {18{8'h00}};
    end
    rw_write <= 0;
    rw_valid <= 0;

    if (rst) begin
      //cmd = {18{8'hff}};
    end else begin
      if (data_in_valid) begin
        //$display("DI: %x (%c) len(%d)", data_in,data_in , cmd_len);
        if (data_in >= 8'h20) begin  // accept value with an chat value above space char(' ')
          //$display("PROTOCOL ADD : %c", data_in);
          cmd = {cmd[17*8-1:0], data_in};  //[cmd_len] <= data_in;
          // cmd_len <= cmd_len + 1;
        end else if (data_in == "\n") begin
          //$display("CMD0: %c", cmd[0]);
          if (cmd[9*8-1-:8] == "r") begin
            //$display("READ CMD");
            //$display("Read address is 0x%08x", r0);
            if (rw_ready) begin
              rw_write   <= 0;
              rw_valid   <= 1;
              rw_address <= r0;
            end else begin
              $display("Skip read (RW BUSY)");
            end
          end
          if (cmd[17*8-1-:8] == "w") begin
            //$display("WRITE CMD");
            //$display("Write address is 0x%08x value 0x%08x", r1, r0);
            if (rw_ready) begin
              rw_write <= 1;
              rw_valid <= 1;
              rw_address <= r1;
              rw_data <= r0;
            end else begin
              $display("Skip write (RW BUSY)");
            end
          end
        end else if (data_in == 8'h00) begin
          $display("PROTOCOL RESET");
          cmd = {18{8'h00}};
        end else begin
          $display("UNCAPTURED VALUE: %c", data_in);
        end
      end
    end
  end
endmodule
