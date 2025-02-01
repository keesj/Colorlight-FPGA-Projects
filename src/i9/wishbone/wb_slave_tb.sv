`timescale  1ns/1ps
// TODO : Add set detaulf nettype none
module wb_slave_tb();

  reg clk;
  initial clk = 1;
  always #10 clk = ~clk;

  reg rst;
  reg wb_cyc;
  reg wb_stb;
  reg wb_we;
  reg [31:0]  wb_addr;
  reg [31:0]  wb_data_w;
  reg [4-1:0] wb_sel;

  wire wb_ack;
  wire reg [31:0] wb_data_r;

  wb_slave  slave (
  .clk_i(clk),
  .rst_i(rst),

  //wishbone
  .wb_cyc_i(wb_cyc),
  .wb_stb_i(wb_stb),
  .wb_we_i(wb_we),
  .wb_addr_i(wb_addr),
  .wb_data_i(wb_data_w),
  .wb_sel_i(wb_sel),

  .wb_ack_o(wb_ack),
  .wb_data_o(wb_data_r)
);

initial begin
  $dumpfile("waves.vcd");
  $dumpvars(1,wb_slave_tb);
  rst = 1;
  wb_cyc =0;
  wb_stb =0;
  wb_we =0;
  wb_addr =0;
  wb_data_w =0;
  wb_sel =0;
  @(posedge clk);
  rst <= 0;


  // wishbone write
  wb_sel <= 4'b1111;
  wb_stb <= 1;
  wb_cyc <= 1;
  wb_we <= 1'b1;
  wb_addr <= 32'h1;
  wb_data_w = 32'hcafebabe;
  @(posedge clk);
  while (!wb_ack) @(posedge clk);
  wb_cyc <= 0;
  wb_stb <= 0;
  @(posedge clk);
  wb_stb <= 1;
  wb_cyc <= 1;
  wb_we <= 1'b1;
  wb_addr <= 32'h2;
  wb_data_w = 32'hbebecaca;
  @(posedge clk);
  while (!wb_ack) @(posedge clk);

  wb_cyc <= 0;
  wb_stb <= 0;
  @(posedge clk);

  wb_stb <= 1;
  wb_cyc <= 1;
  wb_we <= 1'b0;
  wb_addr <= 32'h1;
  @(posedge clk);
  while (!wb_ack) @(posedge clk);
  if(wb_data_r != 32'hcafebabe) begin
    $error("data r does not match ");
  end
  $finish();
end
endmodule
