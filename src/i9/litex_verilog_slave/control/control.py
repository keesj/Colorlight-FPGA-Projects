#!/usr/bin/env python3

import time
import random

from litex import RemoteClient

wb = RemoteClient()
wb.open()
wb.write(0x2000_0000,0xffffffff)
wb.write(0x2000_0004,0xeeeeeeee)
print(hex(wb.read(0x2000_0004)))
print(hex(wb.read(0x2000_0000)))
wb.close()
