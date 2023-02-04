
data nul_res_pref#1
const p_nul_res_pref^nul_res_pref

data inplace_reloc_pref#1
const p_inplace_reloc_pref^inplace_reloc_pref
const zero_reloc=0
const addend_reloc=1

#bool for err2
Function warnings(sd searchInAll,sd includes,sd nameoffset,sd p_err)
	Data warningsboolptr%ptrwarningsbool
	Data warningsbool#1
	Data null=NULL
	Data true=TRUE

	Set warningsbool warningsboolptr#
	If warningsbool==true
		Data var#1
		SetCall var searchinvars(null,null,null,p_err)
		If var==null
			If searchInAll==true
				data ptrcodeFnObj%ptrcodeFnObj
				if ptrcodeFnObj#!=(ignore_warn)
					Data functionsptr%ptrfunctions
					SetCall var varscore(null,null,functionsptr,p_err)
				endif
				if var==null
					sd cb;setcall cb constants_bool((const_warn_get))
					if cb!=(ignore_warn)
						data constantsptr%ptrconstants
						SetCall var varscore(null,null,constantsptr,p_err)
					endif
				endif
			EndIf
		EndIf
		If var!=null
			if p_err#==(noerror)
				Chars unrefformat="Unreferenced variable/function/constant: %s. Scope Termination File: %s. To disable this warning see '.ocompiler.txt'"
				Str ptrunrefformat^unrefformat

				Data printbuffer#1

				Data fileoff=nameoffset
				Add var fileoff
				Add includes nameoffset
				SetCall printbuffer printbuf(ptrunrefformat,var,includes,0)
				If printbuffer!=null
					sd pallocerrormsg%ptrallocerrormsg
					set pallocerrormsg# printbuffer
				EndIf
				Call safeMessage(printbuffer)
				sd w%p_w_as_e
				if w#==(TRUE)
					set p_err# ""
					return (FALSE)
				endif
			endif
		EndIf
	EndIf
	return (TRUE)
EndFunction

#void
#parse and set the value, 0-9(one digit) values are expected here
function parsepreferences(sd ptrcontent,sd ptrsize,sd strs_pointers)
	Chars searchsign="="
	Data sizeuntilsign#1

	str content#1
	data size#1
	set content ptrcontent#
	set size ptrsize#

	SetCall sizeuntilsign valinmem(content,size,searchsign)
	call advancecursors(ptrcontent,ptrsize,sizeuntilsign)

	If sizeuntilsign!=size
		sd backp;setcall backp parsepreferences_back(sizeuntilsign,ptrcontent#,strs_pointers)
		Call stepcursors(ptrcontent,ptrsize)
		if backp!=(NULL)
			set size ptrsize#
			If size!=0
				set content ptrcontent#
				Call stepcursors(ptrcontent,ptrsize)
				Set backp# content#
				Sub backp# (asciizero)
			endIf
		endif
	EndIf
endfunction
#pointer/null
function parsepreferences_back(sd sizeback,ss content,sd strs_pointers)
	sd end;set end strs_pointers
	add end (nr_of_prefs_jumper)
	while strs_pointers!=end
		sd i
		ss s;set s strs_pointers#
		setcall i strlen(s)
		if sizeback>=i
			ss e;set e s;add e i
			sd b
			setcall b parsepreferences_back_helper(content,e,s)
			if b==(TRUE)
				#and put this to last to not get it again without a fight
				sd test;set test strs_pointers
				sd test2;set test2 test;sub test2 (nr_of_prefs_jumper)
				sd return
				set return test2#
				sd store
				set store strs_pointers#
				sd test3;set test3 test2
				sub end :
				while test!=end
					incst test;incst test2
					set strs_pointers# test#
					set test3# test2#
					incst strs_pointers;incst test3
				endwhile
				set test# store
				set test2# return
				return return
			endif
		endif
		incst strs_pointers
	endwhile
	return (NULL)
endfunction
#bool
function parsepreferences_back_helper(ss content,ss e,ss s)
	while s!=e
		dec content
		dec e
		if content#!=e#
			return (FALSE)
		endif
	endwhile
	return (TRUE)
endfunction

function initpreferences()
	#defaults
	sd ptrwarningsbool%ptrwarningsbool
	sd p_over_pref%p_over_pref
	sd p_hidden_pref%p_hidden_pref
	sd p_w_as_e%p_w_as_e
	sd ptrlogbool%ptrlogbool
	sd ptrcodeFnObj%ptrcodeFnObj
	sd cb;setcall cb constants_bool((const_warn_get_init))
	sd ptrincludedir%ptrincludedir
	sd text_fn_info;setcall text_fn_info fn_text_info()
	sd conv_64;setcall conv_64 p_neg_is_for_64()
	sd p_nul_res_pref%p_nul_res_pref
	sd sdsv_p;setcall sdsv_p sd_as_sv((sd_as_sv_get))
	sd p_inplace_reloc_pref%p_inplace_reloc_pref
	sd p_pref_reloc_64%p_pref_reloc_64
	sd p_underscore_pref%p_underscore_pref
	sd p_exit_end%p_exit_end

	data true=TRUE
	data false=FALSE

	set ptrwarningsbool# true
	set p_over_pref# true
	set p_hidden_pref# true
	set p_w_as_e# true
	set ptrlogbool# true
	set ptrcodeFnObj# (log_warn)
	set cb# (log_warn)
	set ptrincludedir# true
	set text_fn_info# false
	set conv_64# (direct_convention_input)
	set p_nul_res_pref# false
	set sdsv_p# false
	set p_inplace_reloc_pref# (addend_reloc)
	set p_pref_reloc_64# true
	set p_underscore_pref# false
	set p_exit_end# false

	#this is used also at arguments

	sv q%nr_of_prefs_pointers_p
	set q# ptrwarningsbool;incst q; set q# p_over_pref;incst q; set q# p_hidden_pref;incst q; set q# p_w_as_e;incst q; set q# ptrlogbool;incst q; set q# ptrcodeFnObj;incst q; set q# cb;incst q;           set q# ptrincludedir;incst q; set q# text_fn_info;incst q;    set q# conv_64;incst q;   set q# p_nul_res_pref;incst q; set q# sdsv_p;incst q;     set q# p_inplace_reloc_pref;incst q; set q# p_pref_reloc_64;incst q; set q# p_underscore_pref;incst q; set q# p_exit_end
	sv t%nr_of_prefs_strings_p
	set t# "warnings";incst t;      set t# "over_pref";incst t; set t# "hidden_pref";incst t; set t# "w_as_e";incst t; set t# "logfile";incst t;  set t# "codeFnObj";incst t;  set t# "const_warn";incst t; set t# "includedir";incst t;  set t# "function_name";incst t; set t# "conv_64";incst t; set t# "nul_res_pref";incst t; set t# "sd_as_sv";incst t; set t# "inplace_reloc";incst t;      set t# "reloc_64";incst t;      set t# "underscore_pref";incst t; set t# "exit_end"
endfunction

#void
function setpreferences(str scrpath)
	Str preferences=".ocompiler.txt"
	data err#1
	data noerr=noerror
	Str preferencescontent#1
	Data ptrpreferencescontent^preferencescontent
	Data preferencessize#1
	Data ptrpreferencessize^preferencessize

	setcall err prefextra(preferences,ptrpreferencessize,ptrpreferencescontent)
	If err!=noerr
		data null=0
		data void#1

		str folders#1
		setcall folders endoffolders(scrpath)
		set folders# null
		sub folders scrpath

		data prefsz#1
		setcall prefsz strlen(preferences)
		inc prefsz

		data total#1
		set total folders
		add total prefsz

		data ptrmem#1
		data allocptrmem^ptrmem
		setcall err memoryalloc(total,allocptrmem)
		if err!=noerr
			call Message(err)
			return void
		endif

		call memtomem(ptrmem,scrpath,folders)

		str apppath#1
		set apppath ptrmem
		add apppath folders
		call memtomem(apppath,preferences,prefsz)

		SetCall err file_get_content_ofs(ptrmem,ptrpreferencessize,ptrpreferencescontent,null)
		call free(ptrmem)
		If err!=noerr
			Call safeMessage(err)
		EndIf
	endif
	If err==noerr
		Data freepreferences#1
		Set freepreferences preferencescontent

		sv t%nr_of_prefs_strings_p
		sd n=nr_of_prefs
		while n>0
			call parsepreferences(ptrpreferencescontent,ptrpreferencessize,t)
			dec n
		endwhile

		Call free(freepreferences)
	endif
EndFunction
#void

function constants_bool(sd direction)
	data bool#1
	if direction==(const_warn_get)
		return bool
	endif
	return #bool
endfunction

function inplace_reloc(sd p_addend)
	sd p_inplace_reloc_pref%p_inplace_reloc_pref
	if p_inplace_reloc_pref#==(zero_reloc)
		set p_addend# (i386_obj_default_reloc)
	endif
endfunction
