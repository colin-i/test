

Data quotsz=0
Data escapes=0
Data pquotsz^quotsz
Data pescapes^escapes

SetCall errormsg quotinmem(pcontent,pcomsize,pquotsz,pescapes)
if errormsg==noerr
	SetCall errormsg addtosecstresc(pcontent,pcomsize,quotsz,escapes,ptrmiscbag,zero)
	If errormsg==noerr
		Call stepcursors(pcontent,pcomsize)
		Set includebool one
	EndIf
EndIf

