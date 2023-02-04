
#note that multiple calls on aftercall are tolerated and the next calls will use the last aftercall(can be used in a code strategy with multiple functions)

if comsize==0;set errormsg "AfterCall variable name expected."
else
	str ac_store_content#1;data ac_store_size#1
	set ac_store_content pcontent#;set ac_store_size comsize
	data acsym_value#1;data acsym_size#1;data acsym_shndx#1
	sd g_e_p;setcall g_e_p global_err_p()
	if subtype==(cAFTERCALL)
		SetCall errormsg entryvarsfns(pcontent#,pcomsize#)
		if errormsg==(noerror)
			sd ac_current_data;setcall ac_current_data get_img_vdata_dataReg()
			SetCall errormsg addaref(ac_current_data,pcontent,pcomsize,comsize,(charsnumber),(dummy_mask))
			if errormsg==(noerror)
				SetCall errormsg addtosec(#null,1,ptrdatasec)
				if errormsg==(noerror)
					If object==(FALSE)
						set g_e_p# ac_current_data
					else
						set acsym_value ac_current_data;set acsym_size 0;set acsym_shndx (dataind)
					endelse
				endif
			endif
		endif
	else
	#(cIMPORTAFTERCALL)
		If object==(FALSE);set errormsg "ImportAfterCall is used at objects."
		else
			set acsym_value 0;set acsym_size (sym_with_size);set acsym_shndx (NULL)
			call advancecursors(pcontent,pcomsize,comsize)
		endelse
	endelse
	if errormsg==(noerror)
		set g_e_b_p# (TRUE)
		if object==(TRUE)
			set g_e_p# tableReg
			if p_is_for_64_resp#==(TRUE)
				div g_e_p# (elf64_dyn_d_val_syment)
			else
				div g_e_p# elf32_dyn_d_val_syment
			endelse
			#adding at current names reg the content lenghting comsize
			SetCall errormsg elfaddstrszsym(ac_store_content,ac_store_size,acsym_value,acsym_size,(STT_NOTYPE),(STB_GLOBAL),acsym_shndx,ptrtable)
		endif
	endif
endelse
