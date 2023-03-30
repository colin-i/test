


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
	Char spc=asciispace
	Char tab=asciitab
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

function extend_arg_size(ss content,sd sizetoverify,sd p_argsize)
	sub sizetoverify p_argsize#
	if sizetoverify!=0
		add content p_argsize#
		sd marker;set marker content
		ss test;set test content
		dec test	##argsize is not 0
		if test#!=(pointerascii)
			if test#!=(castascii)
				call spaces(#content,#sizetoverify)
				if sizetoverify!=0
					if content#==(pointerascii)
						call stepcursors(#content,#sizetoverify)
						if sizetoverify!=0
							if content#==(pointerascii)
								#this " ##" is the only line end comment after sufix and allowing spaces
								ret
							endif
							#this disallow "arg #comment"
							addcall p_argsize# find_whitespaceORcomment(content,sizetoverify)
						endif
						#and not letting "arg #" as comment to not regret later
						sub content marker
						add p_argsize# content
					endif
				endif
			endif
		endif
	endif
endfunction
function extend_sufix_test(ss content,sd p_size)
	while p_size#!=0
		dec content
		sd b;setcall b is_whitespace(content#)
		if b==(FALSE)
			ret
		endif
		dec p_size#
	endwhile
endfunction

#err
Function getarg(sv ptrcontent,sd ptrsize,sd argsize,sd allowdata,sd sens,sd ptrdata,sd ptrlow,sd ptrsufix)
	ss content
	sd size
	sd errnr

	char d_q=getarg_str

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
				if allowdata==(allow_yes)
					#at last/only argument it is better to allow space before sufix to not regret later
					#"##" will be a comment and "#" a sufix
					call extend_arg_size(content,size,#argsize)
				endif
				sd argsize_filter
				sd container_sz
				if content#==(pointerascii)
					#prefix
					setcall prefix prefix_bool()
					set prefix# 1
					inc content
					set argsize_filter argsize
					dec argsize_filter

					#class test
					setcall container_sz valinmem(content,argsize_filter,(asciicolon))
					if container_sz!=argsize_filter
						setcall errnr getarg_colon(content,argsize_filter,container_sz,ptrdata,ptrlow,ptrsufix)
					else
						setcall errnr getarg_testdot(content,argsize_filter,ptrdata,ptrlow,ptrsufix)
					endelse
					if errnr!=(noerror)
						return errnr
					endif
				else
					data ptrobject%ptrobject
					data ptrfunctions%%ptr_functions

					#class test
					setcall container_sz valinmem(content,argsize,(asciicolon))
					if container_sz!=argsize
						setcall errnr getarg_colon(content,argsize,container_sz,ptrdata,ptrlow,ptrsufix)
						if errnr!=(noerror)
							return errnr
						endif
					else
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
	sd errnr
	sd scope
	setcall errnr get_scope(#content,#argsize,container_sz,#scope)
	if errnr!=(noerror)
		return errnr
	endif
	SetCall errnr varsufix_ex(content,argsize,ptrdata,ptrlow,ptrsufix,scope)
	if errnr!=(noerror)
		return errnr
	endif
	sd test;setcall test stackbit(ptrdata#)
	if test==0
		return (noerror)
	endif
	setcall errnr there_is_nothing_there()
	return errnr
endfunction
#er
#function getarg_colon(sd content,sd argsize,sd container_sz,sv ptrdata,sd ptrlow,sd ptrsufix)
#	sd data
#	sd err
#	sd scope
#	sd nr
#	sd subtract_base
#	sd part_sz

#	setcall part_sz valinmem(content,container_sz,(asciidot))
#	sub argsize container_sz
#	if part_sz!=container_sz
#		setcall err get_scope(#content,#container_sz,part_sz,#scope)
#		if err!=(noerror)
#			return err
#		endif
#		setcall data searchinvars_scope(content,container_sz,#nr,scope)
#		if data==(NULL)
#			setcall err undefinedvariable()
#			return err
#		endif
#		if nr<(totalmemvariables)
#			sd entrybags%%ptr_scopes
#			if scope!=entrybags
#				#stored class info
#				setcall subtract_base scopes_get_class_data(scope,data) # test expandbit is inside
#			else
#				setcall subtract_base get_img_vdata() #or img_nbdata if exec will have (test expandbit)
#			endelse
#		else
#			#stack
#			set subtract_base 0
#		endelse
#	else
#		setcall data strinvars(content,container_sz,#nr)
#		if data==(NULL)
#			setcall err undefinedvariable()
#			return err
#		endif
#		if nr<(totalmemvariables)
#			sd ptrinnerfunction%globalinnerfunction
#			if ptrinnerfunction#==(TRUE)
#				sd ptrfunctionTagIndex%ptrfunctionTagIndex
#				setcall scope scopes_get_scope(ptrfunctionTagIndex#)
#				setcall subtract_base scopes_get_class_data(scope,data)
#			else
#				setcall subtract_base get_img_vdata() #or img_nbdata if exec will have (test expandbit)
#			endelse
#		else
#			#stack
#			set subtract_base 0
#		endelse
#	endelse

#	#this offset will be added
#	sd val;set val data#
#	sub val subtract_base

#	add content container_sz
#	call stepcursors(#content,#argsize)

#	#get location and mask
#	setcall err getarg_testdot(content,argsize,ptrdata,ptrlow,ptrsufix)
#	if err!=(noerror)
#		return err
#	endif

#	char random#1
#	data *#2    #ignore name
#	#in case are two args
#	data *#2    #ignore name
#	call tempdatapair(#random,ptrdata)
#	sd pointer;set pointer ptrdata#
#	add pointer# val
#	return (noerror)
#endfunction
#er
function getarg_colon(sd content,sd argsize,sd container_sz,sv ptrdata,sd ptrlow,sd ptrsufix)
	#first test if has runtime pointer
	sd pointer_size=0
	if container_sz!=0
		# !=0? yes, example: ":"
		ss cursor=-1
		add cursor content
		add cursor container_sz
		if cursor#==(pointerascii)
			dec container_sz
			inc pointer_size
		endif
	endif
	sd data
	sd err
	sd scope
	sd is_stack
	sd part_sz;setcall part_sz valinmem(content,container_sz,(asciidot))
	sub argsize container_sz
	if part_sz!=container_sz
		setcall err get_scope(#content,#container_sz,part_sz,#scope)
		if err!=(noerror)
			return err
		endif
		sd nr;setcall data searchinvars_scope(content,container_sz,#nr,scope)
		if data==(NULL)
			setcall err undefinedvariable()
			return err
		endif
		if nr>=(totalmemvariables)
			setcall err there_is_nothing_there()
			return err
		endif
		set is_stack 0   #use later when keeping location
	else
		setcall data searchinvars(content,container_sz,(NULL),(NULL),1)
		if data==(NULL)
			setcall err undefinedvariable()
			return err
		endif
		setcall is_stack stackbit(data)
	endelse
	add content container_sz
	call advancecursors(#content,#argsize,pointer_size)
	call stepcursors(#content,#argsize)

	sd subtract_base
	sd test
	setcall container_sz valinmem(content,argsize,(asciidot))
	if container_sz!=argsize
		setcall err get_scope(#content,#argsize,container_sz,#scope)
		if err!=(noerror)
			return err
		endif
		SetCall err varsufix_ex(content,argsize,ptrdata,ptrlow,ptrsufix,scope)
		if err!=(noerror)
			return err
		endif
		setcall test stackbit(ptrdata#)
		if test==0
			sd entrybags%%ptr_scopes
			if scope!=entrybags
				#stored class info
				setcall subtract_base scopes_get_class_data(scope,ptrdata) # test expandbit is inside
			else
				setcall subtract_base get_img_vdata() #or img_nbdata if exec will have (test expandbit)
			endelse
		else
			setcall subtract_base stack64_base(ptrdata)
		endelse
	else
		SetCall err varsufix(content,argsize,ptrdata,ptrlow,ptrsufix)
		if err!=(noerror)
			return err
		endif
		setcall test stackbit(ptrdata#)
		if test==0
			sd ptrinnerfunction%globalinnerfunction
			if ptrinnerfunction#==(TRUE)
				sd ptrfunctionTagIndex%ptrfunctionTagIndex
				setcall scope scopes_get_scope(ptrfunctionTagIndex#)
				setcall subtract_base scopes_get_class_data(scope,ptrdata)
			else
				setcall subtract_base get_img_vdata() #or img_nbdata if exec will have (test expandbit)
			endelse
		else
			setcall subtract_base stack64_base(ptrdata)
		endelse
	endelse
	char random#1
	data *#3
	#in case are two args
	data d2#3
	call tempdatapair(#random,ptrdata,#d2)

	sd pointer;set pointer ptrdata#
	sub pointer# subtract_base

	#keep location, will be some disturbance if combining stack with data, but if not is ok
	sd pointer2=maskoffset;sd data2=maskoffset
	add pointer2 pointer
	add data2 data
	sd location_part;sd transformation_part
	if is_stack!=0
		set location_part (stack_location_bits)
		and location_part data2#
		set transformation_part (~stack_location_bits)
	else
		set location_part (location_bits)
		and location_part data2#
		set transformation_part (~location_bits)
	endelse
	and pointer2# transformation_part
	or pointer2# location_part

	#decide if add offset now or at runtime with sufix
	if pointer_size!=0
		#runtime
		or pointer2# (suffixbit)
		add pointer2 (masksize)
		set pointer2# pointer#
		set pointer# data#
	else
		add pointer# data#
	endelse

	return (noerror)
endfunction
#err
function getarg_testdot(sd content,sd size,sd ptrdata,sd ptrlow,sd ptrsufix)
	sd errnr
	sd container_sz
	setcall container_sz valinmem(content,size,(asciidot))
	if container_sz!=size
		setcall errnr getarg_dot(content,size,container_sz,ptrdata,ptrlow,ptrsufix)
	else
		SetCall errnr varsufix(content,size,ptrdata,ptrlow,ptrsufix)
	endelse
	return errnr
endfunction

function there_is_nothing_there()
	return "Stack variables are not relevant for scope.variable."
endfunction

#err
function get_scope(sv pcontent,sd psize,sd sz,sv pscope)
	data ptrfunctions%%ptr_functions
	sd var
	sd pos=0
	setcall var vars_core_ref_scope(pcontent#,sz,ptrfunctions,(NULL),(TRUE),#pos)
	if var==(NULL)
		return "Undefined function name."
	endif
	inc sz
	call advancecursors(pcontent,psize,sz)
	setcall pscope# scopes_get_scope(pos)
	return (noerror)
endfunction

function function_in_code()
	data bool#1
	return #bool
endfunction

function is_constant_related_ascii(sd in_byte)
# ! data cursor
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
# : size of integer
	elseif in_byte==(asciicolon)
		return (TRUE)
# not,~
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
	Char firstcomp="==";Data *jne=0x85
	Char *="!=";        Data *je=0x84
	Char *="<=^";       Data *ja=0x87
	Char *=">=^";       Data *jb=0x82
	Char *="<=";        Data *jg=0x8F
	Char *=">=";        Data *jl=0x8C
	Char *="<^";        Data *jae=0x83   #wanted cast before but will problem with arg cast that was after to continue at sufix
	Char *=">^";        Data *jbe=0x86
	Char *="<";         Data *jge=0x8D
	Char *=">";         Data *jle=0x8E
	Char term={0}

	Data ptr#1
	Data ptrini^firstcomp
	Char byte#1

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
	Char conderr="Condition sign(s) expected."
	Str _conderr^conderr
	Return _conderr
	Return err
EndFunction


function prefix_bool()
	data value#1
	data p^value
	return p
endfunction
