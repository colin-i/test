


#bool
Function is_variable_char(sd byte)
	If byte<(asciizero)
		Return (FALSE)
	ElseIf byte<=(asciinine)
		Return (TRUE)
	EndElseIf
	sd bool
	setcall bool is_variable_char_not_numeric(byte)
	return bool
EndFunction

#bool
function is_variable_char_not_numeric(sd in_byte)
	if in_byte==(asciiaround)
		return (TRUE)
	elseif in_byte<(asciiA)
		return (FALSE)
	elseif in_byte<=(asciiZ)
		return (TRUE)
	elseif in_byte==(asciiunderscore)
		return (TRUE)
	elseif in_byte<(asciia)
		return (FALSE)
	elseif in_byte<=(asciiz)
		return (TRUE)
	endelseif
	return (FALSE)
endfunction

#errnr
Function addaref(data value,data ptrcontent,data ptrsize,data size,data typenumber,data mask)
	Str content#1
	Set content ptrcontent#
	Chars byte#1

	Chars err="The declarations must contain only alphanumeric, underscore and around chars and cannot start with a number."
	Str _err^err

	sd bool
	setcall bool is_variable_char_not_numeric(content#)
	if bool!=(TRUE)
		Return _err
	EndIf
	Data len#1
	Set len size
	Data zero=0
	Data false=FALSE
	While len!=zero
		Set byte content#
		SetCall bool is_variable_char(byte)
		If bool==false
			Return _err
		EndIf
		Inc content
		Dec len
	EndWhile

	#set the referenced bit if warnings are off
	Data warningsboolptr%ptrwarningsbool
	if warningsboolptr#==(FALSE)
		or mask (referencebit)
	endif
	
	sd dest
	SetCall dest getstructcont(typenumber)
	sd errnr
	setcall errnr add_ref_to_sec(dest,value,mask,ptrcontent#,size)
	If errnr!=(noerror)
		Return errnr
	EndIf
	
	Call advancecursors(ptrcontent,ptrsize,size)

	Return errnr
EndFunction

#err
function add_ref_to_sec(sd sec,sd value,sd mask,sd name,sd size)
	sd errnr
	SetCall errnr addtosec(#value,(dwsz),sec)
	If errnr!=(noerror)
		Return errnr
	EndIf
	#Mask is described at header.h
	SetCall errnr addtosec(#mask,(dwsz),sec)
	If errnr!=(noerror)
		Return errnr
	EndIf
	SetCall errnr addtosecstr(name,size,sec)
	If errnr!=(noerror)
		Return errnr
	EndIf
	
	return (noerror)
EndFunction
