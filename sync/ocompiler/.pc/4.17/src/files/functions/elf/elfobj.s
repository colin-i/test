

#err
function elfobj_resolve(sd p_localsyms,sd cont,sd end,sd entsize,sd datacont,sd datasize,sd textcont,sd textsize,sd relsize)
	add end cont
	#
	sd st_info_offset
	sd info_symbolindex_offset
	sd info_symbolindex_size
	if entsize==(elf64_dyn_d_val_syment)
		set st_info_offset (elf64_sym_st_info_offset)
		set info_symbolindex_offset (elf64_r_info_symbolindex_offset)
		set info_symbolindex_size (elf64_r_info_symbolindex_size)
	else
		set st_info_offset (elf32_sym_st_info_offset)
		set info_symbolindex_offset (elf_r_info_symbolindex_offset)
		set info_symbolindex_size (elf_r_info_symbolindex_size)
	endelse
	#iterate left right stop on global
	sd first_global
	setcall first_global elfobj_resolve_lr(cont,end,entsize,st_info_offset)
	#iterate right left stop on local
	sd last_local_margin
	setcall last_local_margin elfobj_resolve_rl(cont,end,entsize,st_info_offset)
	#in case there are no globals
	set p_localsyms# first_global
	sub p_localsyms# cont
	div p_localsyms# entsize
	#
	if first_global!=last_local_margin
		sd alloc
		sd localindex
		set localindex p_localsyms#
		#count local/global
		setcall p_localsyms# elfobj_resolve_count(first_global,last_local_margin,entsize,st_info_offset,localindex,#alloc)
		#alloc global aux
		sd sz
		set sz entsize
		mult sz alloc
		sd err
		setcall err memoryalloc(sz,#alloc)
		if err==(noerror)
			#alloc new rellocs for modifs
			sd reldata;sd reltext
			setcall err memoryalloc(datasize,#reldata)
			if err==(noerror)
				setcall err memoryalloc(textsize,#reltext)
				if err==(noerror)
					call memtomem(reldata,datacont,datasize)
					call memtomem(reltext,textcont,textsize)
					#iterate inside
					sd pos
					sd localpos
					set pos alloc
					set localpos first_global
					sd globalindex
					sd index
					set globalindex p_localsyms#
					set index localindex
					#
					sd dataend
					set dataend datasize
					add dataend datacont
					sd textend
					set textend textsize
					add textend textcont
					while first_global!=last_local_margin
						sd comp
						setcall comp elfobj_resolve_stbcomp(first_global,st_info_offset,(STB_GLOBAL))
						if comp==(TRUE)
							#if global put on aux
							call memtomem(pos,first_global,entsize)
							add pos entsize
							#with the entry, modify index in rel data/text
							call elffobj_resolve_relmodif(index,globalindex,datacont,dataend,textcont,textend,relsize,info_symbolindex_offset,info_symbolindex_size,reldata,reltext)
							inc globalindex
						else
							#if local put on position
							call memtomem(localpos,first_global,entsize)
							add localpos entsize
							#
							call elffobj_resolve_relmodif(index,localindex,datacont,dataend,textcont,textend,relsize,info_symbolindex_offset,info_symbolindex_size,reldata,reltext)
							inc localindex
						endelse
						add first_global entsize
						inc index
					endwhile
					#at end, put globals
					call memtomem(localpos,alloc,sz)
					call memtomem(datacont,reldata,datasize)
					call memtomem(textcont,reltext,textsize)
					call free(reltext)
				endif
				call free(reldata)
			endif
			call free(alloc)
		endif
		return err
	endif
	return (noerror)
endfunction

function elfobj_resolve_lr(sd cont,sd end,sd entsize,sd st_info_offset)
	while cont!=end
		#compare st_info
		sd comp
		setcall comp elfobj_resolve_stbcomp(cont,st_info_offset,(STB_GLOBAL))
		if comp==(TRUE)
			set end cont
		else
			add cont entsize
		endelse
	endwhile
	return cont
endfunction

function elfobj_resolve_rl(sd cont,sd end,sd entsize,sd st_info_offset)
	while cont!=end
		sub end entsize
		#compare st_info
		sd comp
		setcall comp elfobj_resolve_stbcomp(end,st_info_offset,(STB_LOCAL))
		if comp==(TRUE)
			add end entsize
			set cont end
		endif
	endwhile
	return end
endfunction

function elfobj_resolve_stbcomp(ss ent,sd offset,sd against)
	add ent offset
	set ent ent#
	div ent (elf_sym_st_info_tohibyte)
	if ent==against
		return (TRUE)
	endif
	return (FALSE)
endfunction

#n
function elfobj_resolve_count(sd a,sd b,sd sz,sd of,sd locals,sd p_alloc)
	add a sz #a is first global
	sd g=1
	while a!=b
		sd comp
		setcall comp elfobj_resolve_stbcomp(a,of,(STB_LOCAL))
		if comp==(TRUE)
			inc locals
		else
			inc g
		endelse
		add a sz
	endwhile
	set p_alloc# g
	return locals
endfunction

function elffobj_resolve_relmodif(sd oldindex,sd newindex,sd datacont,sd dataend,sd textcont,sd textend,sd relsize,sd offset,sd infsize,sd reldata,sd reltext)
	call elfobj_resolve_relmodif_section(oldindex,newindex,datacont,dataend,relsize,offset,infsize,reldata)
	call elfobj_resolve_relmodif_section(oldindex,newindex,textcont,textend,relsize,offset,infsize,reltext)
endfunction
function elfobj_resolve_relmodif_section(sd oldindex,sd newindex,sd cont,sd end,sd size,sd offset,sd infsize,sd newcont)
	sd start
	set start cont
	while cont!=end
		sd a
		set a cont
		add a offset
		sd c
		setcall c memcmp(a,#oldindex,infsize)
		if c==0
			sub a start
			add a newcont
			call memtomem(a,#newindex,infsize)
		endif
		add cont size
	endwhile
endfunction
