
import os
import sys
import readchar

if len(sys.argv)>1:
	type=sys.argv[1]
	extra_because_blank_is_bash_null="E"
else:
	type=""
	extra_because_blank_is_bash_null=""

root=os.environ["HOME"]+"/measures/"
with open(root+"recs"+type,"rb") as file:
	recs=eval(file.read())
with open(root+"text"+type,"w") as out:
	i=0
	for r in recs:
		fnm=root+"current"+type+"/"+r[2]
		with open(fnm,"rb") as f:
			rd=f.read().decode()
			if len(rd)==0:
				with open(root+"text_last"+type,"r") as prev:
					prevtext=prev.read().split("\n")[i]
					prevtext=prevtext[1:]
					print(fnm+" is blank, use '"+prevtext+"' ? y?")
					char=readchar.readchar()
					if char=='y':
						print("yes")
						rd=prevtext
					else:
						print("no")
						exit(1)
			b=""
			if os.environ.get("has_new"): b=" "+r[2]
			print(extra_because_blank_is_bash_null+rd+b,file=out)
			i=i+1
