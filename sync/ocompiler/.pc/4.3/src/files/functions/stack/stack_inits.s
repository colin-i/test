


function is_stack(data pointer)
	data mask#1
	data maskoffset=maskoffset
	data stackb=stackbit
	data stack#1
	
	set mask pointer
	add mask maskoffset
	set stack stackb
	and stack mask#
	return stack
endfunction



function stack_get_relative(sd location)
	sd mask
	data maskoffset=maskoffset
	data to_relative=tostack_relative

	set mask location
	add mask maskoffset
	set mask mask#
	div mask to_relative
	data regopcode_mask=regopcode_mask
	and mask regopcode_mask
	return mask
endfunction