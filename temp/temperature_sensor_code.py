
#git clone https://github.com/pimylifeup/temperature_sensor
#git clone --depth 1
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
	try:
		if lines[0].strip()[-3:] == 'YES':
			equals_pos = lines[1].find('t=')
			if equals_pos != -1:
				temp_string = lines[1][equals_pos+2:]
				temp_c = int(temp_string) / 1000
				#temp_f = temp_c * 9.0 / 5.0 + 32.0
				return temp_c #, temp_f
	except Exception as e:
		print(e.__str__())
	return float('nan')

def read_gree_temp():
	t=subprocess.run(["/bin/bash",base+'/tget',base]).returncode
	if t==216: #that will be wi-fi timeout
		return float('nan')
	return t

import os
iplocation=os.path.expanduser('~')+"/gree_ip"
with open(iplocation,"rb") as f:
	greeip=f.read()

def gree(a): #,b):
	s='Pow='+a
	print(s)
	if send:
		print('send')
		#return is 0 at timeout later
		#r=
		subprocess.run([sys.executable,'gree.py','-c',greeip,'-i','f4911e448ee8','-k',key,'set',s])
		#.returncode
		#if r!=0:
		#	return
	#print(s)
	#global on
	#on=b
def stop():
	z=subprocess.run([sys.executable,'gree.py','-c',greeip,'-i','f4911e448ee8','-k',key,'get','Pow'],capture_output=True,text=True)
	if z.stdout != 'Getting parameters: Pow\nPow = 0\n':
		gree('0') #,False)
	else:
		print("is off")
lasttemp=0
def test(t):
	global lasttemp
	print(t)
	if math.isnan(t)==False:
		if t>max:
			if lasttemp<=t:
				z=subprocess.run([sys.executable,'gree.py','-c',greeip,'-i','f4911e448ee8','-k',key,'get','Pow'],capture_output=True,text=True)
				if z.stdout != 'Getting parameters: Pow\nPow = 1\n':
					gree('1') #,True)
				else:
					print("is on")
		elif t<=min:
			if t<=lasttemp:
				stop()
		lasttemp=t
	sys.stdout.flush()
	#python -u is for | tee (or >~1),to see print() calls, but pdb -u is not ok

def t2_f():
	while True:
		#a=
		if sen2:
			#if a==False:
			test(read_temp())
		else:
			test(read_gree_temp())
		time.sleep(30)
		if done==1:
			break
	stop()
import threading
import readchar

if len(sys.argv)==6:
	print('min='+sys.argv[1]+', max='+sys.argv[2]+', sen2='+sys.argv[3]+', send='+sys.argv[4]+', base='+sys.argv[5])
	#on=bool(int(sys.argv[1]))
	min=float(sys.argv[1])
	max=float(sys.argv[2])
	sen2=bool(int(sys.argv[3]))
	send=bool(int(sys.argv[4]))
	key=os.environ['gree_key']
	if sen2:
		import glob
		#import os
		#os.system('modprobe w1-gpio')
		#os.system('modprobe w1-therm')
		base_dir = '/sys/bus/w1/devices/'
		device_folder = glob.glob(base_dir + '28*')[0]
		device_file = device_folder + '/w1_slave'
		subprocess.run([sys.executable,'gree.py','-b','192.168.1.255','search']) #it is a bind until shotdown
	else:
		base=sys.argv[5]
	t2 = threading.Thread(target=t2_f)
	done=0
	t2.start()
	readchar.readchar()
	print("will close")
	done=1
