TB_TOP = top_tb
TB_SRC = top_tb.v attosoc.v picorv32.v simpleuart.v
VERILOG_SRC = top.v attosoc.v picorv32.v simpleuart.v pll.v
DEVICE = 45k
PACKAGE=CABGA381
ECPDAP_OPTS=-f 500

PIN_DEF ?= top.lpf

BUILDDIR = bin

compile: $(BUILDDIR)/toplevel.bit

prog: $(BUILDDIR)/toplevel.bit
	ecpdap ${ECPDAP_OPTS} program $^

flash: $(BUILDDIR)/toplevel.bit
	ecpdap ${ECPDAP_OPTS} flash write $^

$(BUILDDIR)/toplevel.json: $(VERILOG_SRC)
	mkdir -p $(BUILDDIR)
	yosys -p "synth_ecp5 -abc9 -json $@" $^

sim:
	verilator  \
		  -Wno-CASEINCOMPLETE \
		  -Wno-CASEOVERLAP \
		  -Wno-WIDTHTRUNC \
		  -Wno-WIDTHEXPAND \
		  -Wno-WIDTHXZEXPAND \
		  -Wno-PINMISSING \
			--trace \
			--trace-fst \
			--binary --top $(TB_TOP) $(TB_SRC)

isim:$(TB_SRC)
	iverilog $(TB_SRC)

$(BUILDDIR)/%.config: $(PIN_DEF) $(BUILDDIR)/toplevel.json
	 nextpnr-ecp5 --${DEVICE} --package ${PACKAGE}  --textcfg  $@ --json $(filter-out $<,$^) --lpf $<

$(BUILDDIR)/toplevel.bit: $(BUILDDIR)/toplevel.config
	ecppack --compress $^ $@

clean:
	rm -rf ${BUILDDIR}

.SECONDARY:
.PHONY: compile clean prog
