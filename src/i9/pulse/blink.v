module blink (
    input      clk_i,
    output reg led_o,
    output reg [4:0] gpio
);
//localparam MAX = 12500000;
localparam FREQ = 25_000_000;
localparam MAX = FREQ/39_960/2;// 12500000;
localparam WIDTH = $clog2(MAX);

wire rst_s;
wire clk_s;

assign clk_s = clk_i;
//pll_12_16 pll_inst (.clki(clk_i), .clko(clk_s), .rst(rst_s));
rst_gen rst_inst (.clk_i(clk_s), .rst_i(1'b0), .rst_o(rst_s));

reg  [WIDTH-1:0] cpt_s;
wire [WIDTH-1:0] cpt_next_s = cpt_s + 1'b1;


//GPIO 0 unused 
assign gpio[0] = 1'b0;
assign gpio[1] = led_o;
assign gpio[2] = !led_o;
assign gpio[3] = led_o;
assign gpio[4] = !led_o;
wire             end_s = cpt_s == MAX-1;

always @(posedge clk_s) begin
    cpt_s <= (rst_s || end_s) ? {WIDTH{1'b0}} : cpt_next_s;

    if (rst_s)
        led_o <= 1'b0;
    else if (end_s)
        led_o <= ~led_o;
end
endmodule
