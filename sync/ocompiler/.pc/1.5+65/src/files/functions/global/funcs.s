


function localResolve(sd unrLc,sd unrLcReg)
	data funcs#1
	data ptr_funcs^funcs
	data fns%ptrfunctions

	sd struct
	sd offset

	while unrLcReg!=0
		set struct unrLc#
		sd cont
		sd ptr_cont^cont
		call getcont(struct,ptr_cont)

		add unrLc 4

		set offset unrLc#

		add cont offset

		call getcont(fns,ptr_funcs)
		add funcs cont#
		sd value
		set value funcs#

		add unrLc 4

		if unrLc#==1
			add offset 4
			sub offset value
			setcall offset neg(offset)
		else
			set offset value
		endelse

		set cont# offset

		add unrLc 4
		sub unrLcReg 12
	endwhile
endfunction

function get_fn_pos(sd varfnpointer,sd ptr_out)
	Data ptrfunctions%ptrfunctions
	#store the functions reg
	sd fns_cont
	sd ptr_fns_cont^fns_cont
	call getcont(ptrfunctions,ptr_fns_cont)
	sub varfnpointer fns_cont
	set ptr_out# varfnpointer
endfunction

#e
function unresLc(sd addition,sd structure,sd direct)
	data struct#1
	data offset#1
	data isdirect#1

	sd ptradd^struct
	sd ptroff^offset

	Call getcontReg(structure,ptroff)

	add offset addition

	set struct structure
	set isdirect direct

	data unresLocal%ptrunresLocal
	sd err
	SetCall err addtosec(ptradd,12,unresLocal)
	return err
endfunction

#e
function unresolvedLocal(sd addition,sd structure,sd currentfnpointer,sd ptr_out)
	sd err
	setcall err unresLc(addition,structure,1)
	If err!=(noerror)
		Return err
	EndIf

	call get_fn_pos(currentfnpointer,ptr_out)
	return (noerror)
endfunction

#e
function unresReloc(sd section)
	sd for_64
	sd err
	setcall for_64 is_for_64()
	if for_64==(TRUE)
		setcall err unresLc((-qwsz),section,0)
	else
		setcall err unresLc((-dwsz),section,0)
	endelse
	return err
endfunction
