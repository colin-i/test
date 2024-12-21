
import os
import sys

if len(sys.argv)>1:
	z=sys.argv[1]
else:
	z=""
root=os.environ["HOME"]+"/measures/"
with open(root+"recs"+z,"rb") as file:
	recs=eval(file.read())
	for r in recs:
		print(r)
