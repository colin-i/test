

#err
Function coderegtocondloop()
	Data codesec%ptrcodesec
	Data codeReg#1
	Data ptrcodeReg^codeReg

	Call getcontReg(codesec,ptrcodeReg)

	Data err#1
	Data condloopsec%ptrconditionsloops
	Data dsz=dwsz

	SetCall err addtosec(ptrcodeReg,dsz,condloopsec)
	Return err
EndFunction

#err
Function condbeginwrite(data condnumber)
	Data err#1
	Data noerr=noerror

	SetCall err coderegtocondloop()
	If err!=noerr
		Return err
	EndIf

	Data condloopsec%ptrconditionsloops
	Data dsz=dwsz

	Data ptrcondnumber^condnumber
	SetCall err addtosec(ptrcondnumber,dsz,condloopsec)
	Return err
EndFunction

#err
Function condbegin(data ptrcontent,data ptrsize,data condnumber)
	Data cond#1
	Data ptrcond^cond
	Data err#1
	Data noerr=noerror
	
	SetCall err twoargs(ptrcontent,ptrsize,(not_a_subtype),ptrcond)
	If err!=noerr
		Return err
	EndIf

	SetCall err condbeginwrite(condnumber)
	Return err
EndFunction

#err
Function checkcondloopclose()
	Data regnr#1
	Data ptrregnr^regnr
	Data condloop%ptrconditionsloops
	Call getcontReg(condloop,ptrregnr)
	Data zero=0
	If regnr!=zero
		Chars closeerr="All conditions/loops within a scope most be closed."
		Str _closeerr^closeerr
		Return _closeerr
	EndIf
	Data noerr=noerror
	Return noerr
EndFunction

Const backjumpsize=5
#err
Function condjump(data size)
	Chars jump={0xe9}
	Data jsize#1
	Data bjsz=backjumpsize

	Data pjsize^jsize

	Set pjsize# size

	Data pjump^jump

	Data err#1
	Data code%ptrcodesec
	SetCall err addtosec(pjump,bjsz,code)
	Return err
EndFunction

#err
Function condend(data number)
	Data regnr#1
	Data structure#1
	Data ptrstructure^structure
	Data condloop%ptrconditionsloops
	Call getcont(condloop,ptrstructure)
	Data ptrcReg#1
	Data ptrptrcReg^ptrcReg
	Call getptrcontReg(condloop,ptrptrcReg)
	Set regnr ptrcReg#

	Data zero=0
	If regnr==zero
		Chars uncloseerr="Unexpected condition/loop close command."
		Str _uncloseerr^uncloseerr
		Return _uncloseerr
	EndIf

	Data dsz=dwsz
	Sub regnr dsz
	Add structure regnr
	
	Data lastcondition#1
	Set lastcondition structure#

	If lastcondition!=number
		Chars difcloseerr="The previous condition/loop is from a different type."
		Str _difcloseerr^difcloseerr
		Return _difcloseerr
	EndIf

	Sub regnr dsz
	Sub structure dsz

	Data jumploc#1
	Set jumploc structure#

	Data codeoffset#1
	Data ptrcodeoff^codeoffset
	Data codesec%ptrcodesec
	
	Call getcontReg(codesec,ptrcodeoff)

	Data noerr=noerror

	Data whilenr=whilenumber
	If number==whilenr
		Data bjsz=backjumpsize
		Add codeoffset bjsz

		Data whileloopstart#1
		Data whileloopsize#1
		
		Sub regnr dsz
		Sub structure dsz

		Set whileloopstart structure#
		Set whileloopsize codeoffset

		Sub whileloopsize whileloopstart

		Data inter#1

		Set inter whileloopsize
		Sub whileloopsize inter
		Sub whileloopsize inter

		Data err#1

		SetCall err condjump(whileloopsize)
		If err!=noerr
			Return err
		EndIf
	EndIf

	Data writeloc#1
	Data ptrwriteloc^writeloc
	Call getcont(codesec,ptrwriteloc)

	Add writeloc jumploc
	Sub writeloc dsz
	Sub codeoffset jumploc

	Set writeloc# codeoffset

	Set ptrcReg# regnr

	Return noerr
EndFunction

#err
Function conditionscondend(data close1,data close2)
	Data err#1
	Data noerr=noerror

	Data loop#1
	Data loopini=1
	Data loopstop=0
	Set loop loopini
	
	Data number#1
	Set number close1

	Data ifnr=ifnumber
	Data elsenr=elsenumber
	Data structure%ptrconditionsloops
	Data dsz=dwsz
	sd guardian=0

	While loop==loopini
		SetCall err condend(number)
		If err!=noerr
			Return err
		EndIf
		If number==ifnr
			If close2==elsenr
				Set number elsenr
				set guardian 1
			Else
				Set loop loopstop
			EndElse
		EndIf
		If number==elsenr
			Data clreg#1
			Data cl#1
			Data ptrclreg^clreg
			Data ptrcl^cl
			Call getcontandcontReg(structure,ptrcl,ptrclreg)
			Add cl clreg
			Sub cl dsz
			Data conditionsterminator#1
			Set conditionsterminator cl#
			Data term=ifinscribe
			If conditionsterminator==term
				if guardian==1
					call Message("Warning: ENDELSEIF not matching IF")
				endif
				Set loop loopstop
			EndIf
			set guardian 2
		EndIf
	EndWhile

	Data ptrReg#1
	Data ptrptrReg^ptrReg
	Call getptrcontReg(structure,ptrptrReg)
	Data Reg#1
	Set Reg ptrReg#
	Sub Reg dsz
	Set ptrReg# Reg
	Return err
EndFunction

Function closeifopenelse()
	Data err#1
	Data noerr=noerror

	Data number=0
	SetCall err condjump(number)
	If err!=noerr
		Return err
	EndIf
	Data ifnr=ifnumber
	SetCall err condend(ifnr)
	If err!=noerr
		Return err
	EndIf
	Data elsenr=elsenumber
	SetCall err condbeginwrite(elsenr)
	Return err
EndFunction