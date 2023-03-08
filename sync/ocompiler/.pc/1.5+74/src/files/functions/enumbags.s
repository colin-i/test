

#err
Function enumbags(data is_declare)
	sd pointer%containersbegin
	sd cursor=containerssize
	add cursor pointer
	While pointer!=cursor
		If is_declare==(TRUE)
			sd err;setcall err enumbags_alloc(pointer)
			If err!=(noerror)
				Return err
			EndIf
		Else
			call enumbags_free(pointer)
		EndElse
		add pointer (sizeofcontainer)
	EndWhile
	Return (noerror)
EndFunction

#err
function enumbags_alloc(sd container)
	sd max;call getcontMax(container,#max)
	sd pcont;call getptrcont(container,#pcont)
	sd err;setcall err mem_alloc(max,pcont)
	return err
endfunction
function enumbags_free(sd container)
	sd cont;call getcont(container,#cont)
	If cont!=(NULL)
		Call free(cont)
	EndIf
endfunction

#no return
Function freeclose()
	Data value#1
	Data zero=0

	Call enumbags(zero)

	Data negative=-1

	Data ptrfileout%ptrfileout
	Set value ptrfileout#
	If value!=negative
		Call close(value)
	EndIf

	data ptrlogfile%ptrlogfile
	Set value ptrlogfile#
	If value!=negative
		Call close(value)
	EndIf

	#here if allocerrormsg was a submessage(included in sprintf)
	#here at some main msgerrexits
	call clearmessage()

	sd p_safecurrentdirtopath%p_safecurrentdirtopath
	if p_safecurrentdirtopath#!=(NULL)
		call free(p_safecurrentdirtopath#)
	endif

	call platform_free()

	call align_free()
	call scopes_free()
EndFunction

Function msgerrexit(data msg)
	Call Message(msg)
	call errexit()
EndFunction

Function errexit()
	Call freeclose()
	call errorexit()
EndFunction

function errorexit()
	Call exit(-1)
endfunction
