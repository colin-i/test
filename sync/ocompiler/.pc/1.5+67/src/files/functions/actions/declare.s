
#err
function declare(sv pcontent,sd pcomsize,sd bool_64,sd subtype,sd parses)
	Data valsize#1
	Chars sign#1
	#below also at virtual at get_reserve (with mask there)
	sd is_stack
	sd typenumber
	sd mask

	sd unitsize

	sd declare_typenumber
	sd is_expand
	setcall declare_typenumber commandSubtypeDeclare_to_typenumber(subtype,#is_expand)

	if is_expand==(TRUE)
		if parses==(pass_init)
			call advancecursors(pcontent,pcomsize,pcomsize#)
			return (noerror)
		endif
	endif

	if declare_typenumber==(vintegersnumber)
		set is_stack (FALSE);set typenumber (integersnumber)
		if bool_64==(TRUE);set mask (datapointbit)
			if parses==(pass_init)
				set unitsize (qwsz)
			endif
		else;set mask 0
			if parses==(pass_init)
				set unitsize (dwsz)
			endif
		endelse
	elseif declare_typenumber==(vstringsnumber)
		set is_stack (FALSE);set typenumber (stringsnumber)
		if bool_64==(TRUE);set mask (datapointbit)
			if parses==(pass_init)
				set unitsize (qwsz)
			endif
		else;set mask 0
			if parses==(pass_init)
				set unitsize (dwsz)
			endif
		endelse
	elseif declare_typenumber==(valuesnumber)
		set is_stack (FALSE);set typenumber (integersnumber)
		if bool_64==(TRUE);set mask (valueslongmask)
			if parses==(pass_init)
				set unitsize (qwsz)
			endif
		else;set mask 0
			if parses==(pass_init)
				set unitsize (dwsz)
			endif
		endelse
	else
		setcall typenumber stackfilter(declare_typenumber,#is_stack)
		if parses==(pass_init)
			if is_stack==(TRUE)
				if typenumber==(stringsnumber)
					set unitsize 0
				else
					call advancecursors(pcontent,pcomsize,pcomsize#)
					return (noerror)
				endelse
			else
				if typenumber!=(charsnumber)
					if typenumber!=(constantsnumber)
						set unitsize (dwsz)
					endif
				else
					set unitsize (bsz)
				endelse
			endelse
		else
			if is_stack==(TRUE)
				#must be at the start
				call entryscope_verify_code()
			endif
		endelse
		set mask 0
	endelse

	sd err
	sd relocbool
	setcall err getsign(pcontent#,pcomsize#,#sign,#valsize,typenumber,is_stack,#relocbool)
	if err==(noerror)
		if parses==(pass_init)
			if typenumber==(constantsnumber)
				setcall err addtolog_withchar_ex_atunused(pcontent#,valsize,(log_declare))
				if err==(noerror)
					if sign==(pointersigndeclare)
						call advancecursors(pcontent,pcomsize,pcomsize#)
						return (noerror)
					endif
					setcall err dataassign(pcontent,pcomsize,sign,valsize,typenumber,(NULL),mask) #there are 2 more argument but are not used
				endif
			else
				if unitsize==0
				#ss?
					if sign!=(assignsign)
						call advancecursors(pcontent,pcomsize,pcomsize#)
						return (noerror)
					endif
					#ss =% ""/x/{}
				else
				#search for data%  with R_X86_64_64
					if relocbool==(TRUE)
						if mask==0
						#data str
						#strs are without ""
							vdata is_64_and_pref_is_rx866464%p_elf64_r_info_type
							if is_64_and_pref_is_rx866464#==(R_X86_64_64)
								set unitsize (qwsz)
							endif
						endif
					endif
				endelse
				setcall err dataassign(pcontent,pcomsize,sign,valsize,typenumber,#unitsize,mask,is_stack) #there is 1 more argument but is not used
				sd pdataReg%ptrdataReg
				add pdataReg# unitsize    #this is init by 0
			endelse
		else
			if typenumber==(constantsnumber)
				if sign!=(pointersigndeclare)
					call advancecursors(pcontent,pcomsize,pcomsize#)
					return (noerror)
				endif
			elseif is_expand==(TRUE)
				if sign!=(reserveascii)
					return "Virtual declarations can have only the reserve sign."
				endif
			endelseif
			SetCall err dataassign(pcontent,pcomsize,sign,valsize,typenumber,(NULL),mask,is_stack,relocbool,is_expand)
		endelse
	endif
	return err
endfunction
