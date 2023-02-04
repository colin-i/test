
const dword=4

importx "malloc" malloc
importx "realloc" realloc
importx "memcpy" memcpy
importx "memcmp" memcmp

function malloc_throwless(sv p,sd sz)
	setcall p# malloc(sz)
	if p#!=(NULL)
		return (NULL)
	endif
	return "malloc error"
endfunction
function alloc(sd p)
	sd er
	setcall er alloc_throwless(p)
	if er==(NULL)
		return (void)
	endif
	call erExit(er)
endfunction
function alloc_throwless(sd p)
	sd er
	setcall er malloc_throwless(p,0)
	if er==(NULL)
		add p :
		set p# 0
		return (NULL)
	endif
	return er
	#set p# 0;add p (dword);sd er;setcall er malloc_throwless(p,0);return er
endfunction

#function ralloc_throwless(sd p,sd sz);add sz p#;if sz>0;sv cursor=dword;add cursor p;setcall cursor# realloc(cursor#,sz);if cursor#!=(NULL);set p# sz
function ralloc_throwless(sv p,sd sz)
	sd cursor=:
	add cursor p
	add sz cursor#
	if sz>0
		setcall p# realloc(p#,sz)
		if p#!=(NULL)
			set cursor# sz
			return (NULL)
		endif
		return "realloc error"
	elseif sz==0  #equal 0 discovered at decrementfiles, since C23 the behaviour is undefined
	#using this quirk, lvs[0] will be used at constants at end, when size is 0
		#set p# 0
		set cursor# 0
		return (NULL)
	endelseif
	return "realloc must stay in 31 bits"
endfunction
function ralloc(sv p,sd sz)
	sd er
	setcall er ralloc_throwless(p,sz)
	if er==(NULL)
		return (void)
	endif
	call erExit(er)
endfunction

function addtocont(sv cont,ss s,sd sz)
	#knowing ocompiler maxvaluecheck
	sd size=dword
	add size sz
	call ralloc(cont,size)
	sd mem
	set mem cont#
	add cont :
	add mem cont#d^
	sub mem sz
	call memcpy(mem,s,sz)
	sub mem (dword)
	set mem# sz
	#sd oldsize;set oldsize cont#d^;sd size=dword;add size sz;call ralloc(cont,size);add cont (dword);add oldsize cont#;set oldsize# sz;add oldsize (dword);call memcpy(oldsize,s,sz)
endfunction
function addtocont_rev(sv cont,ss s,sd sz)
	sd size=dword
	add size sz
	call ralloc(cont,size)
	sd mem
	set mem cont#
	add cont :
	add mem cont#d^
	sub mem (dword)
	set mem# sz
	sub mem sz
	call memcpy(mem,s,sz)
	#sd oldsize;set oldsize cont#d^;sd size=dword;add size sz;call ralloc(cont,size);add cont (dword);add oldsize cont#;call memcpy(oldsize,s,sz);add oldsize sz;set oldsize# sz
endfunction
function adddwordtocont(sv cont,sd the_dword)
	call ralloc(cont,(dword))
	sd pos=-dword
	add pos cont#
	add cont :
	add pos cont#d^
	set pos# the_dword
endfunction

#-1/offset
function pos_in_cont(sv cont,ss s,sd sz)
	sd p
	sd mem=:
	set p cont#
	add mem cont
	set mem mem#
	add mem p
	#set mem cont#d^;add cont (dword);set p cont#;add mem p
	while p!=mem
		sd len
		set len p#
		add p (dword)
		if len==sz
			sd c
			setcall c memcmp(s,p,sz)
			if c==0
				sub p cont#
				sub p (dword)
				return p
			endif
		endif
		add p len
	endwhile
	return -1
endfunction
