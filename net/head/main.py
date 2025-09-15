
#if having mem: in /etc/rc.local swapoff -a
#1 /@x/live
# python3-selenium python3-pyperclip python3-zstandard  pip install selenium-wire
# crashsleep crashlimit lessressmatch lessressite

from seleniumwire import webdriver
from selenium.webdriver.chrome.options import Options
import time
import sys, os
import fcntl
import psutil
import subprocess
import threading
import pyperclip

HOME=os.getenv('HOME')

timeout=os.environ.get("timeout")
if timeout==None:
	timeout="10"
no_keys=os.environ.get("no_keys")
if no_keys==None:
	def t3_f():
		popen = subprocess.Popen(["sudo","python","keys"], stdout=subprocess.PIPE)
		while True:
			line=popen.stdout.readline()
			if line[0]==ord('s'):
				stop()
			else:
				cont()
		#popen.stdout.close()
		#popen.wait()
	t3 = threading.Thread(target=t3_f)
	t3.start()
no_cpulimit=os.environ.get("no_cpulimit")
if no_cpulimit==None:
	fd = sys.stdin.fileno()
	oldflags = fcntl.fcntl(fd, fcntl.F_GETFL)
	fcntl.fcntl(fd, fcntl.F_SETFL, oldflags | os.O_NONBLOCK)
match=os.environ.get("match")
if match==None:
	with open(HOME+'/lessressmatch', 'r') as file: #pull
		match=file.read()
match_len=len(match)
site=os.environ.get("site")
if site==None:
	with open(HOME+'/lessressite', 'r') as file:   #https://www..com
		site=file.read()
close_on_link=os.environ.get("close_on_link")
with open(HOME+'/crashlimit', 'r') as file: #200000000
	min = int(file.read()) #in Bytes
with open(HOME+'/crashsleep', 'r') as file: #10
	sleep = int(file.read())
debug=os.environ.get("debug")
print("timeout="+timeout+",no_keys="+("" if no_keys==None else no_keys)+",no_cpulimit="+("" if no_cpulimit==None else no_cpulimit)+",match="+match+",site="+site+",close_on_link="+("" if close_on_link==None else close_on_link)+",min="+str(min)+",sleep="+str(sleep)+",debug="+("" if debug==None else debug))

def stop():
	print("stop")
	ps=p.children(recursive=True)
	pid=""
	for a in ps:
		pid=pid+' '+str(a.pid)
	subprocess.run(["/bin/bash","./stop",pid])
def cont():
	print("cont")
	subprocess.run(["pkill","-f","^cpulimit"])
#f=open("test","wb")
def t2_f(r):
	if debug!=None:
		print(r.url) #f.write(r.url.encode()) #f.write(b'\n')
	if r.url[0:8+match_len]=="https://"+match:
		print(r.url)
		if close_on_link!=None:
			#exec(on_link)
			global done
			if done==None:
				done=1
			else:
				return  #is closing in another thread, and can go some minutes there
		else:
			subprocess.Popen(["zenity","--info","--text=ok","--timeout="+timeout])
		pyperclip.copy(r.url)

done=None
options=webdriver.ChromeOptions()
options.add_argument("user-data-dir=/home/bc/.config/chromium")
d=webdriver.Chrome(options=options)
d.request_interceptor=t2_f
p=d.service.process.pid
p=psutil.Process(p)
from datetime import datetime
#after_load=0

end=0
def t4_f():
	while True:
		time.sleep(sleep)
		m=psutil.virtual_memory().available
		print(str(datetime.now().minute)+' '+str(m))
		if m<min:
			print("limita")
			with open(HOME+'/killstop', 'w') as file:
				pass
			break
		if end==1:
			break
t4 = threading.Thread(target=t4_f)
t4.start()
d.get(site+sys.argv[1])
#after_load=1
print("after load")

def closing():
	try:
		d.close()
	except:
		pass #is already closed (the window)
	d.quit()

#ex=0
if no_cpulimit==None:
	while True:
		time.sleep(sleep)
		if done!=None:
			closing()
			break
		c = sys.stdin.read(1)
		if c!='':
			if c==' ':
				stop()
				sys.stdin.read(1)
				continue
			elif c=='c':
				cont()
				sys.stdin.read(1)
				continue
			break
else:
	while True:
		time.sleep(sleep)
		if done!=None:
			closing()
			break
#	m=psutil.virtual_memory().available
#	print(str(datetime.now().minute)+' '+str(m))
#	if m<min:
#		print("limita")
#		closing()
#		ex=1
#		break
end=1
print("end")
#exit(ex)
