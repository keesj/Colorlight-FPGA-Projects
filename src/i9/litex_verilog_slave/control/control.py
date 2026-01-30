#!/usr/bin/env python3

import time
import random

from litex.tools.remote.comm_uart import CommUART

sys_freg=25e6

wb = CommUART("/dev/ttyACM0")
wb.open()
for i in range(10,40,2):
    blink_freq = i # hz
    blink_counter = sys_freg // blink_freq
    wb.write(0x2000_0000,int(blink_counter))


    ctr = wb.read(0x2000_0000)
    print(f"freq = {25e6 // ctr}")
    time.sleep(2)
wb.close()
