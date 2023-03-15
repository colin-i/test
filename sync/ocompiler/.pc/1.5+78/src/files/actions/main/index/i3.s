
If comsize==zero
	Chars interrupt={0xCC}
	Str ptrinterrupt^interrupt
	SetCall errormsg addtosec(ptrinterrupt,bytesize,ptrcodesec)
endif
