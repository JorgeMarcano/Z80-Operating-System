import serial
import signal
import time

port = 'COM4'

ser = serial.Serial(port,115200,timeout=None)

def handler(signum, frame):
    exit()

signal.signal(signal.SIGINT, handler)

# Serial write section
with open('rasmoutput.bin', 'rb') as file:
    ser.flush()
    time.sleep(5)
        
    phrase = file.read(2)
    index = 0
    while phrase:
        line = "%0.4x" % index
        line += ":"
        #convert to string and send
        for i in range(32):
            line += " "
            if i == 16:
                    line += " "
            line += phrase.hex()
            phrase = file.read(2)
        
        print(line)
        ser.write(line.encode())
        print(ser.readline().decode()[:-2])
        
        index += 64

print("Done Writing")

# Serial read section
line = "%0.4x" % index
ser.write(("p 0 " + line).encode('UTF-8'))

msg = ""
while msg[:3] != 'END':
    msg = ser.readline()[:-2].decode('UTF-8')
    print(msg)

print("Done")
