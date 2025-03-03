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

ser.write(b'\nw0000000112345678\n')
# Write data to the serial port

# Read a line and print it
for i in range(100):
    ser.write(b'r00000001\n')

    line = ser.readline().decode('latin1').rstrip()
    print(f'{i} Received: {line}')

# Close the serial port
ser.close()

