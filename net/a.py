
from multiprocessing.connection import Listener

address = ('localhost', 6000)     # family is deduced to be 'AF_INET'
listener = Listener(address, authkey=b'secret password')

import subprocess
import sys
import time

def get_value():
	t=subprocess.check_output(["/bin/bash","-c","ip -s link show "+sys.argv[1]+" | tr -s ' '"])
	#.returncode
	a=t.splitlines()
	b=len(a)
	tx=int(a[b-1].split()[0])
	rx=int(a[b-3].split()[0])
	current=rx+tx
	#return current

	global total,tstamp
	dif=current-total
	total=current
	t=time.time()
	dif/=t-tstamp
	tstamp=t
	return dif

total=0
tstamp=time.time()
get_value()

while True:
	conn = listener.accept()
	#print('connection accepted from', listener.last_accepted)
	dif=get_value()
	conn.send(dif)
	conn.close()
#this is crtl+c closed
#listener.close()
