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

// Example led blinker
reg [31:0] counter;
wire [31:0] counter_max;
assign counter_max = regs[0];


always @(posedge clk_i) begin
  if (rst_i) begin
        led <= 0;
        counter <= 0;
        regs[0] <= 32'h1000000;
  end else begin
    counter <= counter +1;
    if (counter >= counter_max) begin
      led <= ~ led;
      counter <= 0;
    end
    wb_ack_o <= 1'b0;
    if (wb_stb_i && wb_cyc_i) begin
      wb_ack_o <= 1'b1; // ack transaction
      if (wb_we_i) begin
        if (wb_sel_i == 4'b1111) begin
          regs[reg_addr] = wb_data_i;
          $display("Wishbone write on address %08x",addr);
        end
      end
      wb_data_o <= regs[reg_addr];
    end
  end
end

endmodule
