
import os

qr=os.environ.get('query_result')
fname=qr.split(',')[0]
fn="/home/bc/this.csv"
with open(fn) as f:
	text=f.read()
	lines = text.splitlines()
	n=len(lines)-1
	for i in range(0,n):
		if lines[i].split(',')[0]==fname:
			print("updated")
			lines[i]=qr
			break
with open(fn,"w") as f:
	for r in lines:
		print(r,end='\n',file=f)
