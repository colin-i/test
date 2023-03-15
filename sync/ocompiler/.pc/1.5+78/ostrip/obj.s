
#data extra align at realoffset,concat,reldyn then unaligned at reloc,reldyn
#text extra aligned

const object_nr_of_main_sections=2
const object_nr_of_secondary_sections=2
const object_nr_of_sections=object_nr_of_main_sections+object_nr_of_secondary_sections
const section_alloc=:*section_nr_of_values
const object_alloc_secs=object_nr_of_sections*section_alloc

#const to_text=section_alloc
const to_symtab=object_nr_of_main_sections*section_alloc
const to_strtab=to_symtab+section_alloc
const from_symsize_to_voffset=:+section_alloc
const from_strtab_to_symtab=section_alloc
const from_symtab_to_text=section_alloc
const from_text_to_data_extra=section_alloc+(object_nr_of_secondary_sections*section_alloc)

const to_data_extra=object_alloc_secs
const from_data_extra_to_data_extra_sz=datasize
const from_extra_sz_to_extra_sz_a=:
const from_data_extra_to_data_extra_sz_a=from_data_extra_to_data_extra_sz+from_extra_sz_to_extra_sz_a
const to_data_extra_sz=object_alloc_secs+from_data_extra_to_data_extra_sz
const extra_sz=from_extra_sz_to_extra_sz_a+:
const to_text_extra=to_data_extra_sz+extra_sz
const to_text_extra_a=to_text_extra+from_extra_sz_to_extra_sz_a
const object_alloc=to_text_extra+extra_sz

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

		sv p=to_data_extra
		add p object

		setcall p#d^ get_offset(pargs#)  #the ocomp with these sections from that creation time are still respected (32 bits)

		add p (from_data_extra_to_data_extra_sz)
		incst pargs

		sd file
		sv t=extra_sz
		add t p
		#,(ET_REL)
		setcall p# get_file(pargs#,#file,#oN,object,#nrs,t)
		call fclose(file)
		sv d_unaligned;set d_unaligned p
		add p (from_extra_sz_to_extra_sz_a)
		setcall p# objs_align(d_unaligned#)
		sv t_unaligned;set t_unaligned t
		add t (from_extra_sz_to_extra_sz_a)
		setcall t# objs_align(t_unaligned#)
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

function write_sec(ss name,sd sec,sd size)
	if sec!=(NULL)   #is ok only to execute the prog with no data or text, and for reldyn
		sd file;setcall file fopen(name,"wb")
		if file!=(NULL)
			call writeclose(file,sec,size)
		else
			call fError(name)
		endelse
	endif
endfunction
function write(sv names,sv psections)
	while names#!=(NULL)
		sd sec;set sec psections#
		add psections :
		sd size;set size psections#
		add psections :
		call write_sec(names#,sec,size)
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
