



#80...h and can't compare signed<>unsigned and will loose control at alloc
#this *4 is still positive, this still positive *2 is there a shame check against negative
#                        aaBBccDD
#Const maxreservevalue=0x20000000-1
#1 073 741 823

#err
Function maxsectioncheck(sd a,sd pb)
	add pb# a
	if pb#<0
		return "Section size cannot be greater than 2 147 483 647 (0x7fFFffFF)."
	EndIf
	Return (noerror)
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
			sd err

			Set value destData
			setcall err maxsectioncheck(size,#value)
			If err!=noerr
				Return err
			EndIf
			Data pad#1
			Data ptrsecalign%ptrpage_sectionalignment
			Data secalign#1
			Set secalign ptrsecalign#
			SetCall pad requiredpad(value,secalign)
			setcall err maxsectioncheck(pad,#value)
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
