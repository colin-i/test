#!/data/data/com.termux/files/usr/bin/python

# python /data/data/com.termux/files/usr/lib/python3.12/pdb.py t.py

print('py')
#sys.stdout.flush()

# pip install broadlink / apt install python3-broadlink
import broadlink
import subprocess
import threading
exit=threading.Event()

def set_off():
	global on
	try:
		device.set_power(False)
		on=False
	except:
		err()
		pass
def set_on():
	global on
	try:
		device.set_power(True)
		on=True
	except:
		err()
		pass
def err():
	print("error")
def t_f():
	global device,on
	devices = broadlink.discover(discover_ip_address='192.168.1.255')
	device=devices[0]
	device.auth()
	#Authentication failed ? Unlock the device from the mobile app
	on=device.check_power()
	while not exit.is_set():
		a=subprocess.getoutput('termux-battery-status | jq .percentage')
		print(a)
		a=int(a)
		if on:
			if a>55:
				set_off()
		else:
			if a<45:
				set_on()
		exit.wait(100)
	print('done')
	if on:
		set_off()

t = threading.Thread(target=t_f)
t.start()

import sys
sys.stdin.read(1)
#os.set_blocking(sys.stdin.fileno(), False)
exit.set()
