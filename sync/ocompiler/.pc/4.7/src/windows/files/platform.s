
function platform_free()
	sd a%p_argv
	if a#!=(NULL)
		call free(a#)
	endif
	sd b%p_path_free
	if b#!=(NULL)
		call free(b#)
	endif
endfunction

function wide_to_ansi(ss in)
	ss out
	set out in
	dec out
	chars n=0;chars x#1
	while 0==0
		inc out
		set x in#
		set out# x
		if x==n
			return (void)
		endif
		add in 2
	endwhile
endfunction