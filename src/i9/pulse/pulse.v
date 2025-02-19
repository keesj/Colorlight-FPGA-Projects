module pulse (
    input      clk_i,
    output reg led_o,
    output reg [4:0] gpio
);
localparam FREQ = 25_000_000;
localparam MAX = FREQ/40_200/2;// 
localparam LOW = FREQ/39_960/2;// 12500000;
//localparam LOW = FREQ/36_000/2;// 12500000;
localparam WIDTH = $clog2(LOW);
//localparam PHASE = 60*MAX/360;

wire rst_s;
wire clk_s;

reg out1;

reg [WIDTH-1:0] cnt;
reg [WIDTH-1:0] freq;
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
assign gpio[3] = out2;
assign gpio[4] = !out2;
wire             end_s = cpt_s >= cpt_max-1;
wire             out2_end_s = cpt_s == phase;

always @(posedge clk_s) begin
    cpt_s <= (rst_s || end_s) ? {WIDTH{1'b0}} : cpt_next_s;
    cnt <= cnt +1;

    if (rst_s) begin
        out1 <= 1'b0;
        out2 <= 1'b0;
        led_o<= 1'b0;
        cpt_max <= LOW[WIDTH-1:0];
        phase <= 0;
        cnt <=0;
      end else begin 
        if (cnt > FREQ[WIDTH-1:0]) begin
            cpt_max <= cpt_max -1;
            if (cpt_max < MAX[WIDTH-1:0] ) begin
              cpt_max <= LOW[WIDTH-1:0];
            end
            //out2 <= ~out2;
            phase <= phase - 1;
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
