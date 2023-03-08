


Data err#1

SetCall err openfile(ptrfileout,safecurrentdirtopath,_open_write)
If err!=noerr
	Chars fouterr="Error with the file out open function."
	Str fileouterr^fouterr
	Call msgerrexit(fileouterr)
EndIf

#headers
Data writeres#1
Data writefalse=writeno

SetCall writeres writefile(fileout,fileheaders,sizefileheaders)
If writeres==writefalse
	Call errexit()
EndIf
If fileformat==elf_unix
	If object==false
		SetCall writeres writefile(fileout,elf_progdeffileheaders,elf_progdeffileheaders_size)
		If writeres==writefalse
			Call errexit()
		EndIf
		Add sizefileheaders elf_progdeffileheaders_size
		If implibsstarted==true
			SetCall writeres writefile(fileout,importfileheaders,sizeimportfileheaders)
			If writeres==writefalse
				Call errexit()
			EndIf
			Add sizefileheaders sizeimportfileheaders
			#
			#
			SetCall errormsg elfaddsec_base(secstrs_off_atnames,0,0,null,null,0,0,0,0,null,ptrextra)
			If errormsg!=noerr;Call msgerrexit(errormsg);EndIf
			SetCall errormsg elfaddsec_base(dynstr,(SHT_STRTAB),(SHF_ALLOC),elf_str_offset,elf32_dyn_d_val_strsz,0,0,bytesize,0,elf32_dyn_d_ptr_strtab,ptrextra)
			#                                                   dynstr has alloc, the other str,no
			If errormsg!=noerr;Call msgerrexit(errormsg);EndIf
			const SHT_DYNAMIC=6
			SetCall errormsg elfaddsec_base(dynsec,(SHT_DYNAMIC),(SHF_WRITE|SHF_ALLOC),elf32_phdr_p_offset_dyn,elf32_phdr_p_filesz_dyn,1,0,elf32_phdr_p_align_dyn,qwordsize,elf32_phdr_p_vaddr_dyn,ptrextra)
			If errormsg!=noerr;Call msgerrexit(errormsg);EndIf
			#
			SetCall writeres writefile(fileout,extra,extraReg)
			If writeres==writefalse;Call errexit();EndIf
			Add sizefileheaders extraReg
			#extra used nomore
		Else
			SetCall errormsg elfaddsecn()
			If errormsg!=noerr;Call msgerrexit(errormsg);EndIf
			SetCall writeres writefile(fileout,miscbag,miscbagReg)
			If writeres==writefalse;Call errexit();EndIf
			Add sizefileheaders miscbagReg
		EndElse
	Else
		SetCall writeres writefile(fileout,miscbag,miscbagReg)
		If writeres==writefalse
			Call errexit()
		EndIf
		Add sizefileheaders miscbagReg
		#cannot see why i set this zero
		#Set miscbagReg zero
	EndElse
EndIf

SetCall writeres padsec(fileout,sizefileheaders,startofdata)
If writeres==writefalse
	Call errexit()
EndIf

Data writesecalignment#1
Set writesecalignment page_sectionalignment
If fileformat==elf_unix
	Set writesecalignment one
EndIf

#data section
SetCall writeres paddedwrite(fileout,datasec,datasecReg,writesecalignment)
If writeres==writefalse
	Call errexit()
EndIf

#code section
SetCall writeres paddedwrite(fileout,codesec,codesecReg,writesecalignment)
If writeres==writefalse
	Call errexit()
EndIf

If object==true
	#symtab
	SetCall writeres writefile(fileout,table,tableReg)
	If writeres==writefalse
		Call errexit()
	EndIf

	#relocs
	SetCall writeres writefile(fileout,addresses,addressesReg)
	If writeres==writefalse
		Call errexit()
	EndIf
	SetCall writeres writefile(fileout,extra,extraReg)
	If writeres==writefalse
		Call errexit()
	EndIf

	#strtab
	SetCall writeres writefile(fileout,names,namesReg)
	If writeres==writefalse
		Call errexit()
	EndIf
ElseIf implibsstarted==true
	#idata section
	If fileformat==pe_exec
		#table
		SetCall writeres paddedwrite(fileout,table,tableReg,tableMax)
		If writeres==writefalse
			Call errexit()
		EndIf
		#addresses
		SetCall writeres paddedwrite(fileout,addresses,addressesReg,addressesMax)
		If writeres==writefalse
			Call errexit()
		EndIf
		#names
		SetCall writeres paddedwrite(fileout,names,namesReg,namesMax)
		If writeres==writefalse
			Call errexit()
		EndIf
	Else
		#interpreter
		SetCall writeres writefile(fileout,ptrinterpreter,interpretersize)
		If writeres==writefalse
			Call errexit()
		EndIf

		#dynamic
		SetCall writeres writefile(fileout,table,tableReg)
		If writeres==writefalse
			Call errexit()
		EndIf
		Data ptrelf_dyn%elf_dynfix_start
		SetCall writeres writefile(fileout,ptrelf_dyn,elf_dynfix_size)
		If writeres==writefalse
			Call errexit()
		EndIf

		#lib
		##hashfix
		Data ptrelf_hash%elf_hash_start
		SetCall writeres writefile(fileout,ptrelf_hash,elf_hash_minsize)
		If writeres==writefalse
			Call errexit()
		EndIf
		##hashvar
		Data elf_loop_write#1
		Set elf_loop_write miscbag
		SetCall writeres writefile(fileout,elf_loop_write,hash_var_size)
		If writeres==writefalse
			Call errexit()
		EndIf
		Add elf_loop_write hash_var_size

		##symtab
		SetCall writeres writefile(fileout,addresses,addressesReg)
		If writeres==writefalse
			Call errexit()
		EndIf

		##strtab
		SetCall writeres writefile(fileout,names,namesReg)
		If writeres==writefalse
			Call errexit()
		EndIf

		##rel
		SetCall writeres writefile(fileout,elf_loop_write,rel_var_size)
		If writeres==writefalse
			Call errexit()
		EndIf
		Add elf_loop_write rel_var_size

		##calls
		SetCall writeres writefile(fileout,elf_loop_write,elf_rel_entries_size)
		If writeres==writefalse
			Call errexit()
		EndIf
	EndElse
EndElseIf
