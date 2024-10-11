
import os

root=os.environ["HOME"]+"/measures/"
with open(root+"recs","rb") as file:
	recs=eval(file.read())
with open(root+"text","w") as out:
	for r in recs:
		with open(root+"current/"+r[2],"rb") as f:
			print(f.read().decode(),file=out)
