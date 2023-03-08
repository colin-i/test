

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

function scope64_p()
	datax bool#1;return #bool
endfunction
function scope64_get()
	sd p;setcall p scope64_p();return p#
endfunction
function scope64_set(sd b)
	sd p;setcall p scope64_p();set p# b
endfunction

#get
function is_for_64_is_impX_or_fnX_p_get();data b#1;return #b;endfunction
#get
function is_for_64_is_impX_or_fnX_get();sd p_b;setcall p_b is_for_64_is_impX_or_fnX_p_get();return p_b#;endfunction
function is_for_64_is_impX_or_fnX_set(sd ptrdata,sd subtype)
	sd b
	setcall b is_for_64()
	#importX and functionX used to have a test with is_for_64 outside of this, but at log need to know the type
	if b==(TRUE)
		add ptrdata (maskoffset)
		sd val;set val ptrdata#;and val (x86_64bit)
		sd p_b
		if val==(x86_64bit)
			setcall p_b is_for_64_is_impX_or_fnX_p_get()
			set p_b# (TRUE)
		elseif subtype==(x_callx_flag)
			setcall p_b is_for_64_is_impX_or_fnX_p_get()
			set p_b# (TRUE)
		endelseif
	endif
	#is this required anymore? set p_b# (FALSE)
endfunction
function is_for_64_is_impX_or_fnX_set_force(sd subtype)
	sd b
	setcall b is_for_64()
	if b==(TRUE)
		if subtype==(x_callx_flag)
			sd p_b
			setcall p_b is_for_64_is_impX_or_fnX_p_get()
			set p_b# (TRUE)
		endif
	endif
endfunction

#get
function nr_of_args_64need_p_get();data n#1;return #n;endfunction
function nr_of_args_64need_count()
	sd p_b;setcall p_b is_for_64_is_impX_or_fnX_p_get()
	if p_b#==(TRUE)
		sd p;setcall p nr_of_args_64need_p_get();inc p#
	endif
endfunction

##REX_W
function rex_w(sd p_err)
	Data code%ptrcodesec
	chars r=REX_Operand_64
	SetCall p_err# addtosec(#r,1,code)
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
#b
function is_big(sd dataarg,sd sufix)
#called when lowbyte is false
	sd b;setcall b bigbits(dataarg)
	if b!=0
		setcall b pointbit(dataarg)
		if b==0
			if sufix==(TRUE)
				# sd# is not big
				return (FALSE)
			endif
		endif
		setcall b is_for_64()
		return b
	endif
	return (FALSE)
endfunction
#z
function bigbits(sd data)
	sd test
	setcall test stackbit(data)
	if test==0
		setcall test datapointbit(data)
	endif
	return test
endfunction

#function stack64_op_set()
#	sd b;setcall b is_for_64()
#	if b==(TRUE);call stack64_op_set_get((TRUE),(TRUE));endif
#endfunction
#(false)get
#function stack64_op_set_get(sd b,sd val)
#	data x#1
#	if b==(TRUE);set x val
#	else;return x
#	endelse
#endfunction
#err
#function stack64_op()
#	sd b;setcall b stack64_op_set_get((FALSE))
#	if b!=(FALSE)
#		#reset
#		call stack64_op_set_get((TRUE),(FALSE))
#		#at push 64 and call 64, without rex is ok
#		sd p;setcall p val64_p_get()
#		set p# (val64_no)
#	endif
#endfunction

function stack64_enlarge(sd val)
	sd b;setcall b is_for_64()
	if b==(TRUE)
		mult val 2
	endif
	return val
endfunction

#setx

function val64_init()
	sd p;setcall p val64_p_get();set p# (val64_no)
endfunction
function val64_p_get()
	data x#1;return #x
endfunction

function convdata(sd type,sd dest,sd fnargs)
	if type==(convdata_total)
		data nr_of_args#1
		return nr_of_args   #ms_convention or lin
	elseif type==(convdata_call)
		#rdi
		chars hex_1={REX_Operand_64,moveatprocthemem,ediregnumber*toregopcode|espregnumber,0x24,0}
		#rsi
		chars hex_2={REX_Operand_64,moveatprocthemem,esiregnumber*toregopcode|disp8mod|espregnumber,0x24,8}
		#rcx/rdx,rsp+
		chars hex_3={REX_Operand_64,moveatprocthemem};chars c3#1;chars *=0x24;chars c3o#1
		#rdx/rcx,rsp+
		chars hex_4={REX_Operand_64,moveatprocthemem};chars c4#1;chars *=0x24;chars c4o#1
		#r8,rsp+
		chars hex_5={REX_R8_15,moveatprocthemem,0x44,0x24};chars c5o#1
		#r9,rsp+
		chars hex_6={REX_R8_15,moveatprocthemem,0x4C,0x24};chars c6o#1
		if nr_of_args==(lin_convention)
			set dest# #hex_1
			incst dest;set dest# #hex_2
			incst dest
		endif
		set dest# #hex_3
		incst dest;set dest# #hex_4
		incst dest;set dest# #hex_5
		incst dest;set dest# #hex_6
		ret
	elseif type==(convdata_fn)
		const functionxlin_start=!
		#pop a
		chars functionxlin_code=0x58
		#sub esp,conv8
		chars *={REX_Operand_64,0x83,5*toregopcode|regregmod|espregnumber};chars *=lin_convention*qwsz
		#push a
		chars *=0x50
		const functionxlin_shadow=!-functionxlin_start

		chars *={REX_Operand_64,moveatmemtheproc,ediregnumber*toregopcode|disp8mod|espregnumber,0x24,8}
		const conv_fn_b1=!-functionxlin_start

		chars *={REX_Operand_64,moveatmemtheproc,esiregnumber*toregopcode|disp8mod|espregnumber,0x24,16}
		const functionx_start=!
		const conv_fn_b2=!-functionxlin_start

		#mov [rsp+(8h/18h)],rcx/rdx
		chars functionx_code={REX_Operand_64,moveatmemtheproc};chars f3#1;chars *=0x24;chars f3o#1
		const conv_fn_a1=!-functionx_start
		const conv_fn_b3=!-functionxlin_start

		#mov [rsp+(10h/20h)],rdx/rcx
		chars *={REX_Operand_64,moveatmemtheproc};chars f4#1;chars *=0x24;chars f4o#1
		const conv_fn_a2=!-functionx_start
		const conv_fn_b4=!-functionxlin_start

		#mov [rsp+(18h/28h)],r8
		chars *={REX_R8_15,moveatmemtheproc,0x44,0x24};chars f5o#1
		const conv_fn_a3=!-functionx_start
		const conv_fn_b5=!-functionxlin_start

		#mov [rsp+(20h/30h)],r9
		chars *={REX_R8_15,moveatmemtheproc,0x4C,0x24};chars f6o#1

		if nr_of_args==(ms_convention)
			if fnargs==0
				set dest# 0
			elseif fnargs==1
				set dest# (conv_fn_a1)
			elseif fnargs==2
				set dest# (conv_fn_a2)
			elseif fnargs==3
				set dest# (conv_fn_a3)
			else
				set dest# (!-functionx_start)
			endelse
			return #functionx_code
		endif
		if fnargs==0
			set dest# (functionxlin_shadow)
		elseif fnargs==1
			set dest# (conv_fn_b1)
		elseif fnargs==2
			set dest# (conv_fn_b2)
		elseif fnargs==3
			set dest# (conv_fn_b3)
		elseif fnargs==4
			set dest# (conv_fn_b4)
		elseif fnargs==5
			set dest# (conv_fn_b5)
		else
			set dest# (!-functionxlin_start)
		endelse
		return #functionxlin_code
	endelseif
	set nr_of_args dest
	if nr_of_args==(ms_convention)
		set c3 0x0C;set c3o 0
		set c4 0x54;set c4o 8
		set c5o 16;set c6o 24
		set f3 0x4C;set f3o 8
		set f4 0x54;set f4o 16
		set f5o 24;set f6o 32
	else
		set c3 0x54;set c3o 16
		set c4 0x4C;set c4o 24
		set c5o 32;set c6o 40
		set f3 0x54;set f3o 24
		set f4 0x4C;set f4o 32
		set f5o 40;set f6o 48
	endelse
endfunction

function function_call_64fm(sd nr_of_args,sd hex_n,sd conv,sd code)
	sd err
	if nr_of_args>0
		SetCall err addtosec(hex_n#,4,code);If err!=(noerror);Return err;EndIf
		if nr_of_args>1
			incst hex_n;SetCall err addtosec(hex_n#,5,code);If err!=(noerror);Return err;EndIf
			if nr_of_args>2
				incst hex_n;SetCall err addtosec(hex_n#,5,code);If err!=(noerror);Return err;EndIf
				if nr_of_args>3
					incst hex_n;SetCall err addtosec(hex_n#,5,code);If err!=(noerror);Return err;EndIf
					if conv==(lin_convention)
						if nr_of_args>4
							incst hex_n;SetCall err addtosec(hex_n#,5,code);If err!=(noerror);Return err;EndIf
							if nr_of_args>5
								incst hex_n;SetCall err addtosec(hex_n#,5,code);If err!=(noerror);Return err;EndIf
							endif
						endif
					endif
				endif
			endif
		endif
	endif
	return (noerror)
endfunction
function function_call_64f(sd hex_n,sd conv,sd code)
	sd err
	sd nr_of_args;setcall nr_of_args nr_of_args_64need_p_get()
	set nr_of_args nr_of_args#
	#
	setcall err function_call_64fm(nr_of_args,hex_n,conv,code)
	If err==(noerror)
		if conv==(ms_convention)
			if nr_of_args<conv
				#shadow space
				#sub esp,x;default 4 args stack space convention
				chars hex_w={REX_Operand_64,0x83,0xEC};chars argspush#1
				set argspush nr_of_args;sub argspush conv;mult argspush (-1*qwsz)
				SetCall err addtosec(#hex_w,4,code)
			endif
		elseif nr_of_args>0
			#lin_convention
			#add esp,x
			chars hex_x={REX_Operand_64,0x83,regregmod|espregnumber};chars adjuster#1
			if nr_of_args>conv;set adjuster conv;else;set adjuster nr_of_args;endelse
			mult adjuster (qwsz)
			SetCall err addtosec(#hex_x,4,code)
		endelseif
	endIf
	return err
endfunction
function function_call_64(sd is_callex)
	sd conv;setcall conv convdata((convdata_total))
	sd err
	Data code%ptrcodesec
	sd hex_1;sd hex_2;sd hex_3;sd hex_4;sd hex_5;sd hex_6
	call convdata((convdata_call),#hex_1)
	#
	if is_callex==(FALSE)
		setcall err function_call_64f(#hex_1,conv,code)
		Return err
	endif
	##
	#mov edx,eax
	chars find_args={REX_Operand_64,0x8b,edxregnumber|regregmod}
	SetCall err addtosec(#find_args,3,code);If err!=(noerror);Return err;EndIf
	#
	#convention and shadow space
	#cmp rax,imm32
	chars cmp_je={REX_Operand_64,0x3d};data cmp_imm32#1
	set cmp_imm32 conv;dec cmp_imm32
	#jump if above
	chars *callex_jump=0x77;chars j_off#1
	#
	#convention gdb view,and gui view
	#push a
	chars callex_conv=0x50
	#neg al
	chars *={0xf6,3*toregopcode|regregmod}
	#add al conv
	chars *=0x04;chars conv_neg#1
	#mov cl 5
	chars *={0xb1,5}
	#mult al cl
	chars *={0xf6,4*toregopcode|ecxregnumber|regregmod}
	#call
	chars *={0xe8,0,0,0,0}
	#pop c
	chars *=0x59
	#add rax rcx    can be --image-base=int64 but more than 0xff000000 x64 dbg says invalid but there is int64 rip in parent x64 debug
	chars *={REX_Operand_64,0x01,ecxregnumber|regregmod}
	#pop a
	chars *=0x58
	#add rcx,imm8
	chars *={REX_Operand_64,0x83,ecxregnumber|regregmod,11}
	#j cl
	chars *={0xff,4*toregopcode|ecxregnumber|regregmod}
	#
	set conv_neg conv
	set j_off 25
	SetCall err addtosec(#cmp_je,8,code);If err!=(noerror);Return err;EndIf
	SetCall err addtosec(#callex_conv,25,code);If err!=(noerror);Return err;EndIf
	if conv==(lin_convention)
		SetCall err addtosec(hex_6,5,code);If err!=(noerror);Return err;EndIf
		SetCall err addtosec(hex_5,5,code);If err!=(noerror);Return err;EndIf
	endif
	SetCall err addtosec(hex_4,5,code);If err!=(noerror);Return err;EndIf
	SetCall err addtosec(hex_3,5,code);If err!=(noerror);Return err;EndIf
	SetCall err addtosec(hex_2,5,code);If err!=(noerror);Return err;EndIf
	ss rspwithoffset;set rspwithoffset hex_1;add rspwithoffset 2;or rspwithoffset# (disp8mod)
	SetCall err addtosec(hex_1,5,code);If err!=(noerror);Return err;EndIf
	xor rspwithoffset# (disp8mod)
	#
	#shadow space
	if conv==(ms_convention)
		#neg al
		chars callex_shadow={0xf6,3*toregopcode|regregmod}
		#add al conv-1
		chars *=0x04;chars shadow_neg#1
		#push qwordsz
		chars *={0x6a,qwsz}
		#mul al [esp]
		chars *={0xf6,4*toregopcode|espregnumber,espregnumber*toregopcode|espregnumber}
		#sub rsp,rax
		chars *={REX_Operand_64,0x2b,espregnumber*toregopcode|regregmod}
		#
		set shadow_neg conv;dec shadow_neg
		set j_off 12
		SetCall err addtosec(#cmp_je,8,code);If err!=(noerror);Return err;EndIf
		SetCall err addtosec(#callex_shadow,12,code)
	else
		#lin_convention
		#cmp rax,imm32
		chars callex_unshadow={REX_Operand_64,0x3d};data *cmp_imm32=lin_convention
		#jump if below or equal
		chars *callex_jump=0x76;chars *j_off=10
		chars *rax_conv={REX_Operand_64,0xb8};data *={lin_convention,0}
		#push qwordsz
		chars *={0x6a,qwsz}
		#inc al
		chars *={0xfe,regregmod}
		#mul al [esp]
		chars *={0xf6,4*toregopcode|espregnumber,espregnumber*toregopcode|espregnumber}
		#add rsp,rax
		chars *={REX_Operand_64,0x03,espregnumber*toregopcode|regregmod}
		#
		SetCall err addtosec(#callex_unshadow,28,code)
	endelse
	return err
endfunction
#err
function function_start_64(sd nr_of_args)
	Data code%ptrcodesec
	sd data;sd sz
	setcall data convdata((convdata_fn),#sz,nr_of_args)
	sd err
	SetCall err addtosec(data,sz,code)
	return err
endfunction
#err
function callex64_call()
	sd conv;setcall conv convdata((convdata_total))
	#Stack aligned on 16 bytes.
	const callex64_start=!
	#bt esp,3 (bit offset 3)        rsp for 3 bits is useless
	chars callex64_code={0x0F,0xBA,bt_reg_imm8|espregnumber,3}
	#jc @ (jump when rsp=....8)
	chars *=0x72;chars *=7+2+4+2+2
	#7cmp ecx,5
	chars *={REX_Operand_64,0x81,0xf9};data jcase1#1
	set jcase1 conv;inc jcase1
	#2jb $
	chars *=0x72;chars *=4+2+2+7+2+4+2+4
	#4bt ecx,0
	chars *={0x0F,0xBA,bt_reg_imm8|ecxregnumber,0}
	#2jc %
	chars *=0x72;chars *=2+7+2+4+2
	#2jmp $
	chars *=0xEB;chars *=7+2+4+2+4
	#7@ cmp ecx,5
	chars *={REX_Operand_64,0x81,0xf9};data jcase2#1
	set jcase2 conv;inc jcase2
	#2jb %
	chars *=0x72;chars *=4+2
	#4bt ecx,0
	chars *={0x0F,0xBA,bt_reg_imm8|ecxregnumber,0}
	#2jc $
	chars *=0x72;chars *=4
	#%
	#4 sub rsp,8
	chars *={REX_Operand_64,0x83,0xEC};chars *=8
	#$
	#mov rdx,rcx
	chars *keep_nr_args={REX_Operand_64,0x8b,edxregnumber*toregopcode|ecxregnumber|regregmod}
	sd ptrcodesec%ptrcodesec
	sd err
	SetCall err addtosec(#callex64_code,(!-callex64_start),ptrcodesec)
	return err
endfunction
