

Set path_nofree (NULL)
Include "./wingetfile/getfilefromcommand.s"
set path_free (NULL)
If path_nofree==null
	#open file name
	Include "./wingetfile/getfilefromopenfilename.s"
	set path_nofree path_free
	Data timeatbegin#1
	SetCall timeatbegin GetTickCount()
	Set openfilenamemethod true
EndIf