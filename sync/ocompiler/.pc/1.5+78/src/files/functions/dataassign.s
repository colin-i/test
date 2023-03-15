

#err
Function dataassign(sd ptrcontent,sd ptrsize,sd sign,sd valsize,sd typenumber,sd punitsize,sd long_mask,sd relocbool,sd stack,sd is_expand)
	Data false=FALSE
	Data true=TRUE
	Str err#1
	Data noerr=noerror
	chars nosign=nosign

	Data constantsnr=constantsnumber
	Data charsnr=charsnumber
	Data stringsnr=stringsnumber

	data offset_const#1
	Data ptroffset_const^offset_const
	Data constantsstruct%%ptr_constants
	#Data pointer_structure#1
	#at constants and at data^sd,str^ss

	if punitsize==(NULL)
		if typenumber==constantsnr
			#this can't go after dataparse, addvarref will increase the offset
			Call getcontReg(constantsstruct,ptroffset_const)
			SetCall err addvarreferenceorunref(ptrcontent,ptrsize,valsize,typenumber,long_mask) #there are 2 more argument but are not used
			#it is not a mistake to go with 0 mask in variable from here to addaref
			If err!=noerr;Return err;EndIf
		else
			if stack==(TRUE)
				sd sectiontypenumber=totalmemvariables
				add sectiontypenumber typenumber
				SetCall err addvarreferenceorunref(ptrcontent,ptrsize,valsize,sectiontypenumber,long_mask,0) #there is 1 more argument but is not used
			else
				SetCall err addvarreferenceorunref(ptrcontent,ptrsize,valsize,typenumber,long_mask,0,is_expand)
			endelse
			If err!=noerr;Return err;EndIf
			if sign==nosign
				#stack variable declared without assignation, only increment stack variables
				call addramp(#err)
				Return err
			endif
		endelse
	else
		call advancecursors(ptrcontent,ptrsize,valsize)
	endelse

	Call stepcursors(ptrcontent,ptrsize)

	Data size#1
	Set size ptrsize#
	If size==0
		#not at unitsize: constants,stacks
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
	Data ptrdatasec%%ptr_datasec
	Data ptrcodesec%%ptr_codesec
	Data ptrfunctions%%ptr_functions

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
		if byte==(relsign)
			Call stepcursors(ptrcontent,ptrsize)
			Call stepcursors(#content,#size)
			If size==0
				#to not set byte in vain
				Return ptrrightsideerr
			endIf
			#this comparation is not for chars and const is excluded at getsign
			if relocbool!=true
				return "Unexpected relocation sign."
			endif
			vdata ptr_nobits_virtual%ptr_nobits_virtual
			if ptr_nobits_virtual#==(Yes)
				set relocindx (dtnbind)
			endif
			Set byte content#
		endif
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
						if punitsize!=(NULL)
							set punitsize# 1    #was 1 from bsz is 1 from null end
						endif
					endif
				ElseIf typenumber==stringsnr
					set stringtodata true
					if punitsize==(NULL)
						setcall value get_img_vdata_dataReg()
						if stack==false
							if long_mask!=0
								add value (qwsz)
							else
								add value (dwsz)
								addcall value reloc64_mid()
							endelse
						endif
						if relocbool==true
							str badrelocstr="Relocation sign and string surrounded by quotations is not allowed."
							return badrelocstr
						endif
						set relocbool true
					else
						#let relocationsign, mess with dataReg, possible error will be catched at pass_write
						inc punitsize#   #null end
						if stack==false
							if long_mask==0
								#for ^ and rel64 write is somewhere else
								addcall punitsize# reloc64_mid()
							endif
						endif
					endelse
				EndElseIf
				if stringtodata==false
					chars bytesatintegers="The string assignment (\"\") can be used at CHARS, STR or SS."
					str bytesatints^bytesatintegers
					return bytesatints
				endif
			Else
			#=value+constant-/&...
				if punitsize!=(NULL)
				#dwsz or bsz  or qwsz
				#ss =% x is 0
					call advancecursors(ptrcontent,ptrsize,size)
					return (noerror)
				endif
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
			if punitsize!=(NULL)
				if stack==true
				#ss =% {}      is 0
					call advancecursors(ptrcontent,ptrsize,size)
					return (noerror)
				endif
			endif
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
			if punitsize==(NULL)
				SetCall err enumcommas(ptrcontent,ptrsize,sz,true,typenumber,(NULL),(not_hexenum),stack,long_mask,relocbool,relocindx)
				If err!=noerr;Return err;EndIf
			else
				sd aux;set aux punitsize#
				set punitsize# 0   #will add unit sizes inside
				Call enumcommas(ptrcontent,ptrsize,sz,true,typenumber,punitsize,aux) #there are 4 more arguments but are not used
			endelse
			Call stepcursors(ptrcontent,ptrsize)
			Return noerr
		EndElse
	ElseIf sign==(reserveascii)
		setcall err get_reserve_size(ptrcontent,ptrsize,size,ptrvalue,stack,typenumber,long_mask)
		if err==(noerror)
			if punitsize!=(NULL)
				set punitsize# value
				return (noerror)
			endif
			if stack==false
				if is_expand==(TRUE)
					vdata ptrdataSize%ptrdataSize
					add ptrdataSize# value
				else
					setcall err set_reserve(value)
				endelse
			else
				call growramp(value,#err)
			endelse
		endif
		Return err
	Else
	#^ pointer
		if punitsize!=(NULL)
			call advancecursors(ptrcontent,ptrsize,size)
			return (noerror)
		endif
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

				#vdata ptr_nobits_virtual%ptr_nobits_virtual
				#if ptr_nobits_virtual#==(Yes)
				#data^datax or sd^datax
				#expandbit already has nobits_virtual previous test
				sd expand;setcall expand expandbit(pointer)
				if expand!=0
					set relocindx (dtnbind)
				endif
			else
				set relocbool false
				if stack==false
					If typenumber!=constantsnr
					#data^stack
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
					Else
						set value pointer#
					endElse
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
			#it can be data% but with R_X86_64_64 at prefs and that will force 8 bytes
			if punitsize==(NULL)
				#init -1, 0 is local function in the right
				if importbittest==0
					sd p_inplace_reloc_pref%p_inplace_reloc_pref
					#at addend 0 at data/code must not pe resolved
					if p_inplace_reloc_pref#!=(zero_reloc)
						if stack==false
							setcall err unresLc(0,ptrdatasec,0)
						else
							#it's only an imm to reg
							sd stack_off;setcall stack_off reloc64_offset((rampadd_value_off))
							setcall err unresLc(stack_off,ptrcodesec,0)
						endelse
						if err!=(noerror)
							return err
						endif
					endif
				endif
				#addtocode(#test,1,code) cannot add to code for test will trick the next compiler, entry is started,will look like a bug
				setcall err writevar(ptrvalue,valuewritesize,relocindx,stack,rightstackpointer,long_mask,relocbool)
				If err!=noerr
					Return err
				EndIf
			endif
		Else
			Data container#1
			Data ptrcontainer^container
			Call getcont(constantsstruct,ptrcontainer)
			Add container offset_const
			Set container# value
		EndElse
	endif
	if stringtodata==true
		sd escapes
		SetCall err quotinmem(ptrcontent,ptrsize,ptrvalue,#escapes)
		if punitsize==(NULL)
			SetCall err addtosecstresc(ptrcontent,ptrsize,value,escapes,ptrdatasec,(FALSE))
			if err!=(noerror)
				return err
			endif
			Call stepcursors(ptrcontent,ptrsize)
		else
			sub value escapes
			add punitsize# value
			call advancecursors(ptrcontent,ptrsize,ptrsize#)
		endelse
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
			SetCall err maxsectioncheck(ptrvalue#,ptrvalue)
			If err==(noerror)
				SetCall err maxsectioncheck(ptrvalue#,ptrvalue)
				If err==(noerror)
					if long_mask!=0
						SetCall err maxsectioncheck(ptrvalue#,ptrvalue)
					endif
				endIf
			EndIf
		EndIf
	else
		SetCall err maxsectioncheck(ptrvalue#,ptrvalue)
		If err==(noerror)
			SetCall err maxsectioncheck(ptrvalue#,ptrvalue)
			If err==(noerror)
				#at format 64 can be a *2 at growramp
				sd b;setcall b is_for_64()
				if b==(TRUE)
					SetCall err maxsectioncheck(ptrvalue#,ptrvalue)
				endIf
			endIf
		endIf
	endelse
	Return err
endfunction

#err
function set_reserve(sd value)
	vData ptrdatasec%%ptr_datasec
	sd p_nul_res_pref%p_nul_res_pref
	if p_nul_res_pref#==(TRUE)
		sd reg;call getcontReg(ptrdatasec,#reg)
	endif
	sd err
	SetCall err addtosec(0,value,ptrdatasec)
	If err==(noerror)
		if p_nul_res_pref#==(TRUE)
			sd cont;call getcont(ptrdatasec,#cont)
			add cont reg
			call memset(cont,0,value)
		endif
	EndIf
	Return err
endfunction
