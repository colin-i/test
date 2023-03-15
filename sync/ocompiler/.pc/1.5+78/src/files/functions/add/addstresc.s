

#errnr
Function addtosecstresc(sd pcontent,sd psize,sd sz,sd escapes,sd pdest,sd wordpad)
	#set destination start
	Data destReg#1
	Data ptrdestReg^destReg
	Call getcontReg(pdest,ptrdestReg)

	Data odd#1
	Data zero=0

	# size of the string out with term
	Data sizeEsc#1
	Set sizeEsc sz
	sd end;set end sizeEsc
	Sub sizeEsc escapes
	Inc sizeEsc

	Set odd zero
	#into idata string is padded to word
	If wordpad!=zero
		set odd sizeEsc
		and odd 1
		If odd!=zero
			Inc sizeEsc
		EndIf
	EndIf

	Data noerr=noerror
	Data errnr#1
	SetCall errnr addtosec(0,sizeEsc,pdest)
	If errnr!=noerr
		Return errnr
	EndIf

	#set destination start
	Str destloc#1
	Data ptrdestloc^destloc
	Call getcont(pdest,ptrdestloc)
	Add destloc destReg

	add end pcontent#
	While pcontent#!=end
		Chars byte#1
		SetCall byte quotescaped(pcontent,psize,zero)
		Set destloc# byte
		Inc destloc
		Call stepcursors(pcontent,psize)
	EndWhile
	Set destloc# zero
	If odd!=zero
		Inc destloc
		Set destloc# zero
	EndIf

	Return noerr
EndFunction
