IP= $(shell find ip -name "*.sv")
SRC= $(shell find src -name "*.sv")

# synth/prograamming options
OUT_DIR=out/
ECPDAP_OPTS=-f 500

default: uart-master_tb

.PHONY: uart-master_tb
uart-master_tb: tb/wb_uart_master_tb.sv src/wb_pulse.sv $(SRC) $(IP)
	verilator --top-module wb_uart_master_tb --timing --lint-only $^
	iverilog -o $@ -g2012 $^
	./$@

$(OUT_DIR)design.json: synth/top.sv src/wb_pulse.sv $(SRC) $(IP)
	verilator --top-module top --timing --lint-only $^
	mkdir -p $(OUT_DIR)
	yosys -p "synth_ecp5 -json $@" $^

$(OUT_DIR)design.config: $(OUT_DIR)design.json
	nextpnr-ecp5 --45k --package CABGA381 --speed 6 --json $< --textcfg $@ --lpf synth/top.lpf --freq 65

$(OUT_DIR)design.bit:$(OUT_DIR)design.config
	ecppack --svf $(OUT_DIR)/design.svf $< $@

prog: $(OUT_DIR)design.bit
	ecpdap $(ECPDAP_OPTS) program $(OUT_DIR)design.bit

flash: $(OUT_DIR)design.bit
  #  ecpdap flash unprotect
	ecpdap ${ECPDAP_OPTS} flash write $^

clean:
	rm -rf *_tb 

deep-clean:clean
	rm -rf *.vcd out
