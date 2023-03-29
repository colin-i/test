
function reloc_sort(sv pointer,sv end,sv dest,sd diff)
	sv start;set start pointer
	while start!=end
		set pointer start

		add pointer diff
		add end diff

		sd min;set min pointer#
		sd pos;set pos pointer
		add pointer (rel_size)
		while pointer!=end
			if pointer#<^min
				set min pointer#
				set pos pointer
			endif
			add pointer (rel_size)
		endwhile

		sub pos diff
		sub end diff

		call memcpy(dest,pos,(rel_size))
		add dest (rel_size)
		if start!=pos
		#to fill the gap
			call memcpy(pos,start,(rel_size))
		endif
		add start (rel_size)
	endwhile
endfunction

#correctoffset
function reloc_dyn_value(sd wrongoffset)
	valuex srcstart#1
	valuex srcmid#1
	valuex destd#1
	valuex destv#1

	if wrongoffset>=^srcmid
	#virtual
		sub wrongoffset srcmid
		add wrongoffset destv
		return wrongoffset
	endif
	#file
	sub wrongoffset srcstart
	add wrongoffset destd
	return wrongoffset
endfunction

#datavaddr
function reloc_dyn_initobj(sd datavaddr)
	valuex objects#1
	valuex srcend#1
	valuex destdnext#1
	valuex destvnext#1

	set reloc_dyn_value.destd destdnext
	set reloc_dyn_value.destv destvnext
	set reloc_dyn_value.srcstart datavaddr

	sv obj;set obj objects#
	add obj (to_data_extra)
	sd herevirtual;set herevirtual obj#d^
	set reloc_dyn_value.srcmid datavaddr
	add reloc_dyn_value.srcmid herevirtual
	add destdnext herevirtual
	add obj (from_data_extra_to_data_extra_sz)
	sub herevirtual obj#
	neg herevirtual
	add destvnext herevirtual

	add obj (from_extra_sz_to_extra_sz_a)
	add datavaddr obj#
	set srcend datavaddr

	return datavaddr
endfunction

function reloc_iteration(sv pointer,sd end,sd datavaddr,sd datavaddrend,sd diff)
	#this is called in all 3 cases (even only at addends there is virtual)
	add pointer diff
	add end diff
	#find the minimum and the maximum
	while pointer!=end
		if pointer#>=^datavaddr
			break
		endif
		add pointer (rel_size)
	endwhile
	if pointer!=end
		#can be .text after .data
		sv cursor;set cursor pointer
		while pointer!=end
			if pointer#>=^datavaddrend
				break
			endif
			add pointer (rel_size)
		endwhile
		if cursor!=pointer
			#at first object only virtuals can be corrected
			set reloc_dyn_initobj.objects frees.objects
			set reloc_dyn_initobj.destdnext datavaddr
			set reloc_dyn_initobj.destvnext datavaddr
			add reloc_dyn_initobj.destvnext frees.exedatasize  #this is after the new size was set
			setcall datavaddr reloc_dyn_initobj(datavaddr)
			while cursor!=pointer
				sd offset;set offset cursor#
				while offset>=^reloc_dyn_value.srcstart
					if offset<^reloc_dyn_initobj.srcend
						break
					endif
					incst reloc_dyn_initobj.objects
					if reloc_dyn_initobj.objects#!=(NULL)
						setcall datavaddr reloc_dyn_initobj(datavaddr)
						continue
					endif
					ret     #it's not in .data anymore
				endwhile
				setcall cursor# reloc_dyn_value(offset)
				add cursor (rel_size)
				call verbose((verbose_count))
			endwhile
		endif
	endif
endfunction
