
#er
function debug_lines(sd reg,sd line,sd content,sd last)
	datax prevLine#1
	const ptrprevLineD^prevLine
	datax codeRegD#1
	const ptrcodeRegD^codeRegD
	#initialized values

	sd aux;sd test
	if line!=prevLine   #no a[semicolon]b column atm
		#set line
		set aux prevLine;set prevLine line
		set test (TRUE)
	elseif content==last  #but last line with no new line must be verified
		set aux prevLine;set prevLine line
		set test (TRUE)
	else
		set test (FALSE)
	endelse
	if test==(TRUE)
		if reg!=codeRegD
			sv ptrdebug%%ptr_debug
			chars a=log_line
			sd err
			setcall err addtosec(#a,(bsz),ptrdebug)
			if err==(noerror)
				charsx buf#dw_chars_0
				sd len
				inc aux
				setcall len dwtomem(aux,#buf)
				setcall err addtosec(#buf,len,ptrdebug)
				if err==(noerror)
					chars b=asciispace
					setcall err addtosec(#b,(bsz),ptrdebug)
					if err==(noerror)
						setcall len dwtomem(codeRegD,#buf)
						setcall err addtosec(#buf,len,ptrdebug)
						if err==(noerror)
							sd t;sd sz;setcall t log_term(#sz)
							setcall err addtosec(t,sz,ptrdebug)
							#set codeReg
							set codeRegD reg
						endif
					endif
				endif
			endif
			return err
		endif
	endif
	return (noerror)
endfunction

#err
function addtodebug_withchar(ss content,sd char)
	sd ptr_has_debug%ptr_has_debug
	if ptr_has_debug#==(Yes)
	#at exec formats will add for no one
	#if blocking at exe , care to remove if dst==debugsec from addtosec
		sv ptrdebug%%ptr_debug
		sd err
		setcall err addtosec(#char,(bsz),ptrdebug)
		if err==(noerror)
			sd ln;setcall ln strlen(content)
			setcall err addtosec(content,ln,ptrdebug)
			if err==(noerror)
				sd t;sd sz;setcall t log_term(#sz)
				setcall err addtosec(t,sz,ptrdebug)
			endif
		endif
		return err
	endif
	return (noerror)
endfunction
