
import os
import sys

from .b import bcolors
from .b import outlineend2

outfile=sys.modules['__main__'].outfile

def write(z,c):
	#from .b import outfile #cannot import name 'outfile' from 'b.b'
	outfile.write("<div style=\"width:"+str(z)+"%;background-color:"+c+";display:inline-block\">&nbsp;</div>")

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
