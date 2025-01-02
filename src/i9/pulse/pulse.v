module pulse (
    input      clk_i,
    output reg led_o,
    output reg [4:0] gpio
);
//localparam MAX = 12500000;
localparam FREQ = 25_000_000;
localparam MAX = FREQ/39_960/2;// 12500000;
localparam WIDTH = $clog2(MAX);
//localparam PHASE = 60*MAX/360;

wire rst_s;
wire clk_s;

reg out2;
reg [WIDTH-1:0] phase;

assign clk_s = clk_i;
//pll_12_16 pll_inst (.clki(clk_i), .clko(clk_s), .rst(rst_s));
rst_gen rst_inst (.clk_i(clk_s), .rst_i(1'b0), .rst_o(rst_s));

reg  [WIDTH-1:0] cpt_s;
wire [WIDTH-1:0] cpt_next_s = cpt_s + 1'b1;


//GPIO 0 unused 
assign gpio[0] = 1'b0;
assign gpio[3] = led_o;
assign gpio[4] = !led_o;
assign gpio[1] = out2;
assign gpio[2] = !out2;
wire             end_s = cpt_s == MAX[WIDTH-1:0]-1;
wire             out2_end_s = cpt_s == phase;

always @(posedge clk_s) begin
    cpt_s <= (rst_s || end_s) ? {WIDTH{1'b0}} : cpt_next_s;

    if (rst_s) begin
        led_o <= 1'b0;
        out2 <= 1'b0;
        phase <= 0;
      end else begin 
        if (end_s) begin 
          led_o <= ~led_o;
          phase <= phase + 1;
          if (phase  == MAX[WIDTH-1:0] -1 ) begin
            phase <= 0;
          end
        end
        if (out2_end_s) out2 <= ~out2;
      end
end
endmodule

