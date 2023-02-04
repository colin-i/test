

Data impquotsz#1
Data impescapes#1
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
			SetCall errormsg elfaddsym(namesReg,null,null,STT_FUNC,(STB_GLOBAL),null,ptraddresses)
		ElseIf p_is_for_64_resp#==(TRUE)
			div functionoffset (elf64_dyn_d_val_syment)
		Else
			Div functionoffset elf32_dyn_d_val_syment
		EndElse
	EndElse
	If errormsg==noerr
		SetCall errormsg quotinmem(pcontent,pcomsize,ptrimpquotsz,ptrimpescapes)
		If errormsg==noerr
			Call import_leading_underscore(pcontent,pcomsize,ptrimpquotsz)
			If object==true
				#the sym entry
				SetCall errormsg elfaddsym(namesReg,zero,(sym_with_size),STT_NOTYPE,(STB_GLOBAL),null,ptrtable)
			EndIf
			If errormsg==noerr
				sd imp_mark;set imp_mark namesReg #this is because the null at end makes code harder
				SetCall errormsg addtosecstresc(pcontent,pcomsize,impquotsz,impescapes,ptrnames,true)
				If errormsg==noerr
					Call stepcursors(pcontent,pcomsize)
					Call spaces(pcontent,pcomsize)
					#after this will find var in vars/fns and if not add a new
					sd imp_size;setcall imp_size find_whitespaceORcomment(content,comsize)
					If imp_size==zero
						Chars missimportref="Import name for compiler must be specified after the name for output."
						Str ptrimpref^missimportref
						Set errormsg ptrimpref
					Else
						SetCall errormsg fnimp_exists(content,imp_size) #it is at first pass when only fns and imports are
						If errormsg==noerr
							if codeFnObj==(log_warn)
								if subtype==(cIMPORT)
									sub impquotsz impescapes
									add imp_mark names
									setcall errormsg addtolog_withchar_ex_atunused_handle(imp_mark,impquotsz,(log_import),logaux) #at this pass is no log
								endif
							endif
							If errormsg==noerr
								sd import_ref_mask=idatabitfunction
								if subtype==(cIMPORTX)
									or import_ref_mask (x86_64bit)
								endif
								Data functionsnr=functionsnumber
								SetCall errormsg addaref(functionoffset,pcontent,pcomsize,imp_size,functionsnr,import_ref_mask)
							endIf
						EndIf
					EndElse
				EndIf
			EndIf
		EndIf
	EndIf
EndIf