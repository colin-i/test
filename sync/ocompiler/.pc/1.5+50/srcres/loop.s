
const NULL=0
const void=0
const asciiperiod=0x2E
const asciio=0x6F

importx "fopen" fopen
importx "fclose" fclose
importx "getline" getline
importx "feof" feof
importx "free" free
importx "chdir" chdir
importx "stdout" stdout

include "../src/files/headers/log.h"

include "inits.s"
include "files.s"
include "skip.s"
include "const.s"
include "uconst.s"

function log_file(ss file)
	sd f
	setcall f fopen(file,"r")
	if f!=(NULL)
		sv fp%logf_p
		set fp# f
		sv p%logf_mem_p
		sd sz=0
		sd link=TRUE
		while sz!=-1
			sd bsz
			setcall sz getline(p,#bsz,f)
			if sz!=-1
				#knowing line\r\n from ocompiler
				sub sz 2
				call log_line(p#,sz,#link)
			else
				sd e
				setcall e feof(f)
				if e==0
					call erExit("get line error")
				endif
			endelse
		endwhile
		call uconst_miniresolve()
		call logclose()
		if link==(TRUE)
			call printlink(file)
		endif
		return (void)
	endif
	call erExit("fopen error")
endfunction

function log_line(ss s,sd sz,sd plink)
#i all, f all; at end every f not i, failure. constants are with all includes two types of children declared/already and at every log unused/still unused
	sd type
	set type s#
	inc s;dec sz
	sd skip
	if plink#==(TRUE)
		if type==(log_declare)
			setcall skip skip_test()
			if skip==(FALSE)
				call constant_add(s,sz)
			endif
			return (void)
		elseif type==(log_import)
			setcall skip skip_test()
			if skip==(FALSE)
				call import_add(s,sz)
			endif
			return (void)
		elseif type==(log_constant)
			call uconst_add(s,sz)
			return (void)
		elseif type==(log_function)
			sv fns%fn_mem_p
			call addtocont(fns,s,sz)
			return (void)
		endelseif
	endif
	if type==(log_pathname)
		call filesplus()
		setcall skip skip_test()
		if skip==(FALSE)
			call fileentry(s,sz)
		endif
	elseif type==(log_pathfolder)
		setcall skip skip_test()
		if skip==(FALSE)
			call incrementdir(s,sz)
		endif
	elseif type==(log_fileend)
		setcall skip filesminus()
		if skip<=0
			call decrementdir()
			if skip<0
				call decrementfiles()
			endif
		endif
	elseif type==(log_fileend_old)
		setcall skip filesminus()
		if skip<0
			call decrementfiles()
		endif
	elseif type==(log_reusable)
		set plink# (FALSE)
	endelseif
endfunction

function import_add(sd s,sd sz)
	sv imps%imp_mem_p
	sd p
	setcall p pos_in_cont(imps,s,sz)
	if p==-1
		call addtocont(imps,s,sz)
	endif
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
	call nullend(s,sz);inc sz
	sv cwd%cwd_p
	call addtocont_rev(cwd,s,sz)
	call changedir(s)
endfunction
function decrementdir()
	sv cwd%cwd_p
	sd mem=:
	add mem cwd
	set mem mem#v^
	add mem cwd#
	#sd cwd%cwd_p;sd mem=dword;add mem cwd;set mem mem#v^;add mem cwd#
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

function printlink(sd file)
	ss back
	set back file
	addcall back strlen(file)
	vstr ers="printlink problems with log file name extension."
	while back!=file
		dec back
		if back#==(asciiperiod)
			while back!=file
				dec back
				if back#==(asciiperiod)
					inc back
					if back#!=(NULL)
						set back# (asciio)
						inc back
						set back# (NULL)
						sv st^stdout
						sd len
						setCall len fprintf(st#," ")
						if len==1
							setCall len fprintf(st#,file)
							sub back file
							if len==back
								return (void)
							endif
						endif
						call erExit("fprintf error.")
					endif
					call erExit(ers)
				endif
			endwhile
		endif
	endwhile
	call erExit(ers)
endfunction
