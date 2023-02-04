
EntryLinux main(sd argc,ss argv0,ss argv1)

#main
Include "../files/inits.s"

Include "./files/xgetfile.s"

setcall errormsg comline_parse(argc,#argv0)
if errormsg!=(noerror)
	call exitMessage(errormsg)
endif

Include "../files/actions.s"

Exit zero