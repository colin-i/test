
from gi.repository import GLib,Gtk,Gdk

import time
import os.path
import subprocess

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
	with open(os.path.expanduser('~')+"/load_ip","rb") as f:
		address = (f.read(), 5000)
	listener = Listener(address)
	while listener.accept():
		GLib.idle_add(from_th,text)
		#c.close() #Warning: Source ID 91 was not found when attempting to remove it
	#print('closed')

def termfn(dummy):
	subprocess.run(["gtk-launch","term.desktop"])

def init(loop,pointer):
	text=Gtk.TextView(editable=False,vexpand=True) #,wrap_mode=Gtk.WrapMode.NONE

	th = threading.Thread(target=th_f,args=[text])
	th.start()

	show(text,form(query.yesterday()))
	#
	f=os.path.join(os.path.dirname(__file__),'x')
	t=subprocess.check_output(f)
	total={};total["+"+t.decode()]=1
	show(text,total)
	#
	global storage
	storage=form(query.today())
	show(text,storage)

	smallmark(text,time.time())

	box=Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
	box.append(text)

	global monitors,monitor
	m=Gdk.Display.get_default().get_primary_monitor()
	monitors=Gdk.Display.get_default().get_monitors()
	monitor=0
	for x in monitors:
		if x==m:
			break
		monitor+=1
	monitors=monitors.get_n_items()
	if monitors>1:
		state=Gtk.Button.new_with_label("Move")
		state.connect('clicked', move)
		box.append(state)

	te=Gtk.Button.new_with_label("Term")
	te.connect('clicked', termfn)
	box.append(te)

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
	container[0]=1
	loop.quit()

def exitfn(b,loop):
	#global listener
	#listener.close() still must accept one more
	loop.quit()

def move(b):
	global monitor,monitors
	monitor=monitor+1
	if monitor==monitors:
		monitor=0
	m=Gdk.Display.get_default().get_monitors()[monitor]
	position(m)

title="Activity"

# python3-xlib
import Xlib.display

def position(mon):
	#xid=win.get_surface().get_xid()
	#xdisp=disp.get_xdisplay()
	#xwin = Xlib.display.drawable.Window(xdisp, id)
	#xwin = Xlib.display.drawable.Window(Xlib.display.Display(), id)
	#xwin.configure will not work

	rect=mon.get_geometry()
	y=30
	w=rect.width/16
	h=rect.height-y-5 #-5? will not fit and will go in another monitor
	x=rect.x+rect.width-w

	d = Xlib.display.Display()
	r = d.screen().root
	window_ids = r.get_full_property(
		d.intern_atom('_NET_CLIENT_LIST'), Xlib.X.AnyPropertyType
	).value
	for window_id in window_ids:
		xwin = d.create_resource_object('window', window_id)
		if title==xwin.get_wm_name():
			xwin.configure(
				x=x.__int__(),
				y=y.__int__(),
				width=w.__int__(),
				height=h.__int__()
				#border_width=10
				#,stack_mode=Xlib.X.Above
			)
			d.sync()

def screen():
	position(Gdk.Display.get_default().get_monitors()[monitor])
