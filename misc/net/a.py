
from multiprocessing.connection import Listener

address = ('localhost', 6000)     # family is deduced to be 'AF_INET'
listener = Listener(address, authkey=b'secret password')

import subprocess

#total=0

def get_value():
	t=subprocess.check_output(["/bin/bash","-c","ip -s link show wwan0 | tr -s ' '"])
	#.returncode
	a=t.splitlines()
	b=len(a)
	tx=int(a[b-1].split()[0])
	rx=int(a[b-3].split()[0])
	current=rx+tx
	#
	#global total
	#dif=current-total
	#total=current
	#return dif
	return current

get_value()

while True:
	conn = listener.accept()
	#print('connection accepted from', listener.last_accepted)
	dif=get_value()
	conn.send(dif)
	conn.close()
#this is crtl+c closed
#listener.close()
