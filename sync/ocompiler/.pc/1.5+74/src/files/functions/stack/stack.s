

#set(0)/get(1) index
function ramp_index(data mode,data container)
	data reg#1
	data set=0
	if mode==set
		data ptrreg^reg
		#const ramppointer^reg
		call getcontReg(container,ptrreg)
		data dword=4
		sub reg dword
	else
		return reg
	endelse
endfunction


#typenumber
function stackfilter(data nr,data ptrstack)
	data totalmemvariables=totalmemvariables
	data numberofvars=numberofvars
	data false=0
	data true=1
	set ptrstack# false
	if nr>=totalmemvariables
		if nr<numberofvars
			sub nr totalmemvariables
			set ptrstack# true
		endif
	endif
	return nr
endfunction


#p
function getptrramp()
	data code#1
	data ptrcode^code
	data ptrcodesec%ptrcodesec
	call getcont(ptrcodesec,ptrcode)
	data get=1
	addcall code ramp_index(get)
	return code
endfunction
#ind(before)
function growramp(sd value,sv perr)
	vdata ptrramp#1
	setcall ptrramp getptrramp()
	sd ret;set ret ptrramp#
	setcall perr# maxsectioncheck(value,ptrramp)
	return ret
endfunction
#ind(before)
function addramp(sv perr)
	sd index
	setcall index stack64_enlarge((dwsz))
	data ramp#1
	setcall ramp growramp(index,perr)
	return ramp
endfunction
#ind
function getramp_ebxrel()
	data ptrramp#1
	setcall ptrramp getptrramp()
	return ptrramp#
endfunction

#er
function entryscope()
	data container%ptrcodesec
	sd err
	#push ebx,push ebp
	const scope1_start=!;chars scope1={0x53,0x55};const scope1_sz=!-scope1_start
	const stackinitpush=2*dwsz
	#mov e(r)bp e(r)sp
	const scope2_start=!;chars scope2={moveatregthemodrm,0xec};const scope2_sz=!-scope2_start
	#mov e(r)bx e(r)sp
	const scope3_start=!;chars scope3={moveatregthemodrm,0xdc};const scope3_sz=!-scope3_start
	#sub e(r)bx dword
	const scope4_start=!;chars scope4={0x81,0xeb}
	data *scopestack=0;const scope4_sz=!-scope4_start

	setcall err addtosec(#scope1,(scope1_sz),container);if err!=(noerror);return err;endif
	setcall err rex_w_if64();if err!=(noerror);return err;endif
	setcall err addtosec(#scope2,(scope2_sz),container);if err!=(noerror);return err;endif
	setcall err rex_w_if64();if err!=(noerror);return err;endif
	setcall err addtosec(#scope3,(scope3_sz),container);if err!=(noerror);return err;endif
	setcall err rex_w_if64();if err!=(noerror);return err;endif
	setcall err addtosec(#scope4,(scope4_sz),container);if err!=(noerror);return err;endif
	if err==(noerror)
		data set=0;call ramp_index(set,container)
		setcall err align_entryscope()
	endif
	return err
endfunction

#
function entryscope_verify_code()
	data ptrfnavailable%ptrfnavailable
	data one=1
	if ptrfnavailable#==one
		data ptrinnerfunction%globalinnerfunction
		if ptrinnerfunction#!=one
			data two=2
			set ptrfnavailable# two
			call entryscope()
		endif
	endif
endfunction


#er
function addtocode_decstack(sd for_64)
	chars movtostack=moveatmemtheproc
	chars *modrm=disp32mod|ebxregnumber
	data rampindex#1

	data stack^movtostack
	data size=2+4
	data ptrcodesec%ptrcodesec

	sd err
	if for_64==(TRUE)
		call rex_w(#err);if err!=(noerror);return err;endif
	endif

	setcall rampindex addramp(#err)
	#is with sub now     neg rampindex
	if err==(noerror)
		setcall err addtosec(stack,size,ptrcodesec)
	endif
	return err
endfunction
#er
function addtocodeforstack(sd rightstackpointer,sd for_64)
	data noerr=noerror

	sd err
	setcall err writetake((eaxregnumber),rightstackpointer)
	if err!=noerr
		return err
	endif

	setcall err addtocode_decstack(for_64)
	return err
endfunction
#er
function addtocodefordata(sd value,sd for_64,sd ext)
	chars code=ateaximm
	data val#1

	sd err
	setcall err reloc64_ante();If err!=(noerror);Return err;EndIf
	data ptrcodesec%ptrcodesec
	set val value
	setcall err addtosec(#code,5,ptrcodesec);If err!=(noerror);Return err;EndIf
	setcall err reloc64_post_base_extension(ptrcodesec,ext);If err!=(noerror);Return err;EndIf

	setcall err addtocode_decstack(for_64)
	return err
endfunction
