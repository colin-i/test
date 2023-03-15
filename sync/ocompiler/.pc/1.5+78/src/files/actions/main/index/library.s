
Data libquotsz#1
Data libescapes#1
Data ptrlibquotsz^libquotsz
Data ptrlibescapes^libescapes

If fileformat==pe_exec
	If implibsstarted==true
		SetCall errormsg closelib()
	EndIf
	If errormsg==noerr
		SetCall errormsg openlib()
	EndIf
Else
	If object==false
		#Name of needed library offset
		Data DT_NEEDED=1
		Data d_un#1
		Data ptr_d_tag^DT_NEEDED
		Set d_un namesReg
		SetCall errormsg addtosec(ptr_d_tag,sizeofElf32_Dyn,ptrtable)
	Else
		Chars libatobj="LIBRARY statement is not used at object format."
		Str ptrlibatobj^libatobj
		Set errormsg ptrlibatobj
	EndElse
EndElse

If errormsg==noerr
	SetCall errormsg quotinmem(pcontent,pcomsize,ptrlibquotsz,ptrlibescapes)
	If errormsg==noerr
		SetCall errormsg addtosecstresc(pcontent,pcomsize,libquotsz,libescapes,ptrnames,true)
		If errormsg==noerr
			Call stepcursors(pcontent,pcomsize)
			Set implibsstarted true
		EndIf
		#endif
	EndIf
EndIf


