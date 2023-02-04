
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

	#Data noreg=noregnumber
	Data eaxreg=eaxregnumber
	Data ecxreg=ecxregnumber

	Chars opprim#1
	Chars opsec#1
	Chars atprocthemem={moveatprocthemem}
	Chars atmemtheproc={moveatmemtheproc}

	sd imm
	#call unsetimm()
	Data errnr#1
	Data noerr=noerror
	SetCall errnr argfilters(ptrcondition,ptrcontent,ptrsize,ptrdataargprim,ptrlowprim,ptrsufixprim)
	If errnr!=noerr
		Return errnr
	EndIf

	Data sameimportant#1
	Set sameimportant true
	Data divmul#1
	Set divmul false
	#Data regprep#1
	#Set regprep eaxreg
	Data regopcode#1
	Set regopcode eaxreg

	#need to remind first prefix: p1 p2 need_p2 need_p1
	sd remind_first_prefix
	sd p_prefix
	setcall p_prefix prefix_bool()

	set remind_first_prefix p_prefix#;set p_prefix# 0
	call storefirst_isimm()

	Data primcalltype#1
	Chars two=2

	Set primcalltype false

	#imm second arg can be
	call setimm()

	sd big;sd rem
	If ptrcondition==false
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
		ElseIf subtype<=(cREM)
			Set opprim atprocthemem
			#Set regprep ecxreg
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
			#Set regprep ecxreg
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

	#Data intchar#1
	data is_prepare#1
	set is_prepare (FALSE)
	#Set intchar noreg
	Set opsec atprocthemem

	If ptrcondition==false
		If lowprim==true
			Dec opprim
			if subtype!=(cCALLEX)
				#at callex they can be different
				Dec opsec
			else
			#if lowsec==true;dec opsec
				#it is not possible to push from ff...al and scalar push using full rcx*8 at normal (therefor same for ff...cl)
				return "Second argument at CALLEX must not be one byte."
			endelse
		ElseIf lowsec==true
			#Dec opsec
			If sameimportant==true
				#Set intchar regprep
				set is_prepare (TRUE)
			Else
				Dec opprim
				Dec opsec
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
			#Dec opsec
			#Set intchar eaxreg
			set is_prepare (TRUE)
			If lowprim==true
				#case compare low vs high, then: get low on all eax compare with high but op from mem vs proc becomes proc vs mem
				Add opprim two
				add compimmop two

				#note that xor eax,eax will zero rax (not needing xor rax,rax)
				Data aux#1
				Set aux dataargprim;Set dataargprim dataargsec;Set dataargsec aux
				Set aux sufixprim;Set sufixprim sufixsec;Set sufixsec aux
				call switchimm()
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
			#chars immtake=0xB8
			#set opsec immtake
			#if divmul==(TRUE)
			#	add opsec 1
			#elseif subtype==(cCALLEX)
			#	add opsec 1
			#endelseif
			SetCall errnr write_imm_sign(dataargsec,regopcode)
		else
			if p_prefix#==(FALSE)
				sd comp_at_bigs
				setcall imm getfirst_isimm()
				setcall comp_at_bigs comp_sec(lowsec,dataargprim,sufixprim,dataargsec,sufixsec,sameimportant,is_prepare,imm)
				setcall errnr writeop_promotes(dataargsec,opsec,sufixsec,regopcode,lowsec,comp_at_bigs)
			else
			#only take at prefix on regcode
				setcall errnr writetake(regopcode,dataargsec)
				#call writeoperation_take(#errnr,dataargsec,sufixsec,regopcode,lowsec)
				#pprefix is reset in the road at remind
			endelse
			call restore_argmask()
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

	#setcall imm getfirst_isimm() can be this but needing to deactivate imm slot
	setcall imm getisimm()
	if imm==true
		#first argument imm are comparations
		#first value is imm, or second value is imm (switched)
		SetCall errnr write_imm_sign(dataargprim,(ecxregnumber)) #0xb8+
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
			setcall errnr div_prepare(lowprim,big)
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
				SetCall errnr writeop(dataargprim,storeex,sufixprim,eaxreg,lowprim)
			else
				SetCall errnr writeoperation(dataargprim,storeex,sufixprim,(edxregnumber),ecxreg,lowprim)
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
	call restore_argmask() #this must be after primwrite and/or divmul
	Return errnr
EndFunction

#-1 normal, 0 unpromote, 1 sign extend, 2 zero extend
function comp_sec(sd lowsec,sd dataargprim,sd sufixprim,sd dataargsec,sd sufixsec,sd sameimportant,sd is_prepare,sd immprim)
	sd prim
	if lowsec==(FALSE)
		setcall prim is_big_imm(immprim,dataargprim,sufixprim)
		sd sec;setcall sec is_big(dataargsec,sufixsec)
		if prim!=sec
			if sec==(TRUE)
				#first is low/medium, don't promote the big second
				return 0
			elseif sameimportant==(TRUE)
				#first is big, second is medium, keep sign for second
				return 1
			endelseif
		endif
	elseif is_prepare==(TRUE)
		setcall prim is_big_imm(immprim,dataargprim,sufixprim)
		if prim==(TRUE)
			#zero extend all r64
			sd p;setcall p val64_p_get()
			set p# (val64_willbe)
		endif
		return 2
	endelseif
	return -1
endfunction

#bool
function is_big_imm(sd imm,sd data,sd sufix)
	if imm==(FALSE)
		sd b
		setcall b is_big(data,sufix)
		return b
	endif
	return (FALSE)
endfunction

function writeoper(sd takeindex,sd location,sd sufix)
	sd err
	setcall err writetake(takeindex,location)
	If err==(noerror)
		if sufix==(TRUE)
			sd t;setcall t sufix64(location)
			setcall err sufix_take(takeindex,t)
		endif
	endif
	return err
endfunction

function writeop_prim(sd dataargprim,sd opprim,sd sufixprim,sd lowprim,sd sameimportant,sd lowsec)
	sd err
	if sameimportant==(FALSE)
		if lowsec==(TRUE)
			#this is and/or... at sd low not needing to write rex
			setcall err writeoper((edxregnumber),dataargprim,sufixprim)
			if err!=(noerror);return err;endif
			setcall err writeoperation_op(opprim,(FALSE),(eaxregnumber),(edxregnumber))
			return err
		endif
	endif
	SetCall err writeop(dataargprim,opprim,sufixprim,(eaxregnumber),lowprim)
	return err
endfunction

#err
function writeop_promotes(sd dataarg,sd op,sd sufix,sd regopcode,sd low,sd comp_at_bigs)
	sd err
	if comp_at_bigs==-1
		SetCall err writeop(dataarg,op,sufix,regopcode,low)
	else #0-2
		setcall err writeoper((edxregnumber),dataarg,sufix) #no val64 recordings
		if err==(noerror)
			if comp_at_bigs==1 #these are all 64
				# sd    data    must take signextended data at 64
				set op (moveatprocthemem_sign)
				sd p;setcall p val64_p_get()
				set p# (val64_willbe)
			else
				#2 for zero extend; these are all low
				set op 0xb6
			endelse
			setcall err writeoperation_op(op,low,regopcode,(edxregnumber))
		endif
	endelse
	return err
endfunction

function argmasks()
	value a#5 #aligned(no casts at the time of write)
	return #a
endfunction
function store_argmask(sd data)
	sv a
	setcall a argmasks()
	inc a#
	if a#==2
		add a (2*:)
	endif
	incst a
	set a# data
	incst a
	add data (maskoffset)
	set a# data#
endfunction
function restore_argmask()
	sv a
	setcall a argmasks()
	if a#>0
		dec a#
		if a#==1
			add a (2*:)
		endif
		incst a
		sd data
		set data a#
		incst a
		add data (maskoffset)
		set data# a#
	endif
endfunction


#err
function div_prepare(sd low,sd big)
	const bt_atdiv=bt_reg_imm8|eaxregnumber
	vData codeptr%ptrcodesec
	sd errnr
	if big==(TRUE)
	#bt rax,63;jc,;mov 0,edx;jmp,;mov -1,rdx
	#In x64, any operation on a 32-bit register clears the top 32 bits of the corresponding 64-bit register too, so there's no need to use mov 0,rax (and xor rax, rax)
		const div_prepare_high=!
		chars high={REX_Operand_64,twobytesinstruction_byte1,bt_instruction,bt_atdiv,63,jnc_instruction,9,REX_Operand_64,mov_imm_to_rm,regregmod|edxregnumber,-1,-1,-1,-1,jmp_rel8,5,atedximm,0,0,0,0}
		SetCall errnr addtosec(#high,(!-div_prepare_high),codeptr)
	elseif low==(TRUE)
	#bt eax,15;jc,;mov ah,0;jmp,;mov ah,-1
		const div_prepare_low=!
		chars small={twobytesinstruction_byte1,bt_instruction,bt_atdiv,7,jnc_instruction,5,0xc6,regregmod|ahregnumber,-1,jmp_rel8,3,0xc6,regregmod|ahregnumber,0}
		SetCall errnr addtosec(#small,(!-div_prepare_low),codeptr)
	else
	#bt eax,31;jc,;mov 0,edx;jmp,;mov -1,edx
		const div_prepare_mediu=!
		chars mediu={twobytesinstruction_byte1,bt_instruction,bt_atdiv,31,jnc_instruction,7,atedximm,-1,-1,-1,-1,jmp_rel8,5,atedximm,0,0,0,0}
		SetCall errnr addtosec(#mediu,(!-div_prepare_mediu),codeptr)
	endelse
	return errnr
	#before
	#xor  test   jns  not
	#33D2 4885c0 7903 48f7d2
	#32E4 84c0   7902 f6d4
	#33D2 85c0   7902 f7d2
endfunction
