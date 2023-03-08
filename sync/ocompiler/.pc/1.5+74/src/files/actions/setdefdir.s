

Chars safedirdata="./"
Str safedir^safedirdata

Str filenameloc#1
SetCall filenameloc endoffolders(path_nofree)
Chars storeachar#1
Set storeachar filenameloc#
Set filenameloc# null

sd chdirresult#1
setcall chdirresult changedir(path_nofree)
if chdirresult!=chdirok
	str startchdirerr="Cannot set active folder:"
	setcall errormsg errorDefOut(startchdirerr,path_nofree)
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

	setcall errormsg maxpathverif(safecurrentdirtopath,logextension)
	if errormsg==noerr
		str appendextension#1

		set appendextension safecurrentdirloc
		add appendextension movesize
		dec appendextension

		data sizelogext#1
		setcall sizelogext strlen(logextension)
		inc sizelogext
		call memtomem(appendextension,logextension,sizelogext)

		setcall errormsg openfile(ptrlogfile,safecurrentdirtopath,_open_write)
		if errormsg==noerr
			sd log_main_folder
			setcall log_main_folder getcwd((NULL),0)
			if log_main_folder==(NULL)
				chars getcwd_first="first getcwd error"
				set errormsg #getcwd_first
			else
				setcall errormsg addtolog_withchar(log_main_folder,(log_pathfolder))
				call free(log_main_folder)
			endelse
		endif
		set appendextension# null
	endif
	if errormsg!=noerr
		Call msgerrexit(errormsg)
	endif
endif
