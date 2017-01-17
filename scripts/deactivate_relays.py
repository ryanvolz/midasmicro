#!/usr/bin/python

import tosr0x
import sys
import time

th = tosr0x.handler(devicePaths=['/dev/ttyUSB0'],relayCount=4)

if len(th) == 0:
	print("Unable to open relay")
	sys.exit(1)

print("de-activating relays...")

relay = th[0]

relay.set_relay_position(1,0)  # drives
time.sleep(1)
relay.set_relay_position(2,0)  # GPS
time.sleep(1)
relay.set_relay_position(3,0)  # amps
time.sleep(1)
relay.set_relay_position(4,0)  # USRP
time.sleep(1)
