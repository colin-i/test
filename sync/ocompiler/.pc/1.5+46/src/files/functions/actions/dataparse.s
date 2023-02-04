

#err
Function entryvarsfns(data content,data size)
	Data notype=notype
	Data pointer#1
	SetCall pointer strinvars_ignoreref(content,size,notype)
	Data noerr=noerror
	Data zero=0
	If pointer==zero
		Data fns%ptrfunctions
		SetCall pointer vars_ignoreref(content,size,fns)
		If pointer==zero
			Return noerr
		EndIf
	EndIf

	Chars varfndup="Variable/Function name is already defined."
	Str ptrvarfndup^varfndup
	Return ptrvarfndup
EndFunction

#relocated offset or offset at objects
function get_img_vdata_dataReg()
		Data value#1
		Data inter#1

		Data ptrimageoff%ptrimagebaseoffset
		Data ptrdataoff%ptrstartofdata
		Data ptrdataSec%ptrdatasec
		Data ptrinter^inter

		Set value ptrimageoff#
		Set inter ptrdataoff#
		Add value inter

		Call getcontReg(ptrdataSec,ptrinter)
		Add value inter
		return value
endfunction

#err
Function addvarreference(data ptrcontent,data ptrsize,data valsize,data typenumber,data stackoffset,sd mask)
	#duplications
	Data content#1
	Set content ptrcontent#
	Data zero=0
	Data constantsnr=constantsnumber
	Data value#1
	Data errnr#1
	Data noerr=noerror
	data false=0

	If typenumber!=constantsnr
		SetCall errnr entryvarsfns(content,valsize)
		If errnr!=noerr
			Return errnr
		EndIf
		data stack#1
		data ptrS^stack
		call stackfilter(typenumber,ptrS)
		if stack==false
			setcall value get_img_vdata_dataReg()
		else
			if stackoffset==zero
				#stack free declared
				setcall value getramp_ebxrel()
				#data ebx_relative=ebxregnumber*tostack_relative
				#or mask ebx_relative
			else
				#stack function argument
				set value stackoffset
				#data ebp_relative=ebpregnumber*tostack_relative
				or mask (stack_relative)
			endelse
			or mask (stackbit)
			sd vbool
			if typenumber==(stackvaluenumber);set vbool (TRUE);else;setcall vbool sd_as_sv((sd_as_sv_bool),typenumber);endelse
			if vbool==(TRUE)
				or mask (pointbit)
			endif
		endelse
	Else
		Data structure#1
		SetCall structure getstructcont(constantsnr)
		Data pointer#1
		SetCall pointer vars(content,valsize,structure)
		If pointer!=zero
			Chars constdup="Constant name is already defined."
			Str pconstdup^constdup
			Return pconstdup
		EndIf
		setcall errnr addtolog_withchar_ex_atunused(content,valsize,(log_declare))
		If errnr!=noerr;Return errnr;EndIf
		Set value zero
	EndElse

	SetCall errnr addaref(value,ptrcontent,ptrsize,valsize,typenumber,mask)
	Return errnr
EndFunction

#err
function addvarreferenceorunref(data ptrcontent,data ptrsize,data valsize,data typenumber,data stackoffset,sd mask)
	data err#1
	data noerr=noerror

	Data zero=0
	If valsize==zero
		Chars _namecverr="Name for variable/constant expected."
		vStr namecverr^_namecverr
		Return namecverr
	EndIf

	data content#1
	set content ptrcontent#
	Chars firstchar#1
	Set firstchar content#
	Chars unrefsign="*"

	If firstchar!=unrefsign
		if firstchar==(asciicirc)   #throwless if on a throwing area
			If typenumber==(constantsnumber)
				Return "Unexpected throwless sign ('^') at constant declaration."
			EndIf
			dec valsize
			If valsize==zero
				Return namecverr
			endif
			or mask (aftercallthrowlessbit)
			call stepcursors(ptrcontent,ptrsize)
		elseIf typenumber!=(constantsnumber)
			sd global_err_pB;setcall global_err_pB global_err_pBool()
			if global_err_pB#==(FALSE)
				or mask (aftercallthrowlessbit)
			endif
		endelseif
		SetCall err addvarreference(ptrcontent,ptrsize,valsize,typenumber,stackoffset,mask)
		If err!=noerr
			Return err
		EndIf
	Else
		If typenumber==(constantsnumber)
			Chars unrefconstant="Unexpected unreference sign ('*') at constant declaration."
			vStr ptrunrefconstant^unrefconstant
			Return ptrunrefconstant
		EndIf
		Call advancecursors(ptrcontent,ptrsize,valsize)
		Return noerr
	EndElse
endfunction

#er
function getsign(str content,data size,str assigntype,data ptrsz,data typenumber,data stack,data ptrrelocbool)
	data true=TRUE
	data noerr=noerror
	Data valsize#1
	Chars equalsign=assignsign

	Set ptrrelocbool# (FALSE)

	SetCall valsize valinmem_pipes(content,size,equalsign,ptrsz)
	If valsize!=size
		Set assigntype# equalsign
		return noerr
	endif

	Chars reservesign=reserveascii
	SetCall valsize valinmem_pipes(content,size,reservesign,ptrsz)
	If valsize!=size
		Data constnr=constantsnumber
		If typenumber==constnr
			Chars constreserveerr="Unexpected reserve sign ('#') at constant declaration."
			Str ptrconstreserveerr^constreserveerr
			Return ptrconstreserveerr
		EndIf
		Set assigntype# reservesign
		return noerr
	endif

	Data charsnr=charsnumber
	Chars pointersign=pointersigndeclare
	SetCall valsize valinmem_pipes(content,size,pointersign,ptrsz)
	If valsize!=size
		If typenumber==charsnr
			#grep    stackfilter2 4
			if stack==(FALSE)
				Chars ptrchar="Incorrect pointer sign ('^') used at CHARS declaration."
				Str ptrptrchar^ptrchar
				Return ptrptrchar
			endif
		EndIf
		Set assigntype# pointersign
		If typenumber!=constnr
			Set ptrrelocbool# true
		EndIf
		return noerr
	endif

	Chars relsign="%"
	SetCall valsize valinmem_pipes(content,size,relsign,ptrsz)
	If valsize!=size
		Chars ptrrelchar="Incorrect relocation sign ('%') used at CHARS/CONST declaration."
		Str ptrptrrelchar^ptrrelchar
		If typenumber==charsnr
			#stackfilter2   grep5
			if stack==(FALSE)
				Return ptrptrrelchar
			endif
		ElseIf typenumber==constnr
			Return ptrptrrelchar
		EndElseIf
		Set assigntype# equalsign
		Set ptrrelocbool# true
		return noerr
	endif

	if stack==true
		chars nosign=nosign
		Set assigntype# nosign
		return noerr
	endif

	Chars _assignoperatorerr="One from the assign operators expected."
	Str assignoperatorerr^_assignoperatorerr
	Return assignoperatorerr
endfunction

#err
Function dataparse(sv ptrcontent,sd ptrsize,sd valsize,sd typenumber,sd stack,sd mask)
	Data false=FALSE
	Data err#1

	if stack!=false
		data totalmemvariables=totalmemvariables
		add typenumber totalmemvariables
	endif
	SetCall err addvarreferenceorunref(ptrcontent,ptrsize,valsize,typenumber,false,mask)
	Return err
EndFunction
