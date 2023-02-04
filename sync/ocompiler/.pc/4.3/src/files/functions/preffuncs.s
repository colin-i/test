

#void
Function warnings(data searchinfunctions,data includes,data nameoffset)
	Data warningsboolptr%ptrwarningsbool
	Data warningsbool#1
	Data null=NULL
	Data true=TRUE
	Data false=FALSE

	Set warningsbool warningsboolptr#
	If warningsbool==false
		Return null
	EndIf

	Data var#1
	
	SetCall var searchinvars(null,null,null,true)
	If var==null
		If searchinfunctions==true
			Data functionsptr%ptrfunctions
			SetCall var varscore(null,null,functionsptr,true)
		EndIf
	EndIf
	If var!=null
		Chars unrefformat="Unreferenced variable/function: %s. Scope Termination File: %s. To disable this warning see '.ocompiler.txt'"
		Str ptrunrefformat^unrefformat

		Data printbuffer#1

		Data fileoff=nameoffset
		Add var fileoff
		SetCall printbuffer printbuf(ptrunrefformat,var)
		If printbuffer!=null
			Add includes nameoffset
			Call sprintf(printbuffer,ptrunrefformat,var,includes)
			Call Message(printbuffer)
			Call free(printbuffer)
		EndIf
	EndIf
EndFunction

#void
#parse and set the value, 0-9(one digit) values are expected here
function parsepreferences(data ptrcontent,data ptrsize,data ptrvalue)
	Chars searchsign="="
	Data sizeuntilsign#1

	str content#1
	data size#1
	set content ptrcontent#
	set size ptrsize#

	SetCall sizeuntilsign valinmem(content,size,searchsign)
	call advancecursors(ptrcontent,ptrsize,sizeuntilsign)

	If sizeuntilsign!=size
		Call stepcursors(ptrcontent,ptrsize)
		set content ptrcontent#
		set size ptrsize#
		data zero=0
		If size!=zero
			Call stepcursors(ptrcontent,ptrsize)
			Set ptrvalue# content#
			data asciiNumbersStart=asciizero
			Sub ptrvalue# asciiNumbersStart
		EndIf
	EndIf

	data false=FALSE
	return false
endfunction

#void
function setpreferences(str scrpath)
	data null=0
	data void#1

	str folders#1
	setcall folders endoffolders(scrpath)
	set folders# null
	sub folders scrpath

	Str preferences=".ocompiler.txt"
	data prefsz#1
	setcall prefsz strlen(preferences)
	inc prefsz

	data total#1
	set total folders
	add total prefsz

	data err#1
	data noerr=noerror
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

	#defaults
	data ptrwarningsbool%ptrwarningsbool
	data ptrlogbool%ptrlogbool
	data ptrincludedir%ptrincludedir
	data ptrcodeFnObj%ptrcodeFnObj
	data ptr_log_import_functions%ptr_log_import_functions
	
	data true=TRUE
	data false=FALSE
	data defaultcodeFnObj=logcodeFnObj

	set ptrwarningsbool# true
	set ptrlogbool# false
	set ptrincludedir# true
	set ptrcodeFnObj# defaultcodeFnObj
	sd text_fn_info
	setcall text_fn_info fn_text_info()
	set text_fn_info# false
	set ptr_log_import_functions# true
	sd neg_64
	setcall neg_64 p_neg_is_for_64()
	set neg_64# false
	
	Str preferencescontent#1
	Data ptrpreferencescontent^preferencescontent
	Data preferencessize#1
	Data ptrpreferencessize^preferencessize

	SetCall err file_get_content_ofs(ptrmem,ptrpreferencessize,ptrpreferencescontent,null)
	call free(ptrmem)
	If err!=noerr
		Call safeMessage(err)
		If err!=noerr
			setcall err prefextra(preferences,ptrpreferencessize,ptrpreferencescontent)
			If err!=noerr
				Call safeMessage(err)
			endif
		endif
	EndIf
	If err==noerr
		Data freepreferences#1
		Set freepreferences preferencescontent

		call parsepreferences(ptrpreferencescontent,ptrpreferencessize,ptrwarningsbool)
		call parsepreferences(ptrpreferencescontent,ptrpreferencessize,ptrlogbool)
		call parsepreferences(ptrpreferencescontent,ptrpreferencessize,ptrincludedir)
		call parsepreferences(ptrpreferencescontent,ptrpreferencessize,ptrcodeFnObj)
		call parsepreferences(ptrpreferencescontent,ptrpreferencessize,text_fn_info)
		call parsepreferences(ptrpreferencescontent,ptrpreferencessize,ptr_log_import_functions)
		call parsepreferences(ptrpreferencescontent,ptrpreferencessize,neg_64)

		Call free(freepreferences)
	endif
EndFunction
#void
