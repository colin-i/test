
#err
Function addtonamessized(data str,data sz,data regoff)
	Data ptrnames%ptrnames
	Call getcontReg(ptrnames,regoff)
	Data err#1
	SetCall err addtosecstr(str,sz,ptrnames)
	Return err
EndFunction

#err
Function addtonames(data str,data regoff)
	Data sz#1
	SetCall sz strlen(str)
	Data err#1
	SetCall err addtonamessized(str,sz,regoff)
	Return err
EndFunction

#err
function elfaddsec_base(sd stringname,sd type,sd flags,sd fileoffset,sd bsize,sd link,sd info,sd align,sd entsize,sd addr,sd ptrbag)
	Const elf_section=!
	#Section header
	#Section name (string tbl index)
	Data sh_name#1
	#Section type
	Data sh_type#1
	#Section flags
	Data sh_flags#1
	#Section virtual addr at execution
	Data sh_addr#1
	#Section file offset
	Data sh_offset#1
	#Section size in bytes
	Data sh_size#1
	#Link to another section
	Data sh_link#1
	#Additional section information
	Data sh_info#1
	#Section alignment
	Data sh_addralign#1
	#Entry size if section holds table
	Data sh_entsize#1
	Const elf_section_size=!-elf_section

	Const elf64_section=!
	Data sh64_name#1
	Data sh64_type#1
	Data sh64_flags#1;data *=0
	Data sh64_addr#1;data *=0
	Data sh64_offset#1;data *=0
	Data sh64_size#1;data *=0
	Data sh64_link#1
	Data sh64_info#1
	Data sh64_addralign#1;data *=0
	Data sh64_entsize#1;data *=0
	Const elf64_section_size=!-elf64_section

	Const SHT_NULL=0
	Const SHT_PROGBITS=1
	Const SHT_NOBITS=8

	const SHF_WRITE=1
		#Occupies memory during execution,1 << 1
	Const SHF_ALLOC=2*1
		#Executable,1 << 2
	Const SHF_EXECINSTR=2*2
		#`sh_info' contains SHT index,1 << 6
	#Const SHF_INFO_LINK=2*6

	#A section of SHT_NOBITS may have a non-zero size, but it occupies no space in the file
	#and ld is warning it, so why was here in the first place?
	#Data SHT_PROGBITS=SHT_PROGBITS
	#Data SHT_NOBITS=SHT_NOBITS
	#Data zero=0
	#If type==SHT_PROGBITS
	#	If bsize==zero
	#		Set type SHT_NOBITS
	#	EndIf
	#EndIf

	Data err#1
	#is false at inits, no worry about only at object
	sd e64;setcall e64 is_for_64()
	if e64==(TRUE)
		Set sh64_name stringname;Set sh64_type type;Set sh64_flags flags;set sh64_addr addr;Set sh64_offset fileoffset
		set sh64_size bsize;Set sh64_link link;Set sh64_info info;Set sh64_addralign align;Set sh64_entsize entsize
		setcall err addtosec(#sh64_name,(elf64_section_size),ptrbag)
	else
		Set sh_name stringname;Set sh_type type;Set sh_flags flags;set sh_addr addr;Set sh_offset fileoffset
		set sh_size bsize;Set sh_link link;Set sh_info info;Set sh_addralign align;Set sh_entsize entsize
		SetCall err addtosec(#sh_name,(elf_section_size),ptrbag)
	endelse
	Return err
endfunction
#err
function elfaddsecn()
	Data ptrmiscbag%ptrmiscbag
	sd err
	SetCall err elfaddsec_base((NULL),(SHT_NULL),0,(NULL),(NULL),0,0,0,0,(NULL),ptrmiscbag)
	Return err
endfunction
#err
Function elfaddsec(data stringoff,data type,data flags,data fileoffset,data seccont,data link,data info,data align,data entsize)
	sd bsize
	Call getcontReg(seccont,#bsize)
	Data ptrmiscbag%ptrmiscbag
	sd err
	SetCall err elfaddsec_base(stringoff,type,flags,fileoffset,bsize,link,info,align,entsize,(NULL),ptrmiscbag)
	Return err
EndFunction
#err
Function elfaddstrsec(data stringofname,data type,data flags,data fileoffset,data seccont,data link,data info,data align,data entsize)
	sd err
	sd regnr#1
	sd ptrregnr^regnr
	SetCall err addtonames(stringofname,ptrregnr)
	If err==(noerror)
		setcall err elfaddsec(regnr,type,flags,fileoffset,seccont,link,info,align,entsize)
	endif
	return err
EndFunction

#err
Function elfaddsym(data stringoff,data value,data size,chars st_info,chars bind,data index,data struct)
#	sd st_info
#	Set st_info type
const elf_sym_st_info_tohibyte=16
	Mult bind (elf_sym_st_info_tohibyte)
	Or st_info bind

	Data ptrndxsrc^index
	Data wsz=wsz

	sd err
	sd x;setcall x is_for_64()
	if x==(TRUE)
		Data elf64_sym_st_name#1
	#const elf64_sym_st_info_offset=dwsz
		Chars elf64_sym_st_info#1
		Chars *elf64_sym_st_other={0}
		Chars elf64_sym_st_shndx#2
		Data elf64_sym_st_value#1;data *=0
		Data elf64_sym_st_size#1;data *=0

		Set elf64_sym_st_name stringoff
		Set elf64_sym_st_value value
		Set elf64_sym_st_size size
		set elf64_sym_st_info st_info
		Call memtomem(#elf64_sym_st_shndx,ptrndxsrc,wsz)

		Const elf64_sym_start^elf64_sym_st_name
		SetCall err addtosec(#elf64_sym_st_name,(!-elf64_sym_start),struct)
	else
		#Symbol table entry
		#Symbol name (string tbl index)
		Data elf32_sym_st_name#1
		#Symbol value
		Data elf32_sym_st_value#1
		#Symbol size
		Data elf32_sym_st_size#1
		#Symbol type and binding
		Const STB_LOCAL=0
		Const STB_WEAK=2
		Const STT_FUNC=2
		Const STT_SECTION=3
	#const elf32_sym_st_info_offset=3*dwsz
		Chars elf32_sym_st_info#1
		#Symbol visibility
		Chars *elf32_sym_st_other={0}
		#Section index
		Chars elf32_sym_st_shndx#2

		Set elf32_sym_st_name stringoff
		Set elf32_sym_st_value value
		Set elf32_sym_st_size size
		set elf32_sym_st_info st_info
		Call memtomem(#elf32_sym_st_shndx,ptrndxsrc,wsz)

		Const elf_sym_start^elf32_sym_st_name
		SetCall err addtosec(#elf32_sym_st_name,(!-elf_sym_start),struct)
	endelse

	Return err
EndFunction
#err
Function elfaddstrszsym(data stringstroff,data sz,data value,data size,chars type,chars bind,data index,data struct)
	Data regnr#1
	Data ptrregnr^regnr
	Data err#1
	Data noerr=noerror
	SetCall err addtonamessized(stringstroff,sz,ptrregnr)
	If err==noerr
		SetCall err elfaddsym(regnr,value,size,type,bind,index,struct)
	EndIf
	Return err
EndFunction
#err
Function elfaddstrsym(data stringstroff,data value,data size,chars type,chars bind,data index,data struct)
	Data sz#1
	SetCall sz strlen(stringstroff)
	Data err#1
	SetCall err elfaddstrszsym(stringstroff,sz,value,size,type,bind,index,struct)
	Return err
EndFunction

Data STT_NOTYPE=STT_NOTYPE
Data STT_FUNC=STT_FUNC
Data STT_SECTION=STT_SECTION

#const dataind=1
Const codeind=2
const dtnbind=3
Const symind=3
Data datastrtab#1
Data codestrtab#1
Data dtnbstrtab#1

#Data objfnmask#1
#Const ptrobjfnmask^objfnmask

#inplace	direct: at writetake: sd^data
#			   writevar:  data a^dataB    here is also notinplace data^import
#			   fndecarg:  (data a)
#no inplace:  rel: at writes resolves imports at non-object, this is not occuring at 64
#		 rel_base: call import()
#		 direct: the other writevar sd^data
#			   the other writetake (import)
#			   aftercall
#err
Function addrel_base(sd offset,sd symbolindex,sd addend,sd struct)
	#Direct 32 bit
	Const R_386_32=1
	const R_X86_64_32=10
	#PC relative 32 bit
	#const R_386_PC32=2
	#const R_X86_64_PC32=R_386_PC32
	#const R_X86_64_PC64=24

	sd err
	sd x;setcall x is_for_64()
	if x==(TRUE)
		Data elf64_r_offset#1;data *=0
		data elf64_r_info_type#1
	const p_elf64_r_info_type^elf64_r_info_type
	#const elf64_r_info_symbolindex_offset=2*dwsz
		data elf64_r_info_symbolindex#1
	#const elf64_r_info_symbolindex_size=dwsz
		data elf64_r_addend#1;data *=0

		#it is not enough
		#Call memtomem(#elf64_r_offset,#offset,(qwsz))
		set elf64_r_offset offset
		set elf64_r_info_symbolindex symbolindex
		set elf64_r_addend addend

		SetCall err addtosec(#elf64_r_offset,(elf64_dyn_d_val_relent),struct)
	else
		#offset
		Data elf_r_offset#1
		#Relocation type and symbol index
		Chars *elf_r_info_type=R_386_32
	#const elf_r_info_symbolindex_offset=dwsz+bsz
		chars elf_r_info_symbolindex#3
	#const elf_r_info_symbolindex_size=3
		data elf_r_addend#1

		Set elf_r_offset offset
		Call memtomem(#elf_r_info_symbolindex,#symbolindex,3)
		set elf_r_addend addend

		SetCall err addtosec(#elf_r_offset,(elf32_dyn_d_val_relent),struct)
	endelse
	Return err
EndFunction

#err
Function addrel(sd offset,sd symbolindex,sd struct)
	sd err
	setcall err addrel_base(offset,symbolindex,0,struct)
	return err
endfunction

#err
Function adddirectrel_base(sd relsec,sd extraoff,sd index,sd addend)
	Data err#1
	Data off#1
	Data ptroff^off
	Data ptrdatasec%ptrdatasec
	Data ptrcodesec%ptrcodesec
	Data ptraddresses%ptraddresses
	Data struct#1
	If relsec==ptraddresses
		Set struct ptrdatasec
	Else
		Set struct ptrcodesec
	EndElse
	Call getcontReg(struct,ptroff)
	Add off extraoff
	SetCall err addrel_base(off,index,addend,relsec)
	Return err
EndFunction
