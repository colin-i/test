
value stackalign#1
data *stackalign_size#1
const ptrstackalign^stackalign
#er
function align_alloc(sd sz)
	inc sz   #for entry
	mult sz (dwsz)
	sv s%ptrstackalign
	setcall s# memcalloc(sz) #need 0 by default
	sv start;set start s#
	if s#!=(NULL)
		add s :
		set s#d^ sz
		return (noerror)
	endif
	return (error)
endfunction
function align_free()
	sv s%ptrstackalign
	if s#!=(NULL)
		call free(s#)
	endif
endfunction

#er
function stack_align(sd nr)
	sd final_nr
	setcall final_nr pref_call_align(nr)
	if final_nr!=0
		and final_nr 1
		sd type;setcall type align_type()
		if type==(even_align)
			if final_nr==0
				return (noerror)
			endif
		elseif   final_nr!=0
				return (noerror)
		endelseif
		#Stack aligned on 16 bytes. Depending on the number of arguments
		vdata code%ptrcodesec
		chars align={REX_Operand_64,0x83,0xEC,8}
		sd err
		SetCall err addtosec(#align,(4),code)
		return err
	endif
	return (noerror)
endfunction
#nr
function pref_call_align(sd nr)
	data ptr_call_align%ptr_call_align
	sd type;set type ptr_call_align#
	if type!=(call_align_no)
		sd conv;setcall conv convdata((convdata_total))
		if nr<=conv
			if conv==(lin_convention)
				if type==(call_align_yes_all)
					return 2 #to align at no args
				endif
			else
				if type!=(call_align_yes_arg)
					return conv
				endif
			endelse
		else
			return nr
		endelse
	endif
	return 0
endfunction


#err
function align_ante(sd arguments)
	setcall arguments pref_call_align(arguments)
	if arguments!=0
		sd pointer
		#sd container%ptrstackAlign
		#wanting with three pass, the impXorfnX is not ready at first pass: call getcontplusReg(container,#pointer)
		#sub pointer (dwsz)
		#test if in a function
		#sd fnboolptr%globalinnerfunction
		#if fnboolptr#==(TRUE)
		#	sub pointer (dwsz)
		#endif
		setcall pointer align_ptype()
		sd test=1;and test arguments
		sd test2=0xffFF
		if test==0
		#even, put on low word
			inc pointer#
			and test2 pointer#
			if test2!=0
				return (noerror)
			endif
			return "More than 65535 even calls?"
		endif
		#odd, put on high word
		sd bag;set bag pointer#
		div bag 0x10000
		inc bag
		and test2 bag
		if test2!=0x8000
			#set to high word
			#this is not endian independent add pointer (wsz)
			#and pointer#s^ bag
			#or pointer#s^ bag
			#div bag 0x100
			#inc pointer
			#and pointer#s^ bag
			#or pointer#s^ bag
			mult bag 0x10000
			sd bag2;set bag2 pointer#
			and bag2 bag;or bag2 bag
			and pointer# (0xffFF)
			or pointer# bag2
			return (noerror)
		endif
		return "32768 odd calls?"  #to div without sign
	endif
	return (noerror)
endfunction

function align_resolve()
	sv end%ptrstackalign
	sd pointer;set pointer end#
	add end :
	set end end#d^
	add end pointer
	while pointer!=end
		sd bag;set bag pointer#
		if bag!=0
			sd even=0xffFF;and even bag
			div bag 0x10000
			if even>=bag
				set pointer# (even_align)
			else
				set pointer# (odd_align)
			endelse
		endif
		add pointer (dwsz)
	endwhile
endfunction

#ptype
function align_ptype()
	sd ptrfunctionTagIndex%ptrfunctionTagIndex
	sv container%ptrstackalign
	sd cont;set cont container#
	sd index=dwsz;mult index ptrfunctionTagIndex#
	add cont index
	return cont
endfunction

#type
function align_type()
	sd cont;setcall cont align_ptype()
	return cont#
endfunction

#err
function align_entryscope()
	sd type;setcall type align_type()
	if type!=0
		#bt ebx,3 (offset 3) x8 or x0
		#rex to bt the first byte it is useless
		chars bt={twobytesinstruction_byte1,bt_instruction,bt_reg_imm8|ebxregnumber,3}
		#j(c|nc);sub rbx,8
		chars jump#1;chars *=4;chars *={REX_Operand_64,0x83,RegReg*tomod|(5*toregopcode)|ebxregnumber,8}
		if type==(even_align)
			#there are more even calls to align
			#Jump short if not carry
			set jump (0x73)
		else
			#odd
			#Jump short if carry
			set jump (0x72)
		endelse
		vdata code%ptrcodesec
		sd err
		SetCall err addtosec(#bt,(4+6),code)
		return err
	endif
	return (noerror)
endfunction
