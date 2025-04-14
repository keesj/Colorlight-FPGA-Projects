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

  reg regs_i_valid;
  wire regs_i_ready;


  pulse dut (
      .clk(clk),
      .rst(rst),
      .gpio(gpio),
      .regs_i(pwm_regs_i),
      .regs_o(pwm_regs_o),
      .regs_i_valid(regs_i_valid),
      .regs_i_ready(regs_i_ready)
  );

  initial begin
    $display("Pulse_tb");
    $dumpfile("waves.vcd");
    $dumpvars(0, pulse_tb);
    regs_i_valid = 0;
    rst = 0;
    @(posedge clk);
    rst = 1;
    @(posedge clk);
    rst = 0;
    repeat (4) @(posedge clk);


    pwm_regs_i.cnt = 15;
    pwm_regs_i.duty = 12;
    pwm_regs_i.phase = 0;
    regs_i_valid = 1;

    do begin
      @(posedge clk);  // wait for output buffer to be ready
      $display("WAIT");
      regs_i_valid = 0;
    end while (~regs_i_ready);

    repeat (100) @(posedge clk);
    $display("Write done");
    pwm_regs_i.cnt = 3;
    pwm_regs_i.duty = 1;
    pwm_regs_i.phase = 0;
    regs_i_valid = 1;

    do begin
      @(posedge clk);  // wait for output buffer to be ready
      $display("WAIT");
      regs_i_valid = 0;
    end while (~regs_i_ready);


    repeat (1000) @(posedge clk);
    $finish();
  end
endmodule
