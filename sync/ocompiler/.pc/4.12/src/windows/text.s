

#main

Include "../files/inits.s"

set argv (NULL)
Data openfilenamemethod#1
Set openfilenamemethod false
Include "./files/wingetfile.s"

if argv!=(NULL)
	setcall errormsg comline_parse(argc,argv)
	if errormsg!=(noerror)
		call msgerrexit(errormsg)
	endif
endif

Include "../files/actions.s"

Include "./files/winend.s"

Call exit(zero)
