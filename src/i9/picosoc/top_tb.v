`timescale 1ns/1ps

module top_tb;
  reg clk;
  wire [7:0] led;
  reg uart_tx;
  wire uart_rx;

  attosoc dut(
    .clk(clk),
    .led(led),
    .uart_rx(uart_tx),
    .uart_tx(uart_rx)
    );

  initial begin 
    $display("Lets rock and roll");

    $display("done");
    @(posedge uart_rx);
    $display("YO");
    @(posedge uart_rx);
    $display("Lets rock and roll 2");
    $finish();
  end

  initial clk = 0;
  always #20 clk = ~clk;

endmodule
