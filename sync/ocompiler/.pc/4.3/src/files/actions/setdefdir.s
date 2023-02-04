

Chars safedirdata="./"
Str safedir^safedirdata

Str filenameloc#1
SetCall filenameloc endoffolders(path)
Chars storeachar#1
Set storeachar filenameloc#
Set filenameloc# null

sd chdirresult#1
setcall chdirresult changedir(path)
if chdirresult!=chdirok
	str startchdirerr="Cannot set active folder:"
	setcall errormsg errorDefOut(startchdirerr,path)
	Call msgerrexit(errormsg)
endif


Set filenameloc# storeachar

Data movesize#1
SetCall movesize strlen(filenameloc)
Inc movesize

setcall errormsg maxpathverif(filenameloc,safedir)
if errormsg!=noerr
	Call msgerrexit(errormsg)
endif

Data safecurrentdirtopath#1
SetCall safecurrentdirtopath memalloc(flag_max_path)
If safecurrentdirtopath==null
	Call errexit()
EndIf
Call memtomem(safecurrentdirtopath,safedir,wordsize)
Data safecurrentdirloc#1
Set safecurrentdirloc safecurrentdirtopath
Add safecurrentdirloc wordsize
Call memtomem(safecurrentdirloc,filenameloc,movesize)
if logbool==true
	chars logfileextension=".log"
	str logextension^logfileextension

	data logfilecannotinit#1
	set logfilecannotinit false

	setcall errormsg maxpathverif(safecurrentdirtopath,logextension)
	if errormsg!=noerr
		set logfilecannotinit true
	else
		str appendextension#1
	
		set appendextension safecurrentdirloc
		add appendextension movesize
		dec appendextension

		data sizelogext#1
		setcall sizelogext strlen(logextension)
		inc sizelogext
		call memtomem(appendextension,logextension,sizelogext)
		
		setcall errormsg openfile(ptrlogfile,safecurrentdirtopath,_open_write)
		if errormsg!=noerr
			set logfilecannotinit true
		else
			Set storeachar filenameloc#
			Set filenameloc# null
			call addtolog(path)
			Set filenameloc# storeachar
		endelse
		set appendextension# null
	endelse
	if logfilecannotinit==true
		set logbool false
		call Message(errormsg)
	endif
endif

Call free(path)
Set path safecurrentdirtopath