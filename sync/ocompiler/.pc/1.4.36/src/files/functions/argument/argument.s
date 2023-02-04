
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
Function argument(data ptrcontent,data ptrsize,data subtype,data forwardORcallsens)
	Data false=FALSE
	Data true=TRUE

	Data noreg=noregnumber
	Data eaxreg=eaxregnumber
	Data intchar#1
	Set intchar noreg

	Data integerreminder#1
	Set integerreminder false

	Chars op#1
	Data zero=0

	Str ptrcontinuation#1
	Data sizeofcontinuation#1
	data ptrptrcontinuation^ptrcontinuation

	Set sizeofcontinuation zero

	Data codeptr%ptrcodesec
	Data regopcode#1

	Data err#1
	Data noerr=noerror
	chars immop#1
	chars immtake=0xB8

	call unsetimm()
	Data forward=FORWARD
	If forwardORcallsens==forward
		sd termswitch=FALSE
		if subtype==(cEXIT)
			set subtype (cRETURN)
			set termswitch (TRUE)
		endif
		If subtype==(cRETURN)
			call setimm()
			set immop immtake
			Set integerreminder true
			Set op (moveatprocthemem)

			if termswitch==(FALSE)
				#exit from linux term
				setcall termswitch is_linux_end()
			endif

			if termswitch==true
				#if to keep rsp can be leave pop sub rsp,:

				#int 0x80, sys_exit, eax 1,ebx the return number
				chars sys_exit={0xb8,1,0,0,0}
				data exinit^sys_exit
				data exitsize=5
				SetCall err addtosec(exinit,exitsize,codeptr)
				If err!=noerr
					Return err
				EndIf

				#
				data ebxregnumber=ebxregnumber
				set regopcode ebxregnumber

				add immop ebxregnumber

				#
				Chars unixcontinuation={intimm8,0x80}
				data ptrunixcontinuation^unixcontinuation
				Data two=2
				Set ptrcontinuation ptrunixcontinuation
				set sizeofcontinuation two
			else
				set regopcode (eaxregnumber)
				setcall sizeofcontinuation getreturn(ptrptrcontinuation)
			endelse
			#fileformat#
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
		If forwardORcallsens!=forward
		#push
			If lowbyte==false
				Chars push={0xff}
				Chars pushopcode={6}
				Set op push
				Set regopcode pushopcode
				call stack64_op_set()
			Else
				Set intchar eaxreg
				Chars pushaction={moveatprocthemem}
				Set op pushaction
				set regopcode (eaxregnumber)

				chars pushadvance={0x50}
				data pushcontinuationsize=1
				data ptrpushcontinuation^pushadvance
				Set ptrcontinuation ptrpushcontinuation
				set sizeofcontinuation pushcontinuationsize
			EndElse
		EndIf
	Else
	#imm
		set op immop
	EndElse

	If lowbyte==true
		Dec op
		If integerreminder==true
			Set intchar regopcode
		EndIf
	EndIf

	if imm==true
		setcall err write_imm(dataarg,op)
	else
		SetCall err writeop(dataarg,op,intchar,sufix,regopcode,lowbyte)
		call restore_argmask()
	endelse
	If err!=noerr
		Return err
	EndIf

	If sizeofcontinuation!=zero
		SetCall err addtosec(ptrcontinuation,sizeofcontinuation,codeptr)
		return err
	EndIf

	return noerr

endfunction

