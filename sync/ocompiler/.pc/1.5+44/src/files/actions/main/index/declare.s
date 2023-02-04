
if subtype==(cVDATA)
	if p_is_for_64_value#==(TRUE)
		SetCall errormsg dataassign(pcontent,pcomsize,(integersnumber),(datapointbit))
	else
		SetCall errormsg dataassign(pcontent,pcomsize,(integersnumber),0)
	endelse
elseif subtype==(cVSTR)
	if p_is_for_64_value#==(TRUE)
		SetCall errormsg dataassign(pcontent,pcomsize,(stringsnumber),(datapointbit))
	else
		SetCall errormsg dataassign(pcontent,pcomsize,(stringsnumber),0)
	endelse
elseif subtype==(cVALUE)
	if p_is_for_64_value#==(TRUE)
		SetCall errormsg dataassign(pcontent,pcomsize,(integersnumber),(valueslongmask))
	else
		SetCall errormsg dataassign(pcontent,pcomsize,(integersnumber),0)
	endelse
else
	sd declare_typenumber
	setcall declare_typenumber commandSubtypeDeclare_to_typenumber(subtype)
	sd is_stack
	sd typenumber
	setcall typenumber stackfilter(declare_typenumber,#is_stack)
	if is_stack==true
		#must be at the start
		call entryscope_verify_code()
	endif
	#	SetCall errormsg dataassign_ex(pcontent,pcomsize,typenumber,0,(TRUE))
	#else
		SetCall errormsg dataassign_ex(pcontent,pcomsize,typenumber,0,is_stack)
	#endelse
endelse
