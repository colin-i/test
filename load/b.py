
#import os
#print(os.get_terminal_size().columns)

class bcolors:
	#red = '\033[101m'
	#green = '\033[102m'
	#yellow = '\033[103m'
	end = '\033[0m'
	bold = '\033[1m'
	#underline = '\033[4m'

from multiprocessing.connection import Listener

address = ('192.168.1.15', 6000)     # family is deduced to be 'AF_INET'
listener = Listener(address)
zone=False
outfile=open("./load-output.html","w")

def outtitle(s):
	print(f"{bcolors.bold}Overall{bcolors.end}")  #if not end will continue at next print
	outfile.write("<h3>"+s+"</h3>\n")
def outline(s):
	print(s)
	outfile.write(s+"<br>\n")

def t2_f():
	global zone
	valuesall=[]
	try:
		while True:
			conn = listener.accept()
			val=int(conn.recv())
			print(val)
			conn.close()
			if zone:
				break
		while True:
			if zone:
				print("new zone")
				zone=False
				values=[val];valuesall.append(values)
			else:
				values.append(val)
			conn = listener.accept()
			val=int(conn.recv())
			print(val)
			conn.close()
	except Exception:
		print("closed")
	sum=0;i=0
	for values in valuesall:
		for val in values:
			sum+=val
			i+=1
	outtitle("Overall")
	outline("Entries: "+str(i)+" , Ratio: "+str(int(sum/i)))
	outfile.close()

import threading
t2 = threading.Thread(target=t2_f)
t2.start()

while True:
	import readchar
	c=readchar.readchar()
	if c=='q':
		break
	else:
		print("will change zone")
		zone=True
print("will close")
listener.close()   #this will close after accept gets next client
#if there are threads python will not exit
