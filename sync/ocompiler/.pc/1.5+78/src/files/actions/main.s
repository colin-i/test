

Str content#1
Str last#1
Data contentoffsetinclude=contentoffileoff
data contentlineinclude=lineoffile_offset

data dot_comma_end#1;set dot_comma_end 0

#data logbackup#1

set parses (pass_init)

While includesReg!=null
	Data cursorforincludes#1
	Set cursorforincludes includes
	Add cursorforincludes includesReg
	Data sizeofincludeset=includesetSz
	Sub cursorforincludes sizeofincludeset
	Set contentoffile cursorforincludes#
	If errormsg==noerr
		Add cursorforincludes dwordsize
		Set sizeoffile cursorforincludes#
		Add cursorforincludes dwordsize
		Set offsetoffile cursorforincludes#
		Add cursorforincludes dwordsize
		Set lineoffile cursorforincludes#
		set ptrprevLineD# lineoffile
		Add cursorforincludes dwordsize
		Sub cursorforincludes includes

		Set nameofstoffile cursorforincludes

		Set content contentoffile
		Add content offsetoffile
		Set last contentoffile
		Add last sizeoffile

		While content!=last
			Include "./main/index.s"
			If errormsg==noerr
				if parses==(pass_write)
					if has_debug==(Yes)
						setcall errormsg debug_lines(codesecReg,lineoffile,content,last)
					endif
				endif
			EndIf
			If errormsg!=noerr
				Str nameoffilewitherr#1
				Set nameoffilewitherr includes
				Add nameoffilewitherr nameofstoffile

				Data columnoffile#1
				Set columnoffile content
				Sub columnoffile textlinestart

				Add lineoffile one
				Add columnoffile one

				Data printbuffer#1

				if totalnewlines==0
					setcall printbuffer printbuf("%s File %s, Row %u, Column %u",errormsg,nameoffilewitherr,2,lineoffile,columnoffile)
				else
				#first textlinestart is lost at multilines command
					setcall printbuffer printbuf("%s File %s, Row %u",errormsg,nameoffilewitherr,1,lineoffile)
				endelse
				If printbuffer==null
					Call errexit()
				EndIf
				Call Message(printbuffer)
				Call free(printbuffer)
				Set content last
			EndIf
		EndWhile
		If errormsg==noerr
			setcall errormsg addtolog_withchar_parses("",fileendchar,(FALSE)) #also ok on win
			if errormsg!=(noerror)
				Call Message(errormsg)
			elseif includedir==true
				data int#1
				setcall int chdir(contentoffile)
				#0 success
				if int!=chdirok
					str restoredirerr="Restore folder error."
					set errormsg restoredirerr
					Call Message(errormsg)
				endif
			endelseif
		endIf
	EndIf

	#this is used also inside index.s
	Sub includesReg sizeofincludeset

	data skipfree#1
	set skipfree 0
	if includesReg==0
		if parses!=(pass_write)
			if errormsg==(noerror)
				If innerfunction==true
					Str endfnexp="ENDFUNCTION command expected to close the opened FUNCTION."
					set errormsg endfnexp
					Call Message(errormsg)
				Else
					if parses==(pass_init)
						setcall errormsg align_alloc(functionTagIndex)

						set parses (pass_calls)
						set g_e_b_p# (FALSE)  #in case was set, for writes

						set datasecSize datasecReg
						set datasecReg 0
						set nobitsDataStart datasecSize

						#set logbackup logfile
						#set logfile negative   #will reiterate tree. and will also have reusable,imports and constants
					else
						set parses (pass_write)
						call align_resolve()
						setcall errormsg scopes_alloc(el_or_e,functionTagIndex)
					endelse
					if errormsg==(noerror)
						#used when having multiple includes
						data includescursor#1
						set includescursor includes
						add includescursor contentoffsetinclude
						setcall includescursor# offsetoffile_value()
						#
						set includescursor includes
						add includescursor contentlineinclude
						set includescursor# 0
						#
						add includesReg sizeofincludeset

						set skipfree 1

						set functionTagIndex 0
					endif
				EndElse
			endif
		endif
	endif
	if skipfree==0
		Call free(contentoffile)
	endif
EndWhile

#set logfile logbackup       #set for errexit, func/const at object, virtual, exit

If errormsg!=noerr
	Call errexit()
EndIf
