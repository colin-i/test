


#err
Function dataassign(sd ptrcontent,sd ptrsize,sd typenumber,sd long_mask)
	sd err
	setcall err dataassign_ex(ptrcontent,ptrsize,typenumber,long_mask,(FALSE))
	return err
endfunction

#err
Function dataassign_ex(sd ptrcontent,sd ptrsize,sd typenumber,sd long_mask,sd stack)
	Data false=FALSE
	Data true=TRUE
	Str err#1
	Data noerr=noerror
	Chars sign#1
	Str assignsign^sign
	chars nosign=0

	Data constantsnr=constantsnumber
	Data charsnr=charsnumber
	Data stringsnr=stringsnumber

	data offset_const#1
	Data ptroffset_const^offset_const
	Data constantsstruct%ptrconstants
	#Data pointer_structure#1
	#at constants and at data^sd,str^ss

	Data ptrrelocbool%ptrrelocbool

	#If typenumber!=charsnr
	#for const and at pointer with stack false
	#this can't go after dataparse, addvarref will increase the offset
	if typenumber==constantsnr
		#	set pointer_structure constantsstruct
		#else
		#	setcall pointer_structure getstructcont(typenumber)
		#endelse
		Call getcontReg(constantsstruct,ptroffset_const)
	EndIf
	SetCall err dataparse(ptrcontent,ptrsize,typenumber,assignsign,ptrrelocbool,stack,long_mask)
	If err!=noerr
		Return err
	EndIf
	if assignsign#==nosign
		#stack variable declared without assignation, only increment stack variables
		call addramp()
		Return noerr
	endif

	Data size#1
	Set size ptrsize#
	If size==0
		Chars rightsideerr="Right side of the assignment expected."
		Str ptrrightsideerr^rightsideerr
		Return ptrrightsideerr
	endIf

	data rightstackpointer#1

	Data relocindx#1
	Data dataind=dataind

	Data value#1
	Data ptrvalue^value

	Str content#1
	Data ptrdatasec%ptrdatasec
	Data ptrcodesec%ptrcodesec
	Data ptrfunctions%ptrfunctions

	Data zero=0

	data valuewritesize#1
	#is for chars name="value" or str name="value"
	data stringtodata#1
	#is for chars name="value"
	data skipNumberValue#1
	Data importbittest#1

	set rightstackpointer false
	Set relocindx dataind
	set valuewritesize (dwsz)
	set stringtodata false
	set skipNumberValue false
	set importbittest -1

	If sign==(assignsign)
		Chars byte#1
		Set content ptrcontent#
		Set byte content#
		Chars groupstart="{"
		If byte!=groupstart
			chars stringstart=asciidoublequote
			If byte==stringstart
			#"text"
				If typenumber==charsnr
					if stack==false
					#else is at stack value   grep stackfilter2   2
						set stringtodata true
						set skipNumberValue true
					endif
				ElseIf typenumber==stringsnr
					set stringtodata true
					setcall value get_img_vdata_dataReg()
					if stack==false
						if long_mask!=0
							add value (qwsz)
						else
							add value (dwsz)
						endelse
					endif
					if ptrrelocbool#==true
						str badrelocstr="Relocation sign and string surrounded by quotations is not allowed."
						return badrelocstr
					endif
					set ptrrelocbool# true
				EndElseIf
				if stringtodata==false
					chars bytesatintegers="The string assignment (\"\") can be used at CHARS, STR or SS."
					str bytesatints^bytesatintegers
					return bytesatints
				endif
			Else
			#=value+constant-/&...
				SetCall err parseoperations(ptrcontent,ptrsize,size,ptrvalue,(TRUE))
				if err!=noerr
					return err
				endif
				If typenumber==charsnr
					if stack==false
					#else is at stack value   grep stackfilter2   3
						set valuewritesize (bsz)
					endif
				EndIf
			EndElse
		Else
		#{} group
			If typenumber==constantsnr
				Chars constgroup="Group begin sign ('{') is not expected to declare a constant."
				Str ptrconstgroup^constgroup
				Return ptrconstgroup
			EndIf
			Call stepcursors(ptrcontent,ptrsize)
			Set content ptrcontent#
			Set size ptrsize#
			Data sz#1
			Chars groupstop="}"
			SetCall sz valinmem(content,size,groupstop)
			If sz==size
				Chars groupend="Group end sign ('}') expected."
				Str ptrgroupend^groupend
				Return ptrgroupend
			EndIf
			SetCall err enumcommas(ptrcontent,ptrsize,sz,true,typenumber,stack,(not_hexenum),long_mask)
			If err!=noerr
				Return err
			EndIf
			Call stepcursors(ptrcontent,ptrsize)
			Return noerr
		EndElse
	ElseIf sign==(reserveascii)
		setcall err get_reserve_size(ptrcontent,ptrsize,size,ptrvalue,stack,typenumber,long_mask)
		if err==(noerror)
			if stack==false
				sd p_nul_res_pref%p_nul_res_pref
				if p_nul_res_pref#==(TRUE)
					sd datacont;call getcontplusReg(ptrdatasec,#datacont)
				endif
				SetCall err addtosec(0,value,ptrdatasec)
				If err!=noerr;Return err;EndIf
				if p_nul_res_pref#==(TRUE)
					call memset(datacont,0,value)
				endif
			else
				call growramp(value)
			endelse
		endif
		Return err
	Else
	#^ pointer
		Set content ptrcontent#
		data doublepointer#1
		set doublepointer zero
		if content#==(pointersigndeclare)
			inc doublepointer
			call stepcursors(ptrcontent,ptrsize)
			Set content ptrcontent#
			set size ptrsize#
		endif
		Data tp=notype
		Data pointer#1
		SetCall pointer strinvars(content,size,tp)
		If pointer!=zero
			data rightstackbit#1
			setcall rightstackbit stackbit(pointer)
			if rightstackbit==0
				Set value pointer#
			else
				set ptrrelocbool# false
				if stack==false
					setcall err writetake((eaxregnumber),pointer)
					If err!=noerr
						Return err
					EndIf
					setcall value get_img_vdata_dataReg()
					setcall err datatake_reloc((edxregnumber),value)
					If err!=noerr
						Return err
					EndIf
					sd v64;setcall v64 val64_p_get()
					if long_mask!=0
						setcall v64# is_for_64()
					else
						set v64# (val64_no)
					endelse
					setcall err writeoperation_op((moveatmemtheproc),(FALSE),(eaxregnumber),(edxregnumber))
					If err!=noerr
						Return err
					EndIf
				else
					set rightstackpointer pointer
				endelse
			endelse
		Else
			If typenumber==constantsnr
				SetCall err undefinedvariable()
				Return err
			EndIf
			SetCall pointer vars(content,size,ptrfunctions)
			If pointer==zero
				setcall err undefinedvar_fn()
				return err
			EndIf

			setcall importbittest importbit(pointer)
			setcall value get_function_value(importbittest,pointer)

			Data ptrobject%ptrobject
			If ptrobject#==false
				data addatend#1
				data ptrvirtualimportsoffset%ptrvirtualimportsoffset
				data ptrvirtuallocalsoffset%ptrvirtuallocalsoffset
				If importbittest==false
					set addatend ptrvirtuallocalsoffset
				else
					if doublepointer==zero
						str doubleexp="Double pointer (^^) expected in this case: executable format and imported function."
						return doubleexp
					endif
					dec doublepointer
					set addatend ptrvirtualimportsoffset
				endelse

				sd section
				sd section_offset
				if stack==false
					set section ptrdatasec
					set section_offset zero
				else
					set section ptrcodesec
					data stackoff=rampadd_value_off
					set section_offset stackoff
				endelse
				setcall err unresolvedcallsfn(section,section_offset,addatend) #this is intentionaly without last arg
				If err!=noerr
					Return err
				EndIf
			Else
				setcall relocindx get_function_values(importbittest,#value,pointer)
			EndElse
		EndElse
		if doublepointer!=zero
			str unexpdp="Unexpected double pointer."
			return unexpdp
		endif
		Call advancecursors(ptrcontent,ptrsize,size)
	EndElse
	if skipNumberValue==false
		If typenumber!=constantsnr
			#init -1, 0 is local function in the right
			if importbittest==0
			#and no problems if inplace_reloc is 0 there
				if stack==false
					setcall err unresLc(0,ptrdatasec,0)
				else
					setcall err unresLc((rampadd_value_off),ptrcodesec,0)
				endelse
				if err!=(noerror)
					return err
				endif
			endif
			#addtocode(#test,1,code) cannot add to code for test will trick the next compiler, entry is started,will look like a bug
			setcall err writevar(ptrvalue,valuewritesize,relocindx,stack,rightstackpointer,long_mask)
			If err!=noerr
				Return err
			EndIf
		Else
			Data container#1
			Data ptrcontainer^container
			Call getcont(constantsstruct,ptrcontainer)
			Add container offset_const
			Set container# value
		EndElse
	endif
	if stringtodata==true
		setcall err add_string_to_data(ptrcontent,ptrsize)
		if err!=(noerror)
			return err
		endif
		Call stepcursors(ptrcontent,ptrsize)
	endif
	Return noerr
EndFunction

function undefinedvar_fn()
	return "Undefined variable/function name."
endfunction

#value
function get_function_value(sd impbit,sd pointer)
	if impbit!=0
		#imports
		return pointer#
	endif
	#local
	sd value
	call get_fn_pos(pointer,#value)
	return value
endfunction
#relocindex
function get_function_values(sd impbit,sd p_value,sd pointer)
	If impbit==0
		#code
		return (codeind)
	endif
	#import
	set p_value# 0
	return pointer#
endfunction

#err
function add_string_to_data(sd ptrcontent,sd ptrsize)
	sd err
	Data ptrdatasec%ptrdatasec
	Data quotsz#1
	Data ptrquotsz^quotsz
	Data escapes#1
	Data ptrescapes^escapes
	SetCall err quotinmem(ptrcontent,ptrsize,ptrquotsz,ptrescapes)
	If err!=(noerror)
		return err
	endif
	SetCall err addtosecstresc(ptrcontent,ptrsize,quotsz,escapes,ptrdatasec,(FALSE))
	If err!=(noerror)
		return err
	endif
	return (noerror)
endfunction

#err
function get_reserve_size(sv ptrcontent,sd ptrsize,sd size,sd ptrvalue,sd is_stack,sd typenumber,sd long_mask)
	sd err
	SetCall err parseoperations(ptrcontent,ptrsize,size,ptrvalue,(TRUE))
	If err!=(noerror)
		Return err
	EndIf
	Chars negreserve="Unexpected negative value at reserve declaration."
	vStr ptrnegreserve^negreserve
	If ptrvalue#<0
		Return ptrnegreserve
	EndIf
	if is_stack==(FALSE)
		If typenumber!=(charsnumber)
			SetCall err maxvaluecheck(ptrvalue#)
			If err!=(noerror)
				Return err
			EndIf
			Mult ptrvalue# (dwsz)
			if long_mask!=0
				mult ptrvalue# 2
			endif
		EndIf
		If ptrvalue#<0
			return ptrnegreserve
		endIf
	else
		Mult ptrvalue# :
	endelse
	return (noerror)
endfunction
