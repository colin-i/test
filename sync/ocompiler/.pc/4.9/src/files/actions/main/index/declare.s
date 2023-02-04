
if subtype==(cVDATA)
	SetCall errormsg dataassign(pcontent,pcomsize,(integersnumber),(TRUE))
else
	sd declare_typenumber
	setcall declare_typenumber commandSubtypeDeclare_to_typenumber(subtype)
	SetCall errormsg dataassign(pcontent,pcomsize,declare_typenumber,(FALSE))
endelse
