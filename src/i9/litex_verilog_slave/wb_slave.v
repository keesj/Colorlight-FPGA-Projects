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

  output reg wb_ack_o,
  output reg [31:0] wb_data_o,

  output reg led // Debug
);

reg [31:0] regs [3:0];

wire [1:0] reg_addr = wb_addr_i[1:0];


always @(posedge clk_i) begin
  if (rst_i) begin
        led <= 0;
  end else begin
    wb_ack_o <= 1'b0;
    if (wb_stb_i && wb_cyc_i) begin
      wb_ack_o <= 1'b1; // ack transaction
      if (wb_we_i) begin
        led <= wb_data_i[0];
        if (wb_sel_i[0]) regs[reg_addr][7:0] = wb_data_i[7:0];
        if (wb_sel_i[1]) regs[reg_addr][15:8] = wb_data_i[15:8];
        if (wb_sel_i[2]) regs[reg_addr][23:16] = wb_data_i[23:16];
        if (wb_sel_i[3]) regs[reg_addr][31:24] = wb_data_i[31:24];
        $display("Wishbone write on address %08x",addr);
      end
      wb_data_o <= regs[reg_addr];
    end
  end
end

endmodule
