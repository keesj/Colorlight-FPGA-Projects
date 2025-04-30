module led (
  input clk_i,
  input rst_i,
  output wire out_o
);

localparam FREQ = 25_000_000;
localparam WIDTH = $clog2(FREQ);

reg [WIDTH-1:0] cnt;

assign out_o = cnt[WIDTH-1] & 1'b1;


 always @(posedge clk_i) begin
  if (rst_i) begin
    cnt <= 0;
  end else begin 
    cnt <= cnt +1;
  end
 end
endmodule
