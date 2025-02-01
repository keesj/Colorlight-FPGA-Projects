doit-uart-test:simpleuart_tb.v simpleuart.v
	iverilog -o $@ -g2012 $^
	./$@

doit-slave-interconnect:wb_slave_interconnect_tb.sv wb_slave.sv interconnect.sv
	iverilog -o $@ -g2012 $^
	./$@

doit-slave:wb_slave_tb.sv wb_slave.sv interconnect.sv
	iverilog -o $@ -g2012 $^
	./$@
