IP= $(shell find ip -name "*.sv")
SRC= $(shell find src -name "*.sv")

default: uart-master_tb

.PHONY: uart-master_tb
uart-master_tb: tb/uart_master_tb.sv $(SRC) $(IP)
	echo $(SRC)
	verilator --top-module uart_master_tb --timing --lint-only $^
	iverilog -o $@ -g2012 $^
	./$@

#doit-uart-test:simpleuart_tb.v simpleuart.v
#	verilator --timing --lint-only $^
#	iverilog -o $@ -g2012 $^
##	./$@
#
#doit-slave-interconnect:wb_slave_interconnect_tb.sv wb_slave.sv interconnect.sv
#	iverilog -o $@ -g2012 $^
##	./$@
#
#doit-slave:wb_slave_tb.sv wb_slave.sv interconnect.sv
#	iverilog -o $@ -g2012 $^
#	./$@

clean:
	rm -rf *_tb 

deep-clean:clean
	rm -rf *.vcd
