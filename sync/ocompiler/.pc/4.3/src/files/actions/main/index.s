
Data comsize#1

sd newlines
sd totalnewlines=0

Data pcontent^content
Data pcomsize^comsize

Str commstart#1
if dot_comma_end==0
	Set commstart content
endif

setcall content mem_spaces(content,last)

#test the line size and set the size of line break
Chars newline=0xa
Data linebreaksize#1
Set linebreaksize bytesize

chars quote="\""
#set comsize 0
ss pointer
set pointer content
sd loop=2
sd is_comment=0
if pointer!=last
	if pointer#==(asciiNumber)
		set is_comment 1
	endif
endif
while loop==2
	if pointer==last
		set loop 1
	elseif pointer#==newline
		set loop 1
		set dot_comma_end 0
		if pointer!=content
			ss testcarriage
			Chars carriage=0x0d
			set testcarriage pointer
			dec testcarriage
			If testcarriage#==carriage
				#Dec comsize
				set pointer testcarriage
				Inc linebreaksize
			EndIf
		endif
	elseif is_comment==0
		if pointer#==quote
			setcall errormsg quotes_forward(#pointer,last,#newlines)
			if errormsg!=(noerror)
				set loop 0
			else
				add totalnewlines newlines
			endelse
		elseif pointer#==(asciiSemicolon)
			set loop 1
			set dot_comma_end 1
		else
			inc pointer
		endelse
	else
		inc pointer
	endelse
endwhile
if loop==1
	add lineoffile totalnewlines
	set comsize pointer
	sub comsize content
	#\r\n case begin
	#sub comsize linebreaksize
	#inc comsize
	#\r\n case end
endif

If comsize!=0
	Data pointtosearchat%compointersloc
	SetCall commandset getcommand(pcontent,pcomsize,ptrsubtype,_errormsg,pointtosearchat)
	If errormsg==noerr
		if twoparse==2
			#tested at function gather; FORMAT is here starting with FUNCTIONX to set the mask knowing the format
			if commandset!=(cCOMMENT)
				if formatdefined==0;Set formatdefined 1;endif
				If commandset==(cFORMAT);elseif commandset==(cINCLUDE);elseif commandset==(cSTARTFUNCTION);elseif commandset==(cENDFUNCTION)
				else;set commandset (cCOMMENT);endelse
			endif
		endif
		If commandset==(cFORMAT)
			if twoparse==2;Include "./index/format.s"
			else;Call advancecursors(pcontent,pcomsize,comsize);endelse
		ElseIf commandset==(cDECLARE)
			Include "./index/declare.s"
		ElseIf commandset==(cDECLAREAFTERCALL)
			Include "./index/aftercall.s"
		ElseIf commandset==(cONEARG)
	call entryscope_verify_code()
			Include "./index/onearg.s"
		ElseIf commandset==(cPRIMSEC)
	call entryscope_verify_code()
			Include "./index/primsec.s"
		ElseIf commandset==(cLIBRARY)
			Include "./index/library.s"
		ElseIf commandset==(cIMPORTLINK)
			Include "./index/import.s"
		ElseIf commandset==(cSTARTFUNCTION)
			Include "./index/function.s"
		ElseIf commandset==(cENDFUNCTION)
			Include "./index/endfunction.s"
		ElseIf commandset==(cCALL)
	call entryscope_verify_code()
			Include "./index/call.s"
		ElseIf commandset==(cCALLEX)
	call entryscope_verify_code()
			Include "./index/callex.s"
		ElseIf commandset==(cCONDITIONS)
	call entryscope_verify_code()
			Include "./index/conditions.s"
		ElseIf commandset==(cINCLUDE)
			Include "./index/include.s"
		ElseIf commandset==(cI3)
	call entryscope_verify_code()
			Include "./index/i3.s"
		ElseIf commandset==(cHEX)
	call entryscope_verify_code()
			Include "./index/hex.s"
		ElseIf commandset==(cWARNING)
			Include "./index/warning.s"
		Else
#comments command
			Call advancecursors(pcontent,pcomsize,comsize)
		EndElse
		If errormsg==zero
			If comsize!=zero
				if content#!=(asciiNumber)
					Chars _unreccomaftererr="Unrecognized data after command."
					Str unreccomaftererr^_unreccomaftererr
					Set errormsg unreccomaftererr
				else
					#this is comment after command
					Call advancecursors(pcontent,pcomsize,comsize)
				endelse
			#twoparse==2 more
			#after the first noncomment command, the format command cannot be changed
			elseif formatdefined==1;Set formatdefined 2
			#twoparse==1 more
			ElseIf fnavailable==two
				#retain the file and line where the main scope was started for functions separated from main code
				#fnavailable two was set by code detectors
				Data currentfile#1
				Set currentfile includes
				Add currentfile nameofstoffile
				Data sizeshortstr=shortstrsize
				Call memtomem(ptrentrystartfile,currentfile,sizeshortstr)

				Set entrylinenumber lineoffile
				Inc entrylinenumber

				Set fnavailable zero
			EndElseIf
		EndIf
	EndIf
EndIf

If errormsg==noerr
	#parse the line termination,then is the include that will retain the next line and advance to the next file
	Data lineincrease#1
	Set lineincrease zero
	If content!=last
		Add content linebreaksize
		if dot_comma_end==0
			Set lineincrease one
		endif
	EndIf
	Add lineoffile lineincrease

	#include next file
	If includebool==one
		Data inccursor#1
		Set inccursor includes
		Add inccursor includesReg

		Sub inccursor sizeofincludeset
	
		Add inccursor contentoffsetinclude
		Data contentoffset=0
		Set contentoffset content
		Sub contentoffset contentoffile
		Set inccursor# contentoffset
		Add inccursor dwordsize
	
		Set inccursor# lineoffile
		SetCall errormsg include(miscbag)
		If errormsg!=noerr
			Set content commstart
			Sub lineoffile lineincrease
		Else
			Set content contentoffile
			Set last content
			Add content offsetoffile
			Add last sizeoffile
			Set miscbagReg zero
			Set includebool zero
		EndElse
	EndIf
EndIf