

Data quotsz#1
Data escapes#1
Data pquotsz^quotsz
Data pescapes^escapes

SetCall errormsg quotinmem(pcontent,pcomsize,pquotsz,pescapes)
if errormsg==noerr
	if include_sec==(TRUE)
		add quotsz escapes
		call advancecursors(pcontent,pcomsize,quotsz)
		Call stepcursors(pcontent,pcomsize)
		call spaces(pcontent,pcomsize)
		SetCall errormsg quotinmem(pcontent,pcomsize,pquotsz,pescapes)
	endif
	if errormsg==noerr
		SetCall errormsg addtosecstresc(pcontent,pcomsize,quotsz,escapes,ptrmiscbag,zero)
		If errormsg==noerr
			Call stepcursors(pcontent,pcomsize)
			Set includebool one
			if include_sec==(FALSE)
				SetCall errormsg include_sec_skip(pcontent,pcomsize)
			endif
		EndIf
	endif
EndIf
