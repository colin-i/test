
#git clone https://github.com/pimylifeup/temperature_sensor
#https://github.com/tomikaa87/gree-remote

import time

import sys
import subprocess
import math

def read_temp_raw():
	f = open(device_file, 'r')
	lines = f.readlines()
	f.close()
	return lines

def read_temp():
	lines = read_temp_raw()
	if lines[0].strip()[-3:] == 'YES':
		equals_pos = lines[1].find('t=')
		if equals_pos != -1:
			temp_string = lines[1][equals_pos+2:]
			temp_c = int(temp_string) / 1000
			#temp_f = temp_c * 9.0 / 5.0 + 32.0
			return temp_c #, temp_f
	return float('nan')

def read_gree_temp():
	t=subprocess.run(["/bin/bash",base+'/tget',base]).returncode
	if t==216: #that will be wi-fi timeout
		return float('nan')
	return t


def gree(a,b):
	s='Pow='+a
	if send:
		#return is 0 at timeout later
		subprocess.run([sys.executable,'gree.py','-c','192.168.1.9','-i','f4911e448ee8','-k','9Mn2Pq5St8VwYz4B','set',s])
		#.returncode
	print(s)
	global on
	on=b

def test(t):
	print(t)
	if math.isnan(t)==False:
		if on==False:
			if t>=max:
				gree('1',True)
				#return True
		else:
			if t<min:
				gree('0',False)
				#return True
	#return False

if len(sys.argv)==7:
	on=bool(int(sys.argv[1]))
	sen2=bool(int(sys.argv[2]))
	if sen2:
		import glob
		#import os
		#os.system('modprobe w1-gpio')
		#os.system('modprobe w1-therm')
		base_dir = '/sys/bus/w1/devices/'
		device_folder = glob.glob(base_dir + '28*')[0]
		device_file = device_folder + '/w1_slave'
		subprocess.run([sys.executable,'gree.py','-b','192.168.1.255','search'])
	min=25+float(sys.argv[3])
	max=27+float(sys.argv[4])
	send=bool(int(sys.argv[5]))
	base=sys.argv[6]
	print(sys.argv[1]+' '+sys.argv[2]+' '+min.__str__()+' '+max.__str__()+' '+sys.argv[5]+' '+sys.argv[6])
	while True:
		#a=
		if sen2:
			#if a==False:
			test(read_temp())
		else:
			test(read_gree_temp())
		time.sleep(30)
