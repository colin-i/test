
#advance the content/size by value
Function advancecursors(data ptrcontent,data ptrsize,data nr)
	Str content#1
	Data size#1
	Set content ptrcontent#
	Set size ptrsize#
	Add content nr

	#backward advance
	#take nr if nr>0 or -nr if nr<0
	Data zero=0
	If nr<zero
		SetCall nr neg(nr)
	EndIf

	Sub size nr
	Set ptrcontent# content
	Set ptrsize# size
EndFunction

#advance the content/size by one
Function stepcursors(data ptrcontent,data ptrsize)
	Data one=1
	Call advancecursors(ptrcontent,ptrsize,one)
EndFunction


#String in mem; return size(if string is not),size before string(if string is)
Function strinmem(str content,data size,str match)
	Data zero=0
	Data nrsz#1
	SetCall nrsz strlen(match)
	If size<nrsz
		Return size
	EndIf
	Str cnt#1
	Set cnt content
	Data sz#1
	Set sz size
	Data b#1
	While sz>=nrsz
		SetCall b memcmp(cnt,match,nrsz)
		If b==zero
			Set nrsz sz
			Inc nrsz
		EndIf
		If b!=zero
			Inc cnt
			Dec sz
		EndIf
	EndWhile
	If b==zero
		Sub cnt content
		return cnt
	EndIf
	Return size
EndFunction

#bool
#AB to ab
#match have size
Function stratmem(data pcontent,data psize,str match)
	Data nrsz=0
	Data sz=0
	Str content=0
	Data zero=0
	Data one=1
	Data sizetorun=0

	SetCall nrsz strlen(match)
	Set sz psize#
	Set content pcontent#

	If sz<nrsz
		Return zero
	EndIf

	Set sizetorun nrsz
	While sizetorun!=zero
		Chars a_from_az={a_from_az}
		Chars z_from_az={z_from_az}
		Chars b#1
		Chars c#1

		Set b content#
		If b>=a_from_az
			If b<=z_from_az
				Chars az_to_AZ={az_to_AZ}
				Sub b az_to_AZ
			EndIf
		EndIf
		Set c match#
		If b!=c
			Return zero
		EndIf
		Inc content
		Inc match
		Dec sizetorun
	EndWhile
	Set pcontent# content
	Sub sz nrsz
	Set psize# sz
	Return one
EndFunction

#pointer
function mem_spaces(ss content,ss last)
	while content!=last
		sd bool;setcall bool is_whitespace(content#)
		if bool==(FALSE)
			return content
		endif
		inc content
	endwhile
	return content
endfunction
#new size
function find_whitespaceORcomment(ss content,sd size)
#size is greater than zero
	ss end;set end content;add end size
	ss start;set start content
	while content!=end
		chars b#1;set b content#
		if b==(commentascii)
			sub content start
			return content
		endif
		sd bool
		setcall bool is_whitespace(b)
		if bool==(TRUE)
			sub content start
			return content
		endif
		inc content
	endwhile
	sub content start
	return content
endfunction
#bool
function is_whitespace(chars c)
	if c==(asciispace)
		return (TRUE)
	endif
	if c==(asciitab)
		return (TRUE)
	endif
	return (FALSE)
endfunction
data warn_hidden_whitespaces_times#1
const warn_hidden_whitespaces_times_p^warn_hidden_whitespaces_times
#err
function warn_hidden_whitespaces(sd inc,sd add)
	data warn_hidden_whitespaces_times_p%warn_hidden_whitespaces_times_p
	if warn_hidden_whitespaces_times_p#==0
		add inc add
		sd goodwrongstring
		setcall goodwrongstring errorDefOut("Hidden whitespaces at :",inc)
		call safeMessage(goodwrongstring)
		inc warn_hidden_whitespaces_times_p#
		sd w%p_w_as_e
		if w#==(TRUE)
			sd p%p_hidden_pref
			if p#==(TRUE)
				return ""
			endif
		endif
	endif
	return (noerror)
endfunction

Function spaces_helper(ss cursor,sd size)
	sd end;set end cursor;add end size
	while cursor!=end
		sd b
		setcall b is_whitespace(cursor#)
		if b==(TRUE)
			inc cursor
		else
			return cursor
		endelse
	endwhile
	return cursor
endfunction
#spaces;return 1 if at least one spc/tab;0 otherwise
Function spaces(sd pcontent,sd psize)
	sd start;set start pcontent#
	setcall pcontent# spaces_helper(pcontent#,psize#)
	if pcontent#==start
		return (FALSE)
	endif
	sub start pcontent#
	add psize# start
	return (TRUE)
EndFunction

#bool;return 1 or 0
Function stringsatmemspc(data pcontent,data psize,str match,data spacereq,str extstr,data extbool)
	Data content#1
	Data size#1
	Data bool#1
	Data tocontent^content
	Data tosize^size
	Data zero=FALSE
	Data nonzero=TRUE

	Set content pcontent#
	Set size psize#
	SetCall bool stratmem(tocontent,tosize,match)
	If bool==zero
		Return zero
	EndIf

	If extstr!=zero
		SetCall extbool# stratmem(tocontent,tosize,extstr)
	EndIf

	SetCall bool spaces(tocontent,tosize)
	IF bool==zero
		If spacereq==nonzero
			Return zero
		EndIf
	EndIf
	Set pcontent# content
	Set psize# size
	Return nonzero
EndFunction

#return stringsatmemspc
Function stratmemspc(data pcontent,data psize,str match,data spacereq)
	Data null=NULL
	Data bool#1
	SetCall bool stringsatmemspc(pcontent,psize,match,spacereq,null,null)
	Return bool
EndFunction

#return the escaped char and change the size and cursor
Function quotescaped(Data pcontent,Data psize,Data pescapes)
	Str content#1
	Data size#1
	Chars byte#1
	Chars bs=asciibs
	Data zero=0

	Set content pcontent#
	Set byte content#
	If byte!=bs
		Return byte
	EndIf
	Set size psize#
	Dec size
	If size==zero
		Return byte
	EndIf

	Inc content
	Set byte content#
	Set pcontent# content
	Set psize# size
	If pescapes!=zero
		Inc pescapes#
	EndIf

	Return byte
EndFunction

#return false or true
Function quotientinmem(data ptrcontent,data ptrsize,data pquotsz,data pescapes)
	Chars quotation={asciidoublequote,0}
	Str pquotation^quotation
	Data intnr=0
	Data zero=0
	Data nonzero=1

	SetCall intnr stratmem(ptrcontent,ptrsize,pquotation)
	If intnr==zero
		Return zero
	EndIf

	Str data#1
	Data length#1
	Str ptrdata^data
	Data ptrlength^length

	Set data ptrcontent#
	Set length ptrsize#
	Set pescapes# zero
	Data escbefore=0
	Data escafter=0

	Chars byte={0}
	Chars bnull={0}
	While length!=zero
		Set escbefore pescapes#
		SetCall byte quotescaped(ptrdata,ptrlength,pescapes)
		If byte==quotation
			Set escafter pescapes#
			If escbefore==escafter
				Str datastart#1
				Set datastart ptrcontent#
				Sub data datastart
				Set pquotsz# data
				Return nonzero
			EndIf
		ElseIf byte==bnull
			Return zero
		EndElseIf
		Inc data
		Dec length
	EndWhile
	Return zero
EndFunction

#err
Function quotinmem(data ptrcontent,data ptrsize,data pquotsz,data pescapes)
	Data bool#1
	SetCall bool quotientinmem(ptrcontent,ptrsize,pquotsz,pescapes)
	Data false=FALSE
	If bool==false
		Chars strerr="Expecting string delimited by quotations and with the backslash the escape character."
		Str ptrstrerr^strerr
		Return ptrstrerr
	EndIf
	Data noerr=noerror
	Return noerr
EndFunction

#err
function maxpathverif(str safecurrentdirtopath,str logextension)
	data size1#1
	data size2#1
	setcall size1 strlen(safecurrentdirtopath)
	setcall size2 strlen(logextension)
	add size1 size2
	inc size1

	data err#1
	setcall err compareagainstmaxpath(size1)
	return err
endfunction

#err
function quotes_forward(sd p_content,ss last,sd p_newlines,sd p_lastlinestart)
#this version is knowing that the first char is "
	chars delim=asciidoublequote
	ss content
	set content p_content#
	str unend="end string (\") expected"
	sd escapes=0
	inc content
	if content==last
		return unend
	endif
	sd newlines=0
	while content#!=delim
		chars escape_c=asciibs
		while content#==escape_c
			if escapes==0
				set escapes 1
			else
				set escapes 0
			endelse
			inc content
			if content==last
				return unend
			endif
		endwhile
		chars newline=asciireturn
		if content#==newline
			if p_newlines!=0
				inc newlines
				set p_lastlinestart# content
				inc p_lastlinestart#
			endif
		endif
		if escapes==1
			inc content
			set escapes 0
		elseif content#!=delim
			inc content
		endelseif
		if content==last
			return unend
		endif
	endwhile
	inc content
	set p_content# content
	if p_newlines!=0
		set p_newlines# newlines
	endif
	return (noerror)
endfunction