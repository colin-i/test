
Data warningsboolptr%ptrwarningsbool
sd warning_bool
setcall warning_bool stratmem(pcontent,pcomsize,"ON")
if warning_bool==(TRUE)
	set warningsboolptr# (TRUE)
else
	setcall warning_bool stratmem(pcontent,pcomsize,"OFF")
	if warning_bool==(TRUE)
		set warningsboolptr# (FALSE)
	else
		set errormsg "Expecting 'on' or 'off' command"
	endelse
endelse