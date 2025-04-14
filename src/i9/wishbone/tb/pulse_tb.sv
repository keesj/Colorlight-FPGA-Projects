//Copyright
`timescale 1ns / 1ps
//Copyright
`default_nettype none

`include "structs.vh"

module pulse_tb ();
  //clock generation
  reg rst;
  reg clk;
  initial clk = 0;
  always #10 clk = ~clk;

  wire [3:0] gpio;

  import structs_pkg::*;
  pwm_regs_t pwm_regs_i;
  pwm_regs_t pwm_regs_o;

  reg pwm_regs_i_valid;
  reg pwm_regs_i_ready;


  pulse dut (
      .clk(clk),
      .rst(rst),
      .gpio(gpio),
      .regs_i(pwm_regs_i),
      .regs_o(pwm_regs_o),
      .regs_i_valid(pwm_regs_i_valid),
      .regs_i_ready(pwm_regs_i_ready)
  );

  initial begin
    rst = 0;
    @(posedge clk);
    rst = 1;
    @(posedge clk);
    rst = 0;
    @(posedge clk);
    $display("Pulse_tb");
    $dumpfile("waves.vcd");
    $dumpvars(0, pulse_tb);
    repeat (100) @(posedge clk);
    $finish();
  end
endmodule
