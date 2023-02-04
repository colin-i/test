
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
Function elfaddsec(data stringname,data type,data flags,data fileoffset,data seccont,data link,data info,data align,data entsize)
	#Section header
	#Section name (string tbl index)
	Data sh_name#1
	#Section type
	Data sh_type#1
	#Section flags
	Data sh_flags#1
	#Section virtual addr at execution
	Data *sh_addr=0
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

	Const elf_section^sh_name
	Const lastsectionh^sh_entsize
	Const elf_section_size=lastsectionh+dwsz-elf_section
	Data elf_section%elf_section
	Data elf_section_size=elf_section_size

	Const SHT_NULL=0
	Const SHT_PROGBITS=1
	Const SHT_NOBITS=8
		
		#Occupies memory during execution,1 << 1
	Const SHF_ALLOC=2*1
		#Executable,1 << 2
	Const SHF_EXECINSTR=2*2
		#`sh_info' contains SHT index,1 << 6
	Const SHF_INFO_LINK=2*6

	Data err#1
	Data ptrmiscbag%ptrmiscbag

	Data SHT_NULL=SHT_NULL
	Data SHT_PROGBITS=SHT_PROGBITS
	Data SHT_NOBITS=SHT_NOBITS
	Data zero=0

	If type==SHT_NULL
		Call memset(elf_section,zero,elf_section_size)
	Else
		Set sh_name stringname
		
		Data ptrsh_size^sh_size
		Call getcontReg(seccont,ptrsh_size)
		If type==SHT_PROGBITS
			If sh_size==zero
				Set type SHT_NOBITS
			EndIf
		EndIf
		Set sh_type type

		Set sh_flags flags
		Set sh_offset fileoffset
		#   sh_size
		Set sh_link link
		Set sh_info info
		Set sh_addralign align
		Set sh_entsize entsize
	EndElse
	SetCall err addtosec(elf_section,elf_section_size,ptrmiscbag)
	Return err
EndFunction

#err
Function elfaddstrsec(data stringoffname,data type,data flags,data fileoffset,data seccont,data link,data info,data align,data entsize)
	Data regnr#1
	Data ptrregnr^regnr
	Data err#1
	Data noerr=noerror
	SetCall err addtonames(stringoffname,ptrregnr)
	If err==noerr
		SetCall err elfaddsec(regnr,type,flags,fileoffset,seccont,link,info,align,entsize)
	EndIf
	Return err
EndFunction

#err
Function elfaddsym(data stringoff,data value,data size,chars type,chars bind,data index,data struct)
	#Symbol table entry
	#Symbol name (string tbl index)
	Data elf32_sym_st_name#1
	#Symbol value
	Data elf32_sym_st_value#1
	#Symbol size
	Data elf32_sym_st_size#1
	#Symbol type and binding
	Const STB_LOCAL=0
	Const STB_GLOBAL=1
	Const STT_NOTYPE=0
	Const STT_FUNC=2
	Const STT_SECTION=3
	Chars elf32_sym_st_info#1
	#Symbol visibility
	Chars *elf32_sym_st_other={0}
	#Section index
	Chars elf32_sym_st_shndx#2

	Const elf_sym_start^elf32_sym_st_name
	Data elf_sym_size=!-elf_sym_start
	Data elf_sym%elf_sym_start

	Set elf32_sym_st_name stringoff
	Set elf32_sym_st_value value
	Set elf32_sym_st_size size

	Set elf32_sym_st_info type
	Chars tohibyte={16}
	Mult bind tohibyte
	Or elf32_sym_st_info bind

	Data ptrndxdest^elf32_sym_st_shndx
	Data ptrndxsrc^index
	Data wsz=wsz
	Call memtomem(ptrndxdest,ptrndxsrc,wsz)

	sd err
	SetCall err addtosec(elf_sym,elf_sym_size,struct)
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

Data STB_LOCAL=STB_LOCAL
Data STB_GLOBAL=STB_GLOBAL
Data STT_NOTYPE=STT_NOTYPE
Data STT_FUNC=STT_FUNC
Data STT_SECTION=STT_SECTION

Const dataind=1
Const codeind=2
Const symind=3
Data datastrtab#1
Data codestrtab#1

Data objfnmask#1
Const ptrobjfnmask^objfnmask

#err
Function addrel(data offset,chars type,data symbolindex,data struct)
	#offset
	Data elf_rel_offset#1
	#Relocation type and symbol index
	#Direct 32 bit
	Const R_386_32=1
	#PC relative 32 bit
	Const R_386_PC32=2
	
	Chars elf_rel_info_type#1
	Data elf_rel_info_symbolindex#1
	
	Data elf_rel^elf_rel_offset
	Data elf_rel_sz=elf32_dyn_d_val_relent

	Set elf_rel_offset offset
	Set elf_rel_info_type type
	Set elf_rel_info_symbolindex symbolindex

	Data err#1
	SetCall err addtosec(elf_rel,elf_rel_sz,struct)
	Return err
EndFunction

#err
Function adddirectrel(data relsec,data extraoff,data index)
	Data noerr=noerror
	Data ptrobject%ptrobject
	Data false=FALSE
	If ptrobject#==false
		Return noerr
	EndIf
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
	Chars elf_rel_info_type={R_386_32}
	SetCall err addrel(off,elf_rel_info_type,index,relsec)
	Return err
EndFunction
