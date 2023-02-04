

if parses==(pass_init)
	SetCall errormsg twoargs_ex(pcontent,pcomsize,subtype,null,(allow_later_sec))
else
	call entryscope_verify_code()
	SetCall errormsg twoargs(pcontent,pcomsize,subtype,null)
endelse
