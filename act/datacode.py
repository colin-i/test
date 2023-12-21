
from gi.repository import GLib,Gtk

import time
import os.path
from subprocess import check_output

from . import query

def form(js):
	#json.dumps(js, indent=1)
	d=js["data"]["viewer"]["contributionsCollection"]["commitContributionsByRepository"]
	out={}
	for x in d:
		out[x["repository"]["name"]]=x["contributions"]["edges"][0]["node"]["commitCount"]
	return out

from multiprocessing.connection import Listener
import threading

def from_th(text):
	callba(text)

def th_f(text):
	address = ('192.168.1.11', 5000)
	listener = Listener(address)
	while listener.accept():
		GLib.idle_add(from_th,text)
		#c.close() #Warning: Source ID 91 was not found when attempting to remove it
	#print('closed')

def init(loop,pointer):
	text=Gtk.TextView(editable=False,vexpand=True) #,wrap_mode=Gtk.WrapMode.NONE

	th = threading.Thread(target=th_f,args=[text])
	th.start()

	show(text,form(query.yesterday()))

	f=os.path.join(os.path.dirname(__file__),'x')
	t=check_output(f)
	total={};total["+"+t.decode()]=1
	show(text,total)

	global storage
	storage=form(query.today())
	show(text,storage)

	smallmark(text,time.time())

	box=Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
	box.append(text)

	state=Gtk.Button.new_with_label("Start")
	state.connect('clicked', toggle, text)
	box.append(state)

	if not os.path.isfile(get_flag()):
		toggle(state,text)

	get=Gtk.Button.new_with_label("Get")
	get.connect('clicked', getfn, text)
	box.append(get)

	relaunch=Gtk.Button.new_with_label("Relaunch")
	relaunch.connect('clicked', relaunchfn, (loop,pointer))
	box.append(relaunch)

	exit=Gtk.Button.new_with_label("Exit")
	exit.connect('clicked', exitfn, loop)
	box.append(exit)

	return box

def show(text,data):
	b=text.get_buffer()
	it=b.get_start_iter()
	for x in data:
		n=data[x]
		for i in range(0,n):
			mark(b,it,'xx-large',x)

def mark(b,it,s,x):
	b.insert_markup(it,'<span size=\"'+s+'\">'+x+'</span>\r\n',-1)
def smallmark(text,t):
	loctim=time.localtime(t)
	b=text.get_buffer()
	mark(b,b.get_start_iter(),'small',loctim.tm_hour.__str__()+":"+loctim.tm_min.__str__())

def callba(text):
	t=time.time()

	global storage
	now=form(query.day_core(t,0))

	dif={}
	for x in now:
		b=now[x]
		#if ((x in storage)==False):
		if x in storage:
			a=storage[x]
			if a<b:
				dif[x]=b-a
		else:
			dif[x]=b
	storage=now

	#print the hour:min
	smallmark(text,t)

	if len(dif):
		show(text,dif)

	return True

def getfn(b,text):
	callba(text)

def get_flag():
	return os.path.expanduser("~/arh/activity_flag")
def toggle(b,text):
	global callid
	f=get_flag()
	if b.get_label()=='Start':
		callid=GLib.timeout_add_seconds(60*60,callba,text)
		b.set_label('Pause')
		if os.path.isfile(f):
			os.remove(f) #remove flag
	else:
		GLib.source_remove(callid) #boolean
		b.set_label('Start')
		file=open(f, "w") #set flag
		file.close()

def relaunchfn(b,pack):
	loop,container=pack
	container[0]=True
	loop.quit()

def exitfn(b,loop):
	#global listener
	#listener.close() still must accept one more
	loop.quit()
