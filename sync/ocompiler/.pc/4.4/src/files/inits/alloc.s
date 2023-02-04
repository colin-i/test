

SetCall path memalloc(flag_max_path)
If  path==null
	Call errexit()
EndIf

SetCall errormsg enumbags(true)
If errormsg!=noerr
	Call msgerrexit(errormsg)
EndIf
