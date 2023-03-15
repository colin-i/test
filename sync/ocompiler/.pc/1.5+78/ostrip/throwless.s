
function frees()
	valuex exefile#1
	const pexefile^exefile
	if exefile!=(NULL)
		call fclose(exefile)
	valuex exedata#1;valuex exedatasize#1
	valuex exetext#1;valuex exetextsize#1
	valuex exesym#section_nr_of_values
	valuex exestr#section_nr_of_values
	const pexedata^exedata;const pexedatasize^exedatasize
	const pexetext^exetext
	const pexesym^exesym
	const pexestr^exestr
	valuex execreladyn#1;valuex execreladynsize#1
	valuex execdynsym#1;valuex execdynsymsize#1
	valuex execdynstr#1;valuex execdynstrsize#1
		if exedata!=(NULL)
			call free(exedata)
			if exetext!=(NULL)
				call free(exetext)
				if exesym!=(NULL)
					call free(exesym)
					if exestr!=(NULL)
						call free(exestr)
					endif
				endif
			endif
		endif
		if execreladyn!=(NULL)
			call free(execreladyn)
		endif
		if execdynsym!=(NULL)
			call free(execdynsym)
			if execdynstr!=(NULL)
				call free(execdynstr)
			endif
		endif
		valuex objects#1
		const pobjects^objects
		if objects!=(NULL)
			call freeobjects(objects)
			call free(objects)
		endif
	endif
endfunction
function freeobjects(sv objects)
	while objects#!=(NULL)
		call freeobject(objects#)
		call free(objects#)
		add objects :
	endwhile
endfunction
function freeobject(sv object)
	sd end=object_alloc_secs
	add end object
	while object!=end
		if object#!=(NULL)
			call free(object#)
		else
			ret
		endelse
		add object (section_alloc)
	endwhile
endfunction

function verbose(sd action)
	datax a#1
	const ptrverbose^a
	data n=0     ;#only in one ocomp section
	if a==0
		if action==(verbose_count)
			inc n
		else
		#if action==(verbose_flush)
			chars out#10+1   ;#max 32
			call sprintf(#out,"%u",n)
			call Message(#out)
			set n 0
		endelse
	endif
endfunction

#file

#pos/-1
function shnames_find(ss mem,sd end,sd str)
	sd start;set start mem
	while mem!=end
		sd cmp;setcall cmp strcmp(mem,str)
		if cmp==0
			sub mem start
			return mem
		endif
		addcall mem strlen(mem)
		inc mem
	endwhile
	return -1
endfunction
function shnames_find_sec(sv sec,sd str)
	sd mem;set mem sec#
	incst sec
	sd end;set end mem
	add end sec#
	sd pos;setcall pos shnames_find(mem,end,str)
	return pos
endfunction

#obj

function objs_concat(sv objects,sv pdata,sd datainneroffset)
	sd initial;set initial pdata#
	add initial datainneroffset
	sd dest;set dest initial
	sd src;set src dest

	#skip first memtomem
	sv object=to_data_extra;add object objects#
	add dest object#d^
	add object (from_data_extra_to_data_extra_sz_a)
	add src object#
	incst objects

	while objects#!=(NULL)
		set object (to_data_extra);add object objects#
		sd stripped;set stripped object#d^
		#we implement own memcpy here because right to left can break all
		call memtomem(dest,src,stripped)
		add dest stripped
		add object (from_data_extra_to_data_extra_sz_a)
		add src object#
		incst objects
	endwhile

	incst pdata
	#exe data size can have last object aligned/unaligned this way (don't count on initial size)
	sub dest initial
	#rewrite size from extra+unstripped to stripped, to be used at rel and reldyn
	sd size;set size pdata#
	set pdata# dest

	sub size dest
	sub size datainneroffset
	sv out^stdout
	call fprintf(out#,"Stripped size: %llu bytes",size)
	call messagedelim(out)
endfunction

function memtomem(sv dest,sv src,sd size)
	#optimized?
	const stack_size_trail=:-1
	sd opt=~stack_size_trail
	and opt size
	sub size opt
	add opt dest
	while dest!=opt
		set dest# src#
		incst dest
		incst src
	endwhile
	add size dest
	while dest!=size
		set dest#s^ src#s^
		inc dest
		inc src
	endwhile
endfunction

function objs_align(sd sz)
#must import the align from ocomp
	const elf_sec_obj_align_trail=elf_sec_obj_align-1
	add sz (elf_sec_obj_align_trail)
	and sz (~elf_sec_obj_align_trail)
	return sz
endfunction

#realoffset-offset
function realoffset(sd add,sd sec_size)
	sv objs;set objs frees.objects
	sd data_size=0
	while objs#!=(NULL)
		sv obj;set obj objs#
		add obj add
		sv aligned;set aligned obj
		add aligned (from_extra_sz_to_extra_sz_a)
		set aligned aligned#
		add data_size aligned
		incst objs
	endwhile
	if aligned!=obj#
	#last object is not aligned
		sub aligned obj#
		sub data_size aligned
	endif
	sub data_size sec_size
	neg data_size
	return data_size
endfunction
