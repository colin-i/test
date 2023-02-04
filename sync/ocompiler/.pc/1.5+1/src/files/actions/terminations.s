

#verify that all conditions are closed
SetCall errormsg checkcondloopclose()
If errormsg!=noerr
	Call msgerrexit(errormsg)
EndIf

#close the last LIBRARY
If fileformat==pe_exec
	If implibsstarted==true
		SetCall errormsg closelib()
		If errormsg!=noerr
			Call msgerrexit(errormsg)
		EndIf
	EndIf
EndIf

#verify preferences
sd err_bool
setCall err_bool warnings(true,includes,nameofstoffile,#errormsg)
If errormsg!=noerr
	if err_bool==(TRUE)
		Call msgerrexit(errormsg)
	endif
	call errexit()
EndIf
