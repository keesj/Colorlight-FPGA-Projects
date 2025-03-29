#!/usr/bin/env python3
import serial
import time
import itertools

# Configure the serial port settings
ser = serial.Serial(
    port='/dev/ttyACM0',
    baudrate=115200,
    bytesize=serial.EIGHTBITS,
    parity=serial.PARITY_NONE,
    stopbits=serial.STOPBITS_ONE,
    timeout=0.5
)

def write(address,data):
    global ser
    # Write data to the serial port
    ser.write(f'\x00w{address:08x}{data:08x}\n'.encode('latin1'))

def read(address):
    global ser
    # Write data to the serial port
    ser.write(f'r{address:08x}\n'.encode('latin1'))
    line = ser.readline().decode('latin1').rstrip()
    return int(f"0{line}",0)

# Read a line and print it
#for i in range(40_000,42_000):
#    freq = 25_000_000 // i  //2
#    write(0,freq)
#    print(f"Freq set to {freq}")
#    print(read(0))
#    time.sleep(.2)

while(1):
    for i in itertools.chain(range(320,305,-1),range(305,320)):
        write(0,i)
        f =  i *2 * 25000
        print(f"Freq set to {f}")
        #print(read(0))
        time.sleep(.2)
# Close the serial port
ser.close()

