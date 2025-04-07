typedef struct packed {
  reg [31:0] cnt;
  reg [31:0] duty;
  reg [31:0] phase;
} pwm_regs_t;

module pulse (
    input            clk,
    input            rst,
    output reg [3:0] gpio,

    input wire pwm_regs_t regs_i,
    output wire pwm_regs_t regs_o,
    output wire [31:0] half_pulse_count_do,
    input wire half_pulse_count_valid,
    output reg half_pulse_count_ready
);

  // The ultrasonic sensor can be driven with 2 MOFSETs that can drive the
  // speaker in twoo directions. This means that during a cycle the 
  //
  //          <- hdpc   ->
  //          <--du-->
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
  // du: PWM half duty pulse count
  // di: PWM half pulse count
  // ph: phase of the second wave compared to the first
  // po: pollarity 
  //
  // CPU FREQ
  // 1 Hz is the lowest frequency we can generate
  // 50Khz is typical
  localparam CLK_FREQ = 25_000_000;
  localparam WIDTH = 32;

  reg [WIDTH-1:0] pwm_counter;
  reg [WIDTH-1:0] pwm_half_pulse_count;
  reg [WIDTH-1:0] pwm_duty;
  reg [WIDTH-1:0] pwm_dp_counter;
  reg [WIDTH-1:0] pwm_dn_counter;

  reg [WIDTH-1:0] pwm_next_half_pulse_count;

  assign half_pulse_count_do = pwm_half_pulse_count;


  // Second wave
  reg [WIDTH-1:0] pwm_counter2;
  reg [WIDTH-1:0] pwm_phase;
  reg pwm_polatiry;
  reg [WIDTH-1:0] pwm_dp_counter2;
  reg [WIDTH-1:0] pwm_dn_counter2;


  assign gpio[0] = pwm_dp_counter > 0;
  assign gpio[1] = pwm_dn_counter > 0;
  assign gpio[2] = pwm_dp_counter2 > 0;
  assign gpio[3] = pwm_dn_counter2 > 0;

  reg flip_flop;
  reg flip_flop2;

  wire [WIDTH-1:0] pwm_dp_counter_next = (pwm_dp_counter > 0) ? pwm_dp_counter - 1 : 0;
  wire [WIDTH-1:0] pwm_dn_counter_next = (pwm_dn_counter > 0) ? pwm_dn_counter - 1 : 0;
  wire [WIDTH-1:0] pwm_dp_counter2_next = (pwm_dp_counter2 > 0) ? pwm_dp_counter2 - 1 : 0;
  wire [WIDTH-1:0] pwm_dn_counter2_next = (pwm_dn_counter2 > 0) ? pwm_dn_counter2 - 1 : 0;

  always @(posedge clk) begin
    pwm_counter <= pwm_counter + 1;
    pwm_counter2 <= pwm_counter2 + 1;

    // registers
    half_pulse_count_ready <= 1;

    pwm_dp_counter <= pwm_dp_counter_next;
    pwm_dn_counter <= pwm_dn_counter_next;
    pwm_dp_counter2 <= pwm_dp_counter2_next;
    pwm_dn_counter2 <= pwm_dn_counter2_next;

    if (rst) begin
      pwm_counter <= 0;
      pwm_half_pulse_count <= 116;
      pwm_next_half_pulse_count <= 16;
      pwm_duty <= 16;  // TODO?
      pwm_phase <= 3;  // TODO?
      flip_flop <= 0;
      flip_flop2 <= 0;
      pwm_dp_counter <= 0;
      pwm_dn_counter <= 0;
      pwm_dp_counter2 <= 0;
      pwm_dn_counter2 <= 0;
    end else begin

      if (half_pulse_count_valid) begin
        pwm_next_half_pulse_count <= regs_i.cnt;
        half_pulse_count_ready <= 0;
      end

      if (pwm_counter == pwm_phase) begin
        pwm_counter2 <= 0;
      end

      if (pwm_counter2 >= pwm_half_pulse_count) begin
        pwm_counter2 <= 0;

        if (flip_flop2) begin
          pwm_dp_counter2 <= pwm_duty;
        end else begin
          pwm_dn_counter2 <= pwm_duty;
        end
        flip_flop2 <= ~flip_flop2;
      end

      if (pwm_counter >= pwm_half_pulse_count) begin
        pwm_counter <= 0;
        pwm_half_pulse_count <= pwm_next_half_pulse_count;
        pwm_duty <= pwm_next_half_pulse_count;  // TODO REMOVE the duty is something different

        if (flip_flop) begin
          pwm_dp_counter <= pwm_duty;
        end else begin
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


  reg pwm_half_pulse_count_valid;
  wire pwm_half_pulse_count_ready;
  wire [31:0] pwm_half_pulse_count_out;

  pwm_regs_t pwm_regs;
  pwm_regs_t pwm_regs_o;

  pulse pwm (
      .clk(clk),
      .rst(rst),
      .gpio(gpio),
      .regs_i(pwm_regs),
      .regs_o(pwm_regs_o),

      .half_pulse_count_do(pwm_half_pulse_count_out),
      .half_pulse_count_valid(pwm_half_pulse_count_valid),
      .half_pulse_count_ready(pwm_half_pulse_count_ready)
  );


  wire [2:0] reg_addr = wb_addr_i[2:0];


  always @(posedge clk) begin
    if (pwm_half_pulse_count_ready) begin
      pwm_half_pulse_count_valid <= 1'b0;
    end
    if (rst) begin
      wb_data_o <= 32'h00000000;
      wb_ack_o <= 0;
      //wb_data_o = 0;
    end else begin
      wb_ack_o <= 0;
      if (wb_stb_i && wb_cyc_i && wb_ack_o == 1'h0) begin
        wb_ack_o <= 1;
        if (wb_we_i && wb_sel_i == 4'b1111) begin
          case (reg_addr)
            3'd0: begin
              $display("Commit changes");
              if (pwm_half_pulse_count_ready) begin
                pwm_half_pulse_count_valid <= 1'b1;
              end else begin
                $display("PHPC BUSY");
              end
            end
            3'd1: begin
              $display("Pulse Wishbone write PHPC %08x value %08x", reg_addr, wb_data_i);
              pwm_regs.cnt = wb_data_i;
            end
            3'd2: begin
              $display("Pulse Wishbone write PWM %08x .... value %08x", reg_addr, wb_data_i);
            end
            3'd3: begin
              $display("Pulse Wishbone write PHASE_SHIFT %08x value %08x", reg_addr, wb_data_i);
            end
            3'd4: begin
              $display("Pulse Wishbone write Duty %08x value %08x", reg_addr, wb_data_i);
            end
            default: begin
              $display("Pulse write: Invalid address %x", reg_addr);
            end
          endcase
          //$display("Pulse Wishbone write on address %08x value %08x", reg_addr, wb_data_i);
        end else begin
          case (reg_addr)
            3'd1: begin
              $display("Pulse Wishbone read PHPC %08x value %08x", reg_addr,
                       pwm_half_pulse_count_out);
              wb_data_o <= pwm_half_pulse_count_out;
            end
            3'd2: begin
              $display("Pulse Wishbone read PWM %08x value %08x", reg_addr, wb_data_i);
              wb_data_o <= 32'hc0de0192;
            end
            3'd3: begin
              $display("Pulse Wishbone read PHASE_SHIFT %08x value %08x", reg_addr, wb_data_i);
              wb_data_o <= 32'hc0de0196;
            end
            3'd4: begin
              $display("Pulse Wishbone write XXX %08x value %08x", reg_addr, wb_data_i);
              wb_data_o <= 32'hc0de2000;
            end
            default: begin
              $display("Pulse read: Invalid address %x", reg_addr);
            end
          endcase
          //$display("Pulse Wishbone read on address %08x", reg_addr);
        end
      end
    end
  end

endmodule
