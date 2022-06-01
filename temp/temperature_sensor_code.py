
#git clone https://github.com/pimylifeup/temperature_sensor

#import os
import glob
import time

import sys
import subprocess
import math

#os.system('modprobe w1-gpio')
#os.system('modprobe w1-therm')

base_dir = '/sys/bus/w1/devices/'
device_folder = glob.glob(base_dir + '28*')[0]
device_file = device_folder + '/w1_slave'

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

def gree(a,b):
	s='Pow='+a
	print(s)
	global on
	on=b
	if send:
		subprocess.run([sys.executable,'gree.py','-c','192.168.1.9','-i','f4911e448ee8','-k','9Mn2Pq5St8VwYz4B','set',s])

def test(t,d):
	print(t)
	if math.isnan(t)==False:
		if on==False:
			if t>(max+d):
				gree('1',True)
				return True
		else:
			if t<(min+d):
				gree('0',False)
				return True
	return False

def read_gree_temp():
	return subprocess.run(["/bin/bash",base+'/tget',base]).returncode

if len(sys.argv)==7:
	print(sys.argv[1]+' '+sys.argv[2]+' '+sys.argv[3]+' '+sys.argv[4]+' '+sys.argv[5]+' '+sys.argv[6])
	min=int(sys.argv[1])
	max=int(sys.argv[2])
	dif=int(sys.argv[3])
	send=bool(int(sys.argv[4]))
	sen2=bool(int(sys.argv[5]))
	base=sys.argv[6]
	on=False
	while True:
		a=test(read_gree_temp(),0)
		if sen2:
			if a==False:
				test(read_temp(),dif)
			time.sleep(10)
