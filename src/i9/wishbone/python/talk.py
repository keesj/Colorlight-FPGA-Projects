#!/usr/bin/env python3
import serial

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
    ser.write(f'w{address:08x}{data:08x}\n'.encode('latin1'))

def read(address):
    global ser
    # Write data to the serial port
    ser.write(f'r{address:08x}\n'.encode('latin1'))
    line = ser.readline().decode('latin1').rstrip()
    return line

# Read a line and print it
for i in range(200):
    write(1,i * 2);
    print(read(1))

# Close the serial port
ser.close()

