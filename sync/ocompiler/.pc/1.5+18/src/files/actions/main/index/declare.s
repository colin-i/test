
if subtype==(cVDATA)
	if p_is_for_64_resp#==(TRUE)
		SetCall errormsg dataassign(pcontent,pcomsize,(integersnumber),(datapointbit))
	else
		SetCall errormsg dataassign(pcontent,pcomsize,(integersnumber),0)
	endelse
elseif subtype==(cVSTR)
	if p_is_for_64_resp#==(TRUE)
		SetCall errormsg dataassign(pcontent,pcomsize,(stringsnumber),(datapointbit))
	else
		SetCall errormsg dataassign(pcontent,pcomsize,(stringsnumber),0)
	endelse
elseif subtype==(cVALUE)
	if p_is_for_64_resp#==(TRUE)
		SetCall errormsg dataassign(pcontent,pcomsize,(integersnumber),(valueslongmask))
	else
		SetCall errormsg dataassign(pcontent,pcomsize,(integersnumber),0)
	endelse
else
	sd declare_typenumber
	setcall declare_typenumber commandSubtypeDeclare_to_typenumber(subtype)
	SetCall errormsg dataassign(pcontent,pcomsize,declare_typenumber,0)
endelse
