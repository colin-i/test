
function filesreset()
	data f#1
	const files_nr_p^f
	set f 0
	call skip_reset()
endfunction
function skip_reset()
	data s#1
	const skip_nr_p^s
	set s 0x7fFFffFF #files pointer array not reaching here
endfunction

function filesplus()
	sd f%files_nr_p
	inc f#
endfunction

#cmp
function filesminus()
	sd f%files_nr_p
	sd s%skip_nr_p
	sd nr
	set nr f#
	dec f#
	if nr==s#
		call skip_reset()
		return 0
	elseif nr<s#
		return -1
	endelseif
	return 1
endfunction

function skip_test()
	sd s%skip_nr_p
	sd f%files_nr_p
	if f#>=s#
		return (TRUE)
	endif
	return (FALSE)
endfunction

function skip_set()
	sd s%skip_nr_p
	sd f%files_nr_p
	set s# f#
endfunction
