

Data ifinscribe=ifinscribe
Data ptrifinscribe^ifinscribe

Data nocond=nocondnumber

If subtype==(cIF)
	SetCall errormsg addtosec(ptrifinscribe,dwordsize,ptrconditionsloops)
	If errormsg==noerr
		SetCall errormsg condbegin(pcontent,pcomsize,(ifnumber))
	EndIf
ElseIf subtype==(cELSE)
	SetCall errormsg closeifopenelse()
ElseIf subtype==(cWHILE)
	SetCall errormsg coderegtocondloop()
	If errormsg==noerr
		SetCall errormsg condbegin(pcontent,pcomsize,(whilenumber))
	EndIf
ElseIf subtype==(cELSEIF)
	SetCall errormsg closeifopenelse()
	If errormsg==noerr
		SetCall errormsg condbegin(pcontent,pcomsize,(ifnumber))
	EndIf
ElseIf subtype==(cENDIF)
	SetCall errormsg conditionscondend((ifnumber),nocond)
ElseIf subtype==(cENDELSE)
	SetCall errormsg conditionscondend((elsenumber),nocond)
ElseIf subtype==(cENDWHILE)
	SetCall errormsg condend((whilenumber))
Else
	SetCall errormsg conditionscondend((ifnumber),(elsenumber))
EndElse