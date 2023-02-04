
Data numberofvariables=numberofvars

If innerfunction==false
	Chars unexef="Unexpected ENDFUNCTION command."
	Str unexeferr^unexef
	Set errormsg unexeferr
Else
	if twoparse==1
		SetCall errormsg checkcondloopclose()
		If errormsg==noerr
			data ptrreturn#1
			data sizereturn#1
			data ptrptrreturn^ptrreturn
			setcall sizereturn getreturn(ptrptrreturn)

			SetCall errormsg addtoCode_set_programentrypoint(ptrreturn,sizereturn)
			If errormsg==noerr
				setcall errormsg scopes_store(functionTagIndex)
				If errormsg==noerr
					Set i zero
					While i!=numberofvariables
						Data containertoclear#1
						SetCall containertoclear getstructcont(i)
						Data indexptr#1
						Data ptrindexptr^indexptr
						Call getptrcontReg(containertoclear,ptrindexptr)
						Set indexptr# zero
						Inc i
					EndWhile
					inc functionTagIndex
				endif
			EndIf
		EndIf
	endif
	If errormsg==noerr
		Set innerfunction false
	endif
EndElse
