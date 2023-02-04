
#aftercall pointer (string)
function aftercall_find(sv objects,sv poffset)
	sd doffset=0
	while objects#!=(NULL)
		sv obj=to_symtab
		add obj objects#
		ss sym;set sym obj#
		incst obj
		sd end;set end obj#
		add end sym
		while sym!=end
#Data elf64_sym_st_name#1
#Chars elf64_sym_st_info#1
#Chars *elf64_sym_st_other={0}
#Chars elf64_sym_st_shndx#2
#Data elf64_sym_st_value#1;data *=0
#Data elf64_sym_st_size#1;data *=0
const sym__to_value=datasize+charsize+charsize+(2*charsize)
const sym_size=sym__to_value+:+:
const sym__to_shndx=datasize+charsize+charsize
			add sym (sym__to_shndx)
			chars d={dataind,0}
			sd cmp;setcall cmp memcmp(sym,#d,2)
			if cmp==0
				sub sym (charsize+charsize)
				chars info=STB_GLOBAL*0x10|STT_NOTYPE   ;#global seems to always be here but there is too much code to separate
				if info==sym#
				#this is the aftercall,get string pointer from strtab
					sub sym (datasize)
					incst obj
					sd mem;set mem obj#
					add mem sym#d^

					#and get offset in data
					add sym (sym__to_value)
					add doffset sym#v^
					add poffset# doffset

					return mem
				else
					add sym (sym_size-datasize)
				endelse
			else
				add sym (sym_size-sym__to_shndx)
			endelse
		endwhile
		add obj (from_symsize_to_voffset)
		add doffset obj#d^
		incst objects
	endwhile
	return (NULL)
endfunction

function aftercall_replace(sv psym,sv pstr,ss astr,sv aoffset)
	sd pos;setcall pos shnames_find_sec(pstr,astr)
	if pos!=-1
		sd sec;set sec psym#
		incst psym
		sd end;set end psym#
		add end sec
		while sec!=end
			#name pos is first
			if sec#==pos
				add sec (sym__to_value)
				set sec#v^ aoffset
				call verbose((verbose_count))
				call verbose((verbose_flush))
				ret
			endif
			add sec (sym_size)
		endwhile
	endif
endfunction

function aftercall_in_objects(sv objects,ss astr,sv aoffset,sd textinneroffset)
	sv tphisic%pexetext
	set tphisic tphisic#
	add tphisic textinneroffset
	while objects#!=(NULL)
		sv object;set object objects#
		sv pointer=to_strtab;add pointer object
		sd pos;setcall pos shnames_find_sec(pointer,astr)
		if pos!=-1
			sub pointer (from_strtab_to_symtab)

			sd sympos;set sympos pointer#
			sv end;set end pointer
			incst end
			set end end#
			add end sympos
			while sympos!=end
				if sympos#==pos
					break
				endif
				add sympos (sym_size)
			endwhile
			sub sympos pointer#
			div sympos (sym_size)
			#if not exists there is a problem, but who cares (since objects are our own scripts)

			#in data is with dataind (and only in one object)
			#sub pointer (to_symtab)
			#call aftercall_object_section(pointer,sympos,aoffset)
			sub pointer (from_symtab_to_text)
			call reloc_item(pointer,sympos,aoffset,tphisic)
		endif
		add object (to_text_extra_a)
		add tphisic object#
		incst objects
	endwhile
endfunction
