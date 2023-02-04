

data ptrmem#1
setcall ptrmem memalloc(flag_max_path)
if ptrmem!=null
	data sizep#1
	setcall sizep GetModuleFileName(null,ptrmem,flag_max_path)
	if sizep==null
		str getmoderr="GetModuleFileName error."
		call Message(getmoderr)
	else
		call setpreferences(ptrmem)
	endelse
	call free(ptrmem)
endif


Data commandchar#1
Set path# null
Include "./wingetfile/getfilefromcommand.s"

Set commandchar path#
If commandchar==null
	#open file name
	Include "./wingetfile/getfilefromopenfilename.s"
	Data timeatbegin#1
	SetCall timeatbegin GetTickCount()
	Set openfilenamemethod true
EndIf