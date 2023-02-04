
#more situations: getmax getptrmax getptrcont

Function getcont(data ptrstrucutre,data ptrcontainer)
	Data offset=containersdataoffset
	Add ptrstrucutre offset
	Set ptrcontainer# ptrstrucutre#
EndFunction

Function getptrcontReg(data ptrstrucutre,data ptrptrcontainerReg)
	Data offset=containersdataRegoffset
	Add ptrstrucutre offset
	Set ptrptrcontainerReg# ptrstrucutre
EndFunction

Function getcontReg(data ptrstrucutre,data ptrcontainerReg)
	Data ptrcReg#1
	Data ptrptrcReg^ptrcReg
	Call getptrcontReg(ptrstrucutre,ptrptrcReg)
	Set ptrcontainerReg# ptrcReg#
EndFunction

Function getcontandcontReg(data ptrstrucutre,data ptrcontainer,data ptrcontainerReg)
	Call getcontReg(ptrstrucutre,ptrcontainerReg)
	Call getcont(ptrstrucutre,ptrcontainer)
EndFunction

Function getcontplusReg(data ptrstrucutre,data ptrcontainer)
	Call getcont(ptrstrucutre,ptrcontainer)
	sd r
	Call getcontReg(ptrstrucutre,#r)
	add ptrcontainer# r
EndFunction

Data innerfunction#1
Const globalinnerfunction^innerfunction

#pdata
Function getstructcont(data typenumber)
	Data dest#1
	Data scopes%ptrscopes
	Data sizeofdataset=sizeofcontainer

	Data fnboolptr%globalinnerfunction
	Data fnbool#1

	Set fnbool fnboolptr#

	Data true=TRUE
	Data scopeindependent=afterscopes

	If fnbool==true
		If typenumber<scopeindependent
			Data nrofvars=numberofvars
			Add typenumber nrofvars
		EndIf
	EndIf

	Data offset#1
	Set offset sizeofdataset
	Mult offset typenumber
	Set dest scopes
	Add dest offset
	Return dest
EndFunction

#return virtual value
Function congruentmoduloatsegments(data virtual,data offset,data modulo,data newbytes)
	Data offsettop#1
	Data virtualtop#1

    #add newbytes at virtual, offset already has them
	Add virtual newbytes

	SetCall virtualtop remainder(virtual,modulo)

	SetCall offsettop remainder(offset,modulo)

	Data value#1

	If virtualtop!=offsettop
	    If virtualtop<offsettop
		    #rise virtual to offset
		    Sub offsettop virtualtop
			Add virtual offsettop
		Else
		    #rise virtual to modulo+offset
			Set value modulo
			Sub value virtualtop
			Add virtual value
			Add virtual offsettop
		EndElse
	EndIf

	#pad safe for avoiding segemntation faults
	SetCall value remainder(offsettop,modulo)
	Data zero=0
	If value!=zero
	     Add virtual modulo
	EndIf
	return virtual
EndFunction

#err
function addtolog_ex(ss content,sd sizetowrite)
	data ptrfilehandle%ptrlogfile
	data filehandle#1
	set filehandle ptrfilehandle#
	sd err
	setcall err writefile_errversion(filehandle,content,sizetowrite)
	if err!=(noerror);return err;endif

	chars textterm={asciicarriage,asciireturn,0}
	str text^textterm
	data sz=2
	setcall err writefile_errversion(filehandle,text,sz)
	return err
endfunction
#err
function addtolog_withchar_ex(ss content,sd size,sd type)
	data ptrfilehandle%ptrlogfile
	if ptrfilehandle#!=-1
	#this compare only at first chdir is extra
		sd err
		setcall err writefile_errversion(ptrfilehandle#,#type,1)
		if err==(noerror)
			setcall err addtolog_ex(content,size)
		endif
		return err
	endif
	return (noerror)
endfunction
#err
function addtolog_withchar(ss content,sd type)
	sd len
	setcall len strlen(content)
	sd err
	setcall err addtolog_withchar_ex(content,len,type)
	return err
endfunction
#err
function addtolog_withchar_ex_atunused(ss content,sd size,sd type)
	data ptrobject%ptrobject
	if ptrobject#==(TRUE)
		sd err
		setcall err addtolog_withchar_ex(content,size,type)
		return err
	endif
	return (noerror)
endfunction

function restore_cursors_onok(sd ptrcontent,sd ptrsize,sd forward,sd data1,sd data2)
	sd c
	sd s
	set c ptrcontent#
	set s ptrsize#
	sd err
	data noerr=noerror
	setcall err forward(ptrcontent,ptrsize,data1,data2)
	if err==noerr
		set ptrcontent# c
		set ptrsize# s
	endif
	return err
endfunction
