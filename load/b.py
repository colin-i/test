
#import os
#print(os.get_terminal_size().columns)

class bcolors:
	red = '\033[101m'
	green = '\033[102m'
	yellow = '\033[103m'
	end = '\033[0m'
	bold = '\033[1m'
	#underline = '\033[4m'

from multiprocessing.connection import Listener

address = ('192.168.1.15', 6000)     # family is deduced to be 'AF_INET'
listener = Listener(address)
zone=False
outfile=open("./load-output.html","w")
middle=95
hysteresis=5
paused=False
chzone="will change zone"

import sys
try:
	middle=int(sys.argv[1])
	hysteresis=int(sys.argv[2])
except Exception:
	pass
print("middle="+str(middle)+",hysteresis="+str(hysteresis))

def outtitle(s):
	print(f"{bcolors.bold}"+s+"{bcolors.end}")  #if not end will continue at next print
	outfile.write("<h3>"+s+"</h3>\n")
def outlineend():
	print()
	outfile.write("<br>\n")
def outline(s):
	print(s,end='')
	outfile.write(s)
	outlineend()
def outgtext(sum,i):
	if i:
		s=formstr(sum,i)
		print(f" {bcolors.green}"+s+f"{bcolors.end} ",end='')
		outfile.write(" <span style=\"color:green\">"+s+"</span> ")
def outytext(sum,i):
	if i:
		s=formstr(sum,i)
		print(f" {bcolors.yellow}"+s+f"{bcolors.end} ",end='')
		outfile.write(" <span style=\"color:yellow\">"+s+"</span> ")
def outrtext(sum,i):
	if i:
		s=formstr(sum,i)
		print(f" {bcolors.red}"+s+f"{bcolors.end} ",end='')
		outfile.write(" <span style=\"color:red\">"+s+"</span> ")
def formstr(sum,i):
	return "Entries: "+str(i)+" , Ratio: "+str(int(sum/i))

def show(vals,text):
	sum=0;i=0
	sumleft=0;ileft=0;sumcenter=0;icenter=0;sumright=0;iright=0;
	left=middle-hysteresis;right=middle+hysteresis
	for values in vals:
		for val in values:
			sum+=val;i+=1
			if val<left:
				sumleft+=val;ileft+=1
			elif val<right:
				sumcenter+=val;icenter+=1
			else:
				sumright+=val;iright+=1
	outtitle(text)
	outline(formstr(sum,i))
	outgtext(sumleft,ileft);outytext(sumcenter,icenter);outrtext(sumright,iright);outlineend()

def t2_f():
	global zone, values
	valuesall=[]
	try:
		while True:
			conn = listener.accept()
			val=int(conn.recv())
			conn.close()

			if zone:
				break
			print(val)
		while True:
			if zone:
				print("new zone")
				zone=False
				values=[val];valuesall.append(values)
			elif paused==False:
				values.append(val)
			print(val)

			conn = listener.accept()
			val=int(conn.recv())
			conn.close()
	except Exception:
		print("closed")

	zonedone()
	show(valuesall,"Overall")
	outfile.close()

def zonedone():
	global zone
	print(chzone)
	zone=True
	show([values],"Zone")

import threading
t2 = threading.Thread(target=t2_f)
t2.start()

import readchar
c=readchar.readchar()
print(chzone)
zone=True

while True:
	c=readchar.readchar()
	if c=='q':
		break
	elif c==' ':
		if paused==False:
			paused=True
			print("paused")
		else:
			paused=False
			print("resumed")
	else:
		zonedone()

print("will close")
listener.close()   #this will close after accept gets next client
#if there are threads python will not exit
