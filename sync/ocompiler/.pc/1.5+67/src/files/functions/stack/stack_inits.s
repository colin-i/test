


function data_get_maskbit(ss pointer,sd bit)
	add pointer (maskoffset)
	and bit pointer#
	return bit
endfunction

#import bit
function importbit(sd pointer)
	sd bit
	setcall bit data_get_maskbit(pointer,(idatabitfunction))
	return bit
endfunction
function stackbit(sd pointer)
	sd bit
	setcall bit data_get_maskbit(pointer,(stackbit))
	return bit
endfunction
function pointbit(sd pointer)
	sd bit
	setcall bit data_get_maskbit(pointer,(pointbit))
	return bit
endfunction
function datapointbit(sd pointer)
	sd bit
	setcall bit data_get_maskbit(pointer,(datapointbit))
	return bit
endfunction

function stack_get_relative(sd location)
	sd mask
	set mask location
	add mask (maskoffset)
	set mask mask#
	and mask (stack_relative)
	if mask==0
		return (ebxregnumber)
	endif
	return (ebpregnumber)
endfunction
