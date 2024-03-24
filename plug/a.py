#!/usr/bin/python3 -u
#without -u is not flushing at .service

#same as ./a

import os

HOME=os.getenv('HOME') #working in .service only with User=<user>
log=HOME+'/'+os.getenv('fname')

# to not write from SEEK_SET again at .service
with open(log,"w") as f:  ##os.remove() will not print again in this run
	f.truncate()   # os.remove is doing but this? sudo chown <user>:<user> ~/<log> one time

print(HOME)

import subprocess

def get_temp_inter():
	with open(HOME+'/pass', 'r') as file:
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

with open(HOME+'/tempmax', 'r') as file:
	max = int(file.read())
with open(HOME+'/tempmin', 'r') as file:
	min = int(file.read())

#https://github.com/mjg59/python-broadlink
import broadlink  # only with: WorkingDirectory=/home/<user>/

devices = broadlink.discover(discover_ip_address='192.168.1.255') #the arugment is if manual wlan connection if have both wwan and wlan
device=devices[0]
device.auth()
#Authentication failed ? Unlock the device from the mobile app

import sys

on=int(sys.argv[1])
if on==-1:
	on=device.check_power()
else:
	on=bool(on)
print("On="+on.__str__())

print(sys.argv[2])
if sys.argv[2]=="0":
	local=True
	with open(HOME+'/tempdata', 'r') as file:
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

if len(sys.argv)>3:
	print(sys.argv[3])
	dif=int(sys.argv[3])
	dif2=dif
	if len(sys.argv)>4:
		print(sys.argv[4])
		dif2=int(sys.argv[4])
	min+=dif
	max+=dif2

print(min.__str__())
print(max.__str__())

import time

y=30
z=60
x=z

while True:
	if local:
		t=get_temp_local(name1,name2,name3)
	else:
		t=get_temp_inter()
	info=t.__str__()
	if on==False:
		if t>=max:
			if x>=z:
				device.set_power(True)
				on=True
				x=0
				info+=" on"
			else:
				info+=" at least one minute"
	else:
		if t<min:
			if x>=z:
				device.set_power(False)
				on=False
				x=0
				info+=" off"
			else:
				info+=" at least one minute"
	print(info)
	time.sleep(y)
	x+=y
