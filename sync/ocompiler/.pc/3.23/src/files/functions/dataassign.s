



#err
Function dataassign(data ptrcontent,data ptrsize,data typenumber)
	Data false=FALSE
	Data true=TRUE
	data null=0
	data stack#1
	data ptrS^stack
	data rightstackpointer#1
	
	setcall typenumber stackfilter(typenumber,ptrS)
	if stack==true
		#######must be at the start
		call entryscope_verify_code()
	endif
	set rightstackpointer false

	Str err#1
	Data noerr=noerror
	Chars sign#1
	Str assignsign^sign
	chars nosign=0

	Data constantsnr=constantsnumber
	Data charsnr=charsnumber
	Data stringsnr=stringsnumber

	sd offset
	Data ptroffset^offset
	Data constantsstruct%ptrconstants
	Data container#1
	Data pointer_structure#1
	Data ptrcontainer^container
	#at constants and at data^sd,str^ss
	If typenumber!=charsnr
		if typenumber==constantsnr
			set pointer_structure constantsstruct
		else
			setcall pointer_structure getstructcont(typenumber)
		endelse
		Call getcontReg(pointer_structure,ptroffset)
	EndIf

	Data ptrrelocbool%ptrrelocbool
	Data relocindx#1
	Data dataind=dataind
	Set relocindx dataind
	
	SetCall err dataparse(ptrcontent,ptrsize,typenumber,assignsign,ptrrelocbool,stack)
	If err!=noerr
		Return err
	EndIf
	if assignsign#==nosign
		#stack variable declared without assignation, only increment stack variables
		call addramp()
		Return noerr
	endif

	Data value#1
	Data ptrvalue^value

	Str content#1
	Data size#1
	Data ptrdatasec%ptrdatasec
	Data ptrcodesec%ptrcodesec
	Data ptrfunctions%ptrfunctions

	Data zero=0
	
	Data dwSz=dwsz
	data bsz=bsz
	data valuewritesize#1
	set valuewritesize dwSz
	#is for chars name="value" or str name="value"
	data stringtodata#1
	set stringtodata false
	#is for chars name="value"
	data skipNumberValue#1
	set skipNumberValue false
	Data importbittest#1
	set importbittest -1
	
	Set size ptrsize#
	If size==zero
		Chars rightsideerr="Right side of the assignment expected."
		Str ptrrightsideerr^rightsideerr
		Return ptrrightsideerr
	Chars equal="="
	ElseIf sign==equal
		Chars byte#1
		Set content ptrcontent#
		Set byte content#
		Chars groupstart="{"
		If byte!=groupstart
			chars stringstart="\""
			If byte==stringstart
			#"text"
				If typenumber==charsnr
					set stringtodata true
					set skipNumberValue true
				ElseIf typenumber==stringsnr
					set stringtodata true
					setcall value get_img_vdata_dataReg()
					if stack==false
						add value dwSz
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
				SetCall err parseoperations(ptrcontent,ptrsize,size,ptrvalue)
				if err!=noerr
					return err
				endif
				If typenumber==charsnr
					set valuewritesize bsz
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
			SetCall err enumcommas(ptrcontent,ptrsize,sz,true,typenumber,stack,(not_hexenum))
			If err!=noerr
				Return err
			EndIf
			Call stepcursors(ptrcontent,ptrsize)
			Return noerr
		EndElse
	Chars reserve="#"
	ElseIf sign==reserve
		SetCall err parseoperations(ptrcontent,ptrsize,size,ptrvalue)
		If err!=noerr
			Return err
		EndIf
		If value<zero
			Chars negreserve="Unexpected negative value at reserve declaration."
			Str ptrnegreserve^negreserve
			Return ptrnegreserve
		EndIf
		Data dsz=dwsz
		if stack==false
			SetCall err maxvaluecheck(value)
			If err!=noerr
				Return err
			EndIf
			If typenumber!=charsnr
				Mult value dsz
				SetCall err maxvaluecheck(value)
				If err!=noerr
					Return err
				EndIf
			EndIf
			SetCall err addtosec(null,value,ptrdatasec)
			Return err
		else
			Mult value dsz
			call growramp(value)
			return noerr
		endelse
	Else
	#^ pointer
		Set content ptrcontent#
		data doublepointer#1
		set doublepointer zero
		Chars pointersign="^"
		if content#==pointersign
			inc doublepointer
			call stepcursors(ptrcontent,ptrsize)
			Set content ptrcontent#
			set size ptrsize#
		endif
		Data tp=notype
		Data pointer#1
		SetCall pointer strinvars(content,size,tp)
		If pointer!=zero
			data rightstackbool#1
			setcall rightstackbool is_stack(pointer)
			if rightstackbool==false
				Set value pointer#
			else
				set ptrrelocbool# false
				if stack==false
					data eax=eaxregnumber
					setcall err writetake(eax,pointer)
					If err!=noerr
						Return err
					EndIf
					data op=moveatmemtheproc
					Data noreg=noregnumber
					Call getcont(pointer_structure,ptrcontainer)
					Add container offset
					SetCall err writeop(container,op,noreg,false,eax)
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

			setcall importbittest get_importbit(pointer)
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
				#third value is not used at object==false
				setcall err unresolvedcallsfn(section,section_offset,0,addatend)
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
			setcall err writevar(ptrvalue,valuewritesize,relocindx,stack,rightstackpointer)
			If err!=noerr
				Return err
			EndIf
			#init -1, 0 is local function in the right
			if importbittest==0
				if stack==false
					setcall err unresLc(-4,ptrdatasec,0)
				else
					setcall err unresLc(-4,ptrcodesec,0)
				endelse
				if err!=(noerror)
					return err
				endif
			endif
		Else
			Call getcont(constantsstruct,ptrcontainer)
			Add container offset
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

#import bit
function get_importbit(sd pointer)
	Add pointer (maskoffset)
	sd value
	set value pointer#
	And value (idatabitfunction)
	return value
endfunction
#value
function get_function_value(sd importbit,sd pointer)
	if importbit!=0
		#imports
		return pointer#
	else
		#local
		sd value
		call get_fn_pos(pointer,#value)
		return value
	endelse
endfunction
#relocindex
function get_function_values(sd importbit,sd p_value,sd pointer)
	If importbit==0
		#code
		return (codeind)
	Else
		#import
		set p_value# 0
		return pointer#
	EndElse
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