
#err
Function unresolvedcallsfn(data struct,data inneroffset,data atend,data valuedata)
	data structure#1
	Data offset#1
	data addatend#1

	Data poff^offset
	Call getcontReg(struct,poff)
	add offset inneroffset

	Data err#1
	Data true=TRUE
	Data ptrobject%ptrobject

	If ptrobject#==true
		Data ptrextra%ptrextra
		SetCall err addrel_base(offset,valuedata,atend,ptrextra)
	Else
		#add to resolve at end
		Data unressz=3*dwsz
		Data uncall%ptrunresolvedcalls
		data ptrstruct^structure

		set structure struct
		set addatend atend

		SetCall err addtosec(ptrstruct,unressz,uncall)
	EndElse
	Return err
EndFunction

#b
function is_funcx_subtype(sd subtype)
	if subtype==(cFUNCTIONX)
		return (TRUE)
	elseif subtype==(cENTRY)
		return (TRUE)
	endelseif
	return (FALSE)
endfunction
#subtype is only when declarefn(not callfn)
#err
Function parsefunction(data ptrcontent,data ptrsize,data declare,sd subtype)
	Data true=TRUE
	Data false=FALSE

	Data zero=0
	Data fns%ptrfunctions
	Data code%ptrcodesec

	Data err#1
	Data noerr=noerror

	Str content#1
	Data size#1
	Data sz#1

	Set content ptrcontent#
	Set size ptrsize#

	SetCall sz valinmem(content,size,(asciiparenthesisstart))
	If sz==zero
		Chars funnameexp="Function name expected."
		Str fnerr^funnameexp
		Return fnerr
	EndIf
	If sz==size
		Chars startfnexp="Open parenthesis sign ('(') expected."
		Str starterr^startfnexp
		Return starterr
	EndIf

	If declare==true
		Data fnnr=functionsnumber
		Data value#1
		Data ptrvalue^value

		sd scope64
		data p_two_parse%cptr_twoparse
		if p_two_parse#==2
			Data globalinnerfunction%globalinnerfunction
			#set for searching in the main scope for unique value
			Data aux#1
			Set aux globalinnerfunction#
			Set globalinnerfunction# false
			SetCall err entryvarsfns(content,sz)
			If err!=noerr
				Return err
			EndIf
			Set globalinnerfunction# aux

			#is objfnmask related to the introduction of entry tag at objects, is interacting there
			Data mask#1
			Data ptrobjfnmask%ptrobjfnmask
			Set mask ptrobjfnmask#

			setcall scope64 is_funcx_subtype(subtype)
			if scope64==(TRUE)
				or mask (x86_64bit)
			endif
			SetCall err addaref(value,ptrcontent,ptrsize,sz,fnnr,mask)
			If err!=noerr
				Return err
			EndIf
			#skip the rest of the command at recon
			Call advancecursors(ptrcontent,ptrsize,ptrsize#)
			return noerr
		else
			sd pointer
			setcall pointer vars_ignoreref(content,sz,fns)
			Call advancecursors(ptrcontent,ptrsize,sz)

			#add the function name to the code section if the option is set
			sd fn_text
			setcall fn_text fn_text_info()
			if fn_text#==1
				sd fn_name
				set fn_name pointer
				add fn_name (nameoffset)
				sd len
				setcall len strlen(fn_name)
				inc len
				SetCall err addtoCode_set_programentrypoint(fn_name,len)
				If err!=(noerror)
					Return err
				EndIf
			endif

			Call getcontReg(code,ptrvalue)
			set pointer# value

			#resolve the previous calls at this value
			Data ptrobject%ptrobject
			If ptrobject#==true
				Data STT_FUNC=STT_FUNC
				Data codeind=codeind
				Data ptrtable%ptrtable
				if subtype!=(cFUNCTION)
				#entries are also not local
					SetCall err elfaddstrszsym(content,sz,value,zero,STT_FUNC,(STB_GLOBAL),codeind,ptrtable)
				else
					SetCall err elfaddstrszsym(content,sz,value,zero,STT_FUNC,(STB_WEAK),codeind,ptrtable)
				endelse
				If err!=noerr
					Return err
				EndIf
			EndIf

			setcall scope64 is_funcx_subtype(subtype)
			#functionx,entry in 64 conventions
			#entrylinux has no return but has argc,aexec,a1...an
			if scope64==(TRUE)
				setcall scope64 is_for_64()
				if scope64==(TRUE)
					setcall err function_start_64()
					If err!=noerr
						Return err
					EndIf
				endif
				call scope64_set(scope64)
			elseif subtype==(cENTRYLINUX)
				#scope64 not using, never get into getreturn here
				setcall err entrylinux_top();if err!=noerr;Return err;EndIf
			else
				#cFUNCTION
				call scope64_set((FALSE))
			endelse
		endelse
	Else
		data boolindirect#1
		Data ptrdata#1
		setcall err prepare_function_call(ptrcontent,ptrsize,sz,#ptrdata,#boolindirect)
		if err!=(noerror)
			return err
		endif
	EndElse

	Call stepcursors(ptrcontent,ptrsize)
	data ptr_sz^sz
	setcall err parenthesis_size(ptrcontent#,ptrsize#,ptr_sz)
	if err!=noerr
		return err
	endif

	If declare==true
		If sz!=zero
			SetCall err enumcommas(ptrcontent,ptrsize,sz,declare,fnnr) #there are 3 more arguments but are not used
			if err!=noerr
				return err
			endif
		EndIf
		call entryscope()
	Else
		sd bool;setcall bool is_for_64_is_impX_or_fnX_get()
		if bool==(FALSE)
			if sz!=zero
				SetCall err enumcommas(ptrcontent,ptrsize,sz,declare,(TRUE)) #there are 3 more arguments but are not used
			endif
		else
			sd p;setcall p nr_of_args_64need_p_get();set p# 0 #also at 0 at win will be sub all shadow space
			if sz!=zero
				set content ptrcontent#
				set size ptrsize#
				SetCall err enumcommas(ptrcontent,ptrsize,sz,declare,(FALSE)) #there are 3 more arguments but are not used
				if err==noerr
					setcall err stack_align(p#)
					if err==noerr
						set ptrcontent# content
						set ptrsize# size
						SetCall err enumcommas(ptrcontent,ptrsize,sz,declare,(TRUE)) #there are 3 more arguments but are not used
					endif
				endif
			else
				setcall err stack_align(0)
			endelse
		endelse
		If err==noerr
			setcall err write_function_call(ptrdata,boolindirect,(FALSE))
			if err!=noerr
				return err
			endif
		EndIf
	EndElse
	Call stepcursors(ptrcontent,ptrsize)
	Return noerr
EndFunction
#p
function fn_text_info()
	data text_info#1
	return #text_info
endfunction

#err
function prepare_function_call(sd pcontent,sd psize,sd sz,sd p_data,sd p_bool_indirect)
	Data fns%ptrfunctions

	SetCall p_data# vars(pcontent#,sz,fns)
	If p_data#==0
		setcall p_data# vars_number(pcontent#,sz,(integersnumber))
		If p_data#==0
			setcall p_data# vars_number(pcontent#,sz,(stackdatanumber))
			If p_data#==0
				setcall p_data# vars_number(pcontent#,sz,(stackvaluenumber))
				If p_data#==0
					Chars unfndeferr="Undefined function/data call."
					Str ptrunfndef^unfndeferr
					Return ptrunfndef
				EndIf
			EndIf
		EndIf
		set p_bool_indirect# (TRUE)
	Else
		#at functions
		call is_for_64_is_impX_or_fnX_set(p_data#)
		set p_bool_indirect# (FALSE)
	EndElse
	Call advancecursors(pcontent,psize,sz)

	#move over the stack arguments, ebx is also shorting the first stack variable (mov rbx,rdx)
	#mov esp,ebx
	Data code%ptrcodesec
	sd err
	#
	setcall err rex_w_if64();if err!=(noerror);return err;endif
	#
	chars espebx={moveatregthemodrm,0xe3}
	Str ptrespebx^espebx
	Data sizeespebx=2
	SetCall err addtosec(ptrespebx,sizeespebx,code)
	Return err
endfunction

#err
function write_function_call(sd ptrdata,sd boolindirect,sd is_callex)
	sd err
	Data code%ptrcodesec

	sd pb;setcall pb is_for_64_is_impX_or_fnX_p_get()
	if pb#==(TRUE)
		setcall err function_call_64(is_callex)
		If err!=(noerror);Return err;EndIf
		set pb# (FALSE) #can be at start but intern function are more popular and there is also a test in addition
	endif

	Data ptrfnmask#1
	Set ptrfnmask ptrdata
	Add ptrfnmask (maskoffset)

	Data fnmask#1
	Data idatafn=idatabitfunction
	Data ptrobject%ptrobject
	Set fnmask ptrfnmask#
	And fnmask idatafn

	If ptrobject#==(FALSE)
		If fnmask==idatafn
			Set boolindirect (TRUE)
		EndIf
	EndIf

	If boolindirect==(FALSE)
		Chars directcall#1
		Data directcalloff#1

		Data ptrdirectcall^directcall
		const directcallsize=1+dwsz
		data ptrdirectcalloff^directcalloff

		If fnmask!=idatafn
			set directcall 0xe8
			setcall err unresolvedLocal(1,code,ptrdata,ptrdirectcalloff)
			If err!=(noerror);Return err;EndIf
			SetCall err addtosec(ptrdirectcall,(directcallsize),code)
		Else
			#was: reloc when linking;0-dwsz(appears to be dwsz from Data directcallsize=1+dwsz), no truncation, so direct better
			set directcall 0xb8
			Set directcalloff 0
			sd relocoff
			setcall relocoff reloc64_offset(1)
			SetCall err unresolvedcallsfn(code,relocoff,directcalloff,ptrdata#);If err!=(noerror);Return err;EndIf
			setcall err reloc64_ante();If err!=(noerror);Return err;EndIf
			SetCall err addtosec(ptrdirectcall,(directcallsize),code);If err!=(noerror);Return err;EndIf
			setcall err reloc64_post();If err!=(noerror);Return err;EndIf
			chars callcode={0xff,0xd0}
			setcall err addtosec(#callcode,2,code)
		EndElse
	Else
		#this at object is call data() but the reloc is outside of this function
		if fnmask==idatafn
			data ptrvirtualimportsoffset%ptrvirtualimportsoffset
			SetCall err unresolvedcallsfn(code,1,ptrvirtualimportsoffset) #,ptrdata#
			If err!=(noerror);Return err;EndIf
		endif
		Chars callaction={0xff}
		Data noreg=noregnumber
		Chars callactionopcode={2}
		Data eaxregnumber=eaxregnumber
		call stack64_op_set()
		SetCall err writeoperation(ptrdata,callaction,noreg,(FALSE),callactionopcode,eaxregnumber)#last missing param is at sufix and at declare is not
	EndElse
	If err!=(noerror)
		Return err
	EndIf

	sd global_err_pB;setcall global_err_pB global_err_pBool()
	if global_err_pB#!=(FALSE)
		sd global_err_ptr;setcall global_err_ptr global_err_p()
		Data ptrextra%ptrextra
		If ptrobject#==(FALSE)
		#absolute
			const global_err_ex_start=!
			#mov ecx,imm32
			chars g_err_mov=0xb8+ecxregnumber;data g_err_mov_disp32#1
			#cmp byte[ecx],0
			chars *={0x80,7*toregopcode|ecxregnumber};chars *=0
			const global_err_ex_sz=!-global_err_ex_start
			#add rel,1 is (b8+ecx), one byte
			set g_err_mov_disp32 global_err_ptr#
			#
			SetCall err addtosec(#g_err_mov,(global_err_ex_sz),code)
		Else
			#mov to ecx is reseting the high part of the rcx
			chars g_err=0xb9
			data *rel=0
			#
			sd af_relof
			setcall af_relof reloc64_offset((bsz))
			setcall err adddirectrel_base(ptrextra,af_relof,global_err_ptr#,0);If err!=(noerror);Return err;EndIf
			setcall err reloc64_ante();If err!=(noerror);Return err;EndIf
			SetCall err addtosec(#g_err,5,code);If err!=(noerror);Return err;EndIf
			setcall err reloc64_post();If err!=(noerror);Return err;EndIf
			chars g_cmp={0x80,7*toregopcode|ecxregnumber,0}
			SetCall err addtosec(#g_cmp,3,code)
		EndElse
		If err!=(noerror);Return err;EndIf
		#jz
		chars g_err_jz=0x74;chars ret_end_sz#1
		#
		ss ret_end_p
		sd is_linux_term;setcall is_linux_term is_linux_end()
		if is_linux_term==(TRUE)
			#int 0x80, sys_exit, eax 1,ebx the return number
			const g_err_sys_start=!
			chars g_err_sys={0x8b,ebxregnumber*toregopcode|0xc0|eaxregnumber}
			chars *={0xb8,1,0,0,0}
			Chars *={intimm8,0x80}
			const g_err_sys_size=!-g_err_sys_start
			set ret_end_sz (g_err_sys_size)
			set ret_end_p #g_err_sys
		else
			setcall ret_end_sz getreturn(#ret_end_p)
		endelse
		SetCall err addtosec(#g_err_jz,(bsz+bsz),code);If err!=(noerror);Return err;EndIf
		#return
		SetCall err addtosec(ret_end_p,ret_end_sz,code);If err!=(noerror);Return err;EndIf
	endif

	return err
endfunction

#p
function global_err_p()
	data e#1
	return #e
endfunction
#p
function global_err_pBool()
	data bool#1
	return #bool
endfunction

#bool
function is_linux_end()
	sd p_real_exit_end%p_real_exit_end
	return p_real_exit_end#
endfunction
#er
function entrylinux_top()
	chars s={0x6a,0}
	data code%ptrcodesec
	sd err
	setcall err addtosec(#s,2,code)
	return err
endfunction
