#!/usr/bin/env python3
import serial
import time
import itertools

class Pwm:

    def __init__(self,port):
        # Configure the serial port settings
        self.ser = serial.Serial(
            port=port,
            baudrate=115200,
            bytesize=serial.EIGHTBITS,
            parity=serial.PARITY_NONE,
            stopbits=serial.STOPBITS_ONE,
            timeout=0.5
        )

    def write(self,address,data):
        # Write data to the serial port
        self.ser.write(f'\x00w{address:08x}{data:08x}\n'.encode('latin1'))

    def read(self,address):
        # Write data to the serial port
        self.ser.write(f'r{address:08x}\n'.encode('latin1'))
        line = self.ser.readline().decode('latin1').rstrip()
        return int(f"0{line}",0)

    def cnt(self,data):
        self.write(0x01,data);

    def duty(self,data):
        self.write(0x02,data);

    def phase(self,data):
        self.write(0x03,data);

    def commit(self):
        self.write(0x00,0xffffffff);

# Read a line and print it
#for i in range(40_000,42_000):
#    freq = 25_000_000 // i  //2
#    write(0,freq)
#    print(f"Freq set to {freq}")
#    print(read(0))
#    time.sleep(.2)
p = Pwm("/dev/ttyACM0")

low=305
high=320
while(1):
    for i in itertools.chain(range(high,low,-1),range(low,high)):
        p.cnt(i)
        p.duty(i-2)
        p.phase(0)
        p.commit()
        f =  i *2 * 25000000
        print(f"Freq set to {f} cnt={i:02x}")
        for j in range(4):
          print(f"{j:08x} {p.read(j):08x}")
        time.sleep(.2)
# Close the serial port
ser.close()

