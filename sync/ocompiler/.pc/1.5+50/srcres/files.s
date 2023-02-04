
const FALSE=0
const TRUE=1

importx "realpath" realpath

#const size_cont=dword+:
const size_cont=:+dword
const size_conts=5*size_cont

function fileentry_add(sd full,sd len)
	sd er
	sd size=size_conts+dword
	sd ent
	add size len
	setcall er malloc_throwless(#ent,size)
	if er==(NULL)
		sd init
		set init ent
		#
		setcall er fileentry_init(ent)
		if er==(NULL)
			add ent (size_conts)
			set ent# len
			add ent (dword)
			call memcpy(ent,full,len)
			#
			sv fls%files_p
			sd previous_file
			setcall previous_file incrementfiles()
			setcall er ralloc_throwless(fls,:)
			if er==(NULL)
				sd offset=-:
				sd mem%files_dp
				add offset mem#
				set fls fls#
				add fls offset
				#sd mem;set mem fls#d^;call incrementfiles();setcall er ralloc_throwless(fls,:);if er==(NULL);sv cursor;add fls (dword);set cursor fls#;add cursor mem
				set fls# init
				if previous_file!=(NULL)
					add previous_file (2*size_cont)
					call adddwordtocont(previous_file,offset)
				endif
				return (void)
			endif
			call fileentry_uninit(init)
			call free(init)
			call free(full)
			call erExit(er)
		endif
		call free(init)
		call free(full)
		call erExit(er)
	endif
	call free(full)
	call erExit(er)
endfunction

#er
function fileentry_init(sd cont)
	sd a;set a cont
	sd b;set b cont;add b (size_conts)
	while cont!=b
		sd er
		setcall er alloc_throwless(cont)
		if er!=(NULL)
			call fileentry_uninit_base(a,cont)
			return er
		endif
		add cont (size_cont)
	endwhile
	return (NULL)
endfunction
function fileentry_uninit(sd cont)
	sd b;set b cont;add b (size_conts)
	call fileentry_uninit_base(cont,b)
endfunction
function fileentry_uninit_base(sd cont,sv cursor)
	while cont!=cursor
		sub cursor (size_cont)
		call free(cursor#)
	endwhile
endfunction

function fileentry(sd s,sd sz)
	call nullend(s,sz)
	sd temp
	setcall temp realpath(s,(NULL))
	if temp!=(NULL)
		call fileentry_exists(temp)
		call free(temp)
		return (void)
	endif
	call erExit("realpath error")
endfunction

function fileentry_exists(sd s)
	sd sz
	setcall sz strlen(s)
	sv fls%files_p
	sd init;set init fls#
	sv p
	set p init
	add fls :
	set fls fls#d^
	add fls p
	while p!=fls
		sd b
		setcall b fileentry_compare(p#,s,sz)
		if b==0
			call skip_set()
			#add to previous declared
			sd wf;setcall wf working_file()
			sub p init
			add wf (size_cont)
			call adddwordtocont(wf,p)
			return (void)
		endif
		incst p
	#set p fls#d^;add fls (dword);set fls fls#;add p fls;while fls!=p;sd b;setcall b fileentry_compare(fls#,s,sz);if b==0;call skip_set();return (void);endif;incst fls
	endwhile
	call fileentry_add(s,sz)
endfunction

#cmp
function fileentry_compare(sd existent,sd new,sd sz)
	add existent (size_conts)
	if existent#!=sz
		return (~0)
	endif
	add existent (dword)
	sd c
	setcall c memcmp(existent,new,sz)
	return c
endfunction
