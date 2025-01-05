module pulse (
    input      clk_i,
    output reg led_o,
    output reg [4:0] gpio
);
localparam FREQ = 25_000_000;
//localparam MAX = FREQ/39_960/2;// 12500000;
localparam LOW = FREQ/39_960/2;// 12500000;
//localparam LOW = FREQ/36_000/2;// 12500000;
localparam WIDTH = $clog2(LOW);
//localparam PHASE = 60*MAX/360;

wire rst_s;
wire clk_s;

reg out1;

reg [31:0] cnt;
reg [31:0] freq;
reg out2;
reg [WIDTH-1:0] phase;

assign clk_s = clk_i;
//pll_12_16 pll_inst (.clki(clk_i), .clko(clk_s), .rst(rst_s));
rst_gen rst_inst (.clk_i(clk_s), .rst_i(1'b0), .rst_o(rst_s));

reg  [WIDTH-1:0] cpt_s;
reg  [WIDTH-1:0] cpt_max;
wire [WIDTH-1:0] cpt_next_s = cpt_s + 1'b1;


//GPIO 0 unused 
assign gpio[0] = 1'b0;
assign gpio[1] = out1;
assign gpio[2] = !out1;
assign gpio[3] = !out2;
assign gpio[4] = out2;
wire             end_s = cpt_s == cpt_max-1;
wire             out2_end_s = cpt_s == phase;

always @(posedge clk_s) begin
    cpt_s <= (rst_s || end_s) ? {WIDTH{1'b0}} : cpt_next_s;
    cnt <= cnt +1;

    if (rst_s) begin
        out1 <= 1'b0;
        out2 <= 1'b0;
        led_o<= 1'b0;
        cpt_max <= LOW;
        phase <= 0;
        cnt <=0;
      end else begin 
        if (cnt > FREQ) begin
            //out2 <= ~out2;
            //phase <= phase + 1;
            led_o <= ~led_o;
            cnt <= 0;
        end
        if (end_s) begin 
          out1 <= ~out1;
          //phase <= phase + 1;
          if (phase  >= cpt_max -1 ) begin
            phase <= 0;
          end
        end
        if (out2_end_s) out2 <= ~out2;
      end
end
endmodule
