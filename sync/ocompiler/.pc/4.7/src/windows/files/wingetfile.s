

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

Set path_nofree (NULL)
Include "./wingetfile/getfilefromcommand.s"
set path_free (NULL)
If path_nofree==null
	#open file name
	Include "./wingetfile/getfilefromopenfilename.s"
	set path_nofree path_free
	Data timeatbegin#1
	SetCall timeatbegin GetTickCount()
	Set openfilenamemethod true
EndIf