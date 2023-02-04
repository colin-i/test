

function reloc64_init()
	sd a%p_pref_reloc_64
	sd b%p_elf64_r_info_type
	if a#==(TRUE)
		set b# (R_X86_64_64)
	endif
	#blank is at inits
endfunction

function reloc64_offset(sd offset)
	sd a%p_elf64_r_info_type
	if a#==(R_X86_64_64)
		add offset 1
	endif
	return offset
endfunction
#er
function reloc64_ante()
	sd a%p_elf64_r_info_type
	if a#==(R_X86_64_64)
		sd err
		call rex_w(#err)
		return err
	endif
	return (noerror)
endfunction
#er
function reloc64_post_base(sd struct)
	sd a%p_elf64_r_info_type
	if a#==(R_X86_64_64)
		sd err
		sd null=0
		SetCall err addtosec(#null,(dwsz),struct)
		return err
	endif
	return (noerror)
endfunction
#er
function reloc64_post()
	sd ptrcodesec%ptrcodesec
	sd err
	setcall err reloc64_post_base(ptrcodesec)
	return err
endfunction
