

#null or a pointer to the constant/variable/function
function vars_core_ref(str content,data size,data ptrstructure,data warningssearch,sd setref)
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
		Data true=TRUE
		Data false=FALSE
		If warningssearch==true
			Data ReferenceBit=referencebit
			Data checkvalue#1
			Set checkvalue container#
			And checkvalue ReferenceBit
			If checkvalue==zero
				data returnvalue#1
				set returnvalue entrypoint
				data ptrfunctions%ptrfunctions
				if ptrfunctions==ptrstructure
					Set checkvalue container#
					data idatabitfunction=idatabitfunction
					And checkvalue idatabitfunction
					if checkvalue==zero
						data ptrobject%ptrobject
						if ptrobject#==true
							data ignorecodeFnObj=ignorecodeFnObj
							data logcodeFnObj=logcodeFnObj
							data ptrcodeFnObj%ptrcodeFnObj
							if ptrcodeFnObj#==logcodeFnObj
								set returnvalue zero
								data ptrlogfile%ptrlogfile
								if ptrlogfile#!=-1
									data symbolname#1
									set symbolname container
									add symbolname dwlen
									str str1="Symbol(unused in the obj):"
									data log#1
									setcall log errorDefOut(str1,symbolname)
									call addtolog(log)
									call clearmessage()
								endif
							elseif ptrcodeFnObj#==ignorecodeFnObj
								set returnvalue zero
							endelseif
						endif
					endif
				endif
				if returnvalue!=zero
					Return returnvalue
				endif
			EndIf
		EndIf
		Add container dwlen
		Sub containerReg dwlen
		SetCall varsize strlen(container)
		If warningssearch==false
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
	SetCall pointer vars_core_ref(content,size,ptrstructure,false,false)
	Return pointer
endfunction

#varscore
Function vars(str content,data size,data ptrstructure)
	Data pointer#1
	Data false=FALSE
	SetCall pointer varscore(content,size,ptrstructure,false)
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

	Set i null

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
		Else
			Inc i
		EndElse
	EndWhile
	Return null
EndFunction

#searchinvars
Function strinvars(str content,data size,data ptrtype)
	Data pointer#1
	Data false=FALSE
	SetCall pointer searchinvars(content,size,ptrtype,false)
	Return pointer
EndFunction

#err
Function undefinedvariable()
	Chars undefinedvar="Undefined variable name."
	Str _undefinedvar^undefinedvar
	Return _undefinedvar
EndFunction

#bool
function is_string(sd number)
	Data stringsnumber=stringsnumber
	Data stackstringnumber=stackstringnumber
	data true=1
	data false=0
	if number==stringsnumber
		return true
	elseif number==stackstringnumber
		return true
	endelseif
	return false
endfunction

#err
Function varsufix(str content,data size,data ptrdata,data ptrlow,data ptrsufix)
	Data type#1
	Data ptrtype^type
	Data false=FALSE
	Data true=TRUE
	
	#size is expecting to be greater than zero
	Str viewsfx#1
	Set viewsfx content
	Add viewsfx size
	Dec viewsfx
	Chars nrsgn="#"
	Chars test#1
	Set test viewsfx#
	Data sufix#1
	If test==nrsgn
		Dec size
		Set sufix true
		#and, allow prefix and sufix same time, for fun
	Else
		Set sufix false
	EndElse
	
	Data null=NULL
	Data data#1

	SetCall data strinvars(content,size,ptrtype)

	If data==null
		Data err#1
		SetCall err undefinedvariable()
		Return err
	EndIf

	Set ptrdata# data

	Data charsnumber=charsnumber
	sd is_str
	setcall is_str is_string(type)
	
	sd prefix
	setcall prefix prefix_bool()
	If type==charsnumber
		If sufix==true
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
	ElseIf is_str==false
		Set ptrlow# false
	Else
		If sufix==true
			if prefix#==0
				Set ptrlow# true
			else
				Set ptrlow# false
			endelse
		Else
			Set ptrlow# false
		EndElse
	EndElse

	Set ptrsufix# sufix
	
	Data noerr=noerror
	Return noerr
EndFunction