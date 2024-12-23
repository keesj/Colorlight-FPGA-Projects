VERILOG = top.v attosoc.v picorv32.v simpleuart.v pll.v
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
$(BUILDDIR)/toplevel.json: $(VERILOG)
	mkdir -p $(BUILDDIR)
	yosys -p "synth_ecp5 -abc9 -json $@" $^

$(BUILDDIR)/%.config: $(PIN_DEF) $(BUILDDIR)/toplevel.json
	 nextpnr-ecp5 --${DEVICE} --package ${PACKAGE}  --textcfg  $@ --json $(filter-out $<,$^) --lpf $<

$(BUILDDIR)/toplevel.bit: $(BUILDDIR)/toplevel.config
	ecppack --compress $^ $@

clean:
	rm -rf ${BUILDDIR}

.SECONDARY:
.PHONY: compile clean prog
