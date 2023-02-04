
import os
import pathlib
import json

from . import sets
from . import point
from . import graph
from . import play
from . import draw

points=[]

def insert(poi):
	ln=len(points)
	for ix in range(0,ln):
		p=points[ix]
		if poi._offset_<p._offset_:
			points.insert(ix,poi)
			if ix>0:
				if (points[ix-1]._inter_==False
					 and p._inter_==False):
					poi._inter_=True
			return ix
	points.append(poi)
	return ln
def move(p,o,ini,dels):
	ix=ini
	last=len(points)-1
	of=p._offset_
	forward=o<of
	if forward:
		while ix<last:
			o=points[ix+1]._offset_
			if o<of:
				if p._inter_:
					p._offset_=o
					dels.clear()
					return graph.take(ix,p)
				ix+=1
				continue
			break
	else:
		while ix>0:
			o=points[ix-1]._offset_
			if of<o:
				if p._inter_:
					p._offset_=o
					dels.clear()
					return graph.take(ix,p)
				ix-=1
				continue
			break
	if ini!=ix:
		return move_inter(forward,ini,ix,dels,p)
	if dels:
		dels.clear()
	return graph.take(ix,p)
def move_inter(forward,ini,ix,dels,p):
	indx=ini+1 if forward else ini-1
	pnt=points[indx]
	puts=None
	if pnt._inter_:
		gap=indx!=ix
		if forward:
			aux=points[indx+1]
			d=[dels[len(dels)-1][1],aux]
			if gap and ini>0:
				puts=[dels[0][0],aux]
			dels.clear()
			dels.append(d)
			if gap:
				move_inter_end(forward,ix,dels)
			ix-=1
		else:
			aux=points[indx-1]
			d=[aux,dels[0][0]]
			if gap and ini<len(points)-1:
				puts=[aux,dels[len(dels)-1][1]]
			dels.clear()
			dels.append(d)
			if gap:
				move_inter_end(forward,ix,dels)
			ini-=1
		pr=pnt.get_parent()
		if pr:
			pr.remove(pnt)
		pnt._remove_(indx)
	else:
		if ini>0 and ini<len(points)-1:
			puts=[dels[0][0],dels[1][1]]
		dels.clear()
		move_inter_end(forward,ix,dels)
	del points[ini]
	points.insert(ix,p)
	pts=graph.take(ix,p)
	if puts:
		pts.append(puts)
	return pts
def move_inter_end(forward,ix,dels):
	if forward:
		if ix==len(points)-1:
			return
		dels.append([points[ix],points[ix+1]])
	elif ix>0:
		dels.append([points[ix-1],points[ix]])
fpath_js='json'
def dpath(f_in):
	p=os.path.dirname(f_in)
	return os.path.join(p,'_'+sets.pkgname+'cache_')
def fpath(f_in,ext):
	return os.path.join(dpath(f_in),os.path.basename(f_in)+'.'+ext)
def fpath_full(d_in,f_in):
	return os.path.join(d_in,os.path.basename(f_in)+'.'+fpath_js)
def write(f_in):
	p=dpath(f_in)
	f_out=fpath_full(p,f_in)
	if len(points):
		pathlib.Path(p).mkdir(exist_ok=True)#parents=False, FileExistsError exceptions will be ignored
		with open(f_out,"w") as f:
			d=[]
			for po in points:
				d.append([po._offset_,po._height_,po._inter_,po._convex_])
			a=play.wavefile
			d=[d,(a.getsampwidth(),a.getnchannels(),a.getframerate(),draw.length)]
			json.dump(d,f)
			print(f_out)
	elif os.path.exists(f_out):
		os.remove(f_out)
def read(f_in):
	f_out=fpath(f_in,fpath_js)
	if os.path.exists(f_out):
		with open(f_out) as f:
			if data:=f.read():
				d=json.loads(data)
				for p in d[0]:
					add(p[0],p[1],p[2],p[3],len(points))
				return d[1]

def add(o,h,i,c,pos):
	po=point.struct()
	po._offset_=o
	po._height_=h
	po._inter_=i
	po._convex_=c
	points.insert(pos,po)
