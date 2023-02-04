

if parses==(pass_fns_imps)
	if innerfunction==false
		Chars unexef="Unexpected ENDFUNCTION command."
		Str unexeferr^unexef
		Set errormsg unexeferr
	else
		Set innerfunction false
	endelse
else
	if parses==(pass_write)
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
					While i!=(numberofvars)
						Data containertoclear#1
						SetCall containertoclear getstructcont(i)
						Data indexptr#1
						Data ptrindexptr^indexptr
						Call getptrcontReg(containertoclear,ptrindexptr)
						Set indexptr# zero
						Inc i
					EndWhile
				endif
			EndIf
		EndIf
		Set innerfunction false
	endif
endelse
inc functionTagIndex
