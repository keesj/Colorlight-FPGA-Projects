module wb_slave 
(
  input wire clk_i,
  input wire rst_i,

  //wishbone
  input wire wb_cyc_i,
  input wire wb_stb_i,
  input wire wb_we_i,
  input wire [31:0]  wb_addr_i,
  input wire [31:0]  wb_data_i,
  input wire [4-1:0] wb_sel_i,

  output wire wb_ack_o,
  output reg [31:0] wb_data_o
);

reg [31:0] regs [4];

wire [1:0] reg_addr = wb_addr_i[1:0];

//always ack and set 
assign wb_ack_o = wb_stb_i && wb_cyc_i;
assign wb_data_o  = regs[reg_addr];

always @(posedge clk_i) begin
  if (rst_i) begin
    regs[0] = 32'h11223344;
    regs[1] = 32'h55667788;
    regs[2] = 32'h99aabbcc;
    regs[3] = 32'hddeeff00;
    //wb_data_o = 0;
  end else begin
    if (wb_stb_i && wb_cyc_i) begin
      if (wb_we_i) begin
        if (wb_sel_i[0]) regs[reg_addr][7:0] = wb_data_i[7:0];
        if (wb_sel_i[1]) regs[reg_addr][15:8] = wb_data_i[15:8];
        if (wb_sel_i[2]) regs[reg_addr][23:16] = wb_data_i[23:16];
        if (wb_sel_i[3]) regs[reg_addr][31:24] = wb_data_i[31:24];
        $display("Wishbone write on address %08x value %08x",reg_addr, wb_data_i);
      end else begin
        $display("Wishbone read on address %08x value %08x",reg_addr, regs[reg_addr]);
      end
    end
  end
end

endmodule
