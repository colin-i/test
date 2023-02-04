
const NULL=0
const void=0

importx "fopen" fopen
importx "fclose" fclose
importx "getline" getline
importx "feof" feof
importx "free" free
importx "chdir" chdir

include "../src/files/headers/log.h"

include "inits.s"
include "files.s"

function log_file(ss file)
	sd f
	setcall f fopen(file,"r")
	if f!=(NULL)
		sv fp%logf_p
		set fp# f
		sv p%logf_mem_p
		sd sz=0
		while sz!=-1
			sd bsz
			setcall sz getline(p,#bsz,f)
			if sz!=-1
				#knowing line\r\n from ocompiler
				sub sz 2
				call log_line(p#,sz)
			else
				sd e
				setcall e feof(f)
				if e==0
					call erExit("get line error")
				endif
			endelse
		endwhile
		call logclose()
		return (void)
	endif
	call erExit("fopen error")
endfunction

function log_line(ss s,sd sz)
#i all, f all; at end every f not i I, failure
#nm d;first c inside
#another log; files same; one c has some point in previous files same
#             decisions there
	sd type
	set type s#
	inc s;dec sz
	#d
	if type==(log_import)
		sv imps%imp_mem_p
		sd p
		setcall p pos_in_cont(imps,s,sz)
		if p==-1
			call addtocont(imps,s,sz)
		endif
	elseif type==(log_pathname)
		call fileentry(s,sz)
	elseif type==(log_pathfolder)
		call nullend(s,sz);inc sz
		call incrementdir(s,sz)
	elseif type==(log_fileend)
		call decrementdir()
	# !q
	#c
	elseif type==(log_function)
		sv fns%fn_mem_p
		call addtocont(fns,s,sz)
	endelseif
endfunction

function nullend(ss s,sd sz)
	add s sz;set s# 0 #this is on carriage return
endfunction

function changedir(ss s)
	if s#!=0 #it's extern chdir error
		sd d
		setcall d chdir(s)
		if d!=0
			Call erExit("chdir error")
		endif
	endif
endfunction
function incrementdir(ss s,sd sz)
	sv cwd%cwd_p
	call addtocont_rev(cwd,s,sz)
	call changedir(s)
endfunction
function decrementdir()
	sv cwd%cwd_p
	sd mem=:
	add mem cwd
	set mem mem#
	add mem cwd#
	sub mem (dword)
	#
	sd sz=dword
	add sz mem#
	#
	sub mem sz
	sub mem mem#
	call changedir(mem)
	neg sz
	call ralloc(cwd,sz)
endfunction
