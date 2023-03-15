
setcall errormsg addtolog_natural(datasecReg)
if errormsg!=(noerror)
	call msgerrexit(errormsg)
endif

#also needed at dtnb
#sub datasecSize datasecReg

if nobits_virtual==(No)
	#in case old style virtual
	#setcall errormsg set_reserve(datasecSize)
	setcall errormsg set_reserve(nobitssecReg)
	if errormsg!=(noerror)
		Call msgerrexit(errormsg)
	endif
endif

If fileformat==pe_exec
	Include "./fileformat/pe_struct.s"
	Include "./fileformat/pe_resolve.s"
Else
	Include "./fileformat/elf_resolve.s"
EndElse
