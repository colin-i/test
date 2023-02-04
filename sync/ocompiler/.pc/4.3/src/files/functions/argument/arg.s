


function verify_syntax_end(sd ptrcontent,sd ptrsize,sd argsize,sd *data2)
	Call advancecursors(ptrcontent,ptrsize,argsize)
	Call spaces(ptrcontent,ptrsize)
	data z=0
	if ptrsize#!=z
		str er="Unrecognized inner text."
		return er
	endif
	data noer=noerror
	return noer
endfunction

#err
function arg_size(ss content,sd sizetoverify,sd p_argsize)
	Chars spc=" "
	Chars tab={0x09}
	sd szargspc
	sd szargtab
	SetCall szargspc valinmem(content,sizetoverify,spc)
	SetCall szargtab valinmem(content,sizetoverify,tab)
	If szargspc<szargtab
		Set p_argsize# szargspc
	Else
		Set p_argsize# szargtab
	EndElse
	if p_argsize#==0
		return "Expecting argument name."
	endif
	return (noerror)
endfunction

#err
Function getarg(data ptrcontent,data ptrsize,data sizetoverify,data ptrdata,data ptrlow,data ptrsufix,data sens)
	ss content
	sd size
	sd errnr
	
	Set content ptrcontent#
	set size ptrsize#

	chars string_arg="\""

	Str argnameerr="Argument name expected."
	if sizetoverify==0
		Return argnameerr
	endif
	
	sd argsize
	if content#!=string_arg
		setcall errnr arg_size(content,sizetoverify,#argsize)
		If errnr!=(noerror)
			Return errnr
		EndIf
	endif

	Data noerr=noerror
	data false=0
	
	call resetisimm()
	sd bool
	setcall bool is_constant_related_ascii(content#)
	if bool==(TRUE)
		#verify if imm is ok
		sd canhaveimm
		setcall canhaveimm getimm()
		if canhaveimm==false
			str immnothere="Unexpected numbers/constants, expecting a variable."
			return immnothere
		endif
		#extend to parenthesis if found
		sd ptr_sz^argsize
		setcall errnr parenthesis_all_size(content,size,ptr_sz)
		If errnr!=noerr
			Return errnr
		EndIf
		#find the imm
		setcall errnr findimm(ptrcontent,ptrsize,argsize,ptrdata)
		If errnr!=noerr
			Return errnr
		EndIf
		#
		set ptrlow# false
		#sufix is not used at imm value
	else
		sd prefix
		if content#==string_arg
			#get entry
			sd sec%ptrdummyEntry
			call getcont(sec,ptrdata)
			sd location
			set location ptrdata#
			setcall location# get_img_vdata_dataReg()
			#set string to data
			sd q_size
			sd escapes
			SetCall errnr quotinmem(#content,#size,#q_size,#escapes)
			If errnr!=(noerror)
				return errnr
			endif
			data ptrdatasec%ptrdatasec
			SetCall errnr addtosecstresc(#content,#size,q_size,escapes,ptrdatasec,(FALSE))
			If errnr!=(noerror)
				return errnr
			endif
			#argsize for advancing
			set argsize 2
			add argsize q_size
			#set low and sufix
			set ptrlow# (FALSE)
			set ptrsufix# (FALSE)
			#the code operation is a "prefix" like
			setcall prefix prefix_bool()
			set prefix# 1
		else
			#lower than argsize in case of a prefix
			sd argsize_filter
			set argsize_filter argsize
			
			#at object var/fn,non-object var
			sd undvar_err
			sd possible_err
			setcall undvar_err undefinedvariable()
			set possible_err undvar_err
			set ptrdata# 0
			
			chars arg_pointer="#"
			if content#==arg_pointer
				#prefix
				setcall prefix prefix_bool()
				set prefix# 1
				inc content
				dec argsize_filter
			else
				data ptrobject%ptrobject
				if ptrobject#==1
					#verify for function
					data ptrfunctions%ptrfunctions
					setcall ptrdata# vars(content,argsize,ptrfunctions)
					if ptrdata#==0
						setcall possible_err undefinedvar_fn()
					else
						set ptrlow# (FALSE)
						set ptrsufix# (FALSE)
						sd var
						setcall var function_in_code()
						set var# 1
						#the code operation is a "prefix" like
						setcall prefix prefix_bool()
						set prefix# 1
					endelse
				endif
			endelse
			if ptrdata#==0
				SetCall errnr varsufix(content,argsize_filter,ptrdata,ptrlow,ptrsufix)
				if errnr!=(noerror)
					if errnr==undvar_err
						set errnr possible_err
					endif
					return errnr
				EndIf
			endif
		endelse
	endelse
	#
	If sens==(FORWARD)
		Call advancecursors(ptrcontent,ptrsize,argsize)
		Call spaces(ptrcontent,ptrsize)
		Return noerr
	Else
		data f^verify_syntax_end
		setcall errnr restore_cursors_onok(ptrcontent,ptrsize,f,argsize)
		return errnr
	EndElse
EndFunction

function function_in_code()
	data bool#1
	return #bool
endfunction

function is_constant_related_ascii(sd in_byte)
#! data cursor
	if in_byte==(asciiExclamationmark)
		return (TRUE)
	elseif in_byte==(asciiparenthesisstart)
		return (TRUE)
#negative number
	elseif in_byte==(asciiminus)
		return (TRUE)
	elseif in_byte<(asciizero)
		return (FALSE)
	elseif in_byte<=(asciinine)
		return (TRUE)
#: size of integer
	elseif in_byte==(asciiColon)
		return (TRUE)
#not,~
	elseif in_byte==(asciiequiv)
		return (TRUE)
	endelseif
	return (FALSE)
endfunction

#err
Function arg(data ptrcontent,data ptrsize,data ptrdata,data ptrlow,data ptrsufix,data sens)
	sd szarg
	set szarg ptrsize#

	Data errnr#1
	SetCall errnr getarg(ptrcontent,ptrsize,szarg,ptrdata,ptrlow,ptrsufix,sens)
	Return errnr
EndFunction

#err
Function argfilters(data ptrcondition,data ptrcontent,data ptrsize,data ptrdata,data ptrlow,data ptrsufix)
	Data null=NULL
	Data err#1
	Data forward=FORWARD

	If ptrcondition==null
		SetCall err arg(ptrcontent,ptrsize,ptrdata,ptrlow,ptrsufix,forward)
		Return err
	Else
		call setimm()

		Data content#1
		Data size#1
		Set content ptrcontent#
		Set size ptrsize#
		Data argsz#1
		
Const enterifNOTequal=0x84
		Chars s1="!="
		Data *=enterifNOTequal

Const enterifLESSorEQUAL=0x8F
		Chars *s2="<="
		Data *=enterifLESSorEQUAL

Const enterifGREATERorEQUAL=0x8C
		Chars *s3=">="
		Data *=enterifGREATERorEQUAL

Const enterifEQUAL=0x85
		Chars *s4="=="
		Data *=enterifEQUAL

Const enterifLESS=0x8D
		Chars *s5="<"
		Data *=enterifLESS

Const enterifGREATER=0x8E
		Chars *s6=">"
		Data *=enterifGREATER

		Chars term={0}

		Data ptr#1
		Data ptrini^s1
		Chars byte#1

		Set ptr ptrini
		Set byte ptr#
		
		While byte!=term
			SetCall argsz strinmem(content,size,ptr)
			If argsz!=size
				Set ptrcondition# ptr
				Data errnr#1
				sd verifyafter
				set verifyafter content
				add verifyafter argsz
				SetCall errnr getarg(ptrcontent,ptrsize,argsz,ptrdata,ptrlow,ptrsufix,forward)
				data noerrnr=noerror
				if errnr!=noerrnr
					Return errnr
				endif
				if verifyafter!=ptrcontent#
					str moreatprimcond="Unrecognized characters at first condition argument."
					return moreatprimcond
				endif
				return noerrnr
			EndIf
			Data sz#1
			Data one=1
			Data four=4
			SetCall sz strlen(ptr)
			Add ptr sz
			Add ptr one
			Add ptr four
			Set byte ptr#
		EndWhile
		Chars conderr="Condition sign(s) expected."
		Str _conderr^conderr
		Return _conderr
		Return err
	EndElse
EndFunction


function prefix_bool()
	data value#1
	data p^value
	return p
endfunction