
from gi.repository import GLib,Gtk

from . import query

def form(js):
	#json.dumps(js, indent=1)
	d=js["data"]["viewer"]["contributionsCollection"]["commitContributionsByRepository"]
	out={}
	for x in d:
		out[x["repository"]["name"]]=x["contributions"]["edges"][0]["node"]["commitCount"]
	return out

def init():
	text=Gtk.TextView(editable=False,wrap_mode=Gtk.WrapMode.WORD_CHAR)
	show(text,form(query.yesterday()))
	global storage
	storage=form(query.today())
	show(text,storage)
	GLib.timeout_add_seconds(60*60,callba,text)
	return text

def show(text,data):
	b=text.get_buffer()
	it=b.get_start_iter()

	for x in data:
		n=data[x]
		for i in range(0,n):
			b.insert(it,x+'\r\n',-1)

def callba(text):
	global storage
	now=form(query.today())

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

	#print the hour

	if len(dif):
		show(text,dif)

	return True
