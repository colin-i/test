
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

function writetake(sd takeindex,sd entry)
	Data ptrcodesec%ptrcodesec
	data null=0

	Data errnr#1
	Data noerr=noerror

	Chars takeini={0xb8}

	Chars takeop#1
	Data takeloc#1

	Data ptrtake^takeop
	Data sz1=bsz+dwsz

	Set takeop takeini
	Add takeop takeindex

	Set takeloc entry#

	
	data stack#1
	setcall stack is_stack(entry)

	if stack==null
		Data ptrextra%ptrextra
		data relocoff=1
		sd var
		setcall var function_in_code()
		if var#==0
			Data dataind=dataind
			SetCall errnr adddirectrel_base(ptrextra,relocoff,dataind,takeloc)
			If errnr!=(noerror)
				Return errnr
			EndIf
		else
			#function in code
			set var# 0
			sd importbit
			setcall importbit get_importbit(entry)
			setcall takeloc get_function_value(importbit,entry)
			sd index
			setcall index get_function_values(importbit,#takeloc,entry)
			SetCall errnr adddirectrel_base(ptrextra,relocoff,index,takeloc)
			If errnr!=(noerror)
				Return errnr
			EndIf
			if importbit==0
				setcall errnr unresLc(1,ptrcodesec,0)
				If errnr!=(noerror)
					Return errnr
				EndIf
			endif
		endelse
	endif

	SetCall errnr addtosec(ptrtake,sz1,ptrcodesec)
	If errnr!=noerr
		Return errnr
	EndIf
	
	if stack==null
		return noerr
	else
		setcall errnr rex_w_if64();if errnr!=(noerror);return (noerror);endif
		
		chars getfromstack={0x03}
		chars getfromstack_modrm#1

		chars stack_relative#1
		chars regreg=RegReg

		setcall stack_relative stack_get_relative(entry)
		SetCall getfromstack_modrm formmodrm(regreg,takeindex,stack_relative)

		data ptrgetfromstack^getfromstack
		data sizegetfromstack=2

		SetCall errnr addtosec(ptrgetfromstack,sizegetfromstack,ptrcodesec)
		Return errnr
	endelse
endfunction

#er
Function writeoperation(data location,chars operationopcode,data regprepare,data sufix,data regopcode,data takeindex)
	Data ptrcodesec%ptrcodesec
	Data errnr#1
	Data noerr=noerror

	setcall errnr writetake(takeindex,location)
	If errnr!=noerr
		Return errnr
	EndIf

	Data noreg=noregnumber
	Data sz2=bsz+bsz

	Data true=TRUE
	If sufix==true
		#setcall errnr rex_w_if64();If errnr!=noerr;Return errnr;EndIf it's not ok will break data
		Chars newtake={moveatprocthemem}
		Const edxtoedx=edxregnumber*8|edxregnumber
		Chars *newtakemodrm={edxtoedx}
		Str ptrnewtake^newtake
		SetCall errnr addtosec(ptrnewtake,sz2,ptrcodesec)
		If errnr!=noerr
			Return errnr
		EndIf
	EndIf
	
	If regprepare!=noreg
		Chars comprepare1={0x33}
		Chars comprepare2#1
		setcall comprepare2 formmodrm((RegReg),regprepare,regprepare)
		SetCall errnr addtosec(#comprepare1,sz2,ptrcodesec)
		If errnr!=noerr
			Return errnr
		EndIf
	EndIf

	Chars actionop#1
	Chars actionmodrm#1
	
	Set actionop operationopcode
	
	sd mod=0
	#prefix is tested here; the suffix is above
	sd prefix
	setcall prefix prefix_bool()
	if prefix#!=0
		set mod (RegReg)
		set prefix# 0
	endif
	#reset the behaviour, return if (RegReg), write
	SetCall errnr stack64_op(takeindex,#mod)
	If errnr!=noerr;Return errnr;EndIf
	SetCall actionmodrm formmodrm(mod,regopcode,takeindex)
	
	SetCall errnr val64_phase_3();If errnr!=noerr;Return errnr;EndIf
	
	SetCall errnr addtosec(#actionop,sz2,ptrcodesec)
	Return errnr
EndFunction

#er
Function writeop(data location,chars operationopcode,data regprepare,data sufix,data regopcode)
	Data err#1
	Data edxregnumber=edxregnumber
	SetCall err writeoperation(location,operationopcode,regprepare,sufix,regopcode,edxregnumber)
	Return err
EndFunction