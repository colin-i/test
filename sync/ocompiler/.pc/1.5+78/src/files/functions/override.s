
#err
function override_com(sd pcontent,sd psize)
	sd size
	setcall size valinmem(pcontent#,psize#,(asciispace))
	if size==0
		return "first argument is missing at override"
	endif
	sd name
	set name pcontent#
	call advancecursors(pcontent,psize,size)
	call spaces(pcontent,psize)
	if size==0
		return "second argument is missing at override"
	endif
	sd err
	ss t
	charsx aux#1   #override is at all passes coming again here
	set t name;add t size;set aux t#;set t# 0
	#work can be done do allow line comment here
	ss p
	set size psize#
	setcall err memoryalloc(size,#p)
	#it is file_get_content memwise (not strwise with null ending)
	#memoryalloc? the override mimics command line, but this can be changed
	if err==(noerror)
		inc size
		call memtomem(p,pcontent#,size)
		dec size
		add p size;set p# 0
		sub p size
		setcall err prefs_set(name,p)
		call free(p)
		if err==(noerror)
			set t# aux
			call advancecursors(pcontent,psize,size)
		endif
	endif
	return err
endfunction
