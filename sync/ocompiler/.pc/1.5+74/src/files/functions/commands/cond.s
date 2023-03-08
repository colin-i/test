
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
	Data condloop%ptrconditionsloops
	Data ptrcReg#1
	Data ptrptrcReg^ptrcReg

	Call getptrcontReg(condloop,ptrptrcReg)
	If ptrcReg#==0
		Chars uncloseerr="Unexpected condition/loop close command."
		Str _uncloseerr^uncloseerr
		Return _uncloseerr
	EndIf

	Data codeoffset#1
	Data ptrcodeoff^codeoffset
	Data codesec%ptrcodesec
	Data whilenr=whilenumber
	Data structure#1
	Data ptrstructure^structure

	Call getcontReg(codesec,ptrcodeoff)
	If number==whilenr
		Add codeoffset (backjumpsize)
	EndIf
	Call getcont(condloop,ptrstructure)
	Add structure ptrcReg#
	sd reg;set reg structure

	sd err;setcall err condendtest(#structure,number,codeoffset)
	if err==(noerror)
		If number==whilenr
			setcall err jumpback(codeoffset,structure)
			If err!=(noerror)
				Return err
			EndIf
			add reg (dwsz)   #to match for ptrcReg
		EndIf

		call condendwrite(structure,codeoffset)

		sub reg structure
		Sub ptrcReg# reg
	endif
	return err
EndFunction

#err
function condendtest(sv p_conds,sd number,sd codeoffset)
	sd conds;set conds p_conds#

	#for breaks inside conditions
	sd last;set last conds

	while 1==1
		Data lastcondition#1

		sub conds (dwsz)
		Set lastcondition conds#
		sub conds (dwsz)

		if lastcondition==(breaknumber)
			if number==(whilenumber)
				call condendwrite(conds,codeoffset)
			endif
		elseIf lastcondition!=number
			Chars difcloseerr="The previous condition/loop is from a different type."
			vStr _difcloseerr^difcloseerr
			Return _difcloseerr
		else
			if number!=(whilenumber)
				sub last (2*dwsz)
				if conds!=last
					#move it to last to match the reg set outside
					#and move ifinscribe if it is the case
					#ignore type, it will only be removed outside
					#don't increase size to align ifinscribe and just swap

					sd cursor;set cursor conds
					sub cursor (dwsz)
					sd size
					if cursor#==(ifinscribe)
						set size (2*dwsz)
					else
						set size (dwsz)
						add cursor (dwsz)
					endelse
					sd aux#2
					call memtomem(#aux,cursor,size)
					while conds!=last
						add conds (2*dwsz)
						call memtomem(cursor,conds,(2*dwsz))
						add cursor (2*dwsz)
					endwhile
					call memtomem(cursor,#aux,size)
				endif
			endif
			set p_conds# conds
			return (noerror)
		Endelse
	endwhile
endfunction

function condendwrite(sd structure,sd codeoffset)
	Data jumploc#1
	Data codesec%ptrcodesec
	vData writeloc#1
	Data ptrwriteloc^writeloc

	Call getcont(codesec,ptrwriteloc)

	Set jumploc structure#
	Sub codeoffset jumploc
	Add writeloc jumploc
	Sub writeloc (dwsz)

	Set writeloc# codeoffset
endfunction

#err
function jumpback(sd codeoffset,sd condstruct)
	sub condstruct (dwsz)
	sub codeoffset condstruct#
	neg codeoffset
	sd err
	SetCall err condjump(codeoffset)
	return err
endfunction

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

	While loop==loopini
		SetCall err condend(number)
		If err!=noerr
			Return err
		EndIf
		sd c
		If number==ifnr
			If close2==elsenr
				Set number elsenr
				setcall c prevcond()
				if c==(ifinscribe)
					call Message("Warning: ENDELSEIF not matching IF")
				endif
			Else
				Set loop loopstop
			EndElse
		EndIf
		If number==elsenr
			setcall c prevcond()
			if c==(ifinscribe)
				Set loop loopstop
			endif
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
function prevcond()
	vData cl#1
	vData structure%ptrconditionsloops
	Call getcontplusReg(structure,#cl)
	Sub cl (dwsz)
	return cl#
endfunction

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

#err
function continue()
	sd regnr
	sd structure
	vData condloop%ptrconditionsloops
	call getcontandcontReg(condloop,#structure,#regnr)
	if regnr!=0
		sd start;set start structure
		add structure regnr
		while start!=structure
			sd type
			sub structure (dwsz)
			set type structure#
			if type!=(ifinscribe)
				sub structure (dwsz)
				if type==(whilenumber)
					vdata ptrcodesec%ptrcodesec
					sd codeoffset
					call getcontReg(ptrcodesec,#codeoffset)
					Add codeoffset (backjumpsize)
					sd err;setcall err jumpback(codeoffset,structure)
					return err
				endif
			endif
		endwhile
	endif
	return "There is no loop to continue."
endfunction

#err
function break()
	sd regnr
	sd structure
	vData condloop%ptrconditionsloops
	call getcontandcontReg(condloop,#structure,#regnr)
	if regnr!=0
		sd start;set start structure
		add structure regnr
		while start!=structure
			sd type
			sub structure (dwsz)
			set type structure#
			if type!=(ifinscribe)
				sub structure (dwsz)
				if type==(whilenumber)
					sd err
					SetCall err condjump(0)
					if err==(noerror)
						SetCall err condbeginwrite((breaknumber))
					endif
					Return err
				endif
			endif
		endwhile
	endif
	return "There is no loop to break."
endfunction
