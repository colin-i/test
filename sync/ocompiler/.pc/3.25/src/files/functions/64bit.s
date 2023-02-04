

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

function function_call_64m(sd hex_1,sd hex_2,sd hex_3,sd hex_4,ss args_push,sd hex_x)
	sd err
	Data code%ptrcodesec
	sd nr_of_args;setcall nr_of_args nr_of_args_64need()
	if nr_of_args>0
		SetCall err addtosec(hex_1,4,code);If err!=(noerror);Return err;EndIf
		if nr_of_args>1
			SetCall err addtosec(hex_2,5,code);If err!=(noerror);Return err;EndIf
			if nr_of_args>2
				SetCall err addtosec(hex_3,5,code);If err!=(noerror);Return err;EndIf
				if nr_of_args>3
					SetCall err addtosec(hex_4,5,code);If err!=(noerror);Return err;EndIf
				endif
			endif
		endif
	endif
	#shadow space
	set args_push# 4
	if nr_of_args<args_push#;set args_push# nr_of_args;endif
	sub args_push# 4;mult args_push# -1
	if args_push#!=0
		mult args_push# (qwsz)
		call rex_w(#err);If err!=(noerror);Return err;EndIf
		SetCall err addtosec(hex_x,3,code);If err!=(noerror);Return err;EndIf
	endif
	#stack align,more to see when the offset was taken
	sd stack_align_p;setcall stack_align_p stack_align_off_p_get()
	ss code_pointer;call getcont(code,#code_pointer)
	add code_pointer stack_align_p#
	sd against_one=4;if nr_of_args>4;set against_one nr_of_args;endif;and against_one 1
	#Jump short if not carry
	if against_one==0;set code_pointer# (0x73)
	#Jump short if carry
	else;set code_pointer# (0x72);endelse
	return (noerror)
endfunction
function function_call_64(sd is_callex)
	sd err
	Data code%ptrcodesec
	#
	#rcx,[rsp+0]
	chars hex_1={REX_Operand_64,0x8B,0x0C,0x24}
	#rdx,rsp+8
	chars hex_2={REX_Operand_64,0x8B,0x54,0x24,0x08}
	#r8,rsp+16
	chars hex_3={REX_R8_15,0x8B,0x44,0x24,0x10}
	#r9,rsp+24
	chars hex_4={REX_R8_15,0x8B,0x4C,0x24,0x18}
	#sub esp,x;default 4 args stack space convention
	chars hex_x={0x83,0xEC};chars args_push#1
		
	if is_callex==(FALSE)
		setcall err function_call_64m(#hex_1,#hex_2,#hex_3,#hex_4,#args_push,#hex_x)
		Return err
	endif
	#
	#cmp eax,imm32
	chars cmp_je=0x3d;data cmp_imm32#1
	#jump
	chars callex_jump#1;chars j_off#1
	##
	#mov eax,ebx
	chars find_args={0x8b,0xc3}
	#sub eax,esp
	chars *={0x2b,0xc4}
	#edx=0;ecx=QWORD;div edx:eax,ecx
	chars *=0xba;data *=0;chars *=0xb9;data *=qwsz;chars *={0xF7,0xF1}
	#
	SetCall err addtosec(#find_args,0x10,code);If err!=(noerror);Return err;EndIf
	#jump if equal
	set callex_jump (0x74)
	#
	set cmp_imm32 0
	set j_off (4+7+5+7+5+7+5)
	SetCall err addtosec(#cmp_je,7,code);If err!=(noerror);Return err;EndIf
		SetCall err addtosec(#hex_1,4,code);If err!=(noerror);Return err;EndIf
	#
		set cmp_imm32 1
		set j_off (5+7+5+7+5)
		SetCall err addtosec(#cmp_je,7,code);If err!=(noerror);Return err;EndIf
			SetCall err addtosec(#hex_2,5,code);If err!=(noerror);Return err;EndIf
	#
			set cmp_imm32 2
			set j_off (5+7+5)
			SetCall err addtosec(#cmp_je,7,code);If err!=(noerror);Return err;EndIf
				SetCall err addtosec(#hex_3,5,code);If err!=(noerror);Return err;EndIf
	#
				set cmp_imm32 3
				set j_off (5)
				SetCall err addtosec(#cmp_je,7,code);If err!=(noerror);Return err;EndIf
					SetCall err addtosec(#hex_4,5,code);If err!=(noerror);Return err;EndIf
	#jump if above
	set callex_jump (0x77)
	set args_push (qwsz)
	#4*REX.W
	data jump64#1;set jump64 4
	#
	set cmp_imm32 3
	set j_off (3+7+3+7+3+7+3);add j_off jump64
	SetCall err addtosec(#cmp_je,7,code);If err!=(noerror);Return err;EndIf
		subcall jump64 rex_w(#err);If err!=(noerror);Return err;EndIf
		SetCall err addtosec(#hex_x,3,code);If err!=(noerror);Return err;EndIf
		set cmp_imm32 2
		set j_off (3+7+3+7+3);add j_off jump64
		SetCall err addtosec(#cmp_je,7,code);If err!=(noerror);Return err;EndIf
			subcall jump64 rex_w(#err);If err!=(noerror);Return err;EndIf
			SetCall err addtosec(#hex_x,3,code);If err!=(noerror);Return err;EndIf
			set cmp_imm32 1
			set j_off (3+7+3);add j_off jump64
			SetCall err addtosec(#cmp_je,7,code);If err!=(noerror);Return err;EndIf
				subcall jump64 rex_w(#err);If err!=(noerror);Return err;EndIf
				SetCall err addtosec(#hex_x,3,code);If err!=(noerror);Return err;EndIf
				set cmp_imm32 0
				set j_off (3);add j_off jump64
				SetCall err addtosec(#cmp_je,7,code);If err!=(noerror);Return err;EndIf
					call rex_w(#err);If err!=(noerror);Return err;EndIf
					SetCall err addtosec(#hex_x,3,code);If err!=(noerror);Return err;EndIf
	return (noerror)
endfunction

function function_start_64()
	Data code%ptrcodesec
	sd err
	const functionx_start=!
	#mov [rsp+8h],rcx
	chars functionx_code={REX_Operand_64,moveatmemtheproc,0x4C,0x24,0x08}
	#mov [rsp+10h],rdx
	chars *={REX_Operand_64,moveatmemtheproc,0x54,0x24,0x10}
	#mov [rsp+18h],r8
	chars *={REX_R8_15,moveatmemtheproc,0x44,0x24,0x18}
	#mov [rsp+20h],r9
	chars *={REX_R8_15,moveatmemtheproc,0x4C,0x24,0x20}
	SetCall err addtosec(#functionx_code,(!-functionx_start),code)
endfunction
