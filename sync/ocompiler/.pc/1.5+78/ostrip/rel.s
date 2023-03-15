

function reloc(sv objects,sd daddr,sd datainneroffset,sd textinneroffset)
	sd doffset;set doffset daddr
	sv voffset%pexedatasize;   #this is after the new size was set
	set voffset voffset#
	add voffset daddr
	sv dphisic%pexedata
	set dphisic dphisic#
	add dphisic datainneroffset
	sv tphisic%pexetext
	set tphisic tphisic#
	add tphisic textinneroffset
	while objects#!=(NULL)
		sv object;set object objects#
		sd d;set d object
		add object (section_alloc)

		sd t;set t object
		add object (from_text_to_data_extra)

		sd voffset_obj;set voffset_obj object#d^
		add object (from_data_extra_to_data_extra_sz)

		sv vsize_obj;set vsize_obj object#
		sub vsize_obj voffset_obj

		call reloc_sec(d,doffset,voffset,voffset_obj,dphisic)
		call reloc_sec(t,doffset,voffset,voffset_obj,tphisic)

		add doffset voffset_obj
		add voffset vsize_obj
		add dphisic voffset_obj
		add object (extra_sz+from_extra_sz_to_extra_sz_a)
		add tphisic object#

		incst objects
	endwhile
endfunction

function reloc_sec(sv object,sd doffset,sd voffset,sd voffset_obj,sd soffset)
	sv pointer;set pointer object#
	incst object
	sd end;set end object#
	add end pointer
	while pointer!=end
#		Data elf64_r_offset#1;data *=0
#		data elf64_r_info_type#1
#		data elf64_r_info_symbolindex#1
#		data elf64_r_addend#1;data *=0
		const rel_to_type=:
		const rel_from_type_to_addend=datasize+datasize
		const rel_to_addend=rel_to_type+rel_from_type_to_addend
		const rel_size=rel_to_addend+:

		sv cursor;set cursor pointer
		incst cursor
		if cursor#d^==(R_X86_64_64)
			add cursor (datasize)
			if cursor#d^==(dataind)
				add cursor (datasize)
				sv addend;set addend cursor#
				if addend>=voffset_obj
					add addend voffset
				else
					add addend doffset
				endelse
				sv rel_offset;set rel_offset pointer#
				add rel_offset soffset
				set rel_offset# addend
				call verbose((verbose_count))
			endif
		endif
		add pointer (rel_size)
	endwhile
	call verbose((verbose_flush))
endfunction
function reloc_item(sv object,sd index,sv replacement,sd soffset)
	sv pointer;set pointer object#
	incst object
	sd end;set end object#
	add end pointer
	while pointer!=end
		sv cursor;set cursor pointer
		incst cursor
		if cursor#d^==(R_X86_64_64)
			add cursor (datasize)
			if cursor#d^==index
				sv rel_offset;set rel_offset pointer#
				add rel_offset soffset
				set rel_offset# replacement
				call verbose((verbose_count))
			endif
		endif
		add pointer (rel_size)
	endwhile
	call verbose((verbose_flush))
endfunction

include "reldynt.s"
