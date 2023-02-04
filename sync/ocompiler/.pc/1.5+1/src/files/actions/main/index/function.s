
If innerfunction==true
	Chars finferr="There is already another function started."
	Str ptrfinf^finferr
	Set errormsg ptrfinf
ElseIf programentrypoint!=codesecReg
	Chars funcafterentry="Unavailable FUNCTION/ENTRY[...] statement; The start address was at File: %s; Line: %s."
	Str fnafteren^funcafterentry

	call sprintf(uint64s,"%u",entrylinenumber)
	SetCall allocerrormsg printbuf(fnafteren,ptrentrystartfile,uint64s,0)
	If allocerrormsg==null
		Call errexit()
	EndIf
	Set errormsg allocerrormsg
Else
	sd el_or_e=FALSE;if subtype==(cENTRY);set el_or_e (TRUE);elseif subtype==(cENTRYLINUX);set el_or_e (TRUE);endelseif
	If el_or_e==(TRUE)
		Data referencebit=referencebit
		Set objfnmask referencebit
		if twoparse==1
			set fnavailable two
			if exit_end==(TRUE)
				set real_exit_end (TRUE)
			endif
		endif
	Else
		Set objfnmask null
		Set innerfunction true
	EndElse
	if errormsg==(noerror)
		Data declarefn=declarefunction
		SetCall errormsg parsefunction(pcontent,pcomsize,declarefn,subtype)
	endif
EndElse
