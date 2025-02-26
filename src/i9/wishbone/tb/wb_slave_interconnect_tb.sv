`timescale  1ns/1ps
`default_nettype none
module wb_slave_interconnect_tb();

  reg clk;
  initial clk = 1;
  always #10 clk = ~clk;

  reg rst;

  //master
  reg wb_cyc;
  reg wb_stb;
  reg wb_we;
  reg [31:0]  wb_addr;
  reg [31:0]  wb_data_w;
  reg [4-1:0] wb_sel;
  wire wb_ack;
  reg [31:0] wb_data_r;

  //slave
  wire sl_wb_cyc;
  wire sl_wb_stb;
  wire sl_wb_we;
  wire [31:0]  sl_wb_addr;
  wire [31:0]  sl_wb_data_w;
  wire [4-1:0] sl_wb_sel;
  wire sl_wb_ack;
  wire [31:0] sl_wb_data_r;

//wb_intercon intercom (
wb_intercon #( 
  .MASTERS_NUM(1), 
  .SLAVES_NUM(1),
  .ADDR_WIDTH(32),
  .DATA_WIDTH(32),
  .SEL_WIDTH(4)
  ) intercom (
    .clk_i(clk),
    .rst_i(rst),

    // master
    .m2i_cyc_i(wb_cyc),
    .m2i_stb_i(wb_stb),
    .m2i_we_i(wb_we),
    .m2i_adr_i(wb_addr),
    .m2i_dat_i(wb_data_w),
    .m2i_sel_i(wb_sel),
    .i2m_ack_o(wb_ack),
    .i2m_dat_o(wb_data_r),

    //
    // slave(s)
    //
    .i2s_stb_o(sl_wb_stb),
    .i2s_cyc_o(sl_wb_cyc),
    .i2s_we_o(sl_wb_we),

    .i2s_adr_o(sl_wb_addr),
    .i2s_sel_o(sl_wb_sel),
    .s2i_dat_i(sl_wb_data_r),
    .i2s_dat_o(sl_wb_data_w),

    .s2i_ack_i(sl_wb_ack)
    );

  wb_slave  slave (
  .clk_i(clk),
  .rst_i(rst),

  //wishbone
  .wb_cyc_i(sl_wb_cyc),
  .wb_stb_i(sl_wb_stb),
  .wb_we_i(sl_wb_we),
  .wb_addr_i(sl_wb_addr),
  .wb_data_i(sl_wb_data_w),
  .wb_sel_i(sl_wb_sel),

  .wb_ack_o(sl_wb_ack),
  .wb_data_o(sl_wb_data_r)
);

initial begin
  $dumpfile("waves.vcd");
  $dumpvars(0,wb_slave_interconnect_tb);
  rst = 1;
  wb_cyc =0;
  wb_stb =0;
  wb_we =0;
  wb_addr =0;
  wb_data_w =0;
  wb_sel =0;
  @(posedge clk);
  rst <= 0;


  @(posedge clk);

  // wishbone write
  wb_sel <= 4'b1111;
  wb_stb <= 1;
  wb_cyc <= 1;
  wb_we <= 1'b1;
  wb_addr <= 32'h00_00_00_01;
  wb_data_w = 32'hcafebabe;
  @(posedge clk);
  while (!wb_ack) begin 
    @(posedge clk);
  end


  //second write
  wb_stb <= 1;
  wb_cyc <= 1;
  wb_we <= 1'b1;
  wb_addr <= 32'h2;
  wb_data_w = 32'hbebecaca;
  @(posedge clk);
  while (!wb_ack) begin 
    @(posedge clk);
  end

  wb_stb <= 0;
  wb_cyc <= 0;
  repeat (1) @(posedge clk);
  //read

  wb_stb <= 1;
  wb_cyc <= 1;
  wb_we <= 1'b0;
  wb_addr <= 32'h1;
  @(posedge clk);
  while (!wb_ack) begin 
    @(posedge clk);
  end

  wb_cyc <= 0;
  wb_stb <= 0;
  $display("Value %x",wb_data_r);
  if(wb_data_r != 32'hcafebabe) begin
    $error("data r does not match ");
  end
  $finish();
end
endmodule
