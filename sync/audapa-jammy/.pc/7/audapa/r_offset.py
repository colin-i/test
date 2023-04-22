
from gi.repository import Gtk

from . import sets
from . import draw
from . import seloff
from . import drawscroll

class inttext(sets.colorLabel):
	def _get_(self):
		return int(self.get_text())
	def _set_(self,t):
		self._set_text_(str(t))

def init():
	global atleft,atright
	b=Gtk.Box(homogeneous=True)
	atleft=inttext("0")
	atleft.set_halign(Gtk.Align.START)
	atright=inttext("0")
	atright.set_halign(Gtk.Align.END)
	b.append(atleft)
	b.append(seloff.init())
	b.append(atright)
	return b

def cnged(a,visible):
	val=int(a.get_value())
	l=draw.offset+val
	atleft._set_text_(str(l))
	r=max(draw.length-visible-l,0)
	atright._set_text_(str(r))
def cged(a):
	cnged(a,int(a.get_page_size()))
def cgd(a,d):
	cged(a)
	if sets.turn_page.get_active():
		drawscroll.edge(a.get_value(),a.get_upper()-a.get_page_size())

def calculate(pos):
	#pos is is relative to draw
	pos+=draw.offset
	st=seloff.start._get_()
	en=seloff.end._get_()
	if st==0 and en==0:
		seloff.start._set_(pos)
		seloff.end._set_(pos)
		return
	n=abs(st-pos)
	m=abs(en-pos)
	if m<n or (m==n and en<pos):
		if en<pos:
			draw.sel(en,pos)
		else:
			draw.unsel(pos,en)
		seloff.end._set_(pos)
	else:
		if pos<st:
			draw.sel(pos,st)
		else:
			draw.unsel(st,pos)
		seloff.start._set_(pos)
	draw.area.queue_draw()
