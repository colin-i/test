

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
const reloc64_add=dwsz
function reloc64_mid()
	sd a%p_elf64_r_info_type
	if a#==(R_X86_64_64)
		return (reloc64_add)
	endif
	return 0
endfunction
#er
function reloc64_post_base_extension(sd struct,sd fill)
	sd a%p_elf64_r_info_type
	if a#==(R_X86_64_64)
		sd err
		#extension is for example -1 at sd=const, mostly are 0
		SetCall err addtosec(#fill,(reloc64_add),struct)
		return err
	endif
	return (noerror)
endfunction
#er
function reloc64_post_base(sd struct)
	sd err
	setcall err reloc64_post_base_extension(struct,(NULL))
	return err
endfunction
#er
function reloc64_post()
	sd ptrcodesec%ptrcodesec
	sd err
	setcall err reloc64_post_base(ptrcodesec)
	return err
endfunction
