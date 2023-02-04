

#wget in Makefile maybe

import subprocess
import sys

inputfile=sys.argv[1]
outputfile=sys.argv[2]

txt=subprocess.check_output(['/bin/bash','-c',"printf '%s' $(objdump -h "+inputfile+" | grep ' .data ' | tr -s ' ' | cut -d ' ' -f 4)"])
unstripped_size=int(txt,base=16)
#fn="temp"
#with open(fn,'rb') as f:
#	unstripped_size=int(f.read(),base=16)

#this is not better than objcopy file --update-section .data=data.bin
#data.content=bytearray(b"text")
#ld...-Tdata to put data at trail

import shutil

if inputfile!=outputfile:
	shutil.copyfile(inputfile,outputfile)
#after objcopy symtab changes offset -> .symtab_offset before objcopy

import os

s1=".data"
s2=".text"
s3=".symtab"
if (os.path.exists(s3)):
	#objcopy is not updating symtab
	with open(s3+"_offset",'rb') as f:
		value=f.read()
		x=len(value)
		y=b""
		#need to reverse to big
		for a in range(x,0,-1):
			y+=(value[a-1]).to_bytes(1,'big')
		value=y.hex()
		offset=int(value,base=16)
		with open(outputfile,'r+b') as f:
			f.seek(offset)
			with open(s3,'rb') as s:
				f.write(s.read())
s4=".rela.dyn"
if (os.path.exists(s4)):
	proc=subprocess.run(["objcopy",outputfile,"--update-section",s1+"="+s1,"--update-section",s2+"="+s2,"--update-section",s4+"="+s4])
else:
	proc=subprocess.run(["objcopy",outputfile,"--update-section",s1+"="+s1,"--update-section",s2+"="+s2])

if proc.returncode==0:
	import lief
	#
	elffile = lief.parse(outputfile)
	s=elffile.get_section(s1)
	h=elffile.segments
	#
	found=-1
	dif=0
	#
	for x in h:
		a=x.sections
		n=len(a)
		for i in range(0,n):
			b=a[i]
			if found==-1:
				if b.name==s1:
					#only with .bss: it looks like objcopy is shrinking file size accordingly and is not touching on mem size in section and segment
					#so this file was about to go
					#but when it's at the edge is shrinking mem size
					#then x.virtual_size+= is a must and a[i].virtual_address+= stays like a guardian
					found=i+1
					if (b.virtual_address+unstripped_size)<=(x.virtual_address+x.virtual_size):
						break
					size=b.size
					dif=unstripped_size-size
			else:
				#see about alignments
				#The value of sh_addr must be congruent to 0, modulo the value of sh_addralign
				#	i think that means   if align is 8 addr can start at 0h/8h only
				test=b.virtual_address+dif
				bittest=test&(b.alignment-1)
				if bittest!=0:
					dif+=b.alignment-bittest
		if found!=-1:
			if dif!=0:
				#must first increase segment size if not want to lose the section
				x.virtual_size+=dif
				for i in range(found,n):
					a[i].virtual_address+=dif
					#this is not tested at stdout/stderr that goes into .bss that is after .data
				elffile.write(outputfile)
				print("virtual_address modifications")
			else:
				print("virtual_address modifications were not required")
			st = os.stat(outputfile)
			import stat
			os.chmod(outputfile, st.st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)
			#
			#point that this script is not checking the existent virtual trail of .data
			#remove(fn)
			#
			exit(0)
exit(-1)
