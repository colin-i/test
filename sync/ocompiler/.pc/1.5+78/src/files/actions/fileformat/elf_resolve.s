
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
	Data elf_sections_start_count=2
	data ptrelf_sections_start_count^elf_sections_start_count
	call memtomem(ptrelf32_ehd_e_phnum,ptrelf_sections_start_count,wordsize)
	#######

	#commons#
	Set virtuallocalsoffset elf32_phdr_p_vaddr_code
	Set fileheaders elf_fileheaders
	Set sizefileheaders elf_fileheaders_size
	#commons#

	if implibsstarted==false
		call memtomem(ptrelf32_ehd_e_shnum,#one,wordsize)
		#######
		call memtomem(ptrelf32_ehd_e_shstrndx,ptrnull,wordsize)
	else
		call memtomem(ptrelf32_ehd_e_shnum,#three,wordsize)
		#######
		#add here, next will be calculations and these will be above
		data secstrs_off_atnames#1
		setcall errormsg addtonames(ptrnull,#secstrs_off_atnames)
		chars dynstr_c=".dynstr";data dynstr#1
		#shstrtab
		setcall errormsg addtonames(#dynstr_c,#dynstr)
		If errormsg!=noerr;Call msgerrexit(errormsg);EndIf
		chars dynsec_c=".dynamic";data dynsec#1
		setcall errormsg addtonames(#dynsec_c,#dynsec)
		If errormsg!=noerr;Call msgerrexit(errormsg);EndIf
		#
		call memtomem(ptrelf32_ehd_e_shstrndx,#one,wordsize)

		#imports
		#If implibsstarted==true
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





		#the entry is not taken without this
		data test1#1
		data test2#1
		set test1 elf32_phdr_p_vaddr_interp
		div test1 page_sectionalignment
		set test2 elf32_phdr_p_vaddr_dyn
		div test2 page_sectionalignment
		if test2==test1
			add elf32_phdr_p_vaddr_dyn page_sectionalignment
		endif
		#recent tests (after some years have passed):
		#	dynamic section must be in a load segment by gdb warning
		#	segment=program header
		#	readelf,gdb,objdump are not error/warning but the executable can only run with /lib/ld-linux.so.2 ./prog
		#		for printf or something else, here at libs

		#"ELF load command address/offset not page-aligned"
		#but the fact was to align
		#and elf32_phdr_p_vaddr_dyn (~page_sectionalignment^(page_sectionalignment-1)|page_sectionalignment)
		#~(page_sectionalignment-1)





		Set elf32_phdr_p_paddr_dyn elf32_phdr_p_vaddr_dyn

		Set elf32_phdr_p_filesz_dyn tableReg
		Add elf32_phdr_p_filesz_dyn elf_dynfix_size

		Set elf32_phdr_p_memsz_dyn elf32_phdr_p_filesz_dyn

		#libraries load
		Inc elf32_ehd_e_phnum

		Set elf32_phdr_p_offset_lib elf32_phdr_p_offset_dyn
		#Add elf32_phdr_p_offset_lib elf32_phdr_p_filesz_dyn
		data elf_str_offset#1
		set elf_str_offset elf32_phdr_p_offset_lib
		Add elf_str_offset elf32_phdr_p_filesz_dyn

		set elf32_phdr_p_vaddr_lib elf32_phdr_p_vaddr_dyn
		#Add elf32_phdr_p_vaddr_lib elf32_phdr_p_filesz_dyn

		Set elf32_phdr_p_paddr_lib elf32_phdr_p_vaddr_lib

		##resolve libraries
		###hash
		Set elf32_dyn_d_ptr_hash elf32_phdr_p_vaddr_lib
		Add elf32_dyn_d_ptr_hash elf32_phdr_p_filesz_dyn

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

		#stroff
		add elf_str_offset elf32_phdr_p_filesz_lib

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
		Data elf_rel_info_symbolindex#1

		Set elf_rel_offset elf32_dyn_d_ptr_rel
		Add elf_rel_offset elf32_dyn_d_val_relsz
		Set elf_rel_info_symbolindex zero

		While elf_rel_info_symbolindex<sizeofchain
			SetCall errormsg addrel(elf_rel_offset,elf_rel_info_symbolindex,ptrmiscbag)
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

		SetCall errormsg addtosec(0,elf_rel_entries_size,ptrmiscbag)
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

		Set virtualimportsoffset elf32_dyn_d_ptr_hash
		Add virtualimportsoffset elf32_phdr_p_filesz_lib
		#commons#

		#
		Add elf32_phdr_p_filesz_lib elf_rel_entries_size
		add elf32_phdr_p_filesz_lib elf32_phdr_p_filesz_dyn
		#

		Set elf32_phdr_p_memsz_lib elf32_phdr_p_filesz_lib
	endelse

	#######some section/s for readelf
	sd sections_start=elf32_ehd_e_phentsize
	mult sections_start elf32_ehd_e_phnum
	add sections_start elf_fileheaders_size
	call memtomem(ptrelf32_ehd_e_shoff,#sections_start,wordsize)
Else
	#######
	Data ET_REL=ET_REL
	Data ptrET_REL^ET_REL
	Call memtomem(ptrelf32_ehd_e_type,ptrET_REL,wordsize)
	#######
	Set elf32_ehd_e_entry null
	#######
	Set elf32_ehd_e_phoff null
	#######
	call memtomem(ptrelf32_ehd_e_phnum,ptrnull,wordsize)
	#######
	#######
	sd elf_sec_nr=7
	sd ptrelf_sec_nr^elf_sec_nr
	#######
	sd elf_sec_strtab_nr=-1
	sd ptrelf_sec_strtab_nr^elf_sec_strtab_nr
	#######

	Data SHT_PROGBITS=SHT_PROGBITS
	Data elf_sec_fileoff#1

	SetCall errormsg elfaddsecn()
	If errormsg!=noerr
		Call msgerrexit(errormsg)
	EndIf

	Data elf_sec_flags_data=SHF_WRITE|SHF_ALLOC
	Set elf_sec_fileoff elf32_phdr_p_offset_data
	SetCall errormsg elfaddsec(datastrtab,SHT_PROGBITS,elf_sec_flags_data,elf_sec_fileoff,ptrdatasec,null,null,(elf_sec_obj_align),null)
	If errormsg!=noerr
		Call msgerrexit(errormsg)
	EndIf
	Add elf_sec_fileoff datasecReg

	Data elf_sec_flags_text=SHF_ALLOC|SHF_EXECINSTR
	SetCall errormsg elfaddsec(codestrtab,SHT_PROGBITS,elf_sec_flags_text,elf_sec_fileoff,ptrcodesec,null,null,(elf_sec_obj_align),null)
	If errormsg!=noerr
		Call msgerrexit(errormsg)
	EndIf
	Add elf_sec_fileoff codesecReg

	sd symind=symind

	if nobits_virtual==(Yes)
		SetCall errormsg elfaddsecs(dtnbstrtab,(SHT_NOBITS),elf_sec_flags_data,elf_sec_fileoff,nobitssecReg,(elf_sec_obj_align))
		If errormsg!=noerr
			Call msgerrexit(errormsg)
		EndIf
		inc elf_sec_nr
		inc symind
	endif

	if has_debug==(Yes)
		#SHT_NULL will not reach linker output
		SetCall errormsg elfaddstrsec(".debug",(SHT_PROGBITS),0,elf_sec_fileoff,ptrdebug,0,0,(bsz),0)
		If errormsg!=noerr
			Call msgerrexit(errormsg)
		EndIf
		add elf_sec_fileoff debugsecReg
		inc elf_sec_nr
		inc symind
	endif

	add elf_sec_strtab_nr elf_sec_nr
	sd syment;sd relent
	if p_is_for_64_value#==(TRUE)
		Set elf64_ehd_e_shoff (elf64_fileheaders_size)
		call memtomem(#elf64_ehd_e_shnum,ptrelf_sec_nr,wordsize)
		call memtomem(#elf64_ehd_e_shstrndx,ptrelf_sec_strtab_nr,wordsize)
		Set fileheaders #elf64_ehd_e_ident_sign
		Set sizefileheaders (elf64_fileheaders_size)
		set syment (elf64_dyn_d_val_syment);set relent (elf64_dyn_d_val_relent)
	else
		Set elf32_ehd_e_shoff elf_fileheaders_size
		call memtomem(ptrelf32_ehd_e_shnum,ptrelf_sec_nr,wordsize)
		call memtomem(ptrelf32_ehd_e_shstrndx,ptrelf_sec_strtab_nr,wordsize)
		Set fileheaders elf_fileheaders
		Set sizefileheaders elf_fileheaders_size
		set syment elf32_dyn_d_val_syment;set relent elf32_dyn_d_val_relent
	endelse

	Chars elfsymtab=".symtab"
	Str ptrelfsymtab^elfsymtab
	Data SHT_SYMTAB=2

	SetCall errormsg elfaddstrsec(ptrelfsymtab,SHT_SYMTAB,null,elf_sec_fileoff,ptrtable,elf_sec_strtab_nr,totallocalsymsaddedatstart,dwordsize,syment)
	If errormsg!=noerr
		Call msgerrexit(errormsg)
	EndIf

	Data SHT_RELA=4

	Chars elfreldata=".rela.data"
	Str ptrelfreldata^elfreldata
	Add elf_sec_fileoff tableReg
	SetCall errormsg elfaddstrsec(ptrelfreldata,SHT_RELA,null,elf_sec_fileoff,ptraddresses,symind,dataind,dwordsize,relent)
	If errormsg!=noerr
		Call msgerrexit(errormsg)
	EndIf

	Chars elfreltxt=".rela.text"
	Str ptrelfreltxt^elfreltxt
	Add elf_sec_fileoff addressesReg
	SetCall errormsg elfaddstrsec(ptrelfreltxt,SHT_RELA,null,elf_sec_fileoff,ptrextra,symind,codeind,dwordsize,relent)
	If errormsg!=noerr
		Call msgerrexit(errormsg)
	EndIf

	Chars elfstrtab=".strtab"
	Str ptrelfstrtab^elfstrtab
	Add elf_sec_fileoff extraReg
	SetCall errormsg elfaddstrsec(ptrelfstrtab,(SHT_STRTAB),null,elf_sec_fileoff,ptrnames,null,null,bytesize,null)
	If errormsg!=noerr
		Call msgerrexit(errormsg)
	EndIf

	Set startofdata elf_startofdata
EndElse
