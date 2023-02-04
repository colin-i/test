
importx "get_current_dir_name" get_current_dir_name
importx "strlen" strlen

include "./mem.s"

function inits()
	value logf#1
	const logf_p^logf
	set logf (NULL)
	value logf_mem#1
	const logf_mem_p^logf_mem
	set logf_mem (NULL)
	value imp_mem#1;data *#1
	const imp_mem_p^imp_mem
	set imp_mem (NULL)
	value fn_mem#1;data *#1
	const fn_mem_p^fn_mem
	set fn_mem (NULL)
	value cwd#1;data *#1
	const cwd_p^cwd
	set cwd (NULL)
	value files#1;data files_d#1
	const files_p^files
	const files_dp^files_d
	set files (NULL)
	value levels#1;data levels_d#1
	const levels_p^levels
	const levels_dp^levels_d
	set levels (NULL)
	call uconst_resolved(0)
endfunction

function allocs()
	sv ip%imp_mem_p
	call alloc(ip)
	sv fp%fn_mem_p
	call alloc(fp)
	#
	sv cwd%cwd_p
	setcall cwd# get_current_dir_name()
	if cwd#==(NULL)
		call erExit("get_current_dir_name error")
	endif
	sd size=:
	add size cwd
	sd sz
	setcall sz strlen(cwd#)
	inc sz
	set size# sz
	call ralloc(cwd,(dword))
	set cwd cwd#
	add cwd sz
	set cwd#d^ sz
	#sv cursor=dword;add cursor cwd;setcall cursor# get_current_dir_name();if cursor#==(NULL);call erExit("get_current_dir_name error");endif;sd size;setcall size strlen(cursor#);inc size;set cwd#d^ size;call ralloc(cwd,(dword));set cursor cursor#;add cursor size;set cursor#d^ size
	sv fls%files_p
	call alloc(fls)
	sv lvs%levels_p
	call alloc(lvs)
endfunction

function freeall()
	sv ip%imp_mem_p
	if ip#!=(NULL)
		call free(ip#)
		sv fp%fn_mem_p
		if fp#!=(NULL)
			call free(fp#)
			sv cwd%cwd_p
			if cwd#!=(NULL)
				call free(cwd#)
				sv fls%files_p
				if fls#!=(NULL)
					call freefiles()
					sv lvs%levels_p
					if lvs#!=(NULL)
						call free(lvs#)
						call logclose()
					endif
				endif
			endif
		endif
	endif
endfunction

function logclose()
	sv fp%logf_p
	if fp#!=(NULL)
		call fclose(fp#)
		set fp# (NULL)
		sv p%logf_mem_p
		if p#!=(NULL)
			call free(p#)
			set p# (NULL)
		endif
	endif
endfunction

function freefiles()
	#sv container%files_p;sv cursor;set cursor container#d^;add container (dword);set container container#;add cursor container;while container!=cursor;decst cursor;sv consts=dword;add consts cursor#;call free(consts#);call free(cursor#);endwhile;call free(cursor)
	sv container%files_p
	sv start
	set start container#
	add container :
	set container container#d^
	add container start
	while start!=container
		decst container
		call fileentry_uninit(container#)
		call free(container#)
	endwhile
	call free(container)
endfunction
