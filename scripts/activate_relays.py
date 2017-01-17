#!/usr/bin/python

import tosr0x
import sys
import time

th = tosr0x.handler(devicePaths=['/dev/ttyUSB0'],relayCount=4)

if len(th) == 0:
	print("Unable to open relay")
	sys.exit(1)

print("activating relays...")

relay = th[0]

relay.set_relay_position(1,1)  # drives
time.sleep(1)
relay.set_relay_position(2,1)  # GPS
time.sleep(1)
relay.set_relay_position(3,1)  # amps
time.sleep(1)
relay.set_relay_position(4,1)  # USRP
time.sleep(1)
