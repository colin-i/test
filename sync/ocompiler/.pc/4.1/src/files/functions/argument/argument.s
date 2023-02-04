

function getreturn(data ptrptrcontinuation)
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

	data termswitch#1
	set termswitch false
	if subtype==(cEXIT)
		set termswitch true
		set subtype (cRETURN)
	endif

	Data codeptr%ptrcodesec
	Data regopcode#1
	
	Data err#1
	Data noerr=noerror
	chars immop#1
	chars immtake=0xB8

	call unsetimm()
	Data forward=FORWARD
	If forwardORcallsens==forward
		If subtype==(cRETURN)
			call setimm()
			set immop immtake

			Chars return={moveatprocthemem}

			setcall sizeofcontinuation getreturn(ptrptrcontinuation)

			Set op return
			set regopcode (eaxregnumber)
			Set integerreminder true

			#not cEXIT
			if termswitch==(FALSE)
				setcall termswitch is_linux_end();endif
			if termswitch==true
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
				Chars unixcontinuation={0xCD,0x80}
				data ptrunixcontinuation^unixcontinuation
				Data two=2
				Set ptrcontinuation ptrunixcontinuation
				set sizeofcontinuation two
			endif
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
		ElseIf subtype==(cINCST)
			set op (0x83)
			set regopcode 0
			chars incs_sz#1
			sd b;setcall b is_for_64()
			if b==(FALSE);set incs_sz (dwsz)
			else;set incs_sz (qwsz);endelse
			set ptrcontinuation #incs_sz
			set sizeofcontinuation (bsz)
		Else
		#dec
			Chars dec={0xFF}
			Chars decregopcode={1}
			Set op dec
			Set regopcode decregopcode
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
			Set intchar eaxreg
		EndIf
	EndIf
	
	SetCall err writeop_immfilter(dataarg,op,intchar,sufix,regopcode)
	If err!=noerr
		Return err
	EndIf

	If sizeofcontinuation!=zero
		SetCall err addtosec(ptrcontinuation,sizeofcontinuation,codeptr)
		return err
	EndIf
	
	return noerr

endfunction

