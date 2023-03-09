


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
Function getarg(sv ptrcontent,sd ptrsize,sd argsize,sd allowdata,sd sens,sd ptrdata,sd ptrlow,sd ptrsufix)
	ss content
	sd size
	sd errnr

	chars d_q=getarg_str

	if argsize==0
		return "Argument name expected."
	endif

	Data noerr=noerror
	data false=0

	Set content ptrcontent#
	set size ptrsize#

	sd prefix
	if content#==d_q
		sd q_size
		sd escapes
		SetCall errnr quotinmem(#content,#size,#q_size,#escapes)
		If errnr!=(noerror)
			return errnr
		endif
		if allowdata!=(allow_yes)
			if allowdata==(allow_later)
				vdata ptrdataReg%%ptr_dataReg
				sub q_size escapes
				add ptrdataReg# q_size
				inc ptrdataReg#   #null end
			else
				#allow_no later_sec
				return "String here is useless at the moment."  #the real problem: is disturbing virtual calculation at pass_init
			endelse
		else
			#get entry
			sd sec%ptrdummyEntry
			call getcont(sec,ptrdata)
			sd location
			set location ptrdata#
			setcall location# get_img_vdata_dataReg()
			#set string to data
			data ptrdatasec%%ptr_datasec
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
		endelse
	elseif allowdata!=(allow_later)  #exclude pass_init
		setcall errnr arg_size(content,argsize,#argsize)
		If errnr!=(noerror)
			Return errnr
		EndIf
		if allowdata!=(allow_later_sec)
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
				sd argsize_filter
				sd container_sz
				if content#==(pointerascii)
					#prefix
					setcall prefix prefix_bool()
					set prefix# 1
					inc content
					set argsize_filter argsize
					dec argsize_filter

					setcall container_sz valinmem(content,argsize_filter,(asciidot))
					if container_sz!=argsize_filter
						setcall errnr getarg_dot(content,argsize_filter,container_sz,ptrdata,ptrlow,ptrsufix)
					else
						SetCall errnr varsufix(content,argsize_filter,ptrdata,ptrlow,ptrsufix)
					endelse
					if errnr!=(noerror)
						return errnr
					endif
				else
					data ptrobject%ptrobject
					data ptrfunctions%%ptr_functions
					setcall container_sz valinmem(content,argsize,(asciidot))
					if container_sz!=argsize
						setcall errnr getarg_dot(content,argsize,container_sz,ptrdata,ptrlow,ptrsufix)
						if errnr!=(noerror)
							return errnr
						endif
					elseif ptrobject#==1
						#verify for function
						setcall ptrdata# vars(content,argsize,ptrfunctions)
						if ptrdata#==0
							SetCall errnr varsufix(content,argsize,ptrdata,ptrlow,ptrsufix)
							if errnr!=(noerror)
								sd undvar_err
								setcall undvar_err undefinedvariable()
								if errnr==undvar_err
									setcall errnr undefinedvar_fn()
								endif
								return errnr
							endif
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
					else
						SetCall errnr varsufix(content,argsize,ptrdata,ptrlow,ptrsufix)
						if errnr!=(noerror)
							return errnr
						endif
					endelse
				endelse
			endelse
		endif
	endelseif
	If sens==(FORWARD)
		Call advancecursors(ptrcontent,ptrsize,argsize)
		Return noerr
	endIf
	data f^verify_syntax_end
	setcall errnr restore_cursors_onok(ptrcontent,ptrsize,f,argsize)
	return errnr
EndFunction
#err
function getarg_dot(sd content,sd argsize,sd container_sz,sd ptrdata,sd ptrlow,sd ptrsufix)
	data ptrfunctions%%ptr_functions
	#if is a dot
	sd inter
	#setcall inter vars(content,container_sz,ptrfunctions)
	sd errnr
	sd pos=0
	setcall inter vars_core_ref_scope(content,container_sz,ptrfunctions,(NULL),(TRUE),#pos)
	if inter==(NULL)
		setcall errnr undefinedvar_fn()
		return errnr
	endif
	inc container_sz
	sd argsize_filter
	set argsize_filter argsize
	call advancecursors(#content,#argsize_filter,container_sz)
	#
	sd scope
	setcall scope scopes_get_scope(pos)
	SetCall errnr varsufix_ex(content,argsize_filter,ptrdata,ptrlow,ptrsufix,scope)
	if errnr!=(noerror)
		return errnr
	endif
	sd test;setcall test stackbit(ptrdata#)
	if test==0
		return (noerror)
	endif
	return "Stack variables are not relevant for scope.variable."
endfunction

function function_in_code()
	data bool#1
	return #bool
endfunction

function is_constant_related_ascii(sd in_byte)
#! data cursor
	if in_byte==(asciiexclamationmark)
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
	elseif in_byte==(asciicolon)
		return (TRUE)
#not,~
	elseif in_byte==(asciiequiv)
		return (TRUE)
	endelseif
	return (FALSE)
endfunction

#err
Function arg(sv ptrcontent,sd ptrsize,sd ptrdata,sd ptrlow,sd ptrsufix,sd sens,sd allowdata)
	sd szarg
	set szarg ptrsize#

	Data errnr#1
	SetCall errnr getarg(ptrcontent,ptrsize,szarg,allowdata,sens,ptrdata,ptrlow,ptrsufix)
	Return errnr
EndFunction

#err
Function argfilters(sd ptrcondition,sv ptrcontent,sd ptrsize,sd ptrdata,sd ptrlow,sd ptrsufix,sd allowdata)
	sd err
	setcall err argfilters_helper(ptrcondition,ptrcontent,ptrsize,ptrdata,ptrlow,ptrsufix,allowdata)
	if err==(noerror)
		#this is only at first arg
		call spaces(ptrcontent,ptrsize)
	endif
	return err
endfunction
#err
function argfilters_helper(sd ptrcondition,sv ptrcontent,sd ptrsize,sd ptrdata,sd ptrlow,sd ptrsufix,sd allowdata)
	Data null=NULL
	Data err#1
	Data forward=FORWARD

	If ptrcondition==null
		call unsetimm()
		SetCall err arg(ptrcontent,ptrsize,ptrdata,ptrlow,ptrsufix,forward,allowdata)
		Return err
	EndIf
	call setimm()

	Data content#1
	Data size#1
	Set content ptrcontent#
	Set size ptrsize#
	Data argsz#1

	#and same rule like getcommand like elseif then else
	Chars firstcomp="==";Data *jne=0x85
	Chars *="!=";        Data *je=0x84
	Chars *="<=^";       Data *ja=0x87
	Chars *=">=^";       Data *jb=0x82
	Chars *="<=";        Data *jg=0x8F
	Chars *=">=";        Data *jl=0x8C
	Chars *="<^";        Data *jae=0x83   #wanted cast before but will problem with arg cast that was after to continue at sufix
	Chars *=">^";        Data *jbe=0x86
	Chars *="<";         Data *jge=0x8D
	Chars *=">";         Data *jle=0x8E
	Chars term={0}

	Data ptr#1
	Data ptrini^firstcomp
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
			SetCall errnr getarg(ptrcontent,ptrsize,argsz,allowdata,forward,ptrdata,ptrlow,ptrsufix)
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
		SetCall sz strlen(ptr)
		Add ptr sz
		Add ptr (1+4)
		Set byte ptr#
	EndWhile
	Chars conderr="Condition sign(s) expected."
	Str _conderr^conderr
	Return _conderr
	Return err
EndFunction


function prefix_bool()
	data value#1
	data p^value
	return p
endfunction
