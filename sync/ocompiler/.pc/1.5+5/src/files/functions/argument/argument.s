
#sz
function getreturn(data ptrptrcontinuation)
	sd b;setcall b scope64_get()
	if b==(TRUE)
		sd conv;setcall conv convdata((convdata_total))
		if conv==(lin_convention)
			chars lin64_return={0xc9,0x5b}
			#pop c;add rsp,8*conv;push c
			chars *={0x59,REX_Operand_64,0x83,regregmod|espregnumber,lin_convention*qwsz,0x51}
			chars *=retcom
			set ptrptrcontinuation# #lin64_return
			return (2+6+1)
		endif
	endif
	Chars returncontinuation={0xc9,0x5b,retcom}
	str ptrreturncontinuation^returncontinuation
	data sizeretcontinuation=3
	set ptrptrcontinuation# ptrreturncontinuation
	return sizeretcontinuation
endfunction
#err
function getexit(sv ptrptrcontinuation,sd psizeofcontinuation)
	#if to keep rsp can be leave pop sub rsp,:

	#int 0x80, sys_exit, eax 1,ebx the return number
	chars sys_exit={0xb8,1,0,0,0}
	data exinit^sys_exit
	data exitsize=5
	Data codeptr%ptrcodesec
	sd err
	SetCall err addtosec(exinit,exitsize,codeptr)
	If err!=(noerror)
		Return err
	EndIf

	Chars unixcontinuation={intimm8,0x80}
	set ptrptrcontinuation# #unixcontinuation
	set psizeofcontinuation# 2
	return (noerror)
endfunction

#err
function argument_return(sd termswitch,ss pop,ss pimmop,sd pintegerreminder,sv pptrcontinuation,sd psizeofcontinuation,sd pregopcode)
	call setimm()
	Set pop# (moveatprocthemem)
	chars immtake=0xB8
	set pimmop# immtake
	Set pintegerreminder# (TRUE)

	if termswitch==(TRUE)
		data ebxregnumber=ebxregnumber
		set pregopcode# ebxregnumber
		add pimmop# ebxregnumber
		sd err
		setcall err getexit(pptrcontinuation,psizeofcontinuation)
		return err
	endif
	set pregopcode# (eaxregnumber)
	setcall psizeofcontinuation# getreturn(pptrcontinuation)
	return (noerror)
endfunction

#err
Function argument(data ptrcontent,data ptrsize,data subtype,data forwardORcallsens)
	Data false=FALSE
	Data true=TRUE

	Data regprepare_bool#1

	Chars op#1
	Data zero=0

	Str ptrcontinuation#1
	Data sizeofcontinuation#1

	Data codeptr%ptrcodesec
	Data regopcode#1

	Data err#1
	Data noerr=noerror
	chars immop#1

	Set regprepare_bool false
	Set sizeofcontinuation zero

	call unsetimm()
	Data forward=FORWARD
	If forwardORcallsens==forward
		If subtype==(cRETURN)
			sd termswitch
			setcall termswitch is_linux_end() #exit from linux term
			setcall err argument_return(termswitch,#op,#immop,#regprepare_bool,#ptrcontinuation,#sizeofcontinuation,#regopcode)
			If err!=noerr
				Return err
			EndIf
		ElseIf subtype==(cNOT)
			Chars not={0xF7}
			Chars notregopcode={Notregopcode}
			Set op not
			Set regopcode notregopcode
		ElseIf subtype==(cINC)
			Chars inc={0xFF}
			Set op inc
			set regopcode 0
		ElseIf subtype==(cDEC)
			Chars dec={0xFF}
			Chars decregopcode={1}
			Set op dec
			Set regopcode decregopcode
		ElseIf subtype<=(cDECST)
			set op (0x83)
			if subtype==(cINCST)
				set regopcode 0
			else
				set regopcode 5
			endelse
			chars incs_sz#1
			sd b;setcall b is_for_64()
			if b==(FALSE);set incs_sz (dwsz)
			else;set incs_sz (qwsz);endelse
			set ptrcontinuation #incs_sz
			set sizeofcontinuation (bsz)
		ElseIf subtype==(cEXIT)
			setcall err argument_return((TRUE),#op,#immop,#regprepare_bool,#ptrcontinuation,#sizeofcontinuation,#regopcode)
			If err!=noerr
				Return err
			EndIf
		ElseIf subtype==(cNEG)
			set op (0xf7)
			set regopcode 3
		Else
			set op (0xD1)
			If subtype==(cSHL)
				set regopcode 4
			ElseIf subtype==(cSHR)
				set regopcode 5
			Else
			#cSAR
				set regopcode 7
			EndElse
		EndElse
	Else
	#push imm prepare test
		call setimm()
		chars immpush=0x68
		set immop immpush
	EndElse

	Data lowbyte#1
	Data ptrlowbyte^lowbyte
	Data dataarg#1
	Data ptrdataarg^dataarg
	Data sufix#1
	Data ptrsufix^sufix

	SetCall err arg(ptrcontent,ptrsize,ptrdataarg,ptrlowbyte,ptrsufix,forwardORcallsens)
	If err!=noerr
		Return err
	EndIf

	sd imm
	setcall imm getisimm()
	if imm==false
		Data noreg=noregnumber
		Data eaxreg=eaxregnumber
		Data intchar#1
		Set intchar noreg
		If forwardORcallsens!=forward
		#push
			#If lowbyte==false
			#since with 64 push data will push quad even without rex
			#	Chars push={0xff}
			#	Chars pushopcode={6}
			#	Set op push
			#	Set regopcode pushopcode
			#	call stack64_op_set()
			#Else
			If lowbyte==true
				#prepare for eax for al
				Set intchar eaxreg
			EndIf
			Chars pushaction={moveatprocthemem}
			Set op pushaction
			set regopcode (eaxregnumber)

			chars pushadvance={0x50}
			data pushcontinuationsize=1
			data ptrpushcontinuation^pushadvance
			Set ptrcontinuation ptrpushcontinuation
			set sizeofcontinuation pushcontinuationsize
			#EndElse
		EndIf
		If lowbyte==true
		#imm don't use one byte at the moment
			Dec op
			If regprepare_bool==true
				Set intchar regopcode
			EndIf
		EndIf
		SetCall err writeop(dataarg,op,intchar,sufix,regopcode,lowbyte)
		call restore_argmask() #before this there is no err!=noerr: it is not a must, only less space
	Else
	#imm push/return/exit
		set op immop
		setcall err write_imm(dataarg,op)
	EndElse
	If err!=noerr
		Return err
	EndIf
	If sizeofcontinuation!=zero
		#return / exit / (only at noimm):incst/push
		SetCall err addtosec(ptrcontinuation,sizeofcontinuation,codeptr)
		return err
	EndIf
	Return noerr
endfunction
