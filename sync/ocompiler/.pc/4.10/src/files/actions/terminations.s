

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
Call warnings(true,includes,nameofstoffile,#errormsg)
If errormsg!=noerr
	Call msgerrexit(errormsg)
EndIf
