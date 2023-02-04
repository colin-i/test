

#p_bits
function p_is_for_64()
	data bool#1
	return #bool
endfunction
#bool
function is_for_64()
	sd p;setcall p p_is_for_64();return p#
endfunction
#p_bits
function p_neg_is_for_64()
	data bool#1
	return #bool
endfunction

#get
function is_for_64_is_impX_or_fnX_p_get();data b#1;return #b;endfunction
#get
function is_for_64_is_impX_or_fnX_get();sd p_b;setcall p_b is_for_64_is_impX_or_fnX_p_get();return p_b#;endfunction
function is_for_64_is_impX_or_fnX_set(sd ptrdata)
	sd p_b
	setcall p_b is_for_64_is_impX_or_fnX_p_get()
	#importX and functionX already has a test with is_for_64
	add ptrdata (maskoffset)
	sd val;set val ptrdata#;and val (x86_64bit)
	if val!=(x86_64bit);set p_b# (FALSE);return (void);endif
	set p_b# (TRUE)
endfunction

#get
function nr_of_args_64need_p_get();data n#1;return #n;endfunction
#er
function nr_of_args_64need_set()
	sd p_b;setcall p_b is_for_64_is_impX_or_fnX_p_get()
	if p_b#==(TRUE)
		sd p;setcall p nr_of_args_64need_p_get();set p# 0
		#Stack aligned on 16 bytes. Later set, depending on the number of arguments, jumpCarry or jumpNotCarry
		sd err
		data code%ptrcodesec
		#bt rsp,3 (offset 3)
		chars hex_x={REX_Operand_64,0x0F,0xBA,bt_reg_imm8|espregnumber,3}
		SetCall err addtosec(#hex_x,5,code);If err!=(noerror);Return err;EndIf
		#
		sd stack_align_p;setcall stack_align_p stack_align_off_p_get()
		call getcontReg(code,stack_align_p)
		#j(c|nc);sub rsp,8
		chars jump#1;chars *=4;chars *={REX_Operand_64,0x83,0xEC,8}
		SetCall err addtosec(#jump,6,code);If err!=(noerror);Return err;EndIf
	endif
	Return (noerror)
endfunction
function nr_of_args_64need_count()
	sd p_b;setcall p_b is_for_64_is_impX_or_fnX_p_get()
	if p_b#==(TRUE)
		sd p;setcall p nr_of_args_64need_p_get();inc p#
	endif
endfunction
#nr_of_args
function nr_of_args_64need()
	sd n;setcall n nr_of_args_64need_p_get();return n#
endfunction
#p
function stack_align_off_p_get()
	data o#1;return #o
endfunction



##REX_W
#size of prefix(=1)
function rex_w(sd p_err)
	Data code%ptrcodesec
	chars r=REX_Operand_64;data sz=1
	SetCall p_err# addtosec(#r,sz,code)
	return sz
endfunction
#er
function rex_w_if64()
	sd b;setcall b is_for_64()
	if b==(FALSE)
		return (noerror)
	endif
	sd err
	call rex_w(#err)
	return err
endfunction

function stack64_op_set()
	sd b;setcall b is_for_64()
	if b==(TRUE);call stack64_op_set_get((TRUE),(TRUE));endif
endfunction
#(false)get
function stack64_op_set_get(sd b,sd val)
	data x#1
	if b==(TRUE);set x val
	else;return x
	endelse
endfunction
#err
function stack64_op(sd takeindex,sd p_mod)
	sd b;setcall b stack64_op_set_get((FALSE))
	if b==(FALSE);return (noerror);endif
	#reset
	call stack64_op_set_get((TRUE),(FALSE))
	#return if outside mod=3
	if p_mod#==(RegReg);return (noerror);endif
	#set outside mod=3
	set p_mod# (RegReg)
	#mov reg,[reg]
	chars x=moveatprocthemem;chars y#1
	setcall y formmodrm((mod_0),takeindex,takeindex)
	sd err;data code%ptrcodesec
	setcall err addtosec(#x,2,code)
	return err
endfunction

function stack64_add(sd val)
	sd b;setcall b is_for_64()
	if b==(TRUE)
		mult val 2
	endif
	return val
endfunction

#setx

function val64_phase_0()
	sd p;setcall p val64_p_get();set p# 0
endfunction
function val64_phase_1()
	sd b;setcall b is_for_64()
	if b==(TRUE)
		sd p;setcall p val64_p_get();set p# 1
	endif
endfunction
function val64_phase_2()
	sd p;setcall p val64_p_get()
	if p#==1;set p# 2;endif
endfunction
#er
function val64_phase_3()
	sd p;setcall p val64_p_get()
	if p#==2
		sd er;call rex_w(#er);if er!=(noerror);return er;endif
		set p# 0
	endif
	return (noerror)
endfunction
function val64_p_get()
	data x#1;return #x
endfunction