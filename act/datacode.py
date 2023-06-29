
from gi.repository import GLib,Gtk

import time

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
	line(text)
	global storage
	storage=form(query.today())
	show(text,storage)
	line(text)
	GLib.timeout_add_seconds(60*60,callba,text)
	return text

line_end='\r\n'

def line(text):
	b=text.get_buffer()
	it=b.get_start_iter()
	b.insert(it,"-"+line_end,-1)

def show(text,data):
	b=text.get_buffer()
	it=b.get_start_iter()
	for x in data:
		n=data[x]
		for i in range(0,n):
			mark(b,it,'xx-large',x)

def mark(b,it,s,x):
	b.insert_markup(it,'<span size=\"'+s+'\">'+x+'</span>'+line_end,-1)

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
	b=text.get_buffer()
	loctim=time.localtime(t)
	mark(b,b.get_start_iter(),'small',loctim.tm_hour.__str__()+":"+loctim.tm_min.__str__())

	if len(dif):
		show(text,dif)

	return True
