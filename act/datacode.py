
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

def init():
	text=Gtk.TextView(editable=False) #,wrap_mode=Gtk.WrapMode.NONE

	show(text,form(query.yesterday()))

	f=os.path.join(os.path.dirname(__file__),'x')
	t=check_output(f)
	total={};total["+"+t.decode()]=1
	show(text,total)

	global storage
	storage=form(query.today())
	show(text,storage)

	smallmark(text,time.time())

	GLib.timeout_add_seconds(60*60,callba,text)
	return text

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
