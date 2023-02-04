

#set(0)/get(1) index
function ramp_index(data mode,data container)
	data reg#1
	data set=0
	if mode==set
		data ptrreg^reg
		const ramppointer^reg
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
function growramp(data value)
	data ptrramp#1
	setcall ptrramp getptrramp()
	sd ret;set ret ptrramp#
	subcall ptrramp# stack64_add(value)
	return ret
endfunction
#ind(before)
function addramp()
	data dword=4
	data ramp#1
	setcall ramp growramp(dword)
	return ramp
endfunction
#ind
function getramp_ebxrel()
	data ptrramp#1
	setcall ptrramp getptrramp()
	data ramp#1
	setcall ramp neg(ptrramp#)
	return ramp
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
	const scope4_start=!;chars scope4={0x81,0xc3};const scope4_sz=!-scope4_start
	data scopestack=0
	
	setcall err addtosec(#scope1,(scope1_sz),container);if err!=(noerror);return err;endif
	setcall err rex_w_if64();if err!=(noerror);return err;endif
	setcall err addtosec(#scope2,(scope2_sz),container);if err!=(noerror);return err;endif
	setcall err rex_w_if64();if err!=(noerror);return err;endif
	setcall err addtosec(#scope3,(scope3_sz),container);if err!=(noerror);return err;endif
	setcall err rex_w_if64();if err!=(noerror);return err;endif
	setcall err addtosec(#scope4,(scope4_sz),container);if err!=(noerror);return err;endif
	setcall err addtosec(#scopestack,(dwsz),container);if err!=(noerror);return err;endif
	#
	data set=0;call ramp_index(set,container)
	return (noerror)
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
function addtocodeforstack(data value,data rightstackpointer)
	data eax=eaxregnumber

	data null=0
	chars movtostack#1
	chars *modrm=disp32*tomod|ebxregnumber
	data rampindex#1
	data rampvalue#1

	data stack^movtostack
	data size#1
	data ptrcodesec%ptrcodesec
	data noerr=noerror
	sd err

	if rightstackpointer==null
		chars movimm=0xc7
		set movtostack movimm
		data sizeimm=2+4+4
		set size sizeimm
	else
		setcall err writetake(eax,rightstackpointer)
		if err!=noerr
			return err
		endif
		chars movreg=moveatmemtheproc
		set movtostack movreg
		data sizereg=2+4
		set size sizereg
	endelse

	setcall rampindex addramp()
	setcall rampindex neg(rampindex)
	set rampvalue value
	
	setcall err addtosec(stack,size,ptrcodesec)
	return err
endfunction


