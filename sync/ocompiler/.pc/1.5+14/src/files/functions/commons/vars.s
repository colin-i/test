

#same or zero
function warn_or_log(sd type,sd return_value,ss symbolname,sd log_option,sd p_err)
	data ptrobject%ptrobject
	if ptrobject#==(TRUE)
		if log_option==(log_warn)
			add symbolname (dwsz)
			setcall p_err# addtolog_withchar(symbolname,type) #is not calling atunused version, that will return noerror at object false
			if p_err#==(noerror)
				return 0
			endif
		endif
	endif
	return return_value
endfunction

function vars_core_ref(ss content,sd size,sv ptrstructure,sv warningssearch,sd setref)
	sd data
	setcall data vars_core_ref_scope(content,size,ptrstructure,warningssearch,setref,(NULL))
	return data
endfunction

#null or a pointer to the constant/variable/function
function vars_core_ref_scope(ss content,sd size,sv ptrstructure,data warningssearch,sd setref,sd position_pointer)
	Data zero=0
	Data varsize#1
	Data dwlen=dwsz
	Data blen=bsz

	Str container#1
	Data containerReg#1
	Data ptrcontainer^container
	Data ptrcontainerReg^containerReg
	Call getcontandcontReg(ptrstructure,ptrcontainer,ptrcontainerReg)
	Data entrypoint#1

	While containerReg>zero
		Set entrypoint container
		Add container dwlen
		Sub containerReg dwlen
		If warningssearch!=(NULL)
			Data ReferenceBit=referencebit
			Data checkvalue#1
			Set checkvalue container#
			And checkvalue ReferenceBit
			data ptrconstants%ptrconstants;sd cb
			If checkvalue==zero
				data returnvalue#1
				set returnvalue entrypoint
				#
				data ptrfunctions%ptrfunctions
				if ptrfunctions==ptrstructure
					Set checkvalue container#
					sd against_idata=idatabitfunction
					and against_idata checkvalue
					if against_idata==0
						and checkvalue (x86_64bit)
						if checkvalue==0
							data ptrcodeFnObj%ptrcodeFnObj
							setcall returnvalue warn_or_log((log_function),returnvalue,container,ptrcodeFnObj#,warningssearch)
						else
							#functionx are extern
							set returnvalue 0
						endelse
					endif
				elseif ptrconstants==ptrstructure
					setcall cb constants_bool((const_warn_get))
					setcall returnvalue warn_or_log((log_constant),returnvalue,container,cb,warningssearch)
				endelseif
				if returnvalue!=zero
					Return returnvalue
				endif
			endIf
			#elseIf ptrconstants==ptrstructure 0x72
		EndIf
		Add container dwlen
		Sub containerReg dwlen
		SetCall varsize strlen(container)
		If warningssearch==(NULL)
			If varsize==size
				Data cmpret#1
				SetCall cmpret memcmp(container,content,size)
				If cmpret==zero
					#go back from string to mask
					Sub container dwlen

					#if set the reference is true
					if setref==1
						#get the value and change the reference bit of the mask to true
						Data value#1
						Set value container#
						Data referenceBit=referencebit
						Or value referenceBit
						Set container# value
					endif

					Return entrypoint
				EndIf
			EndIf
			if position_pointer!=(NULL)
				inc position_pointer#
			endif
		EndIf
		Add varsize blen
		Add container varsize
		Sub containerReg varsize
	EndWhile
	Return zero
endfunction

#null or a pointer to the constant/variable/function
Function varscore(str content,data size,data ptrstructure,data warningssearch)
	sd pointer
	setcall pointer vars_core_ref(content,size,ptrstructure,warningssearch,1)
	return pointer
EndFunction

#vars_core_ref
function vars_ignoreref(str content,data size,data ptrstructure)
	Data pointer#1
	Data false=FALSE
	SetCall pointer vars_core_ref(content,size,ptrstructure,(NULL),false)
	Return pointer
endfunction

#varscore
Function vars(str content,data size,data ptrstructure)
	Data pointer#1
	SetCall pointer varscore(content,size,ptrstructure,(NULL))
	Return pointer
EndFunction

function vars_number(ss content,sd size,sd number)
	sd pointer
	sd container
	setcall container getstructcont(number)
	setcall pointer vars(content,size,container)
	return pointer
endfunction

Const notype=0

#null or a pointer to the variable
Function searchinvars(str content,data size,data ptrtype,data warningssearch)
	Data data#1
	Data ptrcontainer#1

	Data i#1
	Data null=NULL
	Data nrofvars=numberofvars

	Set i 0
	While i<nrofvars
		SetCall ptrcontainer getstructcont(i)
		SetCall data varscore(content,size,ptrcontainer,warningssearch)
		If data!=null
			If warningssearch==null
				If ptrtype!=null
					Set ptrtype# i
				EndIf
			EndIf
			Return data
		endIf
		Inc i
	EndWhile
	Return null
EndFunction

#null or a pointer to the variable
Function searchinvars_scope(ss content,sd size,sd ptrtype,sd scope)
	sd data
	sd ptrcontainer
	sd i=0
	While i<(numberofvars)
		SetCall ptrcontainer getstructcont_scope(i,scope)
		SetCall data varscore(content,size,ptrcontainer,(NULL))
		If data!=(NULL)
			Set ptrtype# i
			Return data
		endIf
		Inc i
	EndWhile
	Return (NULL)
EndFunction
#null or a pointer to the variable
Function searchinvars_scope_warn(sd warningssearch,sd scope)
	sd data
	sd ptrcontainer
	sd i=0
	While i<(numberofvars)
		SetCall ptrcontainer getstructcont_scope(i,scope)
		SetCall data varscore((NULL),0,ptrcontainer,warningssearch)
		If data!=(NULL)
			Return data
		endIf
		Inc i
	EndWhile
	Return (NULL)
EndFunction

#searchinvars
Function strinvars(str content,data size,data ptrtype)
	Data pointer#1
	SetCall pointer searchinvars(content,size,ptrtype,(NULL))
	Return pointer
EndFunction

#err
Function undefinedvariable()
	Chars undefinedvar="Undefined variable name."
	Str _undefinedvar^undefinedvar
	Return _undefinedvar
EndFunction

const no_cast=-3
const cast_value=asciiV
const cast_data=asciiD
const cast_string=asciiS

#err
Function varsufix(ss content,sd size,sd ptrdata,sd ptrlow,sd ptrsufix)
	sd err
	setcall err varsufix_ex(content,size,ptrdata,ptrlow,ptrsufix,(NULL))
	return err
endfunction

#err
function varsufix_ex(ss content,sd size,sd ptrdata,sd ptrlow,sd ptrsufix,sd scope)
	Data type#1
	Data ptrtype^type
	Data false=FALSE
	Data true=TRUE
	sd err
	sd cast

	#size is expecting to be greater than zero
	setcall ptrsufix# sufix_test(content,#size,#cast)

	Data null=NULL
	Data data#1

	if scope==(NULL)
		SetCall data strinvars(content,size,ptrtype)
	else
		setcall data searchinvars_scope(content,size,ptrtype,scope)
	endelse
	If data==null
		SetCall err undefinedvariable()
		Return err
	EndIf
	Set ptrdata# data

	Data charsnumber=charsnumber
	sd prefix
	setcall prefix prefix_bool()

	If type==charsnumber
		If ptrsufix#==true
			Chars ptrsfxerr="CHARS statement cannot have the pointer sufix."
			Str _ptrsfxerr^ptrsfxerr
			Return _ptrsfxerr
		EndIf
		if prefix#==0
			Set ptrlow# true
		else
			#need all chars address at prefix
			set ptrlow# false
		endelse
		return (noerror)
	endIf

	sd is_str
	setcall is_str cast_resolve(type,cast,data)

	If is_str==false
		Set ptrlow# false
	Else
	#str ss
		If ptrsufix#==true
			if prefix#==0
				Set ptrlow# true
			else
				Set ptrlow# false
			endelse
		Else
			Set ptrlow# false
		EndElse
	EndElse
	return (noerror)
EndFunction

#sufix
function sufix_test(ss content,sd p_size,sd p_cast)
	add content p_size#
	dec content
	if content#!=(pointerascii)
		if content#==(asciicirc)
			setcall p_cast# cast_test(content,p_size)
			return (TRUE)
		endif
		set p_cast# (no_cast)
		return (FALSE)
	endif
	dec p_size#
	set p_cast# (no_cast)
	#and, allow prefix and sufix same time, for fun
	return (TRUE)
endfunction

#cast
function cast_test(ss content,sd p_size)
	if p_size#>=3 #test only the cast
		dec content
		sd c
		set c content#
		if c>=(a_from_az)
			sub c (az_to_AZ)
		endif
		if c==(cast_value)
		elseif c==(cast_data)
		elseif c==(cast_string)
		else
			set c (no_cast)
		endelse
		if c!=(no_cast)
			dec content
			if content#==(pointerascii)
				sub p_size# 3
				return c
			endif
		endif
	endif
	return (no_cast)
endfunction

#bool is_string
function cast_resolve(sd number,sd cast,sd data)
	if cast==(no_cast)
		Data stringsnumber=stringsnumber
		Data stackstringnumber=stackstringnumber
		if number==stringsnumber
			return (TRUE)
		elseif number==stackstringnumber
			return (TRUE)
		endelseif
		return (FALSE)
	endif
	if cast!=(cast_string)
		call store_argmask(data)
		add data (maskoffset)
		if cast==(cast_data)
			and data# (~pointbit)
		else
		#cast==(cast_value)
			or data# (pointbit)
		endelse
		return (FALSE)
	endif
	return (TRUE)
endfunction
