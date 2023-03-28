

Const addNumber=asciiplus
Const subNumber=asciiminus
Const mulNumber=asciiast
Const divNumber=asciislash
Const andNumber=asciiand
Const orNumber=asciivbar
Const xorNumber=asciicirc
Const powNumber=asciidollar
Const remNumber=asciipercent
Const lessNumber=asciiless
Const greaterNumber=asciigreater
Const shlNumber=asciicomma
Const sarNumber=asciidot
#asciiminus and asciinot for one arg

#err
function const_security(sd item)
	#2$31 is last one
	#1 shl 63 is last one
	#maximum first overflow, ok
	#why not 32 or 33? this check only stops evil big numbers
	sd maximum=qwsz*8-1
	if item#>maximum
		str err="Overflow at constants."
		sd w%p_w_as_e
		if w#==(TRUE)
			sd p%p_over_pref
			if p#==(TRUE)
				return err
			endif
		endif
		call Message(err)
		set item# maximum
	endif
	return (noerror)
endfunction
#err
function shift_right(sd a,sd n)
	sd err
	setcall err const_security(#n)
	If err!=(noerror);return err;endif
	while n>0
		dec n
		sar a#
	endwhile
	return (noerror)
endfunction
#err
function shift_left(sd a,sd n)
	sd err
	setcall err const_security(#n)
	If err!=(noerror);return err;endif
	while n>0
		dec n
		shl a#
	endwhile
	return (noerror)
endfunction

#err pointer
Function operation(ss content,sd size,sd inoutvalue,sd number)
	sd newitem
	sd ptrnewitem^newitem
	sd errptr
	Data noerr=noerror

	if content#!=(asciiparenthesisstart)
		#not needing set newitem 0
		SetCall errptr numbersconstants(content,size,ptrnewitem)
	else
		inc content;sub size 2
		setcall errptr parseoperations(#content,#size,size,ptrnewitem,(FALSE))
	endelse
	If errptr!=noerr;Return errptr;EndIf

	setcall errptr operation_core(inoutvalue,number,newitem)
	return errptr
EndFunction

#err
function operation_core(sd inoutvalue,sd number,sd newitem)
	sd errptr
	sd currentitem
	Set currentitem inoutvalue#
	If number==(addNumber)
		Add currentitem newitem
	ElseIf number==(subNumber)
		Sub currentitem newitem
	ElseIf number==(mulNumber)
		Mult currentitem newitem
	ElseIf number==(divNumber)
		Data zero=0
		If newitem==zero
			Char zerodiv="Division by 0 error."
			Str ptrzerodiv^zerodiv
			Return ptrzerodiv
		EndIf
		Div currentitem newitem
	ElseIf number==(andNumber)
		And currentitem newitem
	ElseIf number==(orNumber)
		Or currentitem newitem
	ElseIf number==(xorNumber)
		Xor currentitem newitem
	ElseIf number==(powNumber)
		if newitem<0
			if currentitem==0
				#is 1/(0 power n)
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
			SetCall errptr const_security(#newitem)
			If errptr!=(noerror);return errptr;endif
			sd item;set item currentitem
			while newitem!=1
				mult currentitem item
				dec newitem
			endwhile
		endelse
	ElseIf number==(remNumber)
		If newitem==zero
			Return ptrzerodiv
		EndIf
		Rem currentitem newitem
	ElseIf number==(shlNumber)
		if newitem<0
			neg newitem
			SetCall errptr shift_right(#currentitem,newitem)
		else
			SetCall errptr shift_left(#currentitem,newitem)
		endelse
		If errptr!=(noerror);return errptr;endif
	ElseIf number==(sarNumber)
		if newitem<0
			neg newitem
			SetCall errptr shift_left(#currentitem,newitem)
		else
			SetCall errptr shift_right(#currentitem,newitem)
		endelse
		If errptr!=(noerror);return errptr;endif
	ElseIf number==(lessNumber)
		if currentitem<newitem
			set currentitem (TRUE)
		else
			set currentitem (FALSE)
		endelse
	Else
	#If number==(greaterNumber)
		if currentitem>newitem
			set currentitem (TRUE)
		else
			set currentitem (FALSE)
		endelse
	EndElse

	Set inoutvalue# currentitem
	Return (noerror)
endfunction

#bool
Function signop(char byte,sd outval)
	Data false=FALSE
	Data true=TRUE

	If byte==(addNumber)
	ElseIf byte==(subNumber)
	ElseIf byte==(mulNumber)
	ElseIf byte==(divNumber)
	ElseIf byte==(andNumber)
	ElseIf byte==(orNumber)
	ElseIf byte==(xorNumber)
	ElseIf byte==(powNumber)
	ElseIf byte==(remNumber)
	ElseIf byte==(lessNumber)
	ElseIf byte==(greaterNumber)
	Else
		return false
	EndElse
	set outval# byte
	Return true
EndFunction

#err
Function oneoperation(sd ptrcontent,ss initial,ss content,sd val,sd op)
	sd size
	sd errptr
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
Function parseoperations(sd ptrcontent,sd ptrsize,sd sz,sd outvalue,sd comments)
	ss content
	ss initial
	sd number
	sd val
	sd ptrval^val
	Data zero=0
	sd errptr
	Data noerr=noerror

	Set content ptrcontent#

	Set initial content
	Set number (addNumber)
	Set val zero

	sd bool
	Data false=FALSE
	Data true=TRUE
	sd nr
	sd pnr^nr
	sd find

	sd end;set end content;add end sz

	Set bool false
	#<end?maybe unsigned cursor
	While content!=end
		SetCall find signop(content#,pnr)
		if find==true
			If initial!=content
				SetCall errptr oneoperation(ptrcontent,initial,content,ptrval,number)
				If errptr!=noerr
					Return errptr
				EndIf
				call doubleoperation(pnr,#content,end)
				set number nr
				Set bool true
			EndIf
		elseif content#==(asciiparenthesisstart)
			inc content
			sd rest_sz;set rest_sz end;sub rest_sz content
			sd insz
			setcall errptr parenthesis_size(content,rest_sz,#insz)
			if errptr!=(noerror);return errptr;endif
			add content insz
		endelseif

		Inc content
		If bool==true
			setcall content mem_spaces(content,end)
			Set initial content
			Set bool false
		EndIf
	EndWhile

	#allow line end comment
	if comments==(TRUE)
		sd szz
		set szz end;sub szz initial
		sd size
		setcall size find_whitespaceORcomment(initial,szz)
		sub szz size
		sub content szz
	endif
	#oneoperation is with cursor adjuster for errors
	SetCall errptr oneoperation(ptrcontent,initial,content,ptrval,number)
	If errptr!=noerr
		Return errptr
	EndIf
	Set outvalue# val

	if comments==(TRUE)
		sub sz szz
	endif
	Call advancecursors(ptrcontent,ptrsize,sz)
	Return noerr
EndFunction

function doubleoperation(ss pnr,sv pcontent,sd end)
	sd nr;set nr pnr#
	if nr!=(lessNumber)
		if nr!=(greaterNumber)
			ret
		endif
	endif
	ss content;set content pcontent#
	inc content
	if content==end
		ret  #error is catched how was before
	endif
	if content#==(lessNumber)
		if nr==(lessNumber)
			set pnr# (shlNumber)
			inc pcontent#
			ret
		endif
	endif
	if content#==(greaterNumber)
		if nr==(greaterNumber)
			set pnr# (sarNumber)
			inc pcontent#
		endif
	endif
endfunction
