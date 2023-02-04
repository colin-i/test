
from gi.repository import Gtk

from . import sets
from . import draw
from . import points
from . import save
from . import move
from . import point
from . import distance

dif=Gtk.EntryBuffer()

#signbutton,maxlabel
sign_positive="+"

#box,distancebutton,pointsorig,pointsorigh,samplesorig

def open(b,combo):
	global signbutton,maxlabel,calculated,middlerate,pausesbool,anchorbool
	global box,distancebutton,pointsorig,samplesorig,pointsorigh #since pauses can be more points
	box=Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
	#+/- button or not   entry   maxim
	b2=Gtk.Box()
	if draw.baseline!=0:
		signbutton=sets.colorButton(sign_positive,sign,"Sign")
		b2.append(signbutton)
	en=sets.colorEntry(dif)
	b2.append(en)
	b2.append(sets.colorLabel("from 0 to "))
	maxlabel=sets.colorLabel(maximum())
	b2.append(maxlabel)
	box.append(b2)
	#atstart   middle[-1,1]   - or calculated
	cdata,mdata=calculate()
	st=sets.colorLabel(cdata)
	middlerate=sets.colorLabel(mdata)
	calculated=sets.colorLabel("-")
	b3=Gtk.Box(homogeneous=True)
	b3.append(st)
	b3.append(middlerate)
	b3.append(calculated)
	box.append(b3)
	b4=Gtk.Grid()
	b4.attach(left_label("Keep pauses"),0,0,1,1)
	pausesbool=Gtk.CheckButton(active=True)
	b4.attach(pausesbool,1,0,1,1)
	b4.attach(left_label("Keep anchor points"),0,1,1,1)
	anchorbool=Gtk.CheckButton(active=True)
	b4.attach(anchorbool,1,1,1,1)
	box.append(b4)
	#Calculate
	calc=sets.colorButton("Set",calcs,"Calculate")
	box.append(calc)
	#Cancel
	exit=sets.colorButton("Cancel",abort,"Abort",combo)
	box.append(exit)
	bt=sets.colorButton("Return",click,"Finish",combo)
	box.append(bt)
	bt=sets.colorButton("Done",ready,"Set & Return",combo)
	box.append(bt)
	#copies
	#.copy() => it is not deep, _height_ same
	pointsorig=points.points.copy()
	pointsorigh=[]
	for p in points.points:
		pointsorigh.append(p._height_)
	samplesorig=draw.samples.copy()
	distancebutton=None
	#and set
	combo[0].set_child(box)
def left_label(a):
	b=sets.colorLabel(a)
	b.set_halign(Gtk.Align.START)
	return b

def click(b,combo):
	finish(combo)
def finish(combo):
	if not (dtest:=distance.test_all()):
		conclude(combo)
	else:
		global distancebutton
		a=distancebutton
		distancebutton=distance.hold(dtest,distancebutton,callback,combo)
		if not a:
			box.append(distancebutton)
def conclude(combo):
	move.saved(combo) #this here, else problems at get_native().get_surface()
	if sets.get_fulleffect():
		save.saved()
	else:
		abort_samples()
def callback(b,combo):
	conclude(combo)

def sign(b,d):
	if b.get_child().get_text()==sign_positive:
		b._set_text_("-")
	else:
		b._set_text_(sign_positive)
	maxlabel._set_text_(maximum())

def abort_samples():
	draw.samples=samplesorig
def abort(b,combo):
	restore()
	abort_samples()
	done(combo)
def restore():
	points.points.clear()
	for i in range(0,len(pointsorigh)):
		points.points.append(pointsorig[i])
		points.points[i]._height_=pointsorigh[i]

def size_sign():
	if draw.baseline!=0:
		positiv=signbutton.get_child().get_text()==sign_positive
	else:
		positiv=True
	return (get_size(),positiv)
def get_size():
	if draw.baseline!=0:
		return int(draw.sampsize*draw.baseline)
	return draw.sampsize

def maximum():
	a,positiv=size_sign()
	a-=1 #not targeting 32768, but [0,32767]
	x=0
	for p in points.points:
		if p._height_>=0:
			h=p._height_
		else:
			h=-p._height_
		if positiv:
			h=a-h
		if h>x:
			x=h
	return x.__str__()

def not_a_digit(buf):
	buf.set_text("0",-1) #isdigit failed

def psign(r,p,a,sz):
	if r._height_>=0:
		p._height_+=a
		if p._height_>=sz:
			p._height_=sz-1
	else:
		p._height_-=a
		if p._height_<-sz:
			p._height_=-sz
def calcs(b,d):
	modify()
def modify():
	c=dif.get_text()
	if c.isdigit():
		a=int(c)
		b=int(maxlabel.get_text())
		if a>b:
			dif.set_text(b.__str__(),-1)
			return False
		restore() #need no more points or points tend to flat
		sz,sgn=size_sign()
		pauses=[]
		if sgn:
			rng=len(points.points)
			for i in range(0,rng):
				if pause(i,pauses) and anchor(i):
					p=points.points[i]
					if p._height_==0 and rng>1:
						#at positiv loud need to go like sibling if it's 0 not plus only
						if i>0:
							psign(points.points[i-1],p,a,sz)
						else:
							psign(points.points[i+1],p,a,sz)
					else:
						psign(p,p,a,sz)
		else:
			rng=len(points.points)
			for i in range(0,rng):
				p=points.points[i]
				if p._height_>=0:
					if a>=p._height_:
						p._height_=0
					else:
						p._height_-=a
				else:
					if a>=-p._height_:
						p._height_=0
					else:
						p._height_+=a
		resolve(pauses)
		maxlabel._set_text_(maximum())
		save.apply()
		cdata,mdata=calculate()
		calculated._set_text_(cdata)
		middlerate._set_text_(mdata)
		return True
	not_a_digit(dif)
	return False

def done(combo):
	combo[0].set_child(combo[1])

def ready(b,combo):
	if modify():
		finish(combo)

def calculate():
	s=len(points.points)
	if s>=2:
		n=0
		start=points.points[0]._offset_
		stop=points.points[s-1]._offset_
		for i in range(start,stop):
			n+=abs(draw.samples[i])
		med=n/(stop-start)
		#
		a=get_size()/2
		b=med-a
		mid=b/a
		#
		return (med.__str__(),mid.__str__())
	return ("-","-")

def pause(i,lst):
	if pausesbool.get_active():
		a=points.points[i]
		if a._height_==0:
			j=i+1
			first=len(lst)==0
			if j!=len(points.points):
				b=points.points[j]
				if b._height_==0:
					#here is a sound pause
					if first or lst[len(lst)-1]!=i:
						#is new
						lst.append(i)
						lst.append(j)
						if first:
							#the interval start if it is at the start it will not be adjusted
							return False
					else:
						#extend only
						lst[len(lst)-1]=j
						return False
			elif (not first) and lst[len(lst)-1]==i:
				#last that is in pause needs false
				return False
	return True
def anchor(i):
	if anchorbool.get_active():
		if i>0 and i+1<len(points.points) and points.points[i]._height_==0 and points.points[i-1]._height_!=0 and \
		points.points[i+1]._height_!=0 and ((points.points[i-1]._height_^points.points[i+1]._height_)<0):
			return False
	return True

def resolve(pauses):
	sz=len(pauses)
	of=0
	i=0
	while i<sz: #for-loop will not care about i modification inside
		a=pauses[i]
		if a>0:
			insert(a+of,1)
			of+=1
		i+=1
		a=pauses[i]
		if a+1<len(points.points):
			insert(a+of,0)
			of+=1
		i+=1

def insert(ix,more):
	p=points.points[ix]
	points.add(p._offset_,0,False,point.default_convex,ix+more)
