

#bool numeric
Function numeric(chars c)
	Chars zero={asciizero}
	Chars nine={asciinine}
	Data false=FALSE
	Data true=TRUE
	If c<zero
		Return false
	ElseIf c>nine
		Return false
	EndElseIf
	Return true
EndFunction

#bool
Function memtoint(str content,data size,data outvalue,data minusbool)
	#if size==0 not required in the program, it already comes at least 1
	
	Data value#1
	Data number#1
	
	data multx#1
	Set value 0
	set multx 1
	Add content size
	While size!=0
		Dec content;Dec size
		
		Data bool#1
		Chars byte#1
		Set byte content#
		SetCall bool numeric(byte)
		If bool==(FALSE)
			Return (FALSE)
		EndIf
		Sub byte (asciizero)
		Set number byte
		
		const bil_1=1000*1000*1000
		const bil_2=2*bil_1
		const max_int=0x80*0x100*0x100*0x100
		const max_int_bil_2_rest=max_int-bil_2
		if multx==(bil_1)
			if size!=0
				#(...)x xxx xxx xxx
				while size!=0
					Dec content;Dec size
					if content#!=(asciizero)
						return (FALSE)
					endif
				endwhile
			endif
			if number>2
				#3 xxx xxx xxx-9 xxx xxx xxx
				return (FALSE)
			elseif number==2
				if value>(max_int_bil_2_rest)
					#2 147 483 649-2 999 999 999
					return (FALSE)
				elseif value==(max_int_bil_2_rest)
					if minusbool==(FALSE)
						#2 147 483 648 is the first positive overflow
						return (FALSE)
					endif
				endelseif
			endelseif
		endif
		
		mult number multx;mult multx 10
		Add value number
	EndWhile
	Set outvalue# value
	Return (TRUE)
EndFunction

const nothex_value=-1

#out -1 or the converted number
Function hexnr(chars byte)
	Chars Asciizero={asciizero}
	Chars Asciinine={asciinine}
	Chars AsciiA={asciiA}
	Chars AsciiF={asciiF}
	Chars Asciia={asciia}
	Chars Asciif={asciif}
	Chars afternine={10}
	If byte<Asciizero
		Return (nothex_value)
	ElseIf byte<=Asciinine
		Sub byte Asciizero
	ElseIf byte<AsciiA
		Return (nothex_value)
	ElseIf byte<=AsciiF
		Sub byte AsciiA
		Add byte afternine
	ElseIf byte<Asciia
		Return (nothex_value)
	ElseIf byte<=Asciif
		Sub byte Asciia
		Add byte afternine
	Else
		Return (nothex_value)
	EndElse
	Return byte
EndFunction

#bool
Function memtohex(str content,data size,data outvalue)
	Data initialval=0
	Data initiallimit=3
	Data val#1
	Data limit#1
	Data false=FALSE
	Data true=TRUE
	Data seven=7

	Set val initialval
	Set limit initiallimit
	
	If size<limit
		Return false
	EndIf
	Add limit seven
	If limit<size
		Return false
	EndIf

	Str pc^content
	Data ps^size
	Data bool=0
	Data zero=0
	Chars byte#1
	Data nr#1
	Data initialmultp=1
	Data multp#1
	
	Set multp initialmultp
	SetCall bool stratmem(pc,ps,"0X")
	If bool==false
		Return false
	EndIf
	Add content size
	While size!=zero
		Dec content
		Dec size
		Set byte content#
		SetCall nr hexnr(byte)
		If nr==(nothex_value)
			Return false
		EndIf
		Mult nr multp
		Add val nr
		Data hextimes=16
		Mult multp hextimes
	EndWhile
	Set outvalue# val
	Return true
EndFunction

#error
function numbertoint(str content,data size,data outval,data minusbool)
	Data bool#1
	#test to see if the ! sign is present that means the current data cursor
	chars data_cursor=asciiExclamationmark
	if content#==data_cursor
		setcall outval# get_img_vdata_dataReg()
		if size!=1
			str er="The text after the data cursor sign isn't recognized."
			return er
		endif
		return (noerror)
	#test for : sign (the size of a stack value, 4B on 32-bits, 8B on 64-bits)
	chars int_size=asciiColon
	elseif content#==int_size
		if size!=1;return "The text after the size of an integer sign isn't recognized.";endif
		sd b;setcall b is_for_64()
		if b==(FALSE);set outval# (dwsz)
		else;set outval# (qwsz);endelse
		return (noerror)
	endelseif
	#decimal or hex number
	SetCall bool memtoint(content,size,outval,minusbool)
	If bool==0
		SetCall bool memtohex(content,size,outval)
		If bool==0
			Chars _intvalerr="Integer(dec/hex) value not recognized."
			Str intvallerr^_intvalerr
			Return intvallerr
		EndIf
	EndIf
	return (noerror)
endfunction

#err pointer
Function numbersconstants(str content,data size,data outval)
	Str intconsterr="Integer(dec/hex) or constant value expected."
	If size<=0
		Return intconsterr
	EndIf
	chars not=asciiequiv
	sd notbool=FALSE
	if content#==not
		set notbool (TRUE)
		inc content
		dec size
		If size<=0
			Return intconsterr
		EndIf
	endif
	sd minusbool=FALSE
	if content#==(asciiminus)
		set minusbool (TRUE)
		inc content
		dec size
		If size<=0
			Return intconsterr
		EndIf
	endif
	sd bool
	setcall bool is_variable_char_not_numeric(content#)
	If bool==(FALSE)
		sd err
		setcall err numbertoint(content,size,outval,minusbool)
	Else
		Data constr%ptrconstants
		Data pointer#1
		SetCall pointer vars(content,size,constr)
		If pointer==0
			Chars unconst="Undefined constant name."
			Str ptruncost^unconst
			Return ptruncost
		EndIf
		Set outval# pointer#
		set err (noerror)
	EndElse
	if err==(noerror)
		if notbool==(TRUE)
			not outval#
		endif
		if minusbool==(TRUE)
			mult outval# -1
		endif
	endif
	return err
EndFunction

#er
function parenthesis_size(ss content,sd size,sd ptr_sz)
	sd opens=1
	data z=0
	sd mark
	data noerr=noerror
	sd last
	Chars closefnexp="Close parenthesis sign (')') expected."
	Str closeerr^closefnexp
	
	set mark content
	set last content
	add last size
	while content!=last
		sd er
		setcall er quotes_forward(#content,last,0)
		if er!=(noerror)
			return er
		endif
		if content==last
			return closeerr
		endif
		Chars fnbegin="("
		Chars fnend=")"
		if content#==fnend
			dec opens
			if opens==z
				sub content mark
				set ptr_sz# content
				return noerr
			endif
		elseif content#==fnbegin
			inc opens
		endelseif
		inc content
	endwhile
	Return closeerr
endfunction
#er
function parenthesis_all_size(sd content,sd size,sd ptr_sz)
	data noerr=noerror
	Chars fnbegin="("
	if content!=fnbegin
		return noerr
	endif
	inc content
	dec size
	sd err
	setcall err parenthesis_size(content,size,ptr_sz)
	if err!=noerr
		return err
	endif
	data two=2
	add ptr_sz# two
	return err
endfunction
