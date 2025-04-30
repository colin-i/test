
import os
import readchar  # pip install readchar

fn="/home/bc/this.csv"
def parse():
	qr=os.environ.get('query_result')
	fname=qr.split(',')[0]

	global lines
	with open(fn) as f:
		text=f.read()
	lines = text.splitlines() #this is not getting the last blank line
	n=len(lines)
	for i in range(0,n):
		if lines[i].split(',')[0]==fname:
			print("updated")
			lines[i]=qr
			return
	print("1 top, 2 bottom, else alpha")
	c=readchar.readchar()
	print(c)
	if c=='1':
		lines.insert(0,qr)
	elif c=='2':
		lines.append(qr)
	else:
		lines.append(qr)
		lines.sort()
parse()
with open(fn,"w") as f:
	for r in lines:
		print(r,end='\n',file=f)
