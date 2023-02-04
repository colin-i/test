

#main

Include "../files/inits.s"

set argv (NULL)
Data openfilenamemethod#1
Set openfilenamemethod false
Include "./files/wingetfile.s"

if argv!=(NULL)
	Include "../files/inits/conv.s"
endif

Include "../files/actions.s"

Include "./files/winend.s"

Call exit(zero)
