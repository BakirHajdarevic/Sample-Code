######################################################################
# Programmer: Bakir Hajdarevic
# Program: bluetoothSearch.py
# Date: 6/1/2016
# Description: This program was written to connect a raspberry pi-3 to
# a HC-06 sensor as part of an embedded system. Commands were sent to 
# the bluetooth device that corresponded with setting the speed and step
# size of a system's stepper motor. These parameters essentially 
# dictated how fast a slider moved.
######################################################################

# Import necessary libraries
from bluetooth import *
from time import sleep

# Initialize Variables
target_name = "HC-06"
target_address = None
i = 0
string = None

# Search for an HC-06 Bluetooth Module
# Any nearby HC-06 device will be picked up
# as we are not specifying the UID
nearby_devices = discover_devices(duration = 8, flush_cache=True)

for address in nearby_devices:
    if target_name == lookup_name( address, timeout=10 ):
        target_address = address
        break
# Inform user if no Bluetooth device was found
if(target_address == None):
    print("Could not find available Bluetooth device.")
# Else pass command(s) to the Arduino
else:
    # Set up Bluetooth connection
    port = 1
    sock = BluetoothSocket( RFCOMM )
    sock.connect((target_address, port))

    # Open the text file and read
    text_file = open("/home/pi/temp/bluetooth.txt","r")
    lines = text_file.read()
    
    # Send complex command, i.e. set the speed or step size of
    # the slider's stepper motor
    if(lines[i] == "r"):
        # This skips the newline characters read in from the text file
        while(i < len(lines)):
            if(lines[i] != "\n"):
                # Send only neccessary characters
                sock.send(str(lines[i]))
            i+=1
    else:
        # Send simple command, i.e. go left so many steps
        sock.send(str(lines[i]))

    # Close all sockets              
    text_file.close()
    sock.close()

    # Inform user that Bluetooth connection and the message sent was success
    print("Passed message")
# Program End
