

#headers
Include "./files/winheaders.h"
Include "../files/headers.h"

#functions
include "./files/prefextra.s"
Function Message(str text)
	Data null=NULL
	Call MessageBox(null,text,null,null)
EndFunction
Include "../files/functions.s"
