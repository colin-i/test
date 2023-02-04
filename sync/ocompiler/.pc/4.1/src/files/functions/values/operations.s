

Const addNumber=0
Const subNumber=1
Const mulNumber=2
Const divNumber=3
Const andNumber=4
Const orNumber=5
Const xorNumber=6
Const powNumber=7

#err pointer
Function operation(str content,data size,data inoutvalue,data number)
	Data newitem#1
	Data ptrnewitem^newitem
	Data initialnewitem=0
	Data errptr#1
	Data noerr=noerror

	Set newitem initialnewitem
	SetCall errptr numbersconstants(content,size,ptrnewitem)
	If errptr!=noerr
		Return errptr
	EndIf

	Data addnumber=addNumber
	Data subnumber=subNumber
	Data mulnumber=mulNumber
	Data divnumber=divNumber
	Data andnumber=andNumber
	Data ornumber=orNumber
	Data xornumber=xorNumber

	Data currentitem=0
	Set currentitem inoutvalue#
	If number==addnumber
		Add currentitem newitem
	ElseIf number==subnumber
		Sub currentitem newitem
	ElseIf number==mulnumber
		Mult currentitem newitem
	ElseIf number==divnumber
		Data zero=0
		If newitem==zero
			Chars zerodiv="Division by 0 error."
			Str ptrzerodiv^zerodiv
			Return ptrzerodiv
		EndIf
		Div currentitem newitem
	ElseIf number==andnumber
		And currentitem newitem
	ElseIf number==ornumber
		Or currentitem newitem
	ElseIf number==xornumber
		Xor currentitem newitem
	Else
		if newitem<0
			if currentitem==0
				#is 0 power -n
				Return ptrzerodiv
			elseif currentitem==1
				#is 1/(1 power n)
			else
				#is 1/(>1)
				set currentitem 0
			endelse
		elseif newitem==0
			set currentitem 1
		else
			sd item
			set item currentitem
			while newitem!=1
				mult currentitem item
				dec newitem
			endwhile
		endelse
	EndElse

	Set inoutvalue# currentitem
	Return noerr
EndFunction

#bool
Function signop(chars byte,data outval)
	Chars plus={asciiplus}
	Chars minus={asciiminus}

	Chars mult={asciiast}
	Chars div={asciislash}
	
	Chars and={asciiand}
	Chars or={asciivbar}
	Chars xor={asciicirc}
	
	Chars pow="$"

	Data addnumber=addNumber
	Data subnumber=subNumber
	Data mulnumber=mulNumber
	Data divnumber=divNumber
	Data andnumber=andNumber
	Data ornumber=orNumber
	Data xornumber=xorNumber
	Data pownumber=powNumber

	Data false=FALSE
	Data true=TRUE

	If byte==plus
		Set outval# addnumber
		Return true
	ElseIf byte==minus
		Set outval# subnumber
		Return true
	ElseIf byte==mult
		Set outval# mulnumber
		Return true
	ElseIf byte==div
		Set outval# divnumber
		Return true
	ElseIf byte==and
		Set outval# andnumber
		Return true
	ElseIf byte==or
		Set outval# ornumber
		Return true
	ElseIf byte==xor
		Set outval# xornumber
		Return true
	ElseIf byte==pow
		Set outval# pownumber
		Return true
	EndElseIf
	
	Return false
EndFunction

#err
Function oneoperation(data ptrcontent,str initial,str content,data val,data op)
	Data size#1
	Data errptr#1
	Data noerr=noerror

	Set size content
	Sub size initial

	SetCall errptr operation(initial,size,val,op)
	If errptr!=noerr
		Set ptrcontent# initial
		Return errptr
	EndIf
	Return noerr
EndFunction

#err pointer
Function parseoperations(data ptrcontent,data ptrsize,data sz,data outvalue)
	Str content#1
	Str initial#1
	Data number#1
	Data val#1
	Data ptrval^val
	Data zero=0
	Data errptr#1
	Data noerr=noerror

	Set content ptrcontent#

	Set initial content
	Set number zero
	Set val zero

	Data bool#1
	Data false=FALSE
	Data true=TRUE
	Data nr#1
	Data pnr^nr
	Chars byte#1
	Data find#1
	
	Data opsize#1
	Set opsize sz

	While sz!=zero
		Set bool false
		Set byte content#
		SetCall find signop(byte,pnr)
		If find==true
			If initial!=content
				SetCall errptr oneoperation(ptrcontent,initial,content,ptrval,number)
				If errptr!=noerr
					Return errptr
				EndIf
				Set bool true
				Set number nr
			EndIf
		EndIf
		Inc content
		Dec sz
		If bool==true
			Data p_content^content
			Data p_sz^sz
			Call spaces(p_content,p_sz)

			Set initial content
		EndIf
	EndWhile

	SetCall errptr oneoperation(ptrcontent,initial,content,ptrval,number)
	If errptr!=noerr
		Return errptr
	EndIf
	Set outvalue# val

	Call advancecursors(ptrcontent,ptrsize,opsize)
	Return noerr
EndFunction