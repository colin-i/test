
#must do a stripped data.bin and resolved text.bin

#input: exec o1 log1 ... oN logN

format elfobj64
#modify debian/control exec depends,appimage.yml,debian/control arh order

#at exec
#there is a rare case with rela.dyn but it is not important here (resolved stderr to object)
#these are not position independent code and inplace relocs add better with obj64 but at obj32 use addend>=0 or sum<0 error check

#both exec and shared:
#	pointers to dataind at text/data
#	aftercall has a copy at .symtab

#only exec:
#	pointers to aftercall

#only at shared:
#	.rela.dyn:
#		addends from pointers to data section (this and the previous are saying the same thing but maybe is compatibility)
#		data section offsets (direct:^printf, pointers to text/data sections)
#	aftercall value at .dynsym

#pin about .data align at objects that ld respects when concatenating

include "header.h"

include "throwless.s"

function messagedelim()
	sv st^stderr
	Chars visiblemessage={0x0a,0}
	Call fprintf(st#,#visiblemessage)
endfunction
Function Message(ss text)
	sv st^stderr
	Call fprintf(st#,text)
	call messagedelim()
EndFunction
function erMessage(ss text)
	call Message(text)
	call erEnd()
endfunction
function erMessages(ss m1,ss m2)
	call Message(m1)
	call Message(m2)
	call erEnd()
endfunction
function erEnd()
	call frees()
	aftercall er
	set er (~0)
	return (EXIT_FAILURE)
endfunction

include "file.s"
include "size.s"

entrylinux main(sd argc,ss *argv0,ss exec,ss obj1,ss *log1)   #... objN logN

if argc>(1+3)  #0 is all the time
	sv pfile%pexefile
	sv pexedata%pexedata
	sv pexetext%pexetext
	call get_file(exec,pfile,".data",pexedata,".text",pexetext,(ET_EXEC))
	sub argc 2
	sd stripped_data_size;setcall stripped_data_size get_offset(#obj1,argc)
	call frees()
	return (EXIT_SUCCESS)
endif
return (EXIT_FAILURE)
