


Str pointofpathout#1
Data pathinsize#1
Str minpath#1
Str cursorpath#1
Data unit=1

Set minpath safecurrentdirloc

Set pointofpathout safecurrentdirloc
SetCall pathinsize strlen(safecurrentdirloc)
Add pointofpathout pathinsize

Set cursorpath pointofpathout
Sub minpath unit
Sub cursorpath unit

While minpath!=cursorpath
	Chars teststr=""
	Set teststr cursorpath#
	If teststr==dot
		Set pointofpathout cursorpath
		Set cursorpath minpath
	EndIf
	If minpath!=cursorpath
		Sub cursorpath unit
	EndIf
EndWhile

Data extension#1
Set extension null

If fileformat==pe_exec
	Chars exe=".exe"
	Str pexe^exe
	Set extension pexe
Else
	If object==true
		Chars obj=".o"
		Str pobj^obj
		Set extension pobj
	EndIf
EndElse

If extension!=null
	Data sz#1
	SetCall sz strlen(extension)

	setcall errormsg maxpathverif(safecurrentdirtopath,extension)
	if errormsg!=noerr
		Call msgerrexit(errormsg)
	endif

	Call memtomem(pointofpathout,extension,sz)
	Add pointofpathout sz
EndIf

Set pointofpathout# null
