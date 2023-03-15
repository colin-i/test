
sd comsize#1

sd newlines
sd totalnewlines=0

Data pcontent^content
Data pcomsize^comsize

Str textlinestart#1
if dot_comma_end==0
	Set textlinestart content
endif

#test the line size and set the size of line break
Chars newline=asciireturn
Data linebreaksize#1
Set linebreaksize bytesize

sd loop=2
#set comsize 0

#cursor for hidden whitespaces, this is different than textlinestart
sd cursor_start
ss pointer
sd is_comment;sd is_comment_multiline

setcall pointer command_start(#is_comment,#is_comment_multiline,#cursor_start,#content,last)
while loop==2
	if pointer==last
		set loop 1
	elseif pointer#==newline
		set dot_comma_end 0   #a multiline comment can also be in a commands line
		if is_comment_multiline==0
			set loop 1
			if pointer!=content
				Chars carriage=asciicarriage
				ss testcontent
				set testcontent pointer
				dec testcontent
				If testcontent#==carriage
					#Dec comsize
					set pointer testcontent
					Inc linebreaksize
				EndIf
			endif
		else
			#like: #!line\nline\nline\n ! command
			inc lineoffile
			inc pointer
			set textlinestart pointer
			if pointer!=last
				setcall pointer mem_spaces(pointer,last)
				if pointer!=last
					if pointer#==(asciiexclamationmark)
						inc pointer
						set content pointer
						setcall pointer command_start(#is_comment,#is_comment_multiline,#cursor_start,#content,last)
					endif
				endif
			endif
		endelse
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
						if formatdefined==0
							if commandset!=(cFORMAT)
								set nobits_virtual (No)   #this is default pe_exe format, same behavior for nobits
							endif
							Set formatdefined 1
						endif
						#needing to find virtual start
						if commandset==(cDECLARE)
						ElseIf commandset==(cPRIMSEC)
						ElseIf commandset==(cONEARG)
						Elseif commandset==(cCALL)
						#at object is difficult, there is no virtual, ostrip is in the project
						elseIf commandset==(cIMPORTLINK) #needing importx here
						elseif commandset==(cSTARTFUNCTION);elseif commandset==(cENDFUNCTION)
						ElseIf commandset==(cLIBRARY)
						elseif commandset==(cINCLUDE)
						Elseif commandset==(cFORMAT)
						Elseif commandset==(cDECLAREAFTERCALL)  #and import
						elseif commandset==(cWARNING)    #for addaref
						elseif commandset==(cOVERRIDE)   #example underscore_pref
						else;set commandset (cCOMMENT);endelse
					else
					#pass_calls
						If commandset==(cPRIMSEC);elseif commandset==(cCALL)
						elseif commandset==(cINCLUDE);elseif commandset==(cENDFUNCTION)
						elseif commandset==(cOVERRIDE)   #example call_align
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
					#this is comment ending in whitespace
						setcall errormsg warn_hidden_whitespaces(includes,nameofstoffile)
					endif
				endif
			ElseIf commandset==(cDECLARE)
				Include "./index/declare.s"
			ElseIf commandset==(cPRIMSEC)
				Include "./index/primsec.s"
			ElseIf commandset==(cONEARG)
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
				else;if subtype==(cAFTERCALL);add datasecReg (aftercalldeclaresize);endif
					Call advancecursors(pcontent,pcomsize,comsize);endelse
				set g_e_b_p# (TRUE)
			ElseIf commandset==(cWARNING)
				Include "./index/warning.s"
			ElseIf commandset==(cCALLEX)
		call entryscope_verify_code()
				Include "./index/callex.s"
			ElseIf commandset==(cOVERRIDE)
				#is at all, example at write hidden_pref
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
				#after the first noncomment command, the format command cannot be changed
				#this can be at line 0
				if formatdefined==1;Set formatdefined 2;endif

				#set when code started
				#this can be at line 0
				If fnavailable==two
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
				EndIf

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
						#mostly parses (pass_write), example: at cCALL is at all parses
						#this is whitespace after command
						#if parses==(pass_write) when show once check was not
						setcall errormsg warn_hidden_whitespaces_after(includes,nameofstoffile,dot_comma_end)
					endelseIf
				endIf
			EndIf
		EndIf
	Elseif cursor_start!=content
		#if parses==(pass_write) when show once check was not
		#this is only whitespace
		setcall errormsg warn_hidden_whitespaces_after(includes,nameofstoffile,dot_comma_end)
		#dot_comma_end check: is not like it accepts "    ;" but it accepts "...!    ;"
		#endif
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
			SetCall errormsg include(miscbag,(FALSE))
			If errormsg!=noerr
				Set content textlinestart
				Sub lineoffile lineincrease
			Else
				set ptrprevLineD# 0    #here 0, at main set back
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
