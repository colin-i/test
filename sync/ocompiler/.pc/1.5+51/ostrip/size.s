
function get_offset(sd args,sd end)
	mult end :
	add end args
	sd offset=0
	while args!=end
		add args :
		addcall offset get_offset_item(args)
		add args :
	endwhile
	return offset
endfunction

function get_offset_item(sd fname)
	sd file;setcall file fopen(fname,"rb")
	if file!=(NULL)
		#at the first 3 documentations there is no info about errno errors for fseek ftell
		#it is implementation specific, many judgements can be made
		call seek(file,0,(SEEK_END))
		sd off;setcall off ftell(file)
		if off!=-1
			sub off (2+8)  #knowing \r\n same as ounused that is not headering with src. and 8 is copy-paste
			call seeks(file,off)
			chars buf={0,0,0,0, 0,0,0,0, 0}
			call read(file,#buf,8) #copy-paste
			datax nr#1
			call sscanf(#buf,"%08x",#nr) #copy-paste
			return nr
		endif
		call erMessages("ftell error at",fname)
	endif
	call fError(fname)
endfunction
