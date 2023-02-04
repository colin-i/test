

#verify that all conditions are closed
SetCall errormsg checkcondloopclose()
If errormsg!=noerr
	Call msgerrexit(errormsg)
EndIf

#verify at executables that LIBRARY are closed
If fileformat==pe_exec
	If implibsstarted==true
		SetCall errormsg closelib()
		If errormsg!=noerr
			Call msgerrexit(errormsg)
		EndIf
	EndIf
EndIf

#verify preferences
Call warnings(true,includes,nameofstoffile)

