
If object==false
	#data
	Set elf32_phdr_p_filesz_data datasecReg
	Set elf32_phdr_p_memsz_data datasecReg

	#code
	Set elf32_phdr_p_offset_code elf32_phdr_p_offset_data
	Add elf32_phdr_p_offset_code datasecReg

	Set elf32_phdr_p_vaddr_code elf32_phdr_p_vaddr_data

	SetCall elf32_phdr_p_vaddr_code congruentmoduloatsegments(elf32_phdr_p_vaddr_code,elf32_phdr_p_offset_code,page_sectionalignment,datasecReg)
	Set elf32_phdr_p_paddr_code elf32_phdr_p_vaddr_code

	Set elf32_phdr_p_filesz_code codesecReg
	Set elf32_phdr_p_memsz_code codesecReg


	#######
	Data ET_EXEC=2
	Data ptrET_EXEC^ET_EXEC
	Call memtomem(ptrelf32_ehd_e_type,ptrET_EXEC,wordsize)
	#######
	Add programentrypoint elf32_phdr_p_vaddr_code
	Set elf32_ehd_e_entry programentrypoint
	#######
	Set elf32_ehd_e_phoff elf_fileheaders_size
	#######
	Set elf32_ehd_e_shoff null
	#######
	Data elf_sections_start_count=2
	data ptrelf_sections_start_count^elf_sections_start_count
	call memtomem(ptrelf32_ehd_e_phnum,ptrelf_sections_start_count,wordsize)
	#######
	call memtomem(ptrelf32_ehd_e_shnum,ptrnull,wordsize)
	#######
	call memtomem(ptrelf32_ehd_e_shstrndx,ptrnull,wordsize)
	#######

	#commons#
	Set virtuallocalsoffset elf32_phdr_p_vaddr_code
	#commons#
Else
	#######
	Data ET_REL=1
	Data ptrET_REL^ET_REL
	Call memtomem(ptrelf32_ehd_e_type,ptrET_REL,wordsize)
	#######
	Set elf32_ehd_e_entry null
	#######
	Set elf32_ehd_e_phoff null
	#######
	Set elf32_ehd_e_shoff elf_fileheaders_size
	#######
	call memtomem(ptrelf32_ehd_e_phnum,ptrnull,wordsize)
	#######
	Const elf_sec_nr=7
	Const elf_sec_strtab_nr=elf_sec_nr-1
	Data elf_sec_nr=elf_sec_nr
	data ptrelf_sec_nr^elf_sec_nr
	call memtomem(ptrelf32_ehd_e_shnum,ptrelf_sec_nr,wordsize)
	#######
	Data elf_sec_strtab_nr=elf_sec_strtab_nr
	data ptrelf_sec_strtab_nr^elf_sec_strtab_nr
	call memtomem(ptrelf32_ehd_e_shstrndx,ptrelf_sec_strtab_nr,wordsize)
	#######

	Data SHT_PROGBITS=SHT_PROGBITS
	Data elf_sec_fileoff#1

	SetCall errormsg elfaddsec(null,null,null,null,null,null,null,null,null)
	If errormsg!=noerr
		Call msgerrexit(errormsg)
	EndIf
	
	Data elf_sec_flags_data=SHF_ALLOC
	Set elf_sec_fileoff elf32_phdr_p_offset_data
	SetCall errormsg elfaddsec(datastrtab,SHT_PROGBITS,elf_sec_flags_data,elf_sec_fileoff,ptrdatasec,null,null,dwordsize,null)
	If errormsg!=noerr
		Call msgerrexit(errormsg)
	EndIf

	Data elf_sec_flags_text=SHF_ALLOC|SHF_EXECINSTR
	Add elf_sec_fileoff datasecReg
	SetCall errormsg elfaddsec(codestrtab,SHT_PROGBITS,elf_sec_flags_text,elf_sec_fileoff,ptrcodesec,null,null,dwordsize,null)
	If errormsg!=noerr
		Call msgerrexit(errormsg)
	EndIf

	Chars elfsymtab=".symtab"
	Str ptrelfsymtab^elfsymtab
	Data SHT_SYMTAB=2
	Add elf_sec_fileoff codesecReg
	Data oneGreaterThanLastSTB_LOCAL=oneGreaterThanLastSTB_LOCAL

	SetCall errormsg elfaddstrsec(ptrelfsymtab,SHT_SYMTAB,null,elf_sec_fileoff,ptrtable,elf_sec_strtab_nr,oneGreaterThanLastSTB_LOCAL,dwordsize,elf32_dyn_d_val_syment)
	If errormsg!=noerr
		Call msgerrexit(errormsg)
	EndIf

	Data SHT_REL=9
	Data symind=symind

	Chars elfreldata=".rel.data"
	Str ptrelfreldata^elfreldata
	Add elf_sec_fileoff tableReg
	SetCall errormsg elfaddstrsec(ptrelfreldata,SHT_REL,null,elf_sec_fileoff,ptraddresses,symind,dataind,dwordsize,elf32_dyn_d_val_relent)
	If errormsg!=noerr
		Call msgerrexit(errormsg)
	EndIf

	Chars elfreltxt=".rel.text"
	Str ptrelfreltxt^elfreltxt
	Add elf_sec_fileoff addressesReg
	SetCall errormsg elfaddstrsec(ptrelfreltxt,SHT_REL,null,elf_sec_fileoff,ptrextra,symind,codeind,dwordsize,elf32_dyn_d_val_relent)
	If errormsg!=noerr
		Call msgerrexit(errormsg)
	EndIf

	Chars elfstrtab=".strtab"
	Str ptrelfstrtab^elfstrtab
	Data SHT_STRTAB=3
	Add elf_sec_fileoff extraReg
	SetCall errormsg elfaddstrsec(ptrelfstrtab,SHT_STRTAB,null,elf_sec_fileoff,ptrnames,null,null,bytesize,null)
	If errormsg!=noerr
		Call msgerrexit(errormsg)
	EndIf

	Set startofdata elf_startofdata
EndElse

#commons#
Set fileheaders elf_fileheaders
Set sizefileheaders elf_fileheaders_size
#commons#

#imports
If implibsstarted==true
	#interpreter
	Inc elf32_ehd_e_phnum

	Set elf32_phdr_p_offset_interp elf32_phdr_p_offset_code
	Add elf32_phdr_p_offset_interp codesecReg

	Set elf32_phdr_p_vaddr_interp elf32_phdr_p_vaddr_code
	Add elf32_phdr_p_vaddr_interp codesecReg
	#SetCall elf32_phdr_p_vaddr_interp congruentmoduloatsegments(elf32_phdr_p_vaddr_interp,elf32_phdr_p_offset_interp,page_sectionalignment,codesecReg)

	Set elf32_phdr_p_paddr_interp elf32_phdr_p_vaddr_interp

	SetCall interpretersize strlen(ptrinterpreter)
	Inc interpretersize

	Set elf32_phdr_p_filesz_interp interpretersize
	Set elf32_phdr_p_memsz_interp interpretersize

	#dynamic
	Inc elf32_ehd_e_phnum
	
	Set elf32_phdr_p_offset_dyn elf32_phdr_p_offset_interp
	Add elf32_phdr_p_offset_dyn interpretersize

	Set elf32_phdr_p_vaddr_dyn elf32_phdr_p_vaddr_interp
	Add elf32_phdr_p_vaddr_dyn interpretersize

	Set elf32_phdr_p_paddr_dyn elf32_phdr_p_vaddr_dyn

	Set elf32_phdr_p_filesz_dyn tableReg
	Add elf32_phdr_p_filesz_dyn elf_dynfix_size

	Set elf32_phdr_p_memsz_dyn elf32_phdr_p_filesz_dyn

	#libraries load
	Inc elf32_ehd_e_phnum

	Set elf32_phdr_p_offset_lib elf32_phdr_p_offset_dyn
	Add elf32_phdr_p_offset_lib elf32_phdr_p_filesz_dyn

	set elf32_phdr_p_vaddr_lib elf32_phdr_p_vaddr_dyn
	Add elf32_phdr_p_vaddr_lib elf32_phdr_p_filesz_dyn

	data test1#1
	data test2#1
	set test1 elf32_phdr_p_vaddr_interp
	div test1 page_sectionalignment
	set test2 elf32_phdr_p_vaddr_lib
	div test2 page_sectionalignment
	if test2==test1
		add elf32_phdr_p_vaddr_lib page_sectionalignment
	endif

	Set elf32_phdr_p_paddr_lib elf32_phdr_p_vaddr_lib

	##resolve libraries
	###hash
	Set elf32_dyn_d_ptr_hash elf32_phdr_p_vaddr_lib

	#
	Set elf32_phdr_p_filesz_lib elf_hash_minsize
	#

	Set sizeofchain addressesReg
	Div sizeofchain elf32_dyn_d_val_syment

	## '## '=import command dependent
	Data loopsymbols#1
	Data ptrloopsymbols^loopsymbols
	Set loopsymbols zero
	While loopsymbols<sizeofchain
		SetCall errormsg addtosec(ptrloopsymbols,dwordsize,ptrmiscbag)
		If errormsg!=noerr
			Call msgerrexit(errormsg)
		EndIf
		Inc loopsymbols
	EndWhile
	##
	Set hash_var_size miscbagReg

	#
	Add elf32_phdr_p_filesz_lib hash_var_size
	#

	###symtab
	Set elf32_dyn_d_ptr_symtab elf32_dyn_d_ptr_hash
	Add elf32_dyn_d_ptr_symtab elf_hash_minsize
	Add elf32_dyn_d_ptr_symtab hash_var_size
	
	#
	Add elf32_phdr_p_filesz_lib addressesReg
	#

	###strtab
	Set elf32_dyn_d_ptr_strtab elf32_dyn_d_ptr_symtab
	Add elf32_dyn_d_ptr_strtab addressesReg

	###strsz
	Set elf32_dyn_d_val_strsz namesReg

	#
	Add elf32_phdr_p_filesz_lib namesReg
	#

	###rel
	Set elf32_dyn_d_ptr_rel elf32_dyn_d_ptr_strtab
	Add elf32_dyn_d_ptr_rel namesReg

	###relsz
	Set elf32_dyn_d_val_relsz sizeofchain

	Mult elf32_dyn_d_val_relsz elf32_dyn_d_val_relent

	#
	Add elf32_phdr_p_filesz_lib elf32_dyn_d_val_relsz
	#

	##
	Data elf_rel_offset#1
	Chars elf_rel_info_type={R_386_32}
	Data elf_rel_info_symbolindex#1

	Set elf_rel_offset elf32_dyn_d_ptr_rel
	Add elf_rel_offset elf32_dyn_d_val_relsz
	Set elf_rel_info_symbolindex zero

	While elf_rel_info_symbolindex<sizeofchain
		SetCall errormsg addrel(elf_rel_offset,elf_rel_info_type,elf_rel_info_symbolindex,ptrmiscbag)
		If errormsg!=noerr
			Call msgerrexit(errormsg)
		EndIf
		Inc elf_rel_info_symbolindex
		Add elf_rel_offset dwordsize
	EndWhile
	##

	Set rel_var_size miscbagReg
	Sub rel_var_size hash_var_size
	
	Set elf_rel_entries_size sizeofchain
	Mult elf_rel_entries_size dwordsize

	SetCall errormsg addtosec(null,elf_rel_entries_size,ptrmiscbag)
	If errormsg!=noerr
		Call msgerrexit(errormsg)
	EndIf

	Data el_rel_entries_loop#1
	Set el_rel_entries_loop miscbag
	Add el_rel_entries_loop miscbagReg
	Set loopsymbols zero
	While loopsymbols<sizeofchain
		Sub el_rel_entries_loop dwordsize
		Set el_rel_entries_loop# zero
		Inc loopsymbols
	EndWhile

	#commons#
	Set importfileheaders elf_importfileheaders
	Set sizeimportfileheaders elf_importfileheaders_size

	Set virtualimportsoffset elf32_phdr_p_vaddr_lib
	Add virtualimportsoffset elf32_phdr_p_filesz_lib
	#commons#

	#
	Add elf32_phdr_p_filesz_lib elf_rel_entries_size
	#

	Set elf32_phdr_p_memsz_lib elf32_phdr_p_filesz_lib



	
	#sub elf32_phdr_p_offset_lib elf32_phdr_p_filesz_interp
	#sub elf32_phdr_p_offset_lib elf32_phdr_p_filesz_dyn

	#add elf32_phdr_p_filesz_lib elf32_phdr_p_filesz_interp
	#add elf32_phdr_p_filesz_lib elf32_phdr_p_filesz_dyn

	#Set elf32_phdr_p_paddr_lib elf32_phdr_p_vaddr_lib
	#Set elf32_phdr_p_memsz_lib elf32_phdr_p_filesz_lib
EndIf

