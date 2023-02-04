

#err
Function twoargs(data ptrcontent,data ptrsize,data subtype,data ptrcondition)
	Data lowprim#1
	Data ptrlowprim^lowprim
	Data lowsec#1
	Data ptrlowsec^lowsec
	Data dataargprim#1
	Data ptrdataargprim^dataargprim
	Data dataargsec#1
	Data ptrdataargsec^dataargsec

	Data sufixprim#1
	Data sufixsec#1
	Data ptrsufixprim^sufixprim
	Data ptrsufixsec^sufixsec

	Data false=FALSE
	Data true=TRUE

	Data noreg=noregnumber
	Data eaxreg=eaxregnumber
	Data ecxreg=ecxregnumber
	
	Data intchar#1
	Set intchar noreg

	Data sameimportant#1
	Set sameimportant true
	
	Chars opprim#1
	Chars opsec#1
	Chars atprocthemem={moveatprocthemem}
	Chars atmemtheproc={moveatmemtheproc}
	Set opsec atprocthemem
	
	Data divmul#1
	Set divmul false
	Data regprep#1
	Set regprep eaxreg
	Data regopcode#1
	Set regopcode eaxreg

	sd imm
	call unsetimm()
	Data errnr#1
	Data noerr=noerror
	SetCall errnr argfilters(ptrcondition,ptrcontent,ptrsize,ptrdataargprim,ptrlowprim,ptrsufixprim)
	If errnr!=noerr
		Return errnr
	EndIf
	#need to remind first prefix: p1 p2 need_p2 need_p1
	sd remind_first_prefix
	sd p_prefix
	setcall p_prefix prefix_bool()
	set remind_first_prefix p_prefix#
	set p_prefix# 0
	call storefirst_isimm()

	Data primcalltype#1
	Chars two=2

	Set primcalltype false
	If ptrcondition==false
		#imm second arg
		call setimm()
		sd subtype_test;set subtype_test subtype;and subtype_test (x_call_flag)
		if subtype_test!=0
			xor subtype (x_call_flag)
			Set primcalltype true
			if subtype==(cSETX)
				if lowprim==(TRUE)
					return "SetX is not encodable at an 8-bit argument."
				endif
				set subtype (cSET);call val64_phase_1()
			endif
		elseif subtype==(cSETX);return "SetX is used at SetXCall only.64 bit variables are not available at the moment."
		endelseif
		if subtype==(cSET)
			Set opprim atmemtheproc
		ElseIf subtype==(cADD)
			Chars addprim={0x01}
			Set opprim addprim
		ElseIf subtype==(cSUB)
			Chars subprim={0x29}
			Set opprim subprim
		ElseIf subtype<(cAND)
			Set opprim atprocthemem
			Set regprep ecxreg
			Set regopcode ecxreg
			Set divmul true
		ElseIf subtype<=(cXOR)
			Set sameimportant false
			If subtype==(cAND)
				Chars andprim={0x21}
				Set opprim andprim
			ElseIf subtype==(cOR)
				Chars orprim={0x09}
				Set opprim orprim
			Else
			#(cXOR)
				Chars xorprim={0x31}
				Set opprim xorprim
			EndElse
		Else
		#(cCALLEX)
			Set opprim atprocthemem
			Set regprep ecxreg
			Set regopcode ecxreg
		EndElse
	Else
		Data sz#1
		Data condition#1
		Set condition ptrcondition#
		SetCall sz strlen(condition)
		Add condition sz
		Call advancecursors(ptrcontent,ptrsize,sz)

		Data one=1
		Add condition one

		Data conditionmodrm#1
		Set conditionmodrm condition#

		Chars compare=0x39
		Set opprim compare

		#imm specific
		chars compimminitial={0x39}
		chars compimmop#1
		set compimmop compimminitial
	EndElse
	
	If primcalltype==false
		SetCall errnr arg(ptrcontent,ptrsize,ptrdataargsec,ptrlowsec,ptrsufixsec,true)
		If errnr!=noerr
			Return errnr
		EndIf
	Else
		Data callfn=callfunction
		SetCall errnr parsefunction(ptrcontent,ptrsize,callfn)
		If errnr!=noerr
			Return errnr
		EndIf
	EndElse

	If ptrcondition==false
		If lowprim==true
			Dec opsec
			Dec opprim
		ElseIf lowsec==true
			Dec opsec
			If sameimportant==true
				Set intchar regprep
			Else
				Dec opprim
			EndElse
		EndElseIf
	Else
		If lowprim==lowsec
			If lowprim==true
				Dec opprim
				Dec opsec
			EndIf
		Else
			Dec opsec
			Set intchar eaxreg
			If lowprim==true
				#case compare low vs high, then: get low on all eax compare with high but op from mem vs proc becomes proc vs mem
				Add opprim two
				Data aux#1
				Set aux dataargprim
				Set dataargprim dataargsec
				Set dataargsec aux
				Set aux sufixprim
				Set sufixprim sufixsec
				Set sufixsec aux
				call switchimm()
				add compimmop two
			EndIf
		EndElse
	EndElse
	
	Data codeptr%ptrcodesec

	If primcalltype==false
		setcall imm getisimm()
		if imm==true
			chars immtake=0xB8
			set opsec immtake
			if divmul==(TRUE)
				add opsec 1
			elseif subtype==(cCALLEX)
				add opsec 1
			endelseif
		endif
		SetCall errnr writeop_immfilter(dataargsec,opsec,intchar,sufixsec,regopcode)
		If errnr!=noerr
			Return errnr
		EndIf
	Else
		if divmul==(TRUE)
			#only at multcall and divcall
			chars transferreturntoecx={0x89,0xc1}
			str ptrcall^transferreturntoecx
			data calltransfersize=2
			setcall errnr addtosec(ptrcall,calltransfersize,codeptr)
			If errnr!=noerr
				Return errnr
			EndIf
		else
			call val64_phase_2()
		endelse
	EndElse
	
	#write first arg, the second already was
	set p_prefix# remind_first_prefix
	call restorefirst_isimm()
	setcall imm getisimm()
	if imm==true
	#comparations
		#first value is imm or was the switch
		chars immcomparationtake=0xb9
		set opprim immcomparationtake
	endif
	SetCall errnr writeop_immfilter(dataargprim,opprim,noreg,sufixprim,eaxreg)
	If errnr!=noerr
		Return errnr
	EndIf
	if imm==true
		#continue to write the imm comparation(first is imm, second doesnt care)ex: 1(constant)==1(constant)->cmp ecx,eax (eax,ecx can be if switch)
		chars immcompdata#1
		set immcompdata compimmop
		chars *immcompdatamodrm=0xc1
		str immcomp^immcompdata
		data immcompsz=2
		SetCall errnr addtosec(immcomp,immcompsz,codeptr)
		If errnr!=noerr
			Return errnr
		EndIf
	endif

	If divmul==true
		Data regreg=RegReg

		Chars regopcodemult={5}
		Chars regopcodediv={7}
		Chars regopcodeex#1

		If subtype==(cMULT)
			Set regopcodeex regopcodemult
		Else
			Set regopcodeex regopcodediv
			#33D2 85c0 7902 f7d2
			#32E4 84c0 7902 f6d4
			Chars d1_0#1
			Chars d1_1#1
			Chars d2_0#1
			Chars *d2_1={0xc0}
			Chars *d3={0x79,0x02}
			Chars d4_0#1
			Chars d4_1#1
			
			Const bitsregreg=RegReg*8*8
			Const bitsedxregop=edxregnumber*8
			Const bitsahregop=ahregnumber*8
			Const bitsnotop=Notregopcode*8

			Const pre1_1_h=bitsregreg|bitsedxregop|edxregnumber
			Chars predef1_1_high={pre1_1_h}
			Const pre4_1_h=bitsregreg|bitsnotop|edxregnumber
			Chars predef4_1_high={pre4_1_h}
			Const pre1_1_l=bitsregreg|bitsahregop|ahregnumber
			Chars predef1_1_low={pre1_1_l}
			Const pre4_1_l=bitsregreg|bitsnotop|ahregnumber
			Chars predef4_1_low={pre4_1_l}

			Str setdivsign^d1_0
			Data divsignsize=8

			Chars d1_0ini={0x33}
			Chars d2_0ini={0x85}
			Chars d4_0ini={0xf7}

			Set d1_0 d1_0ini
			Set d2_0 d2_0ini
			Set d4_0 d4_0ini

			If lowprim==false
				Set d1_1 predef1_1_high
				Set d4_1 predef4_1_high
			Else
				Dec d1_0
				Dec	d2_0
				Dec d4_0
				Set d1_1 predef1_1_low
				Set d4_1 predef4_1_low
			EndElse
			SetCall errnr addtosec(setdivsign,divsignsize,codeptr)
			If errnr!=noerr
				Return errnr
			EndIf
		EndElse

		Chars opcodexini={0xF7}
		Chars opcodeex#1
		Chars modrmex#1
		Data sizeex=2
		Str ptropcodeex^opcodeex
		Chars storeex#1

		Set opcodeex opcodexini
		Set storeex atmemtheproc

		If lowprim==true
			Dec opcodeex
			Dec storeex
		EndIf

		SetCall modrmex formmodrm(regreg,regopcodeex,ecxreg)
		Set regopcodeex modrmex

		SetCall errnr addtosec(ptropcodeex,sizeex,codeptr)
		If errnr!=noerr
			Return errnr
		EndIf

		SetCall errnr writeop(dataargprim,storeex,noreg,sufixprim,eaxreg)
		Return errnr
	ElseIf ptrcondition!=false
		Chars jumpifnotcond={0x0f}
		Chars cond#1
		Data *jump=0

		Data jumpcond^jumpifnotcond
		Data conddatasz=6

		Set cond conditionmodrm

		SetCall errnr addtosec(jumpcond,conddatasz,codeptr)
	EndElseIf
	Return errnr
EndFunction
