
#cont
function working_file()
	sv lvs%levels_p
	sd lvsd%levels_dp
	sv p=-dword
	add p lvsd#
	add p lvs#
	set p p#d^
	sv fls%files_p
	add p fls#
	#sv lvs%levels_p;sv p=-dword;add p lvs#d^;add lvs (dword);add p lvs#;set p p#d^;sv fls%files_vp;add p fls#
	return p#
endfunction

function constant_add(sd s,sd sz)
	sv p
	setcall p working_file()
	call addtocont(p,s,sz)
endfunction

#previous file
function incrementfiles()
	sd cursor%levels_dp
	set cursor cursor#
	sd pf
	if cursor==0
		set pf (NULL)
	else
		setcall pf working_file()
	endelse
	sv lvs%levels_p
	call ralloc(lvs,(dword))
	add cursor lvs#
	#sd cursor;set cursor lvs#d^;call ralloc(lvs,(dword));add lvs (dword);add cursor lvs#
	setcall cursor# filessize()
	return pf
endfunction

function decrementfiles()
	sd lvs%levels_p
	call ralloc(lvs,(-dword))
endfunction

#sz
function filessize()
	sd fls%files_dp
	return fls#
	#sd fls%files_p;set fls fls#;return fls
endfunction

#sz
function constssize()
	sv end%files_p
	sv cursor
	set cursor end#
	add end :
	set end end#d^
	add end cursor
	#sv cursor%files_p;sd end;set end cursor#d^;add cursor (dword);set cursor cursor#;add end cursor
	sd sz=0
	while cursor!=end
		addcall sz constssize_file(cursor#)
		incst cursor
	endwhile
	return sz
endfunction
#sz
#function constssize_file(sd cursor);sd end;set end cursor#;add cursor (dword);set cursor cursor#v^;add end cursor
function constssize_file(sv end)
	sd cursor
	set cursor end#
	add end :
	set end end#d^
	add end cursor
	sd sz=0
	while cursor!=end
		add cursor cursor#
		add cursor (dword)
		inc sz
	endwhile
	return sz
endfunction
