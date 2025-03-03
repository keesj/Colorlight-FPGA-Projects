#!/usr/bin/env python3
import serial

# Configure the serial port settings
ser = serial.Serial(
    port='/dev/ttyACM0',
    baudrate=115200,
    bytesize=serial.EIGHTBITS,
    parity=serial.PARITY_NONE,
    stopbits=serial.STOPBITS_ONE,
    timeout=1
)

# Write data to the serial port
ser.write(b'\x00r00000000\n')

# Read a line and print it
for i in range(2):
    line = ser.readline().decode('latin1').rstrip()
    print(f'{i} Received: {line}')

# Close the serial port
ser.close()

