module pulse_tb();
  reg clk;
  initial clk = 1;
  always #20 clk = ~clk;

  reg led;
  reg [4:0]gpio;

  pulse p ( 
  .clk_i(clk),
  .led_o(led),
  .gpio(gpio)
  );

  integer i;

  initial begin
    $display("Working");
    $dumpfile("waves.vcd");
    $dumpvars(0, clk_gen_tb);

    
    for (i =0 ; i <  100000; i++) begin
      @(posedge clk);
    end
    $display("finish");
   $finish();
   end
endmodule
