



#40...h*2 and can't compare signed<>unsigned and will loose control at alloc
#this is also used at reserve *4 will be negative there
#Const maxsectionvalue=0x40000000-1
#                       aaBBccDD
Const maxsectionvalue=0x20000000-1
#knowing that enlarge value will qwsz them

#err
Function maxvaluecheck(data value)
	Data secmax=maxsectionvalue
	If value>secmax
		#Chars secsizeerr="Section size cannot be greater than 1 073 741 823."
		Chars secsizeerr="Section size cannot be greater than 536 870 911."
		Str ptrsecsizeerr^secsizeerr
		Return ptrsecsizeerr
	EndIf
	Data noerr=noerror
	Return noerr
EndFunction

#errnr
Function addtosec(str content,data size,data dst)
	Data destMax#1
	Data pdestReg#1
	Data ppdestReg^pdestReg

	Call getptrcontReg(dst,ppdestReg)

	Set destMax dst#

	Data null=0
	Data destData#1
	Data avail#1
	Data noerr=noerror

	Set destData pdestReg#
	Set avail destMax
	Sub avail destData
	If avail<size
		Data datasec%ptrdatasec
		Data codesec%ptrcodesec
		Data ptrfileformat%ptrfileformat
		Data elf_unix=elf_unix
		Data false=FALSE
		Data true=TRUE
		Data sectionexpand#1
		Set sectionexpand false
		If ptrfileformat#==elf_unix
			Set sectionexpand true
		Else
			If dst==datasec
				Set sectionexpand true
			ElseIf dst==codesec
				Set sectionexpand true
			EndElseIf
		EndElse
		If sectionexpand==false
			Chars _memerr="Memory space error."
			Str memerr^_memerr
			Return memerr
		Else
			Data value#1
			Set value destData
			Add value size
			Data pad#1
			Data ptrsecalign%ptrpage_sectionalignment
			Data secalign#1
			Set secalign ptrsecalign#
			SetCall pad requiredpad(value,secalign)
			Add value pad

			Data err#1
			SetCall err maxvaluecheck(value)
			If err!=noerr
				Return err
			EndIf

			Data contoffset=containersdataoffset
			Data container#1
			Set container dst
			Add container contoffset

			SetCall err memrealloc(container,value)
			If err!=noerr
				Return err
			EndIf
			Set dst# value
		EndElse
	EndIf
	If content!=null
		Str destloc#1
		Data ptrdest^destloc
		Call getcont(dst,ptrdest)
		Add destloc destData
		Call memtomem(destloc,content,size)
	EndIf
	Add destData size
	Set pdestReg# destData
	Return noerr
EndFunction
#errnr
function addtoCode_set_programentrypoint(ss content,sd size)
	sd err;data code%ptrcodesec
	setcall err addtosec(content,size,code)
	if err!=(noerror);return err;endif
	data c#1
	Call getcontReg(code,#c)
	data e%ptrprogramentrypoint
	Set e# c
	return (noerror)
endfunction
#errnr
Function addtosecstr(str content,data size,data dst)
	Data errnr#1
	Data noerr=noerror
	SetCall errnr addtosec(content,size,dst)
	If errnr!=noerr
		Return errnr
	EndIf
	Chars null={0}
	Data sz=1
	Str ptrnull^null
	SetCall errnr addtosec(ptrnull,sz,dst)
	Return errnr
EndFunction