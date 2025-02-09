#!/data/data/com.termux/files/usr/bin/python

# python /data/data/com.termux/files/usr/lib/python3.12/pdb.py t.py

print('py')
#sys.stdout.flush()

# pip install broadlink / apt install python3-broadlink
import broadlink

devices = broadlink.discover(discover_ip_address='192.168.1.255')
device=devices[0]
device.auth()
#Authentication failed ? Unlock the device from the mobile app

on=device.check_power()

import subprocess
import time
import os
import sys
os.set_blocking(sys.stdin.fileno(), False)

while True:
	try: #Enter is enough
		sys.stdin.read(1)[0]
		break
	except:
		pass
	a=subprocess.getoutput('termux-battery-status | jq .percentage')
	print(a)
	a=int(a)
	if on:
		if a>55:
			device.set_power(False)
			on=False
	else:
		if a<45:
			device.set_power(True)
			on=True
	#sys.stdout.flush()
	time.sleep(100)
