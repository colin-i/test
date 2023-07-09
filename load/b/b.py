
class bcolors:
	high = '\x1b[37;41m'
	low = '\x1b[37;44m'

	normal = '\x1b[30;42m'
	#yellow? 103 and 48;2;255;255;0 will be same vga orange 170,85,0 (43), to differ from red(170,0,0) use 44 which is 0,0,170

	end = '\033[0m'
	bold = '\033[1m'
	#underline = '\033[4m'
def outline2(s,outfile):
	print(s,end='')
	outfile.write(s)
	outlineend2(outfile)
def outlineend2(outfile):
	outlineend3(outfile,True)
def outlineend3(outfile,started): #can't let outfile twice declared
	print()
	if started:
		outfile.write("<br>\n")
def colortext(c,text):
	return "<span class=\"ch"+c+"\">"+text+"</span>"

if __name__ == "__main__":
	import sys
	import threading
	import readchar
	import os
	import time
	from multiprocessing.connection import Listener

	def outtitle(s):
		print(f"{bcolors.bold}"+s+f"{bcolors.end}")  #if not end will continue at next print
		outfile.write("<h3>"+s+"</h3>\n")
	def outline(s):
		outline2(s,outfile)
	def outlineend():
		outlineend2(outfile)
	def text_and_colors(s,c):
		e=f"{bcolors.end}"
		print(" "+c+" "+e+s+c+" "+e+" ",end='')
	def text_and_colors_file(s,c):
		a=" "+colortext(c,"&#x2588;")+" "
		outfile.write(a+s+a)
	def outgtext(sum,i):
		if i:
			s=formstr(sum,i)
			text_and_colors(s,f"{bcolors.low}")
			text_and_colors_file(s,"low")
	def outytext(sum,i):
		if i:
			s=formstr(sum,i)
			text_and_colors(s,f"{bcolors.normal}")
			text_and_colors_file(s,"normal")
	def outrtext(sum,i):
		if i:
			s=formstr(sum,i)
			text_and_colors(s,f"{bcolors.high}")
			text_and_colors_file(s,"high")
	def ens(i):
		return "Entries: "+str(i)
	def ratio(sum,i):
		return " , Ratio: "+str(int(i*100/sum))
	def formstr(sum,i):
		return ens(i)+ratio(sum,i)
	def show(vals):
		i=0;ileft=0;icenter=0;iright=0;
		#sum=0;sumleft=0;sumcenter=0;sumright=0;
		for valus in vals:
			for val in valus:
				i+=1 #sum+=val
				if val<leftlim:
					ileft+=1 #sumleft+=val
				elif val<rightlim:
					icenter+=1 #sumcenter+=val
				else:
					iright+=1 #sumright+=val
		outline(ens(i))
		outgtext(i,ileft);outytext(i,icenter);outrtext(i,iright);outlineend()

		zoneline(i,ileft,icenter,iright)

	def newzone(val):
		global zone, values, zonenr
		zonenr=zonenr+1
		outtitle("Zone "+str(zonenr))
		zone=False
		values=[val];valuesall.append(values)

	def t2_f():
		global zone, values, valuesall, paused
		valuesall=[]
		try:
			while True:
				conn = listener.accept()
				val=int(conn.recv())
				conn.close()

				if zone:
					newzone(val)
					break
				valueline(val,False)
			valueline(val,True)
			unwait()
			while True:
				conn = listener.accept()
				val=int(conn.recv())
				conn.close()
				if zone:
					zonedone()
					newzone(val)
					valueline(val,True)
					if threadspaused:
						paused=True
						print("paused")
					unwait()
				elif paused==False:
					values.append(val)
					valueline(val,True)
				else:
					valueline(val,False)
					if threadspaused==False:
						paused=False
						print("resumed")
						unwait()
					else:
						print("skipped")
		except Exception:
			print("closed")

		zonedone()
		outtitle("Overall")
		show(valuesall)
		outfile.close()

	def zonedoneset():
		global zone
		print("will change zone")
		zone=True
	def zonedone():
		show([values])

	def wait():
		global is_ready
		while is_ready==False:
			print(".",end='',flush=True)
			time.sleep(1)
		is_ready=False
	def unwait():
		global is_ready
		is_ready=True

	is_ready=False
	with open(os.path.expanduser('~')+"/rpi2_ip","rb") as f:
		address = (f.read(), 6000)     # family is deduced to be 'AF_INET'
	listener = Listener(address)
	zone=False
	outfile=open("./load-output.html","w")
	middle=90
	hysteresis=5
	paused=False
	threadspaused=False
	zonenr=0
	try:
		middle=int(sys.argv[1])
		hysteresis=int(sys.argv[2])
	except Exception:
		pass
	leftlim=middle-hysteresis;rightlim=middle+hysteresis

	#first value is the process id for maximum usage calculations
	conn = listener.accept()
	global procthreads
	procthreads=conn.recv()
	conn.close()

	from .bb import zoneline
	from .bb import valueline

	t2 = threading.Thread(target=t2_f)
	t2.start()
	c=readchar.readchar()
	print("will start")
	zone=True
	wait()
	while True:
		c=readchar.readchar()
		if c=='q':
			break
		elif c==' ':
			if threadspaused==False:
				threadspaused=True
				zonedoneset()
				print("will pause")
				wait()
			else:
				threadspaused=False
				print("will resume")
				wait()
		else:
			zonedoneset()
			wait()

	print("will close")
	listener.close()   #this will close after accept gets next client
	#if there are threads python will not exit
