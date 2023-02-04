#err
function comline_parse(sd argc,sv argv)
	if argc>2
		mult argc :
		add argc argv
		add argv (2*:)
		while argv!=argc
			sd err
			#
			sd p
			setcall err comline_pointer(argv#,#p)
			if err!=(noerror)
				return err
			endif
			#
			incst argv
			if argv==argc
				return "missing value for command line argument"
			endif
			ss v
			set v argv#
			setcall err comline_value(v,p)
			if err!=(noerror)
				return err
			endif
			incst argv
		endwhile
	endif
	return (noerror)
endfunction
#err
function comline_value(ss v,sd p)
	chars input#1
	set input v#
	if input!=0
		if input>=(asciizero)
			inc v
			if v#==0
				sub input (asciizero)
				if input<=(last_convention_input)
					set p# input
					return (noerror)
				endif
				return "a command line value can have only 0,1 or 2"
			endif
			return "command line value must have only one digit"
		endif
		return "command line value is not a number"
	endif
	return "command line value null"
endfunction
#err
function comline_pointer(ss a,sd p_p)
	sv t%nr_of_prefs_strings_p
	sd e=nr_of_prefs_jumper
	add e t
	sd a_len
	setcall a_len strlen(a)
	while t!=e
		ss b;set b t#
		sd b_len
		setcall b_len strlen(b)
		if a_len==b_len
			sd c
			setcall c memcmp(a,b,a_len)
			if c==0
				sub t (nr_of_prefs_jumper)
				set p_p# t#
				return (noerror)
			endif
		endif
		incst t
	endwhile
	return "command line argument not found"
endfunction
