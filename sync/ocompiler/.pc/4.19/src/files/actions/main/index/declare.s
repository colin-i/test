
if subtype==(cVDATA)
	SetCall errormsg dataassign(pcontent,pcomsize,(integersnumber),(datapointbit))
elseif subtype==(cVSTR)
	SetCall errormsg dataassign(pcontent,pcomsize,(stringsnumber),(datapointbit))
elseif subtype==(cVALUE)
	SetCall errormsg dataassign(pcontent,pcomsize,(integersnumber),(datapointbit|pointbit))
else
	sd declare_typenumber
	setcall declare_typenumber commandSubtypeDeclare_to_typenumber(subtype)
	SetCall errormsg dataassign(pcontent,pcomsize,declare_typenumber,0)
endelse
