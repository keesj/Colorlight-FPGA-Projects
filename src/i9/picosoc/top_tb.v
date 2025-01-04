`timescale 1ns/1ps

module top_tb;
  reg clk;
  wire [7:0] led;
  wire user_led;
  reg uart_tx;
  wire uart_rx;

  attosoc dut(
    .clk(clk),
    .led(led),
    .user_led(user_led),
    .uart_rx(uart_tx),
    .uart_tx(uart_rx)
    );

  initial begin 
    $dumpfile("waves.vcd");
    $dumpvars(0, top_tb);
    $display("Lets rock and roll");

    $display("done");
    @(posedge uart_rx);
    $display("YO");
    repeat (25) @(posedge uart_rx);
    $display("Lets rock and roll 2");
    repeat (4) @(posedge user_led);
    $finish();
  end

  initial clk = 0;
  always #20 clk = ~clk;

endmodule
