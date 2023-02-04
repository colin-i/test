

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
				Sub columnoffile commstart

				Add lineoffile one
				Add columnoffile one

				Chars errformat="%s File %s, Row %i, Column %i"
				Str perrformat^errformat

				Data printbuffer#1

				SetCall printbuffer printbuf(perrformat,errormsg)
				If printbuffer==null
					Call errexit()
				EndIf
				if totalnewlines==0
					Call sprintf(printbuffer,perrformat,errormsg,nameoffilewitherr,lineoffile,columnoffile)
				else
					sub lineoffile totalnewlines
					Call sprintf(printbuffer,"%s File %s, Row %i",errormsg,nameoffilewitherr,lineoffile)
				endelse
				Call Message(printbuffer)
				Call free(printbuffer)
				Set content last
			EndIf
		EndWhile
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