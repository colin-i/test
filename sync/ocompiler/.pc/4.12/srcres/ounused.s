
#every time this first file has timestamp greater than Makefile, Makefile is deleted
#or make -B

format elfobj

const EXIT_SUCCESS=0
const EXIT_FAILURE=1

Importx "stderr" stderr
Importx "fprintf" fprintf

Function Message(ss text)
	Chars visiblemessage={0x0a,0}
	sd st^stderr
	Call fprintf(st#,text)
	Call fprintf(st#,#visiblemessage)
EndFunction

include "./loop.s"

entrylinux main(sd argc,ss argv0)

if argc>1
	mult argc :
	sv argv;set argv #argv0
	add argc argv
	incst argv
	while argv!=argc
		call log_file(argv#)
		incst argv
	endwhile
	return (EXIT_SUCCESS)
endif

return (EXIT_FAILURE)
