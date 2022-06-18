
import os
import subprocess

def get_temp_inter():
	with open(os.getenv('HOME')+'/pass', 'r') as file:
		p = file.read()
		subprocess.run(['sshpass','-p',p,'sftp','bc@10.42.0.1:/home/bc/n/temp/a','/tmp/a'])
		with open('/tmp/a', 'r') as f:
			return int(f.read())

import json
def get_temp_local(n1,n2,n3):
	from subprocess import check_output
	out = check_output(["sensors", "-j"])
	j=json.loads(out)
	if n3:
		return j[n1][n2]["temp"+n3+"_input"]
	return j[n1]["temp"+n2+"_input"]

with open(os.getenv('HOME')+'/tempmax', 'r') as file:
	max = int(file.read())
	print(max.__str__())
with open(os.getenv('HOME')+'/tempmin', 'r') as file:
	min = int(file.read())
	print(min.__str__())

import sys

on=bool(int(sys.argv[1]))
print(on.__str__())

print(sys.argv[2])
if sys.argv[2]=="0":
	local=True
	with open(os.getenv('HOME')+'/tempdata', 'r') as file:
		data=file.read().split(',')
		name1=data[0]
		print(name1)
		name2=data[1]
		print(name2)
		if len(data)==3:
			name3=data[2]
			print(name3)
		else:
			name3=None
else:
	local=False

#https://github.com/mjg59/python-broadlink
import broadlink

devices = broadlink.discover(discover_ip_address='192.168.1.255') #the arugment is if manual wlan connection if have both wwan and wlan
device=devices[0]
device.auth()

import time

while True:
	if local:
		t=get_temp_local(name1,name2,name3)
	else:
		t=get_temp_inter()
	print(t.__str__())
	if on==False:
		if t>=max:
			device.set_power(True)
			on=True
	else:
		if t<min:
			device.set_power(False)
			on=False
	time.sleep(30)
