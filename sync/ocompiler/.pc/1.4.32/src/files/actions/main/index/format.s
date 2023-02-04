

Data formatresponse#1

#exe format
Chars exeformat="EXE"
Str ptrexeformat^exeformat
SetCall formatresponse stratmemspc(pcontent,pcomsize,ptrexeformat,false)

#elf format
If formatresponse==false
	Chars elfformat="ELF"
	Str ptrelfformat^elfformat
	SetCall formatresponse stratmemspc(pcontent,pcomsize,ptrelfformat,false)
	If formatresponse==true
		Set fileformat elf_unix
		Chars elfobjformat="OBJ"
		Str ptrelfobjformat^elfobjformat
		Data elfobjformresp#1

		sd p_is_for_64_resp;setcall p_is_for_64_resp p_is_for_64()

		SetCall elfobjformresp stringsatmemspc(pcontent,pcomsize,ptrelfobjformat,false,"64",p_is_for_64_resp)
		If elfobjformresp==true
			if p_is_for_64_resp#==(TRUE)
				set convention_64 convention_64#
				if convention_64==(ignore_convention_input)
					set p_is_for_64_resp# (FALSE)
				else
					call reloc64_init()
					if convention_64==(direct_convention_input)
						call convdata((convdata_init),(variable_convention))
					#cross_convention_input
					elseif (variable_convention)==(ms_convention)
						call convdata((convdata_init),(lin_convention))
					else
						call convdata((convdata_init),(ms_convention))
					endelse
				endelse
			endif
			Set object true
			SetCall errormsg elfaddstrsym(ptrnull,null,null,null,null,null,ptrtable)
			If errormsg==noerr
				Chars elfdata=".data"
				Str ptrelfdata^elfdata
				Data dataind=dataind
				Set datastrtab namesReg
				SetCall errormsg elfaddstrsym(ptrelfdata,null,null,STT_SECTION,(STB_LOCAL),dataind,ptrtable)
				If errormsg==noerr
					Chars elftext=".text"
					Str ptrelftext^elftext
					Data codeind=codeind
					Set codestrtab namesReg
					SetCall errormsg elfaddstrsym(ptrelftext,null,null,STT_SECTION,(STB_LOCAL),codeind,ptrtable)
			const totallocalsymsaddedatstart=3
				EndIf
			EndIf
			Set imagebaseoffset null
			Set startofdata null
		Else
			Data elf_imagebase=elf_imagebase
			Set imagebaseoffset elf_imagebase

			Set startofdata elf_startofdata
		EndElse
	EndIf
EndIf

If errormsg==noerr
	If formatresponse==false
		Chars unrecform="Unrecognized file format."
		Str ptrunrecform^unrecform
		Set errormsg ptrunrecform
	ElseIf formatdefined==2
		Chars nomoreformats="The FORMAT command can be defined at the start and only once."
		Str ptrnomoreformats^nomoreformats
		Set errormsg ptrnomoreformats
	EndElseIf
EndIf
