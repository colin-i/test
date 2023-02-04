
#################Memory
#err
Function memrealloc(data ptrpointer,data size)
	Data newpointer#1
	Data oldpointer#1
	Set oldpointer ptrpointer#
	SetCall newpointer realloc(oldpointer,size)
	Data null=NULL
	If newpointer==null
		Chars newmem="Memory allocation error."
		Data pnewmem^newmem
		Return pnewmem
	EndIf
	Set ptrpointer# newpointer
	Data noerr=noerror
	Return noerr
EndFunction
#err
Function mem_alloc(sd size,sv p)
	sd mem
	setcall mem malloc(size)
	if mem!=(NULL)
		set p# mem
		return (noerror)
	endif
	return "malloc error"
EndFunction

#err
Function memoryalloc(data pathsize,data memptr)
	Data err#1
	Data null=NULL
	Set memptr# null
	SetCall err memrealloc(memptr,pathsize)
	Return err
EndFunction

#null or ptr
Function memalloc(data pathsize)
	Data errmsg#1
	Data mem#1
	Data memptr^mem
	SetCall errmsg memoryalloc(pathsize,memptr)
	Data null=NULL
	Data noerr=noerror
	If errmsg==noerr
		Return mem
	Else
		Call Message(errmsg)
		Return null
	EndElse
EndFunction


#null or ptr
Function memcalloc(data pathsize)
	Data path=0
	Data null=NULL
	SetCall path memalloc(pathsize)
	If path==null
		Return null
	EndIf
	Call memset(path,null,pathsize)
	Return path
EndFunction

#0 equal -1 not
Function memcmp(str m1,str m2,data size)
	Data zero=0

	Data equal=0
	Data notequal=-1

	Chars c1#1
	Chars c2#1
	While size!=zero
		Set c1 m1#
		Set c2 m2#
		If c1!=c2
			Return notequal
		EndIf
		Inc m1
		Inc m2
		Dec size
	EndWhile
	Return equal
EndFunction

#sizeof the string
Function strlen(str str)
	Chars term={0}
	Chars byte={0}
	Data sz#1
	Data zero=0
	Set sz zero
	Set byte str#
	While byte!=term
		Inc str
		Inc sz
		Set byte str#
	EndWhile
	Return sz
EndFunction

#null or buffer
Function printbuf(sd format,sd message,sd s1,sd nr,sd n1,sd n2)
	Data bufsize#1
	SetCall bufsize strlen(format)
	addCall bufsize strlen(message)
	addCall bufsize strlen(s1)
	if nr>0
		add bufsize (max_uint64)
		if nr>1
			add bufsize (max_uint64)
		endif
	endif

	Str buf#1
	SetCall buf memalloc(bufsize)
	Data null=NULL
	If buf==null
		Return null
	EndIf
	call sprintf(buf,format,message,s1,n1,n2)
	Return buf
EndFunction

#str1/newPointer
function errorDefOut(str str1,str str2)
	str format="%s%s"
	data ptrallocerrormsg%ptrallocerrormsg
	SetCall ptrallocerrormsg# printbuf(format,str1,str2,0)
	data null=NULL
	If ptrallocerrormsg#==null
		return str1
	EndIf
	return ptrallocerrormsg#
endfunction

#################Files and Folders
#err
Function openfile(data pfile,str path,data oflag)
	sd permission
	sd creat_test;set creat_test oflag;and creat_test (flag_O_CREAT);if creat_test!=0
		set permission (pmode_mode);endif
	Data openfalse=openno
	SetCall pfile# open(path,oflag,permission)
	If pfile#==openfalse
		str errorreturn#1
		Str fileOpenErr="Cannot open a file:"
		setcall errorreturn errorDefOut(fileOpenErr,path)
		Return errorreturn
	EndIf
	Data noerr=noerror
	Return noerr
EndFunction

chars writefile_err="Cannot write data to a file."
const writefile_err_p^writefile_err
#return _write (-1 or wrln)
Function writefile(data hfile,str buf,data ln)
	sd writeres
	SetCall writeres write(hfile,buf,ln)
	If writeres!=ln
		sd writeerr%writefile_err_p
		Call Message(writeerr)
		Return (writeno)
	EndIf
	Return writeres
EndFunction
#err
Function writefile_errversion(data hfile,str buf,data ln)
	sd writeres
	SetCall writeres write(hfile,buf,ln)
	If writeres!=ln
		sd writeerr%writefile_err_p
		Return writeerr
	EndIf
	Return (noerror)
EndFunction

#return required pad, so value can be a multiple of pad
Function requiredpad(data value,data pad)
	Data integers#1
	Set integers value
	Div integers pad
	Mult integers pad
	Sub value integers

	Data zero=0
	If value==zero
		return zero
	EndIf
	Sub pad value
	Return pad
EndFunction

#return writefile
Function padwrite(data hfile,data size)
	Data padmem#1
	Data null=NULL
	Data writefalse=writeno
	SetCall padmem memcalloc(size)
	If padmem==null
		return writefalse
	EndIf
	Data writeres#1
	SetCall writeres writefile(hfile,padmem,size)
	Return writeres
EndFunction

#return writefile
#write ln, and walk size value to pad
Function paddedwrite(data hfile,str buf,data ln,data pad)
	Data zero=0
	Data padvalue#1
	Set padvalue pad
	Div padvalue padvalue
	If padvalue==pad
		Set padvalue zero
	Else
		Set padvalue pad
	EndElse
	Data writeres#1
	If ln!=zero
		Data writefalse=writeno
		SetCall writeres writefile(hfile,buf,ln)
		If writeres==writefalse
			Return writefalse
		EndIf

		SetCall padvalue requiredpad(ln,pad)
		If padvalue==zero
			Return writeres
		EndIf
	EndIf
	SetCall writeres padwrite(hfile,padvalue)
	Return writeres
EndFunction

#return writeres
Function padsec(data hfile,data value,data pad)
	Data valuetopad#1
	SetCall valuetopad requiredpad(value,pad)
	Data writeres#1
	SetCall writeres padwrite(hfile,valuetopad)
	Return writeres
EndFunction

#true if match or false
Function filepathdelims(chars chr)
	Chars bslash=asciibs
	Chars slash=asciislash
	Data true=TRUE
	Data false=FALSE
	If chr==bslash
		Return true
	EndIf
	If chr==slash
		Return true
	EndIf
	Return false
EndFunction

#folders ('c:\folder\file.txt' will be pointer starting at 'file.txt')
Function endoffolders(ss path)
	sd sz
    setcall sz strlen(path)
    ss cursor
    set cursor path
    add cursor sz
    sd i=0
    while i<sz
        dec cursor
        sd bool
        setcall bool filepathdelims(cursor#)
        if bool==(TRUE)
			inc cursor
            return cursor
        endif
        inc i
    endwhile
    return path
EndFunction

#chdir
function changedir(ss path)
	sd testsamefolder
	data null=0
	data chdirok=chdirok
	data chdirresult#1

	setcall testsamefolder strlen(path)
	if testsamefolder==null
		return chdirok
	endif
	SetCall chdirresult chdir(path)
	return chdirresult
endfunction

#################Mixt
#offset is when wanting to put the content at the allocation+offset
Function file_get_content_ofs(str path,data ptrsize,data ptrmem,data offset)
	Data err#1
	Data noerr=noerror

	Data file#1
	Data ptrfile^file

	Data ordflag=_open_read
	SetCall err openfile(ptrfile,path,ordflag)
	If err!=noerr
		Return err
	EndIf

	Data size#1
	Data zero=0
	Data seek_set=SEEK_SET
	Data seek_end=SEEK_END
	SetCall size lseek(file,zero,seek_end)
	If size<zero
		Chars filesizeerr="File length function error."
		Str ptrfilesizeerr^filesizeerr
		Set err ptrfilesizeerr
	Else
		Call lseek(file,zero,seek_set)

		#offset here
		add size offset

		Set ptrsize# size

		SetCall err memoryalloc(size,ptrmem)
		If err==noerr
			Data mem#1
			Set mem ptrmem#

			#and offset here
			add mem offset
			sub size offset
			#

			Call read(file,mem,size)
		EndIf
	EndElse
	Call close(file)
	Return err
EndFunction

#return remainder
Function remainder(data quotient,data dividend)
    Data returnval#1
	Set returnval quotient
	Div quotient dividend
	Mult quotient dividend
	Sub returnval quotient
	Return returnval
EndFunction

#return neg(nr)
Function neg(data nr)
	Data negative#1
	Set negative nr
	Sub nr negative
	Sub nr negative
	Return nr
EndFunction

#void
function clearmessage()
	data ptrallocerrormsg%ptrallocerrormsg
	data null=NULL
	If ptrallocerrormsg#!=null
		Call free(ptrallocerrormsg#)
		#if the error from file_get.. is from open here is ok, else if is only a str err alloc was not
		set ptrallocerrormsg# null
	EndIf
endfunction

#void
function safeMessage(str text)
	call Message(text)
	#here if display msg only
	call clearmessage()
endfunction

#err
function compareagainstmaxpath(data sizetocompare)
	data flag_max_path=flag_MAX_PATH
	if sizetocompare>flag_max_path
		chars greaterthanmax="A file path size is greater than maximum number."
		str greater^greaterthanmax
		return greater
	else
		data noerr=noerror
		return noerr
	endelse
endfunction
