

#errnr
Function addtosecstresc(data pcontent,data psize,data sz,data escapes,data pdest,data allowOdd)
	Data odd=0
	Data zero=0
	Data nonzero=1
	
	#set destination start
	Data destReg#1
	Data ptrdestReg^destReg
	Call getcontReg(pdest,ptrdestReg)

	# size of the string out with term
	Data sizeEsc=0
	Set sizeEsc sz
	Sub sizeEsc escapes
	# the "str" on src
	Data sizeonsrc=0
	Set sizeonsrc sizeEsc
	Inc sizeEsc

	Data sznr=0
	Set odd zero
	#into idata string is padded to word
	If allowOdd!=zero
		Set sznr sizeEsc
		While sznr!=zero
			If odd==zero
				Set odd nonzero
			Else
				Set odd zero
			EndElse
			Dec sznr
		EndWhile
		If odd==nonzero
			Inc sizeEsc
		EndIf
	EndIf

	Data noerr=noerror
	Data errnr#1
	SetCall errnr addtosec(zero,sizeEsc,pdest)
	If errnr!=noerr
		Return errnr
	EndIf

	#set destination start
	Str destloc#1
	Data ptrdestloc^destloc
	SetCall destloc getcont(pdest,ptrdestloc)
	Add destloc destReg

	While sizeonsrc!=zero
		Chars byte={0}
		SetCall byte quotescaped(pcontent,psize,zero)
		Set destloc# byte
		Inc destloc
		Call stepcursors(pcontent,psize)
		Dec sizeonsrc
	EndWhile
	Set destloc# zero
	If odd==nonzero
		Inc destloc
		Set destloc# zero
	EndIf

	Return noerr
EndFunction