
If innerfunction==true
	Chars finferr="There is already another function started."
	Str ptrfinf^finferr
	Set errormsg ptrfinf
ElseIf programentrypoint!=codesecReg
	Chars funcafterentry="Unavailable FUNCTION/ENTRY[...] statement; The start address was at File: %s; Line: %u."
	Str fnafteren^funcafterentry

	SetCall allocerrormsg printbuf(fnafteren,ptrentrystartfile)
	If allocerrormsg==null
		Call errexit()
	EndIf
	Call sprintf(allocerrormsg,fnafteren,ptrentrystartfile,entrylinenumber)
	Set errormsg allocerrormsg
Else
	If subtype==(cENTRYLINUX)
		set subtype (cENTRY)
		set el_b_p# (TRUE)
	endif
	If subtype==(cENTRY)
		Data referencebit=referencebit
		Set objfnmask referencebit
		if twoparse==1
			set fnavailable two
		endif
	Else
		Set objfnmask null
		Set innerfunction true
	EndElse
	Data declarefn=declarefunction
	SetCall errormsg parsefunction(pcontent,pcomsize,declarefn,subtype)
EndElse