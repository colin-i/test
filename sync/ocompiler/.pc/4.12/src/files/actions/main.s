

Str content#1
Str last#1
Data contentoffsetinclude=contentoffileoff
data contentlineinclude=lineoffile_offset

data dot_comma_end#1;set dot_comma_end 0

set twoparse 2
data logaux#1
set logaux logfile
set logfile negative
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
		Add cursorforincludes dwordsize
		Sub cursorforincludes includes

		Set nameofstoffile cursorforincludes

		Set content contentoffile
		Add content offsetoffile
		Set last contentoffile
		Add last sizeoffile

		While content!=last
			Include "./main/index.s"
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
		sd log_err
		setcall log_err addtolog_withchar_ex((NULL),0,0x65) #also ok on win
		if log_err!=(noerror)
			set errormsg log_err
			Call Message(errormsg)
		endif
	EndIf

	if includedir==true
		data int#1
		setcall int chdir(contentoffile)
		#0 success
		if int!=null
			str restoredirerr="Restore folder error."
			set errormsg restoredirerr
			Call Message(errormsg)
		endif
	endif

	Sub includesReg sizeofincludeset

	data skipfortwoparse#1
	set skipfortwoparse 0
	if includesReg==0
		if twoparse==2
			If innerfunction==true
				if errormsg==(noerror)
					Str endfnexp="ENDFUNCTION command expected to close the opened FUNCTION."
					set errormsg endfnexp
					Call Message(errormsg)
				endif
			Else
				#used when having multiple includes
				data includescursor#1
				set includescursor includes
				add includescursor contentoffsetinclude
				setcall includescursor# offsetoffile_value()

				set includescursor includes
				add includescursor contentlineinclude
				set includescursor# 0
				#

				set logfile logaux

				set skipfortwoparse 1
				add includesReg sizeofincludeset
				set twoparse 1
			EndElse
		endif
	endif
	if skipfortwoparse==0
		Call free(contentoffile)
	endif
EndWhile

If errormsg!=noerr
	Call errexit()
EndIf