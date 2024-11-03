
import os
import sys

if len(sys.argv)>1:
	type=sys.argv[1]
else:
	type=""

root=os.environ["HOME"]+"/measures/"
with open(root+"recs"+type,"rb") as file:
	recs=eval(file.read())
with open(root+"text"+type,"w") as out:
	for r in recs:
		with open(root+"current"+type+"/"+r[2],"rb") as f:
			b=""
			if os.environ.get("has_new"): b=" "+r[2]
			print(f.read().decode()+b,file=out)
