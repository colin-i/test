
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

	sd big;sd rem
	If ptrcondition==false
		#imm second arg
		call setimm()
		sd subtype_test;set subtype_test subtype;and subtype_test (x_call_flag)
		if subtype_test!=0
			xor subtype (x_call_flag)
			Set primcalltype true
		endif
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
			if lowprim==(FALSE);setcall big is_big(dataargprim,sufixprim)
			else;set big (FALSE);endelse
			if subtype==(cREM);set rem (TRUE)
			else;set rem (FALSE);endelse
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
			Dec opprim
			if subtype!=(cCALLEX)
				#at callex they can be different
				Dec opsec
			elseif lowsec==true
				dec opsec
			endelseif
		ElseIf lowsec==true
			Dec opsec
			If sameimportant==true
				Set intchar regprep
			Else
				Dec opprim
			EndElse
		EndElseIf
	Else
		sd store_big;set store_big (FALSE)
		If lowprim==lowsec
			If lowprim==true
				Dec opprim
				Dec opsec
			else
			#this code with the rex promotes, if this near comp later,undefined dataargsec(1==1)will go wrong in is_big, viol
				setcall imm getisimm()
				if imm==false
				#it is 1==big/medium
					setcall store_big is_big(dataargsec,sufixsec)
				endif
			endelse
		Else
			Dec opsec
			Set intchar eaxreg
			If lowprim==true
				#case compare low vs high, then: get low on all eax compare with high but op from mem vs proc becomes proc vs mem
				#note that xor eax,eax will zero rax (not needing xor rax,rax)
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
				#and for ss#
				set aux lowprim;set lowprim lowsec;set lowsec aux
				#and char==#sd
				set aux remind_first_prefix;set remind_first_prefix p_prefix#;set p_prefix# aux
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
			SetCall errnr write_imm(dataargsec,opsec)
		else
			if p_prefix#==(FALSE)
				SetCall errnr writeop(dataargsec,opsec,intchar,sufixsec,regopcode,lowsec)
			else
			#only take at prefix on regcode
				call writeoperation_take(#errnr,dataargsec,sufixsec,regopcode,lowsec)
				#pprefix is reset in the road at remind
			endelse
		endelse
		If errnr!=noerr
			Return errnr
		EndIf
	Elseif divmul==(TRUE)
		#only at multcall and divcall
		chars transferreturntoecx={0x89,0xc1}
		str ptrcall^transferreturntoecx
		data calltransfersize=2
		if big==(TRUE)
			call rex_w(#errnr)
			If errnr!=noerr;Return errnr;EndIf
		endif
		setcall errnr addtosec(ptrcall,calltransfersize,codeptr)
		If errnr!=noerr
			Return errnr
		EndIf
	EndElseif

	#write first arg, the second already was
	set p_prefix# remind_first_prefix
	call restorefirst_isimm()
	setcall imm getisimm()
	if imm==true
		#first argument imm are comparations
		#first value is imm, or second value is imm (switched)
		SetCall errnr write_imm(dataargprim,(0xb8+ecxregnumber))
	else
		SetCall errnr writeop_prim(dataargprim,opprim,sufixprim,lowprim,sameimportant,lowsec)
	endelse
	If errnr!=noerr
		Return errnr
	EndIf

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
			Chars d3_0=0x79;chars d3_1#1
			Chars d4_0#1
			Chars d4_1#1

			Const bitsedxregop=edxregnumber*8
			Const bitsahregop=ahregnumber*8
			Const bitsnotop=Notregopcode*8

			Const pre1_1_h=regregmod|bitsedxregop|edxregnumber
			Chars predef1_1_high={pre1_1_h}
			Const pre4_1_h=regregmod|bitsnotop|edxregnumber
			Chars predef4_1_high={pre4_1_h}
			Const pre1_1_l=regregmod|bitsahregop|ahregnumber
			Chars predef1_1_low={pre1_1_l}
			Const pre4_1_l=regregmod|bitsnotop|ahregnumber
			Chars predef4_1_low={pre4_1_l}

			Chars d1_0ini={0x33}
			Chars d2_0ini={0x85}
			Chars d4_0ini={0xf7}

			Set d1_0 d1_0ini
			Set d2_0 d2_0ini
			Set d4_0 d4_0ini

			If lowprim==false
				Set	d1_1 predef1_1_high
				Set	d4_1 predef4_1_high
			Else
				Dec d1_0
				Dec d2_0
				Dec d4_0
				Set d1_1 predef1_1_low
				Set d4_1 predef4_1_low
			EndElse
			SetCall errnr addtosec(#d1_0,2,codeptr);If errnr!=noerr;Return errnr;EndIf
			if big==(TRUE)
				call rex_w(#errnr)
				If errnr!=noerr;Return errnr;EndIf
			endif
			SetCall errnr addtosec(#d2_0,2,codeptr);If errnr!=noerr;Return errnr;EndIf
			if big==(TRUE)
				set d3_1 3
				SetCall errnr addtosec(#d3_0,2,codeptr);If errnr!=noerr;Return errnr;EndIf
				call rex_w(#errnr)
				If errnr!=noerr;Return errnr;EndIf
			else
				set d3_1 2
				SetCall errnr addtosec(#d3_0,2,codeptr);If errnr!=noerr;Return errnr;EndIf
			endelse
			SetCall errnr addtosec(#d4_0,2,codeptr);If errnr!=noerr;Return errnr;EndIf
		EndElse

		Chars opcodexini={0xF7}
		Chars opcodeex#1
		Chars modrmex#1
		Data sizeex=2
		Str ptropcodeex^opcodeex
		Chars storeex#1
		chars storeexrm#1

		Set opcodeex opcodexini
		Set storeex atmemtheproc

		If lowprim==true
			Dec opcodeex
			Dec storeex
		EndIf

		SetCall modrmex formmodrm(regreg,regopcodeex,ecxreg)
		Set regopcodeex modrmex

		if big==(TRUE)
			call rex_w(#errnr)
			If errnr!=noerr;Return errnr;EndIf
		endif
		SetCall errnr addtosec(ptropcodeex,sizeex,codeptr)
		If errnr!=noerr
			Return errnr
		EndIf

		if lowprim==(TRUE)
		# str# ss# chars
		#rdx is ready
			if rem==(FALSE)
				setcall storeexrm formmodrm((mod_0),eaxreg,(edxregnumber))
			else
				setcall storeexrm formmodrm((mod_0),(ahregnumber),(edxregnumber))
			endelse
			setcall errnr addtosec(#storeex,2,codeptr)
		else
			if rem==(FALSE)
				SetCall errnr writeop(dataargprim,storeex,noreg,sufixprim,eaxreg,lowprim)
			else
				SetCall errnr writeoperation(dataargprim,storeex,noreg,sufixprim,(edxregnumber),ecxreg,lowprim)
			endelse
		endelse
	ElseIf ptrcondition!=false
		if imm==true
			#first imm true only at comparations
			#continue to write the imm comparation(first is imm, second doesnt care)ex: 1(constant)==1(constant)->cmp ecx,eax (eax,ecx can be if switch)
			chars immcompdata#1
			set immcompdata compimmop
			chars *immcompdatamodrm=0xc1
			str immcomp^immcompdata
			data immcompsz=2
			if store_big==(TRUE)
				call rex_w(#errnr)
				If errnr!=noerr;Return errnr;EndIf
			endif
			SetCall errnr addtosec(immcomp,immcompsz,codeptr)
			If errnr!=noerr
				Return errnr
			EndIf
		endif

		Chars jumpifnotcond={0x0f}
		Chars cond#1
		#this will be resolved at endcond
		Data *jump#1

		Data jumpcond^jumpifnotcond
		Data conddatasz=6

		Set cond conditionmodrm

		SetCall errnr addtosec(jumpcond,conddatasz,codeptr)
	EndElseIf
	Return errnr
EndFunction

function writeop_prim(sd dataargprim,sd opprim,sd sufixprim,sd lowprim,sd sameimportant,sd lowsec)
	sd err
	if sameimportant==(FALSE)
		if lowsec==(TRUE)
			#this is and/or... at sd low not needing to write rex
			call writeoperation_take(#err,dataargprim,sufixprim,(edxregnumber),lowprim)
			if err!=(noerror);return err;endif
			setcall err writeoperation_op(opprim,(noregnumber),(eaxregnumber),(edxregnumber))
			return err
		endif
	endif
	SetCall err writeop(dataargprim,opprim,(noregnumber),sufixprim,(eaxregnumber),lowprim)
	return err
endfunction