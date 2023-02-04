

Str commandname#1
Data commnamesize#1
Data ptrcommandname^commandname
Data ptrcommnamesize^commnamesize

SetCall commandname GetCommandName()

SetCall commnamesize strlen(commandname)
If commnamesize!=zero
	Call spaces(ptrcommandname,ptrcommnamesize)
	If commnamesize!=zero
		Chars quotation="\""
		Chars space=" "
		Data launchsize#1
		Set commandchar commandname#
		If commandchar==quotation
			Call stepcursors(ptrcommandname,ptrcommnamesize)
			SetCall launchsize valinmem(commandname,commnamesize,quotation)
		Else
			SetCall launchsize valinmem(commandname,commnamesize,space)
		EndElse

#

		Add commandname launchsize
		Sub commnamesize launchsize
		If commnamesize!=zero
			Set commandchar commandname#
			If commandchar==quotation
				Call stepcursors(ptrcommandname,ptrcommnamesize)
			EndIf
			Call spaces(ptrcommandname,ptrcommnamesize)
			If commnamesize!=zero
				Data sizeofpathin#1
				#
				Set commandchar commandname#
				If commandchar==quotation
					Call stepcursors(ptrcommandname,ptrcommnamesize)
					SetCall sizeofpathin valinmem(commandname,commnamesize,quotation)
				Else
					set sizeofpathin commnamesize
				EndElse
				If sizeofpathin!=zero
					Data maximumallowed=flag_MAX_PATH-1
					If sizeofpathin<=maximumallowed
						Call memtomem(path,commandname,sizeofpathin)
						Set commandname path
						Add commandname sizeofpathin
						Set commandname# null
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf
EndIf