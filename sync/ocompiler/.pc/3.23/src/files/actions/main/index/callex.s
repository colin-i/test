

sd call_sz
setcall errormsg arg_size(pcontent#,pcomsize#,#call_sz)
if errormsg==(noerror)
	sd top_data
	sd bool_indirect
	setcall errormsg prepare_function_call(pcontent,pcomsize,call_sz,#top_data,#bool_indirect)
	if errormsg==(noerror)
		call spaces(pcontent,pcomsize)
		setcall errormsg twoargs(pcontent,pcomsize,(cCALLEX),(NULL))
		if errormsg==(noerror)
			#
			sd callex64;setcall callex64 is_for_64_is_impX_or_fnX_get()
			if callex64==(TRUE)
				#Stack aligned on 16 bytes.
				const callex64_start=!
				#bt rsp,3 (bit offset 3)
				chars callex64_code={REX_Operand_64,0x0F,0xBA,bt_reg_imm8|espregnumber,3}
				#jc @ (jump when rsp=....8)
				chars *=0x72;chars *=6+2+4+2+2
				#6cmp ecx,5
				chars *={0x81,0xf9};data *=5
				#2jb $
				chars *=0x72;chars *=4+2+2+6+2+4+2+4
				#4bt ecx,0
				chars *={0x0F,0xBA,bt_reg_imm8|ecxregnumber,0}
				#2jc %
				chars *=0x72;chars *=2+6+2+4+2
				#2jmp $
				chars *=0xEB;chars *=6+2+4+2+4
				#6@ cmp ecx,5
				chars *={0x81,0xf9};data *=5
				#2jb %
				chars *=0x72;chars *=4+2
				#4bt ecx,0
				chars *={0x0F,0xBA,bt_reg_imm8|ecxregnumber,0}
				#2jc $
				chars *=0x72;chars *=4
				#4% sub rsp,8
				chars *={REX_Operand_64,0x83,0xEC};chars *=8
				#$
				SetCall errormsg addtosec(#callex64_code,(!-callex64_start),ptrcodesec)
			endif
			#
			if errormsg==(noerror)
				const callex_start=!
				# ## cmp ecx,0
				chars callex_c1={0x81,0xf9};data *=0
				#je ###
				chars *={0x74};chars callex_je#1
					#dec ecx
					chars *=0xFF;chars *=1*toregopcode|ecxregnumber|0xc0
				const callex_size1=!-callex_start
					# mov edx,[eax+ecx*4]
					chars callex_c2=0x8b;chars *=edxregnumber*toregopcode|4;chars callex_sib#1
					#push e(r)dx
					chars *=0x52
					#jmp ##
					chars *=0xEB;chars callex_jmp#1
				# ###
				const callex_size2=!-callex_start-callex_size1
				#set jumps and mov.sib: index ecx and base eax
				set callex_sib 8
				#set jumps,index*4(2) or *8(3)
				sd callex_bool;setcall callex_bool is_for_64()
				set callex_je 0x08;set callex_jmp 0xf0
				if callex_bool==(FALSE);or callex_sib (2*tomod)
				else;#for 64
					or callex_sib (3*tomod)
					inc callex_je;dec callex_jmp
				endelse
				#
				SetCall errormsg addtosec(#callex_c1,(callex_size1),ptrcodesec)
				if errormsg==(noerror)
					if callex_bool==(TRUE);call rex_w(#errormsg);endif
					if errormsg==(noerror)
						SetCall errormsg addtosec(#callex_c2,(callex_size2),ptrcodesec)
						if errormsg==(noerror)
							setcall errormsg write_function_call(top_data,bool_indirect,(TRUE))
						endif
					endif
				endif
			endif
		endif
	endif
endif