
include "uconstres.s"

function root_file()
	sd lvs%levels_p
	set lvs lvs#v^
	set lvs lvs#
	sv fls%files_p
	set fls fls#
	add fls lvs
	return fls#
endfunction

function uconst_add(sd s,sd sz)
	sd f
	setcall f root_file()
	call uconst_spin(f,s,sz,(TRUE))
endfunction

#b
function uconst_spin(sd f,sd s,sd sz,sd is_new)
	sd const_cont
	set const_cont f
	sd found
	#search in includes declared in other logs
	add f (size_cont)
	setcall found uconst_search(f,s,sz,(FALSE))
	if found==(FALSE)
		#search in includes declared this log
		add f (size_cont)
		setcall found uconst_search(f,s,sz,is_new)
		if found==(FALSE)
			#search in constants declared in this file, with respect to is_new
			sd ofs
			setcall ofs pos_in_cont(const_cont,s,sz)
			if ofs!=-1
				add f (size_cont)
				if is_new==(FALSE)
					#if is in unused move it to doubleunused
					call uconst_unused(f,ofs)
				else
					call adddwordtocont(f,ofs)
				endelse
				return (TRUE)
			endif
		endif
	endif
	return (FALSE)
endfunction

#b
function uconst_search(sv fs,sd s,sd sz,sd is_new)
	sd cursor
	set cursor fs#
	add fs :
	set fs fs#d^
	add fs cursor
	sv fls%files_p
	set fls fls#
	while cursor!=fs
		sv pointer;set pointer fls
		add pointer cursor#
		sd found
		setcall found uconst_spin(pointer#,s,sz,is_new)
		if found==(TRUE)
			return (TRUE)
		endif
		add cursor (dword)
	endwhile
	return (FALSE)
endfunction

function uconst_unused(sv cont,sd ofs)
	sd uns
	set uns cont
	sd cursor
	set cursor cont#
	add cont :
	sd end
	set end cont#d^
	add end cursor
	add cont (dword)
	while cursor!=end
		sd offset
		set offset cursor#
		if offset<=ofs
			if offset==ofs
				#move to doubleunused
				call adddwordtocont(cont,offset)
				sub end (dword)
				sd pointer;set pointer cursor
				while cursor!=end
					add cursor (dword)
					set pointer# cursor#
					add pointer (dword)
				endwhile
				call ralloc(uns,(-dword))
				return (void)
			endif
			add cursor (dword)
		else
			return (void)
		endelse
	endwhile
endfunction
