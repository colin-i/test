



#return the size of the value, if the delim is found the size counts until there
Function valinmemsens(str content,data size,chars delim,data sens)
	Data length#1
	Set length size
	Chars byte#1
	Data zero=0

	If size==zero
		Return size
	EndIf
	Data backward=BACKWARD
	If sens==backward
		Dec content
	EndIf
	Set byte content#
	While byte!=delim
		If sens!=backward
			Inc content
		Else
			Dec content
		EndElse
		Dec size
		If size==zero
			Set byte delim
		Else
			Set byte content#
		EndElse
	EndWhile

	Sub length size
	Return length
EndFunction

Function valinmem(str content,data size,chars delim)
	Data returnvalue#1
	Data forward=FORWARD
	SetCall returnvalue valinmemsens(content,size,delim,forward)
	Return returnvalue
EndFunction

function valinmem_pipes(str content,data size,chars delim,data pipe)
	data sz#1
	setcall sz valinmem(content,size,delim)
	set pipe# sz
	return sz
endfunction