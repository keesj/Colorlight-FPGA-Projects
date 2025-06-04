default:synth
BIT_FILE=build/colorlight_i5/gateware/colorlight_i5.bit

prog:
	./target.py --load

$(BIT_FILE):synth
flash:$(BIT_FILE)
	ecpdap flash write $<

synth:
	./target.py --build
