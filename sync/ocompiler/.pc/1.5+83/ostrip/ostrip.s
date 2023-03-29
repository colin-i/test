
#must do a stripped .data and resolved .text (and .symtab with offset (more at leaf.py))

#input: exec log1 o1 ... logN oN

format elfobj64
#modify debian/control exec depends,appimage.yml,debian/control arh order

#at exec
#there is a rare case with rela.dyn but it is not important here (resolved stderr to object)
#these are not position independent code and inplace relocs add better with obj64 but at obj32 use addend>=0 or sum<0 error check

#both exec and shared:
#	pointers to dataind at text/data
#	aftercall has a copy at .symtab
#	.rela.dyn:
#		data section offsets (R_X86_64_64:^printf)

#only exec:
#	pointers to aftercall

#only at shared and pie:
#	.rela.dyn:
#		addends from pointers to data section (this and the previous are saying the same thing but maybe is compatibility)
#		data section offsets (R_X86_64_RELATIVE pointers to text/data sections)
#iterate by type,compare offset if is in data or in text,will have 3 go ways from there(at text the offset is ok)(at .._64 no addend)(at data both offset and addend)

#only at shared:
#	aftercall value at .dynsym

#pin about .data align at objects that ld respects when concatenating
#aftercall is retrieved in .symtab in an entry with Type=NOTYPE and Ndx=dataind, then .strtab for name, then in another objects an import with that name
#at exec instead of .strtab can be value is inside data(there are outside data values as well), but that's extra code
#aftercall can be resolved not from the first iteration

include "header.h"

include "throwless.s"
include "rel.s"

function messagedelim(sv st)
	Char visiblemessage={0x0a,0}
	Call fprintf(st#,#visiblemessage)
endfunction
Function Message(ss text)
	sv st^stdout
	Call fprintf(st#,text)
	call messagedelim(st)
EndFunction
Function eMessage(ss text)
	sv st^stderr
	Call fprintf(st#,text)
	call messagedelim(st)
EndFunction
function erEnd()
	call frees()
	aftercall er
	set er ~0
	return (EXIT_FAILURE)
endfunction
function erMessage(ss text)
	call eMessage(text)
	call erEnd()
endfunction
function erMessages(ss m1,ss m2)
	call eMessage(m1)
	call eMessage(m2)
	call erEnd()
endfunction

char s1=".data";char s2=".text";char s3=".symtab";char s3o=".symtab_offset";char s4=".strtab"

include "file.s"
include "obj.s"
include "after.s"
include "reldyn.s"

entry main(sd argc,sv argv) #0,ss exec,ss log1,ss *obj1)   #... logN objN

if argc>=(1+3)  #0 is all the time
	sd verb%%ptrverbose
	setcall verb# access(".debug",(F_OK))

	sv pfile%%pexefile
	const s1c^s1;const s2c^s2;const s3c^s3;const s4c^s4
	value sN%{s1c,s2c}
	value s3c%s3c
	value s4c%s4c
	value *=NULL
	sv pexe%%pexedata
	datax nrs#2   #this is required inside but is better than passing the number of sections
	datax symtabnr#1
	datax *#1

	#text/data can go null later, with access error if rela points there, but to not set here null is probably same access error
	#sv pt%%pexetext
	#set pt# (NULL)
	sv ps%%pexesym
	set ps# (NULL)
	#and set data null here, it is useless there for objects call
	set pexe# (NULL)   #data
	set frees.execreladyn (NULL)
	set frees.execdynsym (NULL)
	set frees.execdynstr (NULL)

	sv pobjects%%pobjects
	set pobjects# (NULL) #this is on the main plan, is after ss exec at frees

	mult argc :
	add argc argv

	incst argv
	#,(ET_EXEC)
	sd datavaddr;setcall datavaddr get_file(argv#,pfile,#sN,pexe,#nrs,(NULL),#symtabnr)

	incst argv
	call get_objs(argv,argc) #aftercall can be in any object, need to keep memory

	#at pie(and everywhere like a good practice), there is a starting offset in data
	#	need to get our size then sub from full data size and use that instead of data virtual
	sd datainneroffset;setcall datainneroffset realoffset((to_data_extra_sz),frees.exedatasize)
	#and same for text
	sd textinneroffset;setcall textinneroffset realoffset((to_text_extra),frees.exetextsize)

	sd keepdatasize;set keepdatasize frees.exedatasize
	call objs_concat(pobjects#,pexe,datainneroffset)

	if frees.execreladyn!=(NULL)  #or set size 0
		sd maximum;set maximum datavaddr
		add maximum keepdatasize
		add datavaddr datainneroffset
		call reloc_dyn(datavaddr,maximum)
	else
		add datavaddr datainneroffset
	endelse

	call reloc(pobjects#,datavaddr,datainneroffset,textinneroffset)

	sd acall;setcall acall aftercall_find(pobjects#,#datavaddr) #acall is the string and datavaddr new aftercall virtual
	if acall!=(NULL)
		if ps#!=(NULL)
			#replace if exe symtab
			sv pexestr%%pexestr
			call aftercall_replace(ps,pexestr,acall,datavaddr)

			set s4c (NULL)  #for write skip
		else
			#the symbols have been stripped (-s)
			set s3c (NULL)
		endelse

		#replace on the field
		call aftercall_in_objects(pobjects#,acall,datavaddr,textinneroffset)

		#replace in dynsym (can be at shared, mainly)
		if frees.execdynsym!=(NULL)
			sd bool;setcall bool aftercall_replace(#frees.execdynsym,#frees.execdynstr,acall,datavaddr)
			#it is not in all cases here (even at shared)
			if bool==(TRUE)
				call write_sec(".dynsym",frees.execdynsym,frees.execdynsymsize)
			endif
		endif
	else
		#skip symtab if no aftercall
		set s3c (NULL)  #write will stop there
	endelse

	add frees.exedatasize datainneroffset    #set leading size back for write
	call write(#sN,pexe)
	call write_sec(".rela.dyn",frees.execreladyn,frees.execreladynsize)

	call frees()
	return (EXIT_SUCCESS)
endif
return (EXIT_FAILURE)
