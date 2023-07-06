
class bcolors:
	red = '\033[101m'
	green = '\033[102m'
	yellow = '\033[103m'
	end = '\033[0m'
	bold = '\033[1m'
	#underline = '\033[4m'
def outlineend2(outfile): #can't let outfile twice declared
	print()
	outfile.write("<br>\n")

if __name__ == "__main__":
	import sys
	import threading
	import readchar
	import os
	from multiprocessing.connection import Listener

	def outtitle(s):
		print(f"{bcolors.bold}"+s+f"{bcolors.end}")  #if not end will continue at next print
		outfile.write("<h3>"+s+"</h3>\n")
	def outlineend():
		outlineend2(outfile)
	def outline(s):
		print(s,end='')
		outfile.write(s)
		outlineend()
	def text_and_colors(s,c):
		e=f"{bcolors.end}"
		print(" "+c+" "+e+s+c+" "+e+" ",end='')
	def text_and_colors_file(s,c):
		a=" <span style=\"color:"+c+"\">&#x2588;</span> "
		outfile.write(a+s+a)
	def outgtext(sum,i):
		if i:
			s=formstr(sum,i)
			text_and_colors(s,f"{bcolors.green}")
			text_and_colors_file(s,"green")
	def outytext(sum,i):
		if i:
			s=formstr(sum,i)
			text_and_colors(s,f"{bcolors.yellow}")
			text_and_colors_file(s,"yellow")
	def outrtext(sum,i):
		if i:
			s=formstr(sum,i)
			text_and_colors(s,f"{bcolors.red}")
			text_and_colors_file(s,"red")
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

	with open(os.path.expanduser('~')+"/rpi2_ip","rb") as f:
		address = (f.read(), 6000)     # family is deduced to be 'AF_INET'
	listener = Listener(address)
	zone=False
	outfile=open("./load-output.html","w")
	middle=95
	hysteresis=5
	paused=False
	zonenr=0

	from .bb import zoneline

	try:
		middle=int(sys.argv[1])
		hysteresis=int(sys.argv[2])
	except Exception:
		pass
	print("middle="+str(middle)+",hysteresis="+str(hysteresis))

	t2 = threading.Thread(target=t2_f)
	t2.start()
	c=readchar.readchar()
	print("will start")
	zone=True
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
