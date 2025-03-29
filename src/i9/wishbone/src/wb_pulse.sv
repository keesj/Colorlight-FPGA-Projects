module pulse (
    input            clk,
    input            rst,
    output reg [3:0] gpio,

    input wire [31:0] pulse_div_di,
    output wire [31:0] pulse_div_do,
    input wire pulse_div_valid,
    output reg pulse_div_ready
);

  // The ultrasonic sensor can be driven with 2 MOFSETs that can drive the
  // speaker in twoo directions. This means that during a cycle the 
  //
  //          <--du-->
  //
  // First wave
  // 1:       |------|
  //          |      |
  // 0:  -----|      |------|      |-------
  //                        |      |
  // -1:                    |------|
  //  
  //  Second wave, po
  // 1:  <- ph ->        |------|
  //                     |      |
  // 0:             -----|      |------|      |-------
  //                                   |      |
  // -1:                               |------|
  // du: PWM duty
  // di: PWM divider
  // ph: Phase of the second wave compared to the first
  // po: pollarity 
  //
  // CPU FREQ
  // 1 Hz is the lowest frequency we can generate
  // 50Khz
  localparam CLK_FREQ = 25_000_000;
  localparam MAX_DIV = CLK_FREQ / 1 / 2;
  localparam MAX = CLK_FREQ / 50_000 / 2;

  localparam WIDTH = 32;  //$clog2(MAX_DIV);
  //localparam PHASE = 60*MAX/360;

  reg [WIDTH-1:0] pwm_counter;
  reg [WIDTH-1:0] pwm_div;
  reg [WIDTH-1:0] pwm_next_div;
  reg [WIDTH-1:0] pwm_duty;
  reg [WIDTH-1:0] pwm_dp_counter;
  reg [WIDTH-1:0] pwm_dn_counter;

  assign pulse_div_do = pwm_div;

  // Second wave
  reg [WIDTH-1:0] pwm_phase;
  reg pwm_polatiry;
  reg [WIDTH-1:0] pwm_dp_counter2;
  reg [WIDTH-1:0] pwm_dn_counter2;

  // 
  assign gpio[0] = pwm_dp_counter > 0;
  assign gpio[1] = pwm_dn_counter > 0;
  assign gpio[2] = pwm_dp_counter > 0;
  assign gpio[3] = pwm_dn_counter > 0;

  reg flip_flop;

  wire [WIDTH-1:0] pwm_dp_counter_next = (pwm_dp_counter > 0) ? pwm_dp_counter - 1 : 0;
  wire [WIDTH-1:0] pwm_dn_counter_next = (pwm_dn_counter > 0) ? pwm_dn_counter - 1 : 0;

  always @(posedge clk) begin
    pwm_counter <= pwm_counter + 1;

    // registers
    pulse_div_ready <= 1;

    pwm_dp_counter <= pwm_dp_counter_next;
    pwm_dn_counter <= pwm_dn_counter_next;

    if (rst) begin
      pwm_counter <= 0;
      pwm_div <= 10;
      pwm_next_div <= 10;
      pwm_duty <= 5;
      flip_flop <= 0;
    end else begin

      if (pulse_div_valid) begin
        //$display("PWM DIV %d", pulse_div_di);
        pwm_next_div <= pulse_div_di;
        pulse_div_ready <= 0;
      end

      if (pwm_counter >= pwm_div) begin
        pwm_counter <= 0;
        pwm_div <= pwm_next_div;
        pwm_duty <= pwm_next_div;  // TODO REMOVE
        if (flip_flop) begin
          //          $display("FLIP");
          pwm_dp_counter <= pwm_duty;
        end else begin
          //         $display("FLOP");
          pwm_dn_counter <= pwm_duty;
        end
        flip_flop <= ~flip_flop;
      end
    end
  end
endmodule

module wb_pulse (
    input wire clk,
    input wire rst,

    //wishbone
    input wire wb_cyc_i,
    input wire wb_stb_i,
    input wire wb_we_i,
    input wire [31:0] wb_addr_i,
    input wire [31:0] wb_data_i,
    input wire [4-1:0] wb_sel_i,

    output reg wb_ack_o,
    output reg [31:0] wb_data_o,

    // pulse GPIO
    output wire [3:0] gpio
);


  reg [31:0] pwm_div_in;
  reg pwm_div_valid;
  wire pwm_div_ready;
  wire [31:0] pwm_div_out;

  pulse pwm (
      .clk (clk),
      .rst (rst),
      .gpio(gpio),

      .pulse_div_di(pwm_div_in),
      .pulse_div_do(pwm_div_out),
      .pulse_div_valid(pwm_div_valid),
      .pulse_div_ready(pwm_div_ready)
  );


  wire [1:0] reg_addr = wb_addr_i[1:0];


  always @(posedge clk) begin
    if (pwm_div_ready) begin
      pwm_div_valid <= 1'b0;
    end
    if (rst) begin
      pwm_div_in <= 32'h00000000;
      wb_data_o  <= 32'h00000000;
      wb_ack_o   <= 0;
      //wb_data_o = 0;
    end else begin
      wb_ack_o <= 0;
      if (wb_stb_i && wb_cyc_i && wb_ack_o == 1'h0) begin
        wb_ack_o <= 1;
        if (wb_we_i && wb_sel_i == 4'b1111) begin
          case (reg_addr)
            2'd0: begin
              $display("Pulse Wishbone write DIV %08x value %08x", reg_addr, wb_data_i);
              if (pwm_div_ready) begin
                pwm_div_in <= wb_data_i;
                pwm_div_valid <= 1'b1;
              end else begin
                $display("DIV BUSY");
              end
            end
            2'd1: begin
              $display("Pulse Wishbone write PWM %08x value %08x", reg_addr, wb_data_i);
            end
            2'd2: begin
              $display("Pulse Wishbone write PHASE_SHIFT %08x value %08x", reg_addr, wb_data_i);
            end
            2'd3: begin
              $display("Pulse Wishbone write XXX %08x value %08x", reg_addr, wb_data_i);
            end
          endcase
          //$display("Pulse Wishbone write on address %08x value %08x", reg_addr, wb_data_i);
        end else begin
          case (reg_addr)
            2'd0: begin
              $display("Pulse Wishbone read DIV %08x value %08x", reg_addr, pwm_div_out);
              wb_data_o <= pwm_div_out;
            end
            2'd1: begin
              $display("Pulse Wishbone read PWM %08x value %08x", reg_addr, wb_data_i);
              wb_data_o <= 32'hc0de0192;
            end
            2'd2: begin
              $display("Pulse Wishbone read PHASE_SHIFT %08x value %08x", reg_addr, wb_data_i);
              wb_data_o <= 32'hc0de0196;
            end
            2'd3: begin
              $display("Pulse Wishbone write XXX %08x value %08x", reg_addr, wb_data_i);
              wb_data_o <= 32'hc0de2000;
            end
          endcase
          //$display("Pulse Wishbone read on address %08x", reg_addr);
        end
      end
    end
  end

endmodule
