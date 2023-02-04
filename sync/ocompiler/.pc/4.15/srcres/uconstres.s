
function uconst_miniresolve()
	sd f
	setcall f root_file()
	#spin through old declared
	call uconstres_spin(f,(TRUE))
endfunction

function uconstres_spin(sd f,sd is_new)
	sd cont
	set cont f
	add f (size_cont)
	call uconstres_search(f,(FALSE))
	add f (size_cont)
	call uconstres_search(f,is_new)
	#
	if is_new==(FALSE)
		#resolve doubleunuseds
		add f (size_cont)
		sd double
		set double f
		add double (size_cont+:)
		if double#!=0
			sub double :
			value aux#1;data *#1
			call memcpy(#aux,f,(size_cont))
			call memcpy(f,double,(size_cont))
			call memcpy(double,#aux,(size_cont))
			set f double
		endif
		add f :
		sd size
		set size f#
		if size!=0
			sub f :
			call uconst_resolved(1,f#v^,size)
			neg size
			call ralloc(f,size)
		endif
	endif
endfunction

function uconstres_search(sv f,sd is_new)
	sd cursor
	set cursor f#
	add f :
	set f f#d^
	add f cursor
	sv fls%files_p
	set fls fls#
	while cursor!=f
		sv pointer;set pointer fls
		add pointer cursor#
		call uconstres_spin(pointer#,is_new)
		add cursor (dword)
	endwhile
endfunction

function uconst_resolve(ss const_str)
	sv fls%files_p
	sv cursor
	set cursor fls#
	add fls :
	set fls fls#d^
	add fls cursor
	while cursor!=fls
		sd pointer=3*size_cont+:
		add pointer cursor#
		if pointer#!=0
			sub pointer :
			set pointer pointer#v^
			set cursor cursor#
			set cursor cursor#
			add cursor pointer#
			sd offset
			set offset cursor#d^
			add cursor (dword)
			call wrongExit(const_str,cursor,offset)
		endif
		add cursor :
	endwhile
endfunction

function uconst_resolved(sd t,sd mem,sd size)
	data nr#1
	if t==0
		set nr 0
	elseif t==1
		add size mem
		while mem!=size
			add mem mem#
			add mem (dword)
			inc nr
		endwhile
	else
		return nr
	endelse
endfunction
