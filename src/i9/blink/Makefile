TARGET=blink
TOP=blink

ECPDAP_OPTS=-f 500
OBJS+=blink.v rst_gen.v

TRELLIS=/usr/local/share/trellis

all: ${TARGET}.bit

$(TARGET).json: $(OBJS)
	yosys -p "synth_ecp5 -json $@" $(OBJS)

$(TARGET)_out.config: $(TARGET).json
	nextpnr-ecp5 --45k --package CABGA381 --speed 6 --json $< --textcfg $@ --lpf $(TARGET).lpf --freq 65

$(TARGET).bit: $(TARGET)_out.config
	ecppack --svf ${TARGET}.svf $< $@

${TARGET}.svf : ${TARGET}.bit

prog: ${TARGET}.bit
	ecpdap $(ECPDAP_OPTS) program ${TARGET}.bit

flash: $(TARGET).bit
  #  ecpdap flash unprotect
	ecpdap $(ECPDAP_OPTS) flash write $(TARGET.bit)

clean:
	rm -f *.svf *.bit *.config *.ys *.json

.PHONY: prog clean
