
Function rol(data number,data times)
	Data nr#1
	Data i#1
	Data zero=0
	Data two=2

	Set nr number
	Set i zero
	While i<times
		Mult nr two
		Inc i
	EndWhile
	Return nr
EndFunction
#modrm
Function formmodrm(data mod,data regopcode,data rm)
	Data toregopcode=3
	Data tomod=3
	Data initialbitshift=1
	Data bitshift#1

	Data modrm#1
	Data store#1

	Set bitshift initialbitshift

	Set modrm rm

	SetCall bitshift rol(bitshift,toregopcode)
	Set store bitshift
	Mult store regopcode
	Or modrm store

	SetCall bitshift rol(bitshift,tomod)
	Set store bitshift
	Mult store mod
	Or modrm store

	Return modrm
EndFunction

function takewithimm(sd ind,sd addr)
	Chars takeop#1
	Data takeloc#1

	Set takeop (0xb8)
	Add takeop ind
	set takeloc addr

	Data ptrcodesec%ptrcodesec
	Data sz1=bsz+dwsz

	sd err
	SetCall err addtosec(#takeop,sz1,ptrcodesec)
	return err
endfunction
#er
function datatake_reloc(sd takeindex,sd take_loc)
	data p_is_object%ptrobject
	if p_is_object#==(TRUE)
		sd relocoff
		setcall relocoff reloc64_offset(1)
		sd errnr
		setcall errnr adddirectrel_base_inplace(relocoff,#take_loc)
		If errnr!=(noerror)
			Return errnr
		EndIf
	endif
	setcall errnr datatake(takeindex,take_loc)
	return errnr
endfunction
#er
function datatake(sd takeindex,sd take_loc)
	sd errnr
	setcall errnr reloc64_ante();If errnr!=(noerror);Return errnr;EndIf
	setcall errnr takewithimm(takeindex,take_loc);If errnr!=(noerror);Return errnr;EndIf
	setcall errnr reloc64_post()
	return errnr
endfunction
#err
function adddirectrel_base_inplace(sd relocoff,sd p_take_loc)
	Data ptrextra%ptrextra
	Data dataind=dataind
	sd errnr
	SetCall errnr adddirectrel_base(ptrextra,relocoff,dataind,p_take_loc#)
	If errnr==(noerror)
		call inplace_reloc(p_take_loc)
	EndIf
	Return errnr
endfunction
#er
function writetake(sd takeindex,sd entry)
	Data errnr#1
	sd take_loc;set take_loc entry#
	sd stack
	setcall stack stackbit(entry)
	if stack==0
		data p_is_object%ptrobject
		if p_is_object#==(TRUE)
			Data ptrextra%ptrextra
			data relocoff#1
			setcall relocoff reloc64_offset(1)
			sd var
			setcall var function_in_code()
			if var#==0
				setcall errnr adddirectrel_base_inplace(relocoff,#take_loc)
				If errnr!=(noerror)
					Return errnr
				EndIf
			else
				#function in code, not sd^local, sd^imp
				#function in code is only at objects at the moment, is set only once at arg.s
				#var# 0? is static bool
				set var# 0
				sd impbit
				setcall impbit importbit(entry)
				setcall take_loc get_function_value(impbit,entry)
				sd index
				setcall index get_function_values(impbit,#take_loc,entry)
				SetCall errnr adddirectrel_base(ptrextra,relocoff,index,take_loc)
				If errnr!=(noerror)
					Return errnr
				EndIf
				if impbit==0
					setcall errnr unresReloc(ptrextra)
					If errnr!=(noerror);Return errnr;EndIf
					setcall errnr inplace_reloc_unres(#take_loc,relocoff)
					If errnr!=(noerror);Return errnr;EndIf
				endif
			endelse
		endif
		setcall errnr datatake(takeindex,take_loc)
	else
		chars stack_relative#1
		chars regreg=RegReg
		setcall stack_relative stack_get_relative(entry)
		chars getfromstack={0x03}
		chars getfromstack_modrm#1
		SetCall getfromstack_modrm formmodrm(regreg,takeindex,stack_relative)
		data ptrgetfromstack^getfromstack
		data sizegetfromstack=2
		if take_loc!=0
			setcall errnr takewithimm(takeindex,take_loc);If errnr!=(noerror);Return errnr;EndIf
			set getfromstack 0x03
		else;set getfromstack (moveatprocthemem);endelse
		setcall errnr rex_w_if64();if errnr!=(noerror);return errnr;endif
		Data ptrcodesec%ptrcodesec
		SetCall errnr addtosec(ptrgetfromstack,sizegetfromstack,ptrcodesec)
	endelse
	Return errnr
endfunction

#val64. is one call at this that will break val64 if not a return value
Function writeoperation_take(sd p_errnr,sd location,sd sufix,sd takeindex,sd is_low)
#last parameter is optional
	Data errnr#1
	Data noerr=noerror

	setcall errnr writetake(takeindex,location)
	If errnr!=noerr
		set p_errnr# errnr;return (void)
	EndIf

	sd v_64
	sd prefix
	setcall v_64 sufix64(location)
	If sufix==(TRUE)
		sd take64;set take64 v_64
		if v_64==(val64_willbe)
			if is_low==(TRUE)
			#not ss, rex.w op r/m8 is ok but is useless
				set v_64 (val64_no)
			else
				sd pbit;setcall pbit pointbit(location)
				if pbit==0
					#not needed at sd#
					setcall prefix prefix_bool()
					if prefix#==0
					#but keep at prefix, this is a #a# case,the logic is fragile
						set v_64 (val64_no)
					endif
				endif
			endelse
		endif
		setcall p_errnr# sufix_take(takeindex,take64)
	Else
		sd for_64;setcall for_64 is_for_64()
		if for_64==(TRUE)
			setcall prefix prefix_bool()
			if prefix#!=0
			#set here (example: return #data), this can be thinked to be wrote at writeoperation_op
				set v_64 (val64_willbe)
			endif
		endif
		set p_errnr# (noerror)
	EndElse
	Return v_64
EndFunction
#er
function sufix_take(sd takeindex,sd take64)
	sd err
	if take64==(val64_willbe)
		call rex_w(#err)
		if err!=(noerror)
			return err;endif
	endif
	Data ptrcodesec%ptrcodesec
	Chars newtake=moveatprocthemem
	Chars newtakemodrm#1
	Str ptrnewtake^newtake
	Data sz2=bsz+bsz
	setcall newtakemodrm formmodrm((mod_0),takeindex,takeindex)
	SetCall err addtosec(ptrnewtake,sz2,ptrcodesec)
	return err
endfunction
#v64
function sufix64(sd location)
	sd bittest;setcall bittest bigbits(location)
	if bittest!=0
		sd for_64;setcall for_64 is_for_64()
		return for_64
		#p test
		#if for_64==(TRUE)
		#	return (val64_willbe)
		#	#rex if p
		#endif
		#take on takeindex
	endif
	return (val64_no)
endfunction

#er
Function writeoperation_op(sd operationopcode,sd is_prepare,sd regopcode,sd takeindex)
	Data ptrcodesec%ptrcodesec
	Data errnr#1
	Data noerr=noerror
	Data sz2=bsz+bsz

	sd v64;setcall v64 val64_p_get()
	if v64#==(val64_willbe)
		call rex_w(#errnr);if errnr!=(noerror);return errnr;endif
		set v64# (val64_no)
	endif

	sd mod=mod_0

	#if is like was xor prepare,prepare
	If is_prepare==(TRUE)
	#!=(noregnumber)
		#Chars comprepare1={0x33}
		#Chars comprepare2#1
		#setcall comprepare2 formmodrm((RegReg),regprepare,regprepare)
		#SetCall errnr addtosec(#comprepare1,sz2,ptrcodesec)

		#zero extend
		chars extend_byte=twobytesinstruction_byte1
		SetCall errnr addtosec(#extend_byte,1,ptrcodesec)
		If errnr!=noerr
			Return errnr
		EndIf
	Else
		#at calls there is no low
		#there is no prefix at low, and no val64
		sd prefix
		setcall prefix prefix_bool()
		If prefix#!=0
			set mod (RegReg)
			set prefix# 0
		endIf
		#Else
		#	#this will reset calls and set v64
		#	Call stack64_op()
		#endElse
	EndElse

	Chars actionop#1
	Chars actionmodrm#1

	Set actionop operationopcode
	SetCall actionmodrm formmodrm(mod,regopcode,takeindex)
	SetCall errnr addtosec(#actionop,sz2,ptrcodesec)
	Return errnr
Endfunction
#er
Function writeoperation(sd location,sd operationopcode,sd sufix,sd regopcode,sd takeindex,sd is_low)
	sd err;sd v_64
	setcall v_64 writeoperation_take(#err,location,sufix,takeindex,is_low)
	if err!=(noerror);return err;endif
	sd v64;setcall v64 val64_p_get();set v64# v_64
	setcall err writeoperation_op(operationopcode,(FALSE),regopcode,takeindex)
	return err
Endfunction

#er
Function writeop(sd location,sd operationopcode,sd sufix,sd regopcode,sd is_low)
	Data err#1
	Data edxregnumber=edxregnumber
	SetCall err writeoperation(location,operationopcode,sufix,regopcode,edxregnumber,is_low)
	Return err
EndFunction

#er
function writeopera(sd location,sd operationopcode,sd regopcode,sd takeindex)
	sd err
	setcall err writetake(takeindex,location)
	if err==(noerror)
		setcall err writeoperation_op(operationopcode,(FALSE),regopcode,takeindex)
	endif
	return err
endfunction
