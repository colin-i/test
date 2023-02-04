
#every time this first file has timestamp greater than Makefile, Makefile is deleted
#or make -B

format elfobj

const EXIT_SUCCESS=0
const EXIT_FAILURE=1

Importx "stderr" stderr
Importx "fprintf" fprintf

function messagedelim()
	sv st^stderr
	Chars visiblemessage={0x0a,0}
	Call fprintf(st#,#visiblemessage)
endfunction
Function Message(ss text)
	sv st^stderr
	Call fprintf(st#,text)
	call messagedelim()
EndFunction
function erMessage(ss text)
	call Message(text)
	aftercall er
	set er (~0)
	return (EXIT_FAILURE)
endfunction
function erExit(ss text)
	call freeall()
	call erMessage(text)
endfunction

include "./loop.s"
include "./resolve.s"

entrylinux main(sd argc,ss *argv0,ss argv1)

if argc>1
	call inits()
	call allocs()
	dec argc
	sd i
	set i argc
	mult argc :
	sv argv;set argv #argv1
	add argc argv
	while argv!=argc
		call log_file(argv#)
		call decrementdir()
		incst argv
	endwhile
	call resolve(i)
	call freeall()
	return (EXIT_SUCCESS)
endif

return (EXIT_FAILURE)
