

Include "./actions/setdefdir.s"

SetCall errormsg include(path)
If errormsg!=noerr
	Call msgerrexit(errormsg)
EndIf

Include "./actions/main.s"

Include "./actions/terminations.s"

Include "./actions/pathout.s"

Include "./actions/fileformat.s"

#call to resolve local or imported functions
Include "./actions/resolve.s"

Include "./actions/write.s"

Call freeclose()