
from seleniumwire import webdriver
from selenium.webdriver.chrome.options import Options
import time
import sys, os
import fcntl
import psutil
import subprocess
import threading
import pyperclip

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
match=os.environ.get("match")
if match==None:
	match="pull"
site=os.environ.get("site")
if site==None:
	site="https://www.tiktok.com/"
close_on_link=os.environ.get("close_on_link")
print("timeout="+timeout+",no_keys="+("" if no_keys==None else no_keys)+",match="+match+",site="+site+",close_on_link="+("" if close_on_link==None else close_on_link))

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
	#f.write(r.url.encode())
	#f.write(b'\n')
	if r.url[0:12]=="https://"+match:
		print(r.url)
		pyperclip.copy(r.url)
		if close_on_link!=None:
			global done
			done=1
			#exec(on_link)
		else:
			subprocess.Popen(["zenity","--info","--text=ok","--timeout="+timeout])

options=webdriver.ChromeOptions()
options.add_argument("user-data-dir=/home/bc/.config/chromium")
d=webdriver.Chrome(options=options)
d.request_interceptor=t2_f
d.get(site+sys.argv[1])

fd = sys.stdin.fileno()
oldflags = fcntl.fcntl(fd, fcntl.F_GETFL)
fcntl.fcntl(fd, fcntl.F_SETFL, oldflags | os.O_NONBLOCK)

p=d.service.process.pid
p=psutil.Process(p)

done=None
while True:
	time.sleep(10)
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
	print("a")
	if done!=None:
		d.close()
		d.quit()
		break
print("z")
exit(0)

# sudo swapoff -a
