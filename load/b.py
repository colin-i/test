
class bcolors:
	red = '\033[101m'
	green = '\033[102m'
	yellow = '\033[103m'
	end = '\033[0m'
	bold = '\033[1m'
	#underline = '\033[4m'

import sys
import threading
import readchar
import os
from multiprocessing.connection import Listener

address = ('192.168.1.15', 6000)     # family is deduced to be 'AF_INET'
listener = Listener(address)
zone=False
outfile=open("./load-output.html","w")
middle=95
hysteresis=5
paused=False
zonenr=0

try:
	middle=int(sys.argv[1])
	hysteresis=int(sys.argv[2])
except Exception:
	pass
print("middle="+str(middle)+",hysteresis="+str(hysteresis))

def outtitle(s):
	print(f"{bcolors.bold}"+s+f"{bcolors.end}")  #if not end will continue at next print
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
def ens(i):
	return "Entries: "+str(i)
def ratio(sum,i):
	return " , Ratio: "+str(int(i*100/sum))
def formstr(sum,i):
	return ens(i)+ratio(sum,i)
def show(vals,text):
	i=0;ileft=0;icenter=0;iright=0;
	#sum=0;sumleft=0;sumcenter=0;sumright=0;
	left=middle-hysteresis;right=middle+hysteresis
	for valus in vals:
		for val in valus:
			i+=1 #sum+=val
			if val<left:
				ileft+=1 #sumleft+=val
			elif val<right:
				icenter+=1 #sumcenter+=val
			else:
				iright+=1 #sumright+=val
	outtitle(text)
	outline(ens(i))
	outgtext(i,ileft);outytext(i,icenter);outrtext(i,iright);outlineend()
	zoneline(i,ileft,icenter,iright)

def newzone(val):
	global zone, values
	print("new zone")
	zone=False
	values=[val];valuesall.append(values)

def t2_f():
	global zone, values, valuesall
	valuesall=[]
	try:
		while True:
			conn = listener.accept()
			val=int(conn.recv())
			conn.close()

			if zone:
				newzone(val)
				print(val)
				break
			print(val)
		while True:
			conn = listener.accept()
			val=int(conn.recv())
			conn.close()
			if zone:
				zonedone()
				newzone(val)
			elif paused==False:
				values.append(val)
			print(val)
	except Exception:
		print("closed")

	zonedone()
	show(valuesall,"Overall")
	outfile.close()

def zonedoneset():
	global zone
	print("will change zone")
	zone=True
def zonedone():
	global zonenr
	zonenr=zonenr+1
	show([values],"Zone "+str(zonenr))

t2 = threading.Thread(target=t2_f)
t2.start()

c=readchar.readchar()
print("will start")
zone=True

def zoneline(i,l,c,r):
	columns=os.get_terminal_size().columns
	x=l*columns
	y=c*columns
	z=r*columns
	solids=[int(x/i),int(y/i),int(z/i)]
	rests=[(x%i,0),(y%i,1),(z%i,2)]
	columnstobeshared=(rests[0]+rests[1]+rests[2])/i
	rests.sort(reverse=True)

	while columnstobeshared:
		rest,col=rests[0]
		rests.pop(0)
		solids[col]+=1
		columnstobeshared-=1

while True:
	c=readchar.readchar()
	if c=='q':
		break
	elif c==' ':
		if paused==False:
			paused=True
			print("paused")
			zonedoneset()
		else:
			paused=False
			print("resumed")
	else:
		zonedoneset()

print("will close")
listener.close()   #this will close after accept gets next client
#if there are threads python will not exit
