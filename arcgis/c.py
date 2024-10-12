
import os

root=os.environ["HOME"]+"/measures/"
with open(root+"recs","rb") as file:
	recs=eval(file.read())
with open(root+"text","w") as out:
	for r in recs:
		with open(root+"current/"+r[2],"rb") as f:
			b=""
			if os.environ.get("has_new"): b=" "+r[2]
			print(f.read().decode()+b,file=out)
