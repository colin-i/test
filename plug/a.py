
import os
import subprocess

def get_temp():
	with open(os.getenv('HOME')+'/pass', 'r') as file:
		p = file.read()
		subprocess.run(['sshpass','-p',p,'sftp','bc@10.42.0.1:/home/bc/n/temp/a','/tmp/a'])
		with open('/tmp/a', 'r') as f:
			return int(read.file(f))

with open(os.getenv('HOME')+'/tempmax', 'r') as file:
	max = int(file.read())
	print(max.__str__())
with open(os.getenv('HOME')+'/tempmin', 'r') as file:
	min = int(file.read())
	print(min.__str__())

import sys

if len(sys.argv)==2:
	on=bool(int(sys.argv[1]))
else:
	on=False
print(on.__str__())

#https://github.com/mjg59/python-broadlink
import broadlink

devices = broadlink.discover()
device=devices[0]
device.auth()

import time

while True:
	t=get_temp()
	print(t.__str__())
	if on==False:
		if t>=max:
			device.set_power(True)
			on=True
	else:
		if t<min:
			device.set_power(False)
			on=False
	time.sleep(20)
