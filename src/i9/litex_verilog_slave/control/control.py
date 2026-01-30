#!/usr/bin/env python3

import time
import random

from litex.tools.remote.comm_uart import CommUART

sys_freg=25e6
blink_freq = 10 # hz
blink_counter = sys_freg // blink_freq

wb = CommUART("/dev/ttyACM0")
wb.open()
wb.write(0x2000_0000,int(blink_counter))
print(f"Read: {hex(wb.read(0x2000_0000))}")
wb.close()
