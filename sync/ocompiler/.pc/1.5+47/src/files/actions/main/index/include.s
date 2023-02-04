

Data quotsz#1
Data escapes#1
Data pquotsz^quotsz
Data pescapes^escapes

SetCall errormsg quotinmem(pcontent,pcomsize,pquotsz,pescapes)
if errormsg==noerr
	if include_sec==(TRUE)
		ss include_test
		set include_test content
		add include_test quotsz
		add include_test escapes
		inc include_test
		setcall include_test mem_spaces(include_test,pointer)
		if include_test!=pointer
			if include_test#==(asciidoublequote)
				sub include_test content
				sub comsize include_test
				add content include_test
				SetCall errormsg quotinmem(pcontent,pcomsize,pquotsz,pescapes)
			endif
		endif
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
