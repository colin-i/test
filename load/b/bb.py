
import os
import sys

from .b import bcolors
from .b import outlineend2
from .b import outlineend3
from .b import colortext

outfile=sys.modules['__main__'].outfile
leftlim=sys.modules['__main__'].leftlim
rightlim=sys.modules['__main__'].rightlim
centersize=rightlim-leftlim
rightsize=(sys.modules['__main__'].procthreads*100)-rightlim

outfile.write("<head><style>\
	.green{background-color:green;display:inline-block}\
	.yellow{background-color:yellow;display:inline-block}\
	.red{background-color:red;display:inline-block}\
	.chgreen{color:green}\
	.chyellow{color:yellow}\
	.chred{color:red}\
</style></head>\n")

def write2(z,c,a):
	#from .b import outfile #cannot import name 'outfile' from 'b.b'
	outfile.write("<div style=\"width:"+str(z)+"%\" class=\""+c+"\">"+a+"</div>")
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
	x=round(os.get_terminal_size().columns*a)
	y=round(100*a)
	d=f"{bcolors.end}"

	s=str(val);print(b+s+d,end='')
	x-=len(s)
	if(x>0):
		print(b+form(x)+d,end='')
	if started:
		if y>0:
			write2(y,c,s)
		else:
			outfile.write(colortext(c,s))
	outlineend3(outfile,started)
