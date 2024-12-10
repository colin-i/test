
import os

root=os.environ["HOME"]+"/measures/"
with open(root+"recs_new","rb") as file:
	recs=eval(file.read())
	for r in recs:
		print(r)
