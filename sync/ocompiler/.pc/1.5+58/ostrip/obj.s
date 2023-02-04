
const object_nr_of_main_sections=2
const object_nr_of_secondary_sections=2
const object_nr_of_sections=object_nr_of_main_sections+object_nr_of_secondary_sections
const section_alloc=:*section_nr_of_values
const object_alloc_secs=object_nr_of_sections*section_alloc
const to_text_extra=object_alloc_secs+datasize+:
const object_alloc=to_text_extra+:
#const to_text=section_alloc
const to_symtab=object_nr_of_main_sections*section_alloc
const to_strtab=to_symtab+section_alloc
const from_symsize_to_voffset=:+section_alloc
const from_strtab_to_symtab=section_alloc
const from_symtab_to_text=section_alloc
const from_text_to_extra=section_alloc+(object_nr_of_secondary_sections*section_alloc)

##stripped size
function get_objs(sv pargs,sd end)
	#find the number of objects to prepare the field
	sd pointers;set pointers end
	sub pointers pargs
	div pointers 2
	add pointers :  #for null end

	#make a container
	sv pobjects%pobjects
	setcall pobjects# alloc(pointers)

	#set end
	sv objects;set objects pobjects#
	set objects# (NULL)

	while pargs!=end
		#alloc
		setcall objects# alloc((object_alloc))

		sv object;set object objects#
		set object# (NULL)  #this is not like the first file, there is 1 more like this extra in get_file
		add objects :
		set objects# (NULL)

		chars o1=".rela.data";chars o2=".rela.text";chars o3=".symtab";chars o4=".strtab"
		const o1c^o1;const o2c^o2;const o3c^o3;const o4c^o4
		value oN%{o1c,o2c,o3c,o4c}
		value *=NULL
		datax nrs#object_nr_of_sections   #same as previous call
		#blank sections at ocomp?

		sv p=object_alloc_secs
		add p object

		setcall p#d^ get_offset(pargs#)  #the ocomp with these sections from that creation time are still respected (32 bits)

		add p (datasize)
		incst pargs

		sd file
		sv t=:
		add t p
		setcall p# get_file(pargs#,#file,(ET_REL),#oN,object,#nrs,t)
		call fclose(file)
		setcall t# objs_align(t#)  #will be in two places used (same value)
		incst pargs
	endwhile
endfunction

#stripped size
function get_offset(sd fname)
	sd file;setcall file fopen(fname,"rb")
	if file!=(NULL)
		#at the first 3 documentations there is no info about errno errors for fseek ftell
		#it is implementation specific, many judgements can be made
		call seek(file,0,(SEEK_END))
		sd off;setcall off ftell(file)
		if off!=-1
			sub off (2+8)  #knowing \r\n same as ounused that is not headering with src. and 8 is copy-paste
			call seeks(file,off)
			chars buf={0,0,0,0, 0,0,0,0, 0}
			call read(file,#buf,8) #copy-paste
			datax nr#1
			call sscanf(#buf,"%08x",#nr) #copy-paste
			return nr
		endif
		call erMessages("ftell error at",fname)
	endif
	call fError(fname)
endfunction

function write(sv names,sv psections)
	while names#!=(NULL)
		sd sec;set sec psections#
		add psections :
		sd size;set size psections#
		add psections :
		if sec!=(NULL)   #is ok only to execute the prog with no data or text
			sd file;setcall file fopen(names#,"wb")
			if file!=(NULL)
				call writeclose(file,sec,size)
			else
				call fError(names#)
			endelse
		endif
		incst names
	endwhile
endfunction
function writeclose(sd file,sd buf,sd size)
	sd written;setcall written fwrite(buf,1,size,file)
	call fclose(file)
	#pin that written=size*1
	if written!=size
		call erMessages("fwrite error")
	endif
endfunction
function write_symtab_offset(sd file,sd offset,sd end,sd shentsize,sd pnr)
	datax nr#1;set nr pnr#
	if nr!=-1
		call seeks(file,offset)
		sd rest=-datasize
		add rest shentsize
		while offset!=end
			#the sh64_name is first
			datax offs#1;call read(file,#offs,(datasize))
			if offs==nr
				sd off=sh64_addr_to_offset
				call get_section_loc(file,offset,#off)
				sd fout;setcall fout fopen(#main.s3o,"wb")
				if fout!=(NULL)
					call writeclose(fout,#off,:)
					ret
				endif
				call fError(#main.s3o)
			endif
			call seekc(file,rest)
			add offset shentsize
		endwhile
	endif
endfunction
