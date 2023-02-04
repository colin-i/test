
#err
function declare(sv pcontent,sd pcomsize,sd bool_64,sd subtype,sd prelocbool)
	Data valsize#1
	Chars sign#1
	#below also at virtual at get_reserve (with mask there)
	sd is_stack
	sd typenumber
	sd mask

	if subtype==(cVDATA)
		set is_stack (FALSE);set typenumber (integersnumber)
		if bool_64==(TRUE);set mask (datapointbit)
		else;set mask 0;endelse
	elseif subtype==(cVSTR)
		set is_stack (FALSE);set typenumber (stringsnumber)
		if bool_64==(TRUE);set mask (datapointbit)
		else;set mask 0;endelse
	elseif subtype==(cVALUE)
		set is_stack (FALSE);set typenumber (integersnumber)
		if bool_64==(TRUE);set mask (valueslongmask)
		else;set mask 0;endelse
	else
		sd declare_typenumber
		setcall declare_typenumber commandSubtypeDeclare_to_typenumber(subtype)
		setcall typenumber stackfilter(declare_typenumber,#is_stack)
		if is_stack==(TRUE)
			#must be at the start
			call entryscope_verify_code()
		endif
		set mask 0
	endelse

	sd err
	setcall err getsign(pcontent#,pcomsize#,#sign,#valsize,typenumber,is_stack,prelocbool)
	if err==(noerror)
		SetCall err dataassign(pcontent,pcomsize,sign,valsize,typenumber,is_stack,mask)
	endif
	return err
endfunction
