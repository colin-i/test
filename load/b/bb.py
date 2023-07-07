
import os
import sys
import math

from .b import bcolors
from .b import outlineend2

outfile=sys.modules['__main__'].outfile
leftlim=sys.modules['__main__'].leftlim
rightlim=sys.modules['__main__'].rightlim
centersize=rightlim-leftlim
rightsize=(sys.modules['__main__'].procthreads*100)-rightlim

def write2(z,c,a):
	#from .b import outfile #cannot import name 'outfile' from 'b.b'
	outfile.write("<div style=\"width:"+str(z)+"%;background-color:"+c+";display:inline-block\">"+a+"</div>")
def write(z,c):
	write2(z,c,"&nbsp;")

def shares(i,l,c,r,columns):
	x=l*columns
	y=c*columns
	z=r*columns
	solids=[int(x/i),int(y/i),int(z/i)]
	rests=[(x%i,0),(y%i,1),(z%i,2)]
	columnstobeshared=int((rests[0][0]+rests[1][0]+rests[2][0])/i)  #while 0.0 is not ok
	rests.sort(reverse=True)

	while columnstobeshared:
		rest,col=rests[0]
		rests.pop(0)
		solids[col]+=1
		columnstobeshared-=1
	return solids

def form(n):
	s=''
	while n:
		s+=' '
		n-=1
	return s
def zoneline(i,l,c,r):
	term=shares(i,l,c,r,os.get_terminal_size().columns)
	file=shares(i,l,c,r,100)
	if term[0]:
		print(f"{bcolors.green}"+form(term[0])+f"{bcolors.end}",end='')
		write(file[0],"green")
	if term[1]:
		print(f"{bcolors.yellow}"+form(term[1])+f"{bcolors.end}",end='')
		write(file[1],"yellow")
	if term[2]:
		print(f"{bcolors.red}"+form(term[2])+f"{bcolors.end}",end='')
		write(file[2],"red")
	outlineend2(outfile)

def valueline(val,started):
	columns=os.get_terminal_size().columns
	if val<leftlim:
		a=val/leftlim
		b=f"{bcolors.green}"
		c="green"
	elif val<rightlim:
		a=(val-leftlim)/centersize
		b=f"{bcolors.yellow}"
		c="yellow"
	else:
		a=(val-rightlim)/rightsize
		b=f"{bcolors.red}"
		c="red"
	x=math.ceil(columns*a)
	y=math.ceil(100*a)
	d=f"{bcolors.end}"

	s=str(val);print(b+s+d,end='')
	x-=len(s)
	if(x>0):
		print(b+form(x)+d,end='')
	outlineend2(outfile)
	if started:
		write2(y,c,s)
