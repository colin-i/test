

sd import_ref_mask=idatabitfunction
if subtype==(cIMPORTX)
	sd importx_bool;setcall importx_bool is_for_64()
	if importx_bool==(TRUE);or import_ref_mask (x86_64bit);endif
endif

Data impquotsz=0
Data impescapes=0
Data ptrimpquotsz^impquotsz
Data ptrimpescapes^impescapes

If object==false
	If implibsstarted==false
		Chars noliberr="Unexpected IMPORT statement; there is no LIBRARY opened."
		Str ptrnoliberr^noliberr
		Set errormsg ptrnoliberr
	EndIf
EndIf
If errormsg==noerr
	Data functionoffset#1
	
	If fileformat==pe_exec
		Set functionoffset addressesReg

		Str ptrnamescurrentoffset^namesReg
		SetCall errormsg addtosec(ptrnamescurrentoffset,dwordsize,ptraddresses)
		If errormsg==noerr
			SetCall errormsg addtosec(ptrnull,wordsize,ptrnames)
		EndIf
	Else
		#get the last index for offset resolvations
		If object==false
			Set functionoffset addressesReg
		Else
			Set functionoffset tableReg
		EndElse
		#get the function index
		If object==false
			Div functionoffset elf32_dyn_d_val_syment
			#get the dword offset to call at, index*dword
			Mult functionoffset dwordsize
			SetCall errormsg elfaddsym(namesReg,null,null,STT_FUNC,STB_GLOBAL,null,ptraddresses)
		ElseIf p_is_for_64_resp#==(TRUE)
			div functionoffset (elf64_dyn_d_val_syment)
		Else
			Div functionoffset elf32_dyn_d_val_syment
		EndElse
	EndElse
	If errormsg==noerr
		SetCall errormsg quotinmem(pcontent,pcomsize,ptrimpquotsz,ptrimpescapes)
		If errormsg==noerr
			If object==true
				#the sym entry
				SetCall errormsg elfaddsym(namesReg,zero,(sym_with_size),STT_NOTYPE,STB_GLOBAL,null,ptrtable)
			EndIf
			SetCall errormsg addtosecstresc(pcontent,pcomsize,impquotsz,impescapes,ptrnames,true)
			If errormsg==noerr
				Call stepcursors(pcontent,pcomsize)
				Call spaces(pcontent,pcomsize)
				If comsize==zero
					Chars missimportref="Import name for compiler must be specified after the name for output."
					Str ptrimpref^missimportref
					Set errormsg ptrimpref
				Else
					SetCall errormsg entryvarsfns(content,comsize)
					If errormsg==noerr
						if logbool==(TRUE)
							if log_import_functions==(TRUE)
								ss imp_f="Import Function:";sd imp_f_sz;setcall imp_f_sz strlen(imp_f)
								call writefile(logfile,imp_f,imp_f_sz)
								call addtolog_ex(content,comsize)
							endif
						endif
						Data functionsnr=functionsnumber
						SetCall errormsg addaref(functionoffset,pcontent,pcomsize,comsize,functionsnr,import_ref_mask)
					EndIf
				EndElse
			EndIf
		EndIf
	EndIf
EndIf