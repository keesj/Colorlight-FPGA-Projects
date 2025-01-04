all: firmware.hex

PREFIX=/opt/riscv/bin/riscv64-unknown-elf-
# apt-get install gcc-riscv64-unknown-elf
PREFIX=/usr/bin/riscv64-unknown-elf-
clean:
	rm -f firmware.hex firmware.elf firmware.bin

firmware.elf: sections.lds start.s firmware.c
	${PREFIX}gcc -mabi=ilp32 -march=rv32i -Wl,-Bstatic,-T,sections.lds,--strip-debug -ffreestanding -nostdlib -o firmware.elf start.s firmware.c

firmware.bin: firmware.elf
	${PREFIX}objcopy -O binary firmware.elf firmware.bin

firmware.hex: firmware.bin
	python3 makehex.py $^ 8192 > $@

