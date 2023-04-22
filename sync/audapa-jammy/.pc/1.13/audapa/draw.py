import pyaudio
import wave

from gi.repository import Gtk,Gdk
import cairo

from . import sets
from . import drawscroll
from . import play
from . import seloff
from . import forms
from . import graph

#area,cont,over
offset=0
#length
#samples
#size
#size here is visible samples

#sampsize,baseline,surface,ostore,wstore,hstore

def draw_none(widget,cr,width,height,d,u):
	co=Gdk.RGBA()
	if co.parse(sets.get_text_color()):
		#set line color
		cr.set_source_rgb(co.red,co.green,co.blue)
	cr.set_line_width(1)#default 2.0; cairo scale is 1
	if width>=height:
		y=height/2
		cr.move_to(0,y)
		cr.line_to(width,y)
	else:
		x=width/2
		cr.move_to(x,0)
		cr.line_to(x,height)
	cr.stroke()
def draw_cont(widget,cr,width,height,d,d2):
	n=length-offset
	if drawscroll.calculate(n):
		return
	global ostore,wstore,hstore
	if ostore!=offset or wstore!=width or hstore!=height:
		global size
		ostore=offset
		wstore=width
		hstore=height
		size=min(width,n) if drawscroll.landscape else min(height,n)
		unsel(offset,offset+size)
		draw_sel()
	cr.set_source_surface (surface, 0, 0)
	cr.paint ()
def draw_sel():
	start=seloff.start._get_()
	end=seloff.end._get_()
	if start<(offset+size) and end>offset:
		sel(max(start,offset),min(end,offset+size))
def surf():
	global surface
	surface = area.get_native().get_surface().create_similar_surface(cairo.Content.COLOR,wstore,hstore)
def redraw():
	surf()
	graph.redraw()
	area.queue_draw()

def init():
	global area,over
	area=Gtk.DrawingArea()
	area.set_draw_func (draw_none,None,None)
	over=Gtk.Overlay()
	over.set_child(area)
	return over
def close():
	over.remove_overlay(cont)
	graph.close(over)
	global offset,length#for r_offset
	offset=0
	length=0
	area.disconnect(res_id)
	area.set_draw_func (draw_none,None,None)
	drawscroll.calculate(0)
	play.stop()
def get_samples(sampwidth,channels,data):
	blockAlign=sampwidth*channels
	tot=length*blockAlign
	global samples
	samples=[]
	scan=play.scan(sampwidth,channels)
	for i in range(0, tot, blockAlign):
		s=wave.struct.unpack(scan, data[i:i+blockAlign])
		samples.append(s[0])
def open(sampwidth,channels):
	graph.open(over)
	global cont
	cont=Gtk.Fixed()#fixed is not tracking window default-width
	over.add_overlay(cont)
	#
	global wstore,hstore,sampsize,baseline
	reset()
	#wstore=-1 one flag is enaugh
	#hstore=-1
	sampsize=2**(8*sampwidth)
	fm=play.scan_format(sampwidth,channels)
	baseline=(1/2) if fm.islower() else 0
	global res_id
	res_id=area.connect_after ("resize", resize_cb, None)
	area.set_draw_func (draw_cont,None,None)
	#need landscape,there is a case when n<length when no surface, and points at reopen
	area.emit("resize",area.get_width(),area.get_height())

def resize_cb(a,w,h,d):
	drawscroll.set_landscape()
	global surface
	surface = a.get_native().get_surface().create_similar_surface(cairo.Content.COLOR,w,h)
	graph.surf(w,h)
	forms.redraw(w,h)

def paintland(cr,y,ratio,a,b):
	for i in range(a,b):
		j=i-offset
		cr.move_to(j,y)
		z=samples[i]
		r=ratio*z+y
		cr.line_to(j,r)
def paintport(cr,x,ratio,a,b):
	for i in range(a,b):
		j=i-offset
		cr.move_to(x,j)
		z=samples[i]
		c=ratio*z+x
		cr.line_to(c,j)
def sel(a,b):
	paint(a,b,sets.get_fgcolor())
def unsel(a,b):
	paint(a,b,sets.get_color())
def paint(a,b,clr):
	cr=cairo.Context(surface)
	cr.set_line_width(1)#this at start?nothing
	co=Gdk.RGBA()
	if co.parse(clr):
		cr.set_source_rgb(co.red,co.green,co.blue)
	if drawscroll.landscape:
		paintland(cr,hstore*baseline,hstore/sampsize,a,b)
	else:
		paintport(cr,wstore*baseline,wstore/sampsize,a,b)
	cr.stroke()

def reset():
	global ostore
	ostore=-1
