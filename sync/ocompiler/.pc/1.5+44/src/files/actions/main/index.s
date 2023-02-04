
sd comsize#1

sd newlines
sd totalnewlines=0

Data pcontent^content
Data pcomsize^comsize

Str textlinestart#1
if dot_comma_end==0
	Set textlinestart content
endif

#cursor for hidden whitespaces
sd cursor_start;set cursor_start content
setcall content mem_spaces(content,last)

#test the line size and set the size of line break
Chars newline=asciireturn
Data linebreaksize#1
Set linebreaksize bytesize

#set comsize 0
ss pointer
set pointer content
sd loop=2
sd is_comment=0
if pointer!=last
	if pointer#==(commentascii)
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
			Chars carriage=asciicarriage
			set testcarriage pointer
			dec testcarriage
			If testcarriage#==carriage
				#Dec comsize
				set pointer testcarriage
				Inc linebreaksize
			EndIf
		endif
	elseif is_comment==0
		if pointer#==(asciidoublequote)
			setcall errormsg quotes_forward(#pointer,last,#newlines,#textlinestart)
			if errormsg!=(noerror)
				set loop 0
			else
				add totalnewlines newlines
			endelse
		elseif pointer#==(asciisemicolon)
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
	set comsize pointer
	sub comsize content
	#\r\n case begin
	#sub comsize linebreaksize
	#inc comsize
	#\r\n case end

	ss was_whitespaces
	If comsize!=0
		Data pointtosearchat%compointersloc
		SetCall commandset getcommand(pcontent,pcomsize,ptrsubtype,_errormsg,pointtosearchat)
		If errormsg==noerr
			if parses!=(pass_write)
				if commandset!=(cCOMMENT)
					if parses==(pass_init)
						#tested at function gather; FORMAT is here starting with FUNCTIONX to set the mask knowing the format
						if formatdefined==0;Set formatdefined 1;endif
						#if commandset==(cDECLARE)        #needing to find virtual start
						#at object is difficult, there is no virtual, ostrip will use: ld...-Tdata calculated, objcopy --update-section, write memsize, ounused will include virtual point
						#const at virtual start find
						#	use offset on dataReg for !
						#	const^ is not ok, use a mempbrk against ^ in declare.s at passes, init without ^,write only ^
						#virtual.s,virtual_parse
						#else
						If commandset==(cIMPORTLINK) #needing importx here
						elseif commandset==(cSTARTFUNCTION);elseif commandset==(cENDFUNCTION)
						ElseIf commandset==(cLIBRARY)
						elseif commandset==(cINCLUDE)
						Elseif commandset==(cFORMAT)
						Elseif commandset==(cDECLAREAFTERCALL)  #and import
						elseif commandset==(cWARNING)    #for addaref
						else;set commandset (cCOMMENT);endelse
					else
					#pass_calls
						if commandset==(cCALL);elseif commandset==(cENDFUNCTION);elseif commandset==(cINCLUDE)
						else;set commandset (cCOMMENT);endelse
					endelse
				endif
			endif
			if commandset==(cCOMMENT)
				Call advancecursors(pcontent,pcomsize,comsize)
				#1 is last
				if parses==(pass_write)
					set was_whitespaces content;dec was_whitespaces;setcall was_whitespaces is_whitespace(was_whitespaces#)
					if was_whitespaces==(TRUE)
						setcall errormsg warn_hidden_whitespaces(includes,nameofstoffile)
					endif
				endif
			ElseIf commandset==(cDECLARE)
				Include "./index/declare.s"
			ElseIf commandset==(cPRIMSEC)
		call entryscope_verify_code()
				Include "./index/primsec.s"
			ElseIf commandset==(cONEARG)
		call entryscope_verify_code()
				Include "./index/onearg.s"
			ElseIf commandset==(cCALL)
				if parses==(pass_write)
		call entryscope_verify_code()
				endif
				Include "./index/call.s"
			ElseIf commandset==(cCONDITIONS)
		call entryscope_verify_code()
				Include "./index/conditions.s"
			ElseIf commandset==(cIMPORTLINK)
				if parses==(pass_init);Include "./index/import.s"
				else;Call advancecursors(pcontent,pcomsize,comsize);endelse
			ElseIf commandset==(cSTARTFUNCTION)
				Include "./index/function.s"
			ElseIf commandset==(cENDFUNCTION)
				Include "./index/endfunction.s"
			ElseIf commandset==(cRET)
		call entryscope_verify_code()
				Include "./index/ret.s"
			ElseIf commandset==(cINCLUDE)
				Include "./index/include.s"
			ElseIf commandset==(cFORMAT)
				if parses==(pass_init);Include "./index/format.s"
				else;Call advancecursors(pcontent,pcomsize,comsize);endelse
			ElseIf commandset==(cDECLAREAFTERCALL)
				if parses==(pass_write);Include "./index/aftercall.s";
				else;Call advancecursors(pcontent,pcomsize,comsize);endelse
				set g_e_b_p# (TRUE)
			ElseIf commandset==(cWARNING)
				Include "./index/warning.s"
			ElseIf commandset==(cCALLEX)
		call entryscope_verify_code()
				Include "./index/callex.s"
			ElseIf commandset==(cOVERRIDE)
				Include "./index/override.s"
			ElseIf commandset==(cLIBRARY)
				if parses==(pass_init);Include "./index/library.s"
				else;Call advancecursors(pcontent,pcomsize,comsize);endelse
			ElseIf commandset==(cHEX)
		call entryscope_verify_code()
				Include "./index/hex.s"
			Else
			#If commandset==(cI3)
		call entryscope_verify_code()
				Include "./index/i3.s"
			EndElse
			If errormsg==(noerror)
				If comsize!=zero
					setcall was_whitespaces spaces(pcontent,pcomsize)
					If comsize!=zero
						if content#!=(commentascii)
							Chars _unreccomaftererr="Unrecognized data after command."
							Str unreccomaftererr^_unreccomaftererr
							Set errormsg unreccomaftererr
						else
							#this is comment after command
							Call advancecursors(pcontent,pcomsize,comsize)
						endelse
					elseIf was_whitespaces==(TRUE)
						if parses==(pass_write)
							setcall errormsg warn_hidden_whitespaces(includes,nameofstoffile)
						endif
					endelseIf
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
	Elseif cursor_start!=content
		if parses==(pass_write)
			setcall errormsg warn_hidden_whitespaces(includes,nameofstoffile)
		endif
	Endelseif

	If errormsg==noerr
		add lineoffile totalnewlines
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
			Data contentoffset#1
			Set contentoffset content
			Sub contentoffset contentoffile
			Set inccursor# contentoffset
			Add inccursor dwordsize

			Set inccursor# lineoffile
			SetCall errormsg include(miscbag)
			If errormsg!=noerr
				Set content textlinestart
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
endif
